package csv

import (
	"encoding/csv"
	"errors"
	"io"
	"os"
	"strconv"
	"strings"

	"github.com/Fintan-contents/review-support-tool/getpr/rvtime"
	"golang.org/x/text/encoding/japanese"
	"golang.org/x/text/transform"
)

// 指定されたパスにCSVデータを書き出す。
func WriteCsv(csvFile string, data *CsvData, useSjis bool) error {
	file, err := os.Create(csvFile)
	if err != nil {
		return err
	}
	defer file.Close()
	return writeCsvFile(data, file, useSjis)
}

func writeCsvFile(csvData *CsvData, file *os.File, useSjis bool) error {
	var writer *csv.Writer
	if useSjis {
		writer = csv.NewWriter(transform.NewWriter(file, japanese.ShiftJIS.NewEncoder()))
	} else {
		writer = csv.NewWriter(file)
	}
	writer.UseCRLF = true
	if csvData != nil {
		writer.Write([]string{
			strconv.Itoa(csvData.CsvHeader.Additions),
			strconv.Itoa(csvData.CsvHeader.Deletions),
			csvData.CsvHeader.ReviewTime.ReviewDate,
			csvData.CsvHeader.ReviewTime.ReviewStartTime,
			csvData.CsvHeader.ReviewTime.ReviewEndTime,
			csvData.CsvHeader.ReviewTime.ReviewMinutes,
		})
		for _, csvReviewComment := range csvData.CsvReviewComments {
			writer.Write([]string{
				csvReviewComment.Url,
				escape(csvReviewComment.ReviewerComment),
				csvReviewComment.Reviewer,
				escape(csvReviewComment.RevieweeComment),
				csvReviewComment.Reviewee,
				strconv.FormatBool(csvReviewComment.Resolved),
				strconv.FormatBool(csvReviewComment.HasResolvedStatus),
			})
		}
		writer.Flush()
	}
	err := writer.Error()
	if err != nil && strings.HasPrefix(err.Error(), "encoding: rune not supported by encoding.") {
		return errors.New("絵文字のようなShift_JISで扱えない文字が含まれています。")
	}
	return err
}

// 改行をエスケープして1行のテキストに変換する。
func escape(input string) string {
	builder := strings.Builder{}
	reader := strings.NewReader(input)
	for {
		r, _, err := reader.ReadRune()
		if err == io.EOF {
			return builder.String()
		}
		if r == '\\' {
			builder.WriteRune('\\')
			builder.WriteRune('\\')
		} else if r == '\n' {
			builder.WriteRune('\\')
			builder.WriteRune('n')
		} else if r == '\r' {
			// CRは無視する
		} else {
			builder.WriteRune(r)
		}
	}
}

// ヘッダー
type CsvHeader struct {
	// 追加行数。GitBucketは常に0。
	Additions int
	// 削除行数。GitBucketは常に0。
	Deletions int
	// レビュー日時情報
	ReviewTime rvtime.ReviewTime
}

// レビュー指摘事項・対応内容
type CsvReviewComment struct {
	// 指摘のURL
	Url string
	// レビュー指摘事項。GitHubとGitLabはAPIで取得したマークダウン、GitBucketはAPIが使えないためHTMLをパースして得たテキスト。改行はエスケープして1行にする。
	ReviewerComment string
	// レビュアーのユーザー名。
	Reviewer string
	// 対応内容。GitHubとGitLabはAPIで取得したマークダウン、GitBucketはAPIが使えないためHTMLをパースして得たテキスト。改行はエスケープして1行にする。
	RevieweeComment string
	// レビュイーのユーザー名。
	Reviewee string
	// APIで取得できる指摘の解決状態。GitHubの通常コメントと、GitBucketは指摘の解決状態を取得できないので`false`を返す。
	Resolved bool
	// APIで指摘の解決状態を取得できる場合は`true`を返す。GitHubの通常コメントと、GitBucketは指摘の解決状態を取得できないので`false`を返す。
	HasResolvedStatus bool
}

// CSVデータ
type CsvData struct {
	// ヘッダー
	CsvHeader CsvHeader
	// レビュー指摘事項・対応内容
	CsvReviewComments []CsvReviewComment
}
