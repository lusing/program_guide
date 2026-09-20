# 24 · core.async ⭐

> 对应示例：`examples/22_core_async.clj`
> 依赖：`org.clojure/core.async`（project.clj / deps.edn 已声明）

> 把 Go 的 CSP 模型搬进 Clojure：**靠 channel 传值通信，不靠锁共享内存**。
> go 块停车让线程去干别的——一个线程跑一万个"协程"。

## 24.1 channel 基础

```clojure
(require '[clojure.core.async :as a :refer [go go-loop chan >!! <!! >! <! close! timeout alts!! thread]])

(chan)          ; 无缓冲：写等读（会合）
(chan 3)        ; 缓冲 3：满了写才阻塞
(>!! c 42)      ; 阻塞写（!! = blocking，普通线程用）
(<!! c)         ; 阻塞读
(a/poll! c)     ; 非阻塞读：没数据立即 nil
(a/offer! c 1)  ; 非阻塞写：放不进立即 false
```

**死锁警告**：无缓冲 channel 同一线程先 `>!!` 后 `<!!` = 永久卡死（写的那个人就是该读的人）——写读必须分处不同执行体（thread/go）。

## 24.2 go 块：停车（parking）

```clojure
(<!! (go (+ 6 7)))               ; => 13    go 返回装结果的 channel
(let [c (chan)]
  (go (>! c (* 6 7)))            ; go 里用 >! / <!（停车版）
  (<!! c))                       ; => 42
```

`go` 把 body 编译成**状态机**：`<!` 等不到就"停车"——当前线程被释放去跑别的 go 块，值到了再恢复。**线程不阻塞**（blocking 才占线程），一个 CPU 线程可承载海量 go 块。

停车版（`!`）与阻塞版（`!!`）必须配对用对地方：**go 块内 `!`，普通线程 `!!`**——写反会异常或破坏调度。

## 24.3 close!：流结束信号

```clojure
(>!! c :x) (close! c)
(<!! c)       ; => :x     先排空缓冲
(<!! c)       ; => nil    空了以后：立即 nil，不阻塞不抛错
(>!! c :y)    ; => false  写已关闭 channel：返回 false（不抛！）
```

`nil` 成为"流结束"约定 → 消费端惯用 `(when-some [v (<! c)] ...)`。**生产者关闭、消费者不关**是产权惯例（谁生产谁负责收官）。

## 24.4 go-loop 工作池 ⭐

N 个 worker 消费同一个 jobs channel——channel 就是线程安全任务队列：

```clojure
(let [jobs (chan 10) results (chan 10)]
  (dotimes [_ 4]                          ; 4 个工人
    (go-loop []
      (when-some [job (<! jobs)]          ;; close! 后 <! 得 nil → 工人自然退场
        (>! results (* job job))
        (recur))))
  (doseq [job (range 1 11)] (>!! jobs job))
  (close! jobs)
  (sort (repeatedly 10 #(<!! results))))  ; 收齐排序 => (1 4 9 ... 100)
```

结构读法：`go-loop` = "常驻循环工人"；`close!` = "下班铃"；结果顺序不定（并发），要确定性就 sort 或按 ID 对齐。

## 24.5 alts!!：多路选择

```clojure
(let [slow (chan) fast (chan)]
  (thread (Thread/sleep 60) (>!! slow :slow))
  (thread (>!! fast :fast))
  (let [[v port] (alts!! [slow fast])]     ; 谁先就绪用谁
    v))                                    ; => :fast

;; 限时等待：timeout 是一次性 channel
(let [never (chan)
      t (timeout 80)
      [v port] (alts!! [never t])]
  [(nil? v) (= port t)])                   ; => [true true]  等到超时

(alts!! [c1 c2] :default :none)            ; 都没就绪：不等待，给默认
```

go 块里用 `alts!`。返回 `[值 端口]`——**端口身份**告诉你数据从哪来（比较 `= port c1`）。

## 24.6 thread：真正的阻塞活儿

```clojure
(<!! (thread (do (Thread/sleep 10) :done)))   ; => :done
```

| | `go` | `thread` |
|---|---|---|
| 等待方式 | 停车（不占线程） | 阻塞线程（独占） |
| 适合 | channel 编排、等待多 | 阻塞 IO（JDBC/HTTP/文件）、CPU 密集 |
| 池 | 少量 dispatcher 线程 | 独立线程 |

**规则**：go 块里别写阻塞调用（Thread/sleep、IO）——会把 dispatcher 线程堵死，殃及所有 go 块。IO 活儿丢给 `thread`，结果走 channel 回来。

## 24.7 pipeline：transducer 会师

```clojure
(let [in (chan 10) out (chan 10)]
  (a/pipeline 4 out (map inc) in)          ; 4 并发过 (map inc)
  (thread (doseq [x (range 5)] (>!! in x)) (close! in))
  (sort (take 5 (repeatedly #(<!! out))))) ; => (1 2 3 4 5)
```

20 章的 transducer 原样进 channel 世界——`(map inc)` 一字不改。`pipeline` 关闭 in 会传播关闭 out（流结束级联）。

## 24.8 缓冲策略：背压 or 丢弃

| 缓冲 | 满了以后 | 场景 |
|---|---|---|
| `(chan n)` | 写阻塞（**背压**：逼上游减速） | 生产消费速率要匹配 |
| `(dropping-buffer n)` | 丢**新**来的 | 采样：旧的更有价值 |
| `(sliding-buffer n)` | 丢**旧的** | 行情/日志：最新才有价值 |

```clojure
(let [c (chan (dropping-buffer 2))]
  (doseq [x [1 2 3 4 5]] (>!! c x))
  [(<!! c) (<!! c) (a/poll! c)])           ; => [1 2 nil] 留前丢后

(let [c (chan (sliding-buffer 2))]
  (doseq [x [1 2 3 4 5]] (>!! c x))
  [(<!! c) (<!! c)])                       ; => [4 5] 留最新
```

默认 `(chan n)` 的阻塞是**特性**（背压）不是缺陷——上游失控时系统自然降速，比丢数据安全。

## 24.9 坑位清单

1. **go 块里写阻塞调用**（`Thread/sleep`/JDBC/文件 IO）→ dispatcher 线程被堵，全部 go 块卡顿——阻塞活儿进 `thread`。
2. **`!!` 用在 go 里 / `!` 用在普通线程**——类型/运行时错。记忆：go 里全用单 `!`。
3. **忘了 close! jobs**：worker 的 `when-some` 永远等不到 nil，泄漏常驻 go 块。
4. **结果顺序想当然**：并发生产的结果顺序**不保证**——打印前 sort 或用 ID 映射。
5. **从已关闭 channel 写不抛错**（返回 false）——批量写不检查返回值会静默丢数据；关键路径检查 `(>!! c v)` 的返回。
6. **`alts!!` 两个都就绪**：随机挑一个——别依赖优先级；要优先级用嵌套判断或 `priority-map` 自己排。
7. **忘记消费**：有缓冲 channel 写满前看似"能跑"——背压延迟爆发；测试覆盖生产速率 > 消费速率的场景。

---

上一章：[23 性能与优化](23-performance.md) · 下一章：[25 Web 开发实战：Ring](25-ring-web.md)
