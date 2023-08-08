package csv

import (
	"fmt"
	"strings"
	"testing"
)

func TestEscape(t *testing.T) {
	fixtures := []struct {
		Input, Expected string
	}{
		{"Hello World", "Hello World"},
		{`改行を含む
コメント`, `改行を含む\nコメント`},
		{`エスケープ済みの場合\\nのコメント`, `エスケープ済みの場合\\\\nのコメント`},
	}
	for i, fixture := range fixtures {
		t.Run(fmt.Sprintf("TestEscapse%v", i), func(t *testing.T) {
			actual := escape(fixture.Input)
			if actual != fixture.Expected {
				t.Errorf(`Expected is "%v" but actual is "%v"`, fixture.Expected, actual)
			}
		})
	}
}

func TestWriteCsv(t *testing.T) {
	err := WriteCsv("testwritecsv.csv", nil, false)
	if err == nil {
		t.Fail()
		return
	} else if !strings.Contains(err.Error(), "testwritecsv.csv: is a directory") {
		t.Error(err)
		return
	}
}
