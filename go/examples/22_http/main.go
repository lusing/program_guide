// 22_http：ServeMux 方法路由（1.22+）、中间件、客户端、优雅关停。
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net"
	"net/http"
	"strings"
	"time"
)

// NewMux 组装路由：1.22 起 pattern 支持 "方法 路径 {参数}"。
func NewMux() *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /hello/{name}", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "你好，%s！", r.PathValue("name"))
	})

	mux.HandleFunc("GET /api/user", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json; charset=utf-8")
		_ = json.NewEncoder(w).Encode(map[string]any{"name": "阿G", "age": 18})
	})

	mux.HandleFunc("POST /echo", func(w http.ResponseWriter, r *http.Request) {
		body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20)) // 限 1 MiB：别无限信任输入
		if err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		_, _ = w.Write(body) // 原样回显
	})

	return mux
}

// withLogging 中间件：handler 套 handler，横向切一刀。
func withLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %v", r.Method, r.URL.Path, time.Since(start))
	})
}

func httpGet(ctx context.Context, url string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	b, err := io.ReadAll(resp.Body)
	return string(b), err
}

func postEcho(ctx context.Context, url, body string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, strings.NewReader(body))
	if err != nil {
		return "", err
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	b, err := io.ReadAll(resp.Body)
	return string(b), err
}

func main() {
	srv := &http.Server{Handler: withLogging(NewMux())}
	ln, err := net.Listen("tcp", "127.0.0.1:0") // 0 端口 = 让系统挑空闲端口
	if err != nil {
		log.Fatal(err)
	}
	go srv.Serve(ln)
	base := "http://" + ln.Addr().String()

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	fmt.Println("== GET 路径参数 ==")
	if s, err := httpGet(ctx, base+"/hello/Go"); err == nil {
		fmt.Println(" ", s)
	}
	fmt.Println("== GET JSON API ==")
	if s, err := httpGet(ctx, base+"/api/user"); err == nil {
		fmt.Println(" ", s)
	}
	fmt.Println("== POST 回显 ==")
	if s, err := postEcho(ctx, base+"/echo", "回声测试"); err == nil {
		fmt.Println(" ", s)
	}

	// 优雅关停：不再收新请求，存量处理完再退
	shutdownCtx, cancel2 := context.WithTimeout(context.Background(), time.Second)
	defer cancel2()
	_ = srv.Shutdown(shutdownCtx)
	fmt.Println("服务器已优雅关停")
}
