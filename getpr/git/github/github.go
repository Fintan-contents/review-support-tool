package github

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"sort"
	"strings"

	"github.com/Fintan-contents/review-support-tool/getpr/cfg"
	"github.com/Fintan-contents/review-support-tool/getpr/csv"
	"github.com/Fintan-contents/review-support-tool/getpr/rvtime"
	"github.com/Fintan-contents/review-support-tool/getpr/text"
)

type GitHub struct {
	Config     *cfg.Config
	HttpClient *http.Client
}

func (gitHub *GitHub) ParsePullRequest() (*csv.CsvData, error) {
	comments, additions, deletions, err := gitHub.getComments()
	if err != nil {
		return nil, err
	}

	csvHeader := csv.CsvHeader{
		Additions:  additions,
		Deletions:  deletions,
		ReviewTime: gitHub.extractReviewTime(comments),
	}

	extractedReviewComments := gitHub.extractReviewComments(comments)
	builtReviewComments, err := gitHub.buildReviewComments()
	if err != nil {
		return nil, err
	}

	csvReviewCommentWithTimestamps := make([]CsvReviewCommentWithTimestamp, 0, len(extractedReviewComments)+len(builtReviewComments))
	csvReviewCommentWithTimestamps = append(csvReviewCommentWithTimestamps, extractedReviewComments...)
	csvReviewCommentWithTimestamps = append(csvReviewCommentWithTimestamps, builtReviewComments...)

	sort.Slice(csvReviewCommentWithTimestamps, func(i, j int) bool {
		return csvReviewCommentWithTimestamps[i].timestamp < csvReviewCommentWithTimestamps[j].timestamp
	})

	csvReviewComments := make([]csv.CsvReviewComment, 0, len(csvReviewCommentWithTimestamps))
	for _, c := range csvReviewCommentWithTimestamps {
		csvReviewComments = append(csvReviewComments, c.CsvReviewComment)
	}

	csvData := &csv.CsvData{
		CsvHeader:         csvHeader,
		CsvReviewComments: csvReviewComments,
	}

	return csvData, nil
}

// レビュー時刻を抽出する。
func (gitHub *GitHub) extractReviewTime(comments []Comment) rvtime.ReviewTime {
	reviewTimeComment, extracted := gitHub.extractReviewTimeComment(comments)
	if extracted {
		return rvtime.ParseReviewTime(reviewTimeComment, gitHub.Config.ReviewTimes)
	}
	return rvtime.ReviewTime{}
}

const githubGraphQLEndpoint = "https://api.github.com/graphql"

// コメントと追加行数・削除行数を取得する。
func (gitHub *GitHub) getComments() ([]Comment, int, int, error) {
	comments := make([]Comment, 0)
	var commentsCursor, reviewsCursor string
	var additions, deletions int
	for {
		requestBody := &strings.Builder{}
		data := make(map[string]interface{})
		data["Query"] = commentsQuery
		data["Org"] = gitHub.Config.Org
		data["Repo"] = gitHub.Config.Repo
		data["Pull"] = gitHub.Config.Pull
		data["Limit"] = gitHub.Config.PageSize
		data["CommentsCursor"] = commentsCursor
		data["CommentsCursorIsNil"] = (commentsCursor == "")
		data["ReviewsCursor"] = reviewsCursor
		data["ReviewsCursorIsNil"] = (reviewsCursor == "")
		commentsTemplate.Execute(requestBody, data)

		// エラーが発生するのは HTTPメソッドが不正な場合 と URLが不正な場合 なため、ここではエラーは発生しない
		req, _ := http.NewRequest("POST", githubGraphQLEndpoint, strings.NewReader(requestBody.String()))

		req.Header.Add("Authorization", "Bearer "+gitHub.Config.AccessToken)

		resp, err := gitHub.HttpClient.Do(req)
		if err != nil {
			return nil, 0, 0, errors.New("エラーが発生しました。")

		}
		defer resp.Body.Close()
		if resp.StatusCode == http.StatusUnauthorized {
			return nil, 0, 0, errors.New("認証に失敗しました。アクセストークンの設定を見直してください。")
		}
		if !(200 <= resp.StatusCode && resp.StatusCode <= 299) {
			bs, _ := io.ReadAll(resp.Body)
			s := string(bs)
			if strings.Contains(s, "API rate limit exceeded") {
				return nil, 0, 0, errors.New("APIのレート制限によりプルリクエストの情報を取得できませんでした。しばらく待ってから再実行してください。")
			}
			return nil, 0, 0, errors.New("エラーが発生しました。")
		}

		var root ReviewTimeRoot

		decoder := json.NewDecoder(resp.Body)
		err = decoder.Decode(&root)
		if err != nil {
			return nil, 0, 0, errors.New("エラーが発生しました。")
		}
		if len(root.Errors) > 0 {
			e := root.Errors[0]
			if e.Type == "NOT_FOUND" {
				return nil, 0, 0, errors.New("プルリクエストが見つかりません。オーガニゼーションやリポジトリ、プルリクエストIDの設定を確認してください。")
			}
			return nil, 0, 0, errors.New("エラーが発生しました。")
		}

		pr := root.Data.Repository.PullRequest

		additions = pr.Additions
		deletions = pr.Deletions

		for _, comment := range pr.Comments.Edges {
			comments = append(comments, comment.Node)
		}
		for _, review := range pr.Reviews.Edges {
			comments = append(comments, review.Node)
		}

		// 次のページがあればカーソルを更新してループ
		// 次のページがなければループを脱出
		nextPage := false
		if pr.Comments.PageInfo.HasNextPage {
			commentsCursor = pr.Comments.PageInfo.EndCursor
			nextPage = true
		} else if pr.Comments.PageInfo.EndCursor != "" {
			commentsCursor = pr.Comments.PageInfo.EndCursor
		}
		if pr.Reviews.PageInfo.HasNextPage {
			reviewsCursor = pr.Reviews.PageInfo.EndCursor
			nextPage = true
		} else if pr.Reviews.PageInfo.EndCursor != "" {
			reviewsCursor = pr.Reviews.PageInfo.EndCursor
		}
		if !nextPage {
			break
		}
	}
	return comments, additions, deletions, nil
}

// レビュー時刻が書かれたコメントを抽出する。
func (gitHub *GitHub) extractReviewTimeComment(comments []Comment) (string, bool) {
	reviewTimes := gitHub.Config.ReviewTimes
	for _, comment := range comments {
		input := comment.Body
		if rvtime.IsCurrentReviewTimeComment(input, reviewTimes) {
			return input, true
		}
	}
	return "", false
}

type CsvReviewCommentWithTimestamp struct {
	csv.CsvReviewComment
	timestamp string
}

// 通常のコメントからレビュー指摘コメントを抽出する。
func (gitHub *GitHub) extractReviewComments(comments []Comment) []CsvReviewCommentWithTimestamp {
	csvReviewComments := make([]CsvReviewCommentWithTimestamp, 0)
	for _, comment := range comments {
		if len(comment.Body) > 0 && !rvtime.IsReviewTimeComment(comment.Body) {
			reviewerComment, revieweeComment := text.SplitComment(comment.Body, gitHub.Config.Delimiter)
			if len(reviewerComment) > 0 || len(revieweeComment) > 0 {
				csvReviewComment := CsvReviewCommentWithTimestamp{
					CsvReviewComment: csv.CsvReviewComment{
						Url:             comment.Url,
						ReviewerComment: reviewerComment,
						Reviewer:        comment.Author.Login,
						RevieweeComment: revieweeComment,
						// 通常のコメントではレビュイーや解決状態は取得できない
						HasResolvedStatus: false,
					},
					timestamp: comment.CreatedAt,
				}
				csvReviewComments = append(csvReviewComments, csvReviewComment)
			}
		}
	}
	return csvReviewComments
}

// レビュー指摘コメントを構築する。
func (gitHub *GitHub) buildReviewComments() ([]CsvReviewCommentWithTimestamp, error) {
	csvReviewComments := make([]CsvReviewCommentWithTimestamp, 0)
	var reviewThreadsCursor string
	postscriptPrefix := text.Crlf + gitHub.Config.PostScriptPrefix

	for {
		root, err := gitHub.getReviewComments(gitHub.Config.PageSize, reviewThreadsCursor, gitHub.Config.PageSize, "")
		if err != nil {
			return nil, err
		}

		author := root.Data.Repository.PullRequest.Author.Login

		pr := root.Data.Repository.PullRequest

		for i, reviewThread := range pr.ReviewThreads.Edges {

			csvReviewComment := CsvReviewCommentWithTimestamp{
				CsvReviewComment: csv.CsvReviewComment{
					Reviewee:          author,
					Resolved:          reviewThread.Node.IsResolved,
					HasResolvedStatus: true,
				},
			}

			if len(reviewThread.Node.Comments.Edges) > 0 {
				node := reviewThread.Node.Comments.Edges[0].Node
				csvReviewComment.Url = node.Url
				csvReviewComment.timestamp = node.CreatedAt
			}

			revieweeComment := make([]string, 0)
			reviewerComment := make([]string, 0)

			for _, comment := range reviewThread.Node.Comments.Edges {
				body := comment.Node.Body
				if comment.Node.Author.Login == author {
					revieweeComment = append(revieweeComment, body)
				} else {
					reviewerComment = append(reviewerComment, body)
					if csvReviewComment.Reviewer == "" {
						csvReviewComment.Reviewer = comment.Node.Author.Login
					}
				}
			}

			// 更にコメントがあれば読み込む。
			// スレッド単位で処理するため、1つ前のスレッドのカーソル以降の1件（つまり対象のスレッド）を指定している。
			var cursor string
			if i == 0 {
				cursor = reviewThreadsCursor
			} else {
				cursor = pr.ReviewThreads.Edges[i-1].Cursor
			}
			for reviewThread.Node.Comments.PageInfo.HasNextPage {
				reviewCommentsRoot, err := gitHub.getReviewComments(1, cursor, gitHub.Config.PageSize, reviewThread.Node.Comments.PageInfo.EndCursor)
				if err != nil {
					return nil, err
				}

				for _, nextReviewThread := range reviewCommentsRoot.Data.Repository.PullRequest.ReviewThreads.Edges {
					if nextReviewThread.Node.Id == reviewThread.Node.Id {
						reviewThread = nextReviewThread
						for _, comment := range reviewThread.Node.Comments.Edges {
							body := comment.Node.Body
							if comment.Node.Author.Login == author {
								revieweeComment = append(revieweeComment, body)
							} else {
								reviewerComment = append(reviewerComment, body)
							}
						}
						break
					}
				}
			}

			csvReviewComment.ReviewerComment = strings.Join(reviewerComment, postscriptPrefix)
			csvReviewComment.RevieweeComment = strings.Join(revieweeComment, postscriptPrefix)
			csvReviewComments = append(csvReviewComments, csvReviewComment)
		}

		if pr.ReviewThreads.PageInfo.HasNextPage {
			reviewThreadsCursor = pr.ReviewThreads.PageInfo.EndCursor
		} else {
			break
		}
	}

	return csvReviewComments, nil
}

// レビューコメントを取得する。
func (gitHub *GitHub) getReviewComments(reviewThreadsLimit int, reviewThreadsCursor string, commentsLimit int, commentsCursor string) (ReviewCommentsRoot, error) {
	requestBody := &strings.Builder{}
	data := make(map[string]interface{})
	data["Query"] = threadsQuery
	data["Org"] = gitHub.Config.Org
	data["Repo"] = gitHub.Config.Repo
	data["Pull"] = gitHub.Config.Pull
	data["ReviewThreadsLimit"] = reviewThreadsLimit
	data["ReviewThreadsCursor"] = reviewThreadsCursor
	data["ReviewThreadsCursorIsNil"] = (reviewThreadsCursor == "")
	data["CommentsLimit"] = commentsLimit
	data["CommentsCursor"] = commentsCursor
	data["CommentsCursorIsNil"] = (commentsCursor == "")
	threadsTemplate.Execute(requestBody, data)

	// エラーが発生するのはHTTPメソッドが不正な場合とURLが不正な場合なため、ここではエラーは発生しない
	req, _ := http.NewRequest("POST", githubGraphQLEndpoint, strings.NewReader(requestBody.String()))

	req.Header.Add("Authorization", "Bearer "+gitHub.Config.AccessToken)

	resp, err := gitHub.HttpClient.Do(req)
	if err != nil {
		return ReviewCommentsRoot{}, errors.New("エラーが発生しました。")
	}
	defer resp.Body.Close()
	if !(200 <= resp.StatusCode && resp.StatusCode <= 299) {
		bs, _ := io.ReadAll(resp.Body)
		s := string(bs)
		if strings.Contains(s, "API rate limit exceeded") {
			return ReviewCommentsRoot{}, errors.New("APIのレート制限によりプルリクエストの情報を取得できませんでした。しばらく待ってから再実行してください。")
		}
		return ReviewCommentsRoot{}, errors.New("エラーが発生しました。")
	}

	var root ReviewCommentsRoot

	decoder := json.NewDecoder(resp.Body)
	err = decoder.Decode(&root)
	if err != nil {
		return ReviewCommentsRoot{}, errors.New("エラーが発生しました。")
	}
	if len(root.Errors) > 0 {
		e := root.Errors[0]
		if e.Type == "NOT_FOUND" {
			return ReviewCommentsRoot{}, errors.New("プルリクエストが見つかりません。オーガニゼーションやリポジトリ、プルリクエストIDの設定を確認してください。")
		}
		return ReviewCommentsRoot{}, errors.New("エラーが発生しました。")
	}

	return root, nil
}
