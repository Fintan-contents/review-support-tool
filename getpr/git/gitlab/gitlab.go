package gitlab

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strconv"
	"strings"

	"github.com/Fintan-contents/review-support-tool/getpr/cfg"
	"github.com/Fintan-contents/review-support-tool/getpr/csv"
	"github.com/Fintan-contents/review-support-tool/getpr/rvtime"
)

// GitLabからマージリクエストのコメント情報を取得する
func (gitLab *GitLab) ParsePullRequest() (*csv.CsvData, error) {

	// マージリクエストの情報を取得する
	mergeRequestInfo, err := gitLab.getMergeRequestInfo()
	if err != nil {
		return nil, err
	}

	// 指摘コメントの情報取得
	gitlabDiscussions, err := gitLab.getGitlabDiscussions()
	if err != nil {
		return nil, err
	}

	additions, deletions, err := gitLab.getChanges()
	if err != nil {
		return nil, err
	}

	// レビュー指摘、レビュー時間のパース
	csvReviewComments, csvHeader := gitLab.parseReviewCommentAndTime(&mergeRequestInfo, &gitlabDiscussions, additions, deletions)

	csvData := &csv.CsvData{}
	csvData.CsvHeader = csvHeader
	csvData.CsvReviewComments = csvReviewComments
	return csvData, nil
}

// GitLabからマージリクエストのコメント以外の情報を取得する
func (gitLab *GitLab) getMergeRequestInfo() (MergeRequestInfo, error) {
	//マージリクエストの情報を取得するurlは　GET /projects/:id/merge_requests/:merge_request_iid
	var body io.Reader = nil
	req, err := http.NewRequest(
		"GET",
		gitLab.Config.Endpoint+"/projects/"+gitLab.Config.Repo+"/merge_requests/"+gitLab.Config.Pull,
		body,
	)
	if err != nil {
		return MergeRequestInfo{}, errors.New("エラーが発生しました。")
	}

	req.Header.Add("PRIVATE-TOKEN", gitLab.Config.AccessToken)

	resp, err := gitLab.Client.Do(req)
	if err != nil {
		return MergeRequestInfo{}, errors.New("エラーが発生しました。")
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusUnauthorized {
		return MergeRequestInfo{}, errors.New("認証に失敗しました。アクセストークンの設定を見直してください。")
	} else if resp.StatusCode == http.StatusNotFound {
		return MergeRequestInfo{}, errors.New("マージリクエストが見つかりません。リポジトリやマージリクエストIDの設定を確認してください。")
	}
	if !(200 <= resp.StatusCode && resp.StatusCode <= 299) {
		return MergeRequestInfo{}, errors.New("エラーが発生しました。")
	}

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return MergeRequestInfo{}, errors.New("エラーが発生しました。")
	}

	var mergeRequestInfo MergeRequestInfo
	err = json.Unmarshal(respBody, &mergeRequestInfo)
	if err != nil {
		return MergeRequestInfo{}, errors.New("エラーが発生しました。")
	}

	return mergeRequestInfo, nil
}

// 差分から変更行数を算出する。
func (gitLab *GitLab) getChanges() (int, int, error) {
	var additions, deletions int
	for page := 1; ; page++ {
		var body io.Reader = nil
		req, err := http.NewRequest(
			"GET", gitLab.Config.Endpoint+"/projects/"+gitLab.Config.Repo+"/merge_requests/"+gitLab.Config.Pull+"/changes?per_page="+strconv.Itoa(gitLab.Config.PageSize)+"&page="+strconv.Itoa(page),
			body,
		)
		if err != nil {
			return 0, 0, errors.New("エラーが発生しました。")
		}
		req.Header.Add("PRIVATE-TOKEN", gitLab.Config.AccessToken)

		resp, err := gitLab.Client.Do(req)
		if err != nil {
			return 0, 0, errors.New("エラーが発生しました。")
		}
		defer resp.Body.Close()
		if resp.StatusCode == http.StatusNotFound {
			return 0, 0, errors.New("マージリクエストが見つかりません。リポジトリやマージリクエストIDの設定を確認してください。")
		}
		if !(200 <= resp.StatusCode && resp.StatusCode <= 299) {
			return 0, 0, errors.New("エラーが発生しました。")
		}

		decoder := json.NewDecoder(resp.Body)

		var root Changes
		err = decoder.Decode(&root)
		if err != nil {
			return 0, 0, errors.New("エラーが発生しました。")
		}
		for _, change := range root.Changes {
			additions += strings.Count(change.Diff, "\n+")
			deletions += strings.Count(change.Diff, "\n-")
		}

		xNextPage := resp.Header["X-Next-Page"]
		if len(xNextPage) == 0 || xNextPage[0] == "" {
			break
		}
	}

	return additions, deletions, nil
}

// GiaLabからdiscussionsを取得する
func (gitLab *GitLab) getGitlabDiscussions() ([]GitlabDiscussion, error) {
	discussions := make([]GitlabDiscussion, 0)
	//discussionsを取得するエンドポイントは GET /projects/:id/merge_requests/:merge_request_iid/discussions
	for page := 1; ; page++ {
		var body io.Reader = nil
		req, err := http.NewRequest(
			"GET", gitLab.Config.Endpoint+"/projects/"+gitLab.Config.Repo+"/merge_requests/"+gitLab.Config.Pull+"/discussions?per_page="+strconv.Itoa(gitLab.Config.PageSize)+"&page="+strconv.Itoa(page),
			body,
		)
		if err != nil {
			return nil, errors.New("エラーが発生しました。")
		}
		req.Header.Add("PRIVATE-TOKEN", gitLab.Config.AccessToken)

		resp, err := gitLab.Client.Do(req)
		if err != nil {
			return nil, errors.New("エラーが発生しました。")
		}
		defer resp.Body.Close()
		if resp.StatusCode == http.StatusNotFound {
			return nil, errors.New("マージリクエストが見つかりません。リポジトリやマージリクエストIDの設定を確認してください。")
		}
		if !(200 <= resp.StatusCode && resp.StatusCode <= 299) {
			return nil, errors.New("エラーが発生しました。")
		}

		respBody, err := io.ReadAll(resp.Body)
		if err != nil {
			return nil, errors.New("エラーが発生しました。")
		}

		var discussionsPerPage []GitlabDiscussion
		err = json.Unmarshal(respBody, &discussionsPerPage)
		if err != nil {
			return nil, errors.New("エラーが発生しました。")
		}
		discussions = append(discussions, discussionsPerPage...)

		xNextPage := resp.Header["X-Next-Page"]
		if len(xNextPage) == 0 || xNextPage[0] == "" {
			break
		}
	}

	return discussions, nil
}

// レビューコメントをパースして、レビュー指摘と、レビュー日時を取得する
func (gitLab *GitLab) parseReviewCommentAndTime(mergeRequestInfo *MergeRequestInfo, gitLabDisucussions *[]GitlabDiscussion, additions int, deletions int) ([]csv.CsvReviewComment, csv.CsvHeader) {

	// 各情報の格納先
	var csvReviewComments []csv.CsvReviewComment
	var csvHeader csv.CsvHeader

	csvHeader.Additions = additions
	csvHeader.Deletions = deletions

	for _, discussion := range *gitLabDisucussions {
		if isReviewComment(discussion.Notes) {
			// 指摘一覧に記載する情報を取得
			commentId := strconv.Itoa(discussion.Notes[0].ID)
			reviewer := discussion.Notes[0].Author.Username
			resolved := discussion.Notes[len(discussion.Notes)-1].Resolved
			reveiwerComment, revieweeComment := gitLab.parseReviewComments(discussion.Notes, mergeRequestInfo.Author.ID)
			csvReviewComments = append(csvReviewComments, csv.CsvReviewComment{
				Url:               mergeRequestInfo.WebUrl + "#note_" + commentId,
				ReviewerComment:   reveiwerComment,
				Reviewer:          reviewer,
				RevieweeComment:   revieweeComment,
				Reviewee:          mergeRequestInfo.Author.Username,
				Resolved:          resolved,
				HasResolvedStatus: true,
			})
		} else if isTarget, index := gitLab.isTargetReviewTimeComment(discussion.Notes); isTarget {
			// レビュー日時を取得する
			csvHeader.ReviewTime = gitLab.parseReviewTime(discussion.Notes, index)
		}
	}

	return csvReviewComments, csvHeader
}

// レビュー指摘コメントをパースし取得する
func (gitLab *GitLab) parseReviewComments(notes []Note, authorId int) (reviewerComment string, revieweeComment string) {
	//指摘を加工する前に、配列に格納する。
	reviewerComments := make([]string, 0)
	revieweeComments := make([]string, 0)
	for _, note := range notes {
		if note.Author.ID == authorId {
			revieweeComments = append(revieweeComments, note.Body)
		} else {
			reviewerComments = append(reviewerComments, note.Body)
		}
	}

	// 指摘を加工する。（postscript-prefixをつけ、文字をつなげる。）
	return strings.Join(reviewerComments, "\n"+gitLab.Config.PostScriptPrefix),
		strings.Join(revieweeComments, "\n"+gitLab.Config.PostScriptPrefix)
}

// 取り出したいレビュー時間のコメントかどうかを判断する（bool）
// 取り出したいものであればそのindexを返し、そうでない場合はデフォルトの0を返す（int）
func (gitLab *GitLab) isTargetReviewTimeComment(notes []Note) (bool, int) {
	// １つのスレッドをレビュー時間のスレッドとして、返信する形でレビュー時間を書いていく場合も想定し、このようにした。
	for i, note := range notes {
		if rvtime.IsCurrentReviewTimeComment(note.Body, gitLab.Config.ReviewTimes) {
			return true, i
		}
	}
	return false, 0
}

// レビュー指摘コメントかどうかを判断する
func isReviewComment(notes []Note) bool {
	// スレッドの中の１つ目のコメントがレビュー時間の情報どうかで判断
	return !rvtime.IsReviewTimeComment(notes[0].Body) && !notes[0].System
}

// レビュー時間をパースし取得する
func (gitLab *GitLab) parseReviewTime(notes []Note, targetIndex int) rvtime.ReviewTime {
	return rvtime.ParseReviewTime(notes[targetIndex].Body, gitLab.Config.ReviewTimes)
}

// GitLabの構造体
type GitLab struct {
	Config *cfg.Config
	Client *http.Client
}

// APIで取得するDiscussionの構造体
type GitlabDiscussion struct {
	Notes []Note
}

// APIで取得するDiscussionのnote項目の構造体
type Note struct {
	ID     int    `json:"id"`
	Body   string `json:"body"`
	Author struct {
		ID       int    `json:"id"`
		Username string `json:"username"`
	} `json:"author"`
	System     bool `json:"system"`
	Resolved   bool `json:"resolved"`
	ResolvedBy struct {
		ID       int    `json:"id"`
		Username string `json:"username"`
	} `json:"resolved_by"`
	ResolvedAt string `json:"resolved_at"`
}

// APIで取得するマージリクエスト（コメント以外の情報）の構造体
type MergeRequestInfo struct {
	Author struct {
		ID       int    `json:"id"`
		Username string `json:"username"`
	} `json:"author"`
	WebUrl string `json:"web_url"`
}

type Changes struct {
	Changes []Change `json:"changes"`
}

type Change struct {
	Diff string `json:"diff"`
}
