;; ==========================================================================
;; 12_concurrency.clj - 并发与引用类型
;; ==========================================================================
;; 主题：Clojure 的并发原语与引用类型
;; 内容：
;;   1. atom（原子引用）
;;   2. ref / dosync（STM 软件事务内存）
;;   3. agent（异步代理）
;;   4. future（延迟执行）
;;   5. promise / deliver
;;   6. pmap（并行映射）
;;   7. 线程
;;
;; 运行方式：
;;   clojure -M 12_concurrency.clj
;; ==========================================================================

(ns clojure-tutorial.12-concurrency)

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) atom（原子引用）----
;; atom 是最常用的引用类型
;; 适合单值的独立同步更新
;; swap! 函数式更新：接收旧值，返回新值

(section 1 "atom")

(def counter (atom 0))

(say "Initial @counter:" @counter)
(swap! counter inc)
(say "After (swap! counter inc):" @counter)
(swap! counter + 5)
(say "After (swap! counter + 5):" @counter)
(say "reset! to 100:" (do (reset! counter 100) @counter))

;; compare-and-set!：条件设置
(say "compare-and-set! (100 99):"
     (compare-and-set! counter 100 99) @counter)

;; swap-vals!：返回旧值和新值
(let [[old new] (swap-vals! counter inc)]
  (say "swap-vals! old:" old "new:" new "current:" @counter))

;; atom 的实际应用：缓存
(def cache (atom {}))
(defn cached [key compute-fn]
  (if-let [v (get @cache key)]
    v
    (let [v (compute-fn)]
      (swap! cache assoc key v)
      v)))

(say "(cached :x (fn [] (rand-int 100))):" (cached :x (fn [] (rand-int 100))))
(say "(cached :x (fn [] (rand-int 100))) again:" (cached :x (fn [] (rand-int 100))))

;; ---- 2) ref / dosync（STM）----
;; ref 用于协调多个引用的同步更新
;; dosync 创建事务，保证 ACI（原子性、一致性、隔离性）
;; alter 函数式更新，commute 乐观更新

(section 2 "ref / dosync (STM)")

(def account-a (ref 1000))
(def account-b (ref 500))

(say "Account A:" @account-a)
(say "Account B:" @account-b)

;; 转账事务
(defn transfer [from-ref to-ref amount]
  (dosync
   (alter from-ref - amount)
   (alter to-ref + amount)))

(transfer account-a account-b 200)
(say "After transfer A->B 200:")
(say "  Account A:" @account-a)
(say "  Account B:" @account-b)

;; commute：乐观更新，性能更好但不保证顺序
(def scores (ref {:alice 0 :bob 0}))
(dosync
  (commute scores assoc :alice (inc (:alice @scores))))
(say "Scores:" @scores)

;; ---- 3) agent（异步代理）----
;; agent 用于异步更新
;; send 在线程池中执行
;; send-off 在单独线程中执行
;; @ 或 await 获取结果

(section 3 "agent")

(def logger (agent []))

;; send 异步添加日志
(send logger conj "Log entry 1")
(send logger conj "Log entry 2")
(send logger conj "Log entry 3")

;; 等待 agent 完成
(await logger)
(say "Logger @agent:" @logger)

;; agent 可以有验证器
(def validated (agent 0
                       :validator (fn [v] (and (number? v) (>= v 0)))))
(send validated + 10)
(await validated)
(say "Validated agent:" @validated)

;; ---- 4) future（延迟执行）----
;; future 在另一个线程中执行，返回引用
;; @ 获取结果（阻塞直到完成）
;; future-done? 检查是否完成

(section 4 "future")

(def slow-result (future (Thread/sleep 100) (+ 1 2 3)))

(say "future-done? (immediately):" (future-done? slow-result))
(say "@slow-result (blocks):" @slow-result)
(say "future-done? (after deref):" (future-done? slow-result))

;; 多个 future 并行计算
(def futures (for [i (range 5)]
               (future
                 (Thread/sleep 50)
                 (* i i))))

(say "Results:" (vec (map deref futures)))

;; future-call 是 future 的底层实现
(def f (future-call (fn [] "computed asynchronously")))
(say "@future-call:" @f)

;; ---- 5) promise / deliver ----
;; promise 创建一个 promise，等待 deliver
;; @ 会阻塞直到有值
;; 适合线程间同步

(section 5 "promise / deliver")

(def result (promise))
(future
  (Thread/sleep 50)
  (deliver result "Delivered!"))

(say "Waiting for promise..." )
(say "@result (blocks until deliver):" @result)

;; promise 的超时处理
(def p (promise))
(def timeout (future
               (Thread/sleep 1000)
               (deliver p "timeout value")))
;; 这里会立即返回，因为 timeout 线程会 deliver
(say "Promise result:" @p)

;; ---- 6) pmap（并行映射）----
;; pmap 在多线程上并行执行 map
;; 适合 CPU 密集型操作

(section 6 "pmap")

(defn slow-compute [x]
  (Thread/sleep 10)
  (* x x))

(def data (range 1 10))

;; 串行
(let [start (System/nanoTime)
      _ (doall (map slow-compute data))
      end (System/nanoTime)]
  (say "Serial time (ms):" (int (/ (- end start) 1000000))))

;; 并行
(let [start (System/nanoTime)
      _ (doall (pmap slow-compute data))
      end (System/nanoTime)]
  (say "Parallel time (ms):" (int (/ (- end start) 1000000))))

(say "pmap results:" (vec (pmap slow-compute data)))

;; ---- 7) 线程 ----
;; Clojure 可以直接创建 Java 线程
;; .start / .join

(section 7 "Threads")

(def shared-counter (atom 0))

(def threads
  (for [_ (range 5)]
    (Thread. (fn []
               (dotimes [_ 1000]
                 (swap! shared-counter inc))))))

(doseq [t threads] (.start t))
(doseq [t threads] (.join t))

(say "Shared counter (5000 expected):" @shared-counter)

;; shutdown-agents 关闭 agent 线程池
(shutdown-agents)

(defn -main [& args]
  (println "")
  (println "==== 12 jieshu ===="))

(-main)
