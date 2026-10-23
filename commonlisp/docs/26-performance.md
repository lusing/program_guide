# 26 · 性能优化（SBCL 实测）

> 配套示例：[`examples/26_perf/`](../examples/26_perf/main.lisp)（channel: sbcl）
>
> 声明部分是 ANSI 的（13 章），收益实测主要在 SBCL——它是「始终编译 + 类型推理」
> 的实现；CLISP 主要解释执行，同一份声明收益有限（22 章）。
>
> 本章把 SBCL 手册第 4 章（Compiler）、第 6 章（Efficiency）与第 16 章
> （Profiling）的核心内容完整提炼：读完你不需要再去翻手册。

## 26.1 先测量：time 的正确读法

**先测量，后优化。** `time` 宏是最省事的起点：

```text
(time (loop for i from 1 to 1000000 sum i))
Evaluation took:
  0.002 seconds of real time
  0.004 seconds of total run time
  ...
  0 bytes consed
```

**看 `bytes consed` 这一行比看时间更有用**——它告诉你这段代码有没有分配
内存、GC 压力大不大。时间受机器状态影响波动，分配量则是确定性的。

## 26.2 确定性剖析器 sb-profile

`sb-profile` 在核心里，**不用 require**。它给指定函数裹上计数包装，属于
「逐函数插桩」的确定性剖析：

```lisp
(defun slow-add (a b) (+ a b))
(sb-profile:profile slow-add)
(dotimes (i 1000) (slow-add 1 2))
(sb-profile:report)
```

报告长这样（每次数值不同，看结构）：

```text
  seconds  |     gc     |   consed   |  calls |  sec/call  |  name
---------------------------------------------------------------
     0.000 |      0.000 |          0 |  1,000 |    0.000000 | SLOW-ADD
```

逐列读：总秒数、GC 耗时、分配字节、调用次数、每次调用秒数。配套的
`(sb-profile:reset)` 清零计数、`(sb-profile:unprofile)` 拆掉包装；
`(sb-profile:profile "包名")` 用字符串剖析整个包；`report` 接受
`:limit n` 只看前 n 名。剖析完记得卸掉：

```lisp
(sb-profile:unprofile)
```

**三个实测注意**：

- `report` 会先打一行 `measuring PROFILE overhead..done`——它**绕过 Lisp
  流直接写控制终端**：`--load` 方式运行时 stderr 里没有它（判定不受影响），
  `--script` 方式则会落进 stderr。本仓库统一 `--load` 就是为这个；
- 开销补偿基于运行时间差值估算，涉及 bignum 的超长跑进程里补偿会明显失真；
- **多线程并行执行时，归到每个函数头上的 consing 是不准的**（计时仍可用）；
- 被内联的函数不会出现在任何剖析结果里——它已经没有「调用」可言。

## 26.3 统计剖析器 sb-sprof

contrib 的 `sb-sprof`（**要 require**）是另一条路：不给函数插桩，而是按固定
间隔对程序栈**采样**，开销与函数调用频率无关。它适合剖析 COMMON-LISP 包里
的函数、SBCL 内部、或插桩开销大到扭曲结果的代码：

```lisp
(require :sb-sprof)
```

一个可跑的最小例子（`:report nil` 表示只采样、先不打印，宏返回 body 的值）：

```lisp
(defun sum-02 (n)
  (declare (type fixnum n))
  (let ((acc 0))
    (declare (type fixnum acc))
    (loop for i fixnum from 1 to n do (incf acc i))
    acc))
(sb-sprof:with-profiling (:max-samples 100 :report nil :mode :time)
  (sum-02 100000))                         ; => 5000050000
```

`with-profiling` 的关键字全集：

| 关键字 | 含义 | 默认 |
|---|---|---|
| `:mode` | `:cpu`（CPU 时间）/ `:alloc`（分配）/ `:time`（墙钟） | `:cpu` |
| `:max-samples n` | 采满 n 个样本为止 | `*max-samples*`（50000） |
| `:sample-interval s` | 每隔 s 秒采一个样本 | `*sample-interval*` |
| `:report type` | 结束后自动出报告：`:flat` / `:graph` / `nil` 不出 | 不出 |
| `:loop t` | 反复执行 body 直到采够样本（body 太短时用） | `nil` |
| `:threads form` | 要剖析的线程列表，`:all` 全要 | `:all` |
| `:reset t` | 开始前先清掉旧样本 | — |
| `:show-progress t` | 每轮迭代打印样本计数 | — |

**macOS（Darwin）实测坑**：`:mode :cpu` 下剖析信号不按 CPU 用量比例投递到
各线程，多线程程序可能采出空调用图、某些线程的样本整个丢失。**在 macOS 上
直接养成用 `:mode :time`（墙钟）的习惯**；`:mode :alloc`（分配剖析）要求
分代 GC 构建（x86-64 的 SBCL 默认就是），栈深超过两层的回溯只在
x86/x86-64 上支持。

典型的完整用法（`:loop t` 让短函数反复跑满样本）：

```text
(sb-sprof:with-profiling (:max-samples 1000 :report :flat :loop t
                          :mode :time :show-progress t)
  (sum-02 1000))
```

flat 报告逐列解读：

```text
           Self        Total       Cumul
  Nr  Count  %     Count  %     Count  %    Calls  Function
   1     69 24.4      97 34.3      69 24.4        - SUM-02
   2     64 22.6      64 22.6     133 47.0        - SB-VM::GENERIC-+
```

- **Self**：样本正落在这个函数体内的次数（它自己花的时间）；
- **Total**：样本落在这个函数**或它调用的下游函数**里的次数；
- **Cumul**：从上到下 Self 的累计百分比，用来快速读「前 N 个函数占了
  多少时间」；
- **Calls**：调用次数——默认是 `-`，要先用
  `(sb-sprof:profile-call-counts "CL-USER")`（字符串 = 整包）显式标记。

采样数据还留在内存里时，可以用函数手动出报告，排序、截断都由你控制：

```text
(sb-sprof:report :type :flat :max 10 :min-percent 1.0
                 :sort-by :cumulative-samples)
```

`report` 返回一个 call-graph 对象（没样本时返回 `nil`），`:type :graph`
会额外打印调用图。还有一个隐藏福利：**剖析后再 `disassemble`，被采到样
的指令旁边会标注命中次数**，例如 `; 6/242 samples`——汇编级热点定位，
配合 26.6 的类型声明检查一起用。

## 26.4 读懂编译器诊断消息

SBCL 编译器的话分四个严重级别，知道哪级该紧张：

| 级别 | 含义 | 你该怎么做 |
|---|---|---|
| `ERROR` | 编译无法进行（读错误、宏展开炸了） | 必须修 |
| `WARNING` | 几乎肯定是程序错误（未定义变量、参数个数不对） | 必须修 |
| `STYLE-WARNING` | 合法但可疑的写法（未用的变量、声明了却不内联） | 强烈建议修 |
| `NOTE` | 优化器的旁白（这里没法优化、删了段死代码） | 调优时才看 |

一条诊断消息的完整结构是六部分：`file:` 指出文件与顶层形式位置；`in:`
指出在哪个函数里；接着是原始源码片段；`-->` 展示宏展开/内联的处理路径；
`==>` 之后是编译器实际看到的形态；最后是文字解释。看懂 `==>` 前后的
差异，就知道宏把你写的代码变成了什么样。

几个控制音量的变量（都在 `sb-ext` 包，默认值给出的是出厂设置）：

```lisp
sb-ext:*undefined-warning-limit*       ; => 3
sb-ext:*efficiency-note-limit*         ; => 2
sb-ext:*efficiency-note-cost-threshold*  ; => 5
sb-ext:*enclosing-source-cutoff*       ; => 1
```

- `*undefined-warning-limit*`：未定义函数/变量的 warning 打印上限，超过后
  只给汇总计数；
- `*efficiency-note-limit*`：每个函数最多报几条 efficiency note（优化器
  「这里快不起来」的提示），`*efficiency-note-cost-threshold*` 则是「预计
  收益低于几倍的 note 就不说了」——调优时把前者设大、后者设小能听到更多；
- `*enclosing-source-cutoff*`：报错时向外打印几层包裹的源码；
- `sb-ext:*compile-progress*` 非 nil 时编译器边编译边打印进度。

想彻底掐掉某一类消息，在函数内用声明：

```text
(declare (sb-ext:muffle-conditions cl:style-warning))
```

**最重要的读消息能力：听懂 "deleting unreachable code"**。手册给的经典
例子是这样一个数 `a` 的循环——注意 `pos` 被声明成 `fixnum`：

```text
(defun count-a (seq)
  (declare (optimize (speed 3) (safety 0)))
  (do ((count 0)
       (pos (position #\a seq) (position #\a seq :start (1+ pos))))
      ((null pos) count)
    (declare (type fixnum pos count))
    (incf count)))
```

`position` 找不到时返回 `nil`，但声明说 `pos` 是 `fixnum`——编译器据此
推出 `(null pos)` **恒为假**，于是把循环的终止分支当成不可达代码删掉，
同时发一条 `note: deleting unreachable code`。这个函数实际上再也停不
下来了。**unreachable code note 十有八九是在告诉你：类型声明撒谎了。**
读不出来的时侯，用最可能触发那段代码的输入实际调用一次：要么吃到类型
错误，要么证明它真的不可达。注意编译器只对文本上出现在你源码里的死码
发 note，宏展开产生的死码不报。

正确的写法不需要任何声明也很快：

```lisp
(defun count-a (seq)
  (do ((count 0)
       (pos (position #\a seq) (position #\a seq :start (1+ pos))))
      ((null pos) count)
    (incf count)))
(count-a "banana")                         ; => 3
```

## 26.5 六个优化品质与编译策略

ANSI 规定了四个品质，SBCL 加一个，加上编译速度共六个：

| 品质 | 3 意味着 | 0 意味着 |
|---|---|---|
| `speed` | 运行最快 | 编译器几乎不优化 |
| `compilation-speed` | 编译最快 | 编译慢无所谓 |
| `space` | 代码体积最小 | 体积无所谓 |
| `debug` | 调试信息最全（关尾调用优化） | 栈帧尽可能省 |
| `safety` | 全部运行期检查 | 不做运行期类型检查 |
| `sb-ext:inhibit-warnings` | 尽可能安静 | 正常发音 |

**全部默认 1**——不是 0，也不是 2。这意味着默认策略下编译器已经做了
大量优化。几个来自手册的纪律：

- 0 和 3 都是「英雄主义」极端值，**不要同时把多个品质推到 3**——收益
  递减而交互效应失控；
- 平局时编译器偏向 `safety` 与 `debug`（宁可慢一点也要抓住错误）；
- `(debug 3)` 会关闭尾调用优化（11 章实测：互递归 1000 万层爆栈）。

调优组合写在函数内部，只影响这一个函数的编译：

```lisp
(defun hot-path (n)
  (declare (optimize (speed 3) (safety 1) (debug 1))
           (type fixnum n))
  (loop for i fixnum from 1 to n sum i))
(hot-path 100)                             ; => 5050
```

全局策略才用 `(declaim (optimize ...))`——它是 proclamation，影响之后
编译的**一切**代码，教程示例里不这么做。运行时想确认当前策略，调
`(sb-ext:describe-compiler-policy)`；库里想禁止下游用户把 `safety` 降到
0，用 `(sb-ext:restrict-compiler-policy 'safety 1 3)` 钉死区间。

## 26.6 类型声明：最有效的手段，及其边界

SBCL 的编译器**免费送你一半**：它自己做类型推理（`type-of` 返回精确区间
就是证据，04 章）。声明的作用是把「编译器不确定」的地方钉死：

```lisp
(defun slow-add-2 (a b) (+ a b))           ; 通用版：全类型分派
(defun fast-add-2 (a b)
  (declare (type fixnum a b))
  (the fixnum (+ a b)))                    ; 无装箱的机器加法
(fast-add-2 3 4)                           ; => 7
```

诊断利器：`(disassemble #'fast-add-2)` 直接看汇编——有没有对
`GENERIC-+` 的调用、有没有分配指令，一目了然。

**声明之后谁来检查？** SBCL 有两条策略（历史上第三条「弱类型检查」
已移除）：

- **`safety` ≥ 1（默认）**：函数参数按声明确切检查，语义与 `typep` 一致——
  传错类型立即 type-error；
- **`safety` 0**：完全不检查，声明被当成承诺。手册原话级别的警告：这种
  代码里类型错误**可能损坏堆**——不只是算错，是整个映像都可能废掉。

`the` 同理：**它是承诺不是检查**（13 章）。别为了速度把 `safety` 降到 0
再到处 `the`——那等于关掉所有运行期检查。

**老代码迁移的三类高发事故**（手册 4.3 直接点名）：

1. `prog` 变量初始值是 `nil`，撞上 `(declare (fixnum x))` 之类的声明——
   一进入就违反声明；
2. 给 `defmacro` 的参数加类型声明**几乎总是错的**——宏参数绑定的是源码
   形式本身，不是求值结果；
3. `do` 循环变量配 `position` 时，循环最后一轮 `pos` 是 `nil`，声明
   `fixnum` 后终止测试被优化掉（就是 26.4 的 count-a）。

**ftype 声明的三条限制**（手册 4.3.4，容易踩）：

- 只有 proclaim/declaim **在调用被编译之前**生效的 ftype 才会被用来检查；
  事后补的对已编译代码无效；
- `(debug 3)` 策略下编译器**不信任** ftype（为了让你在 REPL 自由重定义）；
- CLOS 槽的 `:type` 选项只在安全（`safety` ≥ 1）代码里生效。

还有一个让人安心的机制：**编译期就能证明的类型错误只给
`style-warning`，不阻断编译**；但如果能证明触发它的值是 `nil`，连
style-warning 都不发（`nil` 常常只是占位）。宏展开里的错误想进调试器，
把 `*break-on-signals*` 绑到 `warning` 再编译。

## 26.7 源码级优化：编译器免费做的事

在写任何声明之前，先知道 SBCL 已经替你做了什么（手册 6.1）：

- **let 优化**：绑定值是常量、或绑定后不再修改的变量，直接被代入；只调
  一次的局部函数被「let 转换」——等效内联但没有代码膨胀。推论：
  **少 `setq`、多绑定**，绑定形式和赋值形式对编译器的友好度完全不同；
- **常量折叠**：`(+ 2 2)` 在编译期就变成 4；
- **无用表达式消除**：值没被使用的形式直接删除（不发 note）；
- **控制优化**：`if` 套 `if` 被重排；`tagbody` 里的形式不保证按源序执行；
- **死码消除**：见 26.4 的 unreachable code note。

**多值也有优化**：函数内部使用多值时，值可以放在寄存器里，不走栈。手册
明确指出，把两个 `let` 分别求值：改成一个 `multiple-value-bind` 包一个
`values`，**后者更高效**：

```lisp
(defun mv-demo (x)
  (multiple-value-bind (a b)
      (if x (values (1+ x) (1- x)) (values 0 0))
    (+ a b)))
(mv-demo 10)                               ; => 20
```

手册 6.1.7 的风格建议五条，值得背下来：

1. **别为了躲函数调用而写宏**——想要内联，就写函数再声明 `inline`，
   更清楚、更不易错、一样快；
2. **别写那些试图「优化展开」的宏**（比如为避免绑定变量而做的手脚）——
   编译器本来就这么干，而且它比你少犯错；
3. 清晰的地方尽管用 `labels`/`flet` 和尾调用——局部调用比全调用快；
4. 能绑定就别赋值；
5. 与其把相似代码手抄 N 份各自微调，不如定义一个宏或内联函数，让
   编译器为每个调用点做定制。

## 26.8 内联展开

机制一句话：编译器把被调函数的 `lambda` 直接插到调用点，函数调用消失。
SBCL 几乎能内联任何函数（包括带 `&key` 的），唯二的限制是：**调用点的
关键字必须是常量**，以及 `defun` 必须在空词法环境里（不能套在 `let`
里面定义全局函数）。

```lisp
(declaim (inline my-1+))
(defun my-1+ (x) (+ x 1))
(my-1+ 41)                                 ; => 42
```

**内联声明必须在 defun 之前**。编译器不替每个函数保存源码（太占空间），
只有全局 `inline`/`sb-ext:maybe-inline` 声明生效时，`defun` 才会把展开式
记录下来；`compile-file` 会把展开式写进 fasl，load 之后照样可内联。顺序
错了你会吃到这条 style-warning：

```text
; caught STYLE-WARNING:
;   Call to MY-1+ could not be inlined because its source code was not
;   saved. A global INLINE or SB-EXT:MAYBE-INLINE proclamation must be in
;   effect to save function definitions for inlining.
```

每个函数体内联展开的次数有上限（`sb-ext:*inline-expansion-limit*`，
默认 50），防自递归内联爆炸。何时该内联，手册给了两条判据：

- 剖析证明一个**简单**函数的调用开销占比可观；
- 函数小到展开后比调用指令还省地方（比如上面的 `my-1+`）。

内联真正的杀招不是省调用，而是**调用者上下文传播**：实参类型已知可
消掉运行期类型测试，实参是常量可触发常量折叠。教科书例子是 `member`
——它的 `:key`/`:test` 参数默认值都是常量，内联之后一个三测试两调用
的通用循环退化成「一测试零调用」，手册说有数量级提升：

```text
(member a l :key #'foo-a :test #'char=)
;; 内联展开并化简后等效于：
(do ((list list (cdr list)))
    ((null list) nil)
  (let ((car (car list)))
    (if (char= item (foo-a car)) (return list))))
```

**`notinline` 的正确用法**：它不是「默认不内联、偶尔内联」的开关。
`notinline` 会禁止编译器使用关于这个函数的**一切**知识（连参数个数
检查和块编译都受影响），只为一种场景准备：**函数会在运行时被重定义**，
编译器不能假设当前定义就是调用时的定义。想表达「记录下来、默认不展开、
特定调用点再展开」，手册推荐的写法是 `sb-ext:maybe-inline`——它在
`space` 为 0 时做「半内联」（同一函数内所有调用点共享一份展开的局部
副本），比 `inline` + `notinline` 的惯用法干净：

```lisp
(declaim (sb-ext:maybe-inline cube))
(defun cube (x) (* x x x))
(cube 3)                                   ; => 27
```

## 26.9 局部调用与尾调用

SBCL 有两种函数调用。**全调用**（full call）是标准调用约定：晚绑定、
参数个数检查、关键字解析、任意个数返回值——这些通用性就是 Lisp 的本色，
也都是开销。**局部调用**（local call）在编译器能同时看到调用方与被调方
时启用，省略其中大部分环节，有时完全免费。

你其实一直在用局部调用：`flet`/`labels` 定义的函数、函数自递归、甚至
`let`——编译器内部就把：

```text
(let ((a (foo)) (b (bar))) ...)
```

当成 `(funcall #'(lambda (a b) ...) (foo) (bar))` 来编译，所以「语义上
等价于 let 的局部函数调用」全部零开销。闭包也一样：局部函数引用的词法
变量被当成额外参数直接传入，**闭包环境不需要在堆上分配**——不用你手动
把 `a`、`b` 再传一遍。唯一的例外：一个变量**既被 `setq` 又被闭包引用**，
它的 indirect value cell 一定进堆。这是「少赋值」的又一条理由。

手册给的局部尾递归例子，和命令式版本编译出的代码一样好：

```lisp
(defun recurse-fact (n)
  (labels ((loop* (n total)
             (if (zerop n)
                 total
                 (loop* (1- n) (* n total)))))
    (loop* n 1)))
(recurse-fact 5)                           ; => 120
```

一个容易忽略的开销：**返回值个数可变的函数，全调用时有额外代价**。
局部调用对返回值个数固定的函数有专门支持。所以让函数总是返回相同个数的
值（必要时给 `values` 补几个 `nil`），既高效也更清爽。

**尾调用优化（TCO）**：SBCL 做了 ANSI 不要求的 TCO——尾位置的调用
被编译成「改参数 + 一条跳转」，不分配新栈帧。两个条件缺一不可：

1. 调用处于**尾位置**——不被以下任何一种形式包裹：特殊绑定（`let` 绑
   动态变量、`progv`）、`catch`、`unwind-protect`、名字被闭包捕获的
   `block`、go 标签被闭包捕获的 `tagbody`（它们都要求在栈上保留清理
   现场）；
2. `debug` 品质 ≤ 2（默认 1，没问题；`(debug 3)` 就关了）。

局部调用和全调用都可以是尾调用。TCO 的实际意义：**互相递归的一组函数
可以当状态机写**，每层状态转移不耗栈：

```lisp
(defun even-p* (n) (if (zerop n) t (odd-p* (1- n))))
(defun odd-p* (n) (if (zerop n) nil (even-p* (1- n))))
(even-p* 10000)                            ; => T
```

一个调试注意：局部自递归不走 `symbol-function`，所以 `trace` 只能看到
第一次进入，看不到递归的每一层——这不是 trace 坏了。

## 26.10 块编译

块编译把一组 `defun` 之间的全调用也变成局部调用，哪怕调用点在被调函数
之前、甚至在另一个顶层形式里。语义可以想像成：编译器把块内所有 `defun`
揉进一个大 `labels`，再把**入口函数**安装回 `symbol-function`：

```lisp
(declaim (sb-ext:start-block bc-entry))
(defun bc-entry (x) (bc-helper (1+ x)))
(defun bc-helper (y) (* y 2))
(declaim (sb-ext:end-block))
(bc-entry 5)                               ; => 12
```

`start-block` 的参数列出入口（不给参数 = 全部函数都是入口）。**非入口
函数不安装全局定义**，块内对它的调用全是编译期确定的局部调用；只被调用
一次的非入口函数直接被 let 转换——等于零成本的代码组织。代价：块内调用
不再经过 `symbol-function`，**重定义 `bc-helper` 不影响 `bc-entry`**；
块编译吃内存惊人；非空词法环境里的 `defun` 进不了块。

默认 `sb-ext:*block-compile-default*` 是 `nil`，也就是不写声明就不块编
译——开发期保持增量重定义的自由，发布版再圈定热点区域加
`start-block`/`end-block`。想跨文件达到类似效果，用 26.8 的
`sb-ext:maybe-inline` 半内联机制，别指望把整个系统喂给一次
`compile-file`。

## 26.11 栈分配 dynamic-extent

`dynamic-extent` 声明告诉编译器「这个值不会逃出当前动态范围」，SBCL 于
是把它分配在**栈上**——函数返回即释放，零 GC 压力。声明只被信任不被
检查（前提是 `sb-ext:*stack-allocate-dynamic-extent*` 为真，默认就是）。

目前支持栈分配的值（手册 6.7 完整清单）：

- `&rest` 列表；
- `cons`、`list`、`list*`、`vector` 的结果；
- 简单形式的 `make-array`：结果必须是已知一维 simple 数组且
  `:element-type` 是常量（**栈空间有限，大向量会栈溢出**）；
- `flet`/`labels`/`lambda` 定义的闭包；
- 构造器被声明 `inline` 的 `defstruct` 实例；
- 上述值的「otherwise-inaccessible 部分」——比如整个子结构只能通过
  一个 DX 值访问到，子结构一起进栈。

而且 **`setq` 赋的值也算**：变量声明了 DX，循环里反复 `(setq x (cons i x))`
造出来的整条链都在栈上：

```lisp
(defun dx-list-sum (n)
  (let ((xs nil))
    (declare (dynamic-extent xs))
    (dotimes (i n)
      (setq xs (cons (1+ i) xs)))
    (reduce #'+ xs)))
(dx-list-sum 5)                            ; => 15
```

`&rest` 列表是最经典的用法：

```lisp
(defun dx-args (&rest args)
  (declare (dynamic-extent args))
  (length args))
(dx-args 1 2 3)                            ; => 3
```

inline 构造器的结构体也能整实例上栈：

```lisp
(declaim (inline make-perf-pt))
(defstruct perf-pt x y)
(defun pt-norm-sq (a b)
  (let ((p (make-perf-pt :x a :y b)))
    (declare (dynamic-extent p))
    (+ (* (perf-pt-x p) (perf-pt-x p))
       (* (perf-pt-y p) (perf-pt-y p)))))
(pt-norm-sq 3 4)                           ; => 25
```

三条纪律：

1. **违反 DX 约束（让值逃逸）的最好结果是读到垃圾，常见结果是整个
   映像崩溃**——没有警告、没有检查；
2. DX 不穿透 `&rest` 转发：`(apply fun arguments)` 里 `arguments` 的
   元素不进栈（1.0.48.21 起的行为，可移植代码别依赖任何方向）；
3. 很多情况**不用你声明**：SBCL 的逃逸分析能证明局部函数只被「向下」
   传递（downward funarg，比如传给 `position-if` 的谓词）时自动栈分配。

## 26.12 数值与位运算的隐藏福利

**模运算优化**：如果编译器看到 `(logand <表达式> <掩码>)`，且掩码是
`(unsigned-byte 32)`（64 位机上是 64）这样的「好宽度」，而表达式树里
全是「好函数」（`+`、`-`、`logand`、`logior`、`logxor`、`lognot`，以及
第二个参数为正的 `ash`），**所有中间结果都按宽度截断**，直接用机器指令：

```lisp
(defun mod-xor (x y)
  (declare (type (unsigned-byte 32) x y))
  (ldb (byte 32 0) (logxor x (lognot y))))
(mod-xor 5 3)                              ; => 4294967289
```

`lognot` 的结果原本是负数（`(signed-byte 33)`），没有这层优化就没法用
32 位机器算术。有符号版本用这个惯用法（截断后符号扩展）：

```lisp
(defun add64-wrap (a b)
  (declare (type (signed-byte 64) a b))
  (let ((u (ldb (byte 64 0) (+ a b))))
    (logior u (- (mask-field (byte 1 63) u)))))
(add64-wrap 3 4)                           ; => 7
(add64-wrap 9223372036854775807 1)         ; => -9223372036854775808
```

**已识别的惯用法**：有些代码模式会被直接翻成硬件指令。数尾部零：

```lisp
(defun ctz (n)
  (declare (type (unsigned-byte 64) n))
  (integer-length (ldb (byte 64 0) (lognor n (- n)))))
(ctz 8)                                    ; => 3
(ctz 0)                                    ; => 64
```

在 x86-64/arm64 上这就是一条指令，`n` 为 0 时按约定返回 64。

**全局变量加速**：`sb-ext:defglobal` 定义的变量总是绑定的、不可被局部
再绑定，多线程下查找更快；`(declaim (sb-ext:always-bound *x*))` 让编译器
省掉绑定检查；`(declaim (sb-ext:global *x*))` 禁止其再被 proclamation 成
special：

```lisp
(sb-ext:defglobal *perf-global* 42)
*perf-global*                              ; => 42
```

## 26.13 槽访问性能

**结构体**：accessor 快的前提是编译器能开放编码——结构体定义必须先于
调用被编译；别把 accessor 声明 `notinline`；别把 accessor 当函数对象
传来传去（`(mapcar #'pt-x list)` 就走不了开放编码）。

**CLOS 标准对象**分三档（手册 6.6.2 实测口径）：

1. **最快**（约为开放编码结构体访问的 1.6 倍）：`defmethod` 体内、
   `slot-value` 带**常量槽名**、持有实例的变量是方法的**特化参数**且
   从不被赋值；
2. 其次（可能再慢 3 倍）：CLOS accessor，或不满足上面条件的
   `slot-value`；
3. 其余写法自求多福。

```lisp
(defclass perf-foo () ((bar :initform 0)))
(defmethod quux ((foo perf-foo) new)       ; 快：特化参数、不赋值
  (let ((old (slot-value foo 'bar)))
    (setf (slot-value foo 'bar) new)
    old))
(let ((f (make-instance 'perf-foo)))
  (quux f 42)
  (slot-value f 'bar))                     ; => 42
```

反例对照：把 `foo` 先 `(setq temp foo)` 再访问、或在方法体里给 `foo`
本身赋值，都会掉出第一档。剖析泛型函数时注意：**前几次调用的数据不算数**
——分发缓存是懒建立的。

## 26.14 内存与 GC

- `0 bytes consed` 是好代码的勋章：复用缓冲（`map-into`、fill-pointer
  向量）比「每次新建」快得多；
- `(sb-ext:gc)` 手动触发；长驻服务关注 `get-bytes-consed` 的增速；
- `(sb-ext:purify)` 把存活对象全部钉成「永久代」，老式 GC 下收益大，
  分代 GC 下意义有限，但能让代码段地址固定、便于多进程写时复制共享；
- 列表 vs 向量的代价表在 08 章——按下标访问换向量是「免费的」优化；
- `sb-ext:freeze-type` 声明一个类型不再变化，可加速结构体的 `typep`。

## 26.15 数值计算优化套路（实测）

三个层层递进的版本（对照示例 26 的 `fixnum-sum` / `float-sum` / 矩阵乘）：

```lisp
;; ① 朴素版：通用算术，全类型分派，每步可能装箱
(defun sum-01 (n) (loop for i from 1 to n sum i))

;; ② 声明版：钉死类型，编译器生成无装箱的机器加法
(defun sum-02b (n)
  (declare (type fixnum n))
  (let ((acc 0))
    (declare (type fixnum acc))
    (loop for i fixnum from 1 to n do (incf acc i))
    acc))

;; ③ 极限版：热循环里连中间结果的类型都钉死
(declaim (inline sum-03))
(defun sum-03 (n)
  (declare (optimize (speed 3) (safety 0))
           (type fixnum n))
  (let ((acc 0))
    (declare (type fixnum acc))
    (dotimes (i n acc)
      (incf acc (the fixnum (1+ i))))))
```

```lisp
(sum-01 100)                               ; => 5050
(sum-02b 100)                              ; => 5050
(sum-03 100)                               ; => 5050
```

验证手段：`(disassemble #'sum-02b)`——汇编里没有对 `GENERIC-+` 的调用、
没有分配指令，就说明类型钉死了。反例同样有教育意义：去掉声明后每步循环
都是一次函数调用 + 装箱。

**safety 0 的代价要有意识**：`sum-03` 传一个 bignum 会直接产生错误结果
甚至破坏堆（26.6）——发布版宁可 `(safety 1)`。

## 26.16 常见性能陷阱

| 陷阱 | 后果 | 修法 |
|---|---|---|
| 循环里 `nth` | O(n²) | 向量 + `aref` |
| `append` 累积 | 每次全量拷贝 | `push` + 最后 `nreverse` |
| 字符串反复 concatenate | 分配风暴 | `with-output-to-string` |
| 动态变量在热循环里 | 查找开销 | 词法变量 |
| 装箱算术 | 每步分配 | fixnum 声明 |
| safety 0 + `the` 说谎 | 神秘错误结果/堆损坏 | 定位时开回 safety 1 |
| `(reduce #'f x)`（x 类型编译期已知） | 未专门优化 | 手写循环或 `loop` |
| `(position 0 位向量)`、`(remove x s :count 1)` | 未专门优化 | 自己展开 |
| 既 `setq` 又被闭包捕获的变量 | value cell 进堆 | 换成绑定 |

最后一类是手册点名的「理论上能优化、实际没人写 transform」的情形——
遇到了要么绕开，要么给 SBCL 提个 `deftransform` 补丁。

## 26.17 基准的正确姿势

- 单次 `time` 是噪音——跑多轮取中位数；
- 对比优化前后用**同一函数**的热加载（REPL 里 redefine 即可，21 章的
  交互循环）；
- 别比较 SBCL 与 CLISP 的微基准绝对值——编译型 vs 字节码解释（01 章），
  那是「选实现」的输入，不是「写代码」的输入；
- 泛型函数先跑几十次暖掉分发缓存再计时（26.13）。

## 26.18 坑位清单

| 症状 | 原因 | 解法 |
|---|---|---|
| sb-profile 那行 overhead 打进 stderr | `--script` 模式 | 统一 `--load` |
| sb-sprof 调用图是空的（macOS） | `:cpu` 模式信号不按线程比例投递 | 换 `:mode :time` |
| 剖析报告里找不到某函数 | 它被内联了 | 想剖析就别 inline |
| 优化后结果悄悄错了 | safety 0 + the 撒谎 | 定位时开 safety 1 |
| 尾递归突然爆栈 | debug 3 关了 TCO | 调优组合别开 debug 3 |
| 循环永不终止 + unreachable code note | 类型声明撒谎（26.4 count-a） | 信 note，查声明 |
| `could not be inlined` style-warning | inline 声明晚于 defun | 声明挪到定义前 |
| `REQUIRE SB-SPROF` 没报错但 SB-PROFILE 报 | 后者在核心里 | 分清核心/contrib（23 章） |
| 重定义辅助函数没效果 | 调用点被块编译/静态链接 | 开发期别开块编译 |
| 微基准忽快忽慢 | 单次计时噪音 | 多轮取中位数 |

---

上一章：[25 SBCL 扩展 III：FFI](25-sbcl-ffi.md) · 下一章：[27 实战：迷你 Lisp 解释器](27-minilisp.md)
