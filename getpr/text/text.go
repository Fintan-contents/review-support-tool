package text

import "strings"

const Crlf = "\r\n"

// コメントをデリミタで分割する
func SplitComment(comment string, delimiter string) (string, string) {
	reviewerComment, revieweeComment, _ := strings.Cut(Crlf+comment+Crlf, Crlf+delimiter+Crlf)
	return strings.TrimSpace(reviewerComment), strings.TrimSpace(revieweeComment)
}
