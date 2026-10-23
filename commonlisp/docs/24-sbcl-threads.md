# 24 · SBCL 线程：sb-thread 与 sb-concurrency

> 配套示例：[`examples/24_sbcl_threads/`](../examples/24_sbcl_threads/main.lisp)（channel: sbcl）
>
> 本章全部基于 SBCL 2.6.9 实测。手册第 13 章（Threading）与 sb-concurrency
> contrib 的核心内容已提炼在本章内，自包含，无需另查原文。

## 24.1 线程模型：一个 Lisp 线程 = 一个 OS 线程

SBCL 的线程接口是**低层**的：每个 Lisp 线程直接映射到宿主操作系统的一个
线程（轻量进程）。这带来两个直接推论：

- 多核机器上线程可以**真正并行**地跑在不同 CPU 上；
- Lisp 层**无法控制调度器**——谁先跑、跑多久，全由操作系统决定。你的代码
  必须对任意交错顺序都正确。

接口都在 `sb-thread` 包里。x86-64 Darwin（本机平台）上线程**不是默认开启**
的，编译 SBCL 时要显式加 `--with-sb-thread`（Linux/Windows 上是默认的）。
判断当前镜像有没有线程支持，查特性关键字：

```lisp
(and (member :sb-thread *features*) t)   ; => T（有线程支持时非 NIL；member 返回的是子串，外面包一层取布尔）
```

本章假设线程已启用（23 章介绍的自编译命令里带了 `--with-sb-thread`）。

## 24.2 创建与回收：make-thread 与 join-thread

```text
(sb-thread:make-thread 函数 &key name arguments)
```

`函数` 在新线程里被调用，线程在函数返回时结束。`:name` 给个名字（调试时
打印线程对象会带上）；`:arguments` 是传给函数的参数列表（designator，可以
是单个非列表值）。函数的返回值会被**保存**，由 `join-thread` 取回：

```lisp
(let ((th (sb-thread:make-thread (lambda () (+ 1 2)) :name "adder")))
  (sb-thread:join-thread th))     ; => 3   阻塞等它结束，拿回返回值
```

`sb-thread:make-thread` 会给新线程建立一个初始的 `abort` restart；在新
线程里调用它会终止该线程（回到「未运行」状态），主线程里的 `abort` 行为
则取决于 toplevel 配置。

### 24.2.1 join-thread 的全部语义

```text
(sb-thread:join-thread thread &key default timeout)
```

四种结局，规则要记全：

1. **正常结束**：返回线程函数的值（多值也原样返回）。
2. **超时**（`:timeout` 秒内没结束）：给了 `:default` 就返回两个值
   `default` 和 `:timeout`；没给就报 `join-thread-error`。
3. **异常终止**（线程被 abort）：给了 `:default` 就返回 `default` 和
   `:abort` 两个值；没给就报 `join-thread-error`。
4. **join 自己**：直接报 `join-thread-error`（`:self-join`）。

用 `nth-value` 取第二返回值可以区分超时与异常：

```lisp
(let ((th (sb-thread:make-thread (lambda () (sleep 30)))))
  (list (sb-thread:join-thread th :timeout 0.1 :default :too-slow)
        (nth-value 1 (sb-thread:join-thread th :timeout 0.1 :default :too-slow))))
                                        ; => (:TOO-SLOW :TIMEOUT)
```

（上面那个线程还在睡，进程退出时它会随之消失；后面的例子不再留这种尾巴。）

注意 join **主线程**会阻塞到超时或进程退出——主线程一退整个进程就没了。
另外不要从多个线程同时 join 同一个线程，手册明确说这是未定义行为。

### 24.2.2 查询与改名

```lisp
sb-thread:*current-thread*            ; 每线程绑定为自己
(sb-thread:thread-name sb-thread:*current-thread*)    ; => "main thread"
(sb-thread:main-thread-p)             ; => T   在文件顶层当然是主线程
(sb-thread:list-all-threads)          ; 所有活线程的列表（可能立刻过时）
```

`thread-name` 可 `setf`；`thread-alive-p` 与 `list-all-threads` 的返回值
**拿到手就可能已经过时**（线程随时会结束），只适合展示和调试，不要据此做
同步决策。`sb-thread:thread-yield` 主动让出 CPU，基本只用于测试。

还有一对「提前结束自己」的函数：`sb-thread:return-from-thread`（带值正常
退出，值对 `join-thread` 可见）和 `sb-thread:abort-thread`（异常退出，
`join-thread` 收到 `:abort`）。对**主线程**调用这两个默认报错——主线程
一退进程就没了；加 `:allow-exit t` 则等价于 `sb-ext:exit`。

## 24.3 特殊变量的线程语义：绑定不继承

规则只有三条：

- 全局特殊值对所有线程可见；
- `let` 等建立的**动态绑定**是线程本地的；
- **新线程不继承父线程的动态绑定。**

第三条最容易踩。下面的代码打印 `0` 而不是 `1`，因为新线程看到的是全局值：

```lisp
(defparameter *x24* 0)
(let ((*x24* 1))
  (sb-thread:join-thread
   (sb-thread:make-thread (lambda () *x24*))))       ; => 0  不是 1！
```

想让 worker 拿到父线程的某个绑定，必须显式传参，在它自己的函数里重新
`let`。另外线程构建里对「可动态绑定的不同符号数」有硬上限（启动参数
`--tls-limit`），超过会掉进 LDB 报 `Thread local storage exhausted`——
正常代码碰不到，代码生成器海量绑定时才需要调大。

## 24.4 互斥锁（mutex）

```text
(sb-thread:make-mutex :name "queue-lock")   ; 名字仅供打印/调试
(sb-thread:with-mutex (lock &key wait-p timeout) &body body)
```

`with-mutex` 在 body 的动态范围内持锁。要点：

- `wait-p` 为 T（默认）时拿不到锁就睡等到拿到为止；为 NIL 时拿不到就
  **不执行 body，整个宏返回 NIL**；
- `:timeout` 给相对秒数，超时同样返回 NIL（body 不执行）；
- 成功拿到则执行 body 并返回 body 的值。

用超时做一次「试试抢锁」的实测——主线程先占住，worker 限时 0.05 秒抢同
一把，必然超时返回 NIL：

```lisp
(let ((m (sb-thread:make-mutex)))
  (sb-thread:grab-mutex m)
  (let ((th (sb-thread:make-thread
             (lambda ()
               (sb-thread:with-mutex (m :timeout 0.05) :got-it)))))
    (prog1 (sb-thread:join-thread th)
      (sb-thread:release-mutex m))))   ; => NIL   没抢到，body 没执行
```

**SBCL 的 mutex 不可重入**：同一线程对已持有的锁再次 `with-mutex` /
`grab-mutex`（哪怕 `:waitp nil`）不是返回 NIL，而是直接报
`Recursive lock attempt` 错误：

```lisp
(let ((m (sb-thread:make-mutex)))
  (sb-thread:with-mutex (m)
    (sb-thread:with-mutex (m :wait-p nil) :again)))   ; 会报错：不可重入
```

真要可重入（递归函数每层都想进临界区），换 `with-recursive-lock`（关键字
同样是 `wait-p`/`timeout`）。想检查持有状态而不是试探加锁：

```lisp
(let ((m (sb-thread:make-mutex)))
  (sb-thread:with-mutex (m)
    (list (sb-thread:holding-mutex-p m)
          (eq (sb-thread:mutex-owner m) sb-thread:*current-thread*))))
                                        ; => (T T)
```

`mutex-owner` 拿到的是「此刻」的持有者，天生有竞态，只用于信息展示；
判断「我是否持有」用 `holding-mutex-p` 才是可靠的。

`grab-mutex` / `release-mutex` 是底层接口，手册明确建议**优先
`with-mutex`**。两个原因：一是它们不是中断安全的（正确姿势要包
`sb-sys:without-interrupts` 再在抓锁处开 `allow-with-interrupts`，见
24.8 的完整范式）；二是手写「成对释放」在报错 unwind 时容易漏。
`release-mutex` 有个 `:if-not-owner` 关键字控制「我不是持有者」时的行为：
`:punt`（默认，静默什么都不干）、`:warn`、`:error`、`:force`（强制释放）。

## 24.5 条件变量（waitqueue）：最易写错的原语

POSIX 条件变量那套设计，在 SBCL 里叫 **waitqueue**（为了不和 CL 的
condition 系统撞名）。三个组成部分缺一不可：

1. **条件本身**（你的数据，代码里没有一个对象代表它）；
2. **条件变量**（waitqueue，代替条件被等待/通知）；
3. **一把锁**，测试条件时必须持有。

三条铁律（手册逐字强调）：

- 调 `condition-wait` 时**必须持有**那把锁；它会**原子地**「放锁 + 入睡」，
  醒来返回前再把锁拿回来；
- 调 `condition-notify` / `condition-broadcast` 时同样**必须持有同一把锁**；
- `condition-wait` 可能**虚假唤醒**（spurious wakeup）——返回不代表条件
  成立，必须**循环重查**，用 `while` 不是 `if`。

`condition-wait` 还支持 `:timeout`（秒）。超时的语义要抠准：返回 NIL 且
**不再持有锁**——这时不能去碰共享数据，必须直接退出临界区。手册给出的
标准写法（生产者-消费者，带超时版）：

```lisp
(defvar *wq-data* nil)
(defvar *wq-queue* (sb-thread:make-waitqueue))
(defvar *wq-lock* (sb-thread:make-mutex))

(defun pop-data (&optional timeout)
  (sb-thread:with-mutex (*wq-lock*)
    (loop until *wq-data*
          do (or (sb-thread:condition-wait *wq-queue* *wq-lock* :timeout timeout)
                 ;; 超时返回时锁已不在手里：不能碰 *wq-data*，直接走人
                 (return-from pop-data nil)))
    (pop *wq-data*)))

(defun push-data (data)
  (sb-thread:with-mutex (*wq-lock*)
    (push data *wq-data*)
    (sb-thread:condition-notify *wq-queue*)))
```

跨线程跑一遍验证它确实工作：主线程 push，worker 在 pop 里等到为止：

```lisp
(setf *wq-data* nil)
(let ((th (sb-thread:make-thread (lambda () (pop-data 5)))))
  (sleep 0.05)
  (push-data :hello)
  (sb-thread:join-thread th))          ; => :HELLO
```

`condition-notify` 只叫醒一个（可选参数 `n` 叫醒 n 个）；
`condition-broadcast` 叫醒全部等待者——「结束了，大家各自判断退出」的
场景必须用 broadcast，只 notify 一个会把其余线程永远挂住（配套示例的
生产者-消费者一节就是这么收尾的）。

## 24.6 信号量（semaphore）：可数资源

信号量维护一个非负计数，适合「队列里有多少条消息」「连接池还剩几个名额」
这类**可数资源**：

```lisp
(let ((sem (sb-thread:make-semaphore :count 2)))
  (list (sb-thread:semaphore-count sem)         ; 2
        (sb-thread:wait-on-semaphore sem)       ; 拿到一个，返回新计数 1
        (sb-thread:try-semaphore sem)           ; 非阻塞再拿一个 → 0
        (sb-thread:try-semaphore sem)))         ; 空了，非阻塞放弃 → NIL
                                         ; => (2 1 0 NIL)
```

- `wait-on-semaphore`：计数不够就睡到够为止（`:timeout` 限时，超时返回
  NIL 且不减计数）；成功返回**新计数**。
- `signal-semaphore`：计数加 `n`（默认 1），叫醒至多 n 个等待者。
- `try-semaphore`：非阻塞版，拿不到就返回 NIL。
- `semaphore-notification` 对象可以传给 `:notification` 参数，事后用
  `semaphore-notification-status` 查「那次等待到底成没成」——用于把
  等待结果跨函数传递的场合，同一对象不能并发复用，重用前
  `clear-semaphore-notification`。

配套示例第 4 节用计数 3 的信号量做「最多 3 个任务同时跑」的限流器，并用
`(<= 峰值 3)` 这种与调度无关的断言收尾——并发测试就该这么写。

## 24.7 屏障：SBCL 里没有「会合屏障」，只有内存屏障

先把名词掰正。很多语言里的 barrier 指「n 个线程到齐了一起放行」的**会合
屏障**；SBCL **没有**这个 API（旧版教程里写的 `make-barrier` /
`wait-on-barrier` 并不存在）。要会合，用信号量自己数（配套示例第 5 节的
完整实现：到齐计数到 n 就 `signal-semaphore` n 次），或者用 24.9 的
sb-concurrency **gate**。

SBCL 里的 `sb-thread:barrier` 是**内存屏障**——防止编译器或 CPU 把内存
访问**重排**过某个点：

```text
(sb-thread:barrier (:memory) ...)   ; kind ∈ :compiler :memory :read :write :data-dependency
```

- `:compiler` 只挡编译器重排；
- `:memory` 挡 CPU 的一切内存访问重排（全屏障）；
- `:read` / `:write` 分别只挡读 / 写；
- `:data-dependency` 最弱，只保证「依赖前面读结果的读」不被提前。

写无锁算法的人才需要显式插屏障。日常代码你已经在**隐式**使用内存屏障了——
下列操作全都自带屏障效果：`atomic-incf`/`atomic-decf`/`atomic-push`/
`atomic-pop`、`compare-and-swap`、所有 mutex 操作、所有信号量操作、
`condition-wait`/`condition-notify`/`condition-broadcast`。也就是说：用
锁和原子操作正常写出来的代码，内存可见性已经是对的，不需要再插屏障。

## 24.8 中断与终止线程：能不用就不用

`sb-thread:interrupt-thread thread function` 让目标线程**异步地**在某个
任意点停下来跑 `function`（`sb-sys:without-interrupts` 保护的区段除外）。
它是调试利器，却是生产毒药，原因有两层：

1. **异步 unwind 安全性**：如果 `function` 做了非局部退出，而打断点恰好
   在某个 `unwind-protect` 的**清理形式里**，那么该清理形式和同一
   `unwind-protect` 里排在它后面的清理形式**都不会执行**。要整个调用栈
   上每一段代码都是异步 unwind 安全的才安全——这个性质**不可组合**，第
   三方库几乎不可能保证。
2. **可重入性**：被打断处正在执行的函数可能被 `function` 再次进入（特殊
   变量绑定、全局状态都会错位）。

手册的官方建议：`interrupt-thread` **只留给交互式调试**，生产环境禁用。
最经典的调试用法是强行把某个线程拉进调试器看状态：

```lisp
;; 交互场景专用（会进调试器，本教程的自动验证不执行它）：
;; (sb-thread:interrupt-thread th #'break)
```

`sb-thread:terminate-thread thread` 是用 `interrupt-thread` 实现的「让
目标线程调 `abort-thread`」——同样受异步 unwind 之苦。手册给的反面教材：

```lisp
;;; 这段代码里，terminate 若恰好打在 (release-foo foo) 执行期间，
;;; release-foo 本身会被打断 —— 资源照样泄漏。
(defun unsafe-worker ()
  (let (foo)
    (unwind-protect
         (progn
           (setf foo (get-foo))
           (work-on-foo foo))
      (when foo
        (release-foo foo)))))
```

对应的**异步终止安全**写法是把整段关进 `without-interrupts`，只在「干活」
处开一个局部中断窗口（这样打断点只能落在 `work-on-foo` 里，清理形式必然
完整执行）：

```lisp
(defun safe-worker ()
  (let (foo)
    (sb-sys:without-interrupts
      (unwind-protect
           (progn
             (setf foo (sb-sys:allow-with-interrupts (get-foo)))
             (sb-sys:with-local-interrupts (work-on-foo foo)))
        (when foo
          (release-foo foo))))))
```

结论：**不要**假设任何你不完全掌握的代码能被 `terminate-thread` 安全终止。
工程上的正解是协作式退出——线程自己循环检查一个退出标志（或从队列取到
「毒药丸」任务就 return），配合 `join-thread` 收尾。配套示例的线程池
（第 8 节）就是这么做的。

调试时想看**别的线程**里某个特殊变量的绑定值，用
`sb-thread:symbol-value-in-thread`（可 `setf`）。它也是调试工具，不是
线程间通信机制。

## 24.9 sb-concurrency：无锁队列、信箱与闸门

contrib 模块 `sb-concurrency`（类比 Java 的 `java.util.concurrent`）提供
三组高层数据结构。先加载：

```lisp
(require :sb-concurrency)              ; => ("SB-CONCURRENCY")
```

（`require` 的返回值是本次新加载的模块列表，重复 require 返回 NIL。）

### 24.9.1 queue：无锁线程安全 FIFO

```lisp
(let ((q (sb-concurrency:make-queue :initial-contents '(1 2))))
  (sb-concurrency:enqueue 3 q)                       ; 入队尾
  (list (sb-concurrency:dequeue q)                   ; 出队头 → 1
        (sb-concurrency:queue-count q)               ; 剩 2 个
        (sb-concurrency:list-queue-contents q)))     ; 还剩 (2 3)
                                         ; => (1 2 (2 3))
```

`dequeue` 空队列返回两个 NIL（第二值是「拿到了吗」标志）。`queue-count`
和 `list-queue-contents` 都要遍历整条链，只用于检查/打印，别放热路径。
`enqueue`/`dequeue` 本身是无锁的，多生产者多消费者随便用。

### 24.9.2 mailbox：可以「睡到有消息」的队列

mailbox 在 queue 之上加了**阻塞接收**，是线程间发消息的顺手工具：

```lisp
(let ((mb (sb-concurrency:make-mailbox)))
  (sb-concurrency:send-message mb :ping)
  (list (sb-concurrency:receive-message-no-hang mb)  ; 非阻塞收 → :PING
        (nth-value 1 (sb-concurrency:receive-message-no-hang mb))))
                                         ; => (:PING NIL)   第二封没了，标志 NIL
```

- `receive-message`：阻塞到收到为止；`:timeout` 限时，超时返回两个 NIL。
- `receive-message-no-hang`：非阻塞，第二值标志成功与否。
- `receive-pending-messages`：一次掏空（可选上限 `n`）。

用它写「主线程发任务、worker 收任务」比手工 queue+waitqueue 省一大半代码：

```lisp
(let ((mb (sb-concurrency:make-mailbox)))
  (let ((th (sb-thread:make-thread
             (lambda () (sb-concurrency:receive-message mb :timeout 5)))))
    (sb-concurrency:send-message mb (* 6 7))
    (sb-thread:join-thread th)))         ; => 42
```

### 24.9.3 gate：多线程等一个事件

gate 正是 24.7 说的「会合」场景的高层答案：一批线程 `wait-on-gate` 卡住，
任一线程 `open-gate` 后全部放行；还能 `close-gate` 重新关上等下一轮：

```lisp
(let ((g (sb-concurrency:make-gate)))           ; 默认关闭
  (list (sb-concurrency:gate-open-p g)          ; NIL
        (sb-concurrency:wait-on-gate g :timeout 0.01)  ; 关着，超时 → NIL
        (sb-concurrency:open-gate g)            ; 打开 → T（之前是关的）
        (sb-concurrency:wait-on-gate g)))       ; 已开，直接过 → T
                                         ; => (NIL NIL T T)
```

`open-gate`/`close-gate` 的返回值表示「状态有没有因此改变」（已开再开
返回 NIL）。

## 24.10 frlock：读远多于写时的快速读锁

`sb-concurrency:frlock`（Fast Read Lock）服务一种特定场景：**读者非常多、
写者很少**，且读者读到一半写者插进来是「可以容忍、只要发现后重读」的。

- 读者**不等锁**，读完校验「我读的时候有没有写者动过」；动过就重读
  （`frlock-read` 自动循环到拿到一致快照为止）；
- 写者互斥（`frlock-write` 同时只有一个写者）。

关键警告：frlock 提供的是**一致性**不是**互斥**——读写是真的并行发生的。
用它保护「写一半读到会出垃圾」的数据（比如 SBCL 哈希表）是**不安全**的；
适合「每个字段各自原子、只是要几个字段凑成一致快照」的场景，比如手册的
例子：`c` 恒等于 `a+b`，读者要么全旧要么全新：

```lisp
(let ((a 0) (b 0) (c 0)
      (lk (sb-concurrency:make-frlock)))
  (flet ((foo () (sb-concurrency:frlock-read (lk) (list a b c)))
         (bar (x y) (sb-concurrency:frlock-write (lk)
                       (setf a x b y c (+ x y)))))
    (bar 1 2)
    (foo)))                              ; => (1 2 3)   c 总是 a+b
```

底层接口 `frlock-read-begin` / `frlock-read-end` 返回 token 与 epoch，
手工比对决定重读——除非要写新的无锁结构，否则用宏就够了。

## 24.11 实战纪律（本仓库示例里踩出来的）

这几条不是手册内容，是配套示例反复修订沉淀的硬经验：

**纪律一：线程必须 join，不能拿 `(sleep N)` 赌。** 主线程跑完进程就退出，
没 join 的线程可能还在打印——输出缺内容甚至缺结束标记。线程池的 shutdown
也不能只看标志位就 return（会丢队列里没跑完的任务）：worker 的退出条件
必须是「取不到任务」（队列空**且**已 shutdown），然后逐个 join。

**纪律二：多线程打印必须自己加锁。** 一次 `format` 按指令拆成多次写，两个
线程的输出会逐指令穿插；更糟的是 SBCL 写多字节汉字会分块，一个汉字的字节
能被两个线程各写走一半，stdout 出现**非法 UTF-8**（本仓库实测抓到，下游
`tr` 直接报 `Illegal byte sequence` 并截断输入）。对策是一把全局打印锁 +
`finish-output`：

```lisp
(defvar *print-lock* (sb-thread:make-mutex :name "print-lock"))
(defun say (fmt &rest args)
  (sb-thread:with-mutex (*print-lock*)
    (apply #'format t fmt args)
    (finish-output)))
```

**所有**输出（含主线程）都走 `say`；锁序保持单向（其它锁 → 打印锁）就
不会死锁。

**纪律三：并发断言只写与调度无关的量。** 谁先跑不确定，但「计数总和」
「排序后的集合」「`(<= 峰值 上限)`」是确定的。把结论汇总放到所有
`join-thread` 之后由主线程统一打印——配套示例从头到尾都是这个模式
（原子计数 10000、CAS 计数 5000、限流峰值 ≤ 3）。

**纪律四：可移植代码走 bordeaux-threads。** `bt:make-thread` /
`bt:with-lock-held` / `bt:condition-notify` 等把各实现的原语包成统一
API；SB-THREAD 留给需要原子操作、waitqueue 超时、sb-concurrency 这些
高级原语的场合。

## 24.12 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| 找不到 `make-barrier` | SBCL 没有会合屏障 API | 信号量自数（示例 §5）或 sb-concurrency gate |
| Recursive lock attempt | mutex 不可重入，同线程二次加锁 | `holding-mutex-p` 判断；或 `with-recursive-lock` |
| 消费者醒来数据是空的 | 虚假唤醒后没重查条件 | `condition-wait` 外套 `while` 循环 |
| 超时后数据被写坏 | `condition-wait` 超时返回时**不持锁** | 超时分支直接退出临界区，不碰共享数据 |
| shutdown 后丢任务 | worker 只看 shutdown 标志就退出 | 退出条件 = 取不到任务；然后 join |
| 输出乱序 / 非法 UTF-8 | 多线程直接 `format t` | 打印锁 say + `finish-output` |
| 输出缺内容 / 缺结束标记 | 没 join 主线程先退了 | 全部 join；屏障/池都要 join |
| worker 拿不到父线程绑定 | 动态绑定不继承 | 显式传参，worker 内重新 let |
| `join-thread` 挂死 | join 了主线程或互相 join | join 主线程会阻塞到进程退出 |
| terminate 后资源泄漏 | 异步 unwind 打断清理形式 | 协作式退出标志；别用 terminate-thread |

---

上一章：[23 SBCL 扩展 I](23-sbcl-extensions.md) · 下一章：[25 SBCL 扩展 III：FFI](25-sbcl-ffi.md)
