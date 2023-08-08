package github

import (
	_ "embed"
	"html/template"
	"strings"
)

// コメントを取得するためのHTTPリクエストボディのテンプレート。
var commentsTemplate *template.Template

// コメントを取得するためのGraphQLクエリー。
//
//go:embed "comments.gql"
var commentsQuery string

// コメントを取得するためのHTTPリクエストボディのテンプレート文字列。
var commentsRequestBodyTemplate = `{
	"query": "{{.Query}}",
	"variables": {
		"org": "{{.Org}}",
		"repo": "{{.Repo}}",
		"pull": {{.Pull}},
		"limit": {{.Limit}},
		"commentsCursor": {{if .CommentsCursorIsNil}}null{{else}}"{{.CommentsCursor}}"{{end}},
		"reviewsCursor": {{if .ReviewsCursorIsNil}}null{{else}}"{{.ReviewsCursor}}"{{end}}
	}
}`

func init() {
	commentsQuery = strings.ReplaceAll(commentsQuery, "\n", "\\n")
	commentsQuery = strings.ReplaceAll(commentsQuery, "\t", " ")
	commentsTemplate = template.Must(template.New("example").Parse(commentsRequestBodyTemplate))
}

// スレッドを取得するためのHTTPリクエストボディのテンプレート。
var threadsTemplate *template.Template

// スレッドを取得するためのGraphQLクエリー
//
//go:embed "threads.gql"
var threadsQuery string

// スレッドを取得するためのHTTPリクエストボディのテンプレート文字列。
var threadsRequestBodyTemplate = `{
	"query": "{{.Query}}",
	"variables": {
		"org": "{{.Org}}",
		"repo": "{{.Repo}}",
		"pull": {{.Pull}},
		"reviewThreadsLimit": {{.ReviewThreadsLimit}},
		"commentsLimit": {{.CommentsLimit}},
		"reviewThreadsCursor": {{if .ReviewThreadsCursorIsNil}}null{{else}}"{{.ReviewThreadsCursor}}"{{end}},
		"commentsCursor": {{if .CommentsCursorIsNil}}null{{else}}"{{.CommentsCursor}}"{{end}}
	}
}`

func init() {
	threadsQuery = strings.ReplaceAll(threadsQuery, "\n", "\\n")
	threadsQuery = strings.ReplaceAll(threadsQuery, "\t", " ")
	threadsTemplate = template.Must(template.New("example").Parse(threadsRequestBodyTemplate))
}
