;; ==========================================================================
;; 23_ring_web.clj - Web 开发实战：Ring
;; ==========================================================================
;; 主题：Clojure Web 的基石——Ring 抽象
;; 内容：
;;   1. Ring 模型：request/response 就是普通 map
;;   2. 手写路由（method + uri 分发）
;;   3. 中间件：自定义 wrap-counter + 标准库 wrap-params
;;   4. 纯调用测试（不起服务器就能测——Ring 的核心优势）
;;   5. 启动真实 Jetty 服务器，用 HttpURLConnection 发真请求
;;
;; 运行方式：
;;   clojure -M 23_ring_web.clj     # macOS/Linux（Clojure CLI）
;;   见 build.ps1 / build.sh           # 本教程统一验证入口
;;
;; 依赖：ring/ring-core、ring/ring-jetty-adapter（project.clj / deps.edn 已声明）
;; ==========================================================================

(ns clojure-tutorial.23-ring-web
  (:require [ring.adapter.jetty :refer [run-jetty]]
            [ring.middleware.params :refer [wrap-params]]
            [ring.util.response :refer [response not-found content-type]]
            [clojure.java.io :as io])
  (:import [java.net URL HttpURLConnection])
  ;; 注：Jetty 12 只带了 SLF4J API 没带实现，启动时会打几行
  ;; "No SLF4J providers were found" 警告，无害；生产项目里加一行
  ;; org.clojure/tools.logging + logback 依赖即可消除。
  )

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) Ring 模型 ----
;; handler：一个函数，吃 request map（一般由服务器构造），吐 response map。
;; 没有魔法、没有基类——任何满足这个签名的函数都是合法 handler。

(section 1 "the Ring model: plain maps")

(defn hello-handler [request]
  {:status 200
   :headers {"Content-Type" "text/plain"}
   :body "Hello, Ring!"})

(def fake-request
  {:request-method :get
   :uri "/"
   :query-string nil
   :body nil})

(say "Request map:" fake-request)
(say "Response map:" (hello-handler fake-request))

;; ---- 2) 手写路由 ----
;; Ring 本身不带路由：method + uri 就是两个 map 键，cond 一把就是路由。
;; ring.util.response 提供常用响应构造函数。

(section 2 "routing by hand")

(defn app [request]
  (let [{:keys [request-method uri query-params]} request]
    (cond
      (and (= request-method :get) (= uri "/"))
      (-> (response "Home: try /hello?name=X, /api/users, POST /echo")
          (content-type "text/plain"))

      (and (= request-method :get) (= uri "/hello"))
      (-> (response (str "Hello, " (get query-params "name" "World") "!"))
          (content-type "text/plain"))

      (and (= request-method :get) (= uri "/api/users"))
      (-> (response "[{\"id\":1,\"name\":\"Alice\"},{\"id\":2,\"name\":\"Bob\"}]")
          (content-type "application/json"))

      (and (= request-method :post) (= uri "/echo"))
      (-> (response (slurp (:body request)))
          (content-type "text/plain"))

      :else
      (not-found (str "No route: " (name request-method) " " uri)))))

;; 路由正确性不用起服务器，直接调用（这就是 Ring 的可测试性）：
(say "GET /        -> status:" (:status (app (assoc fake-request :uri "/"))))
(say "GET /hello   -> body:"   (:body   (app (assoc fake-request :uri "/hello"
                                                          :query-params {"name" "Clojure"}))))
(say "GET /nope    -> status:" (:status (app (assoc fake-request :uri "/nope"))))

;; ---- 3) 中间件 ----
;; 中间件 = 「吃 handler 吐 handler」的高阶函数。
;; 自定义 wrap-counter：计数请求、塞一个响应头。
;; 标准库 wrap-params：把 :query-string 解析成 :query-params。

(section 3 "middleware = decorator over handlers")

(def request-count (atom 0))

(defn wrap-counter [handler]
  (fn [request]
    (swap! request-count inc)
    (let [resp (handler request)]
      (assoc-in resp [:headers "X-Request-Count"] (str @request-count)))))

;; 组合（自内向外）：先 params 包住 app，再 counter 包住 params
(def app+ (-> app wrap-params wrap-counter))

(let [resp (app+ (assoc fake-request :uri "/hello"
                               :query-string "name=Middleware"))]
  (say "Pure call, no server! status:" (:status resp))
  (say "  body:" (:body resp))
  (say "  X-Request-Count header:" (get-in resp [:headers "X-Request-Count"])))

;; ---- 4) 真实服务器 + 真实 HTTP 请求 ----
;; run-jetty 把 Ring handler 挂到嵌入式 Jetty 上。
;; :join? false → 不阻塞当前线程（生产用 :join? true）

(section 4 "real Jetty server, real HTTP requests")

(defn http-request
  "用 JDK 自带的 HttpURLConnection 发请求，返回 {:status :body :header}。"
  [method url-str body]
  (let [^HttpURLConnection conn (doto ^HttpURLConnection (.openConnection (URL. url-str))
                                  (.setRequestMethod (.toUpperCase (name method)))
                                  (.setConnectTimeout 3000)
                                  (.setReadTimeout 3000))]
    (when body
      (.setDoOutput conn true)
      ;; 不设 Content-Type 时 HttpURLConnection 默认按表单发送
      ;;（application/x-www-form-urlencoded），wrap-params 会把 body
      ;; 解析成 :form-params 吃掉。显式声明 text/plain 保住原始 body。
      (.setRequestProperty conn "Content-Type" "text/plain")
      (with-open [w (io/writer (.getOutputStream conn))]
        (.write w ^String body)))
    (let [code (.getResponseCode conn)
          stream (if (>= code 400) (.getErrorStream conn) (.getInputStream conn))]
      {:status code
       :body (if stream (slurp stream :encoding "UTF-8") "")
       :request-count-header (.getHeaderField conn "X-Request-Count")})))

;; 端口探测：从 18899 起逐个试，避开被占用的端口
(defn start-server [app' ports]
  (some (fn [p]
          (try
            (let [s (run-jetty app' {:port p :join? false})]
              [s p])
            (catch Exception _ nil)))
        ports))

(defn stop! [[server _]] (.stop server))

(let [[server port] (start-server app+ [18899 18900 18901 18902 18903])]
  (when (nil? server) (throw (ex-info "No free port in range" {})))
  (say "Jetty started on port" port)
  (Thread/sleep 200)                         ;; 等监听就绪

  (let [r1 (http-request :get (str "http://localhost:" port "/") nil)]
    (say "GET /            status:" (:status r1))
    (say "                body:  " (:body r1)))

  (let [r2 (http-request :get (str "http://localhost:" port "/hello?name=Clojure") nil)]
    (say "GET /hello?name=Clojure status:" (:status r2))
    (say "                body:  " (:body r2)))

  (let [r3 (http-request :post (str "http://localhost:" port "/echo") "ping-echo-body")]
    (say "POST /echo       status:" (:status r3))
    (say "                body:  " (:body r3)))

  (let [r4 (http-request :get (str "http://localhost:" port "/api/users") nil)]
    (say "GET /api/users   status:" (:status r4))
    (say "                body:  " (:body r4)))

  (let [r5 (http-request :get (str "http://localhost:" port "/nope") nil)]
    (say "GET /nope        status:" (:status r5))
    (say "                body:  " (:body r5))
    (say "                X-Request-Count:" (:request-count-header r5)))

  ;; 校验：中间件对每个真实请求都生效了
  ;;（之前有 1 次纯调用 + 5 次 HTTP，这次是第 7 个计数）
  (let [r6 (http-request :get (str "http://localhost:" port "/") nil)]
    (say "7th call saw X-Request-Count:" (:request-count-header r6)))

  (stop! [server port])
  (say "Server stopped."))

;; ---- 总结 ----
(println)
(say "Takeaways:")
(say " 1. Ring = plain data in, plain data out; handlers are functions")
(say " 2. Middleware are higher-order functions composed with ->")
(say " 3. Test handlers with plain function calls, no server needed")
(say " 4. Compojure/Reitit only replace the hand-rolled routing above")
(say " 5. The same handler runs under Jetty / HTTP Kit / Pedestal")

(defn -main [& args]
  (println "")
  (println "==== 23 jieshu ===="))

(-main)
