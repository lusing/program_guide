# 14 · 并发与引用类型 ⭐

> 对应示例：`examples/12_concurrency.clj`

> Clojure 的答案不是"加锁小心点"，而是把可变状态圈进**四种引用类型**，
> 各管一摊：atom 独立值、ref 协调多值、agent 异步、future 并行计算。
> 不可变数据（05 章）是这一切的地基——值不会被偷改，要操心的只剩"引用指向谁"。

## 14.1 心智模型：身份 × 时间 × 值

```
(def balance (atom 1000))     身份 = atom 这个"容器"
@balance                      现在 => 1000     deref = "此刻指向的值"
(swap! balance + 200)         时间前进：基于旧值算新值，原子替换
```

读永远不加锁（拿到的是某个完整版本，绝不会是改了一半）；写走 compare-and-swap 循环。**没有"锁保护下的临界区"这种心智负担**。

## 14.2 atom：独立值的原子更新 ⭐

```clojure
(def counter (atom 0))

(swap! counter inc)             ; => 1   读-改-写，原子
(swap! counter + 10)            ; => 11
(reset! counter 100)            ; 无视旧值直接设
@counter                        ; => 100  （deref counter 的简写）

(compare-and-set! counter 100 999)   ; => true  CAS：旧值对得上才设（乐观并发原语）
```

`swap!` 语义三要点：

1. **函数必须纯**：`swap!` 可能**重试**（多线程竞争时 CAS 失败重来）——函数跑多次，副作用会翻倍！
2. 返回**新值**（不是旧值）。
3. 更新过程其他线程看到的是旧值或新值，**绝无中间态**。

```clojure
;; 经典竞态演示：1000 次 inc 并发跑
(def c (atom 0))
(dotimes [_ 10] (future (dotimes [_ 1000] (swap! c inc))))
;; 等全部完成后 @c => 1000  —— swap! 保证不丢更新
;; 对照：Java 的 i++ 在同场景会丢（读和写之间被插队）
```

### validator 与 watcher：atom 的护栏

```clojure
(def acct (atom 1000 :validator pos?))       ; validator：新值不合法 → 抛异常、状态不变
(reset! acct -1)                              ; IllegalStateException

(add-watch acct :log                          ; watcher：每次成功变更回调
  (fn [k ref old new] (println old " -> " new)))
```

validator 是"写入口契约"，watcher 是"变更订阅"——观察者模式两行搞定。

## 14.3 ref + dosync：多值协调（STM）

atom 管不住"两个值必须一起变"——转账（A 减、B 加，不能只发生一半）。这是 **STM（软件事务内存）** 的主场：

```clojure
(def account-a (ref 1000))
(def account-b (ref 500))

(defn transfer [from to amount]
  (dosync                                  ; 事务：块内对 ref 的修改要么全成要么全弃
    (alter from - amount)                  ; alter：事务内"读-改-写"
    (alter to + amount)))

(transfer account-a account-b 200)
[@account-a @account-b]                    ; => [800 700]

(ref-set account-a 0)                      ; 事务内直接设值（也要在 dosync 里）
```

- 事务冲突（别的事务动了同一 ref）→ **自动重试**整个 dosync——块内代码同样要纯、要可重跑。
- `ensure`：预读加读锁，减少写冲突（`dosync` 里先 `(ensure ref)` 再算）。
- `commute`：可交换的更新（+/- 这类顺序无关的操作），冲突时不用重跑、只需重放函数——吞吐更高。
- **dosync 里别放不可重试的副作用**（网络调用、IO）——重试会执行多次；副作用挪到事务外或用 agent 收集。

**选型**：单值独立变 → atom；多值必须一致变 → ref。日常 95% 是 atom。

## 14.4 agent：异步更新的"信箱"

```clojure
(def log (agent []))

(send log conj :event-1)          ; 异步：把 (conj @log :event-1) 排队执行，立即返回
(send log conj :event-2)          ; 排队——严格按提交顺序执行（无竞态）
(await log)                       ; 等它跑完（测试用；生产少用）
@log                              ; => [:event-1 :event-2]

(send-off log save-to-disk)       ; 阻塞型 IO 用 send-off（独立线程池，不堵计算池）
```

agent = "独占执行队列 + 一个值"。所有更新串行排队——**把并发写变成排队写**，日志、指标上报、写文件的天然模型。失败处理：`(agent-error log)` 查异常，`restart-agent` 复位。

## 14.5 future / promise：并行计算

```clojure
(def result (future (Thread/sleep 100) (+ 1 2)))   ; 提交线程池立即返回
@result                                             ; => 3  阻塞等结果
(deref result 50 :timeout)                          ; 限时 deref，超时给默认

(def p (promise))                                   ; promise：先建"空槽"
(deliver p 42)                                      ; 别处填值（只能一次）
@p                                                  ; => 42  填之前 deref 阻塞
```

- future = "并行算 + 等收账"（eager）；promise = "跨线程传值的一次性管道"（手动 deliver）。
- `future` 内抛异常在 deref 时**重新抛出**——异常不会凭空消失。

## 14.6 并行 map：pmap

```clojure
(pmap #(* % %) (range 100))       ; 语义同 map，但分块并行（nproc + 2 并发）
(doall (pmap slow-job items))     ; CPU 密集任务并行化的最短路径
```

半惰性（chunk 级并行）。适合"任务重、数量中等"；任务极小的话调度开销反噬（23 章）。

## 14.7 四种引用类型一张表

| 类型 | 协调 | 同步性 | 典型场景 | 更新原语 |
|---|---|---|---|---|
| `atom` | 独立 | 同步（CAS 重试） | 计数器、缓存、配置 | `swap!` `reset!` |
| `ref` | **多值协调（STM）** | 同步（事务） | 转账、库存+订单 | `alter` `ref-set` `commute`（dosync 内） |
| `agent` | 独立 | **异步**（串行队列） | 日志、落盘、指标 | `send` `send-off` |
| `future` | — | eager + 阻塞读 | 并行计算 | `deref` |
| `promise` | — | 手动填值 | 线程间传值/回调 | `deliver` |

## 14.8 坑位清单

1. **`swap!`/`alter` 的函数必须纯**：重试语义下副作用会重复执行——`swap!` 里 `println`/发请求是经典事故；先算好结果再 `reset!`，或用 agent 承接副作用。
2. **dosync 里做 IO**：事务重试 = IO 重复执行。模式：事务内算决策，事务外执行副作用。
3. **`@ref` 在 dosync 外**读到的是"某一刻的快照"，多个 `@` 之间不保证一致——要一致快照必须在同一个 dosync 里读。
4. **忘记 deref**：`(str balance)` 打出 `#object[clojure.lang.Atom ...]`——到处要用 `@`；反过来 `(if @balance ...)` 时把 atom 值当集合用（04 章真值）。
5. **promise 无人 deliver = 永久阻塞**：跨线程交付要有超时或兜底（`deref p 1000 ::timeout`）。
6. **agent 异常会"冻住"后续任务**：agent 出错后默认不再执行后续 send——测试时 `await` 后查 `agent-error`。
7. **pmap 小任务负优化**：并行有分块/调度成本；先 `time` 后上 pmap（23 章基准方法）。

---

上一章：[13 记录与协议](13-records-protocols.md) · 下一章：[15 Java 互操作](15-java-interop.md)
