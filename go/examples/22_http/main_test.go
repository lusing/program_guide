package main

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestHelloRoute(t *testing.T) {
	srv := httptest.NewServer(withLogging(NewMux()))
	defer srv.Close()
	got, err := httpGet(t.Context(), srv.URL+"/hello/Go")
	if err != nil {
		t.Fatal(err)
	}
	if want := "你好，Go！"; got != want {
		t.Errorf("got %q, want %q", got, want)
	}
}

func TestAPIRoute(t *testing.T) {
	srv := httptest.NewServer(NewMux())
	defer srv.Close()
	got, err := httpGet(t.Context(), srv.URL+"/api/user")
	if err != nil {
		t.Fatal(err)
	}
	var m map[string]any
	if err := json.Unmarshal([]byte(got), &m); err != nil {
		t.Fatalf("应返回合法 JSON: %v（原文 %q）", err, got)
	}
	if m["name"] != "阿G" || m["age"] != float64(18) { // JSON 数字 → float64！
		t.Errorf("api 返回 %v", m)
	}
}

func TestEchoRoute(t *testing.T) {
	srv := httptest.NewServer(NewMux())
	defer srv.Close()
	got, err := postEcho(t.Context(), srv.URL+"/echo", "ping")
	if err != nil {
		t.Fatal(err)
	}
	if got != "ping" {
		t.Errorf("echo = %q, want ping", got)
	}
}

func TestMethodMismatch(t *testing.T) {
	srv := httptest.NewServer(NewMux())
	defer srv.Close()
	resp, err := http.Get(srv.URL + "/echo") // GET 打 POST 路由
	if err != nil {
		t.Fatal(err)
	}
	defer resp.Body.Close()
	if resp.StatusCode != http.StatusMethodNotAllowed {
		t.Errorf("GET /echo 应 405，得 %d", resp.StatusCode)
	}
}
