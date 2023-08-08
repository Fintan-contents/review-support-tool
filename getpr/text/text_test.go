package text

import (
	"fmt"
	"testing"
)

func TestSplitComment(t *testing.T) {
	fixtures := []struct {
		input     string
		expected1 string
		expected2 string
	}{
		{"foo\r\n\r\n---\r\n\r\nbar", "foo", "bar"},
		{"foo\r\n---", "foo", ""},
		{"foo", "foo", ""},
		{"---\r\nbar", "", "bar"},
		{"", "", ""},
		{"---", "", ""},
		{"foo\r\n\r\n---\r\n\r\nbar\r\n\r\n---\r\n\r\nbaz\r\n", "foo", "bar\r\n\r\n---\r\n\r\nbaz"},
	}
	const delimiter = "---"
	for i, fixture := range fixtures {
		t.Run(fmt.Sprintf("%v", i), func(t *testing.T) {
			actual1, actual2 := SplitComment(fixture.input, delimiter)
			if actual1 != fixture.expected1 {
				t.Errorf("期待値は %v ですが実際には %v でした", fixture.expected1, actual1)
			} else if actual2 != fixture.expected2 {
				t.Errorf("期待値は %v ですが実際には %v でした", fixture.expected2, actual2)
			}
		})
	}
}
