package rvtime

import (
	"regexp"
)

var regexpMinute = regexp.MustCompile(`\d+`)
var regexpDate = regexp.MustCompile(`\d{4}/\d{1,2}/\d{1,2}`)
var regexpTime = regexp.MustCompile(`\d{1,2}:\d{1,2}`)
var regexpSplit = regexp.MustCompile(`\r\n?|\n`)
var reviewTimeCommentPattern = regexp.MustCompile(`^(?:- )?レビュー(\d+)回目`)

// 現在のレビュー回数と一致するコメントならtrueを返す。
func IsCurrentReviewTimeComment(input string, currentReviewTimes string) bool {
	groups := reviewTimeCommentPattern.FindStringSubmatch(input)
	return len(groups) > 1 && groups[1] == currentReviewTimes
}

// レビュー日時コメントならtrueを返す。
func IsReviewTimeComment(input string) bool {
	return reviewTimeCommentPattern.MatchString(input)
}

// レビュー日時コメントをパースする。
func ParseReviewTime(input string, reviewTimes string) ReviewTime {
	reviewTime := ReviewTime{}
	if IsCurrentReviewTimeComment(input, reviewTimes) {
		splitResult := regexpSplit.Split(input, -1)
		if len(splitResult) > 1 {
			reviewTime.ReviewDate = regexpDate.FindString(splitResult[1])
		}
		if len(splitResult) > 2 {
			reviewTime.ReviewStartTime = regexpTime.FindString(splitResult[2])
		}
		if len(splitResult) > 3 {
			reviewTime.ReviewEndTime = regexpTime.FindString(splitResult[3])
		}
		if len(splitResult) > 4 {
			reviewTime.ReviewMinutes = regexpMinute.FindString(splitResult[4])
		}
	}
	return reviewTime
}

// レビュー日時情報
type ReviewTime struct {
	// レビュー日付
	ReviewDate string
	// 開始時刻
	ReviewStartTime string
	// 終了時刻
	ReviewEndTime string
	// レビュー時間
	ReviewMinutes string
}
