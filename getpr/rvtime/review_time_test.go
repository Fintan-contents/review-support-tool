package rvtime

import (
	"strconv"
	"strings"
	"testing"
)

func TestIsCurrentReviewTimeComment(t *testing.T) {
	fixtures := []struct {
		input       string
		reviewTimes string
		expected    bool
	}{
		{"- レビュー1回目\r\n- 開始日時：2023/4/1 9:00", "1", true},
		{"レビュー1回目\r\n開始日時：2023/4/1 9:00", "1", true},
		{"前に行がある。\r\n- レビュー2回目\r\n  - 開始日時：2023/4/1 9:00", "2", false},
		{"まったく関係のないコメント", "1", false},
		{"- レビュー1回目\r\n- 開始日時：2023/4/1 9:00", "2", false},
	}
	for i, fixture := range fixtures {
		name := strconv.Itoa(i)
		t.Run(name, func(t *testing.T) {
			actual := IsCurrentReviewTimeComment(fixture.input, fixture.reviewTimes)
			if actual != fixture.expected {
				t.Fail()
			}
		})
	}
}

func TestIsReviewTimeComment(t *testing.T) {
	fixtures := []struct {
		input    string
		expected bool
	}{
		{"- レビュー1回目\r\n- 開始日時：2023/4/1 9:00", true},
		{"前に行がある。\r\n- レビュー2回目\r\n  - 開始日時：2023/4/1 9:00", false},
		{"まったく関係のないコメント", false},
		{"レビュー1回目\r\n- 開始日時：2023/4/1 9:00", true},
		{"    - レビュー1回目\r\n- 開始日時：2023/4/1 9:00", false},
	}
	for i, fixture := range fixtures {
		name := strconv.Itoa(i)
		t.Run(name, func(t *testing.T) {
			actual := IsReviewTimeComment(fixture.input)
			if actual != fixture.expected {
				t.Fail()
			}
		})
	}
}

func TestParseReviewTime2(t *testing.T) {
	fixtures := []Fixture2{
		{"一般的なケース", `
- レビュー1回目
- 日付：2023/4/14
- 開始時刻：9:00
- 終了時刻：2023/4/14 11:30
- レビュー時間：30
			`,
			"1",
			ReviewTime{"2023/4/14", "9:00", "11:30", "30"}, true},

		{"レビュー時間が抜けているケース", `
- レビュー1回目
- 日付：2023/4/14
- 開始時刻：9:00
- 終了時刻：2023/4/14 11:30
			`,
			"1",
			ReviewTime{"2023/4/14", "9:00", "11:30", ""}, true},

		{"レビュー時間と終了時刻が抜けているケース", `
- レビュー1回目
- 日付：2023/4/14
- 開始時刻：9:00
			`,
			"1",
			ReviewTime{"2023/4/14", "9:00", "", ""}, true},

		{"レビュー時間と終了時刻と開始時刻が抜けているケース", `
- レビュー1回目
- 日付：2023/4/14
			`,
			"1",
			ReviewTime{"2023/4/14", "", "", ""}, true},

		{"レビュー回数が2桁のケース", `
- レビュー10回目
- 日付：2023/4/14
- 開始時刻：9:00
- 終了時刻：2023/4/14 11:30
- レビュー時間：30
			`,
			"10",
			ReviewTime{"2023/4/14", "9:00", "11:30", "30"}, true},

		{"レビュー時間が3桁のケース", `
- レビュー1回目
- 日付：2023/4/14
- 開始時刻：9:00
- 終了時刻：2023/4/14 11:30
- レビュー時間：100
			`,
			"1",
			ReviewTime{"2023/4/14", "9:00", "11:30", "100"}, true},

		{"レビュー時間が1桁のケース", `
- レビュー1回目
- 日付：2023/4/14
- 開始時刻：9:00
- 終了時刻：2023/4/14 11:30
- レビュー時間：9
			`,
			"1",
			ReviewTime{"2023/4/14", "9:00", "11:30", "9"}, true},

		{"レビュー時間ではないケース", `
これは指摘コメントなのでレビュー時間ではない。
			`,
			"1",
			ReviewTime{"", "", "", ""}, false},

		{"ラベルを省略するケース", `
- レビュー1回目
- 2023/4/14
- 9:00
- 2023/4/14 11:30
- 30
			`,
			"1",
			ReviewTime{"2023/4/14", "9:00", "11:30", "30"}, true},
	}

	for _, fixture := range fixtures {
		t.Run(fixture.name, func(t *testing.T) {
			actual1 := ParseReviewTime(strings.TrimSpace(fixture.input), fixture.reviewTimes)
			if actual1 != fixture.expected1 {
				t.Errorf("抽出した値が期待通りではありません。期待値：%v 実際の値：%v", fixture.expected1, actual1)
			}
		})
	}
}

// Fixture2 はTestParseReviewTime2の入力値の構造体
type Fixture2 struct {
	name        string
	input       string
	reviewTimes string
	expected1   ReviewTime
	expected2   bool
}
