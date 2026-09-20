# 25 · Web 开发实战：Ring

> 对应示例：`examples/23_ring_web.clj`
> 依赖：`ring/ring-core` + `ring/ring-jetty-adapter`（1.15.5，Jetty 12）

> Ring 是 Clojure Web 的一切地基：**handler 是函数，request/response
> 是 map**。路由、中间件、服务器全是这枚原子核上的搭积木——
> 而且不用起服务器就能完整测试。

## 25.1 模型：普通函数吃 map 吐 map

```clojure
(defn handler [request]
  {:status 200
   :headers {"Content-Type" "text/plain"}
   :body "Hello, Ring!"})
```

request 是服务器构造的 map（关键字键），response 是你返回的 map——**没有框架类、没有注解、没有反射注册**。标准形状：

| request 常用键 | 含义 |
|---|---|
| `:request-method` | `:get` / `:post` / ...（关键字） |
| `:uri` | 路径 `"/hello"` |
| `:query-string` | 原始查询串 `"name=A"` |
| `:headers` | 请求头 map（小写字符串键） |
| `:body` | 请求体 **InputStream**（只能读一次！） |

| response 键 | 要求 |
|---|---|
| `:status` | 整数 HTTP 状态码 |
| `:headers` | 字符串键的 map |
| `:body` | String / InputStream / File / seq（按需流式） |

## 25.2 路由：cond 一把

```clojure
(require '[ring.util.response :refer [response not-found content-type]])

(defn app [request]
  (let [{:keys [request-method uri query-params]} request]
    (cond
      (and (= request-method :get) (= uri "/hello"))
      (-> (response (str "Hello, " (get query-params "name" "World") "!"))
          (content-type "text/plain"))
      :else (not-found (str "No route: " uri)))))
```

`ring.util.response` 给常用响应的构造函数（`response`/`not-found`/`redirect`/`status`/`header`）——它们只是**造 map 的辅助函数**。真实项目路由用 Reitit/Malli 路由（27 章），但替换的只是这段 cond。

## 25.3 中间件：handler 的高阶函数

```clojure
(def request-count (atom 0))

(defn wrap-counter [handler]                  ; 吃 handler
  (fn [request]                               ; 吐新 handler
    (swap! request-count inc)
    (-> (handler request)
        (assoc-in [:headers "X-Request-Count"] (str @request-count)))))

(def app+ (-> app wrap-params wrap-counter))  ; 自内向外包裹
```

标准库中间件示例——`wrap-params` 把 `:query-string` 解析成 `:query-params`：

```clojure
(app+ {:request-method :get :uri "/hello" :query-string "name=Middleware"})
; => {:status 200 :body "Hello, Middleware!" :headers {"X-Request-Count" "1"}}
```

**这是普通函数调用——没起服务器就完成了一次完整 HTTP 测试。** Ring 最大的架构红利：handler/中间件全是纯数据函数，测试不需要 socket。

包裹顺序 = 洋葱层次：`(-> app wrap-params wrap-counter)` 里 counter 在外层（先计数后解析）；换序则行为不同——调试中间件链时从里往外读。

## 25.4 嵌入式 Jetty：真服务器

```clojure
(require '[ring.adapter.jetty :refer [run-jetty]])

(def server (run-jetty app+ {:port 18899 :join? false}))
;; ... 真实 HTTP 请求 ...
(.stop server)
```

- `:join? false`：不阻塞主线程（脚本/测试用）；生产主线程 `true` 挂住。
- 返回 Jetty `Server` 对象，`.stop`/`.start` 可控生命周期。
- 端口占用会抛异常——示例里做了 18899-18903 的**端口探测回退**（部署脚本同款技巧）。

## 25.5 真实 HTTP 客户端验证

JDK 自带 `HttpURLConnection`（零依赖做验证）：

```clojure
(defn http-request [method url-str body]
  (let [^HttpURLConnection conn (doto ^HttpURLConnection (.openConnection (URL. url-str))
                                  (.setRequestMethod (.toUpperCase (name method)))   ; 必须大写！
                                  (.setConnectTimeout 3000)
                                  (.setReadTimeout 3000))]
    (when body
      (.setDoOutput conn true)
      (.setRequestProperty conn "Content-Type" "text/plain")   ; 见 25.7 坑 2
      (with-open [w (io/writer (.getOutputStream conn))]
        (.write w ^String body)))
    {:status (.getResponseCode conn)
     :body (slurp (if (>= (:status ...) 400) (.getErrorStream conn) (.getInputStream conn)))}))
```

示例里验证了全链路：GET /、GET /hello?name=、POST /echo 回显、GET /api/users 返回 JSON、GET /nope 返回 404、中间件头逐请求递增。

## 25.6 真实项目的下一级

教学示例手写了路由/JSON；生产栈是现成的（27 章索引）：

```clojure
;; Reitit 路由（数据驱动、带 coercion）
["/api/users/:id" {:get {:handler get-user
                         :parameters {:path {:id int?}}}}]     ; Malli 集成
;; JSON：muuntaja/cheshire（application/json 编解码中间件）
;; 组件生命周期：integrant/mount（数据库连接池等共享资源）
;; 全家桶脚手架：lein new luminus my-app
```

## 25.7 坑位清单（示例实测）

1. **`setRequestMethod` 只吃大写**：`(name :get)` 传进去 → `ProtocolException: Invalid HTTP method: get`——`.toUpperCase` 一下。
2. **POST 不设 Content-Type 被 `wrap-params` 吃掉 body**：HttpURLConnection 默认 `application/x-www-form-urlencoded`，中间件把 body 解析成 `:form-params`，handler 里 `slurp` 拿到空串——显式 `Content-Type: text/plain`。
3. **`:body` 是 InputStream，只能读一次**：读两次第二次是空流；多个中间件要看 body 就得 wrap 后回填（`wrap-restful-body` 类中间件的由来）。
4. **response 的 headers 键是小写字符串**——`assoc-in [:headers "X-Request-Count"]` 混大小写没问题（Jetty 不敏感），但**测试断言**时注意 `get-in` 匹配。
5. **Jetty 12 的 SLF4J 警告**（"No SLF4J providers were found"）：只带 API 没带实现，无害；加 logback 依赖消除。
6. **端口探测的端口数字面量**：并发测试进程撞端口——示例的 18899-18903 回退链就是为这个。
7. **`run-jetty` 返回对象别丢**：没引用就拿不到 `.stop`，脚本挂住不退。

---

上一章：[24 core.async](24-core-async.md) · 下一章：[26 Leiningen 项目实战](26-leiningen.md)
