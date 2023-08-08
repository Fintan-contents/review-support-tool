package git

import (
	"net/http"
	"net/url"
	"strings"
	"testing"

	"github.com/Fintan-contents/review-support-tool/getpr/cfg"
)

func TestBuildHttpClientInvalidProxyUrl(t *testing.T) {
	config := &cfg.Config{
		Proxy: "invalid-proxy-url\n",
	}
	cli, err := BuildHttpClient(config)
	if cli != nil || err == nil {
		t.Fail()
		return
	} else if !strings.Contains(err.Error(), "proxyに不正なURLが指定されています。") {
		t.Error(err)
		return
	}
}

func TestBuildHttpClientWithProxy(t *testing.T) {
	proxyUrl := "http://proxy.example.com:3128"
	config := &cfg.Config{
		Proxy: proxyUrl,
	}
	cli, err := BuildHttpClient(config)
	if err != nil {
		t.Error(err)
		return
	}
	transport := cli.Transport.(*http.Transport)
	actualProxy, _ := transport.Proxy(nil)
	expectedProxy, _ := url.Parse(proxyUrl)
	if actualProxy.String() != expectedProxy.String() {
		t.Errorf("Expected is %s but actual is %s", expectedProxy, actualProxy)
		return
	}
}

func TestBuildGitServiceInvalidTarget(t *testing.T) {
	config := &cfg.Config{
		Target: "unknown",
	}
	cli, err := BuildGitService(config, nil)
	if cli != nil || err == nil {
		t.Fail()
		return
	} else if !strings.Contains(err.Error(), "targetはgithub、gitlab、gitbucketのいずれかを指定してください。") {
		t.Error(err)
		return
	}
}
