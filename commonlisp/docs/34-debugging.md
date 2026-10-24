# 34 · 调试器、追踪与单步（SBCL）

> 配套示例：[`examples/34_debug/`](../examples/34_debug/main.lisp)（channel: sbcl）
>
> 本章把 SBCL 手册第 5 章（Debugging）完整提炼：调试器的进入与命令循环、
> 栈帧与变量怎么读、源码位置、debug 优化品质、断点、单步、LDB，以及
> `trace` 的全部选项。读完你不需要再去翻手册。

SBCL 的调试器工作在**编译代码**上——这是它与「解释器单步」气质完全不同的
根源：帧可能被尾调用优化吃掉、变量可能因为寄存器复用而「不可用」、源码位置
依赖编译期记录的 debug 信息。本章的主线就是讲清三件事：**怎么进调试器、
进去之后能看什么能做什么、怎么让编译器多留调试信息**。

## 34.1 调试器何时出现

四种途径会让 SBCL 进入调试器：

1. `error` 信号了错误且没有任何 handler 转移控制；
2. 显式调用 `break`；
3. `signal` 信号的条件类型匹配 `*break-on-signals*`（默认 `NIL`，即谁都不是）；
4. 直接调用 `invoke-debugger`。

注意第 3 条里 `signal` 本身的语义：**没有 handler 时 `signal` 安静返回
`NIL`**，不会像 `warn` 那样打印、更不会进调试器：

```lisp
(signal 'simple-warning :format-control "没人处理，安静通过") ; => NIL
```

把 `*break-on-signals*` 绑成 `'warning` 之后，上面这行就会进调试器——它是
「我想在某种条件被信号的**当下**看看栈」的开关，不要和 handler 混淆。

进调试器之前还有两道钩子，SBCL 把它们分得很清楚：

- **`*debugger-hook*`（ANSI）**：调试器即将进入时调用，传两个参数——条件
  对象和钩子之前的值；调用期间 `*debugger-hook*` 被绑成 `NIL` 防递归。
  但 ANSI 明确规定：**`break` 进入调试器时不调用它**。
- **`sb-ext:*invoke-debugger-hook*`（SBCL 扩展）**：**任何**进入途径都会
  调用（包括 `break`），参数约定相同。想提供替代调试界面（比如把错误记
  日志、发告警）就用它。

利用钩子可以在错误到达交互调试器之前拦截。下面这段在钩子里直接调用一个
restart，让错误「无声地」被处理掉：

```lisp
(let ((sb-ext:*invoke-debugger-hook* nil)   ; 清掉 --non-interactive 装的退出钩子
      (*debugger-hook* (lambda (condition hook)
                         (declare (ignore condition hook))
                         (invoke-restart 'recover))))
  (restart-case
      (invoke-debugger (make-condition 'simple-error
                         :format-control "演示：被钩子拦截"))
    (recover () :RECOVERED))) ; => :RECOVERED
```

为什么用 `invoke-debugger` 而不是直接 `(error ...)`？因为条件系统先找
handler、找不到才进调试器——只要外层有任何 `error` 的 handler（比如测试
框架、批处理脚本的兜底 handler-case），`(error ...)` 就被半路接走，钩子
根本没机会跑。`invoke-debugger` 是上一节列的第四条进入途径，**不做 handler
搜索，直接进调试器**，钩子的行为和未处理 error 到达时完全一致；生产代码里
把条件记日志、调 restart 恢复的场景，写法和上面一模一样。

`--non-interactive`（以及 `--disable-debugger`）启动的镜像里，
`*invoke-debugger-hook*` 上装了一个「打印栈然后退出进程」的钩子——这就是
批处理模式下未处理错误直接挂掉的原因。演示里先把它绑成 `NIL`，正常的
`*debugger-hook*` 路径才轮得到。交互式 REPL 下不需要这一绑。

**生产部署的含义**：常驻服务要么用 `--disable-debugger` 让未处理错误立即
以非零码退出（交给进程 supervisor 重启），要么在钩子里记日志后调 restart
恢复；最糟的是留着交互调试器等一个永远不来的键盘输入。

## 34.2 命令循环：会话长什么样

调试器是一个和顶层类似的 read-eval-print 循环，但**行首的符号会被优先解释
成调试器命令**而不是求值。规则：

- 命令 = 符号名 + 同行参数；有些命令会再提示输入；
- 命令可以缩写成**任何无歧义的前缀**：`help` 可以打 `h`、`he`；
- 命令**与包无关**：任何包下同名的符号都认。如果你有个变量恰好叫 `help`
  想看它的值，包一层 `(progn help)` 就把它藏起来不当命令解析；
- 提示符是 `帧号]`，帧从栈顶（最近调用）的 0 号开始向下编号；调试器里再
  进调试器（嵌套）时提示符变成 `帧号[嵌套层]`，如 `0[2]`。

两个控制变量：

- `sb-debug:*debug-beginner-help-p*`（默认 `T`）：进调试器时多打几行新手
  提示；嫌啰嗦绑成 `NIL`；
- `sb-ext:*debug-print-variable-alist*`（默认 `NIL`）：一个 alist，调试
  命令执行期间把 car 位置的特殊变量绑成 cdr 的值。例如
  `((*print-length* . 10) (*print-level* . 6) (*print-pretty* . nil))`
  可以让调试器里打印的结构更紧凑，同变量出现多次时后面的绑定生效。

一次典型会话长这样（`text` 示意，不进自动验证）：

```text
* (defun half (x) (/ x 2))
* (half "不是数字")

debugger invoked on a TYPE-ERROR: ...
restarts (invokable by number or by possibly-abbreviated name):
  0: [ABORT] Reduce debugger level ...
  1:         Restart at toplevel READ/EVAL/PRINT loop.
(HALF "不是数字")
0] backtrace 2
0: (HALF "不是数字")
1: ("top level form") [toplevel]
0] 0
```

最后一行打 `0` 是「调用 0 号 restart」的短形式——restart 编号可以直接当
命令打（见 34.6）。

## 34.3 栈帧怎么读

调试器把当前函数调用打成 `(函数名 实参...)` 的样子，规则：

- 显示的是**实际参数值**，不是形参名；
- `&rest` 参数**摊平**成一个个独立实参打印；但如果 `&rest` 和 `&key`
  同时出现，只显示 rest 列表本身（否则关键字参数会重复两遍）；
- `#<unused-arg>` 表示这个参数在函数体里从没被引用过，编译器干脆没留值；
- `#<unavailable-arg>` 表示值不可得——位置被复用或 debug 信息不足（见
  34.4 的可用性规则）。

帧的「名字」告诉你这是什么帧：

- 全局 `defun`：就是函数名符号；
- 局部函数：`(FLET 名 :IN 外层)`、`(LABELS 名 :IN 外层)`；
- 匿名 lambda：`(LAMBDA (参数) :IN 来源)`；
- 字符串名的帧是运行时内部帧，如 `("varargs entry for ...")`、
  `("top level form") [toplevel]`——external entry、cleanup、optional
  参数处理等辅助帧都长这样；
- **被内联的函数没有帧**（它已没有调用）；**尾调用会吃掉调用者的帧**。

最后一条值得实测。先用 `sb-debug:map-backtrace` 把栈帧名字收集成列表——
这是程序化抓栈的标准做法，不依赖交互调试器：

```lisp
(defun frame-names ()
  (let ((names '()))
    (sb-debug:map-backtrace
     (lambda (f) (push (sb-di:debug-fun-name (sb-di:frame-debug-fun f)) names))
     :count 10)
    (nreverse names)))
(defun caller-nontail () (cons :keep (frame-names)))   ; 非尾调用：帧留下
(defun caller-tail () (frame-names))                    ; 尾调用：帧被吃掉
(if (member 'caller-nontail (cdr (caller-nontail))) :PRESENT :GONE) ; => :PRESENT
(if (member 'caller-tail (caller-tail)) :PRESENT :GONE) ; => :GONE
```

`caller-nontail` 在调用 `frame-names` 后还要 `cons`，所以它的帧在栈上；
`caller-tail` 是裸尾调用，帧被尾调用优化（TCO）回收——断言证明它**不在**
自己的调用栈里。调试递归深的程序时记住这个不对称：栈上看不到不等于没调
用，可能只是尾位置。

帧号显示为 `unknown location`（位置未知）有三个原因：编译时 debug 品质
小于 2；被 C-c 之类的异步中断打断（没有安全点信息）；以及 unsafe 代码里
的硬件错误（如除零）。

程序化抓栈的全家福（签名用 `text` 示意）：

```text
sb-debug:print-backtrace &key stream start from count print-thread
                          print-pc argument-limit print-frame-source
                          method-frame-style emergency-best-effort
sb-debug:backtrace &optional count stream        ; 上面者的简写
sb-debug:backtrace-as-list &optional count       ; 每帧一个字符串的列表
sb-debug:list-backtrace &key count argument-limit start ...
sb-debug:map-backtrace function &key start from count
sb-debug:backtrace-all-threads                   ; 所有线程各一份栈
```

`print-backtrace` 默认打到 `*debug-io*`、最多 `sb-debug:*backtrace-
frame-count*`（默认 1000）帧；`:from` 指定帧编号的相对基准
（`:debugger-frame`/`:current-frame`/`:interrupted-frame` 或帧对象）。
`backtrace-all-threads` 在多线程服务里排查死锁时特别有用——一次拿到每个
线程的栈。

## 34.4 看变量：list-locals 与 sb-debug:var

调试器里 `list-locals`（缩写 `l`）列出当前帧能看到的局部变量；`sb-debug:var`
按名取值：

```text
0] list-locals
X  = 3
Y  = 10
0] (sb-debug:var 'x)
3
```

同名变量（不同 let 层）用 `X`、`X#1`、`X#2`……区分，`var` 的第二个可选
参数就是这个序号。`var` 返回的是** symbol-macrolet 绑定**，因此可以
`(setf (sb-debug:var 'x) 99)` 改正在跑的帧里的值——但有两条警告：

1. 给变量 setq 一个编译器**已证明它不可能取的类型**的值，后果自负（优化
   代码里类型假设已写死在指令里）；
2. 变量值「不可用」时就别指望改它有效。

可用性规则（手册原文的精确版）：

| 变量类别 | 什么时候能看 |
|---|---|
| 参数 | `debug ≥ 1` 且 `speed < 3`；若被 setq 过还要 known location |
| 非参数局部变量 | `debug ≥ 2` 且有 known location（即变量「活着」且位置唯一）|
| uninterned 符号变量 | 仅 `debug = 3`（同时禁止 lifetime 分析）|

「known location」指编译器能证明变量此刻有唯一确定的存放位置；寄存器复用、
变量已死都会让它变成 `#<unavailable-arg>`。**`debug 3` 会禁止 lifetime
分析**——变量的值在整个作用域内都保持可见，代价是寄存器/栈位不能复用。

## 34.5 源码位置与 debug 品质

`source [n]` 命令显示当前帧的代码出自哪个文件、对应哪个源形式。规则：

- 打印的是**原始源码里包住出错形式的最内层列表**；出错形式本身不是列表
  （比如只是个变量引用）时打印某个外层形式；
- 代码若来自宏展开或编译器源级优化，打印的是**展开前的原始宏调用**——
  定义 `(defmacro mymac () '(myfun))` 后 `foo` 里调 `(mymac)`，出错时
  `source` 打的是 `(MYMAC)` 而不是 `(MYFUN)`；
- 给 `source` 一个数字 n 就多套 n 层 enclosing 形式打印，真正的源形式会
  被包成 `(#:***HERE*** 源形式)` 标出来；
- 函数是 `compile-file` 编译的而源文件后来**被移动过**时，SBCL 用启发式
  找源，找不到会在用源码时给警告。

能看到多少，取决于编译时的 `debug` 优化品质。手册的四级定义：

| debug 值 | 你得到什么 |
|---|---|
| 0 | 回溯里只有函数名；栈至少可解析、能走路 |
| 1 | 参数变量可看（未被 setq 且 speed≠3）；有参数个数等文档信息 |
| 2 | interned 局部变量可看；有源码位置；有 lifetime（known location）信息 |
| 3 | uninterned 变量也能看；**禁止 lifetime 分析**（变量全作用域可见）|

`debug 3` 还有三个联动效果：**尾调用优化被禁用**（回溯能看到所有帧，包括
尾位置的）；**局部函数不再内联**（所以 flet/labels 可以被 trace）；以及当
`speed 3` 同时存在时调试器本身变慢（参数的特判路径被优化掉了，trade-off
不可避免，但 debug ≥ 2 时不算严重）。

两个政策门槛：

- `debug > max(speed, space)`：调试器的 `return 值`（从当前帧直接返回）与
  `restart-frame`（重跑当前帧）可用；
- `debug > max(speed, space, compilation-speed)`：代码可插桩**单步**
  （见 34.8）。

`debug 3` 禁 TCO 这件事可以当场验证——34.3 的 `frame-names` 借过来，
同一个尾调用在两种政策下各编译一次：

```lisp
(defun tco-default () (frame-names))
(if (member 'tco-default (tco-default)) :PRESENT :GONE) ; => :GONE
(declaim (optimize (debug 3)))
(defun tco-debug3 () (frame-names))
(declaim (optimize (debug 1)))   ; 恢复默认政策，别污染后续编译
(if (member 'tco-debug3 (tco-debug3)) :PRESENT :GONE) ; => :PRESENT
```

默认政策下尾调用帧被吃掉（`:GONE`）；`debug 3` 下同一个形状的调用帧完整
保留（`:PRESENT`）。`declaim` 是全局宣言，演示完立刻宣言回 `debug 1`
（SBCL 的默认值），免得影响这个文件之后编译的所有代码——26 章讲性能时
刚好需要相反的设置，两章对照着看。

## 34.6 退出与信息命令

退出调试器的命令：

- `toplevel`：直接抛回顶层 REPL；
- `restart [n]` 或裸打 `n`：调用 `error` 命令列出的第 n 个 restart。不给
  n 就列出现有 restart。注意短形式里**打一个没有对应 restart 的整数会被
  当普通表达式求值**（REPL 语义），不是错误；
- `continue`、`abort`：严格说这不是调试器命令，而是两个常见 restart 的
  名字——打在命令行上按 restart 解析。`abort` 可以一层层弹出嵌套调试器；
- `return 值`：让当前帧直接返回指定值（政策门槛见 34.5；值的类型必须是
  SBCL 期望这个帧返回的类型，否则后果自负）；
- `restart-frame`：从头重跑当前帧（仅全局函数的帧；若在调试器里重定义过
  该函数，重跑用的是新定义）。

信息命令：

- `help` 或 `?`：命令一览；
- `describe`：对当前函数调 `describe`，并报告局部变量个数；
- `print`：按「移动到该帧」的样子重打当前调用；
- `error`：重打触发调试器的条件和可用 restart；
- `backtrace [n]`：从当前帧向栈底打 n 帧（不给就打全部），打印格式受
  `sb-ext:*debug-print-variable-alist*` 控制。

## 34.7 编译代码里的断点

SBCL 支持在**编译好的函数内部**下断点。前提：断点只能下在 known
location 上，所以 `debug` 至少要是 2，否则这组命令基本没用。

- `breakpoint 位置 [:condition f][:break f][:print f][:function f]`：
  下断点。`位置` 是 `list-locations` 打的整数编号，或关键字 `:start`/`:s`
  （函数入口）、`:end`/`:e`（函数出口）。四个选项语义和 `trace` 的同名
  选项一致（34.10）；
- `list-locations [函数]`（缩写 `ll`）：列出当前帧的函数（或指定函数）
  所有 code location，格式是「编号: 源形式」；连续同源的编号会合写成
  `3-5:` 区间。一次普通函数调用在**调用前后各有一个** known location，
  所以同一源形式出现两个编号很正常。列过的函数成为之后 `breakpoint`
  的默认对象；
- `list-breakpoints`（`lb`）：列出现有断点及编号；
- `delete-breakpoint [n]`（`db`）：删第 n 个；不给 n 全删；
- `step*`：走到当前函数里的下一个断点位置。**总是越过**函数调用，不进
  去。

手册的阶乘会话（自包含重述）：定义

```text
(defun ! (n)
  (if (zerop n)
      1
      (* n (! (1- n)))))
```

`(break)` 进调试器后，`ll #'!` 列出 0-10 号位置（0-1 是整个 named-lambda，
4 是 `(* N (! (1- N)))`，6 是递归调用 `(! (1- N))`……）；`br 4` 在乘法处
下断点（回显 `1: 4 in !` 表示 1 号断点）；`toplevel` 退出后跑 `(! 10)`，
执行到乘法就 `*Breakpoint hit*` 重新进调试器，当前帧是 `(! 10)`，`source`
显示 `(* N (! (1- N)))`；打 `step*` 走到 `(! 9)` 的乘法再停——每次递归
都会在同一源码位置停下，直到 `db` 删断点。

`step*` 和 34.8 的插桩单步不同：它**不需要**代码带步进插桩，只是走到下一
个编译期记录的 code location，开销低得多；代价是粒度粗（只能停在已知位
置）。手册说将来它可能好到取代插桩单步。

## 34.8 单步执行

插桩式单步用 ANSI 的 `step` 宏启动，或在调试器里用这组命令：

- `start`：选 `continue` restart 并开始单步（没开始过之前其余单步命令
  不可用）；
- `step`：步入——当前形式求值后，在**下一个带插桩的形式**处再停；
- `next`：步过——当前形式求完再停；
- `out`：步出——当前帧返回后再停；
- `stop`：结束单步，恢复正常执行。

两个前提缺一不可：被单步的代码编译时 `debug > max(speed, space,
compilation-speed)`（34.5 的门槛）；`step form` 里**词法作用域之外**的
函数调用，只有那些函数本身也按可步进政策编译过才能步入。交互会话示意：

```text
* (step (fact34 3))
;=> *Step*
(FACT34 3)   ; 停在入口
0] step
(IF (ZEROP N) 1 (* N (FACT34 (1- N))))   ; 步入函数体
0] next
...
```

`--non-interactive` 下别试：`step` 触发 STEP 条件进调试器，而调试器被禁
就直接退出了（34.9）。

## 34.9 LDB 与彻底关掉调试器

LDB 是 **C 实现的低层调试器**，在 Lisp 堆或栈耗尽、Lisp 调试器自身无法
运行时仍能工作。运行时的底层断言失败时：若 SBCL 编译时没加
`--without-sb-ldb` 且没用 `--disable-ldb`（或 `sb-ext:disable-debugger`）
禁掉，就进 LDB；否则打印最多 100 帧回溯然后以**非零退出码**退出。LDB 提
示符下打 `help` 看命令。相关的还有 `--lose-on-corruption` 运行时选项。

程序内开关：

```lisp
(progn (sb-ext:disable-debugger)   ; 关 Lisp 调试器 + LDB（等价 --disable-debugger + --disable-ldb）
       (sb-ext:enable-debugger)    ; 恢复
       (sb-ext:disable-debugger)   ; 本镜像以 --non-interactive 启动，关回去保持原状
       :OK) ; => :OK
```

常驻服务的标准姿势：命令行 `--disable-debugger`（未处理错误打栈即退，配
合 supervisor 重启），应用内部用 34.11 的 handler 模式自己记栈。

## 34.10 trace：函数追踪完全指南

`trace` 让指定函数在**每次进入和返回时打印实参与返回值**，输出写到
`*trace-output*`。最基本的形式（名字不求值）：

```lisp
(defun fact34 (n) (if (zerop n) 1 (* n (fact34 (1- n)))))
(trace fact34)
(fact34 3) ; => 6
(untrace fact34)
```

交互下实际看到的追踪输出长这样（数字是调用深度）：

```text
  0: (FACT34 3)
    1: (FACT34 2)
      2: (FACT34 1)
        3: (FACT34 0)
        3: FACT34 returned 1
      2: FACT34 returned 1
    1: FACT34 returned 2
  0: FACT34 returned 6
```

**能 trace 的「名字」**有六种：

| 形式 | 追踪对象 |
|---|---|
| `符号` / `(setf 名)` 等 fname | 函数或宏 |
| `(method 名 限定符 (特化符))` | 某个具体方法 |
| `(compiler-macro 符号)` | 编译器宏 |
| `(labels 名 :in 外层)` / `(flet 名 :in 外层)` | 局部函数（外层名递归适用上面任一形式；可能要 `debug 3` 防内联）|
| `"包名字符串"` | 该包主符号上有函数定义的全部函数 |
| `:function 函数形式` | 对求值出的函数对象本身（匿名函数也能追）|

局部函数追踪实测：

```lisp
(defun outer-labels34 (n)
  (labels ((walk (x) (if (zerop x) 0 (1+ (walk (1- x))))))
    (walk n)))
(trace (labels walk :in outer-labels34))
(outer-labels34 2) ; => 2
(untrace)
```

`:methods t` 让泛型函数的**所有方法**连同泛型本身一起被追：

```lisp
(defgeneric area34 (s))
(defmethod area34 ((s integer)) (* s s))
(trace area34 :methods t)
(area34 3) ; => 9
(untrace area34)
```

**选项**：`trace` 语法是 `trace {全局选项 值}* {名字 {局部选项 值}*}*`——
第一个名字之前的选项对本次 trace 的全部函数生效；跟在名字后面的只影响紧
挨着的前一个名字，并覆盖同名全局选项。全部选项：

- `:report 类型`：报告方式。`trace`（默认）立即打印；`nil` 不打印只执行
  其它选项；其它情况当作**函数指示符**，每个追踪事件 funcall 一次，传 5
  个参数：深度（非负整数）、函数名或函数对象、事件类别
  （`:enter`/`:exit`/`:non-local-exit`）、栈帧、值列表（实参或返回值）。
  注意这个值**在宏展开期就要是 symbol 或函数对象**——写 lambda 形式会
  报「not a valid TRACE :REPORT type」，先 `defun` 一个再传名字；
- `:condition form` / `:condition-after form` / `:condition-all form`：
  form 为假就什么都不做。`-after` 抑制进入时的打印、在返回时测试；
  `-all` 进出都测；
- `:break form` / `:break-after` / `:break-all`：form 为真时在进入/返回
  /两处进调试器；
- `:print form` / `:print-after` / `:print-all`：额外求值 form 并打印结果，
  可写多次打多个值；
- `:wherein 名字或列表`：只有当调用链上有这些函数之一**包着**本次调用时
  才追踪（匿名函数的名是 `"defun FOO"` 这样的字符串）；
- `:encapsulate {t | nil | :default}`：选实现机制（下面详说）；
- `:function 形式`：见名字表。

`:condition`/`:break`/`:print` 的 form 在**模拟被调函数词法环境**里求值，
可以用 `sb-debug:var` 取局部变量、`(sb-debug:arg n)` 取第 n 个实参；在
`-after` 形式里，`(sb-debug:arg n)` 变成第 n 个**返回值**。条件追踪：

```lisp
(defun add34 (a b) (+ a b))
(trace add34 :condition (eql (sb-debug:arg 0) 10))
(add34 1 2)     ; 条件不成立：完全不打印
(add34 10 20) ; => 30
(untrace add34)
```

`:print` 的输出会**回显 form 本身再跟结果**，例如
`:print (list :args (sb-debug:arg 0) (sb-debug:arg 1))` 打出来是
`0: (LIST :ARGS (ARG 0) (ARG 1)) = (:ARGS 10 20)`。

`:wherein` 回答「这个函数是被谁调用的」：

```lisp
(defun inner34 (x) (* x 2))
(defun outer34 (x) (1+ (inner34 x)))   ; 1+ 让调用不在尾位置
(trace inner34 :wherein outer34)
(inner34 5)     ; 直接调：调用链上没有 OUTER34，不打印
(outer34 5) ; => 11
(untrace inner34)
```

**这里有个和 34.3 直接相关的坑**：`:wherein` 靠回溯找外层函数，如果
`outer34` 对 `inner34` 是**尾调用**，外层帧被 TCO 吃掉，匹配就永远失败——
上面特意写的 `1+` 就是为了让 `outer34` 的帧留在栈上。`:wherein` 失灵时
先怀疑尾调用和内联。

自定义 `:report`（先命名再传）：

```lisp
(defun reporter34 (depth name kind frame values)
  (declare (ignore frame))
  (format t "[自报] 深度~A ~A ~A => ~A~%" depth name kind values))
(defun noisy34 (x) (+ x 1))
(trace noisy34 :report reporter34)
(noisy34 41) ; => 42
(untrace noisy34)
```

调用一次打两行：`[自报] 深度0 NOISY34 ENTER => (41)` 和
`[自报] 深度0 NOISY34 EXIT => (42)`。**自定义 report 的输出去向由你的
函数自己决定**（这里打 stdout），默认报告才走 `*trace-output*`。

**封装 vs 断点**两种实现：

| `:encapsulate` | 机制 | 含义 |
|---|---|---|
| `t`（默认）| 重定义函数名（encapsulation）| 经符号的调用被追；选项 form **不在**被调函数的词法环境求值（但 `sb-debug:arg` 仍可用）|
| `nil` | 断点（破坏性地改函数对象）| `funcall` 直接调函数对象也追得上；函数对象身份不变；匿名/局部函数可追 |
| `:default` | 解释函数与 funcallable 实例用封装，其余用断点 | 注意它不是默认值——默认是 `t` |

有一类函数用已知返回约定（known return convention）优化过，断点式追踪会
直接报错：

```text
Error in function FOO: :FUNCTION-END breakpoints are
currently unsupported for the known return convention.
```

对策就是 `(trace foo :encapsulate t)`。

四个控制变量：`sb-debug:*trace-indentation-step*`（每层缩进增量，默认
2）、`sb-debug:*max-trace-indentation*`（缩进超过它归零重排，默认 40）、
`sb-debug:*trace-encapsulate-default*`（`:encapsulate` 缺省值，默认
`T`）、`sb-debug:*trace-report-default*`（`:report` 缺省值，默认
`TRACE`）。

`untrace` 拆掉追踪：`(untrace 名字...)` 卸指定函数，裸 `(untrace)` 全部
卸掉。顺手养成「追完就 untrace」的习惯——追踪包装有开销，留在那里还会
持续往 `*trace-output*` 刷屏。

## 34.11 实战模式

**在 handler 里抓栈**。`handler-case` 的 handler 运行时栈已经回卷，抓不
到出错现场；`handler-bind` 的 handler 在回卷**之前**运行。但 CL 按「从
内到外」的顺序找 handler，所以抓栈的 `handler-bind` 必须放在**比兜底
handler 更内**的位置，否则兜底先跑、栈先没了：

```lisp
(defun crash34 (x y) (+ x y))   ; y 传字符串时运行期类型错误
(let ((bt-string nil))
  (handler-case
      (handler-bind ((serious-condition
                       (lambda (c)
                         (declare (ignore c))
                         (setf bt-string
                               (with-output-to-string (s)
                                 (sb-debug:print-backtrace :stream s :count 5))))))
        (crash34 1 "oops"))
    (serious-condition () nil))
  (and bt-string (search "CRASH34" bt-string) t)) ; => T
```

内层 `handler-bind` 抓完栈串（此时 `CRASH34` 的帧还在栈上）后返回
`NIL`——handler 不转移控制，错误继续向外，被外层 `handler-case` 兜住。
断言证明抓到的栈串里确实含 `CRASH34`。把 `bt-string` 换成写日志文件就
是生产服务的错误上报骨架。

**钩子拦截**：常驻进程不让人坐键盘前，就用 34.1 的
`*invoke-debugger-hook*`/`*debugger-hook*` 模式在进调试器前记日志、调
restart。

**多线程**：`sb-debug:backtrace-all-threads` 一次拿全部线程的栈，配合
24 章的互斥锁调试死锁。

**性能对照**：26 章的 `sb-profile`/`sb-sprof` 回答「慢在哪」，本章的
trace/断点回答「为什么错」——被内联的函数两边都看不见，排查前先
`(declaim (notinline 嫌疑函数))` 重编译。

## 小结

- 进调试器的四条路：未处理错误、`break`、`*break-on-signals*`、
  `invoke-debugger`；钩子分 `*debugger-hook*`（`break` 不触发）与
  `sb-ext:*invoke-debugger-hook*`（都触发）；
- 命令循环提示符 `帧号]`，命令可缩写、与包无关；`progn` 包住与命令同名
  的变量；
- 帧显示实际参数；`&rest` 摊平；`#<unused-arg>`/`#<unavailable-arg>`
  各是一种「没值」；**TCO 与内联会吃帧**；
- 变量可用性：参数 `debug≥1` 且 `speed<3`；局部 `debug≥2` 且 known
  location；`debug 3` 禁 lifetime 分析与 TCO、放开 uninterned 变量；
- `debug>max(speed,space)` 解锁 `return`/`restart-frame`；再大于
  `compilation-speed` 解锁插桩单步；
- 断点命令组（`breakpoint`/`ll`/`lb`/`db`/`step*`）作用于编译代码的
  known location，需 `debug≥2`；
- LDB 是 C 层的最后防线；生产用 `--disable-debugger` + 自己的钩子；
- `trace` 六种名字、全套选项（`:report`/`:condition`/`:break`/`:print`
  三兄弟、`:wherein`、`:encapsulate`、`:methods`、`:function`），form
  里用 `sb-debug:arg`/`sb-debug:var`；`:wherein` 失灵先查尾调用。
