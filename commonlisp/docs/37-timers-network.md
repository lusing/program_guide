# 37 · 定时器与网络编程

> 「两秒之后做这件事」和「把这几个字节发到那台机器」——ANSI Common
> Lisp 对这两件事都只字未提，SBCL 用一对干净的小 API 补齐：核心自带的
> **定时器**（`sb-ext`，手册第 14 章）和 contrib 模块
> **sb-bsd-sockets**（手册第 15 章）。前者架在 `setitimer(2)` 上，
> 多线程程序里直接用、不需要专门的调度线程；后者是 BSD socket 的
> 薄封装，socket 是 CLOS 对象。本章一次讲透。
>
> 配套例程：[`examples/37_timers_network/`](../examples/37_timers_network/main.lisp)
>
> 与前面各章一样，本章**自包含**：手册对应章节的核心内容全部在正文里
> 讲清楚，所有断言值都在 SBCL 2.6.9 上实测过（网络部分只走回环接口
> `127.0.0.1`，不需要真的联网）。

## 37.1 定时器：到点执行一个函数

一个定时器就是「某个时刻调用某个函数」的约定。创建用
`sb-ext:make-timer`（可选 `:name` 起名），排程用
`sb-ext:schedule-timer`——`time` 是从现在起的**秒数**，可以是非整数：

```lisp
(defvar *fired37* nil)
(defparameter *tm37* (sb-ext:make-timer (lambda () (setf *fired37* :fired))
                                        :name :demo :thread t))
(sb-ext:timer-name *tm37*)        ; => :DEMO
(sb-ext:timer-scheduled-p *tm37*) ; => NIL    ← 还没排程
```

`:thread t` 的含义 37.3 细讲，先记住它让定时器函数在一个新线程里跑。
排程之后，`timer-scheduled-p` 为真，`sb-ext:list-all-timers` 能列出它
（这个函数返回**系统里所有**定时器，包括别人建的）；触发之后自动出队。
观察异步动作还是老搭档 `sb-ext:wait-for`（第 35 章等终结器用过）：

```lisp
(sb-ext:schedule-timer *tm37* 0.05)          ; 0.05 秒后触发
(sb-ext:timer-scheduled-p *tm37*) ; => T
(if (member *tm37* (sb-ext:list-all-timers)) t nil) ; => T
(sb-ext:wait-for *fired37* :timeout 5) ; => :FIRED
(sb-ext:timer-scheduled-p *tm37*) ; => NIL    ← 一次性定时器触发完即出队
```

`timer-scheduled-p` 还有个可选参数 `:delta`，手册里说是「delta 秒之后
是否仍需触发」。注意一个实现与文档的出入：SBCL 2.6.9 的源码把 `delta`
**直接当作内部时间单位**（1 秒 = 1000 个内部单位）与当前时间相加，而
不是当作秒——给一次性定时器传 `:delta 5`，实际只望向 5 毫秒之后。
所以可靠的用法就两种：默认 `:delta 0`（此刻是否还在排程），以及下面
会看到的「重复定时器恒为真」。

## 37.2 重复定时器、绝对时间与撤销

`:repeat-interval` 让定时器触发后自动重新排程。重复定时器的
`timer-scheduled-p` **恒为真**（这是手册承诺的行为，与上面的单位
问题无关）：

```lisp
(defvar *tick37* 0)
(defparameter *tm37r* (sb-ext:make-timer (lambda () (incf *tick37*))
                                         :thread t))
(sb-ext:schedule-timer *tm37r* 0.05 :repeat-interval 0.05)
(sb-ext:timer-scheduled-p *tm37r* :delta 100) ; => T
(sb-ext:wait-for (>= *tick37* 3) :timeout 5) ; => T
```

`sb-ext:unschedule-timer` 撤销定时器。它的保证比「删了」更强：
**函数一返回，这个定时器就绝不会再触发，而且不存在尚未跑完的触发**
——没有「撤销和触发撞车」的竞态窗口：

```lisp
(sb-ext:unschedule-timer *tm37r*)
(sb-ext:timer-scheduled-p *tm37r*) ; => NIL
(let ((n *tick37*))
  (sleep 0.2)
  (= n *tick37*)) ; => T           ← 撤销之后计数器一动不动
```

`schedule-timer` 的另外两个关键字：

- `:absolute-p t` —— `time` 不再是「从现在起几秒」，而是
  **universal time**（允许非整数值）：

  ```lisp
  (defvar *abs37* nil)
  (sb-ext:schedule-timer (sb-ext:make-timer (lambda () (setf *abs37* :abs))
                                            :thread t)
                         (+ (get-universal-time) 1)   ; 1 秒后的时刻
                         :absolute-p t)
  (sb-ext:wait-for *abs37* :timeout 5) ; => :ABS
  ```

- `:catch-up` —— 只在 `:repeat-interval` 非 nil 时有意义（单独给会
  报错）。电脑休眠再唤醒这类**时钟跳变**会让定时器错过若干次触发；
  `:catch-up t` 让它唤醒后不带延迟地连续调用函数、把欠下的次数补齐，
  默认 `nil` 不补。做「每小时整点写日志」之类的事要权衡：补跑能把
  账做平，但唤醒瞬间的突发调用可能很密集。

## 37.3 定时器在哪个线程里运行

`make-timer` 的 `:thread` 参数有三个取值，语义差别很大：

- **缺省 = 调用 `make-timer` 时的 `sb-thread:*current-thread*`**：
  函数在**那个线程**里跑，投递方式是
  `sb-thread:interrupt-thread`（第 24 章）——到点打断宿主线程、
  插进来执行。`interrupt-thread` 的排序保证同样适用，且函数执行时
  **中断处于禁用状态**（函数内部可以用 `sb-thread:with-interrupts`
  重新放开）。
- **`t`**：每次触发都新建一个线程跑函数。
- **`nil`**：在某个不指定的线程里跑。

用 `*current-thread*` 的身份就能把前两种语义直接看出来：

```lisp
(defvar *thr37a* nil)
(let ((tm (sb-ext:make-timer
           (lambda () (setf *thr37a* sb-thread:*current-thread*)))))
  ;; 缺省：在 make-timer 时所在的线程（这里正是本线程）里跑
  (sb-ext:schedule-timer tm 0.05)
  (sb-ext:wait-for *thr37a* :timeout 5)
  (eq *thr37a* sb-thread:*current-thread*)) ; => T
```

```lisp
(defvar *thr37b* nil)
(let ((tm (sb-ext:make-timer
           (lambda () (setf *thr37b* sb-thread:*current-thread*))
           :thread t)))
  ;; :thread t：每次触发换一个新线程，不是本线程
  (sb-ext:schedule-timer tm 0.05)
  (sb-ext:wait-for *thr37b* :timeout 5)
  (eq *thr37b* sb-thread:*current-thread*)) ; => NIL
```

默认语义藏着本章最重要的坑：**函数看到的是宿主线程触发那一刻的动态
环境**——动态变量绑定、正握着的锁，全都取决于宿主当时恰好在执行哪段
代码。手册给的警示例子我们这里完整复现：让同一个函数分别在两个
`let` 绑定生效的窗口里触发，它看到的 `*foo37*` 就不同（真实代码里
`show-foo37` 是 `format` 打印，教程里把观察值收进列表好断言）：

```lisp
(defvar *foo37* nil)
(defvar *seen37* nil)
(defun show-foo37 ()
  (push *foo37* *seen37*))
```

```lisp
(setf *seen37* nil)
(sb-ext:schedule-timer (sb-ext:make-timer #'show-foo37) 0.05)
(sb-ext:schedule-timer (sb-ext:make-timer #'show-foo37) 0.15)
(let ((*foo37* t))
  (sleep 0.1))                  ; 0.05s 的定时器落在这个绑定窗口里
(let ((*foo37* :surprise))
  (sleep 0.2))                  ; 0.15s 的落在这个窗口里
(nreverse *seen37*) ; => (T :SURPRISE)
```

同一个函数，两次触发，读到两个不同的 `*foo37*`。推论：**定时器函数
里不要依赖任何动态绑定，也不要假设能拿到某把锁**；要把活儿交回主
线程，就走全局变量、原子容器，或者第 24 章的
`sb-thread:mailbox`——定时器里只负责「投信」，正事让收件人做。

## 37.4 sb-bsd-sockets：socket 是 CLOS 对象

网络支持不在核心里，在 contrib 模块 `sb-bsd-sockets` 里，第一次用
之前先 `require`（`SBCL_HOME` 指向的 `contrib/` 目录里有编译好的
fasl，直接加载，不需要联网）：

```lisp
(require :sb-bsd-sockets)
(sb-bsd-sockets:make-inet-address "127.0.0.1") ; => #(127 0 0 1)
```

这套 API 刻意贴着 BSD socket 的 C 接口建模，但按 Lisp 的习惯做了四处
改造（手册 15.1 的原话提炼）：

1. C 里返回 `-1` 再查 `errno` 的地方，这里直接 **signal 错误**；
   所有错误都是 `sb-bsd-sockets:socket-error` 的子类，且与 `errno`
   的取值一一对应。连接一个没人监听的端口试试（回环端口 1 几乎
   必然空闲）：

   ```lisp
   (handler-case
       (let ((s (make-instance 'sb-bsd-sockets:inet-socket
                               :type :stream :protocol :tcp)))
         (sb-bsd-sockets:socket-connect s #(127 0 0 1) 1)
         :no-error)
     (sb-bsd-sockets:socket-error () :sock-err)) ; => :SOCK-ERR
   ```

   实际 signal 的条件类型是
   `sb-bsd-sockets:connection-refused-error`——正是 `ECONNREFUSED`
   这个 errno 的镜像。
2. C 里靠「指针出参」返回的东西（对端地址之类），这里用**多值**。
3. 很多地方不用显式传长度——Lisp 对象自己知道长度。
4. **地址与端口的表示更友好**：IPv4 地址是 4 元素的
   `(unsigned-byte 8)` 向量（如 `#(127 0 0 1)`），IPv6 是 16 元素
   向量；端口就是整数。**不需要**在网络字节序和主机字节序之间做任何
   转换——包内部处理掉了。`make-inet-address` 把点分四段字符串
   转成地址向量（格式非法会报错），IPv6 对应
   `make-inet6-address`。

类层级：`socket` 是所有 socket 的共同基类（不直接实例化）；具体类有
`inet-socket`（IPv4）、`inet6-socket`（IPv6）、`local-socket`
（AF_LOCAL，Unix domain）及其子类 `local-abstract-socket`（抽象
命名空间，无文件系统节点，Linux 专用）。INET 家族创建时给两个参数：
`:type` 取 `:stream`（字节流）或 `:datagram`（报文），`:protocol`
取 `:tcp` 或 `:udp`。

协议号本身也能查，`get-protocol-by-name` 返回三个值（协议号、官方
协议名、别名列表），主值是协议号：

```lisp
(sb-bsd-sockets:get-protocol-by-name "tcp") ; => 6
```

## 37.5 TCP 全链路：bind → listen → connect → accept

服务器四步：`socket-bind` 绑地址端口、`socket-listen` 开始监听
（参数 backlog 是待处理连接队列的最大长度）、`socket-accept` 取出
一个已连接的新 socket、然后用流读写。客户端一步：`socket-connect`。
`socket-bind` 传**端口 0** 表示让内核挑一个空闲端口，自己的实际端口
用 `socket-name` 问回来（它返回本端地址和端口两个值；对端对应物是
`socket-peername`）。`socket-accept` 返回**三个值**：新连上的
socket、对端地址、对端端口：

```lisp
(defparameter *srv37* (make-instance 'sb-bsd-sockets:inet-socket
                                     :type :stream :protocol :tcp))
(setf (sb-bsd-sockets:sockopt-reuse-address *srv37*) t)
(sb-bsd-sockets:sockopt-reuse-address *srv37*) ; => T
(sb-bsd-sockets:socket-bind *srv37* #(127 0 0 1) 0)
(sb-bsd-sockets:socket-listen *srv37* 5)
(sb-bsd-sockets:socket-open-p *srv37*) ; => T
```

`sockopt-reuse-address` 是 socket 选项家族的一员（对应 C 的
`SO_REUSEADDR`），可 `setf`；命名规则很机械：`SO_KEEPALIVE` →
`sockopt-keep-alive`、`TCP_NODELAY` → `sockopt-tcp-nodelay` 等等。

有了监听中的服务器，客户端连上来，双方各把 socket 包成流，就能用
熟悉的 `write-line` / `read-line` 对话：

```lisp
(let ((client (make-instance 'sb-bsd-sockets:inet-socket
                             :type :stream :protocol :tcp)))
  (sb-bsd-sockets:socket-connect
   client #(127 0 0 1)
   (nth-value 1 (sb-bsd-sockets:socket-name *srv37*)))  ; 问回真实端口
  (multiple-value-bind (peer paddr) (sb-bsd-sockets:socket-accept *srv37*)
    (let ((cs (sb-bsd-sockets:socket-make-stream
               client :input t :output t :buffering :none :auto-close t))
          (ps (sb-bsd-sockets:socket-make-stream
               peer :input t :output t :buffering :none :auto-close t)))
      (write-line "ping37" cs)                 ; 客户端说
      (let ((heard-by-server (read-line ps)))  ; 服务器听
        (write-line "pong37" ps)               ; 服务器回
        (let ((heard-by-client (read-line cs)))
          (close cs) (close ps)                ; auto-close 顺带关 socket
          (list heard-by-server heard-by-client paddr))))))
; => ("ping37" "pong37" #(127 0 0 1))
```

`socket-make-stream`（socket 必须先已连接）的关键字值得逐个记住：

- `:input` / `:output` —— 要哪个方向（两个都不给是错误）；
- `:element-type` —— 默认 `'character`（字符流）；给 `:default`
  造**双价流**（字符字节混读写，第 36 章）；
- `:external-format` —— 默认 `:default`；
- `:buffering` —— `:full`（默认）/`:line` / `:none`。`:full` 下
  输出会一直攒着，直到 `close` 或 `finish-output` 才真正发出去；
  注意手册特别提醒：`force-output` 只保证冲出**一部分**，要冲干净
  用 `finish-output`。演示里用 `:none` 是为了每行立即到达；
- `:timeout` —— 读超时秒数（默认无超时）；
- `:auto-close` —— 为真时，流和 socket 被 GC 回收后底层文件描述符
  自动关闭（默认 `nil`）；上面 `close` 流时也会顺带关掉 socket；
- `:serve-events` —— 为真时阻塞 IO 会派发到递归事件循环（默认
  `nil`）。

最后一个坑：**socket 的流是被缓存的**——对同一个 socket 第二次调
`socket-make-stream` 拿到的是同一个流。两次调用参数不一致（比如
第一次要输入、第二次要输出）会得到出乎意料的东西。

收尾服务器，关掉之后 `socket-open-p` 变假：

```lisp
(sb-bsd-sockets:socket-close *srv37*)
(sb-bsd-sockets:socket-open-p *srv37*) ; => NIL
```

`socket-close` 有个 `:abort` 关键字；另外如果这个 socket 曾经
`socket-make-stream` 过，`socket-close` 会以 abort 方式关那个流。

## 37.6 UDP：socket-send 与 socket-receive

无连接协议不需要 listen/accept：两个 socket 各自 `socket-bind`，然后
用 `socket-send` / `socket-receive` 直接收发报文。`socket-send` 的
`:address` 是 `(地址向量 端口)` 组成的**列表**；不给 `:address` 就走
`send(2)`（要求 socket 已连接）。返回发送的字节数。`socket-receive`
的三个位置参数是 socket、缓冲区、长度——缓冲区传 `nil` 表示现场造一
个，默认元素类型是**字符**（拿到的是字符串，要原始字节就传
`:element-type '(unsigned-byte 8)`）；返回值有三个：缓冲区、实际
长度、发送方地址。报文比缓冲区大也不怕：datagram socket 上它设了
`MSG_TRUNC`，返回的长度是**报文的真实长度**。

还有一个容易踩的坑：返回的缓冲区是**整个缓冲区**，不会截断到实际
收到的长度——下面缓冲区是 16 字符，只收到 6 字节时，拿到的是
16 字符的串，没读到的尾部是 NUL 字符（终端里看不见），所以实际
数据要用 `(subseq buf 0 len)` 截取：

```lisp
(let ((a (make-instance 'sb-bsd-sockets:inet-socket
                        :type :datagram :protocol :udp))
      (b (make-instance 'sb-bsd-sockets:inet-socket
                        :type :datagram :protocol :udp)))
  (sb-bsd-sockets:socket-bind a #(127 0 0 1) 0)
  (sb-bsd-sockets:socket-bind b #(127 0 0 1) 0)
  (let ((pa (nth-value 1 (sb-bsd-sockets:socket-name a))))
    (sb-bsd-sockets:socket-send b "ping37" 6
                                :address (list #(127 0 0 1) pa))
    (multiple-value-bind (buf len from) (sb-bsd-sockets:socket-receive a nil 16)
      (sb-bsd-sockets:socket-close a)
      (sb-bsd-sockets:socket-close b)
      (list (subseq buf 0 len) len from)))) ; => ("ping37" 6 #(127 0 0 1))
```

`socket-send` 的缓冲区是字符串时按 `:external-format` 转成字节再发；
长度参数传 `nil` 就用缓冲区的全长。

## 37.7 半关闭：socket-shutdown

「我的请求发完了，但还要等你回话」——TCP 里这个状态叫半关闭，用
`socket-shutdown` 表达，`:direction` 取 `:input` / `:output` /
`:io`。对端读到的是一个干净的 EOF。下面客户端一个字节不发直接
shutdown 输出方向，服务器端 `read-line` 立刻见到流尾（`read-line`
在 EOF 处的第二返回值为真，表示没遇到换行符就结束了）：

```lisp
(let ((srv (make-instance 'sb-bsd-sockets:inet-socket
                          :type :stream :protocol :tcp))
      (cli (make-instance 'sb-bsd-sockets:inet-socket
                          :type :stream :protocol :tcp)))
  (sb-bsd-sockets:socket-bind srv #(127 0 0 1) 0)
  (sb-bsd-sockets:socket-listen srv 1)
  (sb-bsd-sockets:socket-connect cli #(127 0 0 1)
                                 (nth-value 1 (sb-bsd-sockets:socket-name srv)))
  (let* ((peer (sb-bsd-sockets:socket-accept srv))
         (ps (sb-bsd-sockets:socket-make-stream
              peer :input t :buffering :none :auto-close t)))
    (sb-bsd-sockets:socket-shutdown cli :direction :output)
    (prog1 (multiple-value-list (read-line ps nil :eof))
      (close ps)
      (sb-bsd-sockets:socket-close cli)
      (sb-bsd-sockets:socket-close srv)))) ; => (:EOF T)
```

## 37.8 local socket：同机进程间通信

`local-socket`（AF_LOCAL，也叫 Unix domain socket）的地址是一个
**字符串**，`socket-bind` 会拿它在文件系统里真的创建一个节点
（所以跨不了网络，只能同机）。剩下的 API 和 TCP 一模一样：

```lisp
(let ((path "doc37-local.sock"))
  (when (probe-file path) (delete-file path))
  (let ((srv (make-instance 'sb-bsd-sockets:local-socket :type :stream)))
    (sb-bsd-sockets:socket-bind srv path)
    (sb-bsd-sockets:socket-listen srv 1)
    (let ((cli (make-instance 'sb-bsd-sockets:local-socket :type :stream)))
      (sb-bsd-sockets:socket-connect cli path)
      (let* ((peer (sb-bsd-sockets:socket-accept srv))
             (cs (sb-bsd-sockets:socket-make-stream
                  cli :input t :output t :buffering :none :auto-close t))
             (ps (sb-bsd-sockets:socket-make-stream
                  peer :input t :output t :buffering :none :auto-close t)))
        (write-line "local37" cs)
        (prog1 (read-line ps)
          (close cs) (close ps)
          (sb-bsd-sockets:socket-close srv)
          (delete-file path)))))) ; => "local37"
```

相比回环 TCP，它省掉整个协议栈开销，还天然支持用文件权限控制谁能
连。它的子类 `local-abstract-socket` 用抽象命名空间做地址——同样
是字符串，但**不**在文件系统里留节点（Linux 专用）。

## 37.9 名字服务：get-host-by-name

名字解析走平台的 `getaddrinfo(3)` 一族（DNS 还是 hosts 文件由平台
决定），结果装在 `host-ent` 对象里。`get-host-by-name` 查不到会
signal `name-service-error`；它可能多返回一个**第二值**——装着零个
或多个 IPv6 地址的另一个 `host-ent`。`host-name` 参数也可以是点分
四段的 IP 字符串。取地址用 `host-ent-address`，取规范名字用
`host-ent-name`：

```lisp
(let ((h (sb-bsd-sockets:get-host-by-name "localhost")))
  (list (sb-bsd-sockets:host-ent-address h)
        (sb-bsd-sockets:host-ent-name h))) ; => (#(127 0 0 1) "localhost")
```

反查用 `get-host-by-address`。这里躺着和第 36 章同款的元素类型陷阱：
它内部按地址向量的**精确类型**分派，传字面量 `#(127 0 0 1)`（元素
类型 `T`）会掉进缝隙里报 `case-failure`，必须用
`make-inet-address` 造出来的真 `(unsigned-byte 8)` 向量：

```lisp
(sb-bsd-sockets:host-ent-address
 (sb-bsd-sockets:get-host-by-address
  (sb-bsd-sockets:make-inet-address "127.0.0.1"))) ; => #(127 0 0 1)
```

## 37.10 小结

| 主题 | 入口 | 要点 |
|---|---|---|
| 创建/排程 | `sb-ext:make-timer` / `schedule-timer` | `time` 为秒数；`:repeat-interval`、`:absolute-p`、`:catch-up` |
| 查询/撤销 | `timer-scheduled-p` / `unschedule-timer` / `list-all-timers` / `timer-name` | 撤销返回后绝不再触发；重复定时器 scheduled-p 恒真 |
| 线程语义 | `make-timer` 的 `:thread` | 缺省 = 创建时所在线程（interrupt-thread 投递）；`t` = 每次新线程；`nil` = 不定线程 |
| 动态环境 | 手册警示示例 | 触发瞬间宿主线程在执行什么，函数就看到什么绑定——别依赖动态环境 |
| 加载 | `(require :sb-bsd-sockets)` | contrib 模块；socket 是 CLOS 对象 |
| 错误体系 | `socket-error` 及其子类 | 与 errno 一一对应，如 `connection-refused-error` |
| 地址表示 | `#(127 0 0 1)` + 端口整数 | ub8 向量；不用转网络序；`make-inet-address` |
| TCP | `socket-bind` / `listen` / `connect` / `accept` | 端口 0 = 内核挑端口；accept 返回新 socket + 对端地址端口 |
| 流化 | `socket-make-stream` | 默认字符流；`:buffering :full` 要 `finish-output`；流被缓存 |
| UDP | `socket-send` / `socket-receive` | `:address` 是 `(地址 端口)` 列表；MSG_TRUNC 返回真实包长 |
| 半关闭 | `socket-shutdown` | `:direction` :input/:output/:io；对端见 EOF |
| 同机 IPC | `local-socket` / `local-abstract-socket` | 地址是字符串；前者建文件节点 |
| 名字服务 | `get-host-by-name` / `get-host-by-address` / `host-ent-address` | 反查要真 ub8 向量，字面量会 case-failure |

下一章把 SBCL 的 contrib 模块挨个巡一遍：哪些值得常备、各自解决
什么问题。
