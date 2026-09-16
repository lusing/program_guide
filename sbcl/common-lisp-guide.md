# Common Lisp 编程指南（SBCL 实测版）

一份从「看得懂 S 表达式」到「能写出可用程序」的 Common Lisp 教程。

**文中每一段带 `; =>` 的结果、每一段报错原文，都是在 SBCL 2.6.7（macOS）上实际跑出来的**，
不是手写的示意。凡是每次运行都会不同的地方（对象地址、`gensym` 编号、哈希表遍历顺序、
并发输出顺序），文中都会显式标注。

---

## 这份指南怎么用

Common Lisp 和多数语言有个根本差别：**它的「编译期」和「运行期」是同一个进程里的两件事**，
而且这个进程一直活着。你在 REPL 里输入的每个表达式都会被单独编译成机器码再执行。
所以学它的正确姿势不是「写一个文件、编译、运行、看结果」，而是：

1. **先用 REPL 把语义搞明白**（本指南第 1 章就是干这个的）；
2. **再把搞明白的东西写成文件**，用 `--load` 跑成脚本（这样能进 CI、能被验证）。

本指南两条路都走，并且每次给出可复现的命令。

### 章节目录与示例对照

本目录下的 17 个示例文件（`01-hello-world.lisp` … `17-testing-and-deployment.lisp`）
是配套的可运行代码，每章都会指出该看哪一个：

| 章 | 主题 | 配套示例 |
|---|---|---|
| 0 | 环境、两种运行方式与验证标准 | — |
| 1 | 求值模型：Lisp 怎么读你的代码 | `01-hello-world.lisp` |
| 2 | 数字：整数不会溢出、有理数精确、浮点不精确 | `02-data-types.lisp` |
| 3 | 字符、字符串、符号 | `02-data-types.lisp` |
| 4 | 列表与 cons 结构 | `02-data-types.lisp` |
| 5 | 变量与作用域（词法 vs 动态） | `04-functions.lisp` |
| 6 | 函数、参数模型与多值 | `04-functions.lisp` |
| 7 | 控制流与迭代 | `03-control-structures.lisp` |
| 8 | 序列与高阶函数 | `16-sequences-hash-tables.lisp` |
| 9 | 哈希表与结构体 | `16-sequences-hash-tables.lisp` |
| 10 | 条件系统与重启（CL 最独特的部分） | `08-conditions.lisp` |
| 11 | CLOS：类、方法、多分派 | `06-clos.lisp` |
| 12 | 包与命名隔离 | `07-packages.lisp` |
| 13 | 宏与元编程 | `05-macros.lisp` |
| 14 | `format` 格式化输出 | `10-format.lisp` |
| 15 | 文件与流 I/O | `09-file-io.lisp` |
| 16 | SBCL 专用：线程、FFI、优化、部署 | `11`/`12`/`13`/`14`/`17` |
| 17 | 工程化：ASDF、测试与工具链 | `15-asdf-quicklisp.lisp` |
| 附录 A | 常见坑速查（症状 → 原因 → 解法） | — |
| 附录 B | 报错信息对照表 | — |

### 环境

本指南在 **SBCL 2.6.7**（macOS，MacPorts 安装）上编写和验证。SBCL 是 ANSI Common Lisp 的
一个实现，绝大多数 `CL:` 包里的东西换到 CCL / ECL / CLISP 上行为一致；而本指南第 16 章
讲的是 **SBCL 特有的** `SB-*` 包，换实现就跑不了。

检查你的环境：

```bash
$ sbcl --version
SBCL 2.6.7
```

---

# 第 0 章 先跑起来

## 0.1 两种运行方式

**交互式 REPL** —— 学语言、试想法、看报错用这个：

```bash
$ sbcl
* (+ 1 2)

3
* (quit)
```

`*` 是提示符。你输入一个表达式，SBCL 编译它、执行它、把返回值打印出来。这个循环就是
**R**ead-**E**val-**P**rint **L**oop。

**脚本方式** —— 写正式代码、进 CI 用这个：

```bash
$ sbcl --noinform --non-interactive --no-userinit --load hello.lisp
```

四个参数各有用意：

| 参数 | 作用 |
|---|---|
| `--noinform` | 不打印启动 banner（那行版本信息会污染 stdout） |
| `--non-interactive` | 出错不当场进调试器，直接退出 |
| `--no-userinit` | 不加载 `~/.sbclrc`，保证结果**可复现** |
| `--load FILE` | 加载并执行文件 |

`--no-userinit` 这一条最容易被忽略又最要命：你自己的 `~/.sbclrc` 里如果改了
`*read-default-float-format*` 或者装了 Quicklisp，同一个脚本在别人机器上结果就不一样。

> **⚠️ 一个会骗过验证的组合**：`--script` 与 `--non-interactive` **不能连用**。
> 连用会把文件名当成运行期参数，脚本根本不执行，只打一行 banner、退出码 0 —— 看起来「跑过了」。
> 本仓库的 `run-all.sh` 用的是 `--load`。

## 0.2 输出走哪去

这是本仓库所有示例统一风格的原因：

| 写法 | 去哪里 |
|---|---|
| `(format t ...)`、`(print x)`、`(princ x)` | **stdout** |
| `(format *error-output* ...)`、`(warn ...)` | **stderr** |
| SBCL 编译器的警告与回显 | **stderr** |

`(print x)` 和 `(princ x)` 省掉了第一个参数，其实是 `*standard-output*`。要写 stderr 得显式写
`*error-output*`：

```lisp
(format *error-output* "这条是 stderr~%")
```

`warn` 则**天生**写 stderr（实测）：

```lisp
;; 把 *error-output* 临时改道到 stdout，才能在 stdout 里看见它
(let ((*error-output* *standard-output*))
  (warn "这行 WARNING 是写到 stderr 的（此处临时改道）"))
```

```
WARNING: 这行 WARNING 是写到 stderr 的（此处临时改道）
```

这条事实直接决定了示例怎么写：如果示例用 `warn` 打印结果，那么在「stderr 必须为空」这条
判定下它就会失败。所以 `08-conditions.lisp` 演示警告时，临时把 `*error-output*`
绑到了标准输出。

## 0.3 四个判定标准

本目录的验证入口对每个示例检查四件事，缺一不可：

| # | 标准 | 为什么 |
|---|---|---|
| 1 | 退出码为 0 | 崩了要算失败 |
| 2 | **stderr 为空** | 见上一节：编译警告、`warn`、SBCL 回显都会走 stderr |
| 3 | stdout 里没有多余控制字符（0..31 除 TAB/LF/CR） | 一个 `~\|` 写错就会吐出 `#\Page` |
| 4 | stdout 里有结束标记 `==== NN 结束 ====` | SBCL 有「静音掉报错、退出码仍是 0」的玩法，标记是最后一道防线 |

跑全部：

```bash
$ ./run-all.sh                 # macOS / Linux
$ pwsh ./build.ps1 -All        # PowerShell，三平台通用
```

关于第 4 条：**Common Lisp 的编译器有时会把错误降级成警告**（比如你在 `--load` 一个
已经编译过的 `fasl` 时）。让示例自己声明「我跑完了」，比依赖退出码可靠。

## 0.4 关于本指南里的代码块

三种记法，请分清：

```lisp
(+ 1 2)          ; => 3        ← 表达式，右边是实际的返回值
```

```bash
$ sbcl --version        # `$` 是你敲的，下面是实际输出
SBCL 2.6.7
```

```
这是「某段程序的输出」，前面会说明是哪段程序跑出来的
```

另外，为了让长列表能在一行里显示，少量结果是在 `*print-pretty*` 为 `nil` 的情况下打印的；
这一点在用到时会注明。默认情况下 SBCL 的 `*print-pretty*` 是 `T`，会让长结构折行。

---

# 第 1 章 求值模型：Lisp 到底怎么读你的代码

这一章是全书的根基。Common Lisp 的语法事实上只有一个规则，但**读入**和**求值**是两个独立步骤，
混淆这两步是初学者 80% 困惑的来源。

## 1.1 只有一个语法规则：前缀表达式

一个表达式要么是**原子**（数字、字符串、符号），要么是**表**：`(` 开头、`)` 结尾，
里面可以是零个或多个表达式。

```lisp
(+ 1 2)          ; => 3
(+ 1 2 3 4 5)    ; => 15
(+)              ; => 0        （+ 的零元运算是 0）
(* 3 4)          ; => 12
```

函数名写在最前面，后面是实参。嵌套时也是同样的形状，没有运算符优先级这回事：

```lisp
(* (+ 1 2) (- 10 4))    ; => 18
```

`(+ 1 2)` 里的 `+` 是个**符号**（symbol），`1` 和 `2` 是**数字**。这听起来像废话，
但它是后面一切的基础 —— 宏能存在，就是因为「代码」和「由符号与数字组成的列表」是同一种数据结构。

三种简写要知道，它们会一直出现：

```lisp
(car (cdr '(1 2 3)))    ; => 2    ← 标准写法
(cadr '(1 2 3))         ; => 2    ← 缩写：a/d 序列从右往左读
(second '(1 2 3))       ; => 2    ← 可读性最好
```

## 1.2 读入与求值是两件事

**这是本章最重要的一节。**

REPL 的名字已经说明了流程：Read（读入）→ Eval（求值）→ Print（打印）。这两个步骤是分开的，
中间那个产物叫**形式**（form）。

`quote` 的作用就是「读入之后不要再求值」。它的简写是一个单引号：

```lisp
'(+ 1 2)              ; => (+ 1 2)    ← 原样返回这张表，没做加法
(quote (+ 1 2))       ; => (+ 1 2)    ← 同上，前者是后者的简写
(type-of '(+ 1 2))    ; => CONS       ← 它就是一个 cons 结构
(eval '(+ 1 2))       ; => 3          ← 要它求值，得显式调 eval
```

因为读入先发生，引号可以套娃：

```lisp
''x                   ; => 'X         ← 外层引号阻止内层引号被求值
```

**这条性质有一个非常实际的后果**：一个形式在被求值之前，它里面的**所有**符号都已经定型了。
所以你**不能**在同一个形式里「先加载一个包，再用这个包里的符号」：

```lisp
;; 错的：读入整行时 SB-BSD-SOCKETS 还不存在
(progn (require :sb-bsd-sockets) (sb-bsd-sockets:get-host-by-name "x"))
```

必须分成两个顶层形式（两行，或文件的两次 `--load`）：

```lisp
(require :sb-bsd-sockets)
(sb-bsd-sockets:get-host-by-name "localhost")
```

## 1.3 大小写：读入器把符号名变成大写

Lisp 的读入器默认把**未转义的小写字母转成大写**：

```lisp
(read-from-string "hello")             ; => HELLO
(symbol-name 'hello)                   ; => "HELLO"
'Hello                                 ; => HELLO
```

想保留小写要用竖线转义：

```lisp
(read-from-string "|hello|")                       ; => |hello|
(symbol-name (read-from-string "|hello|"))         ; => "hello"
```

打印时用什么大小写由 `*print-case*` 控制，默认是 `:upcase`：

```lisp
*print-case*            ; => :UPCASE
```

这就是为什么 Lisp 代码里到处都是大写符号 —— **写小写是习惯，实际符号名是大写**。
也解释了 `(intern "foo")` 和 `(intern "FOO")` 为什么不是同一个符号（第 12 章会实测）。

## 1.4 哪些东西自己就是自己的值

不用求值、直接得到自身的叫**自求值对象**：

```lisp
42        ; => 42
"abc"     ; => "abc"
:key      ; => :KEY       ← 关键字，永远自求值
t         ; => T          ← 真
nil       ; => NIL        ← 假，也是空表
'()       ; => NIL        ← 空表就是 NIL
(eq nil '())            ; => T
```

**`nil` 和空表是同一个东西**，而 `t` 只是「恰好」被用作真的符号 —— 严格说 Lisp 里
**只有 `nil` 是假，其他任何东西都是真**（第 7 章会实测 `0` 和 `""` 都是真）。

## 1.5 实参先算完再进函数

普通函数调用遵循「先求值所有实参，再调用」：

```lisp
(list (+ 1 1) (* 2 2))       ; => (2 4)         ← 传进去的是 2 和 4
(list '(+ 1 1) '(* 2 2))     ; => ((+ 1 1) (* 2 2))   ← 传进去的是两张表
```

实参的**求值顺序**在 ANSI 标准里没有规定，SBCL 是从左到右（实测）：

```lisp
;; SBCL 的实参求值顺序 => (1 2 3)
```

想调用一个「直接写在调用位置的函数」，同样合法：

```lisp
((lambda (x) (* x x)) 6)     ; => 36
```

## 1.6 特殊形式、宏、函数：三种东西，三种时机

同样是 `(if t :yes :no)`，`if` 却**不能**先求值实参 —— 那样两个分支都会被执行。
这类不走普通求值规则的叫**特殊形式**（special form）：

```lisp
'if                       ; => IF           ← if 本身是个符号
(if t :yes :no)           ; => :YES
(fboundp 'if)             ; 非 NIL
```

怎么区分三者？看它们**什么时候**工作：

| 种类 | 例子 | 实参求值 | 何时生效 |
|---|---|---|---|
| 特殊形式 | `if` `let` `quote` `setf` | 不预先求值 | 编译器内建 |
| 宏 | `when` `unless` `loop` `defun` | 收到的是**未求值的代码** | **编译/展开期** |
| 函数 | `+` `car` `mapcar` | 先求值 | 运行期 |

宏这一格是 Common Lisp 最有意思的部分，第 13 章会用实测把它讲透 —— 一个宏展开时看到的
是 `(+ 1 2)` 这个**表达式**，而函数收到的是 `3` 这个**值**。

## 1.7 常见坑

**① 未绑定的符号会报错，不是返回 nil**

```lisp
(car 5)          ; 报错：Value of 5 in (CAR 5) is 5, not a LIST.
(+ 1 "2")        ; 报错：Value of "2" in (+ 1 "2") is "2", not a NUMBER.
```

注意这两条报错是**同一个机制**：SBCL 先由 `car` 的参数类型断言报出
「值不匹配」，而不是「函数不存在」。错误信息里的 `(CAR 5)` 是**原始形式**，
这是 Lisp 系语言调试体验好的原因之一 —— 报错直接给你出错的那段代码。

**② 引号容易漏，也容易多**

```lisp
(car (1 2 3))    ; 错：读入没问题，但求值时会去找名为 1 的函数
(car '(1 2 3))   ; => 1
```

**③ 括号数对不代表嵌套对**

这条是写 Lisp 最阴的坑。少一个 `)` 多一个 `)` 会互相抵消，肉眼看不出，
报的错也常常指向别处（本仓库在写 `12-threads.lisp` 时踩过：报的是
`Error while parsing arguments to DEFMACRO PUSH: too few elements in (...)`）。
写文件前跑一遍 `compile-file` 能立刻抓住：

```bash
$ sbcl --noinform --non-interactive --no-userinit \
    --eval '(compile-file "x.lisp" :output-file "/tmp/c.fasl" :print nil :verbose nil)'
```

**注意**：`compile-file` 只做静态检查，**不能替代真跑** —— 它对运行期才崩的代码一样返回成功。

---

# 第 2 章 数字：三种数，三套脾气

配套示例：`02-data-types.lisp`。

Common Lisp 把数字分成**整数、有理数、浮点、复数**四类，它们之间会自动转换，
而且转换规则是「**精度只升不降**」。理解这一章能避免大量「为什么结果不是我算的那个」。

## 2.1 整数：不会溢出，只会变慢

多数语言的整数会静默回绕（`int` 溢出成负数）。CL 的实现**必须**保证正确性 ——
超出机器字长时自动切换成大整数（bignum）：

```lisp
(expt 2 100)                    ; => 1267650600228229401496703205376
(* 99999999999 99999999999)     ; => 9999999999800000000001
(integer-length (expt 2 1000))  ; => 1001
```

`integer-length` 返回的是**位宽**，上面 `2^1000` 占 1001 位。

那「小整数」的边界在哪？SBCL 里叫 `fixnum`，是**立即数**（不分配内存、最快）：

```lisp
most-positive-fixnum              ; => 4611686018427387903
(1+ most-positive-fixnum)         ; => 4611686018427387904
(type-of (1+ most-positive-fixnum))  ; => (INTEGER 4611686018427387904)
```

注意 `type-of` 返回的不是 `INTEGER`，而是 `(INTEGER 4611686018427387904)` ——
**一个具体的类型区间**。SBCL 的编译器会推理出比 `integer` 更精确的类型，
这是它优化能力的来源，也意味着：**别拿 `type-of` 的结果做字符串比较**，
它不是给你做类型判断用的。要判断用 `integerp` / `typep`。

固定范围的整数类型（写性能敏感代码时有用）：

| 类型 | 含义 |
|---|---|
| `fixnum` | 不分配内存的小整数 |
| `bignum` | 超出 fixnum 的整数 |
| `(integer 0 255)` | 0 到 255 的整数（区间类型） |
| `(unsigned-byte 8)` | 0..255 |
| `(signed-byte 32)` | -2^31 .. 2^31-1 |

## 2.2 有理数：算得准

两个整数相除，如果除不尽，得到的是**精确的有理数**而不是浮点近似：

```lisp
(/ 10 4)              ; => 5/2        （不是 2.5）
(+ 1/3 1/6)           ; => 1/2
(+ 1/3 1/3 1/3)       ; => 1          （完全等于 1，无误差）
(* 1/3 3)             ; => 1
(expt 2 -1)           ; => 1/2
(type-of 1/2)         ; => RATIO
```

有理数的字面量直接写成 `分子/分母`。取分子分母：

```lisp
(numerator 3/4)       ; => 3
(denominator 3/4)     ; => 4
```

浮点也可以转成它**精确**代表的那个有理数 —— 结果可能让你惊讶：

```lisp
(rational 0.5)        ; => 1/2        （0.5 恰好能精确表示）
(rational 0.1)        ; => 13421773/134217728
```

`0.1` 转出来不是 `1/10` 而是 `13421773/134217728`。为什么？因为 `0.1` 这个**字面量**
默认是单精度浮点（见下一节），它存不下 0.1，只能存一个近似值；`rational` 忠实地
告诉你那个近似值到底是多少。**想要 1/10 就写 `1/10`，不要写 `0.1`。**

## 2.3 浮点：默认是单精度，这是个陷阱

**这一节是本指南最值得先记住的一节。**

```lisp
*read-default-float-format*    ; => SINGLE-FLOAT
(type-of 1.5)                  ; => SINGLE-FLOAT
(type-of 1.5f0)                ; => SINGLE-FLOAT     （f = single）
(type-of 1.5d0)                ; => DOUBLE-FLOAT     （d = double）
```

按 ANSI 标准，**没加后缀的浮点字面量是单精度**。单精度只有约 7 位十进制有效数字，
而大家熟知的「双精度 15~16 位」需要显式写 `d0`。后果：

```lisp
(+ 0.1 0.2)                    ; => 0.3        ← 单精度下「看不出来」有问题
(+ 0.1d0 0.2d0)                ; => 0.30000000000000004d0
(= (+ 0.1d0 0.2d0) 0.3d0)      ; => NIL        ← 经典浮点误差
```

单精度把误差藏起来了（打印精度不够），双精度把它暴露出来。所以：

- **要浮点精度就写 `1.5d0`**，别写 `1.5`；
- **不要用 `=` 比较浮点**，用 `(<= (abs (- a b)) 容差)`；
- 能不用浮点就不用 —— 金融计算用整数（以「分」为单位）或有理数。

其它几条实测：

```lisp
(* 1.0 1/3)            ; => 0.33333334        ← 单精度只给 8 位
(float 1/3 1.0d0)      ; => 0.3333333333333333d0
pi                     ; => 3.141592653589793d0   ← 常量 pi 是双精度
(type-of pi)           ; => DOUBLE-FLOAT
(sqrt 2)               ; => 1.4142135          ← 单精度
(sqrt 2d0)             ; => 1.4142135623730951d0
```

## 2.4 类型提升金字塔

混合运算时结果取「更宽」的那个类型，方向是：
**整数 → 有理数 → 单精度 → 双精度 → 复数**。逐条实测：

```lisp
(+ 1 1/2)         ; => 3/2            （整数 + 有理数 → 有理数）
(+ 1/2 0.5)       ; => 1.0            （有理数 + 单精度 → 单精度）
(+ 1/2 0.5d0)     ; => 1.0d0          （有理数 + 双精度 → 双精度）
(+ 1 2.0)         ; => 3.0            （整数 + 浮点 → 浮点）
(+ 1 2)           ; => 3              （整数 + 整数 → 整数）
```

**关键点：一旦沾上浮点，精确性就永久丢了。** `(+ 1/2 0.5)` 得到的是浮点 `1.0`，
而 `(+ 1/2 1/2)` 得到的是精确的 `1`。把浮点混进金融计算是经典事故。

`type-of` 对照：

```lisp
(type-of (+ 1 2))       ; => (INTEGER 0 4611686018427387903)
(type-of (+ 1 1/2))     ; => RATIO
(type-of (+ 1 2.0))     ; => SINGLE-FLOAT
```

## 2.5 除法与取余：四个函数，两种语义

`/` 给有理数，但很多场合你要的是「商和余数」。CL 有四个函数，区别在于**余数怎么取**：

| 函数 | 取整方向 | 与另一个操作数的关系 |
|---|---|---|
| `floor` | 向下（向 -∞） | 余数与除数同号 |
| `ceiling` | 向上（向 +∞） | 余数与除数反号 |
| `truncate` | 向零 | 余数与被除数同号 |
| `round` | 就近（平局取偶） | — |

它们都返回**两个值**（商和余数），REPL 里看全部要显式取：

```lisp
(multiple-value-list (floor 7 2))      ; => (3 1)
(multiple-value-list (floor -7 2))     ; => (-4 1)     ← 向下取整！
(multiple-value-list (truncate -7 2))  ; => (-3 -1)    ← 向零截断
(multiple-value-list (ceiling 7 2))    ; => (4 -1)
(multiple-value-list (round 7 2))      ; => (4 -1)
```

从 C / Python 来的人最容易栽在这里：**`floor` 不是截断**。`-7/2` 在 C 里是 `-3`，
在 CL 的 `floor` 下是 `-4`。

`mod` 和 `rem` 是「只要余数」的版本，也是从 C 来的人最容易混的一对：

```lisp
(mod -7 2)     ; => 1      （符号跟除数）
(rem -7 2)     ; => -1     （符号跟被除数）
(mod 7 -2)     ; => -1
(rem 7 -2)     ; => 1
```

**记住：`mod` 跟除数，`rem` 跟被除数。** 想判断奇偶用 `evenp` / `oddp`，
别自己写 `(zerop (rem x 2))` —— 对负数会得到意想不到的结果。

对比一下 `/`、`floor` 和 `rational`：

```lisp
(/ 7 2)        ; => 7/2     有理数，精确
(floor 7/2)    ; => 3       丢掉余数，只取第一个值
(floor 7 2)    ; => 3       同上，但两个操作数都是整数
```

## 2.6 舍入是「四舍六入五成双」

`round` 遇到正好一半时，取**最近的偶数**（银行家舍入），不是「四舍五入」：

```lisp
(round 2.5)    ; => 2
(round 3.5)    ; => 4
(round 0.5)    ; => 0
(round 1.5)    ; => 2
(round 5/2)    ; => 2       有理数也一样
(round 7/2)    ; => 4
(fround 2.5)   ; => 2.0     返回浮点
```

这条在**统计和财务**里是真会算错的。要传统四舍五入得自己写，
通常用 `(floor (+ x 1/2))`。

## 2.7 开方、对数与位运算

```lisp
(sqrt 4)         ; => 2.0        ← 注意：返回浮点，不是整数 2！
(sqrt 4.0)       ; => 2.0
(isqrt 17)       ; => 4          ← 整数开方（向下取整）
(sqrt -4)        ; => #C(0.0 2.0)   ← 负数开方给复数，不报错
(log 100 10)     ; => 2.0
(expt 8 1/3)     ; => 2.0
(expt 2 10)      ; => 1024       ← 整数指数给整数
(abs -3)         ; => 3
(abs -3.0)       ; => 3.0
```

`(sqrt 4)` 给 `2.0` 而不是 `2`，是新手最常见的「类型意外」。要整数用 `isqrt`
（它只对完全平方数精确）或 `(expt n 1/2)`。

位运算和数论函数都在标准里：

```lisp
(ash 1 10)       ; => 1024        ← 左移 10 位
(ash 1024 -5)    ; => 32          ← 负数右移
(logand 12 10)   ; => 8
(logior 12 10)   ; => 14
(logxor 12 10)   ; => 6
(lognot 0)       ; => -1
(gcd 12 18)      ; => 6
(lcm 4 6)        ; => 12
```

> **注意**：`exptmod`（模幂）**不是** Common Lisp 标准函数，SBCL 里也没定义
> （实测报 `The function COMMON-LISP-USER::EXPTMOD is undefined`）。
> 需要模幂就自己写快速幂。

## 2.8 比较：`=` 比数值，`eql` 比类型

这是 CL 里一组很容易混的比较（第 4 章有完整的「五种相等」对照表）：

```lisp
(= 1 1.0)         ; => T      ← = 只比数值，跨类型也相等
(eql 1 1.0)       ; => NIL    ← 类型不同就不相等
(equal 1 1.0)     ; => NIL
(= 1/2 0.5)       ; => T      ← 有理数与浮点数值相等
```

比大小支持**多个参数连写**（这是 CL 的便利，C 里得 `&&`）：

```lisp
(< 1 2 3)         ; => T
(< 1 3 2)         ; => NIL
(<= 1 1 2)        ; => T
```

其余常用谓词：

```lisp
(max 1 2.0)       ; => 2.0        ← 混类型结果按提升规则
(min 1 2)         ; => 1
(zerop 0.0)       ; => T
(plusp 0.0)       ; => NIL        ← 0 既不正也不负
(evenp 4)         ; => T
```

## 2.9 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| 小数算出来差一点 | 浮点字面量默认**单精度** | 写 `1.5d0`，或用有理数 |
| `(/ 7 2)` 得到 `7/2` 而不是 `3` | `/` 给精确有理数 | 要整数商用 `floor` / `truncate` |
| 负数取模结果和 C 不一样 | `mod` 跟除数、`rem` 跟被除数 | 想清楚要哪个 |
| `(round 2.5)` 得 2 不是 3 | 银行家舍入 | 要传统舍入写 `(floor (+ x 1/2))` |
| `(sqrt 4)` 得到浮点 | `sqrt` 一律返回浮点 | 要整数用 `isqrt` |
| `type-of` 结果不是预期的类名 | SBCL 会返回精确区间类型 | 判断用 `integerp` / `typep` |

---

# 第 3 章 字符、字符串、符号

配套示例：`02-data-types.lisp`。

## 3.1 字符是独立类型（不是小整数）

从 C / Rust / Elisp 过来会习惯「字符就是整数」，**CL 里不是**：

```lisp
#\a              ; => #\a
(char-code #\a)  ; => 97
(code-char 65)   ; => #\A
(eql #\a 97)     ; => NIL       ← 字符和整数是两种东西
(type-of #\a)    ; => STANDARD-CHAR
```

字面量写法是 `#\` 加字符；有名字的特殊字符：

```lisp
#\Space          ; 空格（码 32）
#\Newline        ; 换行
#\Tab            ; 制表
(char-code #\Space)   ; => 32
(char-name #\Space)   ; => "Space"
```

比较用 `char=` 系列（**区分大小写**），不分大小写用 `char-equal` 系列：

```lisp
(char< #\a #\b)       ; => T
(char= #\a #\A)       ; => NIL
(char-equal #\a #\A)  ; => T
(char-upcase #\a)     ; => #\A
(digit-char-p #\7)    ; => 7        ← 是数字字符就返回它的数值，否则 NIL
```

注意 `char<` 返回 `T`/`NIL`，而**字符串**版本的 `string<` 返回的是
**第一个不同字符的下标**（下一节实测），这两个别记混。

## 3.2 字符串是字符向量

CL 的字符串不是独立类型，它就是一个**元素类型为 `character` 的向量**：

```lisp
(type-of "abc")         ; => (SIMPLE-ARRAY CHARACTER (3))
(vectorp "abc")         ; => T
(stringp "abc")         ; => T
(aref "abc" 0)          ; => #\a      ← 用向量取元素的方式
(char "abc" 1)          ; => #\b      ← 用字符串取字符的方式
(length "abc")          ; => 3
```

这解释了两件事：为什么字符串函数和序列函数长得一样，以及为什么字符串可以
用 `map` / `subseq` / `elt` 这些通用序列函数。

**字面量字符串不可以改。** 直接改它在 SBCL 上「看起来成功」但其实是未定义行为：

```lisp
(setf (char "abc" 0) #\A)     ; => #\A     ← 居然成功了！
```

成功的原因是这个字面量恰好在可写内存里 —— 但 SBCL 的**编译期会给出警告**：

```
caught WARNING:
  Destructive function (SETF AREF) called on constant data: "abc"
```

一旦代码进了只读段，同样的语句就会崩。**正确做法是先拷贝**：

```lisp
(let ((s (copy-seq "abc"))) (setf (char s 0) #\A) s)     ; => "Abc"
```

要构造可变的空字符串，用 `make-array`：

```lisp
(let ((s (make-array 3 :element-type 'character :initial-element #\x)))
  (setf (char s 0) #\A) s)                               ; => "Axx"
```

## 3.3 字符串操作速查

比较是新手最容易搞错的一处：

```lisp
(string= "abc" "abc")     ; => T
(equal "abc" "abc")       ; => T        ← OK，但是通用函数
(eq "abc" "abc")          ; => NIL      ← eq 比的是「同一个对象」，两个字面量不是
(string< "abc" "abd")     ; => 2        ← 返回值是「第一个不同字符的下标」
(string< "abc" "abc")     ; => NIL      ← 完全相同才返回 NIL
(string/= "abc" "abd")    ; => 2
(string-equal "ABC" "abc") ; => T       ← 不分大小写
```

`string<` 返回 `2` 而不是 `T`，这一点跟 `char<` 不一样 —— 它是「广义布尔值」
（generalized boolean）：**非 `nil` 即真**，所以 `(if (string< a b) ...)` 照样能用，
但别写成 `(if (eql (string< a b) t) ...)`。

查找与切割：

```lisp
(search "lo" "hello")                  ; => 3        ← 找不到返回 NIL
(position #\l "hello")                 ; => 2
(subseq "Hello World" 0 5)             ; => "Hello"
(concatenate 'string "abc" "def")      ; => "abcdef"
(string-upcase "abc")                  ; => "ABC"
(string-capitalize "hello world")      ; => "Hello World"
(string-trim '(#\Space) "  hi  ")      ; => "hi"     ← 注意参数是个字符列表
(string-left-trim "0" "007")           ; => "7"
(replace (copy-seq "abcdef") "XY" :start1 1 :end1 3)   ; => "aXYdef"
```

`string-trim` 的参数是**字符集合**，可以是列表也可以是字符串（字符串会被当作字符集）。

拼接字符串有两种常用写法：

```lisp
(format nil "~A-~A" "a" 1)             ; => "a-1"
(with-output-to-string (s) (write-string "ab" s) (write 42 :stream s))   ; => "ab42"
```

`format nil` 是最常用的：第一个参数 `nil` 表示「返回字符串而不是打印」。

反过来，把字符串变成数据：

```lisp
(parse-integer "42")                   ; => 42
(parse-integer "ff" :radix 16)         ; => 255
(parse-integer "12abc" :junk-allowed t) ; => 12      ← 允许尾部有垃圾
(parse-integer "abc")                  ; 报错：junk in string "abc"
```

`read-from-string` 能读入**任意 Lisp 形式**，并且返回两个值（读到的对象 + 用掉的位置）：

```lisp
(read-from-string "(1 2 3)")                       ; => (1 2 3)
(multiple-value-list (read-from-string "42 rest")) ; => (42 3)
```

## 3.4 输出：`write` / `princ` / `prin1` / `format` 怎么选

这四者的差别是「给机器读」还是「给人看」：

| 写法 | 字符串打印成 | 用途 |
|---|---|---|
| `(prin1 x)` / `~S` | `"abc"`（带引号、会转义） | **能再读回来**，调试首选 |
| `(princ x)` / `~A` | `abc`（原样） | 给人看 |
| `(write x)` | 同上，但可选 `:escape` | 需要细控时 |
| `(format t ...)` | 由指令决定 | 拼接输出 |

实测：

```lisp
(format t "~S 保留引号，~A 不带引号：~S / ~A~%" "ab" "ab" "ab" "ab")
```

```
"ab" 保留引号，ab 不带引号："ab" / ab
```

```lisp
(prin1 "prin1 给机器读" *standard-output*)    ; 输出 "prin1 给机器读"
(princ "princ 给人看" *standard-output*)      ; 输出 princ 给人看（无引号）
```

一个实用的习惯：**调试日志用 `~S`**。因为 `~A` 打印 `nil` 和空字符串、
`1` 和 `"1"` 长得一样，而 `~S` 能区分。第 14 章有 `format` 的完整清单。

## 3.5 符号的三件事：名字、包、身份

一个符号（symbol）身上挂着三样东西，理解它们是理解 CL 包系统的前提：

1. **名字**（`symbol-name`，一个字符串）
2. **所属的包**（`symbol-package`）
3. **身份**（`eq` 比较 —— 同名同包的符号是同一个对象）

```lisp
(symbol-package 'foo)          ; => #<PACKAGE "COMMON-LISP-USER">
(symbol-name 'foo)             ; => "FOO"
(eq 'foo 'foo)                 ; => T
(type-of 'foo)                 ; => SYMBOL
```

符号还挂着两个「命名空间」和一个属性表：**变量值**（`symbol-value`）和
**函数值**（`symbol-function`）是分开的两格。这就是为什么 CL 里变量和函数可以同名：

```lisp
(defun list-length-2 (x) (* 2 (length x)))   ; 函数格
(defvar list-length-2 :a-var)                ; 变量格：同名，互不影响
```

关键字（keyword）是「住在 `KEYWORD` 包里、并且自己绑定到自己」的符号：

```lisp
:foo                       ; => :FOO      ← 自求值
(keywordp :foo)            ; => T
(keywordp 'foo)            ; => NIL
(symbol-value :foo)        ; => :FOO      ← 它的值就是它自己
(string :foo)              ; => "FOO"
(package-name (symbol-package :a))     ; => "KEYWORD"
```

所以关键字天生适合当「常量」，不需要 `defconstant`。

## 3.6 `intern`：字符串变成符号（有个大坑）

`intern` 把字符串变成符号，并保证「同名同包**只有一个**符号」：

```lisp
(intern "FOO")                        ; => FOO
(eq (intern "FOO") 'foo)              ; => T      ← 就是同一个符号
(multiple-value-list (intern "BRAND-NEW-SYM"))   ; => (BRAND-NEW-SYM NIL)      ← NIL 表示新建
(multiple-value-list (intern "BRAND-NEW-SYM"))   ; => (BRAND-NEW-SYM :INTERNAL) ← 第二次是已有
```

第二个返回值告诉你这个符号是「新建的」还是「本来就有」。

**坑在这里**：`(intern "foo")` 用的是**小写名字**，而 `'foo` 读入后名字是大写！

```lisp
(intern "foo")            ; => |foo|      ← 名字是小写的 "foo"
(intern "FOO")            ; => FOO
(eq (intern "foo") 'foo)  ; => NIL        ← 不是同一个符号！
```

`|foo|` 这个写法就是「名字里含小写字母、需要转义」的符号。**从字符串构造符号时，
用 `string-upcase` 包一下**，除非你确实要大小写敏感的符号名。

不作兴进符号表的临时符号用 `make-symbol`：

```lisp
(make-symbol "FOO")                    ; => #:FOO      ← #: 前缀表示「无归属」
(eq (make-symbol "FOO") (make-symbol "FOO"))   ; => NIL
(symbol-package (make-symbol "FOO"))   ; => NIL
```

`#:` 前缀独立出现的符号在**打印出来再读回去**时会变成另一个新符号 ——
这正是宏里 `gensym` 需要的性质（第 13 章）。

## 3.7 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| `(eql #\a 97)` 是 NIL | 字符不是整数 | 用 `char-code` 显式转换 |
| 改字面量字符串有时成功有时崩 | 字面量在只读内存 | 先 `copy-seq` 或 `make-array` |
| `(eq "a" "a")` 是 NIL | `eq` 比对象身份 | 比内容用 `equal` / `string=` |
| `(string< a b)` 返回数字 | 它返回的是差异下标 | 当布尔用即可，别和 `t` 比 |
| `(intern "foo")` 和 `'foo` 不相等 | 读入器把 `'foo` 变成大写 | `(intern (string-upcase s))` |
| `(string 42)` 报错 | `string` 只接受字符/符号/字符串 | 数字用 `write-to-string` |

---

# 第 4 章 列表与 cons：一根筋的数据结构

配套示例：`02-data-types.lisp`。

Lisp 的「列表」不是一种特殊容器，而是**由 `cons` 单元串起来的链**。搞清楚这一点，
后面所有列表函数的行为（包括破坏性操作、结构共享、`equal` 的边界）都能推出来。

## 4.1 cons 单元是唯一的砖

一个 `cons` 只有两格：`car` 和 `cdr`。

```lisp
(cons 1 2)              ; => (1 . 2)        ← 点号表示「两格都不是列表」
(cons 1 nil)            ; => (1)            ← cdr 是 nil，就打印成列表
(cons 1 (cons 2 nil))   ; => (1 2)
(cons 1 (cons 2 3))     ; => (1 2 . 3)      ← 最后一个 cdr 不是 nil，就是「点对」
(car (cons 1 2))        ; => 1
(cdr (cons 1 2))        ; => 2
```

所以 `(1 2 3)` 的真实结构是 `(1 . (2 . (3 . nil)))`。两个术语：

- **proper list**（正规列表）：最后一个 `cdr` 是 `nil`，能正常遍历；
- **dotted list**（点对列表）：最后不是 `nil`，`length` 之类会报错。

```lisp
(length '(1 . 2))       ; 报错：The value 2 is not of type LIST
```

`(last '(1 2 3))` 返回 `(3)` —— 注意它返回的是**最后一个 cons 单元**（也就是尾部的列表），
不是元素 `3`。

## 4.2 判定的反直觉之处

这一组谓词的名字和直觉经常不符，实测一遍：

```lisp
(listp '(1 . 2))     ; => T      ← 点对也算「列表」！
(listp nil)          ; => T
(consp nil)          ; => NIL    ← 这是唯一能区分 nil 的
(null nil)           ; => T
(atom '(1 2))        ; => NIL    ← atom 是「不是 cons」
(atom nil)           ; => T      ← nil 是原子
(type-of nil)        ; => NULL
(type-of '(1 2))     ; => CONS   ← 不是 LIST
```

要点：

- `listp` = 「是 cons **或**是 nil」，所以点对也返回 `T`；
- 想判断「非空列表」用 `consp`；
- `type-of` 一个列表返回 `CONS`，别拿它判断「是不是列表」，用 `listp`。

## 4.3 取元素：两种风格

```lisp
(nth 1 '(a b c))     ; => B
(first '(1 2 3))     ; => 1
(rest '(1 2 3))      ; => (2 3)
(elt '(1 2 3) 1)     ; => 2      ← 通用序列函数，列表向量都能用
```

但列表和向量**不能混用各自的取用函数**：

```lisp
(nth 1 #(a b c))     ; 报错：…is #(A B C), not a LIST.
(aref '(a b c) 1)    ; 报错：…is (A B C), not a VECTOR.
```

因为列表是链，`nth` 要**走 n 步**（O(n)）；向量是连续内存，`aref` 是 O(1)。
写循环里频繁 `nth` 是常见的性能事故。

## 4.4 append：只拷贝除最后一个以外的所有参数

```lisp
(append '(1 2) '(3 4))    ; => (1 2 3 4)
(append '(1 2) 3)         ; => (1 2 . 3)     ← 最后一个参数不必是列表！
```

第二条是很多人第一次踩的坑：`append` 的**最后一个参数原样接到后面**，
前面所有参数的顶层 cons 会被复制。所以传非列表进去不会报错，而是产生点对。

因为不复制最后一个参数，`append` 会产生**结构共享**：

```lisp
(defvar *shared* '(1 2))
(eq (append nil *shared*) *shared*)     ; => T
```

这条性质有用也有危险：改 `(append nil x)` 的结果会连带改到 `x`。要独立副本用
`(copy-list x)`。

## 4.5 破坏性操作：`n` 开头的函数

`n` 前缀（non-consing）意味着**就地修改**，通常还要求你**接住返回值**。
`reverse` 与 `nreverse` 的对照最清楚：

```lisp
(defvar *l4* (list 1 2 3))
(reverse *l4*)       ; => (3 2 1)
*l4*                 ; => (1 2 3)      ← 原列表没变

(defvar *l3* (list 1 2 3))
(nreverse *l3*)      ; => (3 2 1)
*l3*                 ; => (1)          ← 变量还指着原来的头，而它现在是尾巴！
```

`nreverse` 之后 `*l3*` 是 `(1)` 而不是 `(3 2 1)` —— 这是典型症状：
**破坏性函数必须用返回值，不能用原变量。**

`nconc` 把两个列表接起来，而且是**真的接上去**（共享对象）：

```lisp
(defvar *l1* (list 1 2))
(defvar *l2* (list 3 4))
(nconc *l1* *l2*)            ; => (1 2 3 4)
*l1*                         ; => (1 2 3 4)
(eq (cddr *l1*) *l2*)        ; => T       ← 接的就是同一个对象
```

同族的还有 `delete`（破坏性）与 `remove`（非破坏性）、`nsubst` / `subst`。
第 8 章会实测 `delete` 的一个著名陷阱。

## 4.6 拷贝的深浅

```lisp
(defvar *orig* (list 1 (list 2 3)))
(defvar *shallow* (copy-list *orig*))
(defvar *deep* (copy-tree *orig*))

(eq *orig* *shallow*)                       ; => NIL   ← 顶层是新对象
(eq (second *orig*) (second *shallow*))     ; => T     ← 内层共享！
(eq (second *orig*) (second *deep*))        ; => NIL   ← 深拷贝不共享
(copy-seq '(1 2 3))                         ; => (1 2 3)   向量/列表都能拷
```

`copy-list` 只复制顶层链条（浅拷贝），内层结构与原列表**共享**。
要完全独立用 `copy-tree`。

取子列表也是共享的：

```lisp
(defvar *l5* (list 1 2 3))
(nthcdr 1 *l5*)                      ; => (2 3)
(eq (nthcdr 1 *l5*) (cdr *l5*))      ; => T
```

## 4.7 当栈用：`push` / `pop` / `adjoin`

```lisp
(let ((s nil)) (push 1 s) (push 2 s) (list s (pop s) s))
; => ((2 1) 2 (1))
```

`push` 是「往头部塞」，`pop` 是「取头部」。想**不重复**地塞用 `pushnew`
（依赖 `adjoin`）：

```lisp
(adjoin 1 '(1 2))                          ; => (1 2)      ← 已存在，原样返回
(adjoin 3 '(1 2))                          ; => (3 1 2)
(let ((s (list 1 2))) (pushnew 3 s) s)     ; => (3 1 2)
```

注意 `pushnew` 的第一个参数必须是**变量**（它内部是 `setf`），
`(pushnew 3 (list 1 2))` 会报 `(SETF LIST) is undefined`。

## 4.8 关联表与属性表

**关联表**（alist）是「点对的列表」，按 `car` 查找：

```lisp
(defvar *alist* '((:a . 1) (:b . 2)))
(assoc :a *alist*)                ; => (:A . 1)
(cdr (assoc :a *alist*))          ; => 1
(assoc :z *alist*)                ; => NIL
```

**`assoc` 默认用 `eql` 比较**，所以字符串键找不到：

```lisp
(defvar *str-alist* '(("a" . 1) ("b" . 2)))
(assoc "a" *str-alist*)                          ; => NIL
(assoc "a" *str-alist* :test #'equal)            ; => ("a" . 1)
```

**属性表**（plist）是「平铺的键值对」，用 `getf`：

```lisp
(defvar *plist* (list :a 1 :b 2))
(getf *plist* :a)                 ; => 1
(getf *plist* :z)                 ; => NIL
(getf *plist* :z :默认值)         ; => :默认值
(setf (getf *plist* :c) 3)        ; 新键会插到最前面
*plist*                           ; => (:C 3 :A 1 :B 2)
```

每个**符号**自带一个属性表，可以用 `get` / `setf get` 存取 —— 这是 CL 里
「给符号挂元数据」的传统做法（现代代码一般用哈希表）：

```lisp
(setf (get 'foo 'color) :red)
(get 'foo 'color)                 ; => :RED
(symbol-plist 'foo)               ; => (COLOR :RED)   ← 属性表的形状是 (键 值 键 值 …)
```

注意属性表是**平整的 plist**（`(COLOR :RED)`），不是点对列表 `((COLOR . :RED))` ——
这一点和 `alist` 容易混（第 4 章开头讲过两者的区别）。

## 4.9 相等：五种，各管一段

这是 CL 里必须背下来的一张表（全部实测）：

| 函数 | 比什么 | `(… 1 1.0)` | `(… "a" "a")` | `(… #(1 2) #(1 2))` |
|---|---|---|---|---|
| `eq` | 同一个对象 | `T`（注） | `NIL` | `NIL` |
| `eql` | 同一对象**或**同类型同数值 | `NIL` | `NIL` | `NIL` |
| `equal` | 结构相同（cons/字符串/位向量/路径名） | `NIL` | `T` | `NIL` |
| `equalp` | 更宽松：字符串不分大小写、向量比内容、数字跨类型 | `T` | `T`（且 `"AB"` = `"ab"`） | `T` |
| `=` | 数值 | `T` | 类型错误 | 类型错误 |

字面量实测：

```lisp
(eq 'a 'a)              ; => T
(eq 1 1)                ; => T
(eq 1.0 1.0)            ; => T
(eq #\a #\a)            ; => T
(eq "a" "a")            ; => NIL
(eq (list 1) (list 1))  ; => NIL
(eql 1 1.0)             ; => NIL
(eql 1.0 1.0)           ; => T
(equal (list 1 2) (list 1 2))   ; => T
(equal "ab" "ab")               ; => T
(equal "AB" "ab")               ; => NIL
(equal #(1 2) #(1 2))           ; => NIL      ← 向量不按内容比
(equalp #(1 2) #(1 2))          ; => T
(equalp "AB" "ab")              ; => T        ← 不分大小写
(equalp 1 1.0)                  ; => T
(= 1 1.0)                       ; => T
```

> **注**：`(eq 1.0 1.0)`、`(eq 1.0 (float 1))` 在 SBCL 上都是 `T`（小浮点是立即数），
> 但**标准并不保证** `eq` 对数字的行为。比较数字一律用 `=`，比较浮点用 `eql`。

**结构体要用 `equalp`**（这是和 CLOS 实例的一个关键差别，第 9、11 章会再提）：

```lisp
(defstruct pt x y)
(equal  (make-pt :x 1) (make-pt :x 1))    ; => NIL
(equalp (make-pt :x 1) (make-pt :x 1))    ; => T
```

**实践建议**：

- 比数字用 `=`，比字符用 `char=`，比字符串内容用 `string=` / `equal`；
- 别用 `eq` 比任何「看起来像值」的东西（字符串、列表、浮点）；
- 判断「是不是同一个对象」时才用 `eq`。

## 4.10 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| `(append '(1 2) 3)` 得点对 | 最后一个参数原样接上 | 最后一个参数也写成列表 |
| `(nreverse x)` 之后 `x` 变了 | 破坏性 + 变量仍指旧头 | 一定用返回值 |
| `(delete 1 x)` 没删掉 1 | 删头元素时旧变量失效 | 用返回值 |
| `(length '(1 . 2))` 报错 | 点对不是正规列表 | 先确认结构，或用 `list-length` |
| `(assoc "a" alist)` 找不到 | 默认 `eql` 比较 | 带 `:test #'equal` |
| `(equal #(1 2) #(1 2))` 是 NIL | `equal` 不比向量内容 | 用 `equalp` |
| `nth` 在大列表里很慢 | 列表是链，`nth` 是 O(n) | 改用向量 + `aref` |

---

# 第 5 章 变量与作用域：词法还是动态

配套示例：`04-functions.lisp`。

这一章是 CL 与几乎所有主流语言差别最大的地方，也是 Lisp 的「宏」能成立的原因。

## 5.1 三种定义全局变量的方式，语义各不相同

| 形式 | 重复加载时 | 适合 |
|---|---|---|
| `(defvar *x* v)` | **不覆盖**已存在的值 | 配置、可选状态 |
| `(defparameter *x* v)` | **覆盖**，每次加载都重置 | 必须重置的参数 |
| `(defconstant +x+ v)` | 不许再改 | 真常量 |

「重复加载」的差别值得亲手跑一遍。连续加载同一个文件两次，文件内容是：

```lisp
(defvar *dv* 1)
(defparameter *dp* 1)
(format t "加载时 *dv* = ~S   *dp* = ~S~%" *dv* *dp*)
(setf *dv* :changed-in-first-load
      *dp* :changed-in-first-load)
(format t "改动后 *dv* = ~S   *dp* = ~S~%" *dv* *dp*)
```

```
第 1 次加载：
加载时 *dv* = 1                     *dp* = 1
改动后 *dv* = :CHANGED-IN-FIRST-LOAD   *dp* = :CHANGED-IN-FIRST-LOAD

第 2 次加载：
加载时 *dv* = :CHANGED-IN-FIRST-LOAD   *dp* = 1
改动后 *dv* = :CHANGED-IN-FIRST-LOAD   *dp* = :CHANGED-IN-FIRST-LOAD
```

对比两轮的「加载时」那一行：`*dv*` 保留了上一轮改过的值，`*dp*` 被打回初值 `1`。
这个差别就是 `defvar` 与 `defparameter` 的差别。

**这就是为什么「改完代码重新加载」时，你的调试状态有时会保留、有时被冲掉**。
把「每次都要回到初值」的变量写成 `defparameter` 是更好的默认选择。

另外两个实测细节：

```lisp
(defvar *v* 1)
(defvar *v* 999)
*v*                    ; => 1        ← 第二次 defvar 不生效

(defvar *u*)           ; 只声明，不绑定
(boundp '*u*)          ; => NIL      ← 注意：还是没有值！
(symbol-value '*u*)    ; 报错：The variable *U* is unbound.
```

**`defvar` 不带初值只声明「这是个特殊变量」，不会创建绑定。** 很反直觉，但确实如此。

常量被赋值是编译期错误：

```lisp
(defconstant +c+ 1)
(setf +c+ 2)
```

```
Execution of a form compiled with errors.
Form:
  (SETQ +C+ 2)
Compile-time error:
  +C+ is a constant and thus can't be set.
```

**命名约定**：全局变量用「耳罩」`*name*`。这不只是风格 ——
它让读代码的人一眼看出「这里可能被动态绑定」，也让 SBCL 对这类名字有额外的检查。

## 5.2 `let` 是并行绑定，`let*` 是顺序绑定

这是初学 CL 最常见的运行期错误：

```lisp
(let ((a 1) (b (+ a 1))) b)
; 报错：The variable A is unbound.
```

因为 `let` 的所有初值表达式是在**外层环境**里求值的，`b` 的初值看不到同一个 `let`
刚绑定的 `a`。要顺序绑定用 `let*`：

```lisp
(let* ((a 1) (b (+ a 1))) b)     ; => 2
```

内层遮蔽时，这个差别更明显：

```lisp
(let ((a 0)) (let ((a 1) (b a)) (list a b)))      ; => (1 0)   ← b 拿到外层 a
(let* ((a 0)) (let* ((a 1) (b a)) (list a b)))    ; => (1 1)   ← b 拿到刚绑的 a
```

**实践建议**：不确定时用 `let*`，它的行为是「从上往下读」的直觉。

## 5.3 词法作用域 vs 动态作用域（重头戏）

CL 默认是**词法作用域**：函数体只能看到自己定义处能看到的变量，
看不到**调用者**的局部变量。

```lisp
(defun callee () *lexical-x*)
(defun caller () (let ((*lexical-x* :from-caller)) (callee)))
(caller)
; 报错：The variable *LEXICAL-X* is unbound.
```

`caller` 里那个 `let` 只是个普通的词法绑定，`callee` 根本看不到它。
这就是 Java / Python / JS 的行为，符合直觉。

但如果你把变量声明成**特殊变量**（用 `defvar` / `defparameter` 声明过），
绑定就变成**动态作用域** —— 会跟着调用链往下走：

```lisp
(defvar *dyn-x* :global)
(defun dcallee () *dyn-x*)
(defun dcaller () (let ((*dyn-x* :from-caller)) (dcallee)))
(dcaller)     ; => :FROM-CALLER
*dyn-x*       ; => :GLOBAL      ← 调用结束自动恢复
```

注意最后一行的 `:GLOBAL`：动态绑定是**栈式**的，退出 `let` 就恢复原值。
这条性质让动态变量天然适合「临时改变配置」：

```lisp
(let ((*print-base* 16))
  (format t "~X~%" 255))            ; 这个 let 里所有打印都受影响
```

标准库自己就是这么干的（`*print-base*`、`*package*`、`*standard-output*`
全都是动态变量）。

**让 `let` 产生动态绑定的条件**：符号必须是**已声明为 special 的**。
`defvar` / `defparameter` 会自动声明；只想临时声明可以显式写：

```lisp
(let ((x 1)) (declare (special x)) (boundp 'x))     ; => T
```

`(declare (special x))` 之后，这个 `x` 成了动态变量。

> **为什么 Lisp 要两套并存？** 因为动态作用域的「跟着调用链走」
> 恰好是「临时改变全局配置」需要的行为。现代语言要用线程局部变量或依赖注入
> 模拟的东西，CL 一个 `let` 就够了。代价是容易误用，所以约定用 `*耳罩*` 命名区分。

## 5.4 闭包

函数可以捕获定义处的词法环境：

```lisp
(defun make-adder (n) (lambda (x) (+ x n)))
(funcall (make-adder 3) 4)          ; => 7
```

捕获的是**变量**而不是值，所以状态可以累积（这是 CL 里做「对象」的老办法）：

```lisp
(let ((acc 0))
  (defun push-acc (v) (incf acc v))
  (push-acc 5)
  (push-acc 5)
  acc)                              ; => 10
```

`defun` 写在 `let` 里面也是合法的顶层定义，它会把 `acc` 这个**词法**变量封进函数里。

## 5.5 给全局变量赋值的几种写法

```lisp
(defvar *counter* 0)
(setf *counter* 7)                    ; 最常用
(setf (symbol-value '*counter*) 8)    ; 显式走「变量格」，宏里常用
(incf *counter*)                      ; 自增
```

还有一个容易误用的写法：**没 `defvar` 过的名字直接 `setf`**，SBCL 会隐式建立一个
全局绑定，但会给编译警告（`undefined variable`）。别依赖它 ——
声明过的变量和没声明过的，在编译优化上完全是两回事。

## 5.6 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| `(let ((a 1) (b (+ a 1))) ...)` 报 `A is unbound` | `let` 是并行绑定 | 用 `let*` |
| `(defvar *x*)` 之后 `*x*` 还是 unbound | 无初值不创建绑定 | 给初值 |
| 重新加载后变量回到初值（或没回） | `defparameter` 会重置、`defvar` 保留 | 按需要选 |
| 函数里读不到调用者的局部变量 | 默认词法作用域 | 用动态变量（`defvar` 声明） |
| 全局变量忘了 `defvar` | 隐式建立了全局绑定 + 警告 | 显式声明 |

---

# 第 6 章 函数

配套示例：`04-functions.lisp`。

## 6.1 参数模型的四件套

`defun` 的形参列表可以按顺序摆这四段（实测）：

```lisp
(defun opt (a &optional (b :b默认值)) (list a b))
(opt 1)          ; => (1 :B默认值)     留空用默认值
(opt 1 2)        ; => (1 2)

(defun rest-only (&rest xs) (list (length xs) xs))
(rest-only)          ; => (0 NIL)
(rest-only 1 2 3)    ; => (3 (1 2 3))

(defun keyed (&key a (b 2) (c 3 c-p)) (list a b (and c-p t)))
(keyed :a 1)             ; => (1 2 NIL)
(keyed :a 1 :c nil)      ; => (1 2 T)      ← 显式传 nil 也算「给过」，c-p 为真

(defun aux (a &aux (b (* a 2))) (list a b))
(aux 5)          ; => (5 10)           &aux 是纯局部变量，不是参数
```

**`b-p` 这种「有没有给过」的判断很重要**，因为 `nil` 也是合法值：

```lisp
(defun opt-sp (a &optional (b 10 b-p)) (list a b (and b-p t)))
(opt-sp 1)          ; => (1 10 NIL)     ← 没给，用默认值
(opt-sp 1 nil)      ; => (1 NIL T)      ← 给了 nil，不是默认值
```

不带「有没有给过」的变量就分不出这两种情况。

默认值表达式**可以引用前面的参数**：

```lisp
(defun default-sees-earlier (a &optional (b (1+ a))) (list a b))
(default-sees-earlier 10)     ; => (10 11)
```

段与段的组合有规则：`&optional` 要在 `&rest`/`&key` 前面。要允许未知关键字：

```lisp
(defun mixed (a &optional b &rest r &key k1 k2 &allow-other-keys)
  (list a b r k1 k2))
(mixed 1 2 :k1 3)     ; => (1 2 (:K1 3) 3 NIL)
```

注意 `&rest r` 和 `&key k1 k2` **共享同一批实参** —— `r` 拿到完整的 `(:K1 3)`，
`k1` 再从中解析出 `3`。

## 6.2 多值：返回「不止一个结果」

`floor` 这类函数需要同时返回商和余数。CL 的做法是**多值**（values）而不是元组：

```lisp
(floor 7 2)              ; => 3          ← 只显示第一个值
(multiple-value-list (floor 7 2))          ; => (3 1)
(nth-value 1 (floor 7 2))                  ; => 1
(multiple-value-bind (q r) (floor 7 2) (list q r))   ; => (3 1)
(multiple-value-list (values))             ; => NIL
(setf (values a b) (floor 7 2))            ; 也能用 setf 接
```

多值的关键性质：**在普通「单值上下文」里，多余的值会被静默丢弃。**

```lisp
(list (values 1 2))      ; => (1)        ← 2 被丢了，不报错
```

这条和元组/多返回值的语言很不一样：CL 里「接收方」负责声明要几个值，
所以同一行的 `(floor 7 2)` 既能当单个数字用，也能拆成两个。好处是不用为了
「顺便返回个额外信息」而包装成对象；代价是**忘了接就静默丢**。

想看有没有丢，用 `multiple-value-list` 显式捕获来调试。

## 6.3 局部函数：`flet` 与 `labels`

```lisp
(flet ((f (x) (* x 2))) (f 4))                ; => 8        互相不可见
(labels ((f (n) (if (zerop n) 1 (* n (f (1- n)))))) (f 5))   ; => 120  可以互相递归
(macrolet ((m (x) `(+ ,x 1))) (m 4))          ; => 5        定义局部宏
```

**用 `labels` 写递归，`flet` 写互不调用的辅助函数。** 这是最常见的写法约定。

## 6.4 尾调用：SBCL 实测到哪一步

这一条网上说法很乱，直接实测（SBCL 2.6.7）：

```lisp
(defun self (n) (if (zerop n) :done (self (1- n))))
(defun me (n) (if (zerop n) t (mo (1- n))))
(defun mo (n) (if (zerop n) nil (me (1- n))))
```

| 情况 | 结果 |
|---|---|
| 自尾递归 `(self 1000000000)`（10 亿） | `:DONE` — 不爆栈 |
| 互尾递归 `(me 1000000000)`（10 亿） | `T` — 不爆栈 |
| 同样代码加 `(declaim (optimize (debug 3) (speed 0) (safety 3)))` 后 `(me 10000000)` | **爆栈** |

爆栈时的信息非常好，直接点名了原因：

```
Control stack exhausted (no more space for function call frames).
This is probably due to heavily nested or infinitely recursive function
calls, or a tail call that SBCL cannot or has not optimized away.
```

**结论**：SBCL 在默认优化级别下会做尾调用优化，自递归和互递归都吃；
但**提高 `debug` 级别会关掉它**（为了保留完整栈帧供调试）。
ANSI 标准**不要求**任何实现做 TCO，所以：

- 别把「靠 TCO 跑得动」当可移植保证，长循环用 `loop` / `do` / `dotimes`；
- 要写深度递归的算法时，先在手头的实现上压测一次。

## 6.5 函数是数据：`#'` 与 `'`

```lisp
(funcall #'car '(1 2))            ; => 1
(funcall 'car '(1 2))             ; => 1     ← 符号也能当函数设计符
(funcall (lambda (x) (1+ x)) 1)   ; => 2
(mapcar #'1+ '(1 2 3))            ; => (2 3 4)
```

三种「函数设计符」都行：`#'car`（函数对象）、`'car`（符号）、`(lambda ...)`
（匿名函数对象）。`#'` 是 `(function car)` 的简写。

因为变量格和函数格分开（第 3 章），把函数存在变量里要用 `funcall`：

```lisp
(let ((f #'car)) (funcall f '(1 2)))     ; => 1
```

**不能**写 `(f '(1 2))` —— 那会被当成「调用名为 `f` 的函数」而不是「调用 `f` 变量里的函数」。

`apply` 用来把列表展成实参：

```lisp
(apply #'+ '(1 2 3))              ; => 6
```

## 6.6 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| `&optional` 变量分不清「没给」和「给了 nil」 | 少一个 supplied-p 变量 | 加 `(b 10 b-p)` |
| `(floor 7 2)` 拿到 3 丢了 1 | 单值上下文只取第一个值 | `multiple-value-bind` / `nth-value` |
| `(f ...)` 报 undefined function | `f` 是变量里的函数 | 用 `funcall` |
| 递归爆栈 | 优化级别高（debug 3）关掉了 TCO | 降 debug 或改写成循环 |
| `&key` 收到未知关键字报错 | 默认不宽松 | 加 `&allow-other-keys` |

---

# 第 7 章 控制流与迭代

配套示例：`03-control-structures.lisp`。

## 7.1 只有 `nil` 是假

这是 CL 与 C/Python 差别最大的常识点，实测一遍：

```lisp
(if 0 :true :false)      ; => :TRUE      ← 0 是真！
(if "" :true :false)     ; => :TRUE      ← 空字符串是真！
(if '() :true :false)    ; => :FALSE     ← 空表就是 nil，才是假
(if nil :true :false)    ; => :FALSE
(not 0)                  ; => NIL
(null 0)                 ; => NIL
(not '())                ; => T
```

**把 C 代码翻成 Lisp 时最容易漏的一处**：`if (n)` 在这种语境下常表示「n 非零」，
但 Lisp 的 `(if n ...)` 对 `0` 是真。要判断零用 `(if (zerop n) ...)`。

`not` 和 `null` 在 CL 里是**同一个函数**（都返回 `(if x nil t)`），
用哪个纯粹看可读性：判断「是空表」写 `null`，判断「是假」写 `not`。

## 7.2 分支：`if` / `when` / `unless` / `cond` / `case`

```lisp
(if (> 1 2) :yes)                ; => NIL      ← 没有 else 分支就返回 NIL
(when (> 2 1) :a :b)             ; => :B       ← 相当于 progn + if
(unless (> 1 2) :a :b)           ; => :B
```

`cond` 是从上往下找第一个为真的分支，全假返回 `NIL`：

```lisp
(defun grade (n)
  (cond ((> n 90) :a) ((> n 80) :b) ((> n 70) :c) (t :f)))
(grade 95)      ; => :A
(grade 60)      ; => :F
(cond (nil :a) (nil :b))     ; => NIL
```

`case` 按**值的相等性**分支（内部用 `eql`），匹配不上且没有 `otherwise` 就返回 `NIL`：

```lisp
(case 2 (1 :one) (2 :two) (otherwise :other))        ; => :TWO
(case 7 ((1 3 5 7) :odd-digit) (t :other))           ; => :ODD-DIGIT   ← 多个值要写成列表
(case 9 (1 :one))                                    ; => NIL
(ecase 9 (1 :one))                                   ; 报错：9 fell through ECASE expression. Wanted one of (1).
```

**`case` 用 `eql`，所以字符串和浮点永远匹配不上**：

```lisp
(case "a" ("a" :string-case) (otherwise :other))     ; => :OTHER      ← 不是 :STRING-CASE！
```

要按类型分支用 `typecase` / `etypecase`：

```lisp
(typecase "s" (integer :int) (string :str) (t :other))   ; => :STR
(typecase 1.0 (integer :int) (string :str))              ; => NIL
(etypecase 1.0 (integer :int) (string :str))
; 报错：1.0 fell through ETYPECASE expression. Wanted one of (INTEGER STRING).
```

`e` 前缀的版本（`ecase` / `etypecase` / `ccase`）匹配不上时报错而不是返回 `NIL`。
**多写 `ecase` 比写 `case` 安全** —— 拼错的常量会立刻暴露。

## 7.3 `and` / `or` 返回的是值，不是布尔

```lisp
(and 1 2 3)          ; => 3          ← 最后一个真值
(and 1 nil 3)        ; => NIL
(or nil nil :x)      ; => :X
(and)                ; => T          ← 零个参数是 T
(or)                 ; => NIL
```

因为短路，`and` 最适合写「先判断再取用」：

```lisp
(let ((v nil)) (and v (length v)))       ; => NIL    ← v 是 nil 时不会去调 length
(and nil (error "不该被求值"))            ; => NIL    ← 右边根本没执行
(or :x (error "不该被求值"))              ; => :X
```

这个习惯（`(and obj (slot-of obj))`）在 CL 代码里到处都是，
等价于其它语言的 `obj?.slot`。

## 7.4 三种简单循环

```lisp
(dotimes (i 3) (format t "~A~%" i))       ; 打印 0 1 2
(dotimes (i 3 i) ...)                     ; 第三个元素是返回值，注意它引用 i 没问题
(dolist (x '(:a :b)) (format t "~A~%" x)) ; 遍历列表
```

返回值都取「有值的那一段」：

```lisp
(let (r) (dotimes (i 3 r) (setf r i)))     ; => 2
(dolist (x '(:a :b) :finished) x)          ; => :FINISHED     ← 第三个元素是结果表达式
(dolist (x '(1 2 3)) (when (= x 2) (return x)))   ; => 2       ← return 提前退出
```

`return` 能用在 `dotimes` / `dolist` / `loop` 里，因为它们的循环体被包在一个
**隐式的 `nil` 块**里（下一节解释）。

## 7.5 `do`：最灵活也最啰嗦

`do` 的语法是「变量表 + 结束条件 + 循环体」：

```lisp
(do ((i 1 (1+ i)) (a 0 b) (b 1 (+ a b)))
    ((= i 10) a))
; => 34     斐波那契第 10 项
```

`(a 0 b)` 表示初值 `0`、下一轮的值取 `b` ——
这是 `do` 的并行赋值，能写出很紧凑的迭代。另外要记住**结束判断在每轮循环体之前**：

```lisp
(do ((i 0 (1+ i))) ((= i 3) :done) (format t "  body i=~A~%" i))
```

```
  body i=0
  body i=1
  body i=2
```

实际项目里 `do` 用得比 `loop` 少，因为 `loop` 可读性好得多。会读 `do` 就够了。

## 7.6 `loop`：CL 里最实用的宏

`loop` 有两种形态。简单形态就是把上面那些「遍历 + 汇总」写得像英语：

```lisp
(loop for i from 1 to 5 collect i)                  ; => (1 2 3 4 5)
(loop for i below 5 collect i)                      ; => (0 1 2 3 4)
(loop for i from 0 to 10 by 2 collect i)            ; => (0 2 4 6 8 10)
(loop for i downfrom 3 to 1 collect i)              ; => (3 2 1)
(loop for x in '(1 2 3) sum x)                      ; => 6
(loop for x in '(1 2 3) count (oddp x))             ; => 2
(loop for x in '(3 1 2) maximize x)                 ; => 3
(loop for x in '(3 1 2) minimize x)                 ; => 1
(loop for x in '((1 2) (3 4)) append x)             ; => (1 2 3 4)
(loop repeat 3 collect :x)                          ; => (:X :X :X)
```

遍历各种容器：

```lisp
(loop for x across #(1 2 3) collect (* x x))          ; => (1 4 9)      向量
(loop for x on '(1 2 3) collect x)                     ; => ((1 2 3) (2 3) (3))   尾巴而非元素
(loop for (k . v) in '((:a . 1) (:b . 2)) collect v)   ; => (1 2)        解构
```

遍历哈希表要单独记一句语法（`hash-keys` / `hash-values` / `hash-pairs`）：

```lisp
(let ((ht (make-hash-table)))
  (setf (gethash :a ht) 1 (gethash :b ht) 2)
  (loop for k being the hash-keys of ht collect k))
; 一次运行的结果 => (:B :A)     ← 顺序不定（原因见 9.2 节）
```

`for x on` 和 `for x in` 的差别值得单记一笔：**`on` 给的是「每一段尾巴」**，
所以结果是 `((1 2 3) (2 3) (3))`。要在 `on` 上取元素得写 `(car x)`。

条件与提前结束：

```lisp
(loop for x in '(1 2 3 4) when (evenp x) collect x)          ; => (2 4)
(loop for x in '(1 2 3 4) if (evenp x) collect x else collect 0)  ; => (0 2 0 4)
(loop for i from 1 while (< i 4) collect i)                  ; => (1 2 3)
(loop for i = 0 then (1+ i) until (> i 2) collect i)          ; => (0 1 2)
(loop for x in '(1 2 3) thereis (> x 2))                      ; => T     找到就停
(loop for x in '(1 2 3) always (integerp x))                  ; => T     全部为真
(loop for x in '(1 2 3) never (minusp x))                     ; => T
```

`with` 定义累积变量、`initially` / `finally` 在首尾执行：

```lisp
(loop with n = 5 for i below n collect i)     ; => (0 1 2 3 4)

(loop initially (format t "  开始时~%")
      for i below 2
      do (format t "  i=~A~%" i)
      finally (format t "  结束~%")
      collect i)
```

```
  开始时
  i=0
  i=1
  结束
```

命名块 + `return-from` 可以从中途退出（`loop` 自带 `nil` 块，所以裸 `return`
也能用，但只能退出最近的一层）：

```lisp
(loop named sum-to for i from 1 to 100 when (> i 5) do (return-from sum-to :early) sum i)
; => :EARLY

(loop for i below 3 do (return :from-return) finally (return :from-finally))
; => :FROM-RETURN        ← do 里的 return 先执行
```

嵌套 `loop` 时 `collect` 的结果是一个列表的列表：

```lisp
(loop for i below 3 collect (loop for j below 2 collect (list i j)))
; => (((0 0) (0 1)) ((1 0) (1 1)) ((2 0) (2 1)))
```

## 7.7 非局部退出：四种机制

**`block` / `return-from`** —— 命名出口：

```lisp
(block b (return-from b :done) :never)      ; => :DONE
(block nil (return 42) :never)              ; => 42
```

`(return x)` 其实是 `(return-from nil x)` 的简写。`loop` / `dolist` /
`dotimes` 会在外面包一层名为 `nil` 的块，所以里面能直接 `return`。

**`catch` / `throw`** —— 动态的、按标签的出口：

```lisp
(catch 'tag (throw 'tag :caught))           ; => :CAUGHT
(catch 'tag :no-throw)                      ; => :NO-THROW
(catch 'tag (mapc (lambda (x) (when (= x 2) (throw 'tag x))) '(1 2 3)) :none)
; => 2
```

`catch` 的标签是按**对象身份**找的（通常用符号或关键字），
所以可以穿越很深的调用栈 —— 这是「从深层回调里直接跳出」的标准做法。

**`unwind-protect`** —— 无论怎么退出都执行清理：

```lisp
(block b
  (unwind-protect (return-from b :jumped)
    (format t "  cleanup 仍然执行~%")))
```

```
  cleanup 仍然执行
=> :JUMPED
```

注意顺序：**cleanup 先执行，然后才把控制权交出去**。这是 `try/finally` 的对应物，
也是关闭文件、释放锁的标准写法（`with-open-file` 内部就是它）。

**`tagbody` / `go`** —— 最底层的跳转，现在很少手写：

```lisp
(let ((i 0) (acc nil))
  (tagbody top (when (< i 3) (push i acc) (incf i) (go top)))
  (reverse acc))
; => (0 1 2)
```

顺手记两个常用工具：

```lisp
(prog1 :a :b :c)      ; => :A     ← 按顺序求值，返回第一个
(prog2 :a :b :c)      ; => :B     ← 返回第二个
```

`prog1` 特别适合「先取旧值再改」的场景，例如交换或计数。

## 7.8 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| `(if 0 ...)` 走了「真」分支 | 只有 `nil` 是假 | 用 `(zerop x)` 等显式判断 |
| `case` 匹配字符串/浮点总是失败 | `case` 用 `eql` | 用 `cond` / `typecase` / `string=` 判断 |
| 忘了 `otherwise` 静默拿到 `NIL` | `case` 无匹配返回 `NIL` | 需要报错就用 `ecase` |
| `(loop for x on lst ...)` 拿到的是尾巴 | `on` 给的是子列表 | 用 `in`，或 `(car x)` |
| **`for i downfrom 3` 不写 `to` 把内存吃爆** | 没有上界就是死循环 | 一定写 `to`（下面有真实后果） |
| `nested loop` 的结果比预期多一层 | 每个 `loop` 各自 collect | 需要平铺用 `append` |

> **关于那个死循环**：本指南在实测时就真的写错过一次
> `(loop for i downfrom 3 collect i)`（漏了 `to 1`）。SBCL 没有报错、没有断点，
> 它一直往列表里塞元素，最后以**进程级致命错误**结束：
>
> ```
> Heap exhausted during garbage collection: 0 bytes available, 16 requested.
> ...
> fatal error encountered in SBCL pid 45101:
> Heap exhausted, game over.
> ```
>
> 这个错误**不是可捕获的 condition**，`handler-case` 拦不住，进程直接没了。
> 写无界 `loop` 时务必确认终止条件。

---

# 第 8 章 序列与高阶函数

配套示例：`16-sequences-hash-tables.lisp`。

CL 把「列表」和「向量」抽象成**序列**（sequence），于是 `length` / `subseq` /
`reverse` / `find` / `sort` 这些函数对两种容器都通用：

```lisp
(length '(1 2 3))            ; => 3
(length #(1 2 3))            ; => 3
(elt '(1 2 3) 1)             ; => 2
(elt #(1 2 3) 1)             ; => 2
(subseq '(1 2 3 4) 1 3)      ; => (2 3)
(subseq #(1 2 3 4) 1 3)      ; => #(2 3)
(reverse '(1 2 3))           ; => (3 2 1)
(reverse #(1 2 3))           ; => #(3 2 1)
(concatenate 'list '(1 2) #(3 4))      ; => (1 2 3 4)   ← 类型混着传也行
(concatenate 'vector '(1 2) #(3 4))    ; => #(1 2 3 4)
```

`coerce` 在类型之间转换：

```lisp
(coerce '(1 2 3) 'vector)      ; => #(1 2 3)
(coerce #(1 2 3) 'list)        ; => (1 2 3)
(coerce '(#\a #\b) 'string)    ; => "ab"      ← 字符列表变字符串
(concatenate 'string "ab" "cd") ; => "abcd"
```

`concatenate` 和 `coerce` 是最常用的两个「类型转换」入口。

## 8.1 map 家族：`mapcar` 和 `map` 的区别是返回类型

```lisp
(mapcar #'1+ '(1 2 3))              ; => (2 3 4)
(mapcar #'+ '(1 2) '(10 20))        ; => (11 22)     ← 多个列表并行喂
(map 'list #'1+ #(1 2 3))           ; => (2 3 4)
(map 'vector #'1+ #(1 2 3))         ; => #(2 3 4)
(map 'string #'char-upcase "abc")   ; => "ABC"       ← 结果类型由第一个参数决定
```

**`mapcar` 只能吃列表、返回列表；`map` 的第一个参数决定返回什么类型。**
要处理字符串或向量，用 `map`。

长度不等时**取最短的**（不像有些语言报错）：

```lisp
(mapcar #'+ '(1 2 3) '(10 20))      ; => (11 22)     ← 第三个元素被丢掉
```

`maplist` / `mapcon` 操作的是**子列表**而不是元素 —— 和 `for x on` 是同一个概念：

```lisp
(maplist #'identity '(1 2 3))       ; => ((1 2 3) (2 3) (3))
(mapcon #'list '(1 2 3))            ; => ((1 2 3) (2 3) (3))
```

还有原地写入的 `map-into`（省掉分配）：

```lisp
(map-into (make-list 3) #'1+ '(1 2 3))     ; => (2 3 4)
```

## 8.2 `sort` 是破坏性的，必须接返回值

这是 CL 新手最常见的 bug 之一。`sort` **会改掉你传进去的那个序列**：

```lisp
(defvar *xs* (list 3 1 2))
*xs*                       ; => (3 1 2)
(sort *xs* #'<)            ; => (1 2 3)
*xs*                       ; => (1 2 3)     ← 原列表被改掉了
```

向量也一样：

```lisp
(defvar *vec* (vector 3 1 2))
(sort *vec* #'<)           ; => #(1 2 3)
*vec*                      ; => #(1 2 3)
```

而**列表排序时，返回值可能不是同一个对象**（`sort` 允许重建链），所以：

```lisp
(sort (list 3 1 2) #'<)         ; 不接返回值 → 排序结果直接被丢掉
(sort (copy-list '(3 1 2)) #'<) ; => (1 2 3)
```

**规矩：`sort` 的结果一律接住，而且要排序就别改原数据就 `copy-list` / `copy-seq`。**

`stable-sort` 保证相等元素的相对顺序不变（`sort` 不保证）：

```lisp
(stable-sort (copy-list '((1 :a) (1 :b) (0 :c))) #'< :key #'car)
; => ((0 :C) (1 :A) (1 :B))
```

`:key` 是「比之前先做一次变换」，比写 lambda 清楚：

```lisp
(sort (copy-list '(1 2 3)) #'> :key #'-)     ; => (1 2 3)
```

## 8.3 `remove` 与 `delete`：一个非破坏、一个破坏

```lisp
(defvar *ys* (list 1 2 3 2))
(remove 2 *ys*)        ; => (1 3)
*ys*                   ; => (1 2 3 2)     ← 没变
(delete 2 *ys*)        ; => (1 3)
*ys*                   ; => (1 3)         ← 变了
```

`delete 2` 之后 `*ys*` 也变成 `(1 3)`（因为被删的元素在中间，链条能就地改）。
但如果**删的是第一个元素**，`delete` 没法就地改，必须靠返回值：

```lisp
(defvar *zs* (list 1 2 3 2))
(delete 1 *zs*)        ; => (2 3 2)
*zs*                   ; => (1 2 3 2)     ← 旧变量还指着旧头，没删掉！
```

**这条是最容易上线的 bug**：`(delete x lst)` 的结果不接就丢掉，在「恰好要删头元素」
的时候失效。

我的建议：**默认用 `remove`**（非破坏，语义清晰），只有在确定的性能热点上才换
`delete` 并严格接返回值。

## 8.4 `remove-duplicates` 保留的是**最后**一个

反直觉但确定：

```lisp
(remove-duplicates '(1 2 1 3))                  ; => (2 1 3)    ← 保留后面的 1，丢掉第一个
(remove-duplicates '(1 2 1 3) :from-end t)      ; => (1 2 3)    ← 保留第一个
```

想「保留第一次出现的」要显式写 `:from-end t`。这一条在去重时影响很大 ——
如果元素是「后来的覆盖前面的」（比如配置项），默认行为正好合适；
如果是「先来的优先」，就得加 `:from-end t`。

## 8.5 查找、计数与判定

```lisp
(find 3 '(1 2 3 4))                 ; => 3
(find-if #'evenp '(1 3 6 7))        ; => 6
(find 3 '(1 2 3 4) :from-end t)     ; => 3
(position #\l "hello")              ; => 2
(count 2 '(1 2 2 3))                ; => 2
(count-if #'oddp '(1 2 3 5))        ; => 3
(search '(2 3) '(1 2 3 4))          ; => 1        ← 子序列出现的位置
(mismatch '(1 2 3) '(1 9 3))        ; => 1        ← 第一个不同的下标
(mismatch '(1 2) '(1 2))            ; => NIL      ← 完全相同才 NIL
(substitute 0 2 '(1 2 3 2))         ; => (1 0 3 0)
```

它们都接受 `:test` / `:key`：

```lisp
(remove 2 '(1 2 3) :test #'< )      ; => (1 2)     ← 用 < 判断「相等」，2 只不小于 1
(remove 2 '(1 2 3) :start 2)        ; => (1 2 3)   ← 从下标 2 开始找，没找到
```

`:test` 的语义是「当相等看待」的谓词，很容易写反（上例 `#'<` 之下，
只有比 2 大的才算「等于 2」），用的时候多想一秒。

判定整个序列的性质，这四个函数比手写循环清楚：

```lisp
(every #'evenp '(2 4 6))                   ; => T
(some #'evenp '(1 3 4))                    ; => T
(notany #'oddp '(2 4))                     ; => T
(notevery #'evenp '(2 3))                  ; => T
(every #'< '(1 2 3) '(2 3 4))              ; => T     ← 也可以多序列并行
```

`some` 返回的是**第一个非 nil 的结果**（不是 `T`），所以能用来「找到第一个满足条件的」：

```lisp
(some (lambda (x) (and (evenp x) (* x 10))) '(1 3 4))     ; => 40
```

## 8.6 `reduce`：三个容易踩的边界

```lisp
(reduce #'+ '(1 2 3 4))              ; => 10
(reduce #'+ '(1 2 3) :initial-value 10)   ; => 16
(reduce #'+ '())                     ; => 0        ← (+) 是 0
(reduce #'- '())                     ; 报错：invalid number of arguments: 0
(reduce #'- '(1 2 3))                ; => -4       ← 1-2-3
(reduce #'- '(1 2 3) :from-end t)    ; => 2        ← 从右往左结合
```

**边界一**：空序列时 `reduce` 调用的是「零参形式」的函数。`(+)` 合法（得 0），
`(-)` 不合法（报错）。所以 `(reduce #'+ '())` 能跑，`(reduce #'- '())` 会炸。

**边界二**：`reduce` 的结合方向。默认左结合：

```lisp
(reduce #'cons '((a) (b) (c)))              ; => (((A) B) C)
(reduce #'cons '((a) (b) (c)) :from-end t)  ; => ((A) (B) C)
```

（这两条实测结果和直觉都不同，值得抄下来备用。）

**边界三**：只有一个元素的序列不会调用函数：

```lisp
(reduce #'- '(1))                    ; => 1        ← 直接返回，不调 -
```

## 8.7 列表 vs 向量：性能直觉

同一件事两种容器的代价不同：

| 操作 | 列表 | 向量 |
|---|---|---|
| `nth n` / `elt n` | **O(n)**，要走链 | **O(1)**，下标寻址 |
| 头部插入 | **O(1)**，改两个指针 | O(n)，要搬 |
| 尾部追加 | O(n) | O(1)（带 fill-pointer）/ O(n)（真实数组） |
| 随机访问密集 | 慢 | 快 |
| 顺序遍历 | 快 | 快 |

所以：**需要下标随机访问就用向量**；需要频繁在头部增删就用列表。
把列表当数组用（循环里 `nth`）是 CL 里最典型的性能事故。

从列表转向量非常简单，别硬扛：

```lisp
(coerce lst 'vector)
```

## 8.8 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| 排序「没生效」 | `sort` 的返回值没接 | 一定接返回值 |
| 排序把原数据改了 | `sort` 是破坏性的 | 先 `copy-list` / `copy-seq` |
| `(delete x lst)` 丢结果后没删 | 删头元素时旧变量失效 | 接返回值或用 `remove` |
| 去重保留了不希望的那一个 | `remove-duplicates` 默认留最后 | 加 `:from-end t` |
| `(reduce #'- '())` 报错 | 空序列要调零参函数 | 给 `:initial-value` |
| `(mapcar #'+ a b)` 结果比预期短 | 多序列取最短长度 | 先确认长度一致 |
| `nth` 在长列表里很慢 | 链式结构 O(n) | 换成向量 + `aref` |

---

# 第 9 章 哈希表与结构体

配套示例：`16-sequences-hash-tables.lisp`。

## 9.1 哈希表：`test` 选错就取不出数据

```lisp
(defvar *ht* (make-hash-table))
(setf (gethash :a *ht*) 1)              ; => 1      setf gethash 就是「put」
(multiple-value-list (gethash :a *ht*))         ; => (1 T)
(multiple-value-list (gethash :missing *ht*))   ; => (NIL NIL)
(gethash :missing *ht* :default)                ; => :DEFAULT
(hash-table-count *ht*)                 ; => 1
```

**`gethash` 返回两个值**：值 + 「存不存在」。这个是必需的，因为「存了 `nil`」
和「没存」必须能区分 —— 用第二个返回值判断，别用 `(if (gethash k h) ...)`。

删除与清空：

```lisp
(remhash :a *ht*)          ; => T      ← 删掉了
(remhash :a *ht*)          ; => NIL    ← 本来就没有
(hash-table-count *ht*)    ; => 0
```

**最大的坑是 `:test` 的默认值 `eql`**：

```lisp
(let ((h (make-hash-table)))                        ; 默认 eql
  (setf (gethash "key" h) 1)
  (list (gethash "key" h) (gethash (copy-seq "key") h)))
; => (NIL NIL)      ← 连原本那个 "key" 都取不回来！
```

原因是两个字面量 `"key"` 是**不同对象**，而 `eql` 比对象身份（第 4 章的表）。
换成 `equal` 就正常：

```lisp
(let ((h (make-hash-table :test 'equal)))
  (setf (gethash "key" h) 1)
  (list (gethash "key" h) (gethash (copy-seq "key") h)))
; => (1 1)
```

四个 `:test` 的适用场景：

| `:test` | 比较方式 | 适合的键 |
|---|---|---|
| `eq` | 对象身份 | **符号、关键字**（最快） |
| `eql` | 身份或同类型同数值（默认） | 符号、整数、字符 |
| `equal` | 结构相同 | **字符串**、列表 |
| `equalp` | 更宽松（大小写不敏感） | 要忽略大小写的字符串 |

**实践规则：键用关键字（`:foo`）配默认的 `eql` 最快；键用字符串必须写
`:test 'equal`。**

## 9.2 遍历顺序是不确定的

```lisp
(let ((h (make-hash-table)) (ks nil))
  (loop for k in '(:c :a :b) do (setf (gethash k h) (length (symbol-name k))))
  (maphash (lambda (k v) (push (cons k v) ks)) h)
  ks)
; 一次运行的结果 => ((:B . 1) (:A . 1) (:C . 1))     ← 顺序每次可能不同
```

**不要依赖遍历顺序。** 需要确定性输出（比如做验证、生成报告）就先排序
（下面这段把哈希表重新建一遍，是为了让它能单独运行）：

```lisp
(let ((h (make-hash-table)))
  (loop for k in '(:c :a :b) do (setf (gethash k h) (length (symbol-name k))))
  (sort (loop for k being the hash-keys of h collect k) #'string<))
; => (:A :B :C)
```

`loop` 直接汇总也可以，它比 `maphash` + 手工累积清楚：

```lisp
(let ((h (make-hash-table)))
  (loop for k in '(:c :a :b) do (setf (gethash k h) (length (symbol-name k))))
  (loop for v being the hash-values of h sum v))
; => 3
```

另外 `equalp` 能按内容比较两个哈希表：

```lisp
(equalp (make-hash-table :test 'equalp) (make-hash-table :test 'equalp))   ; => T
```

## 9.3 结构体：`defstruct`

结构体是「固定几个槽的轻量记录」，一行就能生成构造函数、判定函数和访问器：

```lisp
(defstruct point x y)
(defvar *pt* (make-point :x 1 :y 2))
*pt*                    ; => #S(POINT :X 1 :Y 2)     ← 打印形式固定
(point-x *pt*)          ; => 1                       ← 自动生成访问器
(point-p *pt*)          ; => T                       ← 自动生成判定
(type-of (make-point))  ; => POINT
```

`defstruct` 一次给你四样东西：构造函数 `make-point`、谓词 `point-p`、
访问器 `point-x`/`point-y`（它们都是 `setf`-able 的位置）、打印形式。

支持继承与自定义构造函数：

```lisp
(defstruct (point3 (:include point) (:constructor make-point3 (x y z)))
  z)
(point3-z (make-point3 1 2 3))      ; => 3
(point-x (make-point3 1 2 3))       ; => 1      ← 继承来的槽也在
```

**相等性**：结构体要用 `equalp`（这一点和 CLOS 实例相反，第 11 章对比）：

```lisp
(equal  (make-pt :x 1) (make-pt :x 1))    ; => NIL
(equalp (make-pt :x 1) (make-pt :x 1))    ; => T
```

结构体 vs CLOS 类，怎么选：

| | `defstruct` | `defclass` |
|---|---|---|
| 定位 | 数据记录 | 完整对象系统 |
| 槽访问 | 自动生成访问器 | 要写 `:accessor` / `:reader` |
| 继承 | 单一继承（`:include`） | 多继承 |
| 方法 | 无（可用普通函数） | 泛型函数 + 多分派 |
| 相等 | `equalp` 比内容 | 默认比身份 |
| 开销 | 小 | 略大 |
| 可变性 | 槽可 `setf` | 槽可 `setf` |

**经验法则**：只是「几个字段捆一起传」用 `defstruct`；需要多态、需要多分派、
需要 `:before`/`:after` 钩子才上 `defclass`。

## 9.4 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| 字符串键存进去取不出来 | 默认 `:test 'eql` | `:test 'equal` |
| 存了 `nil` 之后分不清有没有 | 只用了第一个返回值 | 用 `gethash` 的第二个返回值 |
| 程序两次运行输出顺序不同 | 哈希表遍历顺序不确定 | 显式排序 |
| `(equal s1 s2)` 两个结构体是 NIL | `equal` 不比结构体内容 | 用 `equalp` |

---

# 第 10 章 条件系统与重启：CL 最独特的部分

配套示例：`08-conditions.lisp`。

其它语言的异常是「跳出去」，CL 的条件系统是「**发通知、然后由外层的处理器决定怎么办**」。
多出来的那一层（restart）让「出错后还能接着修」成为可能 —— 这是 CL 交互式开发体验的核心。

## 10.1 三档：`signal` < `warn` < `error`

```lisp
(error "出问题了")       ; 一路向上，没人接就进调试器
(warn "注意一下")        ; 打印一条 WARNING，然后**继续执行**，返回 NIL
(signal 'some-condition) ; 通知一下，没人管就返回 NIL
```

实测：

```lisp
(handler-case (progn (warn "注意一下") :continued) (error (e) :should-not-happen))
; => :CONTINUED
```

`warn` 的内容走 **stderr**（第 0 章说过，这会影响示例的「stderr 为空」判定）：

```lisp
(let ((*error-output* *standard-output*))
  (warn "这行 WARNING 是写到 stderr 的（此处临时改道）"))
```

想静音所有警告，把 `*error-output*` 接到一个丢弃流上：

```lisp
(let ((*error-output* (make-broadcast-stream))) (warn "静音掉"))
```

`signal` 的语义有个**容易忽视的分支**：如果条件类型是 `error` 的子类，
`signal` 的行为**和 `error` 一样**（会进调试器）。实测对照：

```lisp
;; 只继承 condition 的类：signal 就是「通知」
(define-condition note (condition) ((text :initarg :text :reader note-text)))
(signal 'note :text "只是通知")                ; => NIL      ← 没人管，安静返回

;; 继承 error 的类：signal 会炸
(define-condition boom (error) ((text :initarg :text :reader boom-text)))
(signal 'boom :text "我其实是个 error")        ; 进调试器／报错
```

所以「自定义条件想当错误用就继承 `error`，只想通知就继承 `condition`」。

## 10.2 自定义条件：带上数据，并写好报告

条件就是**类实例**，可以带槽，可以定义打印形式：

```lisp
(define-condition insufficient-funds (error)
  ((balance :initarg :balance :reader insufficient-funds-balance)
   (amount  :initarg :amount  :reader insufficient-funds-amount))
  (:report (lambda (c stream)
             (format stream "余额 ~A 不足，需要 ~A"
                     (insufficient-funds-balance c)
                     (insufficient-funds-amount c)))))

(handler-case (error 'insufficient-funds :balance 10 :amount 99)
  (error (e) (format nil "~A" e)))
; => "余额 10 不足，需要 99"
```

类型层次自动搭好（实测）：

```lisp
(handler-case (error 'insufficient-funds :balance 1 :amount 2)
  (insufficient-funds (e) (list (typep e 'insufficient-funds)
                                (typep e 'error)
                                (typep e 'condition)
                                (typep e 'serious-condition))))
; => (T T T T)
```

所以你既可以用最具体的类型接，也可以用 `error` 一把接住。

判断错误带的数据用访问器，不要解析消息字符串：

```lisp
(handler-case (/ 1 0) (error (e) (list (type-of e) (format nil "~A" e))))
; => (DIVISION-BY-ZERO "arithmetic error DIVISION-BY-ZERO signalled
;                        Operation was (/ 1 0).")

(handler-case (car 5)
  (type-error (e) (list (type-error-datum e) (type-error-expected-type e))))
; => (5 LIST)         ← 非法值 5、期望类型 LIST
```

`type-error` 有标准访问器 `type-error-datum` 和 `type-error-expected-type`，
比读字符串可靠得多。

**一个容易误判的点**：SBCL 的数组越界报错，具体类型是实现专有的
`SB-INT:INVALID-ARRAY-INDEX-ERROR`，但它**仍然属于 `type-error`**，所以能接住：

```lisp
(handler-case (aref #(1 2) 9)
  (type-error (e) (list :caught-as-type-error (type-of e))))
; => (:CAUGHT-AS-TYPE-ERROR SB-INT:INVALID-ARRAY-INDEX-ERROR)
```

想写可移植代码，捕 `type-error`（或更宽的 `error`），别捕 `SB-INT:` 开头的类。

## 10.3 `handler-case` 与 `handler-bind`：一个展开栈，一个不展开

这是条件系统里最重要的一个区别。

**`handler-case`** 是「捕获并放弃现场」：它先**展开栈**（unwind）到自己的位置，
再执行处理代码。所以处理代码里看不到出错时的调用栈。

**`handler-bind`** 是「就地介入」：处理函数在**出错的那个栈帧上**运行，
栈还没展开。因此它能看到现场，也能**调用 restart** 让程序继续跑。

实测对比：

```lisp
;; handler-case：展开后处理
(handler-case (error "boom") (error (e) :unwound))       ; => :UNWOUND

;; handler-bind：在出错现场处理
(block done
  (handler-bind ((error (lambda (e)
                          (format t "  在报错的现场做点事~%")
                          (return-from done :handled-in-place))))
    (error "x")))
; => :HANDLED-IN-PLACE
```

**一个关键细节**：`handler-bind` 的处理函数正常返回，**不会阻止错误继续传播**：

```lisp
(handler-bind ((boom (lambda (e) :我把返回值当处理了)))
  (signal 'boom :text "我其实是个 error"))
; 仍然报错
```

处理函数必须**转走控制流**（`invoke-restart` / `throw` / `return-from`），
错误才算被处理。这一点和「try/catch 里 return 就没事了」的直觉相反。

调试时的实用组合：用 `handler-bind` **记录**（保住现场），再用 `handler-case` 接住：

```lisp
(let (seen)
  (handler-case
      (handler-bind ((error (lambda (e) (push (type-of e) seen))))
        (deep 3))
    (error (e) (list :seen (reverse seen)))))
; => (:SEEN (SIMPLE-ERROR))
```

## 10.4 restart：报错之后还能接着干

restart 是「出错时提供的**可选出路**」。定义：

```lisp
(defun fetch (fail)
  (restart-case
      (if fail (error "取数失败") :data)
    (use-cache ()
      :report "改用缓存的旧数据"
      :from-cache)
    (skip ()
      :report "跳过这一项"
      nil)))
```

没有外层干预时，`restart-case` **完全不改变行为**：

```lisp
(fetch nil)      ; => :DATA
```

外层的处理器可以「挑一条出路」并调用它，于是程序**从 `restart-case` 的位置继续**：

```lisp
(handler-bind ((error (lambda (e)
                        (let ((r (find-restart 'use-cache)))
                          (when r (invoke-restart r))))))
  (fetch t))
; => :FROM-CACHE
```

换成挑 `skip` 就得到 `nil`。`:report` 是给交互式调试器显示的说明文字 ——
在 REPL 里报错时，SBCL 会把这些 restart 列出来，你敲数字就能选一条：

```
restarts (invokable by number or by possibly-abbreviated name):
  0: [USE-CACHE] 改用缓存的旧数据
  1: [SKIP] 跳过这一项
```

`with-simple-restart` 是「只提供一个 exit」的简写：

```lisp
(with-simple-restart (abort "放弃") (error "x"))
```

`cerror` 则同时做两件事：报一个可继续的错误 + 提供 `continue` restart：

```lisp
;; 没人管 → 报错
(cerror "继续好了" "出错了但能继续")

;; 有人 invoke continue → 从这里继续往下跑
(handler-bind ((simple-error (lambda (e) (invoke-restart 'continue))))
  (cerror "继续好了" "出错了但能继续"))
; => NIL
```

标准库到处在用这个模式：`parse-integer` 遇到坏字符、`read` 遇到未知语法、
编译器遇到警告，都会提供 restart，让你在 REPL 里「修一下接着跑」。

## 10.5 `assert` 与 `check-type`

写测试和前置条件用它们俩，比手写 `(if (not ...) (error ...))` 信息量更大：

```lisp
(assert (> 3 2))          ; => NIL        ← 通过时返回 NIL
(assert (> 2 3))
; 报错：The assertion (> 2 3) failed.

(let ((x "s")) (check-type x integer) x)
; 报错：The value of X is "s", which is not of type INTEGER.
(let ((x 5)) (check-type x integer) x)    ; => 5
```

给 `assert` 加自定义消息的语法要小心（**消息里的占位符要靠额外的实参来填**）：

```lisp
(let ((x 3))
  (assert (> 2 x) (x) "自定义消息：x=~A" x))
; 报错：自定义消息：x=3
```

`(x)` 那段是「可以重新绑定的变量列表」，让调试器可以修好值重试；后面的实参
按顺序供 `~A` 取用。写错参数数量会得到 `The variable X is unbound.` 这种
让人摸不着头脑的报错。

三个都是 `restart-case` 的包装：在 REPL 里报错时你可以「改一个值再重试」。

## 10.6 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| 示例「stderr 非空」判定失败 | `warn` 写 stderr | 临时绑 `*error-output*` |
| `handler-bind` 里处理器返回了但错误还炸 | 正常返回不算处理 | 用 `invoke-restart` / `throw` 转走控制流 |
| `handler-case` 里想再抛原始错误却拿不到 | 栈已展开 | 用 `handler-bind` 或保存条件对象 |
| 自定义条件 `~A` 打印出 `#<...>` | 没写 `:report` | 加 `:report` 函数 |
| 捕不到某个错误 | 捕的类太具体，或者是实现专有类 | 捕 `type-error` / `error` 这类标准父类 |
| `(signal 'my-error)` 突然进调试器 | `my-error` 继承自 `error` | 只通知就继承 `condition` |

---

# 第 11 章 CLOS：类、方法、多分派

配套示例：`06-clos.lisp`。

CLOS（Common Lisp Object System）和主流 OOP 有两处根本区别，先记住它们：

1. **方法不属于类**，而是属于**泛型函数**（generic function）。方法是独立的定义，
   按参数类型「挂」到泛型函数上。
2. **方法可以按多个参数分派**（multiple dispatch），不只是第一个参数。

## 11.1 类与槽

```lisp
(defclass account ()
  ((owner   :initarg :owner   :accessor account-owner)
   (balance :initarg :balance :initform 0 :accessor account-balance)
   (history :initform nil     :accessor account-history)))

(defvar *a* (make-instance 'account :owner "Alice" :balance 100))
(account-owner *a*)          ; => "Alice"
(account-balance *a*)        ; => 100
(slot-value *a* 'balance)    ; => 100      ← 通用入口，慢但万能
(setf (slot-value *a* 'balance) 250)
(account-balance *a*)        ; => 250
```

槽选项速查：

| 选项 | 作用 |
|---|---|
| `:initarg :x` | 允许 `(make-instance 'c :x 1)` 传值 |
| `:initform v` | 没传时的初值（默认值） |
| `:accessor x` | 生成读+写函数（`setf`-able） |
| `:reader x` | 只生成读函数 |
| `:writer x` | 只生成写函数 |
| `:type t` | 声明槽类型（供优化） |
| `:documentation "..."` | 槽的文档 |

类型与类的关系：

```lisp
(type-of *a*)                         ; => ACCOUNT
(class-name (class-of *a*))           ; => ACCOUNT
(typep *a* 'account)                  ; => T
(typep *a* 'standard-object)          ; => T      ← 所有 CLOS 实例的祖先
```

`(class-of obj)` 返回**类对象**本身，想要名字用 `class-name`。

槽可以「未绑定」—— 这是 CLOS 独有的状态：

```lisp
(defclass sparse () ((x :initarg :x) (y :initarg :y)))
(defvar *s* (make-instance 'sparse :x 1))
(slot-boundp *s* 'x)          ; => T
(slot-boundp *s* 'y)          ; => NIL
(slot-value *s* 'y)           ; 报错：The slot COMMON-LISP-USER::Y is unbound in the object ...
(slot-exists-p *s* 'nope)     ; => NIL       ← 判断槽「定义」是否存在
```

「未绑定」不等于「值是 nil」。要判断某个槽有没有值用 `slot-boundp`。

想批量访问槽，用 `with-slots`（直接按名字用）或 `with-accessors`（走访问器）：

```lisp
(with-slots (balance) *a* (* balance 2))                  ; => 500
(with-accessors ((b account-balance)) *a* b)              ; => 250
```

## 11.2 `:initform` 与 `:default-initargs`

两者都能给默认值，但优先级和作用范围不同：

```lisp
(defclass config ()
  ((debug :initarg :debug :initform nil :accessor config-debug)
   (level :initarg :level :initform 1   :accessor config-level))
  (:default-initargs :level 5))

(config-level (make-instance 'config))          ; => 5     ← default-initargs 赢过 initform
(config-level (make-instance 'config :level 9)) ; => 9     ← 显式传值最优先
```

优先级：**显式参数 > `:default-initargs` > `:initform`**。

传了未知关键字会报错（帮你抓拼写错误）：

```lisp
(make-instance 'config :nope 1)
; 报错：Invalid initialization argument: :NOPE in call for class #<STANDARD-CLASS ...CONFIG>.
```

## 11.3 泛型函数与多分派

方法定义在**泛型函数**上，可以按任意参数的类型分派：

```lisp
(defgeneric combine (a b))
(defmethod combine ((a integer) (b integer)) :int-int)
(defmethod combine ((a integer) (b string))  :int-str)
(defmethod combine ((a string)  (b string))  :str-str)

(combine 1 2)      ; => :INT-INT
(combine 1 "s")    ; => :INT-STR
(combine "a" "b")  ; => :STR-STR
(combine 1 2.0)
; 报错：There is no applicable method for the generic function ... when called with arguments (1 2.0).
```

还能按**具体值**分派（`eql` 特化器），常用来处理「枚举」：

```lisp
(defmethod combine ((a (eql :x)) (b integer)) :eql-specializer)
(combine :x 1)     ; => :EQL-SPECIALIZER
(combine :y 1)     ; 没有适用方法
```

单继承加覆盖是最常见的用法：

```lisp
(defclass animal () ((name :initarg :name :reader animal-name)))
(defclass dog (animal) ((breed :initarg :breed :reader dog-breed)))

(defmethod speak ((a animal)) (format nil "~A 发出声音" (animal-name a)))
(defmethod speak ((d dog)) "汪汪")

(speak (make-instance 'animal :name "?"))   ; => "? 发出声音"
(speak (make-instance 'dog :name "旺"))      ; => "汪汪"
(subtypep 'dog 'animal)                      ; => T
```

## 11.4 方法组合：`before` / `after` / `around` 的执行顺序

这组顺序**必须实测一遍才记得住**。下面的类层次是 `number` → `integer`：

```lisp
(defgeneric process (x))
(defmethod process ((x integer)) (format t "  主方法（最具体）~%") :main)
(defmethod process :before ((x integer)) (format t "  before 整数~%"))
(defmethod process :after  ((x integer)) (format t "  after 整数~%"))
(defmethod process :before ((x number))  (format t "  before 数字（较泛）~%"))
(defmethod process :after  ((x number))  (format t "  after 数字（较泛）~%"))
```

`(process 1)` 的实际输出：

```
  before 整数
  before 数字（较泛）
  主方法（最具体）
  after 数字（较泛）
  after 整数
```

规律：**`before` 从最具体到最泛，`after` 从最泛到最具体**（镜像的），
主方法只执行最具体的那一个。记法：`before` 像「构造函数的调用链」（从具体到祖先），
`after` 像「析构/清理」（从祖先到具体）。

`:around` 包在最外层，并**可以决定要不要继续**：

```lisp
(defmethod process :around ((x integer))
  (format t "  around-进入~%")
  (let ((r (call-next-method)))
    (format t "  around-退出 next-method-p=~A~%" (next-method-p))
    (list :wrapped r)))
```

再调 `(process 1)`：

```
  around-进入
  before 整数
  before 数字（较泛）
  主方法（最具体）
  after 数字（较泛）
  after 整数
  around-退出 next-method-p=T
=> (:WRAPPED :MAIN)
```

- `call-next-method` 调用「下一个更泛的方法」，它的**返回值就是被包裹方法的返回值**；
- `next-method-p` 判断还有没有下一个（上例里是 `T`）；
- **不调 `call-next-method` 就等于「拦下这次调用」** —— 拦截、缓存、加锁都是这么做的。

`before` / `after` 方法的返回值**会被丢弃**，它们只用来做副作用（日志、校验、缓存失效）。

## 11.5 实例化的钩子

`make-instance` 的流程里有标准协议函数可以插队：

```lisp
(defclass traced () ((v :initarg :v :accessor traced-v)))

(defmethod initialize-instance :after ((o traced) &key)
  (format t "  initialize-instance :after 被调用，v=~A~%" (slot-value o 'v)))

(defmethod shared-initialize :after ((o traced) slots &key)
  (declare (ignore slots))
  (format t "  shared-initialize :after~%"))

(traced-v (make-instance 'traced :v 7))     ; => 7
```

实测的顺序是 `shared-initialize :after` 先于 `initialize-instance :after`。
**要做校验 / 补默认值，用 `initialize-instance :after`** —— 这是最常用的钩子。

## 11.6 打印对象

默认打印出来是一串看不懂的东西：

```lisp
(make-instance 'traced :v 1)     ; => #<TRACED {…}>              ← 大括号里是内存地址，每次运行都不同
```

自定义 `print-object` 之后：

```lisp
(defmethod print-object ((o traced) stream)
  (print-unreadable-object (o stream :type t)
    (format stream "v=~A" (slot-value o 'v))))
(make-instance 'traced :v 1)     ; => #<TRACED v=1>
```

`print-unreadable-object` 负责加上 `#<>` 和类型名，你只管写内容。
它**同时影响 `~S` 和 `princ-to-string`**：

```lisp
(princ-to-string (make-instance 'traced :v 2))     ; => "#<TRACED v=2>"
```

写自定义打印时注意：**别打印每次都变的东西**（地址、时间戳），否则测试没法比对输出。

## 11.7 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| `slot-value` 报 unbound | 该槽没有初值也没传参 | 用 `slot-boundp` 先判断，或加 `:initform` |
| `:before` 方法的返回值被丢了 | 组合方法只取主方法的返回值 | 副作用写在 before/after，值写在主方法 |
| 方法「不生效」 | 参数类型没匹配（如传了 `1.0` 而方法只认 `integer`） | 用 `describe` / `methods` 查适用的方法 |
| `equal` 两个实例是 NIL | CLOS 实例默认比身份 | 自定义 `equal` 或改用结构体 + `equalp` |
| 打印输出里有地址导致测试不稳定 | 默认打印含地址 | 自定义 `print-object` |

---

# 第 12 章 包：名字的空间

配套示例：`07-packages.lisp`。

## 12.1 包是什么

包是**符号名到符号的映射表**（符号表）。同一时刻有一个「当前包」`*package*`：

```lisp
(package-name *package*)          ; => "COMMON-LISP-USER"
(find-package :cl)                ; => #<PACKAGE "COMMON-LISP">
(find-package :没有这个包)         ; => NIL
(package-nicknames (find-package :cl))       ; => ("CL")
(length (package-use-list :cl-user))         ; => 6
(length (loop for s being the external-symbols of :cl collect s))   ; => 978
```

`COMMON-LISP` 包里对外公开了 978 个符号 —— 这基本就是标准库的规模。

查找符号用 `find-symbol`，它返回**两个值**：符号 + 状态：

```lisp
(multiple-value-list (find-symbol "CAR" :cl))     ; => (CAR :EXTERNAL)
(multiple-value-list (find-symbol "NOPE" :cl))     ; => (NIL NIL)
```

状态有四种：`:internal`（本包私有）、`:external`（本包导出）、
`:inherited`（从别的包继承来）、`NIL`（不存在）。

`(symbol-package 'car)` → `COMMON-LISP`，而 `(symbol-package 'foo)` →
`COMMON-LISP-USER`。**符号的名字只有在「哪个包」确定之后才有意义** ——
这就是 `A::B` 记法的由来。

## 12.2 单冒号与双冒号

| 记法 | 含义 | 用法 |
|---|---|---|
| `pkg:sym` | **导出的**符号 | 正常用法 |
| `pkg::sym` | **内部**符号 | 应急，不推荐 |
| `pkg:` （不写符号） | 只用 `pkg` 做包前缀 | — |

双冒号能打通一切，但它是「我在用你的私有实现」的信号，升级时会崩。

## 12.3 定义自己的包

```lisp
(defpackage :shop
  (:use :cl)
  (:nicknames :shop-pkg)
  (:export #:item #:item-name #:make-item))

(in-package :shop)
(defstruct item name price)
(defun item-label (it) (format nil "~A（~A 元）" (item-name it) (item-price it)))
(export 'item-label)
```

`defpackage` 的常用选项：

| 选项 | 作用 |
|---|---|
| `:use :cl` | 继承标准库的所有外部符号 |
| `:export #:a` | 导出符号（用 `#:` 写，避免把符号先 intern 到当前包） |
| `:nicknames` | 别名 |
| `:shadow` | 屏蔽继承来的同名符号 |
| `:import-from` | 从别的包引入特定符号 |
| `:use` 别的包 | 把整个包继承进来 |

用起来（`in-package :cl-user` 之后）：

```lisp
(shop:item-label (shop:make-item :name "书" :price 30))    ; => "书（30 元）"
(shop-pkg:make-item)                       ; => #S(SHOP:ITEM :NAME NIL :PRICE NIL)
```

没导出的符号单冒号拿不到：

```lisp
(find-symbol "ITEM-PRICE" :shop)     ; => SHOP::ITEM-PRICE（状态 :INTERNAL，不是 :EXTERNAL）
```

注意 `find-symbol` 照样**找得到**它（它返回了符号），只是它不是 `:external`，
所以不能写 `shop:item-price`。双冒号可以：

```lisp
(shop::item-price (shop:make-item :price 5))     ; => 5
```

**在导出符号时用 `#:item` 而不是 `:item`**：`:item` 会被当作关键字先 intern 到
`KEYWORD` 包，虽然不影响功能，但这是不严谨的写法。

## 12.4 包锁：CL 的符号不许乱改

```lisp
(defun car (x) x)
```

```
WARNING: redefining COMMON-LISP:CAR in DEFUN
...
Lock on package COMMON-LISP violated when setting fdefinition of CAR
while in package COMMON-LISP-USER.
See also:
  The SBCL Manual, Node "Package Locks"
  The ANSI Standard, Section 11.1.2.1.2
```

**这是好事**：包锁防止你把 `car` 改成别的东西，然后整个程序行为诡异。
它是「可继续的错误」（有 restart），在 REPL 里可以强行绕过，但**不要这么做**。

自己的包不受锁保护（除非加 `:lock`）。另外**同名不同包完全合法** ——
自己定义 `mypkg:car` 是没问题的。

## 12.5 `shadow`：屏蔽继承来的名字

`COMMON-LISP-USER` 默认 `:use :cl`，所以 `list` 这个名字是继承来的，
不能直接重定义（会违反包锁）。想用自己的 `list` 就在包里 `shadow` 掉：

```lisp
(defpackage :demo-shadow
  (:use :cl)
  (:shadow :list))

(let ((*package* (find-package :demo-shadow)))
  (find-symbol "LIST" :demo-shadow))
; => DEMO-SHADOW::LIST，包是 DEMO-SHADOW（不再是 COMMON-LISP）
```

`shadow` 之后，这个包里的 `list` 指向**新符号**，与 `CL:LIST` 无关。
这是「我要一个同名但语义不同的东西」的标准做法。

顺带一个诊断工具 —— `apropos` 按关键词找符号：

```lisp
(subseq (apropos-list "hash-table" :cl) 0 3)
; => (HASH-TABLE HASH-TABLE-COUNT HASH-TABLE-P)
```

忘了函数名时非常有用。**注意返回顺序由实现决定**（这里是 SBCL 的顺序），
别写代码去依赖它。

## 12.6 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| `Package FOO does not exist.` | 写了 `foo:bar` 但 `FOO` 包不存在 | 先 `defpackage` / `require` |
| 重定义 `car` 报包锁错误 | `COMMON-LISP` 被锁 | 换个名字，或在自己包里 `shadow` |
| `(intern "foo")` 与 `'foo` 不相等 | 读入器转大写 | `(intern (string-upcase s))` |
| 用了 `pkg::sym` 之后另一台机器上崩 | 依赖了别人的内部符号 | 用导出符号，或加 `:export` |
| `export` 写在定义之前就没生效 | 顺序问题 | 先 `defpackage`，定义完再 `export` |

---

# 第 13 章 宏：让语言长出你要的语法

配套示例：`05-macros.lisp`。

宏是 CL 区别于「函数式语言 + 语法糖」的关键。核心事实只有一条：

> **宏在「展开期」运行，收到的是未求值的代码；函数在「运行期」运行，收到的是值。**

## 13.1 先把这条事实实测一遍

```lisp
(defmacro noisy (form)
  (format t "  [宏展开时] 我看到的实参是 ~S~%" form)
  `(list :运行时求值 ,form))

(defun noisy-fn (form)
  (format t "  [函数调用时] 我收到的实参是 ~S~%" form)
  (list :运行时求值 form))
```

调用两者，输出完全不同：

```
调用 (noisy (+ 1 2))：
  [宏展开时] 我看到的实参是 (+ 1 2)
(noisy (+ 1 2)) => (:运行时求值 3)

对照：函数 (noisy-fn (+ 1 2))：
  [函数调用时] 我收到的实参是 3
(noisy-fn (+ 1 2)) => (:运行时求值 3)
```

**宏看到 `(+ 1 2)` 这个表达式，函数看到 `3` 这个值。** 所以宏能做函数做不到的事：
定义新语法、控制求值次数、避免不必要的计算。

## 13.2 `macroexpand`：把宏看穿

调试宏的第一工具：

```lisp
(defmacro my-unless (test &body body) `(if (not ,test) (progn ,@body)))

(macroexpand-1 '(my-unless (> 1 2) :a :b))     ; => (IF (NOT (> 1 2)) (PROGN :A :B))
(macroexpand '(car x))                          ; => (CAR X)      ← 不是宏就原样返回
```

`macroexpand-1` 只展开一层，`macroexpand` 一直展到「不再是宏」：

```lisp
(defmacro outer-m (x) `(my-unless nil ,x))
(macroexpand-1 '(outer-m :z))     ; => (MY-UNLESS NIL :Z)      ← 还有一层
(macroexpand   '(outer-m :z))     ; => (IF (NOT NIL) (PROGN :Z))
```

> **排版说明**：上面两行的展开结果是**真实输出**，只是为了排版压成了一行。
> REPL 里 `*print-pretty*` 默认是 `T`，这类结构会被折成多行
> （`(MY-UNLESS NIL` 换行 `  :Z)`）。要看单行结果就把 `*print-pretty*` 绑成 `nil` ——
> 但那会连带改变别的打印形式，见 14.6 节。

判断一个名字是不是宏：

```lisp
(macro-function 'my-unless)     ; => #<FUNCTION (MACRO-FUNCTION MY-UNLESS) {…}>（非 NIL）
(macro-function 'car)           ; => NIL
```

## 13.3 反引号（backquote）

写宏 90% 的代码用反引号模板：

```lisp
`(1 2 3)          ; 就是 (1 2 3)
`(1 ,x 3)         ; 把 x 的值插进去
`(1 ,@lst 3)      ; 把列表 lst 的元素摊平插进去
```

| 记法 | 名字 | 作用 |
|---|---|---|
| `` ` `` | backquote | 模板，里面的东西默认当数据 |
| `,` | comma | 求值后插进去 |
| `,@` | comma-at | 求值后摊平（必须是列表） |

`(let ((x 2)) `(1 ,x 3))` → `(1 2 3)`；`(let ((lst '(a b))) `(1 ,@lst 3))` → `(1 A B 3)`。
**注意 `,` 求值发生在宏展开期**，所以它插进去的是「运行期会求值的代码」还是
「运行期的值」，取决于你在哪一层写。

## 13.4 变量捕获：写宏最容易犯的错

反面教材：

```lisp
(defmacro bad-swap (a b)
  `(let ((tmp ,a))
     (setf ,a ,b)
     (setf ,b tmp)))
```

展开后立刻能看出问题：

```lisp
(macroexpand-1 '(bad-swap tmp x))
; => (LET ((TMP TMP))     ← 用户传进来的变量就叫 tmp，被这里绑死了！
;      (SETF TMP X)
;      (SETF X TMP))
```

结果就是错的：

```lisp
(let ((tmp 1) (x 2)) (bad-swap tmp x) (list tmp x))
; => (1 2)      ← 期望 (2 1)
```

修法是用 `gensym` 生成一个**保证不会撞名**的符号：

```lisp
(defmacro good-swap (a b)
  (let ((tmp (gensym "TMP")))        ; 关键：在宏体里一次算出来，再插进去
    `(let ((,tmp ,a))
       (setf ,a ,b)
       (setf ,b ,tmp))))

(let ((tmp 1) (x 2)) (good-swap tmp x) (list tmp x))     ; => (2 1)
```

展开结果是 `(LET ((#:TMP255 TMP)) ...)` —— `#:TMP255` 是**无归属符号**，
用户代码里永远不会出现同名的它。

三个相关事实：

```lisp
(gensym)               ; => #:G264          ← 编号每次运行都不同
(gensym "TMP")         ; => #:TMP269
(symbol-package (gensym))     ; => NIL
```

**注意**：宏体里 `(gensym)` 只能调一次并存进变量 —— 每次调用都给新符号，
写两次会得到两个不同的符号，宏就错了。

## 13.5 宏的形参是「代码的形状」

宏的形参列表可以解构，这让宏特别好用：

```lisp
(defmacro two-forms (&rest forms)
  `(list :count ,(length forms) :forms ',forms))
(macroexpand-1 '(two-forms a b c))
; => (LIST :COUNT 3 :FORMS '(A B C))     ← 形参数量在**展开期**就算出来了

(defmacro destructure-demo ((a b &key c) &body body)
  `(list :a ,a :b ,b :c ,c :body ',body))
(destructure-demo (1 2 :c 3) :x :y)
; => (:A 1 :B 2 :C 3 :BODY (:X :Y))

(defmacro whole-demo (&whole w a) `(list :whole ',w :a ,a))
(whole-demo 42)         ; => (:WHOLE (WHOLE-DEMO 42) :A 42)
```

`&whole` 拿到「整个调用形式」（包括宏名），`&body` 和 `&rest` 功能相同
（`&body` 只是给编辑器更好的缩进提示）。

`&environment` 能拿到**编译环境**，配合 `constantp` 做编译期判断：

```lisp
(defmacro env-demo (x &environment env)
  (list 'quote (list :constant (and (constantp x env) t)
                     :expanded (macroexpand-1 x env))))
(env-demo 42)           ; => (:CONSTANT T :EXPANDED 42)
(env-demo (+ 1 2))      ; => (:CONSTANT T :EXPANDED (+ 1 2))
```

第二行值得注意：**`constantp` 对 `(+ 1 2)` 也返回 T** —— 它判断的是
「这个形式是不是编译期常量形式」（会被常量折叠），不是「是不是字面量」。

## 13.6 宏不能当函数用

```lisp
(apply #'my-unless '(nil :x))
```

```
Execution of a form compiled with errors.
Form:
  #'MY-UNLESS
Compile-time error:
  The macro MY-UNLESS was found as the argument to FUNCTION.
```

**编译期**就报错，不会等到运行期。`funcall` / `mapcar` / `apply` 也一样不行。
所以宏**不能**当高阶函数的参数 —— 这是宏的代价：它们是语法，不是值。

需要「能传的语法」时，用 `macrolet` 定义**局部宏**（作用域仅限于当前 `macrolet` 体）：

```lisp
(macrolet ((m (x) `(* ,x 2))) (m 3))     ; => 6
```

## 13.7 一个实用的宏

```lisp
(defmacro with-timing (&body body)
  `(let ((start (get-internal-real-time)))
     (prog1 (progn ,@body)
       (format t "  用时 ~,3F 秒~%"
               (/ (- (get-internal-real-time) start)
                  internal-time-units-per-second)))))

(with-timing (+ 1 2))     ; => 3（并打印：用时 0.000 秒）
```

看 `prog1` 的用法：**执行 `body`、保存其返回值、再打印时间、最后返回保存的值**。
这是「加副作用但不改变返回值」的标准写法（第 7 章讲过 `prog1`）。

## 13.8 `symbol-macrolet` 与 `eval-when`

`symbol-macrolet` 让一个**名字**在词法范围内等价于另一个表达式：

```lisp
(symbol-macrolet ((x 42)) (+ x 1))          ; => 43
```

但它替换的是「名字的位置」，所以不能赋值：

```lisp
(symbol-macrolet ((x 42)) (setf x 1) x)
; 报错：Variable name is not a symbol: 42.
```

`eval-when` 控制一段代码在**编译期 / 加载期 / 执行期**的哪几个阶段运行：

```lisp
(eval-when (:compile-toplevel) :only-at-compile)
; 用 --load 加载源文件时 => NIL（因为根本没走「编译」这个阶段）
```

`--load` 一个 `.lisp` 文件时，SBCL 会逐个形式编译并求值，
`:compile-toplevel` 语义下的代码不会以那种方式执行。
真正需要「编译期求值」的场合（比如定义宏需要的辅助函数），用 `:compile-toplevel`；
需要「编译器和加载器都要」用 `(:compile-toplevel :load-toplevel :execute)`。

## 13.9 什么时候**不要**写宏

宏的代价是「读代码的人必须知道展开成什么」。所以：

- **能用函数就用函数。** 判断标准：如果参数的求值次数和时机无所谓，那它就是函数；
- 需要「不执行参数」（`when` / `unless`）、需要「参数执行多次或一次都不执行」、
  需要「新语法」时才用宏；
- 写宏时**一定要实测 `macroexpand-1`** —— 展开结果比宏本身好懂。

## 13.10 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| 宏展开后变量名撞车 | 用了固定的临时变量名 | `(gensym)` 生成 |
| `gensym` 生成了两个不同符号 | 在宏体里调了两次 | 一次生成、存进 `let` 变量 |
| `(apply #'my-macro ...)` 编译报错 | 宏不是函数 | 把逻辑挪进函数，宏只做包装 |
| 宏里的 `eval-when` 没按预期执行 | `--load` 不触发 `:compile-toplevel` | 用 `:load-toplevel` 或改流程 |
| 展开结果里出现 `#:G123` | 正常现象（gensym） | 不必修，它在每次运行都不同 |

---

# 第 14 章 `format`：CL 的 printf，但更强也更危险

配套示例：`10-format.lisp`。

`format` 的第一个参数决定输出到哪：`t` 是标准输出、`nil` 是「返回字符串」、
也可以是任意流：

```lisp
(format nil "~A" 1)              ; => "1"
(type-of (format nil "~A" 1))    ; => (SIMPLE-BASE-STRING 1)
(format t "")                    ; => NIL     ← 输出到流时返回 NIL
```

**`(format nil ...)` 是 CL 里拼字符串的标准做法**，比 `concatenate` 好用得多。

## 14.1 `~A` 与 `~S`

| 指令 | 行为 | 例子 |
|---|---|---|
| `~A` | 给人看（princ 风格，字符串不带引号） | `"abc"` → `abc` |
| `~S` | 给读入器看（prin1 风格，带引号会转义） | `"abc"` → `"abc"` |

```lisp
(format t "~S / ~A~%" "字符串" "字符串")     ; "字符串" / 字符串
(format t "~S / ~A~%" #\a #\a)               ; #\a / a
(format t "~S / ~A~%" '(1 "two" #\3) '(1 "two" #\3))
; (1 "two" #\3) / (1 two 3)
```

**日志和错误消息用 `~S`** —— `~A` 会把 `nil`、`""`、`0` 打成容易混淆的样子。

## 14.2 数字

```lisp
(format t "~D ~B ~O ~X~%" 255 255 255 255)     ; 255 11111111 377 FF
(format t "~R / ~:R / ~@R~%" 4 4 4)            ; four / fourth / IV
(format t "~F / ~E / ~G~%" 3.14159 3.14159 3.14159)
; 3.14159 / 3.14159e+0 / 3.14159
(format t "定点两位：~,2F~%" 3.14159)            ; 3.14
(format t "科学计数三位：~,3E~%" 1234567.0)      ; 1.235e+6
(format t "宽度 10 补零：~10,'0D|~%" 42)        ; 0000000042|
(format t "~:D 带千分位：~:D~%" 1234567)         ; 1,234,567
(format t "负数补零：~10,'0D|~%" -42)           ; 0000000-42|
```

**两条实测出来的事实**：

1. **`~R` 只接受整数**。`(format nil "~R" 1/2)` 会报错
   （`Value of SB-FORMAT::FORMAT-ARG1 ... is 1/2, not a INTEGER.`）——
   别拿它打印有理数。
2. **`~D` 不受 `*print-base*` 影响**（`(let ((*print-base* 16)) (format nil "~D" 255))`
   在 SBCL 上仍然得到 `"255"`）。要别的进制显式用 `~B` / `~O` / `~X` 或 `~VR`。

宽度与填充的参数顺序记不住没关系，看效果：

```lisp
(format t "~~A 右补空格、~~D 左补空格：~10A|~10D|~%" 42 42)
; 42        |        42|
```

**`~A` 是左对齐（补在右边），`~D` 是右对齐（补在左边）** —— 正好相反，
排版数字和文字时靠这条。

## 14.3 大小写与字符

```lisp
(format t "原样：~A / 小写：~(~A~) / 大写：~:@(~A~)~%" "hEllo" "hEllo" "hEllo")
; 原样：hEllo / 小写：hello / 大写：HELLO
(format t "~C / ~:C / ~@C~%" #\a #\a #\a)     ; a / a / #\a
(format t "1 item~P / 3 item~P~%" 1 3)         ; 1 item / 3 items
```

`~(...~)` 转换大小写，`:@` 组合表示「首字母大写 + 其余小写」。
`~P` 按前一个参数决定单复数（英语语法糖）。

## 14.4 换行、制表，以及一个**经常被写错**的指令

```lisp
(format t "~% 是换行；~& 是「不在行首才换行」~%")
```

- `~%` 无条件换行；
- `~&` 只在「当前不在行首」时换行 —— 用它避免出现空行。

**`~|` 不是表格竖线，它是「换页」指令**（page），会往输出里塞一个
`#\Page`（字节 `0x0C`）：

```lisp
(let ((s (format nil "a~|b")))
  (format t "~S 长度 ~D，中间那个字节的码 = ~D~%" s (length s) (char-code (char s 1))))
```

```
"ab" 长度 3，中间那个字节的码 = 12
```

（`~S` 打印 `#\Page` 时显示不出来，所以看起来像 `"ab"`，但长度是 3。）

这个错误非常常见：**有人用 `~|` 当表格分隔线，结果输出里全是控制字符。**
本仓库的验证标准里「stdout 不得含多余控制字符」这一条，抓的就是这类错误。
要竖线直接写 `|`，要对齐用 `~T`：

```lisp
(format t "姓名~10T年龄~20T城市~%张三~10T28~20T北京~%")
```

```
姓名        年龄        城市
张三        28        北京
```

## 14.5 参数跳位、循环与条件

```lisp
(format t "~~* 跳过下一个参数：~A 和 ~A~%" :第一个 :第二个)     ; 第一个 和 第二个
(format t "~~{...~~} 循环，~~^ 让最后一项不带分隔：~{~A~^, ~}~%" '("甲" "乙" "丙"))
; 甲, 乙, 丙
(format t "嵌套循环 ~~:{：~:{~A-~A ~}~%" '((1 a) (2 b)))        ; 1-A 2-B
(format t "~~[ 条件选择：~[零~;一~;二~]~%" 1)                    ; 一
(format t "~~:[ 真假二选一：~:[假~;真~]~%" t)                    ; 真
(format t "~~@[ 有值才输出：~@[值=~A~]~%" nil)                    ; （什么都不输出）
(format t "~~@[ 有值才输出：~@[值=~A~]~%" 42)                     ; 值=42
```

`~{~A~^, ~}` 这个组合是打印列表的万能写法：`~{...~}` 循环消费参数，
`~^` 表示「到了最后一个就停（不再输出后面的分隔符）」。

## 14.6 打印控制变量

`format` 的 `~S` 以及 REPL 的回显都受这些变量影响：

```lisp
(let ((*print-pretty* nil)) (format nil "~S" '(1 2 3)))          ; => "(1 2 3)"
(let ((*print-case* :downcase)) (format nil "~S" 'hello))         ; => "hello"
(let ((*print-length* 3)) (format nil "~S" '(1 2 3 4 5)))         ; => "(1 2 3 ...)"
(let ((*print-level* 2)) (format nil "~S" '(1 (2 (3 (4))))))      ; => "(1 (2 #))"
*print-right-margin*                                              ; => NIL
```

`*print-circle*` 专治**循环结构** —— 不开会无限递归：

```lisp
(let* ((cyc (list 1 2 3)) (*print-circle* t))
  (setf (cddr cyc) cyc)
  (format nil "~S" cyc))
; => "#1=(1 2 . #1#)"
```

这条在写「图 / 树 / 相互引用的对象」的调试输出时是必需的。

`*print-pretty*` 默认是 `T`，会让长结构折行。**做输出比对（测试、黄金文件）时
关掉它**，否则同一个值的打印结果可能因为行宽变化而不一致：

```lisp
(let ((*print-pretty* nil) (*print-right-margin* 200)) ...)
```

**但关掉它会连带改变别的打印形式** —— 最典型的是引号缩写。SBCL 只在 pretty
打开时才把 `(quote x)` 打成 `'x`：

```lisp
(format nil "~S" ''x)                              ; => "'X"
(let ((*print-pretty* nil)) (format nil "~S" ''x)) ; => "(QUOTE X)"
```

这一条是写这份指南时实测撞出来的：同一个表达式，只因为 `*print-pretty*` 不同，
打印结果就从 `'X` 变成 `(QUOTE X)`。**所以做黄金文件比对时，比对双方必须用
完全相同的打印变量**，否则会把「打印设置不同」误判成「程序行为不同」。
本仓库的示例因此统一**不关** pretty，改用「结束标记 + 结构化断言」保证判定稳定。

## 14.7 指令写错会怎样

`format` 的指令是**运行期解析**的（字符串字面量则会在编译期预编译），
所以拼错不会在写代码时告诉你：

```lisp
(format nil "~A ~A" 1)
; 报错：error in FORMAT: No more arguments
;   ~A ~A
;    ^            ← 连出错位置都标出来了

(format nil "~A" 1 2)          ; => "1"        ← 参数多了不报错，静默忽略
(format nil "~K" 1)
; 报错：Unknown directive (character: LATIN_CAPITAL_LETTER_K)
(format nil "~-10D" 1)
; 报错：error in FORMAT: The value of mincol is -10, should be a non-negative integer
```

**最常犯的错是这个**：把 `~A` 当普通文字写进了格式串：

```lisp
(format nil "== 1. ~A 与 ~S ==" 1 2)     ; => "== 1. 1 与 2 =="
```

你想输出 `~A 与 ~S` 这几个字符，结果 format 把它们当指令执行了。
**要显示波浪号必须写 `~~`**：

```lisp
(format nil "== 1. ~~A 与 ~~S ==")       ; => "== 1. ~A 与 ~S =="
```

（本指南在编写过程中就在这句话上摔了两次 —— 所以它值得单独一节。）

## 14.8 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| 输出里混进控制字符 / 缺内容 | 把 `~\|` 当成了表格竖线 | 竖线写 `\|`，对齐用 `~T` |
| 想输出 `~A` 却少了参数 | 没写 `~~` | 转义成 `~~A` |
| `(format nil "~R" 1/2)` 报错 | `~R` 只收整数 | 用 `~A` / `~D` |
| 设了 `*print-base*` 但 `~D` 没变 | `~D` 固定十进制 | 用 `~X` / `~B` / `~VR` |
| 测试比对输出不稳定 | `*print-pretty*` 在折行 | 比对时绑定 `*print-pretty*` 为 `nil` |
| 打印循环结构卡死 | 没开 `*print-circle*` | 绑定 `*print-circle*` 为 `t` |

---

# 第 15 章 文件与流 I/O

配套示例：`09-file-io.lisp`。

## 15.1 写文件：`with-open-file`

```lisp
(with-open-file (out "/tmp/demo.txt" :direction :output
                                    :if-exists :supersede
                                    :if-does-not-exist :create)
  (write-line "第一行" out)
  (write-line "第二行" out)
  (format out "格式化写入: ~D~%" 42))
```

`with-open-file` 保证**无论如何都关闭文件**（内部是 `unwind-protect`，
第 7 章讲过）。四个常用参数：

| 参数 | 取值 | 含义 |
|---|---|---|
| `:direction` | `:input` / `:output` / `:io` / `:probe` | 读写方向，默认 `:input` |
| `:if-exists` | `:supersede` / `:append` / `:overwrite` / `:error` / `nil` | 已存在怎么办 |
| `:if-does-not-exist` | `:create` / `:error` / `nil` | 不存在怎么办 |
| `:element-type` | `'character` / `'(unsigned-byte 8)` | 文本还是二进制 |

追加写用 `:if-exists :append`。

## 15.2 读文件：三种读法

**整行读**（处理文本最常用）：

```lisp
(with-open-file (in "/tmp/demo.txt")
  (loop for line = (read-line in nil nil) while line collect line))
; => ("第一行" "第二行" "格式化写入: 42")
```

`(read-line in nil nil)` 的两个 `nil` 是「EOF 时返回 nil」和「EOF 时不报错」——
**不写它们，读到文件末尾会抛错误**。

**整块读**（一次拿到全部内容）：

```lisp
(with-open-file (in "/tmp/demo.txt" :element-type 'character)
  (let* ((n (file-length in))
         (buf (make-string n))
         (filled (read-sequence buf in)))
    (subseq buf 0 filled)))
```

这里有个**必须记住的坑**：`file-length` 返回的是**字节数**，不是字符数。
同一个文件：

```lisp
(with-open-file (in "/tmp/demo.txt") (file-length in))        ; => 40    （字节）
;; 字符数 => 18
```

因为文件里有中文（UTF-8 下一个汉字 3 字节）。如果你按 `file-length` 分配
`make-string` 然后直接打印，**尾部会多出 22 个 `#\Nul`** —— 本仓库在修
`09-file-io.lisp` 时就踩过这个（stdout 里混进 42 个 NUL 字节，被验证脚本抓住）。
正确做法就是上面那样：**接住 `read-sequence` 的返回值再 `subseq`**。

**逐字符读**（要精细控制时）：

```lisp
(with-open-file (in "/tmp/demo.txt")
  (loop repeat 5 for c = (read-char in nil nil) while c collect c))
; => (#\U7B2C #\U4E00 #\U884C #\Newline #\U7B2C)
```

注意 SBCL 打印非 ASCII 字符用 `#\U7B2C` 这种形式（码点），中文就是三个这样的字符。

## 15.3 存在性与路径名

```lisp
(probe-file "/tmp/demo.txt")            ; => #P"/private/tmp/demo.txt"   ← 返回路径名对象，不是 T
(probe-file "/tmp/nope.txt")            ; => NIL
```

**`probe-file` 返回的是路径名对象**，可以当布尔用，但也顺带给了你规范化后的路径。
注意 macOS 上 `/tmp` 是符号链接，`truename` 会解析成 `/private/tmp`，
顺手也会消掉 `.` 这类冗余段：

```lisp
(truename "/tmp/demo.txt")        ; => #P"/private/tmp/demo.txt"
(truename "/tmp/./demo.txt")      ; => #P"/private/tmp/demo.txt"   ← 点段被消掉
```

**比较路径要用 `equal` 比 `namestring`，别用 `string=`**（因为可能一个是相对路径、
一个是绝对路径）。

路径名拆解：

```lisp
(pathname-name "/tmp/a/b.txt")        ; => "b"
(pathname-type "/tmp/a/b.txt")        ; => "txt"
(pathname-directory "/tmp/a/b.txt")   ; => (:ABSOLUTE "tmp" "a")
(namestring (pathname "/tmp/a/b.txt")) ; => "/tmp/a/b.txt"
(merge-pathnames "x.txt" "/a/b/")      ; => #P"/a/b/x.txt"
```

## 15.4 `rename-file` 与 `delete-file` 的坑

两者失败都**报错**，不会静默返回 nil：

```lisp
(delete-file "/tmp/demo-dir/nope.txt")
; 报错：Could not delete the file "/tmp/demo-dir/nope.txt": No such file or directory
```

`rename-file` 的**第二个参数是「目标路径的默认值」**，这个措辞很要命 ——
它自己的**目录部分会被丢掉**，改用源文件所在目录。先造两个文件出来：

```lisp
(ensure-directories-exist "/tmp/demo-dir/probe.txt")
(dolist (f '("/tmp/demo-dir/old.txt" "/tmp/demo-dir/old2.txt"))
  (with-open-file (o f :direction :output
                       :if-exists :supersede :if-does-not-exist :create)
    (write-string "hi" o)))
```

**坑在这里** —— 第二参数带了目录时，目录会被拼在「源文件所在目录」后面：

```lisp
(rename-file "/tmp/demo-dir/old.txt" "demo-dir/renamed.txt")
; 报错：couldn't rename /tmp/demo-dir/old.txt to
;       /tmp/demo-dir/demo-dir/renamed.txt: No such file or directory
;                      ^^^^^^^^^^^^^^^^^ 目录被拼了两遍
```

本仓库在 `09-file-io.lisp` 上踩的正是这种写法。第二参数**只给文件名**是正常的
（落在源文件旁边）；要指定目标目录就**显式用绝对路径**：

```lisp
(rename-file "/tmp/demo-dir/old2.txt" "renamed.txt")     ; 落回源文件所在目录
; => #P"/tmp/demo-dir/renamed.txt"

(with-open-file (o "/tmp/demo-dir/old2.txt" :direction :output
                                           :if-exists :supersede
                                           :if-does-not-exist :create)
  (write-string "hi" o))
(rename-file "/tmp/demo-dir/old2.txt"
             (merge-pathnames "new.txt" (truename "/tmp/demo-dir/")))
; => #P"/private/tmp/demo-dir/new.txt"
```

`(truename "/tmp/demo-dir/")` 拿到目录本身的路径名（**目录末尾必须带 `/`**，
否则它会被当成文件名去解析）。

另外，源文件**不存在**时报的是另一个错，别混淆：

```lisp
(rename-file "/tmp/demo-dir/nope.txt" "/tmp/demo-dir/x.txt")
; 报错：Failed to find the TRUENAME of /tmp/demo-dir/nope.txt:
;       No such file or directory
```

## 15.5 二进制与字符串流

二进制要把 `:element-type` 写成字节类型，读写用 `read-byte` / `write-byte`：

```lisp
(with-open-file (o "/tmp/bin.dat" :direction :output
                                :element-type '(unsigned-byte 8)
                                :if-exists :supersede :if-does-not-exist :create)
  (write-byte 200 o) (write-byte 1 o))

(with-open-file (i "/tmp/bin.dat" :element-type '(unsigned-byte 8))
  (list (read-byte i) (read-byte i) (read-byte i nil :eof)))
; => (200 1 :EOF)      ← 读到末尾返回第三个参数
```

**字符串流**把字符串当流用，测试里非常方便（不用碰磁盘）：

```lisp
(with-input-from-string (s "(a b c)") (read s))          ; => (A B C)
(with-output-to-string (s) (write-string "ab" s))        ; => "ab"
(read (make-string-input-stream "42"))                   ; => 42
```

`with-output-to-string` 是「一堆输出拼成字符串」最干净的写法。

## 15.6 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| stdout 里混进一堆 NUL | `file-length` 是字节数、却按字符数用 | 接 `read-sequence` 的返回值 |
| `read-line` 到末尾报错 | 没给 EOF 参数 | `(read-line in nil nil)` |
| `probe-file` 返回值不能当字符串 | 它返回路径名对象 | 用 `namestring` 转换 |
| 路径比较「不相等」 | 一个是相对路径 / `/tmp` 是符号链接 | 用 `truename` 规范化后比 |
| `rename-file` 报找不到 TRUENAME | 第二参数给了相对路径 | `merge-pathnames ... (truename dir)` |
| 目录写成没带 `/` 的路径 | 被当成文件解析 | 目录路径末尾加 `/` |

---

# 第 16 章 SBCL 专用：线程、FFI、优化、部署

配套示例：`11-sbcl-extensions.lisp`、`12-threads.lisp`、`13-ffi.lisp`、
`14-performance.lisp`、`17-testing-and-deployment.lisp`。

## 16.1 用 `SB-*` 之前先想清楚

`SB-` 开头的包是 SBCL 的**实现扩展**，标准里没有。用它们意味着：

- ✅ 能拿到别的实现没有的能力（原生线程、`run-program`、精确的优化控制）；
- ❌ 代码换实现就跑不了。

本仓库的 `sbcl/` 目录是**故意的单实现教程** —— 这里就是要讲 SBCL 的部分。
但业务代码里建议把 `SB-*` 的使用**收进一个小适配层**，方便将来换实现。

## 16.2 哪些包在核心里、哪些要 `require`

这是个很实际的坑：核心里就有的包**不需要 `require`**，而 `require` 它们会**报错**。
实测：

```lisp
;; 核心里就有（直接可用）
(sb-ext:posix-getenv "HOME")     ; => "/Users/xulun"
```

| 包 | 位置 |
|---|---|
| `SB-EXT`（扩展：`posix-getenv` / `run-program` / `exit`） | **核心** |
| `SB-ALIEN`（FFI） | **核心** |
| `SB-THREAD`（线程） | **核心** |
| `SB-PROFILE`（性能分析） | **核心** |
| `SB-DEBUG` / `SB-GRAY` / `SB-SYS` / `SB-KERNEL` | **核心** |
| `SB-POSIX` | contrib，**需要 `(require :sb-posix)`** |
| `SB-SPROF` | contrib，需要 `require` |
| `SB-COVER` | contrib，需要 `require`（会连带加载 `SB-MD5`） |
| `SB-BSD-SOCKETS` | contrib，需要 `require` |
| `SB-CLTL2` | contrib，需要 `require` |

实测证据：

```lisp
(require :sb-posix)          ; => ("SB-POSIX")
(require :sb-cover)          ; => ("SB-MD5" "SB-COVER")   ← 连带依赖
(find-package :sb-posix)     ; => #<PACKAGE "SB-POSIX">

(require :sb-profile)        ; 报错：Don't know how to REQUIRE SB-PROFILE.
(require :sb-thread)         ; 报错：Don't know how to REQUIRE SB-THREAD.
```

**最后一个错误容易误解**：它不是「没有这个功能」，而是「它已经在核心里了，
没有一个叫这个名字的 contrib 模块可以加载」。直接用即可。

还有一个连带问题：`require` 与 `pkg:符号` **不能写在同一个顶层形式里**
（第 1 章讲过「读入先于求值」）：

```lisp
;; 错的：读入这一行时 SB-POSIX 还不存在
(progn (require :sb-posix) (sb-posix:getpid))

;; 对的：分成两个顶层形式
(require :sb-posix)
(sb-posix:getpid)
```

## 16.3 实现信息与环境

```lisp
(lisp-implementation-type)      ; => "SBCL"
(lisp-implementation-version)   ; => "2.6.7"
(machine-type)                  ; => "X86-64"
(software-type)                 ; => "Darwin"
(sb-ext:posix-getenv "HOME")    ; => "/Users/xulun"
(sb-ext:posix-getenv "NOPE")    ; => NIL       ← 不存在的变量返回 NIL
```

**跨平台取环境变量要小心**：`USERPROFILE`、`OS` 这些是 Windows 专有的，
在 macOS 上实测返回 `NIL`（`11-sbcl-extensions.lisp` 里就是这样标注的）。
写跨平台代码时用 `#+win32` / `#-win32` 条件化：

```lisp
(defun shell-command (command)
  #+win32  (list "cmd" (list "/c" command))
  #-win32  (list "/bin/sh" (list "-c" command)))
```

## 16.4 跑外部命令：`sb-ext:run-program`

三个实测出来的坑：

```lisp
;; ① 给裸程序名必须加 :search t，否则不会去 PATH 里找
(sb-ext:run-program "echo" '("hi") :output t :search nil)
; 报错：Couldn't execute "echo": No such file or directory
(sb-ext:run-program "echo" '("hi") :output *standard-output* :search t)   ; 正常

;; ② :output 不接受 :string（想要字符串结果就自己接一个字符串流）
(sb-ext:run-program "echo" '("hi") :output :string :search t)
; 报错：RUN-PROGRAM error processing :OUTPUT argument: invalid option: :STRING

;; ③ 正确拿输出字符串的写法
(with-output-to-string (s)
  (sb-ext:run-program "echo" '("hi") :output s :search t))
; => "hi
; "
```

`:output t` 表示「继承当前进程的标准输出」（所以你会看到子进程的输出直接混进来），
`:output <流>` 表示「写到这个流里」。示例 `11-sbcl-extensions.lisp` 里两种都演示了，
实测能拿到 `退出码: 0`。

## 16.5 线程

```lisp
(sb-thread:thread-name sb-thread:*current-thread*)    ; => "main thread"
(length (sb-thread:list-all-threads))                 ; => 1     （只有主线程）

(let ((th (sb-thread:make-thread (lambda () 42) :name "worker")))
  (list (sb-thread:join-thread th)          ; => 42
        (sb-thread:thread-alive-p th)))     ; => NIL
```

**两条必须遵守的纪律**（`12-threads.lisp` 里都是踩过才写下的）：

**① 线程必须 `join`，不能用 `(sleep N)` 代替。**

主线程跑完就退出，没 join 的线程可能还在打印，输出会缺内容甚至缺结束标记。
线程池的 `shutdown` 也不能只看标志位就 `return` —— 那会丢掉队列里没跑完的任务，
要「取不到任务才退出」，然后 `join`。

**② 多线程打印必须自己加锁。**

多个线程直接 `(format t ...)` 会互相穿插：一次 `format` 按格式指令拆成**多次写**，
而 SBCL 写多字节汉字还会分块，两个字节能被两个线程各写走一半 ——
结果是 stdout 里出现**非法 UTF-8 字节**。标准做法：

```lisp
(defvar *print-lock* (sb-thread:make-mutex :name "print-lock"))

(defun say (fmt &rest args)
  (sb-thread:with-mutex (*print-lock*)
    (apply #'format t fmt args)
    (finish-output)))
```

**所有**输出（包括主线程的）都走 `say`。锁序保持单向（其它锁 → 打印锁），就不会死锁。

另外，**别直接 `~A` 打印线程对象**：

```lisp
;; #<THREAD tid=4099 ... waiting on: #<MUTEX ...>>  ← tid 和瞬时状态每次都不同
```

要展示就取稳定的部分（比如 `(type-of thread)`），否则输出没法比对。

**并发程序的输出顺序天然不确定**，所以关键结论要写成**与调度无关的汇总**：
计数、排序后的列表、`(<= 峰值 上限)` 这样的布尔断言。

## 16.6 FFI：`sb-alien`

`SB-ALIEN` 能在核心里直接调 C 函数，不用编译胶水代码：

```lisp
(load-shared-object "libSystem.B.dylib")     ; macOS
;; Linux 下换成 "libc.so.6"

(define-alien-routine ("strlen" c-strlen) long (s c-string))
(c-strlen "hello")                            ; => 5
```

`13-ffi.lisp` 的实测输出（节选）：

```
strlen("hello") = 5
abs(-42) = 42
getenv("HOME") = /Users/xulun
sqrt(2.0) = 1.4142135623730951d0
toupper(#\a) = A
strcmp("abc", "abc") = 0
strcmp("abc", "abd") = -1
```

**跨平台的坑**：C 库里没有 `strupr`（那是 MSVC 专有扩展），所以要大小写转换
用标准的 `toupper` / `strcasecmp` —— `13-ffi.lisp` 原来就是用了 `strupr`，
在 macOS 上链接失败。

**能用 CFFI 就用 CFFI**：`sb-alien` 的接口是 SBCL 专有的，而 CFFI 是跨实现的事实标准，
而且能处理结构体、回调这些复杂情况。需要跟 C 库做正经集成时别硬扛。

## 16.7 优化与性能

**类型声明**是 SBCL 上最有效的优化手段（编译器据此生成无装箱的算术）：

```lisp
(defun fast-add (a b)
  (declare (type fixnum a b))
  (the fixnum (+ a b)))
```

优化级别用 `declaim` / `declare`：

```lisp
(declaim (optimize (speed 3) (safety 1) (debug 1)))
```

**但要记住第 6 章的实测结论**：`(debug 3)` 会关掉尾调用优化。
调优时的常见组合是 `(speed 3) (safety 1) (debug 1)`，
发布时不要为了性能把 `safety` 降到 0（会关掉很多运行期检查）。

`time` 宏是最省事的测量手段（`14-performance.lisp` 实测输出）：

```
Evaluation took:
  0.002 seconds of real time
  0.002014 seconds of total run time (0.001995 user, 0.000019 system)
  100.00% CPU
  6,278,825 processor cycles
  0 bytes consed
```

**注意 `0 bytes consed` 这一行** —— 它告诉你这段代码有没有分配内存。
GC 压力大不大，看这一行比看时间更有用。

要按函数看耗时，用核心里的 `SB-PROFILE`（**不用 `require`**）：

```lisp
(sb-profile:profile my-function)
```

输出长这样（示例 14 的真实输出）：

```
  seconds  |     gc     |   consed  | calls |  sec/call  |  name
-------------------------------------------------------
     0.002 |      0.000 | 1,604,848 |     1 |   0.002130 | PROFILE-TARGET-3
```

顺手记两个诊断函数：

```lisp
(disassemble #'my-function)    ; 看反汇编
(describe obj)                 ; 看对象的所有信息
```

## 16.8 部署：生成可执行文件

`save-lisp-and-die` 把当前堆（含你定义的所有函数）保存成一个可执行文件：

```lisp
(save-lisp-and-die "myapp"
                   :executable t
                   :toplevel #'main)
```

要点：

- **`:toplevel` 指定入口函数**（不指定的话启动后会进 REPL）；
- **macOS / Linux 上不要加 `.exe`**，Windows 上才加；
- `save-lisp-and-die` **不返回** —— 它保存完就退出进程，所以必须是最后一条语句。

可执行文件的 `main` 函数里，命令行参数用：
`sb-ext:*posix-argv*`（或 `(cdr sb-ext:*posix-argv*)` 去掉程序名）。

## 16.9 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| `Don't know how to REQUIRE SB-THREAD` | 它在核心里，没有同名 contrib | 直接用，别 require |
| `require` 之后的 `pkg:sym` 读不到 | 同一个形式里先读后求值 | 分成两个顶层形式 |
| `Couldn't execute "echo"` | 没加 `:search t` | 加 `:search t` 或用绝对路径 |
| `:output :string` 报错 | 不支持的选项 | 用 `with-output-to-string` |
| 并发输出出现乱码/非法 UTF-8 | 多线程直接 `format t` | 加打印锁 |
| 输出缺内容 | 线程没 `join` | 全部 `join` |
| 链接 `strupr` 失败 | 那是 MSVC 专有函数 | 用 `toupper` / `strcasecmp` |
| `save-lisp-and-die` 之后的代码没执行 | 它不返回 | 放到最后 |

---

# 第 17 章 工程化：ASDF、测试与工具链

配套示例：`15-asdf-quicklisp.lisp`、`17-testing-and-deployment.lisp`。

## 17.1 一个最小可用项目的结构

```
myproj/
├── myproj.asd          ← 系统定义（ASDF 的入口，相当于 package.json / Cargo.toml）
├── src/
│   ├── package.lisp    ← 先定义包
│   └── main.lisp
├── tests/
│   └── tests.lisp
└── README.md
```

**关键约定**：`.asd` 文件必须和系统**同名**，且放在 ASDF 能找到的目录里
（`~/.config/common-lisp/source-registry.conf.d/` 或 `~/common-lisp/`、`~/quicklisp/local-projects/`）。

## 17.2 ASDF 系统定义

`.asd` 文件里的 `defsystem` **不是 `CL-USER` 里的函数** —— ASDF 加载 `.asd` 时会把
`*package*` 绑到 `ASDF-USER`（包名写成 `ASDF/USER`），`defsystem` 是从那里继承来的。
实测：

```lisp
(require :asdf)
(find-package :asdf-user)                  ; => #<PACKAGE "ASDF/USER">
(nth-value 1 (find-symbol "DEFSYSTEM" :asdf-user))   ; => :INHERITED
(find-symbol "DEFSYSTEM" :cl-user)         ; => NIL   ← CL-USER 里没有！
```

所以在 REPL 里手敲 `(defsystem "myproj" ...)` 会报 `illegal function call`
（被当成普通函数调用）。要手动加载 `.asd` 请用 `(asdf:load-asd ".../myproj.asd")`。

`myproj.asd` 的内容：

```lisp
(defsystem "myproj"
  :description "示例项目"
  :version "0.1.0"
  :depends-on ()                    ; 依赖列表，如 ("alexandria" "cl-ppcre")
  :serial t                         ; 按顺序加载（有依赖关系时必须）
  :components ((:file "src/package")
               (:file "src/main"))
  :in-order-to ((test-op (test-op "myproj/tests"))))

(defsystem "myproj/tests"
  :depends-on ("myproj")
  :components ((:file "tests/tests"))
  :perform (test-op (o c) (symbol-call :myproj/tests :run-tests)))
```

`:serial t` 值得单独记：**它表示「按 components 的顺序依次加载」**。
不写的话 ASDF 可能并行编译，依赖顺序就乱了。

加载与编译：

```lisp
(asdf:load-system "myproj")      ; 加载（必要时编译）
(asdf:test-system "myproj")      ; 跑测试
```

命令行入口（不需要进 REPL）：

```bash
$ sbcl --non-interactive --eval '(require :asdf)' \
       --eval '(asdf:load-system "myproj")'
```

## 17.3 依赖管理

- **Quicklisp** 是事实标准：`(ql:quickload "alexandria")` 会自动下载、编译、加载。
- **但依赖要写进 `.asd` 的 `:depends-on`** —— Quicklisp 只是「拿到依赖」的手段，
  `:depends-on` 才是「声明依赖」的地方。别人拿到你的项目靠的是后者。
- 本仓库的示例**刻意只用内置库**（不依赖任何第三方包），这样任何 SBCL 都能跑。
  这是教学项目的取舍；真实项目不必如此。

## 17.4 测试：从 `assert` 开始

CL 没有内置测试框架（标准的 `assert` 算是半个），但**轻量测试用 `assert` 完全够**：

```lisp
(defun run-tests ()
  (assert (= (my-add 1 2) 3))
  (assert (string= (my-greet "x") "Hello, x"))
  (format t "全部通过~%"))
```

配合 `handler-case` 测「预期会失败的路径」：

```lisp
(assert
 (handler-case (progn (parse-integer "abc") nil)
   (parse-error () t)))
```

需要更完整的功能（fixture、报告、失败计数）时上 **FiveAM** 或 **Rove**。
但**别一开始就上框架** —— `assert` + 结束标记已经能进 CI 了，
本仓库 17 个示例就是这么做的。

## 17.5 交互式开发流程

这是 CL 相对编译型语言的**最大优势**，值得单独说：

1. **在 REPL 里试**。不用重启进程、不用重新编译整个项目 —— 改完一个函数
   `C-c C-c`（SLIME 里）就替换掉运行中的定义，**其它状态保留**；
2. **出错不要慌**。报错时 REPL 会进调试器，你会看到完整的调用栈、
   出错现场的所有变量、以及可用的 restart。修好再 `continue`，程序接着跑 ——
   **不需要复现**；
3. **状态就在进程里**。连着一个跑了三天的服务，你可以直接检查它的内存数据。

这套流程依赖编辑器集成：**SLIME**（`slime` + `sbcl`）或 **SLY**，
Emacs 用户装 SLIME，Vim 用户用 `vlime` / `slimv`，VS Code 用 `alive` / `common-lisp` 插件。

不用编辑器也能做，只是效率低：`sbcl` 启动 REPL，`(load "x.lisp")` 重新加载文件。

## 17.6 本仓库的验证约定

`sbcl/` 目录下每个示例都遵守一套约定，这对写自己的可测试脚本很有参考价值：

1. **每个示例最后打印结束标记** `==== NN 结束 ====` —— 因为 SBCL 有
   「静音掉错误、退出码仍是 0」的情况，标记是最后的把关；
2. **所有输出走 stdout**（`format t`），警告和诊断文字走 stderr
   —— 于是「stderr 为空」等价于「零警告」，这条判定真能拦住东西；
3. **不用会变的东西做输出**：地址、`gensym` 编号、哈希顺序、线程调度顺序，
   要么消掉，要么排序，要么在文件头列出「本次运行可能不同的行」；
4. **并发示例自己加打印锁**，并让关键结论与调度无关。

跑一遍：

```bash
$ ./run-all.sh                 # macOS / Linux
$ pwsh ./build.ps1 -All        # PowerShell（三平台）
```

两个入口的判定逻辑一致：退出码 0 + stderr 为空 + stdout 无多余控制字符 +
有结束标记。实测均为 `通过 17   失败 0`。

**注意：不要同时开两份。** 两个入口都把产物写到同一个 `build/<示例名>/` 目录，
并行跑会互相覆盖 stdout，表现为「输出只写了一半、结束标记丢失」，
看起来像示例崩了，其实是产物目录被抢了。实测并行两轮时第二轮误报 3 个失败，
串行则稳定 17/17。

本指南里的 `; =>` 断言也能一键复核：

```bash
$ python3 verify-guide.py
==== blocks 267, claims 521, mismatch 0, broken 18 ====
```

它把每个代码块还原成 `.lisp` 按顺序 `--load`，再逐条比对打印结果。
`broken 18` 是**故意演示报错**或**摘录片段**的块，不是失败项 —— 细节见 `README.md`。

## 17.7 本章的坑

| 症状 | 原因 | 解法 |
|---|---|---|
| ASDF 找不到系统 | `.asd` 不在注册目录，或名字不符 | 放进 `~/quicklisp/local-projects/`，文件名与系统同名 |
| 加载顺序错乱 | 没写 `:serial t` | 有依赖就加上 |
| `save-lisp-and-die` 生成的程序没有入口 | 没指定 `:toplevel` | `:toplevel #'main` |
| 换台机器跑不起来 | 依赖了第三方库但没写 `:depends-on` | 依赖写进 `.asd` |
| 示例「通过」但其实没执行 | 用了 `--script` 与 `--non-interactive` | 用 `--load` |

---

# 附录 A 常见坑速查（症状 → 原因 → 解法）

## 求值与语法

| 症状 | 原因 | 解法 |
|---|---|---|
| 报 `A is unbound` / `X is undefined` | 变量没绑/名字拼错 | 检查 `defvar` 与拼写 |
| `(car 5)` 报类型错 | 参数类型不对 | 看报错里的原始形式 |
| 括号数对但报解析错 | 嵌套位置错（漏一个又多一个） | 跑 `compile-file` 静态检查 |
| `Package FOO does not exist.` | `foo:bar` 但包不存在 | 先 `defpackage` / `require` |
| `require` 后同一行用不到新包 | 读入先于求值 | 分两个顶层形式 |

## 数字

| 症状 | 原因 | 解法 |
|---|---|---|
| 小数算出来差一点 | 浮点字面量默认**单精度** | 写 `1.5d0` 或用有理数 |
| `(/ 7 2)` 得到 `7/2` | `/` 给精确有理数 | 要整数商用 `floor` / `truncate` |
| 负数除法结果和 C 不同 | `floor` 是向下取整 | 想截断用 `truncate` |
| 负数取模结果怪 | `mod` 跟除数、`rem` 跟被除数 | 想清楚要哪个 |
| `(round 2.5)` 得 2 | 银行家舍入 | 要传统舍入用 `(floor (+ x 1/2))` |
| `(sqrt 4)` 是浮点 | `sqrt` 一律返回浮点 | 用 `isqrt` |

## 字符串与序列

| 症状 | 原因 | 解法 |
|---|---|---|
| 改字面量字符串偶尔崩 | 字面量在只读内存 | `copy-seq` / `make-array` |
| `(eq "a" "a")` 是 NIL | `eq` 比身份 | 用 `equal` / `string=` |
| `(string< a b)` 返回数字 | 它返回差异下标 | 当布尔用 |
| `(intern "foo")` ≠ `'foo` | 读入器转大写 | `(intern (string-upcase s))` |
| `(length '(1 . 2))` 报错 | 点对不是正规列表 | 检查结构 |
| `(assoc "a" alist)` 找不到 | 默认 `eql` | 加 `:test #'equal` |
| `(equal #(1 2) #(1 2))` 是 NIL | `equal` 不比向量内容 | 用 `equalp` |

## 控制流与迭代

| 症状 | 原因 | 解法 |
|---|---|---|
| `(if 0 ...)` 走了真分支 | 只有 `nil` 是假 | 用 `(zerop x)` |
| `case` 匹配字符串总失败 | `case` 用 `eql` | 用 `cond` / `typecase` |
| 循环把内存吃爆（`Heap exhausted`） | `loop` 没有上界 | 写 `to` / `while` / `until` |
| `for x on lst` 拿到尾巴 | `on` 给子列表 | 用 `in` 或 `(car x)` |

## 破坏性操作与相等

| 症状 | 原因 | 解法 |
|---|---|---|
| 排序「没生效」 | `sort` 的返回值没接 | 接返回值 |
| 原数据被改了 | `sort` / `nreverse` / `delete` 是破坏性的 | `copy-list` 或改用非破坏版本 |
| `(delete x lst)` 丢结果后没删 | 删头元素时旧变量失效 | 接返回值或用 `remove` |
| 去重保留了不想要的那个 | `remove-duplicates` 默认留最后 | 加 `:from-end t` |
| 结构体 `equal` 是 NIL | 结构体要 `equalp` | 用 `equalp` |

## 条件系统

| 症状 | 原因 | 解法 |
|---|---|---|
| 示例「stderr 非空」 | `warn` 写 stderr | 临时绑 `*error-output*` |
| `handler-bind` 处理器返回了错误还炸 | 正常返回不算处理 | 用 `invoke-restart` 转走控制流 |
| `handler-case` 里拿不到原始出错现场 | 栈已展开 | 用 `handler-bind` 或保存条件对象 |
| 自定义条件打印成 `#<...>` | 没写 `:report` | 加 `:report` |
| 捕不到某个错误 | 捕的类太具体 | 捕 `type-error` / `error` |

## 宏

| 症状 | 原因 | 解法 |
|---|---|---|
| 宏展开后行为诡异 | 变量捕获 | `(gensym)` |
| `gensym` 生成两个不同符号 | 在宏体里调了两次 | 生成一次、存变量 |
| `(apply #'my-macro ...)` 编译报错 | 宏不是函数 | 逻辑挪进函数 |
| 展开结果里出现 `#:G123` | 正常现象 | 不用管 |

## SBCL 与工具

| 症状 | 原因 | 解法 |
|---|---|---|
| `Don't know how to REQUIRE SB-THREAD` | 它在核心里 | 直接用 |
| `Couldn't execute "echo"` | 没加 `:search t` | 加 `:search t` |
| 并发输出乱码 | 多线程直接 `format t` | 加打印锁、全部 `join` |
| 示例「通过」但没执行 | `--script` 与 `--non-interactive` 连用 | 用 `--load` |
| 改了判定脚本后结果反了 | 判定函数自身有 bug | 重做反向验证 |
| stdout 里混进 NUL | `file-length` 是字节数 | 接 `read-sequence` 返回值 |
| 输出里混进控制字符 | `~\|` 被当成了竖线 | 竖线写 `\|`，对齐用 `~T` |
| `format` 报参数不够 | 格式串里写了 `~A` 却没转义 | 写成 `~~A` |
| 关闭 `*print-pretty*` 后 `'X` 变成 `(QUOTE X)` | SBCL 只在 pretty 打开时才用引号缩写 | 比对双方用同一套打印变量 |
| REPL 里 `(defsystem ...)` 报 `illegal function call` | 它是 `ASDF-USER` 里的名字，不在 `CL-USER` | 写进 `.asd` 文件，或用 `asdf:load-asd` |

---

# 附录 B 报错信息对照表

SBCL 的报错信息很具体，值得认识几条常见的：

| 报错原文（节选） | 含义 |
|---|---|
| `The variable X is unbound.` | 用了未绑定的变量（漏 `defvar` 或拼错） |
| `The variable A is unbound.`（在 `let` 里） | `let` 是并行绑定，该用 `let*` |
| `Value of 5 in (CAR 5) is 5, not a LIST.` | 参数类型不对，原文形式就是出错点 |
| `The assertion (> 2 3) failed.` | `assert` 失败 |
| `9 fell through ECASE expression. Wanted one of (1).` | `ecase` 没匹配上 |
| `No applicable method for the generic function ...` | 没有匹配的 `defmethod` |
| `The slot COMMON-LISP-USER::Y is unbound in the object ...` | 槽没有值（不是 nil） |
| `Lock on package COMMON-LISP violated when ...` | 想改标准符号，被包锁拦住 |
| `Package FOO does not exist.` | 包前缀写错了 |
| `Don't know how to REQUIRE SB-THREAD.` | 该包在核心里，不能也不需 require |
| `Couldn't execute "echo": No such file or directory` | `run-program` 缺 `:search t` |
| `Control stack exhausted ... a tail call that SBCL cannot or has not optimized away.` | 递归太深，或 `debug 3` 关掉了 TCO |
| `Heap exhausted, game over.` | 无界循环/无限分配，进程级致命错误（拦不住） |
| `error in FORMAT: No more arguments` | 格式串的指令数多于实参 |
| `error in FORMAT: Unknown directive (character: LATIN_CAPITAL_LETTER_K)` | 格式指令拼错 |
| `The value of mincol is -10, should be a non-negative integer` | `~-10D` 这类负宽度非法 |
| `1/2 is not of type INTEGER.` | `~R` 只接受整数 |
| `Execution of a form compiled with errors.` | 编译期就报错（如 `setf` 常量、宏当函数用） |
| `junk in string "abc"` | `parse-integer` 遇到非数字字符 |
| `The file #P"..." does not exist` | 文件不存在且未给 `:if-does-not-exist` |

---

## 参考与配套

- 示例代码：本目录的 17 个 `.lisp` 文件（`01-hello-world.lisp` … `17-testing-and-deployment.lisp`）
- 一键验证：`./run-all.sh` 或 `pwsh ./build.ps1 -All`（判定标准见 `README.md`）
- 环境：macOS + SBCL 2.6.7（MacPorts）

### 这份指南里，哪些是实测、哪些是可移植结论

本指南的写法约定如下，读的时候可以据此判断一条说法的分量：

| 类型 | 标记 | 可否照搬 |
|---|---|---|
| **实测输出** | 代码行后的 `; =>`、``` 围栏里的报错原文 | 本机 SBCL 2.6.7 的真实结果 |
| **跨实现结论** | 「ANSI 规定」「标准行为」这类表述 | 换 CCL / ECL / CLISP 也成立 |
| **SBCL 专有** | 第 16 章、以及正文里带 `sb-*` / `SB-*` 的内容 | **只在 SBCL 上成立** |
| **每次都可能不同** | 标了「每次运行都不同」的行 | 对象地址、`gensym` 编号、哈希表顺序、并发输出顺序 |

三条纪律：

1. **凡是带 `; =>` 的，都是真跑出来的**，没有手写的示意值；地址一类的必然变量会显式标注。
2. **示例只依赖内置库**（`CL` + SBCL 自带），不依赖 Quicklisp 或第三方包 —— 这样任何
   装了 SBCL 的机器都能直接跑。第 17 章讲 ASDF / Quicklisp 是「工程化知识」，
   那一章的代码块需要你自己建项目才能真正跑。
3. **判定靠「结束标记 + 四条标准」**，不靠输出逐字节比对 —— 原因见 `README.md`
   的「已知的、不影响判定的现象」一节（并发示例、墙钟计时、当前目录路径都会变）。
