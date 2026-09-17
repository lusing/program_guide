# 22 · HTTP 服务

> 对应示例：`examples/22_http/`

标准库 `net/http` 是 Go 的门面担当——不装框架就能写生产服务。

## 22.1 Handler：一个函数就是一个服务

```go
mux := http.NewServeMux()

mux.HandleFunc("GET /hello/{name}", func(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "你好，%s！", r.PathValue("name"))
})

http.ListenAndServe(":8080", mux)    // 一行起服
```

**1.22 起路由 pattern 支持方法 + 路径参数**：`"GET /hello/{name}"` 精确匹配方法（不匹配返回 405 而非 404）、`r.PathValue("name")` 取参数、`{path...}` 通配尾部。以前要 chi/gorillamux 才有的能力进了标准库。

| pattern | 匹配 |
|---|---|
| `/hello` | 精确（任意方法） |
| `GET /hello` | 方法限定 |
| `GET /items/{id}` | 单段参数 |
| `/static/` | 前缀子树 |
| `GET /` | 兜底 |

**长 pattern 优先**：`/items/{id}` 比 `/` 先中。

## 22.2 中间件：handler 套 handler

```go
func withLogging(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		next.ServeHTTP(w, r)
		log.Printf("%s %s %v", r.Method, r.URL.Path, time.Since(start))
	})
}

srv := &http.Server{Handler: withLogging(NewMux())}    // 洋葱式包装
```

中间件就是**返回 Handler 的函数**——日志、计时、鉴权、recover（10 章的 panic 兜底挂这）、trace 全这一层。串多个就一层层套。

## 22.3 请求与响应的细节

```go
// 响应：先 Header 后 body
w.Header().Set("Content-Type", "application/json; charset=utf-8")
w.WriteHeader(http.StatusOK)          // 不写默认 200
json.NewEncoder(w).Encode(data)
http.Error(w, "出错了", http.StatusBadRequest)   // 错误响应一行

// 请求：读 body 要限流（别无限信任输入）
body, err := io.ReadAll(io.LimitReader(r.Body, 1<<20))
r.URL.Query().Get("q")               // 查询参数
```

## 22.4 客户端

```go
req, _ := http.NewRequestWithContext(ctx, http.MethodGet, url, nil)   // ctx 控超时
resp, err := http.DefaultClient.Do(req)
defer resp.Body.Close()               // 不关 = 连接池泄漏
b, _ := io.ReadAll(resp.Body)

// 更直接的整活
resp, err := http.Get(url)            // 无 ctx 版（演示代码用）
```

`http.DefaultClient` 自带连接池。生产建议自建 `&http.Client{Timeout: 10 * time.Second}`——**DefaultClient 没有总超时**，挂着不动是真实事故。取消/超时一律 `NewRequestWithContext`（18 章 ctx 贯穿到 TCP 层）。

## 22.5 优雅关停

```go
srv := &http.Server{Handler: mux}
ln, _ := net.Listen("tcp", "127.0.0.1:0")    // 0 端口：系统挑空闲端口
go srv.Serve(ln)

ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
defer cancel()
srv.Shutdown(ctx)    // 不收新连接；存量请求处理完（或超时）再退
```

`ListenAndServe` 自己管监听时拿不到精确控制；**Listen + Serve 拆开**是标准姿势（示例 22 用 0 端口随机起服——测试不撞端口）。

## 22.6 测试：httptest 不起真端口

```go
srv := httptest.NewServer(NewMux())      // 起在随机端口的真服务器
defer srv.Close()
resp, _ := http.Get(srv.URL + "/hello/Go")

rec := httptest.NewRecorder()            // 不起端口的内存版
NewMux().ServeHTTP(rec, httptest.NewRequest("GET", "/hello/Go", nil))
rec.Code / rec.Body.String()
```

示例 22 的测试两种都用了（带中间件与不带）。**HTTP 测试不需要 mock 框架**——Recorder 就是官方 mock。

## 22.7 坑位清单

1. **Handler 里忘 return**：`http.Error` 后代码继续跑，body 写两份——Error 后立刻 return（Go 没有异常短路，if 块尾 return 是仪式）。
2. **resp.Body 不关**：连接池耗尽，跑几小时开始超时——defer resp.Body.Close() 肌肉记忆。
3. **DefaultClient 无超时**：上游一挂跟着挂——自建 Client 带 Timeout。
4. **1.22 前的路由写法**：`mux.Handle("/hello", ...)` 无方法匹配、无参数——老代码 `r.URL.Path` 手撕路径的写法该升级了。
5. **ReadAll 大 body**：`io.ReadAll(r.Body)` 无上限读——配 `LimitReader`（本示例代码就这么写的）。
6. **JSON 响应忘 Content-Type**：浏览器按文本渲染——`application/json; charset=utf-8` 一行省一坑。

---
