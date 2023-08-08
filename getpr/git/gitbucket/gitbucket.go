package gitbucket

import (
	"errors"
	"io"
	"net/http"
	"net/url"
	"strings"

	"github.com/Fintan-contents/review-support-tool/getpr/cfg"
	"github.com/Fintan-contents/review-support-tool/getpr/csv"
	"github.com/Fintan-contents/review-support-tool/getpr/rvtime"
	"github.com/Fintan-contents/review-support-tool/getpr/text"
	"golang.org/x/net/html"
)

type GitBucket struct {
	Config     *cfg.Config
	HttpClient *http.Client
}

func (gitBucket *GitBucket) ParsePullRequest() (*csv.CsvData, error) {

	htmlSource, err := gitBucket.getHtml()
	if err != nil {
		return nil, err
	}

	return gitBucket.parseHtml(htmlSource)
}

// HTTPクライアントを利用して次の手順でプルリクエストのページのHTMLを取得する
//
//  1. ログインページを開く
//  2. ログインを実施する
//  3. プルリクエストのページを開く
func (gitBucket *GitBucket) getHtml() (string, error) {

	// ログインページを開く
	resp, err := gitBucket.HttpClient.Get(gitBucket.Config.Endpoint + "/signin")
	if err != nil {
		// 実装を見る限り、ここで発生するエラーはURLが不正なことが原因
		return "", errors.New("エラーが発生しました。エンドポイントの設定を見直してください。")
	}
	defer resp.Body.Close()
	if 200 != resp.StatusCode {
		return "", errors.New("エラーが発生しました。エンドポイントの設定を見直してください。")
	}

	username, password, found := strings.Cut(gitBucket.Config.AccessToken, ":")
	if !found {
		return "", errors.New("GitBucketのアクセストークンはユーザー名とパスワードを:で繋いだものを設定してください。")
	}

	// ログインを実施する
	form := url.Values{}
	form.Add("userName", username)
	form.Add("password", password)
	resp, err = gitBucket.HttpClient.PostForm(gitBucket.Config.Endpoint+"/signin", form)
	if err != nil {
		return "", errors.New("エラーが発生しました。")
	}
	defer resp.Body.Close()
	if !(200 <= resp.StatusCode && resp.StatusCode <= 399) {
		return "", errors.New("エラーが発生しました。")
	}
	defer func() {
		resp, err = gitBucket.HttpClient.Get(gitBucket.Config.Endpoint + "/signout")
		if err != nil {
			return
		}
		defer resp.Body.Close()
	}()

	// プルリクエストのページを開く
	resp, err = gitBucket.HttpClient.Get(gitBucket.buildUrl())
	if err != nil {
		return "", errors.New("エラーが発生しました。")
	}
	defer resp.Body.Close()
	if resp.StatusCode == http.StatusUnauthorized {
		return "", errors.New("認証に失敗したか、あるいはリポジトリへアクセスする権限がありません。アクセストークンやオーガニゼーション、リポジトリの設定を見直してください。")
	} else if resp.StatusCode == http.StatusNotFound {
		return "", errors.New("プルリクエストが見つかりません。オーガニゼーションやリポジトリ、プルリクエストIDの設定を確認してください。")
	} else if !(200 <= resp.StatusCode && resp.StatusCode <= 399) {
		return "", errors.New("エラーが発生しました。")
	}

	bs, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", errors.New("エラーが発生しました。")
	}

	s := string(bs)
	return s, nil
}

func (gitBucket *GitBucket) buildUrl() string {
	return gitBucket.Config.Endpoint + "/" + gitBucket.Config.Org + "/" + gitBucket.Config.Repo + "/pull/" + gitBucket.Config.Pull
}

// PRに付いたコメントの構造
// div#comment-list
//
//	// PRの概要
//	div.panel.panel-default.issue-comment-box
//	    // ユーザー名(PRを作ったユーザー)
//	    div.panel-heading > a.username.strong
//	    // 本文
//	    div.panel-body.markdown-body#issueContent
//	// レビューコメント
//	div.panel.panel-default
//	    // 1つのコメント
//	    div.commit-comment-box.inline-comment#discussion_r5
//	        // ユーザー名
//	        a.username.strong
//	        // 本文
//	        div.commit-commentContent-5
//	// 通常のコメント
//	div.panel.panel-default.issue-comment-box#comment-1
//	    // ユーザー名
//	    div.panel-heading > a.username.strong
//	    // 本文
//	    div.panel-body.markdown-body#commentContent-1

// HTMLをパースしてCSVデータを構築する。
func (gitBucket *GitBucket) parseHtml(htmlSource string) (*csv.CsvData, error) {
	root, err := html.Parse(strings.NewReader(htmlSource))
	if err != nil {
		return nil, errors.New("エラーが発生しました。")
	}
	commentNodes := getCommentList(root)

	// 先頭のコメントはPRの概要
	author := extractAuthor(findElementByClass(commentNodes[0], "panel-heading"))

	csvHeader := csv.CsvHeader{}
	csvReviewComments := make([]csv.CsvReviewComment, 0)
	for _, commentNode := range commentNodes[1:] {
		id, ok := getId(commentNode)
		if ok {
			// id属性を持つのが通常のコメント（非スレッド）
			panelHeading := findElementByClass(commentNode, "panel-heading")
			if isMergedComment(panelHeading) {
				// マージ時のコミットコメントは無視する
				continue
			}
			reviewer := extractAuthor(panelHeading)
			textContent := getTextContent(findElementByClass(commentNode, "panel-body markdown-body"))
			if rvtime.IsReviewTimeComment(textContent) {
				// レビュー日時情報が書かれたコメント
				if rvtime.IsCurrentReviewTimeComment(textContent, gitBucket.Config.ReviewTimes) {
					csvHeader.ReviewTime = rvtime.ParseReviewTime(textContent, gitBucket.Config.ReviewTimes)
				}
			} else {
				// レビュー指摘事項・対応内容が書かれたコメント
				reviewComment, revieweeComment := text.SplitComment(textContent, gitBucket.Config.Delimiter)
				csvReviewComment := csv.CsvReviewComment{
					Url:               gitBucket.buildUrl() + "#" + id,
					ReviewerComment:   reviewComment,
					Reviewer:          reviewer,
					RevieweeComment:   revieweeComment,
					Reviewee:          author,
					Resolved:          false,
					HasResolvedStatus: false,
				}
				csvReviewComments = append(csvReviewComments, csvReviewComment)
			}
		} else {
			// id属性を持たないのはレビューコメント（スレッド）
			csvReviewComment := gitBucket.buildReviewComment(gitBucket.Config.PostScriptPrefix, author, commentNode)
			csvReviewComments = append(csvReviewComments, csvReviewComment)
		}
	}
	csvData := &csv.CsvData{
		CsvHeader:         csvHeader,
		CsvReviewComments: csvReviewComments,
	}
	return csvData, nil
}

// panel-header に "referenced the  pull request" というテキストがあるとマージ時のコミットコメント。
func isMergedComment(n *html.Node) bool {
	if n == nil {
		return false
	}
	element := findElementByClass(n, "muted")
	if element == nil {
		return false
	}
	textContent := getTextContent(element)
	return strings.Contains(textContent, "referenced the  pull request")
}

func getCommentList(n *html.Node) []*html.Node {
	commentListNode := findElementById(n, "comment-list")
	childDivs := getChildDivs(commentListNode)
	commentNodes := make([]*html.Node, 0)
	for _, cd := range childDivs {
		if hasClass(cd, "panel") {
			commentNodes = append(commentNodes, cd)
		}
	}
	return commentNodes
}

func hasClass(n *html.Node, class string) bool {
	for _, attr := range n.Attr {
		if attr.Key == "class" && strings.Contains(attr.Val, class) {
			return true
		}
	}
	return false
}

func getChildDivs(n *html.Node) []*html.Node {
	nodes := make([]*html.Node, 0)
	if n != nil {
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			if c.Type == html.ElementNode && c.Data == "div" {
				nodes = append(nodes, c)
			}
		}
	}
	return nodes
}

func extractAuthor(n *html.Node) string {
	usernameNode := findElementByClass(n, "username strong")
	return getTextContent(usernameNode)
}

func (gitBucket *GitBucket) buildReviewComment(postScriptPrefix, reviewee string, n *html.Node) csv.CsvReviewComment {
	childDivs := getChildDivs(findElementByClass(n, "panel-body"))
	reviewerComment := strings.Builder{}
	revieweeComment := strings.Builder{}
	id, _ := getId(childDivs[0])
	var reviewer string
	for _, childDiv := range childDivs {
		nestedChildDivs := getChildDivs(findElementByClass(childDiv, "markdown-body"))
		author := extractAuthor(nestedChildDivs[0])
		if textContent := getTextContent(nestedChildDivs[1]); len(textContent) > 0 {
			if author == reviewee {
				if revieweeComment.Len() > 0 {
					revieweeComment.WriteString(text.Crlf)
					revieweeComment.WriteString(postScriptPrefix)
				}
				revieweeComment.WriteString(textContent)
			} else {
				if reviewerComment.Len() > 0 {
					reviewerComment.WriteString(text.Crlf)
					reviewerComment.WriteString(postScriptPrefix)
				}
				reviewerComment.WriteString(textContent)
				if reviewer == "" {
					reviewer = author
				}
			}
		}
	}
	csvReviewComment := csv.CsvReviewComment{
		Url:               gitBucket.buildUrl() + "#" + id,
		ReviewerComment:   reviewerComment.String(),
		Reviewer:          reviewer,
		RevieweeComment:   revieweeComment.String(),
		Reviewee:          reviewee,
		Resolved:          false,
		HasResolvedStatus: false,
	}
	return csvReviewComment
}

func getId(n *html.Node) (string, bool) {
	for _, attr := range n.Attr {
		if attr.Key == "id" {
			return attr.Val, true
		}
	}
	return "", false
}

func getTextContent(n *html.Node) string {
	builder := strings.Builder{}
	var fn func(n *html.Node)
	fn = func(n *html.Node) {
		if n.Type == html.TextNode {
			textContent := strings.TrimSpace(n.Data)
			if len(textContent) > 0 {
				if builder.Len() > 0 {
					builder.WriteString(text.Crlf)
				}
				builder.WriteString(textContent)
			}
			return
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			fn(c)
		}
	}
	fn(n)
	return builder.String()
}

func findElementById(n *html.Node, id string) *html.Node {
	return findElementByAttr(n, "id", id)
}

func findElementByClass(n *html.Node, class string) *html.Node {
	return findElementByAttr(n, "class", class)
}

func findElementByAttr(n *html.Node, attrKey, attrVal string) *html.Node {
	if n.Type == html.ElementNode {
		for _, attr := range n.Attr {
			if attr.Key == attrKey && attr.Val == attrVal {
				return n
			}
		}
	}
	for c := n.FirstChild; c != nil; c = c.NextSibling {
		if found := findElementByAttr(c, attrKey, attrVal); found != nil {
			return found
		}
	}
	return nil
}
