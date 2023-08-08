package main

import (
	"flag"
	"fmt"
	"io"
	"os"

	"github.com/Fintan-contents/review-support-tool/getpr/cfg"
	"github.com/Fintan-contents/review-support-tool/getpr/csv"
	"github.com/Fintan-contents/review-support-tool/getpr/git"
	"golang.org/x/text/encoding/japanese"
	"golang.org/x/text/transform"
)

var config *cfg.Config

func init() {
	config = &cfg.Config{}
	config.ConfigureFlag()
}

// Gitからレビュー情報を取得し、csvファイルに出力する。
func main() {
	err := run()
	if err != nil {
		var writer io.Writer
		if config.UseSjisStdErr {
			writer = transform.NewWriter(os.Stderr, japanese.ShiftJIS.NewEncoder())
		} else {
			writer = os.Stderr
		}
		fmt.Fprint(writer, err)
		os.Exit(1)
		return
	}
}

func run() error {
	flag.Parse()

	if err := config.Validate(); err != nil {
		return err
	}

	config.SetupEndpoint()

	// 構造体の準備をする
	httpClient, err := git.BuildHttpClient(config)
	if err != nil {
		return err
	}
	gitService, err := git.BuildGitService(config, httpClient)
	if err != nil {
		return err
	}

	// プルリクエストの情報を取得する
	data, err := gitService.ParsePullRequest()
	if err != nil {
		return err
	}

	// CSVへ書き出す
	if err := csv.WriteCsv(config.CsvFile, data, config.UseSjisFile); err != nil {
		return err
	}
	return nil
}
