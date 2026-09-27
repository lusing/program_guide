package main

import (
	"expvar"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"
)

func TestIntListValue(t *testing.T) {
	var l IntList
	if err := l.Set("1, 2,3"); err != nil {
		t.Fatal(err)
	}
	if err := l.Set("4"); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual([]int(l), []int{1, 2, 3, 4}) {
		t.Errorf("多次 Set 累加 = %v", l)
	}
	if l.String() != "1,2,3,4" {
		t.Errorf("String = %q", l.String())
	}
	if err := (&IntList{}).Set("a"); err == nil {
		t.Error("非整数应报错")
	}
}

func TestParseAdd(t *testing.T) {
	n, ids, err := ParseAdd([]string{"-n", "5", "-ids", "7"})
	if err != nil || n != 5 || !reflect.DeepEqual([]int(ids), []int{7}) {
		t.Errorf("ParseAdd = (%d,%v,%v)", n, ids, err)
	}
	if _, _, err := ParseAdd([]string{"-h"}); err == nil {
		t.Error("-h 应触发 ContinueOnError 返回 err")
	}
	if _, _, err := ParseAdd([]string{"stray"}); err == nil {
		t.Error("多余位置参数应报错")
	}
}

func TestSlogDemo(t *testing.T) {
	text, json := SlogDemo()
	if !strings.Contains(text, "user=ada") || !strings.Contains(text, "attempts=3") {
		t.Errorf("文本日志缺字段:\n%s", text)
	}
	if !strings.Contains(text, "级别=DEBUG") && !strings.Contains(text, "DEBUG") {
		t.Errorf("Debug 应在 LevelDebug 放行后出现:\n%s", text)
	}
	if !strings.Contains(json, `"module":"auth"`) || !strings.Contains(json, `"request"`) {
		t.Errorf("JSON 缺 With 字段或分组:\n%s", json)
	}
}

func TestExpvarHandler(t *testing.T) {
	hits.Add(41)
	req := httptest.NewRequest("GET", "/debug/vars", nil)
	rec := httptest.NewRecorder()
	expvar.Handler().ServeHTTP(rec, req)
	body := rec.Body.String()
	if !strings.Contains(body, `"demo_hits": 41`) && !strings.Contains(body, `"demo_hits":41`) {
		t.Errorf("demo_hits 计数不在输出里:\n%s", body[:200])
	}
}
