# 24 · SBCL 扩展 II：线程（sb-thread）

> 配套示例：[`examples/24_sbcl_threads/`](../examples/24_sbcl_threads/main.lisp)（channel: sbcl）
>
> 示例是本目录最大的一个（九节全跑通）：创建/管理、互斥锁、条件变量、
> 信号量、屏障、线程本地存储、原子操作、并发模式（生产者消费者 + 线程池）。

## 24.1 创建与管理

```lisp
(sb-thread:thread-name sb-thread:*current-thread*)    ; => "main thread"
(let ((th (sb-thread:make-thread (lambda () 42) :name "worker")))
  (list (sb-thread:join-thread th)          ; => 42   等 worker 结束并取结果
        (sb-thread:thread-alive-p th)))     ; => NIL  join 之后已结束
```

**纪律一：线程必须 `join`，不能用 `(sleep N)` 代替。** 主线程跑完就退出，
没 join 的线程可能还在打印——输出缺内容甚至缺结束标记。线程池的 shutdown
也不能只看标志位就 return（会丢队列里没跑完的任务），要「取不到任务才退出」
然后 join。

**纪律二：多线程打印必须自己加锁。**

```lisp
(defvar *print-lock* (sb-thread:make-mutex :name "print-lock"))
(defun say (fmt &rest args)
  (sb-thread:with-mutex (*print-lock*)
    (apply #'format t fmt args)
    (finish-output)))
```

多个线程直接 `(format t ...)` 会互相穿插——一次 format 按指令**拆成多次写**，
SBCL 写多字节汉字还会分块，一个汉字的字节能被两个线程各写走一半——
stdout 里出现**非法 UTF-8**（本仓库实测抓到过）。**所有**输出（含主线程）
都走 `say`；锁序保持单向（其它锁 → 打印锁）就不会死锁。

并发程序的输出顺序天然不确定——关键结论写成**与调度无关的汇总**：
计数、排序后的列表、`(<= 峰值 上限)` 这类布尔断言（示例 24 的做法）。

## 24.2 互斥锁

```lisp
(sb-thread:with-mutex (lock) ...)          ; 获取-执行-释放
(sb-thread:grab-mutex lock :waitp nil)     ; 非阻塞尝试
```

**坑（实测）**：`grab-mutex` 不可重入——同一线程再锁（哪怕 `:waitp nil`）
是**报错**不是返回 NIL。判断持有情况用 `sb-thread:holding-mutex-p` /
`sb-thread:mutex-owner`。

## 24.3 条件变量：生产者-消费者全码

```lisp
(sb-thread:make-waitqueue :name "not-empty")     ; CLISP 里叫 condition variable
;; 等待/通知必须在持锁下进行；condition-wait 原子地「放锁睡着」，
;; 醒来时锁已回到手里
```

示例 24 的完整实现（骨架）：

```lisp
(let ((queue '())
      (lock (sb-thread:make-mutex))
      (not-empty (sb-thread:make-waitqueue))
      (finished nil))
  ;; 消费者：醒来后要**循环**重查条件（while 不是 if——防虚假唤醒）
  (let ((consumer (sb-thread:make-thread
                   (lambda ()
                     (loop
                       (sb-thread:with-mutex (lock)
                         (loop while (and (null queue) (not finished))
                               do (sb-thread:condition-wait not-empty lock))
                         (when (and (null queue) finished) (return))
                         (say "  消费: ~A" (pop queue))))))))
    ;; 生产者：push 后 notify；结束时置标志并 broadcast（叫醒所有等待者）
    (let ((producer (sb-thread:make-thread
                     (lambda ()
                       (dotimes (i 10)
                         (sb-thread:with-mutex (lock)
                           (push i queue)
                           (sb-thread:condition-notify not-empty)))
                       (sb-thread:with-mutex (lock)
                         (setf finished t)
                         (sb-thread:condition-broadcast not-empty))))))
      (sb-thread:join-thread producer)
      (sb-thread:join-thread consumer))))
```

四个记忆点：`condition-wait` 必须持锁调用；等待条件用 `while` 循环重查；
结束时 `broadcast`（叫醒所有等「空了」的消费者让它们各自判断退出）；
结论汇总只输出确定性数字（生产/消费计数）。

## 24.4 信号量与屏障

```lisp
(sb-thread:make-semaphore :count 0)
(sb-thread:wait-on-semaphore sem)
(sb-thread:signal-semaphore sem)
(sb-thread:make-barrier n) / (sb-thread:wait-on-barrier b)
```

屏障凑齐 n 个线程一起放行（fork-join 模式）；**要 join**——示例里屏障一节
最初版本靠 `(sleep 2)` 赌线程跑完，实测能「提前走」，收集句柄统一 join 后才稳。

## 24.5 线程本地存储与原子操作

```lisp
(defparameter *tls* nil)
(sb-thread:make-thread (lambda () (setf *tls* :worker值)))   ; 动态绑定天然线程本地
(sb-ext:atomic-incf place)      ; 原子自增（place 须是 (unsigned-byte 64) 槽）
```

无锁计数用 `atomic-incf`；复杂的用 CAS（23 章）。注意「读-改-写」三步的
代码必须拿锁，原子操作只保护单条。

## 24.6 并发模式实战（示例第 8 节）

**线程池**（完整可跑版在示例里，骨架与关键坑）：

```lisp
(defun make-pool (num-workers)
  ;; worker 循环体（关键部分）：
  ;;   持锁 → 等到「有任务 或 已 shutdown」→ 取任务 → 放锁
  ;;   有任务就执行；取不到任务 = 队列已空且已 shutdown → 退出
  ...)
(defun pool-submit (pool task) ... )    ; 持锁 push + notify
(defun pool-shutdown (pool)
  ;; 持锁置 shutdown + broadcast，然后 JOIN——返回时队列真的排空了
  ...)
```

**坑（修订史上的真实 bug）**：worker 的退出条件必须是「队列空**且**已
shutdown」，不能只判断 shutdown 就 return——那样 shutdown 一到，队列里
还没跑的任务会被直接丢掉。正确顺序：先取任务（取不到才是真空了），
有任务干活，没任务才退出。这样 shutdown 之后**不需要 sleep 等待**，直接 join。

**并行 map**：把列表切块，每块一个线程，结果按下标写进预分配向量，
join 全部后聚合——分块数固定（不是每元素一个线程），开销可控。

## 24.7 可移植替代

**bordeaux-threads** 把这些原语包成跨实现 API（Quicklisp 一装）：
`bt:make-thread` / `bt:with-lock-held` / `bt:condition-notify`…
底层按 `*features*` 挑 SB-THREAD / CLISP 线程 / 其它。写业务并发优先用它，
SB-THREAD 留给需要原子操作、屏障这类高级原语的场合。

CLISP 自带线程（`MT` 模块，构建选项 `--with-threads`；本机构建未含）——
API 面不同，又一例「并发代码走可移植层」的理由。

## 24.8 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 输出乱序/非法 UTF-8 | 多线程直接 format | 打印锁 say + finish-output |
| 输出缺内容 | 线程没 join | 全部 join；池要排空再 join |
| Recursive lock attempt 报错 | grab-mutex 不可重入 | holding-mutex-p 判断 |
| 屏障后结果不全 | sleep 赌时序 | 收集句柄统一 join |
| 计数偶发偏小 | 读-改-写没加锁 | 互斥锁或 atomic-incf |
| 直接打印线程对象 | tid/状态每次不同 | 打 `(type-of th)` 等稳定字段 |
