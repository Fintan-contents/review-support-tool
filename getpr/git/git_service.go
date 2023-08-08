package git

import (
	"errors"
	"net/http"
	"net/http/cookiejar"
	"net/url"

	"github.com/Fintan-contents/review-support-tool/getpr/cfg"
	"github.com/Fintan-contents/review-support-tool/getpr/csv"
	"github.com/Fintan-contents/review-support-tool/getpr/git/gitbucket"
	"github.com/Fintan-contents/review-support-tool/getpr/git/github"
	"github.com/Fintan-contents/review-support-tool/getpr/git/gitlab"
)

// HTTPクライアントを構築する。
func BuildHttpClient(config *cfg.Config) (*http.Client, error) {
	client := &http.Client{}
	var transport *http.Transport
	if config.Proxy != "" {
		proxyUrl, err := url.Parse(config.Proxy)
		if err != nil {
			return nil, errors.New("proxyに不正なURLが指定されています。")
		}
		transport = &http.Transport{
			Proxy: http.ProxyURL(proxyUrl),
		}
	} else {
		// プロキシが設定されていない場合は明示的にプロキシを空にする
		transport = &http.Transport{
			Proxy: func(r *http.Request) (*url.URL, error) {
				return nil, nil
			},
		}
	}
	client.Transport = transport
	// GitBucketはパスワードでログインしてHTMLをパースする方式のためCookieを有効化する
	if config.Target == "gitbucket" {
		// 実装を見る限りエラーが返ることはない
		jar, _ := cookiejar.New(nil)
		client.Jar = jar
	}
	return client, nil
}

// 指定されたGitホスティングサービスに合わせてGitServiceを構築する。
func BuildGitService(config *cfg.Config, httpClient *http.Client) (GitService, error) {
	if config.Target == "github" {
		return &github.GitHub{Config: config, HttpClient: httpClient}, nil
	} else if config.Target == "gitlab" {
		return &gitlab.GitLab{Config: config, Client: httpClient}, nil
	} else if config.Target == "gitbucket" {
		return &gitbucket.GitBucket{Config: config, HttpClient: httpClient}, nil
	}
	// 通常であればConfigのバリデーション実施後にこのメソッドが呼ばれるため、ここには到達しない
	return nil, errors.New("targetはgithub、gitlab、gitbucketのいずれかを指定してください。")
}

// Gitホスティングサービスに対する操作をまとめたinterface。
type GitService interface {
	// プルリクエストの情報を取得してCSVデータに変換して返す。
	ParsePullRequest() (*csv.CsvData, error)
}
