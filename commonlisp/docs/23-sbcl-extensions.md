# 23 · SBCL 扩展 I：进程、环境、GC、编译器与映像

> 配套示例：[`examples/23_sbcl_ext/`](../examples/23_sbcl_ext/main.lisp)（channel: sbcl）
>
> 从本章起是 **SBCL 专属**部分（22 章讲了 CLISP 对应接口与可移植替代）。
> 本章以 SBCL 2.6.9 为准。

## 23.1 用 `SB-*` 之前先想清楚

`SB-` 开头的包是 SBCL 的实现扩展，标准里没有：换实现就跑不了。
业务代码建议把 `SB-*` 的使用收进一个小适配层，或直接用可移植库
（bordeaux-threads / cffi / uiop）。

## 23.2 哪些包在核心里、哪些要 require

核心里就有的包**不需要 require**，require 它们反而报错（实测）：

| 包 | 位置 |
|---|---|
| `SB-EXT`（getenv / run-program / gc / quit） | **核心** |
| `SB-ALIEN`（FFI，25 章） | **核心** |
| `SB-THREAD`（线程，24 章） | **核心** |
| `SB-PROFILE`（性能分析，26 章） | **核心** |
| `SB-POSIX` / `SB-SPROF` / `SB-COVER` / `SB-BSD-SOCKETS` | contrib，**要 require** |

```lisp
(require :sb-posix)      ; => ("SB-POSIX")
(require :sb-profile)    ; 报错：Don't know how to REQUIRE SB-PROFILE
```

后一个错误容易误解——不是「没这功能」，是「它在核心里，没有同名 contrib」。
直接用即可。另外 `require` 与 `pkg:sym` **不能写在同一个顶层形式**（03 章：
读入先于求值）。

## 23.3 实现信息与环境变量

```lisp
(lisp-implementation-type)      ; => "SBCL"
(lisp-implementation-version)   ; => "2.6.9"
```

`sb-ext:posix-getenv` 取单个环境变量，不存在时返回 `NIL`：

```lisp
(sb-ext:posix-getenv "DEFINITELY-NOT-SET-XYZ")   ; => NIL
```

**跨平台要小心变量名**：`USERPROFILE`/`OS` 是 Windows 专有，POSIX 上得 NIL；
用 `HOME`/`SHELL`/`PATH` 这类通用变量（或 `#+win32` 分发）。变量的具体取值
因机器而异，断言无从写起——这正是示例 23 用 `(or … "（未设置）")` 兜底的原因。

## 23.4 run-program：跑外部命令

`sb-ext:run-program` 是 SBCL 拉起子进程的唯一入口。先把签名看全：

```lisp
;; sb-ext:run-program program args
;;   &key env environment (wait t) search pty
;;        input if-input-does-not-exist output (if-output-exists :error)
;;        (error :output) (if-error-exists :error)
;;        status-hook external-format directory preserve-fds
```

三个要点先记住：

1. **不经过 shell**。`args` 是字符串列表，逐个变成 `argv[1..]`，
   不需要也不能带 shell 转义；通配符、管道、`>` 重定向都不会发生——
   想要 shell 语义就显式调 `/bin/sh -c`（见下面 shell-command）。
2. **裸程序名必须 `:search t`**，否则按绝对/相对路径找，找不到就报错；
   给了 `:search t` 才在子进程的 `$PATH` 里找。
3. **默认 `:wait t`**，同步等到子进程结束；`:wait nil` 异步，
   返回后立刻继续跑 Lisp。

```lisp
(sb-ext:run-program "echo" '("hi") :output t :search t)
(sb-ext:run-program "echo" '("hi") :wait t)                 ; 会报错：Couldn't execute
(sb-ext:run-program "echo" '("hi") :output :string :search t) ; 会报错：:output 不收 :string
```

### 23.4.1 拿输出：给流，不给关键字

`:output` 只接受 `t`（直通当前 stdout）、`nil`（丢进 /dev/null）、路径名、
流、或 `:stream`（事后用 `process-output` 读）。想要字符串结果，
惯用法是给它一个 `with-output-to-string` 的流：

```lisp
(with-output-to-string (s)
  (sb-ext:run-program "echo" '("hi") :output s :search t))    ; 返回 "hi" 加换行
```

返回的串是 `"hi"` 后跟一个**真实换行符**。Common Lisp 字符串没有 C 式
`\n` 转义，所以没法把这种串写进单行断言，验证时用 `format nil "~%"` 拼出
对照串再 `string=`：

```lisp
(string= (with-output-to-string (s)
           (sb-ext:run-program "echo" '("hi") :output s :search t))
         (format nil "hi~%"))                                 ; => T
```

`:input` 的取值与 `:output` 对称（`t` 继承 / `nil` 空 / 路径名 / 流 / `:stream`），
`:stream` 时用 `process-input` 拿到往子进程写的流。`:error` 同 `:output`，
额外多一个取值 `:output`——把 stderr 并进 stdout 同一条流（这也是默认值）。

输出到文件时 `:if-output-exists` 控制已存在怎么办：`:error`（默认）、
`:supersede`、`:append`、`nil`（直接返回 nil 不执行）。

一行 shell 命令要按平台选解释器（读取期分发）：

```lisp
(defun shell-command (command)
  #+win32 (list "cmd" (list "/c" command))
  #-win32 (list "/bin/sh" (list "-c" command)))
```

### 23.4.2 环境与工作目录

`:environment` 接受 `"NAME=VALUE"` 字符串列表，**整体替换**子进程环境
（默认是复制当前进程环境；`:env` 是 CMUCL 遗留的旧格式，两者不能同时给）：

```lisp
(string= (with-output-to-string (s)
           (sb-ext:run-program "/bin/sh" '("-c" "echo $DEMO_VAR") :output s
                               :environment '("DEMO_VAR=42")))
         (format nil "42~%"))                                 ; => T
```

`:directory` 指定子进程的工作目录（`nil` 默认，表示不变）；`:external-format`
指定三条流的编码；`:pty`（非 win32）让子进程跑在伪终端下——需要交互式程序
（比如要骗它「你在终端里跑」）时用。

### 23.4.3 进程对象操作全集

`run-program` 返回 `process` 结构，配套操作符：

| 操作 | 作用 |
|---|---|
| `process-pid` | 操作系统 PID |
| `process-status` | `:running` / `:stopped` / `:exited` / `:signaled` |
| `process-alive-p` | 还活着吗（对已 close 的进程可能假阳性） |
| `process-wait` | 阻塞等它结束，返回进程本身 |
| `process-exit-code` | 退出码；被信号打死时是信号编号 |
| `process-core-dumped` | 是否吐出了 core 文件 |
| `process-input/output/error` | 三条流的访问器（`:stream` 模式才有） |
| `process-kill p sig &optional whom` | 发信号；`whom` 为 `:pid`（默认）或 `:process-group` |
| `process-close` | 关掉所有流、不再维护状态（之后 exit-code 等信息可能过时） |
| `:status-hook` 构造参数 | 状态变化时回调的函数（异步场景的挂勾点） |

实测一组：

```lisp
(let ((p (sb-ext:run-program "/bin/sh" '("-c" "exit 3"))))
  (sb-ext:process-exit-code p))                    ; => 3

(let ((p (sb-ext:run-program "/usr/bin/true" '())))
  (sb-ext:process-status p))                       ; => :EXITED
```

异步 + 信号的完整生命周期（示例 23 里有可跑版本）：

```lisp
(let ((p (sb-ext:run-program "/bin/sleep" '("30") :wait nil)))
  (sb-ext:process-alive-p p)     ; 异步启动，立刻返回，进程还活着
  (sb-ext:process-kill p 9)      ; SIGKILL
  (sb-ext:process-wait p)        ; 等它真正死掉
  (sb-ext:process-status p))     ; => :SIGNALED
```

Windows 专有参数顺带一提：`:escape-arguments`（默认 t）控制参数转义，
`:window` 控制子窗口显隐（`:hide`/`:show-normal` 等）。

## 23.5 sb-ext:exit 与退出/初始化钩子

`sb-ext:exit` 是 2.x 时代的正式出口（`sb-ext:quit` 是它的兼容包装）：

- `(sb-ext:exit :code 0)`——干净退出：unwind 栈、跑 `*exit-hooks*`、
  然后 `terminate-thread` 其余线程并 `join-thread` 等它们，总等待上限
  `:timeout` 秒（默认取 `*exit-timeout*`，60；`nil` 表示无限等）。
  超时不退的线程直接丢下不管。
- `(sb-ext:exit :abort t)`——立刻 `_exit(2)`：栈不 unwind、钩子不跑、
  `atexit(3)` 都不执行。退出过程里再调 `exit`（递归）也等同 `:abort t`。
- 想要**有序的同步关停**（复杂清理逻辑），自己挂退出钩子做，
  别依赖隐式的 terminate-thread——它是异步的，清理顺序很难搞对。

三个钩子变量，SBCL 自己不用，专门留给用户和应用：

```lisp
;; *exit-hooks*：进程退出时按未定顺序调用
;; *init-hooks*：保存过的 core 启动时调用（系统初始化完、后台线程起来前）
(let ((hook (lambda () (format t "清理资源~%"))))
  (push hook sb-ext:*exit-hooks*)
  (setf sb-ext:*exit-hooks* (remove hook sb-ext:*exit-hooks*))
  (member hook sb-ext:*exit-hooks*))              ; => NIL
```

（验证环境不能真退出，所以这里只演示钩子的增删；真用时 push 进去即可。）

## 23.6 GC：分代、钩子、终结器与弱指针

### 23.6.1 触发与观测

```lisp
(sb-ext:gc)                  ;  nursery 回收（可能连带更老的代）
(sb-ext:gc :full t)          ; 全代回收
(sb-ext:gc :gen 3)           ; 保证回收到第 3 代为止
```

观测一组（数值因运行而异，这里只断言类型）：

```lisp
(integerp (sb-ext:get-bytes-consed))            ; => T   累计分配字节数
(integerp (sb-ext:dynamic-space-size))          ; => T   动态空间总大小
(> (sb-ext:bytes-consed-between-gcs) 0)         ; => T   距下次 GC 的配额（可 setf）
```

`*gc-run-time*` / `*gc-real-time*` 是 GC 累计花费的 CPU / 墙钟时间，
可以 `let` 绑成 0 来测某段代码的 GC 开销（会干扰 `time` 的统计）。
`(setf (sb-ext:gc-logfile) path)` 让每次 GC 往文件里追加分代统计，
长驻服务排查 GC 行为时用。

`sb-ext:*after-gc-hooks*` 在**每次** GC 后调用。但有一个 2.6.9 必须知道的
行为：带线程的 SBCL 里钩子**不在调用 `gc` 的线程里同步执行**——`gc`
只负责唤醒一个叫 `finalizer` 的内部系统线程，钩子由它在**不确定的稍后**
异步执行。所以下面这种「`gc` 一返回就检查计数」的写法是**错的**（竞态，
时灵时不灵）：

```text
(let ((count 0))
  (push (lambda () (incf count)) sb-ext:*after-gc-hooks*)
  (sb-ext:gc :full t)
  count)                  ; 错误示范：钩子可能还没跑，count 常常还是 0
```

正确姿势是**主动同步等待**钩子生效。闭包本身没问题（抓 lexical 变量
照样工作），问题全在「主线程何时读结果」：没有一个同步点，主线程永远
可能读早。简单场景轮询加 `sleep` 就够了：

```lisp
(defvar *gc-hook-count* 0)
(push (lambda () (incf *gc-hook-count*)) sb-ext:*after-gc-hooks*)

(sb-ext:gc :full t)
(loop repeat 100                              ; 轮询等 finalizer 线程跑完钩子
      when (plusp *gc-hook-count*) do (return)
      do (sleep 0.01))
*gc-hook-count*                               ; => 1
```

清理时把钩子从列表里删掉即可。因为执行线程是 `finalizer`，钩子里必须
完全可重入、不能假设任何动态绑定；抛错只会变成一个 warning。

### 23.6.2 finalize：对象被回收后的善后

`sb-ext:finalize` 安排「对象没有任何引用之后」调用某函数——
典型用途是释放 Lisp 对象牵着的堆外资源（FFI 内存、句柄）。
手册给的好坏两个对照例，核心差别一句话：**闭包抓句柄，别抓对象自己**。

```lisp
(defstruct (wrapped-handle (:constructor make-wrapped-handle (handle)))
  handle)

;;; GOOD：闭包只抓 handle，object 能正常被回收
(let* ((handle 42)
       (object (make-wrapped-handle handle)))
  (sb-ext:finalize object (lambda () (format t "释放句柄 ~A~%" handle)))
  (sb-ext:cancel-finalization object))           ; => T（演示完即撤销，防真跑）
```

```text
;;; BAD：闭包引用了 object —— 对象被自己的终结器永久拽住，永远回收不掉
(let* ((handle 42)
       (object (make-wrapped-handle handle)))
  (sb-ext:finalize object
                   (lambda ()
                     (format t "释放 ~A" (wrapped-handle-handle object)))))
```

两条使用纪律：

- 终结器**可能在任意线程、任意动态环境里**执行，必须完全可重入；
  它抛的错误会被吞掉变成一个 warning。
- `:dont-save t` 让 `save-lisp-and-die` 时丢弃该终结器——
  释放系统内存的终结器必须加，否则新映像启动时会拿着旧世界的地址乱释放。

`cancel-finalization` 撤销对象的所有终结器，本来有才返回 T：

```lisp
(let ((x (list 1)))
  (sb-ext:finalize x (lambda () nil))
  (sb-ext:cancel-finalization x))                ; => T
```

### 23.6.3 弱指针：不续命的引用

弱指针指向对象但不阻止它被回收——做缓存的标配：

```lisp
(let* ((strong (list :keep))
       (wp (sb-ext:make-weak-pointer strong)))
  (multiple-value-bind (v ok) (sb-ext:weak-pointer-value wp)
    (list (eq v strong) ok)))                    ; => (T T)
```

`weak-pointer-value` 返回两个值：指向的对象、以及「是否还活着」。
强引用消失、GC 跑过之后，第二值变 NIL——但回收时机不确定，
教程不拿它写断言。哈希表也内建弱键/弱值（`make-hash-table :weakness`，
见 35 章），多数场景比手搓弱指针更方便。

## 23.7 编译控制：compile / declaim / disassemble

SBCL 是「始终编译」的实现——`--load` 加载源码也走编译器，所以刚 defun 出来的
函数就已经是编译产物，**类型声明在日常代码里就有效果**；代价是 style-warning
会打到 stderr（这也是好事：警告即线索）。

```lisp
(defun to-be-compiled (x) (+ x 1))
(compiled-function-p #'to-be-compiled)  ; => T（load 阶段就已编译，无需手动 compile）
(compile 'to-be-compiled)               ; 单函数显式编译，依然合法

(declaim (optimize (speed 3) (safety 1) (debug 1)))   ; 全局优化策略
(defun fixnum-add (a b)
  (declare (type fixnum a b)
           (optimize (speed 3) (safety 0)))
  (the fixnum (+ a b)))
(fixnum-add 20 22)                      ; => 42
(disassemble #'fixnum-add)              ; 打印真机器码，输出随版本/平台变（26 章细看）
```

## 23.8 save-lisp-and-die：整世界打包

签名（2.6.9）：

```lisp
;; sb-ext:save-lisp-and-die core-file-name
;;   &key toplevel executable save-runtime-options callable-exports
;;        (purify t) root-structures (environment-name "auxiliary") compression
```

典型用法（验证环境不能真调——它**调用即退出**，"and die" 是字面意思，
只能放程序最后一步；示例 23 里也以注释形式给出）：

```lisp
;; (defun my-app-main ()
;;   ;; 注意：toplevel 函数应当自己提供 abort restart
;;   (format t "启动！~%")
;;   (sb-ext:exit :code 0))
;;
;; (sb-ext:save-lisp-and-die "my-app"
;;                           :toplevel #'my-app-main
;;                           :executable t
;;                           :compression t)
```

各关键字逐项说清：

- `:executable t`——把运行时和 core 合成独立可执行文件；
  默认 `nil` 只存 `.core`，用 `sbcl --core xxx.core` 恢复，体积小得多。
  独立可执行文件总是带 `--noinform` 行为。`:executable :elf-object`
  则产出需要进一步链接的 `.o`（实验性）。
- `:toplevel`——core 恢复后跑的函数。它正常返回等价于 `(sb-ext:exit :code 0)`；
  默认是处理命令行选项 + REPL 的那个。`:callable-exports` 非空时不能给 `:toplevel`。
- `:save-runtime-options t`——把启动时的 `--dynamic-space-size` /
  `--control-stack-size` 存进可执行文件并恢复；同时**关闭**运行时的选项处理，
  所有命令行参数原样交给 toplevel。`:accept-runtime-options` 是折中：
  这两个选项仍由运行时处理。
- `:purify t`（默认）——把编译期常量向量、符号名等不可变对象映射成只读，
  多进程跑同一份程序时省内存。
- `:root-structures`——新加载系统的入口点列表，影响 purify/代码重排的局部性，
  一般不填也行。
- `:compression`——只有构建时带 `:sb-core-compression` 特性才可用。
  `nil`（默认）不压缩；`t` 用默认等级 9；也可给 **-7 到 22 的整数**，
  对应 zstd 压缩等级（注意：2.x 时代起压缩后端是 **zstd**，不是早年文档里的 zlib）。
- `:application-type`（仅 Windows）——`:console`（默认）或 `:gui`。

构建特性可以这样自检（本教程验证用的 2.6.9 构建带压缩支持）：

```lisp
(and (member :sb-core-compression *features*) t)   ; => T
```

存/取过程会重置一些全局状态：`*standard-output*` 等流、`*random-state*`、
默认路径名等；`*init-hooks*` 在 core 启动时被调用（23.5）。
对比 CLISP 的 `ext:saveinitmem`：映像更小但不带运行时（21 章）。

## 23.9 原子操作与 CAS 全族

无锁结构的地基。先认清**返回值约定**：`atomic-incf`/`atomic-decf` 返回
**修改前的旧值**，`cas` 也返回旧值——判断成败靠「返回值是否 eq 期望值」。

```lisp
(defstruct (ch23-counter (:constructor make-ch23-counter)
                         (:conc-name counter-))
  (value 0 :type (unsigned-byte 64)))

(let ((c (make-ch23-counter)))
  (list (sb-ext:atomic-incf (counter-value c))   ; 旧值 0
        (sb-ext:atomic-incf (counter-value c))   ; 旧值 1
        (counter-value c)))                      ; => (0 1 2)
```

`atomic-incf`/`atomic-decf` 的 `place` 只能是这几种（`sb-ext:word`
就是 `(unsigned-byte 64)` 的别名）：

- 声明了 `(unsigned-byte 64)` 类型的 defstruct 槽，或同类型 simple-array 的 `aref`；
- cons 的 `car`/`cdr`（`first`/`rest` 同义）；
- `defglobal` 定义且声明为 `fixnum` 的全局变量。

算术是**模块化**的（回绕，不报错）：

```lisp
(let ((c (make-ch23-counter)))
  (sb-ext:atomic-decf (counter-value c))   ; 0 减 1 回绕到最大值
  (counter-value c))                       ; => 18446744073709551615
```

`atomic-push`/`atomic-pop`/`atomic-update` 覆盖更一般的读-改-写，
可用于所有可 CAS 的位置；`update-fn` 可能被**重复调用**（竞争下重试），
所以传进去的函数必须无副作用。注意**普通变量不是可 CAS 位置**——
`(atomic-push 1 stack)` 直接编译报错 `Invalid place to CAS`；想要一个
「变量语义」的原子盒子，惯用法是拿 cons 的 `car` 当盒子：

```lisp
(let ((cell (cons nil nil)))                 ; car 当栈顶盒子
  (sb-ext:atomic-push 1 (car cell))
  (sb-ext:atomic-push 2 (car cell))
  (list (sb-ext:atomic-pop (car cell))
        (car cell)))                         ; => (2 (1))

(let ((x (cons :count 0)))
  (sb-ext:atomic-update (cdr x) #'+ 10)
  (cdr x))                                   ; => 10
```

`compare-and-swap`（别名 `cas`）内建支持的位置：`car cdr first rest svref
symbol-plist symbol-value slot-value`、`sb-mop:standard-instance-access`、
以及**存储类型非 raw** 的 defstruct 访问器。它还可以**用户扩展**——
定义名为 `(sb-ext:cas 位置名)` 的函数（类比 setf 函数）。注意扩展机制
**只认 `(名字 参数...)` 形的复合 place**：`(sb-ext:cas foo-cell ...)` 这种
裸符号写法会直接报 `Invalid place to CAS`：

```lisp
(defvar *foo-cell* nil)
(defun foo-cell () *foo-cell*)
(defun (sb-ext:cas foo-cell) (old new)
  (sb-ext:cas (symbol-value '*foo-cell*) old new))

(setf *foo-cell* 0)
(sb-ext:cas (foo-cell) 0 42)               ; => 0（旧值，说明换成功了）
*foo-cell*                                 ; => 42
```

注意系统**不保证 cas 函数的原子性**——上面的实现靠转发到内建可 CAS 位置
才安全。24 章会把这些原语拼成真正的无锁队列。

## 23.10 限时三件套：:timeout、deadline、with-timeout

SBCL 提供三种限制操作耗时的机制，安全性递减、覆盖面递增：

### 23.10.1 调用点的 `:timeout` 参数（最安全）

线程同步原语（`join-thread`、`grab-mutex`、`condition-wait`、
`wait-on-semaphore` 等）接受 `:timeout`，超时后要么正常返回特殊值、
要么抛专门条件。任意条件等待用 `sb-ext:wait-for`：

```lisp
(sb-ext:wait-for t :timeout 1)       ; => T    条件立刻成立，返回它的值
(sb-ext:wait-for nil :timeout 0.1)   ; => NIL  超时返回 NIL
```

### 23.10.2 `sb-sys:with-deadline`：动态范围的全局死线

给一整段计算设死线，范围内所有「尊重 deadline 的操作」
（`sleep`、阻塞 IO、`get-mutex`、`condition-wait` 等，含 SBCL 内部隐式使用）
共享这一个时间预算；嵌套时取最早到期的（`:override t` 才能放宽外层）：

```lisp
(handler-case
    (sb-sys:with-deadline (:seconds 0.2)
      (sleep 5))                     ; 预算只有 0.2 秒，睡不下去
  (sb-sys:deadline-timeout () :deadline))   ; => :DEADLINE
```

死线是**每线程**的：子线程不受父线程死线影响。条件抛出后，handler 可以用
`sb-sys:defer-deadline` / `sb-sys:cancel-deadline` 两个 restart 推迟或
取消死线并继续原操作；线程在调试器里时，deadline 信号会推迟到退出调试器。

### 23.10.3 `sb-ext:with-timeout`：异步打断（最能干也最危险）

时间一到，**几乎任意位置**异步抛 `sb-ext:timeout`：

```lisp
(handler-case
    (sb-ext:with-timeout 0.2
      (sleep 5))
  (sb-ext:timeout () :timed-out))    ; => :TIMED-OUT
```

危险在于：从异步条件里 unwind **永远谈不上安全**。手册的标准反例——

```text
(let (foo)
  (unwind-protect
       (progn (setf foo (get-foo))
              (funcall function foo))
    (when foo (release-foo foo))))
```

如果超时恰好打在 `get-foo` 返回之后、`setf` 赋值之前，`release-foo`
就永远漏掉了。单个点可以加固，但 unwind 路径上的每一帧（包括系统代码）
都得加固——实际上做不到。所以：**能用 `:timeout` 参数就别用 deadline，
能用 deadline 就别用 with-timeout**；with-timeout 只兜「这段计算可能
无限跑飞、宁可带伤也要打断」的底。

## 23.11 包锁：防止误改他人包

包锁给「你自己的包」提供 ANSI 强制给 `COMMON-LISP` 包的那种保护：
`COMMON-LISP` 和 SBCL 内部包（含 `SB-EXT`）默认上锁，新建包默认不上锁
（`defpackage` 的 `:lock` 选项可以开）。它是防手滑的护栏，**不是安全机制**。

违规分两类：

- **词法绑定/声明**撞锁（`let`/`flet`/`labels`/`macrolet`/`declare`
  绑了锁包里的名字）：编译期 warning + 运行到该形式时 `program-error`。
  可以用 `sb-ext:disable-package-locks` 声明局部豁免，
  `sb-ext:enable-package-locks` 恢复——`with-foo` 这类宏包一层
  `locally` 就能安全地给自己的 `foo` 建词法绑定。
- **其它操作**撞锁（给锁包 intern/import/export 符号、定义锁包符号的
  函数/宏/类型/setf 展开器、改包结构等）：抛**可继续**的错误，
  类型是 `sb-ext:package-lock-violation` 的子类型——
  包级操作 `sb-ext:package-locked-error`，符号级操作
  `sb-ext:symbol-package-locked-error`。

注意上锁之后连 **intern 一个新符号**都算违规（`COMMON-LISP` 包就享受
这条），所以下面的示例先把符号 intern 好再上锁，否则会连示例代码本身
都读不进来：

```lisp
(sb-ext:package-locked-p (find-package "COMMON-LISP")) ; => T（CL 包默认上锁）

(let* ((p (make-package "CH23-LOCK-DEMO" :use nil))
       (foo (intern "FOO" p)))                   ; 趁没锁先 intern 好符号
  (sb-ext:lock-package p)
  (list (sb-ext:package-locked-p p)              ; 上锁生效
        (handler-case                            ; 锁着时定义函数被拒
            (eval `(defun ,foo () 1))
          (sb-ext:package-lock-violation () :blocked))
        (progn (sb-ext:unlock-package p)         ; 解锁后恢复
               (eval `(defun ,foo () 2))
               (funcall foo))))                  ; => (T :BLOCKED 2)
```

上锁/解锁/查询分别是 `sb-ext:lock-package` / `sb-ext:unlock-package` /
`sb-ext:package-locked-p`（**不是** setf 接口）。
还有个相关旋钮 `sb-ext:*on-package-variance*`：`defpackage` 重定义与
现状不一致时，按包名单决定 `:warn`（尽量保留现状）还是 `:error`（给 restart）：

```lisp
;; (setf sb-ext:*on-package-variance* '(:warn (:swank) :error t))
;; → SWANK 包不一致只警告，其它包不一致直接报错
```

## 23.12 *features* 与实现自检

`*features*` 含 `:sbcl`、`:sb-thread`、`:little-endian`、`:unix` 等——
`#+` 的数据源。跨实现时是分发依据（22 章）。

```lisp
(and (member :sbcl *features*) t)          ; => T
(and (member :sb-thread *features*) t)     ; => T
(and (member :little-endian *features*) t) ; => T
```

## 23.13 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| `Don't know how to REQUIRE SB-THREAD` | 它在核心里 | 直接用，别 require |
| require 后同形式里用 `pkg:sym` 读不到 | 读入先于求值 | 分两个顶层形式 |
| `Couldn't execute "echo"` | 没加 `:search t` | 加上，或给绝对路径 |
| `:output :string` 报错 | 不支持 | 给流（with-output-to-string） |
| 管道/通配符不生效 | run-program 不经过 shell | 显式 `/bin/sh -c` |
| POSIX 上跑 `cmd /c` | 平台写死 | `#+win32` 分发 |
| save-lisp-and-die 后代码没执行 | 它不返回 | 放最后一条 |
| `:compression` 报错 | 构建没带 `:sb-core-compression` | 查 `*features*` 再决定 |
| 终结器导致对象永不回收 | 闭包抓了对象自己 | 只抓句柄等资源标识 |
| atomic-incf「没生效」错觉 | 它返回旧值 | 看 place 的当前值 |
| with-timeout 漏清理 | 异步 unwind 打在资源获取与赋值之间 | 优先 :timeout 参数 / deadline |
| 改 CL 包名字报 violation | 包锁 | 自己的符号放自己的包；确需词法重用就 `disable-package-locks` 声明 |
| `(lisp-implementation-version)` 断言翻车 | 环境相关值 | 文档里这类值不写死断言 |

---

上一章：[22 实现对比与可移植性](22-implementations.md) · 下一章：[24 SBCL 扩展 II：线程](24-sbcl-threads.md)
