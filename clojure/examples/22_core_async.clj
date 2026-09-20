;; ==========================================================================
;; 22_core_async.clj - core.async 并发编程
;; ==========================================================================
;; 主题：基于 CSP 模型的 core.async（Go 语言风格的 channel）
;; 内容：
;;   1. channel 与阻塞读写（>!! / <!!）
;;   2. go 块与停车读写（>! / <!）
;;   3. close! 的语义
;;   4. go-loop 工作池模式
;;   5. alts!! 多路选择与 timeout
;;   6. thread（线程版 go）
;;   7. pipeline：transducer 遇上 channel
;;   8. 缓冲策略：blocking / dropping / sliding
;;
;; 运行方式：
;;   clojure -M 22_core_async.clj     # macOS/Linux（Clojure CLI）
;;   见 build.ps1 / build.sh           # 本教程统一验证入口
;;
;; 依赖：org.clojure/core.async（已在 project.clj / deps.edn 声明）
;; ==========================================================================

(ns clojure-tutorial.22-core-async
  (:require [clojure.core.async :as a :refer [go go-loop chan >!! <!! >! <!
                                              close! timeout alts!! thread]]))

(defn say [& args] (println (apply str (interpose " " args))))
(defn section [n title]
  (println)
  (println (format "---- %d) %s ----" n title))
  (println (apply str (repeat 50 "-"))))

;; ---- 1) channel 与阻塞读写 ----
;; (chan)        无缓冲：写阻塞直到有人读
;; (chan 3)      缓冲 3 个：满了才阻塞
;; >!! / <!!     阻塞式写/读（parking 版本是 >! / <!，只能在 go 里用）

(section 1 "channel basics (blocking)")

(let [c (chan 3)]
  (>!! c :a)                                 ;; 缓冲未满，立即返回
  (>!! c :b)
  (>!! c :c)
  (say "Takes:" (<!! c) (<!! c) (<!! c)))

;; 无缓冲 channel 在同一个线程里 >!! 会死锁，示例用 thread 配合：
(let [c (chan)]
  (thread (>!! c :from-thread))              ;; 另一个线程写
  (say "Got:" (<!! c)))                      ;; 主线程读

;; ---- 2) go 块与停车读写 ----
;; go 把 body 编译成状态机，<! 停车（park）而不是阻塞线程——
;; 一个线程可以跑几万个 go 块。go 返回一个 channel，装着 body 的返回值。

(section 2 "go blocks (parking)")

(say "(<!! (go (+ 6 7))):" (<!! (go (+ 6 7))))

(let [c (chan)]
  (go (>! c (* 6 7)))                        ;; go 里写
  (say "(go (>! c 42)) then (<!! c):" (<!! c)))

(let [c1 (chan) c2 (chan)]
  (go
    (>! c2 (+ (<! c1) (<! c1))))             ;; 停车等两个值
  (>!! c1 20)
  (>!! c1 22)
  (say "20 + 22 via go pipeline:" (<!! c2)))

;; ---- 3) close! 的语义 ----
;; 关闭后：读立即返回 nil（不会阻塞、不会抛错）；写则返回 false。

(section 3 "close!")

(let [c (chan 1)]
  (>!! c :last-item)
  (close! c)
  (say "Take from closed (drains buffer):" (<!! c))
  (say "Take from closed (empty):" (<!! c))
  (say "Put to closed returns:" (>!! c :nope)))

;; go 块里的 >! / <! 同理：读写已关闭的 channel 时 go 直接返回

;; ---- 4) go-loop 工作池 ----
;; 经典模式：N 个 worker 从同一个 jobs channel 取活儿，算完把结果写回
;; results channel。channel 天然就是工作队列。

(section 4 "worker pool pattern")

(let [jobs (chan 10)
      results (chan 10)
      ;; 4 个 worker，每个都是 go-loop：循环取任务，直到 jobs 关闭
      _ (dotimes [_ 4]
          (go-loop []
            (when-some [job (<! jobs)]       ;; jobs 关闭后 <! 返回 nil → 退出
              ;; (Thread/sleep ...) 模拟干活
              (>! results (* job job))
              (recur))))]
  (doseq [job (range 1 11)]
    (>!! jobs job))
  (close! jobs)
  ;; 已知有 10 个结果，按顺序收齐（顺序不定，排序后打印）
  (say "Squares of 1..10 from 4 workers:"
       (sort (repeatedly 10 #(<!! results))))
  (close! results))

;; ---- 5) alts!! 多路选择 ----
;; 同时等多个 channel，谁先就绪用谁。返回 [值 端口]。
;; 配合 timeout channel 可以实现"限时等待"。

(section 5 "alts!! and timeout")

(let [slow (chan)
      fast (chan)]
  (thread (Thread/sleep 60) (>!! slow :slow))
  (thread (>!! fast :fast))
  (let [[v port] (alts!! [slow fast])]
    (say "Winner value:" v "(expected :fast, the other one sleeps 60ms)")))

(let [never (chan)]                          ;; 没人写的 channel
  (let [t (timeout 80)
        [v port] (alts!! [never t])]         ;; 80ms 内 never 不会有数据
    (say "Timed out? value nil:" (nil? v)
         "| winner is timeout chan:" (= port t))))

;; ---- 6) thread ----
;; go 块适合"等待多、计算少"的协调逻辑；真正会阻塞（IO）或吃 CPU 的活儿
;; 放到 thread 里。thread 返回 channel，行为类似 future。

(section 6 "thread (blocking work)")

(say "(<!! (thread (do (Thread/sleep 10) :done))):"
     (<!! (thread (do (Thread/sleep 10) :done))))

;; ---- 7) pipeline ----
;; (pipeline n out xf in)：从 in 读，过 transducer xf，写进 out。
;; transducer 与 channel 在这里会师——同一套 (map inc) 既可用于序列也可用于流。

(section 7 "pipeline + transducers")

(let [in (chan 10)
      out (chan 10)]
  (a/pipeline 4 out (map inc) in)            ;; 4 并发过 xf
  (thread
    (doseq [x (range 5)]
      (>!! in x))
    (close! in))                             ;; in 关闭会传播：out 也被关闭
  (say "pipeline (map inc) over 0..4:"
       (sort (take 5 (repeatedly #(<!! out))))))

;; ---- 8) 缓冲策略 ----
;; (chan n)               固定缓冲，满则写阻塞（背压 backpressure）
;; (dropping-buffer n)    满则丢新
;; (sliding-buffer n)     满则丢旧
;; 传感器/日志/行情这类场景，丢数据反而比阻塞健康。

(section 8 "buffer strategies")

(let [c (chan (a/dropping-buffer 2))]        ;; 留前 2 个，丢后面的
  (doseq [x [1 2 3 4 5]] (>!! c x))
  (say "dropping-buffer keeps:" (<!! c) (<!! c) "| more?" (some? (a/poll! c))))

(let [c (chan (a/sliding-buffer 2))]         ;; 丢前面的，留最新 2 个
  (doseq [x [1 2 3 4 5]] (>!! c x))
  (say "sliding-buffer keeps:" (<!! c) (<!! c) "| more?" (some? (a/poll! c))))

;; ---- 总结 ----
(println)
(say "Takeaways:")
(say " 1. chan/go/go-loop cover most coordination needs")
(say " 2. Blocking ops (!! outside go) for simple scripts; parking (!) inside go")
(say " 3. close! + nil is the standard shutdown signal")
(say " 4. alts!/alts!! to multiplex; timeout for deadlines")
(say " 5. go parks (cheap), thread blocks (for real IO/CPU work)")
(say " 6. pipeline bridges transducers and channels")

(defn -main [& args]
  (println "")
  (println "==== 22 jieshu ===="))

(-main)
