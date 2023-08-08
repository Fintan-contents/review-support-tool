package cfg

import (
	"errors"
	"flag"
)

// ツールの設定を保持する構造体。
type Config struct {
	Target           string
	Endpoint         string
	AccessToken      string
	Org              string
	Repo             string
	Pull             string
	PostScriptPrefix string
	Delimiter        string
	ReviewTimes      string
	UseDiffCount     bool
	CsvFile          string
	UseSjisFile      bool
	UseSjisStdErr    bool
	Proxy            string
	PageSize         int
}

// コマンドライン引数をパースするための設定を行う。
func (config *Config) ConfigureFlag() {
	flag.StringVar(&config.Target, "target", "", "Gitホスティングサービス。github、gitlab、gitbucketのいずれかの値。")
	flag.StringVar(&config.Endpoint, "endpoint", "", "APIのルートURI。GitHub、GitLabのSaaS版は設定不要。")
	flag.StringVar(&config.AccessToken, "access-token", "", "APIを使用するためのアクセストークン。GitBucketはユーザー名とパスワードをコロンで繋いだものを設定する。")
	flag.StringVar(&config.Org, "org", "", "オーガニゼーション。GitLabは設定不要。")
	flag.StringVar(&config.Repo, "repo", "", "リポジトリ名（GitHub、GitBucket）、またはプロジェクトID（GitLab）。")
	flag.StringVar(&config.Pull, "pull", "", "プルリクエスト（マージリクエスト）のID。")
	flag.StringVar(&config.PostScriptPrefix, "post-script-prefix", "(追記)", "スレッド形式のコメントをまとめる際、2つめ以降のコメントに付けるプレフィックス。")
	flag.StringVar(&config.Delimiter, "delimiter", "~~", "レビュアーのコメントとレビュイーのコメントを分けるデリミタ。")
	flag.StringVar(&config.ReviewTimes, "review-times", "1", "レビュー回数。")
	flag.BoolVar(&config.UseDiffCount, "use-diff-count", true, "差分の行数カウントを使用するかどうかを切り替えるフラグ。")
	flag.StringVar(&config.CsvFile, "csv-file", "", "出力するCSVファイルのパス。")
	flag.BoolVar(&config.UseSjisFile, "use-sjis-file", true, "出力するCSVファイルの文字コードをShift_JISにするフラグ。このフラグがfalseの場合、CSVファイルはUTF-8で出力される。")
	flag.BoolVar(&config.UseSjisStdErr, "use-sjis-stderr", true, "標準エラー出力へ書き出す文字コードをShift_JISにするフラグ。このフラグがfalseの場合、標準エラー出力へはUTF-8で出力される。")
	flag.StringVar(&config.Proxy, "proxy", "", "プロキシ。http://proxy.example.com:3128 といった形式で設定する。")
	flag.IntVar(&config.PageSize, "page-size", 100, "ページングを行う場合の1ページあたりのサイズ。")
}

const (
	github    = "github"
	gitlab    = "gitlab"
	gitbucket = "gitbucket"
)

// バリデーションを行う。
func (config *Config) Validate() error {
	if len(config.Target) == 0 {
		return errors.New("Gitホスティングサービスを設定してください。")
	}
	if config.Target != github && config.Target != gitlab && config.Target != gitbucket {
		return errors.New("Gitホスティングサービスはgithub、gitlab、gitbucketのいずれかを設定してください。")
	}
	if config.Target == gitbucket && len(config.Endpoint) == 0 {
		return errors.New("エンドポイントを設定してください。")
	}
	if len(config.AccessToken) == 0 {
		return errors.New("アクセストークンを設定してください。")
	}
	if (config.Target == github || config.Target == gitbucket) && len(config.Org) == 0 {
		return errors.New("オーガニゼーションを設定してください。")
	}
	if len(config.Repo) == 0 {
		switch config.Target {
		case github, gitbucket:
			return errors.New("リポジトリ名を設定してください。")
		case gitlab:
			return errors.New("プロジェクトIDを設定してください。")
		}
	}
	if len(config.Pull) == 0 {
		switch config.Target {
		case github, gitbucket:
			return errors.New("プルリクエストのIDを設定してください。")
		case gitlab:
			return errors.New("マージリクエストのIDを設定してください。")
		}
	}
	if config.Target != gitlab && len(config.Delimiter) == 0 {
		return errors.New("デリミタを設定してください。")
	}
	if len(config.ReviewTimes) == 0 {
		return errors.New("レビュー回数を設定してください。")
	}
	if len(config.CsvFile) == 0 {
		return errors.New("CSVファイルのパスを設定してください。")
	}
	if !(1 <= config.PageSize && config.PageSize <= 100) {
		return errors.New("ページサイズは1〜100の値を設定してください。")
	}
	return nil
}

// Gitホスティングサービスに応じて適切なエンドポイントを設定する。
func (config *Config) SetupEndpoint() {
	if config.Target == github {
		config.Endpoint = "https://api.github.com/graphql"
	} else if config.Target == gitlab && len(config.Endpoint) == 0 {
		config.Endpoint = "https://gitlab.com/api/v4"
	}
}
