# Emacs 扩展开发指南

一份从零到能写出可用扩展的 Emacs Lisp 教程。每一章都对应 `examples/` 里一个可以真跑起来的文件，
文中引用的输出都是**在本机实际运行得到的**，不是手写的示意。

---

## 这份指南怎么用

Emacs 的扩展开发有个特点：语言（Elisp）本身很小，但它的**运行环境**（buffer、point、keymap、hook、
face）是独一份的。所以本指南分两部分交替推进 —— 先把语言讲透，再讲这几个环境对象，
最后用它们拼出真正的扩展。

读书方式建议是**边读边在 Emacs 里跑**。每章的示例都是自包含的，直接打开加载即可：

```bash
# 跑单个示例（-Q 表示不加载任何配置文件，保证结果可复现）
emacs -Q --batch -l examples/01-hello.el

# 跑全部 26 个示例，逐个核对判定标准
./run-all.sh
```

```powershell
# Windows 侧等价入口
.\build.ps1 -All
```

### 章节目录与示例对照

| 章 | 主题 | 示例文件 |
|---|---|---|
| 0 | 环境、运行方式与验证标准 | — |
| 1 | 第一个程序：输出与 quote | `01-hello.el` |
| 2 | 类型与值 | `02-types.el` |
| 3 | 变量与绑定 | `03-variables.el` |
| 4 | 函数 | `04-functions.el` |
| 5 | 控制流 | `05-control-flow.el` |
| 6 | 相等性：`eq` / `eql` / `equal` | `06-equality.el` |
| 7 | 列表与关联结构 | `07-lists.el` |
| 8 | 字符串与正则 | `08-strings-regexp.el` |
| 9 | 序列与 `cl-lib` | `09-sequences.el` |
| 10 | buffer 与 point | `10-buffers.el` |
| 11 | 文本属性与 overlay | `11-text-properties.el` |
| 12 | 文件与目录 | `12-files.el` |
| 13 | 交互式命令 | `13-interactive.el` |
| 14 | keymap 与按键绑定 | `14-keymaps.el` |
| 15 | minor mode | `15-minor-mode.el` |
| 16 | major mode | `16-major-mode.el` |
| 17 | hook | `17-hooks.el` |
| 18 | 可定制选项 `defcustom` | `18-custom.el` |
| 19 | advice：不改源码改行为 | `19-advice.el` |
| 20 | 子进程 | `20-processes.el` |
| 21 | 定时器 | `21-timers.el` |
| 22 | 错误处理 | `22-errors.el` |
| 23 | 宏 | `23-macros.el` |
| 24 | 模块、加载与打包 | `24-packages.el` |
| 25 | 测试 | `25-tests.el` |
| 26 | 完整示例：一个 todo 扩展 | `26-todo-demo.el` |
| 附录 A | 常见坑速查 | — |
| 附录 B | 命令与变量速查 | — |

### 环境

本指南在 **GNU Emacs 31.1** 上编写和验证。示例只用内置库（`seq`、`cl-lib`、`ert`、`package`），
不依赖任何第三方包，所以任何 Emacs 27 以上的版本都应该能跑。差异点会在正文里注明。

---

# 第 0 章 先跑起来：环境、运行方式与验证标准

## 0.1 batch 模式：扩展能自动化测试的前提

Emacs 有两种工作方式。交互模式下它是编辑器；`--batch` 模式下它是一个**纯粹的 Lisp 解释器** ——
不读配置文件、不开窗口、跑完就退出：

```bash
emacs -Q --batch -l examples/01-hello.el
```

其中：

- `-Q` 等价于 `-q --no-site-file --no-splash`，即「不加载 `~/.emacs.d/init.el`」。
  写扩展时**永远**加它，否则你的输出会被用户的配置污染，问题变得不可复现。
- `--batch` 关掉交互界面，并在最后自动退出。
- `-l file` 加载文件；也可以用 `--eval '(表达式)'` 直接跑一段代码。

这套组合是整个扩展开发流程的地基：它让「运行一个扩展」变成一条可以在 CI 里跑的普通命令。

## 0.2 最重要的一条：输出往哪去

这是本指南的第一个、也是最影响写代码方式的事实，值得单独一节。Emacs 里有两个看起来都能「输出」的函数：

| 函数 | batch 模式下写到哪里 |
|---|---|
| `princ` | **stdout** |
| `message` | **stderr** |

实测：

```bash
$ emacs -Q --batch --eval '(message "MSG via message")' 2>/dev/null
$ emacs -Q --batch --eval '(princ "PRINC via princ\n")' 2>/dev/null
PRINC via princ
```

`message` 那一行第一个命令什么也没打印 —— 因为它的内容全在 stderr 里。

为什么会这样？因为 `message` 在交互模式下要把文字送进 **echo area**，那是 UI 的一部分而不是程序输出，
所以它走错误流。`princ` 才是「往标准输出写」。

**这条事实直接决定了示例怎么写**：如果示例里用了 `message` 来打印结果，那么在「stderr 必须为空」
这条判定下它就会失败。所以本仓库所有示例统一用：

```elisp
(princ (format "格式串 %d / %S\n" 一个整数 一个对象))
```

`princ` 原样输出不换行不加引号，所以换行要自己写 `\n`，所有格式化交给 `format`。

## 0.3 四个判定标准

`run-all.sh`（macOS/Linux）和 `build.ps1`（Windows）对每个示例做**三步**检查，缺一不可：

1. **字节编译**：`byte-compile-file` 退出码为 0，且 stderr 为空。
2. **加载运行**：退出码为 0。
3. **输出三条**：
   - stderr 为空；
   - stdout 里没有多余控制字符（0..31，TAB/LF/CR 除外）；
   - stdout 里有结束标记 `==== NN 结束 ====`（NN 与文件名前缀一致）。

### 为什么「stderr 为空」是认真的一条

因为**字节编译的警告也走 stderr，而退出码仍然是 0**。实测：

```elisp
;;; warn.el
;;; -*- lexical-binding: t; -*-
(defun demo-fn (x)
  (if (eq x t) 1 2)
  undefined-var-here)
```

```bash
$ emacs -Q --batch --eval '(byte-compile-file "warn.el")' 2>/dev/null
   # ← stdout 是空的，什么警告都没有
$ echo $?
0

$ emacs -Q --batch --eval '(byte-compile-file "warn.el")' 2>&1 1>/dev/null
warn.el:4:11: Warning: reference to free variable 'undefined-var-here'
warn.el:1:1: Warning: Unused lexical argument 'x'
```

于是「stderr 为空」这条规则的实际含义是：**零警告**。它把「能跑」提升成了「干净」。
本指南里那些 `【坑】` 标注的段落，绝大多数就是这条规则逼出来的 —— 写出来会被编译器抓住的东西。

### 为什么还要查控制字符

因为 `%S` 打印某些对象时会**把原始字节写进输出**。实测两个真实例子：

```bash
$ emacs -Q --batch --eval '(princ (format "%S" (kbd "C-c x")))' | cat -v
"^Cx"                      # 这里的 ^C 就是原始的 0x03 字节
```

```elisp
;; advice-member-p 返回的不是 t，而是整个 advice 对象（内含字节码）
(advice-member-p #'demo-log-before #'demo-save)   ; → 一个含控制字节的对象
```

这类输出扔进终端会把光标搞乱，重定向到文件后 `grep` 也可能崩。所以判定脚本会扫一遍字节流，
发现 TAB/LF/CR 之外的控制字符就报失败。规避方法很简单：要么用 `key-description`/`prin1-to-string`
这类「给人看」的转换函数，要么把布尔转换掉（`(and x t)`）。

### 结束标记

每个示例最后一行固定是：

```elisp
(princ "==== 01 结束 ====\n")
```

它的作用是兜住「代码被静默截断」这种情况 —— 比如某个 `(error ...)` 让 Emacs 提前退出、
或者某段 `condition-case` 把整块吞掉了。只要能跑到底，这行就一定在。

## 0.4 交互式调试与 batch 验证的分工

别因为 batch 能自动跑就只用 batch。实际开发节奏是：

| 场景 | 用什么 |
|---|---|
| 想快速看一个表达式的结果 | 在 `*scratch*` 里写、`C-j` 求值 |
| 想知道某个函数怎么用 | `C-h f`；变量用 `C-h v` |
| 想看当前 buffer 里所有 keybinding | `C-h b`；某个前缀下用 `C-h` |
| 想看某个 face 长什么样 | `M-x list-faces-display` |
| 排查为什么出错 | `M-x toggle-debug-on-error` 打开再复现 |
| **回归验证** | `./run-all.sh` |

`M-x toggle-debug-on-error` 值得一提：打开之后任何未捕获的错误都会弹出带完整调用栈的 backtrace，
比在代码里到处插 `princ` 有效得多（见第 22 章）。

## 0.5 示例文件的统一节拍

`examples/` 下每个文件都长这样，你在自己写示例时也可以照这个模板：

```elisp
;;; -*- lexical-binding: t; -*-
;;; ============================================================
;;; 07 - 列表与关联结构
;;;   点对、共享结构、破坏性操作这些容易出错的点
;;;
;;; 编译：emacs -Q --batch --eval '(byte-compile-file "07-lists.el")'
;;; 运行：emacs -Q --batch -l 07-lists.el
;;; ============================================================

;;; 1) 第一节……
;;; 2) 第二节……
...

(princ "==== 07 结束 ====\n")
```

两处约定要注意：

- 第一行 **`;;; -*- lexical-binding: t; -*-` 不能省**。它开启词法作用域，是 2026 年写 Elisp 的默认选择。
  没有它就会退回动态作用域，闭包和 `let` 的语义会完全不同（第 3 章会详细讲这个区别）。
- 分节用 `;;; 1) 2) 3)`，与正文的讲解编号对应，方便对着指南读代码。

---

# 第 1 部分 语言基础

这一部分把 Elisp 当作一门普通编程语言学完。Elisp 的语法极简 —— 全是括号前缀表达式 ——
真正的坑都在**求值规则**和**相等性**这类语义细节上，所以下面九章的重点也在这儿。

# 第 1 章 第一个程序：输出与 quote

> 示例：`examples/01-hello.el`

## 1.1 最小程序

```elisp
(princ "Hello, Emacs!\n")
```

```bash
$ emacs -Q --batch -l examples/01-hello.el
Hello, Emacs!
```

一个「函数调用」就是一个被括号包起来的列表，第一个元素是函数名，后面是参数。没有语句、没有分号结束符。

## 1.2 唯一的输出组合

日常只需要记住这一个写法：

```elisp
(princ (format "1 + 1 = %d，列表 = %S，字符串 = %s，pi = %.2f\n"
               (+ 1 1) '(1 2 3) "abc" float-pi))
```

```
1 + 1 = 2，列表 = (1 2 3)，字符串 = abc，pi = 3.14
```

`format` 的四个常用控制符：

| 控制符 | 用途 | 例子 → 结果 |
|---|---|---|
| `%s` | 字符串、数字等「给人看」的形式 | `(format "%s" "abc")` → `"abc"` |
| `%d` | 整数 | `(format "%d" 42)` → `"42"` |
| `%f` / `%.2f` | 浮点，可指定小数位 | `(format "%.2f" float-pi)` → `"3.14"` |
| `%S` | **能被 `read` 回来的 Lisp 语法形式** | 见下 |

`%S` 和 `%s` 的区别在调试时特别重要：

```elisp
(princ (format "prin1 形式：%s\n" (prin1-to-string "带\"引号\"的字符串")))
```

```
prin1 形式："带\"引号\"的字符串"
```

字符串带着引号和转义一起打印出来了 —— 这正是「能被读回来」的意思。想看一个对象的**准确结构**
（而不是友好的显示），就用 `%S` / `prin1-to-string`。

> **注意** `%S` 有时会打印出原始字节，比如键序列（第 14 章）。真要在输出里展示这类对象，
> 先用 `key-description` 之类的函数转成人读形式。

## 1.3 quote：阻止求值

Lisp 的求值规则是「先求值所有参数，再把结果传给函数」。所以：

```elisp
(1 2 3)      ;; 错误！会被当成「调用一个名叫 1 的函数」
'(1 2 3)     ;; 正确，三元素列表
```

```
quote 后：(1 2 3)
等价写法：(1 2 3)
符号本身：foo，符号的名字："foo"
```

`'x` 是 `(quote x)` 的语法糖。它做两件事：

- 对列表：阻止「当函数调用」，原样返回这个列表；
- 对符号：阻止「当变量求值」，返回**符号本身**。

区分「符号」和「符号的名字」在元编程里很关键：`'foo` 是一个符号对象，`(symbol-name 'foo)` 才得到字符串 `"foo"`。
反过来 `(intern "foo")` 能从字符串造出符号。

## 1.4 注释的三种惯例

这不是编译器的要求，而是整个 Emacs 生态的约定，`checkdoc`、`package-lint` 和所有主流 mode 都依赖它：

```elisp
;;; 三个分号 —— 文件头、以及顶格的「分节标题」
;;   两个分号 —— 普通注释，跟代码缩进对齐
;    一个分号 —— 行尾的简短说明
```

分节标题写成 `;;; 1) 说明` 而不是 Markdown 那种标题，是因为 Emacs 的 `outline-minor-mode`
和 `imenu` 会把它们识别成结构，可以折叠、可以跳转。

---

# 第 2 章 类型与值

> 示例：`examples/02-types.el`

## 2.1 类型查询与谓词

`type-of` 给出类型的符号，日常判断则用一堆 `xxxp` 谓词：

```elisp
(princ (format "type-of: %S\n" (mapcar #'type-of
                                       (list 1 1.0 "s" 'sym '(1) [1] ?A))))
```

```
type-of: (integer float string symbol cons vector integer)
```

注意最后一个 `?A`（字符）的类型是 **integer**，不是 `character` —— 这是第 5 节的内容。

常用谓词一览：

```elisp
42: integerp=t numberp=t floatp=nil
"abc": stringp=t  'sym: symbolp=t
nil: null=t listp=t consp=nil symbolp=t
'(1): listp=t consp=t
```

两个反直觉但正确的点：

- `nil` 同时是「空表」和「假」，所以 `listp`、`null`、`symbolp` 对它**都为真**；
  `consp`（是不是非空 cons 单元）为假。
- `(listp nil)` → `t`，但 `(consp nil)` → `nil`。判「非空列表」要用 `consp`。

## 2.2 只有 nil 是假

这是 Lisp 家族最需要记住的语义，和其他语言差别最大：

```elisp
(princ (format "0 是真是假？%S     \"\" 是真是假？%S\n"
               (if 0 "真" "假") (if "" "真" "假")))
```

```
0 是真是假？"真"     "" 是真是假？"真"
```

**`0` 和空字符串在 Elisp 里都是真**。只有 `nil`（以及等价于 `nil` 的 `'()`）是假。

导致的常见 bug 是写 `(if (string-match ...) ...)` 之外的判断时误以为 0 是假，比如
`(if (length list) ...)` —— 空列表长度为 0，这里恰好能用，但 `(if (- x y) ...)` 就是不行的。

## 2.3 字符就是整数

```elisp
?A = 65, (char-to-string ?A) = "A", (string-to-char "A") = 65
```

`?A` 读作整数 65。`(char-to-string ?A)` 得到 `"A"`，`(string-to-char "A")` 得到 65。
没有单独的字符类型，所以 `(+ ?a 1)` = 98 是合法的 —— 这在处理 ASCII 算术时很方便。

## 2.4 整数除法

```elisp
(/ 1 2) = 0, (/ 1.0 2) = 0.5, (float 1) = 1.0
```

**两个整数相除做整除**，`(/ 1 2)` 是 0。想得到小数就必须让其中一个操作数变成浮点：

```elisp
(/ 1.0 2)      ; → 0.5
(float 1)      ; → 1.0
(* 1.0 (/ 1 2)) ; 错误：先整除就晚了，结果是 0.0
```

最后一行是个典型的顺序陷阱。

## 2.5 bignum：整数不会静默溢出

```elisp
2^70 = 1180591620717411303424, most-positive-fixnum = 2305843009213693951
```

Emacs 有原生大整数。超过 `most-positive-fixnum` 之后会自动提升为 bignum，**不会**像 C 那样回绕。
这是 Python 风格而不是 C 风格 —— 写算钱的、算哈希的代码时不用再担心溢出。

## 2.6 常用常量

```elisp
t = t, float-pi = 3.141592653589793, emacs-version = "31.1"
```

写扩展时经常用到的还有 `emacs-major-version` / `emacs-minor-version`（做版本适配）、
`most-positive-fixnum`、`nil`、`t`。特别地 `t` 是**符号**，`(eq t t)` 为真，但 `(eq t 1)` 为假。

---

# 第 3 章 变量与绑定

> 示例：`examples/03-variables.el`

## 3.1 setq 与 defvar

```elisp
(defvar demo-counter 10)
(setq demo-counter 10)
```

```
setq 之后：demo-counter = 10
再次 defvar 999 之后：demo-counter = 10
```

`setq` 赋值。`defvar` 声明一个变量并给初值，但它有个**很容易踩的特性**：

> `defvar` 只在变量「还没有值」的时候才赋初值。如果变量已经有值（哪怕是上一个 `defvar` 给的），
> 再写 `(defvar demo-counter 999)` 也不会生效。

实测就是上面第二行 —— 又 `defvar` 了 999，值还是 10。这个设计是为了让用户配置不被包更新覆盖，
但写代码时如果指望「`defvar` 会重置」，就会困惑很久。想强制重置得用 `(setq demo-counter 999)`。

## 3.2 let 与 let*

```elisp
(let  ((a 1) (b 2)) ...)     ; 初值之间互相看不见，并行绑定
(let* ((a 1) (b (+ a 1))) ...) ; 后面的初值能看到前面的，串行绑定
```

```
let: 3
let*: 20
```

`let` 的初值在**外层**环境求值，所以 `(let ((a 1) (b (+ a 1))) ...)` 里的 `a` 是外层的 `a`（或未定义）。
只要初值之间有依赖关系，就用 `let*`。

## 3.3 遮蔽与恢复

```elisp
(let ((x "外层"))
  (list x (let ((x "内层")) x) x))
```

```
遮蔽：("外层" "内层" "外层")
```

内层 `let` 建立一个新的绑定，出了内层自动恢复外层 —— 这是 Lisp 里「局部状态」的基本手段，
也是为什么 Elisp 很少需要手动保存/恢复变量的值。

## 3.4 关键区别：special 变量 vs 词法绑定

这是本章最重要的一节。同一个 `let`，对「被 `defvar` 过的变量」和「普通变量」做的事完全不同：

```elisp
(defvar demo-greeting "hello world")     ; ← 被 defvar 声明过 = special 变量

(princ (format "平常：%S\n" demo-greeting))

(defun demo-shout ()                      ; 这个函数「看不见」demo-greeting 参数
  (setq demo-greeting "hi world"))

(let ((demo-greeting "unused"))           ; 对 special 变量，let 是「临时改其全局值」
  (demo-shout)
  (princ (format "let 动态绑定后：%S\n" demo-greeting)))

(princ (format "出了 let：%S\n" demo-greeting))
```

```
平常："hello world"
let 动态绑定后："hi world"
出了 let："hello world"
```

关键点：`demo-shout` **没有接收** `demo-greeting` 作为参数，但它在 `let` 里被调用时，
读到的是 `let` 绑定的那个值。这就是动态作用域（dynamic binding）。

而没被 `defvar` 声明过的变量是**词法绑定**，此时 `let` 建立的是真正的局部变量，闭包捕获它：

```elisp
(defun demo-make-adder (n)
  (lambda (x) (+ x n)))                ; 捕获的是「当时的 n」

(let ((add-5 (demo-make-adder 5))
      (add-3 (demo-make-adder 3)))
  (princ (format "闭包：(adder 10) 5 = %S, (adder 3) 4 = %S\n"
                 (funcall add-5 10) (funcall add-3 4))))
```

```
闭包：(adder 10) 5 = 15, (adder 3) 4 = 7
```

**判断规则**：只要文件第一行有 `lexical-binding: t`，并且变量没被 `defvar`/`defcustom` 声明过，
它就是词法绑定的。所以：

- 想做一个「真正的局部变量」→ 别 `defvar`，直接 `let`；
- 想做一个「可以被动态绑定的全局配置」→ `defvar`。第 17 章的「一次性 hook」就是用这个特性做的。

## 3.5 buffer-local 变量

buffer 有自己的一份变量值 —— 这是 Emacs 扩展里最常用的状态存法：

```elisp
(defvar-local demo-indent 4)     ; 声明成「buffer 局部」的
```

```
buffer 内 = 8, 默认值 = 4, 另一个 buffer = 4
```

三个概念要分清：

| 概念 | 读法 | 含义 |
|---|---|---|
| 默认值 | `(default-value 'demo-indent)` | 所有 buffer 共享的底值 |
| 当前值 | `demo-indent` | 当前 buffer 的值（可能被 buffer 局部绑定覆盖） |
| 别的 buffer 的值 | `(buffer-local-value 'demo-indent buf)` | 指定 buffer 的值 |

写扩展时的标准做法是 `(setq-local demo-indent 8)` 在 mode 函数里设，用户则通过 `setq-default`
改全局默认值。

## 3.6 boundp 与 makunbound

```elisp
boundp demo-counter = t, boundp 不存在的 = nil
```

`boundp` 检查「变量有没有值」，`fboundp` 检查「函数有没有定义」。写兼容代码时常用：

```elisp
(when (boundp 'some-new-option) ...)     ; 新版本 Emacs 才有这个变量
(when (fboundp 'some-new-function) ...)  ; 新版本 Emacs 才有这个函数
```

这是让一份扩展同时支持多个 Emacs 版本的标准手段。

---

# 第 4 章 函数

> 示例：`examples/04-functions.el`

## 4.1 基本定义与 docstring

```elisp
(defun demo-square (n)
  "返回 N 的平方。"
  (* n n))
```

```elisp
square(7) = 49
```

docstring 不是可选的装饰。`C-h f`、eldoc（把光标放在调用处时在 echo area 显示签名）、
`checkdoc`、`describe-function` 全都读它。公开函数必须写。

## 4.2 可选参数与变参

```elisp
(defun demo-greet (name &optional greeting)
  (if greeting (concat greeting ", " name "!") (concat "Hello, " name "!")))
```

```
"Hello, Emacs!" / "你好, Emacs!"
```

`&optional` 后面的参数省略时是 `nil`，所以判 `nil` 再给默认值。更麻烦的是参数多了之后位置记不住，
这时用 `cl-defun` 的 `&key`（第 9 章）会好很多。

`&rest` 把剩余参数收成一个列表：

```elisp
(defun demo-sum (&rest nums)
  (apply #'+ nums))
```

```
sum(1 2 3 4) = 10，sum() = 0
```

`(apply #'+ nil)` 是 0，所以空参调用也能正确返回 0 —— `apply` 和 `&rest` 是天生的搭档。

## 4.3 没有多返回值

Elisp 函数只有一个返回值。要返回多个值就返回 `cons` 或 `list`，再用 `let` + 解构：

```elisp
(defun demo-divmod (a b)
  "返回 (商 . 余数)。"
  (cons (/ a b) (% a b)))

(let ((r (demo-divmod 17 5)))
  (princ (format "divmod(17 5) = %S\n" r)))
```

```
divmod(17 5) = (3 . 2)
```

用 `cons` 而不是 `list` 是 Elisp 的惯例（省一层分配），取值用 `(car r)` / `(cdr r)`。
多个值则用 `pcase-let` 或 `cl-destructuring-bind` 解构。

## 4.4 lambda、funcall 与 apply

函数在 Elisp 里是**一等对象**：

```elisp
(funcall (lambda (x) (* x x)) 7)     ; → 49
(apply (lambda (a b) (+ a b)) '(1 2)) ; → 3
```

```
funcall: 42
apply:   9
apply 混着传: (1 2 3 4)
mapcar + #': (1 4 9 16)
```

区别：

- `funcall` 用固定数量的参数调用；
- `apply` 最后一个参数是**列表**，其余是散开的参数（`(apply #'list 1 2 '(3 4))` → `(1 2 3 4)`）。

## 4.5 `#'` 与 `'` 的差别

这是本章的第二个坑。对普通函数名，`#'foo` 和 `'foo` 都能用；但对 **lambda**，差别巨大：

```elisp
(mapcar #'(lambda (x) (* x x)) '(1 2 3 4))   ; 词法作用域下正确
(mapcar '(lambda (x) (* x x)) '(1 2 3 4))    ; 字节编译后可能出错
```

原因是 `'` 只是 quote，得到的列表在字节编译后**不会被当成闭包处理**，自由变量的绑定会丢失。
规则很简单：

> **lambda 一律写 `#'(lambda ...)`，或者干脆用 `(lambda ...)` 直接当参数**（不加任何 quote）。
> 用 `'` 去 quote lambda 是明确错误的。

`#'` 读作 `sharp-quote` / `function`，写成 `(function (lambda ...))` 也等价。

## 4.6 函数存在变量里：分派表

```elisp
(defvar demo-handlers
  `((add . ,#'demo-add) (mul . ,#'demo-mul)))

(funcall (cdr (assq 'mul demo-handlers)) 6 7)   ; → 42
```

```
分派表: (13 42)
```

这种「把函数存进 alist 当查表用」的写法在写扩展时很常见 —— 比一长串 `cond` 好维护，
第 16 章的字体锁、第 20 章的进程 filter 都是这个思路。

## 4.7 defalias

```elisp
(defalias 'demo-sq #'demo-square)
```

```
defalias 别名: 81, functionp = t
```

给函数起别名。两个经典用途：

- 提供更短的命令名，或改掉一个不合适的旧名字（`defalias` 保留旧名可用，用户配置不会断）；
- 用一个「你自己写的函数」覆盖内置函数，调试时很好用。

---

# 第 5 章 控制流

> 示例：`examples/05-control-flow.el`

## 5.1 if / when / unless

```elisp
(if (> n 0) "正" "负")
```

```
sign: "正" / "负" / "零"
```

`if` 只接受两个分支。**只有 then 分支时用 `when`，只有 else 分支时用 `unless`** ——
它们本身就隐含了「多表达式块」，不用自己包 `progn`：

```elisp
(when (> n 0)          ; 等价于 (if (> n 0) (progn ...) nil)
  (princ "正数\n")
  (princ "继续处理\n"))
```

## 5.2 cond

```elisp
(cond ((>= score 90) "A")
      ((>= score 60) "B")
      (t "C"))
```

```
grade: "A" / "B" / "C"
```

每个子句是 `(条件 body...)`，命中第一个为真的就执行它的 body 并返回。**最后的 `t` 子句相当于 else**。

## 5.3 if 的 then 只能有一句

```elisp
(princ (format "  %S\n"
               (if t
                   (progn (princ "  (then 分支执行了)\n") "progn 的返回值")
                 "no")))
```

```
  (then 分支执行了)
progn: "progn 的返回值"
```

`progn` 按顺序求值所有表达式并返回**最后一个**的值。如果你写了

```elisp
(if t
    (princ "a")
    (princ "b"))
(princ "c")        ;; ← 这行不在 if 里！它总会执行
```

缩进会误导你以为 `(princ "c")` 在分支里，其实不是。这是新手最常犯的错，`when` / `unless` 就是为了消掉它。

## 5.4 and / or 的短路

```elisp
(or nil 0 "" 'fallback) = 0
(and 1 2 nil 3) = nil
```

它们是「返回操作数」而不是「返回 t/nil」：

- `or` 返回**第一个真值**，全假则返回最后一个值；
- `and` 返回**第一个假值**（或者最后一个值，如果全真）。

所以 `(or nil 0 "" 'fallback)` 是 `0` 而不是 `'fallback` —— 因为 0 是真（见 2.2）。
这个特性常被拿来给默认值：`(or user-value default-value)`，但必须确认 `user-value` 的合法取值里
没有 `0` 和 `""`。

## 5.5 while

```elisp
(let ((i 0) (acc 0))
  (while (< i 5)
    (setq acc (+ acc i))
    (setq i (1+ i)))
  acc)
```

```
while: 0+1+2+3+4 = 10
```

Elisp 没有 `for`，计数循环要么自己 `setq` 计数器，要么用下面的 `dotimes`。

## 5.6 dotimes 与 dolist

```elisp
(dotimes (i 5) (princ i))          ; i = 0,1,2,3,4
(dolist (x '(1 2 3)) (princ x))    ; 遍历列表
```

```
dotimes 累加: 10
  遍历 i=0
  遍历 i=1
  遍历 i=2
dotimes 结果式: "循环结束时 i = 3"
dolist 累加: 60
```

两者都有「结果表达式」：`dotimes` 的第三个位置、`dolist` 的第三个位置，在循环结束后求值并作为返回值。

### 【坑】循环变量的绑定方式

这是写循环时最容易出错的地方。`dolist` / `dotimes` 的循环变量到底是词法绑定还是动态绑定？
**取决于它是否被 `defvar` 过** —— 和 3.4 节的规则是同一条：

```elisp
;; i 没被 defvar → 词法绑定 → 每次迭代是「新的绑定」
;; 所以下面的闭包各自捕获到自己的 i
(let (fns)
  (dolist (i '(1 2 3))
    (push (lambda () i) fns))
  (mapcar #'funcall (nreverse fns)))
```

```
dolist + 闭包: (1 2 3)
```

若 `i` 是 special 变量，同样的代码会全部捕获到**同一个** `i`，输出 `(3 3 3)`。这是一个经典陷阱，
写「给一堆元素各自挂一个回调」时必踩。

### 【坑】RESULT 表达式里不用循环变量会报警告

```elisp
;; 这样写会得到 "Unused lexical variable 'i" 警告
(dotimes (i 5 acc) (setq acc (+ acc i)))
```

因为宏展开后 `acc` 被包在 `(let ((i counter)) ...)` 里，`i` 没被用到就成了未使用变量。
想避免就让 RESULT 表达式引用它（哪怕只是打印），或者改成在 body 外返回：

```elisp
(princ (format "dotimes 结果式：%S\n"
               (let ((acc 0))
                 (dotimes (i 5 acc)      ; 让结果式用上 i
                   (setq acc (+ acc i))))))
```

## 5.7 cl-case

`cl-case` 比 `cond` 紧凑，用 `eql` 比较，适合「值等于几种情况」的分派：

```elisp
(cl-case kind
  ((1 2 3) "小数字")
  ((10 20) "整十")
  (t "其它"))
```

```
cl-case: "A 类" / "其它"
```

需要 `(require 'cl-lib)`。注意 `cl-case` 用 `eql` 比，所以字符串不能用它分派（字符串要用 `pcase` + `equal`）。

## 5.8 一个对照：cond 和 cl-case 写同一件事

```
cond 也能做同样的事: "B"
```

两者都能表达，选哪个看判据是「值的集合」还是「任意谓词」：
值的集合用 `cl-case`，涉及计算或范围的用 `cond`。

---

# 第 6 章 相等性：eq / eql / = / equal

> 示例：`examples/06-equality.el`

这一章单独成一章，是因为「比较」在 Elisp 里分了四个函数，选错不会报错，只会静默给出错误结果。

## 6.1 eq：比「同一对象」

```elisp
eq 'a 'a = t,  eq nil nil = t,  eq 1 1 = t
```

`eq` 最严格也最快：**两个参数是不是同一个内存对象**。符号、`nil`、小整数（fixnum）在 Emacs 里是
立即值或唯一对象，所以 `eq` 都能正确判断。

但对**浮点和字符串**就不行了：

```elisp
eq 两个不同的 1.0 = nil
eq 两个内容相同的字符串 = nil，equal = t
```

实测 `(eq 1.0 1.0)` 在本机是 `nil` —— 每个浮点字面量都是独立分配的对象。
字符串同理，两个内容一样的字符串是**两个对象**。

> 注意 `(eq 1.0 1.0)` 到底是 `t` 还是 `nil` 属于实现细节（不同版本、是否字节编译都可能不一样）。
> 正因为不可依赖，所以结论是：**`eq` 不用在浮点和字符串上**。

## 6.2 eql：eq 加上「数值相同且类型相同」

```elisp
eql 1.0 1.0 = t,  eql 1 1.0 = nil,  (= 1 1.0) = t
```

`eql` 修好了浮点的问题，但仍然要求类型一致：`(eql 1 1.0)` 是 `nil`。
它主要用在需要「哈希键语义」的地方 —— 比如 `cl-case`、`hash-table` 的默认比较。

## 6.3 =：只比数

```elisp
= 3 3.0 = t
```

只对数字有效，会做类型提升。**比数一律用 `=`**，不要用 `eq`/`eql`。传非数字会报
`wrong-type-argument`（这其实是好事，说明错误能立刻暴露）。

## 6.4 equal：递归比结构（日常最常用）

```elisp
equal "aa" (concat "a" "a") = t
equal (list 1 2) (list 1 2) = t
equal '(1 (2)) '(1 (2)) = t
```

`equal` 递归比较结构：字符串比内容，列表逐元素比，嵌套列表递归下去。**判断两个值「是不是一样」
就用 `equal`** —— 它是正确性优先的选择。

## 6.5 equal 会忽略文本属性

```elisp
equal = t, equal-including-properties = nil
```

一个带 face 属性的字符串和同内容无属性的字符串，`equal` 认为相等，
`equal-including-properties` 认为不等（第 11 章会详细讲文本属性）。

## 6.6 字符串专用比较

```elisp
string-equal "a" "A" = nil
compare-strings 忽略大小写 = t
```

- `string-equal`（别名 `string=`）：比内容，**区分大小写**；
- `string-prefix-p` / `string-suffix-p`：判前后缀；
- `compare-strings`：可取片段、可忽略大小写（第 5 个参数传 `t`）。

## 6.7 【重点】查找函数的默认比较方式各不相同

这是本章最实用的一张表。同一个「查 key」，不同函数用的比较函数不一样，写错了会**静默查不到**：

```elisp
(defvar demo-alist '(("name" . "emacs") ("ver" . "31")))

assoc  (equal)   找到: ("name" . "emacs")
assq   (eq)    找不到: nil
alist-get 默认 eq    -> nil
alist-get 传 equal   -> "emacs"
```

| 函数 | 默认比较 |
|---|---|
| `assoc` | `equal` |
| `assq` | `eq` |
| `alist-get` | `eq`（但可以传第 4 个参数指定别的） |
| `member` | `equal` |
| `memq` | `eq` |
| `cl-find` / `seq-contains-p` | `eql`（可传 `:test`） |

**所以：字符串做 key 的 alist，查值要用 `assoc` 或 `(alist-get k alist nil nil #'equal)`，
绝对不能用 `assq` / 默认的 `alist-get`** —— 后者永远返回 `nil`，而且不报错。这个坑非常常见。

## 6.8 排序要用比较函数，不是相等函数

```elisp
(sort '(3 1 2) #'<)
(sort '("b" "a") #'string<)
```

```
sort 数字: (1 2 3)
sort 字符串: ("a" "b")
非破坏的 seq-sort: (1 2 3)
```

`sort` 接受的是「小于」谓词，不是相等谓词。三个常用谓词：`<`（数）、`string<`（字符串）、
`string-collate-lessp`（按本地化顺序，中文/多语言场景用它）。

`sort` 是**破坏性的**（会改原列表），要保留原列表就用 `seq-sort`（第 9 章）或先 `copy-sequence`。

---

# 第 7 章 列表与关联结构

> 示例：`examples/07-lists.el`

## 7.1 cons 单元

列表不是数组，而是一条**由 cons 单元串起来的链**。每个 cons 有两个格子：`car` 和 `cdr`。

```elisp
(cons 1 2)      ; → (1 . 2)   点对：cdr 不是列表
(list 1 2 3)    ; → (1 2 3)
```

```
(cons 1 2) = (1 . 2)      <- 点对的写法
(list 1 2 3) = (1 2 3)
car = 1, cdr = (2 3)
cadr = 2, cddr = (3)  <- c[a/d]+r 可组合，最多四层
```

`(1 2 3)` 是 `(1 . (2 . (3 . nil)))` 的简写，末尾的 `nil` 就是空表。
`cadr` 是 `(car (cdr x))` 的简写，`c` 和 `r` 之间最多四个 `a`/`d`（`caadr` 可以，`cadaadr` 不行）。

## 7.2 构造

```elisp
(make-list 3 'x)              ; → (x x x)
(number-sequence 1 5)         ; → (1 2 3 4 5)
(number-sequence 1 9 2)       ; → (1 3 5 7 9)
```

```
make-list: (x x x)
number-sequence 1..5: (1 2 3 4 5)，步长 2: (1 3 5 7 9)
```

## 7.3 当栈用：push / pop

```elisp
(let ((stack nil))
  (push 1 stack)     ; → (1)
  (push 2 stack)     ; → (2 1)   注意是插到**前面**
  (pop stack))       ; → 2，stack 变成 (1)
```

```
push 两次: (2 1)，pop 出 2，剩下 (1)
```

`push` 和 `pop` 都是宏，直接改变量指向的位置。因为插在前面，从 `push` 攒出来的列表是**逆序**的，
需要正序时在最后 `(nreverse result)`。

## 7.4 取元素

```elisp
(nth 1 '(a b c d))       ; → b      下标从 0 开始
(nthcdr 2 '(a b c d))    ; → (c d)  跳过 n 个格子
(last '(a b c d))        ; → (d)    返回最后一个 cons（是个列表！）
(butlast '(a b c d))     ; → (a b c)
(car (last x))           ; 才是「最后一个元素」
```

```
nth 1 = b, nthcdr 2 = (c d), last = (d), butlast = (a b)
```

`last` 返回的是**列表而不是元素**，这个不一致非常容易写错。

## 7.5 【坑】append 与 nconc

```elisp
(append '(1 2) '(3 4))   ; → (1 2 3 4)，参数不变
(nconc  '(1 2) '(3 4))   ; → (1 2 3 4)，但第一个参数被改掉了
```

```
append: (1 2 3 4)，之后 a 仍是 (1 2)
nconc:  (1 2 3 4)，之后 a 变成 (1 2 3 4)
```

- `append` 复制除**最后一个**参数之外的所有参数（省一次复制），非破坏性，安全；
- `nconc` 直接把前一个列表的尾巴接到后一个上，破坏性、更省内存，但会**改掉前面的列表**。

写扩展时默认用 `append`。只有在明确知道那些列表是临时变量、没有别的地方引用时，才考虑 `nconc`。

## 7.6 【坑】共享结构

```elisp
(let ((x '(1 2 3)))
  (let ((y x))           ; y 和 x 是**同一个对象**
    (setcar (cdr y) 99)
    (list x y)))
```

```
改了 y 的 car 之后，x = (99 2 3)，y = (99 2 3)
```

`setq` 只复制「指针」。想让两个列表独立，必须显式复制：

- `copy-sequence`：**浅**拷贝 —— 顶层是新 cons，嵌套的子列表仍是共享的；
- `copy-tree`：**深**拷贝 —— 递归复制所有层级。

```
浅拷贝跟着变 = (1 (99))，深拷贝不变 = (1 (2))
```

这个区别在改嵌套结构（比如配置 alist）时是关键。

## 7.7 遍历与映射

```elisp
(mapcar #'1+ '(1 2 3))            ; → (2 3 4)   返回新列表
(mapc #'princ '(a b c))           ; 只做副作用，返回原列表
(mapcan (lambda (x) (list x x)) '(1 2))  ; → (1 1 2 2)  拼接结果
```

```
mapcar: (1 4 9 16)
mapcan（拼接结果）: (1 1 2 2)
mapc 只做副作用: (a b c)
```

`mapcan` 等价于 `(apply #'nconc (mapcar ...))` —— 所以它**会改掉 lambda 返回的列表**，
lambda 必须每次返回新造的列表，不能返回共享结构。

## 7.8 【坑】remove 与 delete

```elisp
remove 2: (1 3)，原列表没变: (1 2 3 2)
delete 2: (1 3)，原列表已变: (1 3)
delete 头元素必须接返回值: (2)
```

- `remove` 非破坏，返回新列表；
- `delete` 破坏，直接在原列表上摘掉节点。

`delete` 有个额外的坑：如果删的正好是**头几个元素**，它会返回一个新的开头，
而调用方手里的变量还指着老的头。所以 `delete` 必须**接收返回值**：

```elisp
(setq my-list (delete 2 my-list))    ; 正确
(delete 2 my-list)                   ; 错误：头元素被删时 my-list 仍指向旧头
```

## 7.9 alist：配置类数据的首选

元素是 `(key . value)` 的列表：

```elisp
(defvar cfg '((host . "localhost") (port . 8080)))

(cdr (assq 'port cfg))          ; → 8080
(alist-get 'port cfg)           ; → 8080  （更简洁）
(alist-get 'port cfg nil nil #'equal)   ; 字符串 key 必须加这个
```

```
alist = ((host . "localhost") (port . 8080))
assq 'port = (port . 8080)，alist-get = 8080
assoc-default = "localhost"，rassoc 反查 = (port . 8080)
```

好处是**可以重复**、可以有序、查找是 O(n) 对配置量级完全够用。代价是查找慢，
数据量大（几百条以上）要换成 `hash-table`。

`rassoc` 按 value 反查 key，`assoc-default` 直接给值（找不到返回 nil），`copy-alist` 复制。

## 7.10 plist：扁平 key value 列表

```elisp
(plist-get '(:a 1 :b 2) :a)              ; → 1
(plist-put '(:a 1) :b 2)                 ; → (:a 1 :b 2)
```

```
plist-get: 2
plist-put: (:a 1 :b 2)
```

结构是 `key1 value1 key2 value2 ...`。查找同样是 O(n)（用 `eq` 比 key，所以 **key 必须是符号**）。
符号的属性表（`(get 'sym 'prop)` / `(put 'sym 'prop val)`）就是 plist ——
第 16 章的 `derived-mode-parent` 就是这么存的。

选择建议：

| 数据结构 | 用于 |
|---|---|
| `plist` | 少量、key 是符号、临时传递参数（`&key` 展开也是 plist） |
| `alist` | 配置、可能重复、需要有序 |
| `hash-table` | 数据量大、频繁查 |

---

# 第 8 章 字符串与正则

> 示例：`examples/08-strings-regexp.el`

## 8.1 拼接与切分

```elisp
(concat "foo" "-" "bar")                    ; → "foo-bar"
(mapconcat #'identity '("a" "b" "c") ", ")  ; → "a, b, c"
(string-join '("a" "b" "c") ", ")           ; → "a, b, c"  （等价的现代写法）
```

```
concat: "foo-bar"
mapconcat: "a, b, c"
string-join 等价写法: "a, b, c"
```

## 8.2 【坑】split-string 的默认行为

```elisp
(split-string " a  b   c ")          ; → ("a" "b" "c")
(split-string "a,,b" ",")            ; → ("a" "b")     空串被丢掉
(split-string "a,,b" "," t)          ; → ("a" "" "b")  保留空串
```

```
默认（按空白、去空）: ("a" "b" "c")
按逗号切: ("a" "b" "c")
按逗号切并保留空串: ("a" "" "b" "c")
```

两个默认行为和直觉不符：默认分隔符是**空白**（不是逗号），而且**会丢掉空串**。
解析 CSV 这类数据时，**必须传第 3 个参数 `t`**，否则空字段会静默消失 —— 这是很严重的静默 bug。

## 8.3 取子串与裁剪

```elisp
(substring "hello world" 0 5)     ; → "hello"   下标从 0 开始，右开区间
(string-trim "  hi  ")            ; → "hi"      去两端空白
(string-pad "hi" 8)               ; → "hi      " 补齐到指定宽度
```

```
substring: "hello"
string-trim: "hi"
string-pad 补到 8 位: "hi      "
```

`substring` 的下标越界会被**截断**而不是报错（`(substring "abc" 0 99)` → `"abc"`）。

## 8.4 Emacs 正则的方言

Emacs 正则和 PCRE 有几处必须记住的差别：

| 需求 | Emacs 写法 | 类比 PCRE |
|---|---|---|
| 分组 | `\\(...\\)` | `(...)` |
| 或 | `\\|` | `\|` |
| 词首/词尾 | `\\<` / `\\>` | `\b` |
| 词组成字符 | `\\w` | `\w` |
| 非捕获 `(?:)` | **不支持** | — |

最大的一条：**分组要多写一层反斜杠**。原因是 `\\(` 在 Lisp 字符串字面量里正好是 `\(`。

## 8.5 string-match 与提取组

```elisp
(string-match "\\([a-z]+\\)=\\([0-9]+\\)" "version=31")
(match-string 0)    ; → "version=31"   整串
(match-string 1)    ; → "version"      第 1 组
(match-string 2)    ; → "31"           第 2 组
```

```
整串匹配: "version 31.1"
第 1 组: "31"，第 2 组: "1"
位置: 0..12
所有数字: ("31" "1" "2026")
匹配失败时 string-match 返回: nil
```

- 第 0 组是整串；
- 匹配失败返回 `nil`（**不会报错**），所以 `match-string` 前一定要判一下；
- 还可以用 `(match-beginning n)` / `(match-end n)` 取位置。

## 8.6 【坑】match-string 的全局状态

```elisp
(princ (format "所有数字: %S\n"
               (let ((start 0) (acc nil))
                 (while (string-match "[0-9]+" "v31.1 2026" start)
                   (push (match-string 0 "v31.1 2026") acc)
                   (setq start (match-end 0)))
                 (nreverse acc))))
```

```
所有数字: ("31" "1" "2026")
```

两个要点：

1. 「上次匹配」是**全局状态**。`match-string` 拿的是最近一次匹配的结果 —— 所以下面这段代码是错的：

   ```elisp
   (when (string-match "a" s1)
     (when (string-match "b" s2)     ; 这次匹配覆盖了上面
       (match-string 0 s1)))          ; 拿到的是 s2 里 b 的位置，不是 a
   ```

   要跨表达式保留，得自己 `(match-string 0 s)` 立刻存下来。

2. 循环找所有匹配，靠 `(setq start (match-end 0))` 推进。**不能写 `(1+ start)`** ——
   那会在零宽匹配上死循环。

## 8.7 【推荐】rx：用 S-表达式写正则

正则字符串写多了没人看得懂。`rx` 宏让你用 S-表达式构造，还能直接看它生成了什么：

```elisp
(rx "v" (one-or-more digit))          ; → "v[[:digit:]]+"
(rx bol (group (one-or-more (any "a-z"))) "=" (group (one-or-more digit)) eol)
```

```
rx 生成: "v[[:digit:]]+"
rx 复杂例子: "^\\([a-z]+\\)=\\([[:digit:]]+\\)$"
rx 匹配: 0
rx 取组: "31"
```

`rx` 生成的仍然是普通的正则字符串，所以能直接传给 `string-match` / `re-search-forward`。
好处是**不用记反斜杠的层数**、可读、有缩进。强烈建议新代码都用它。

常用的 `rx` 元件：

| 元件 | 含义 |
|---|---|
| `bol` / `eol` | 行首 / 行尾 |
| `digit` / `alpha` / `alnum` / `space` | 字符类 |
| `(one-or-more x)` / `(zero-or-more x)` / `(optional x)` | 重复 |
| `(group x)` | 捕获组 |
| `(or a b)` | 或 |
| `(any "abc")` / `(not (any "abc"))` | 字符集合 / 补集 |
| `(seq a b)` | 连接（列表形式默认就是 seq） |

## 8.8 字符与字符串互转

```elisp
(string-to-list "ab")      ; → (97 98)
(string-to-char "A")       ; → 65
(char-to-string 65)        ; → "A"
(number-to-string 31)      ; → "31"
(string-to-number "31")    ; → 31
```

```
string-to-list: (97 98)
string-to-number: 0，number-to-string: "31"
实际写代码里更常用 (format "%d" 31) = "31"
```

注意 `(string-to-number "abc")` 返回 **0**（不是 nil，也不报错）—— 判「转换是否失败」不能靠它。

---

# 第 9 章 序列与 cl-lib

> 示例：`examples/09-sequences.el`

## 9.1 seq.el：一套函数吃三种序列

`seq.el` 的杀手锏是**同一套函数能作用于 list、vector、string**，不用为每种类型记不同的函数名：

```elisp
(seq-map #'1+ '(1 2 3))      ; → (2 3 4)    列表
(seq-map #'1+ [1 2 3])       ; → [2 3 4]    vector
(seq-filter (lambda (c) (= c ?a)) "aaa")  ; → (97 97 97)  字符串进去，字符列表出来
```

```
seq-map list:   (2 3 4)
seq-map vector: (2 3 4)
seq-filter string: (97 97 97)
```

## 9.2 常用 seq-* 一览

```
seq-remove: (1 3)
seq-reduce: 10
seq-sort: (3 2 1)
seq-uniq: (1 2 3)
seq-position: 2
seq-contains-p: t
seq-elt / seq-length: 20 / 3
seq-take / seq-drop: (1 2) / (3 4)
seq-group-by 奇偶: ((nil 1 3) (t 2 4))
seq-do 累加: 6
```

几个特别有用的：

- `seq-take` / `seq-drop`：取前 n 个 / 丢掉前 n 个；
- `seq-group-by`：按某个函数分组，返回 alist（上面的例子里 key 是 t/nil，因为用 `cl-oddp` 分组）；
- `seq-uniq`：去重（用 `equal`）；
- `seq-reduce`：折叠，比手写 `while` 干净。

## 9.3 【坑】seq.el 大多是非破坏性的

```elisp
seq-sort 后原列表: (3 1 2)，新列表: (1 2 3)
```

`seq-sort` 返回新序列，**原列表不动** —— 这正好和 `sort` 相反（第 6.8 节）。
两个函数名这么像，语义相反，是很容易混的一对。记法：`seq-*` 一律安全，不带前缀的 `sort` /
`delete` / `nconc` 一律破坏性。

## 9.4 cl-loop：功能最强的循环

`cl-lib` 的 `cl-loop` 是 Common Lisp 的 `loop` 宏，几乎能表达所有遍历需求：

```elisp
(cl-loop for i from 1 to 5 collect (* i i))          ; → (1 4 9 16 25)
(cl-loop for i from 1 to 10 when (cl-evenp i) collect i)  ; → (2 4 6 8 10)
(cl-loop for i in '(1 2 3) sum i)                    ; → 6
(cl-loop for c across "abc" collect (char-to-string c))   ; → ("A" "B" "C")
(cl-loop for (a b) in '((1 11) (2 22) (3 33)) collect b)  ; → (11 22 33)
```

```
cl-loop collect: (1 4 9 16 25)
cl-loop 带条件: (2 4 6 8 10)
cl-loop sum: 6
cl-loop 遍历字符串: ("A" "B" "C")
cl-loop 多变量: (11 22 33)
```

常用动词（子句）：

| 子句 | 作用 |
|---|---|
| `for x in list` | 遍历列表 |
| `for i from a to b` | 数值区间 |
| `for x across seq` | 遍历 vector/string |
| `collect x` | 收集成列表 |
| `sum x` / `count x` / `maximize x` | 聚合 |
| `when c` / `unless c` | 过滤 |
| `do x` | 只做副作用 |
| `while` / `until` / `thereis` / `always` | 控制 |

它比 `dolist` + 手工累加干净很多，值得花点时间熟悉。

## 9.5 cl-lib 的其他常用件

```elisp
(cl-incf n)          ; 原地自增，可加步长
(cl-case kind ...)   ; 见 5.7
```

```
cl-incf 之后 n = 6
```

`cl-incf` / `cl-decf` 是宏，直接改地方（`(cl-incf (aref v 0))` 也能用）。

## 9.6 cl-defstruct：带名字的结构

```elisp
(cl-defstruct demo-point x y)     ; 自动生成 demo-point-p / demo-point-x / 构造器等
(setq p (make-demo-point :x 3 :y 4))
(demo-point-x p)                  ; → 3
```

```
结构: #s(demo-point 3 4), x = 3, 判定 = t
setf 风格改字段后: #s(demo-point 13 4)
copy 出的副本: #s(demo-point 13 4)
```

生成的东西：`make-demo-point`（构造器，支持 `:x` `:y` 关键字）、`demo-point-p`（判定）、
`demo-point-x` / `demo-point-y`（访问器，可 `setf`）、`copy-demo-point`（拷贝）、
`demo-point-p` 打印成 `#s(demo-point 3 4)`。

它比 alist 更适合「数据结构固定」的场景：有类型判定、有名字、`%S` 打印可读。

## 9.7 cl-defun 的 &key

参数多了之后 `&optional` 的位置陷阱很痛：

```elisp
(defun demo-connect (host &optional port user scheme) ...)
;; 只想改 user 也得写全前面三个 (demo-connect "h" nil "me")

(cl-defun demo-connect (host &key (port 22) (user "root") scheme) ...)
(demo-connect "h1" :user "me")    ; 只写要改的
```

```
"root@h1:22" / "me@h1:80"
```

`&key` 让调用点自解释，还支持默认值 `(port 22)`。代价是每个参数多两个字节的开销，
但可读性提升明显，参数超过 3 个就值得用。

## 9.8 cl-letf：临时改写函数或变量

测试里 mock 的标准手段：

```elisp
(cl-letf (((symbol-function 'demo-slow-call) (lambda (&rest _) "fake")))
  (demo-slow-call))     ; 用假的
;; 出了 let 自动恢复
```

```
cl-letf 临时改值: 42
```

它同时能改函数和变量（`(cl-letf (((symbol-function 'f) ...)) ...)` 改函数，
`(cl-letf ((var value)) ...)` 改变量）。第 25 章的测试用的就是这个。

---

# 第 2 部分 编辑器数据结构

到这里语言部分讲完了。接下来是 Emacs 的三个核心对象 —— **buffer**、**文本属性/overlay**、
**文件**。写扩展和写普通 Lisp 程序最大的分界就在这儿：这些对象有状态、有生命周期、
有「当前」的概念（`current-buffer`、`current-local-map`……），必须理解透彻。

# 第 10 章 buffer 与 point

> 示例：`examples/10-buffers.el`

## 10.1 buffer 是一等公民

**Emacs 里文本不是「在文件里」，而是在 buffer 里**。文件只是 buffer 的一个可选关联（第 12 章）。
这个观念转换很重要 —— 扩展操作的对象绝大多数是 buffer。

```elisp
(with-temp-buffer
  (insert "hello\n")
  (buffer-string))
```

```
当前 buffer: "*scratch*"，所有 buffer 数: 4
```

`with-temp-buffer` 造一个用完即焚的临时 buffer，是所有扩展测试代码的标配。它保证：

- 不污染用户正在编辑的 buffer；
- 退出时自动 kill、自动恢复原来的 `current-buffer`；
- 可以嵌套。

## 10.2 point：位置是一个 1 开始的整数

```
插入后 point = 7（停在新文本之后）
point-min = 1, point-max = 7, bobp = t
到末尾: point = 7, eobp = t
```

- **point 从 1 开始**（不是 0）。`(point-min)` 是 1，`(point-max)` 是 `(buffer-size) + 1`；
- 插入文本后 point 停在**新插入内容之后**；
- `bobp` / `eobp` 判「在开头/结尾」。

「位置」和「字符」的区别：`point-max` 是个合法位置但**没有字符**（它是末尾之后）。
所以访问 `(char-after (point-max))` 是 `nil`。

## 10.3 移动

```
下移一行后 point = 5，当前行 = "bbb"
```

```elisp
(goto-char 5)              ; 绝对位置
(forward-char 2)           ; 相对移动
(forward-line 1)           ; 下移一行，返回「还剩几行没移动」（0 表示成功）
(line-beginning-position)  ; 行首
(line-end-position)        ; 行尾
```

`forward-line` 的返回值是「剩余行数」，比它移动的位置更有用 —— 判「有没有真的移动成功」靠它。

## 10.4 取内容

```elisp
(buffer-string)                    ; 整个 buffer
(buffer-substring 1 6)             ; 区间 [1,6)
(buffer-substring-no-properties 1 6) ; 不带文本属性（第 11 章）
```

```
buffer-substring 1..6 = "hello"
```

## 10.5 查找替换

```elisp
(goto-char (point-min))
(when (re-search-forward "THIS")
  (replace-match "that"))     ; 替换「刚匹配的那段」
```

```
re-search-forward 找到 id="42"，point 现在在 6
looking-at 从当前位置匹配: t
```

关键点：`re-search-forward` **把 point 移到匹配的末尾**，`replace-match` 替换的正是这段。
所以两者天然配对。要拿匹配位置用 `(match-beginning 0)` / `(match-end 0)`。

其他搜索函数：

| 函数 | 行为 |
|---|---|
| `search-forward` | 找字面字符串 |
| `re-search-forward` | 找正则，point 停在匹配末尾 |
| `re-search-backward` | 往回找，point 停在匹配开头 |
| `looking-at` | 从**当前位置**试匹配，**不移动** point |
| `looking-back` | 往回试匹配（有性能注意点） |

`replace-match` 的坑：替换字符串里 `\` 和 `\&` 有特殊含义（引用捕获组），
想要字面反斜杠要写 `\\\\`。安全做法是用第 4 个参数：

```elisp
(replace-match "字面\\文本" t t)     ; 第 4 个参数 t = 不当正则处理替换串
```

## 10.6 【核心】save-excursion

```elisp
(save-excursion
  (goto-char (point-min))
  ...)                  ; 退出时 point 自动还原
```

```
save-excursion 之后 point 还原到 8
```

这是写扩展时**最常用的宏**。它保存的不只是 point：

- **point 和 mark**；
- **当前 buffer**（所以里面 `set-buffer` 也会被还原）；
- **narrowing 状态**（下一节）。

所以「我要跳到别处做点事然后回来」一律用 `save-excursion`，不要手工记位置 —— 出错时（比如中途
signal 了错误）手工方案不会还原，`save-excursion` 会。

## 10.7 narrowing

把 buffer 逻辑上「裁」成一段，之后所有读写都只看这一部分：

```elisp
(save-restriction
  (narrow-to-region start end)
  ...)                 ; 退出自动恢复
```

```
narrow 之后 point-min=7 point-max=13 只看到="B1
还原之后又能看全: "A1
```

`save-restriction` 保存/恢复 narrowing。`save-excursion` 也会还原 narrowing，
但**语义上更明确的写法是 `save-restriction`** —— 两者嵌套时可以写得更清楚。

> narrowing 期间 `point-min` / `point-max` 会变，所以任何依赖绝对位置的代码在 narrowing 下都可能出错。
> 这也是为什么很多扩展会先 `(widen)`。

## 10.8 在别的 buffer 里干活

```elisp
(with-current-buffer "some-buffer"
  (buffer-string))                 ; 这里的「当前 buffer」是它

(let ((buf (get-buffer-create "demo")))
  (with-current-buffer buf
    (erase-buffer)
    (insert "内容"))
  buf)                             ; 返回 buffer 对象
```

```
名字="demo-work" 内容="工作在别的 buffer"
回到主 buffer: "*scratch*"，它还在吗: t
新建 buffer: "*demo-scratch*"，再取一次同一个对象: t
```

- `with-current-buffer` 是**宏**，退出自动恢复，优先用它；
- 对应地 `set-buffer` 是**函数**，不恢复 —— 只有在你确定后面要一直待在那儿时才用；
- `get-buffer` 找不到返回 `nil`，**`get-buffer-create` 会新建**。这个区别很重要：
  用错了会意外创建一堆垃圾 buffer。

## 10.9 小结表

| 需求 | 用什么 |
|---|---|
| 临时干活不污染 | `with-temp-buffer` |
| 跳到别处做完再回来 | `save-excursion` |
| 只看一段 | `narrow-to-region` + `save-restriction` |
| 在另一个 buffer 里干活 | `with-current-buffer` |
| 拿全部文本 | `buffer-string` |
| 拿一段文本 | `buffer-substring`（不去属性）/ `buffer-substring-no-properties` |

---

# 第 11 章 文本属性与 overlay

> 示例：`examples/11-text-properties.el`

这是「怎么给文本加高亮/链接/隐藏」这一整类功能的底层机制。Emacs 里有两套：**文本属性** 和 **overlay**。
它们的区别只有一条，但决定了该用哪个。

## 11.1 文本属性：粘在字符上

```elisp
(let ((s (propertize "重要" 'face 'bold)))
  s)
```

```
带属性字符串: #("重要" 0 2 (face bold))
取属性 face = bold，取不存在的 = nil
```

属性是 `(key . value)` 对，跟着**字符**走。在 buffer 里加：

```elisp
(put-text-property 1 3 'face 'error)         ; 区间 [1,3)
(add-text-properties 1 3 '(face error help-echo "点我"))
```

```
KEYWORD 首字符的 face = error，普通字符的 face = nil
属性变化点: 7
```

## 11.2 【坑】equal 忽略文本属性

```
equal = t，equal-including-properties = nil
```

一个带 face 的和一个不带 face 的同内容字符串，`equal` 认为相等。这在测试里会造成
「明明 face 没加上，测试却过了」的情况。要验属性用 `equal-including-properties`，或者直接查
`(get-text-property pos 'face)`。

## 11.3 【关键区别一】属性跟着字符走

```elisp
(let ((s (propertize "重要" 'face 'bold)))
  (concat s "后面"))
```

```
后面紧插的文本继承了属性: face@3 = nil
```

复制/拼接时属性会跟着字符一起移动。有意思的是「插入」时的继承规则：
**从带属性的字符后面插入，新文本会继承属性**；从前面插入则不继承 —— 所以这里 `face@3` 是 `nil`。

想彻底去掉属性：`substring-no-properties` / `(buffer-substring-no-properties ...)` /
`remove-text-properties`。

```
去掉属性后: "重要"，equal-including-properties = t
```

## 11.4 【关键区别二】overlay 是位置上的对象

overlay 不属于字符，它是**一个 (起, 止) 区间上的独立对象**：

```elisp
(let ((ov (make-overlay 3 6)))
  (overlay-put ov 'face 'highlight)
  (move-overlay ov 1 3)          ; 移动的是区间，不碰文本
  (delete-overlay ov))
```

```
overlay 范围 = 3..6，face = highlight
move 之后 = 1..3
查询 buffer 位置 2 上的 overlay: 1 个
删除后 overlays-at 2: 0 个
help-echo = "点我"
```

overlay 的常用属性：`face`、`display`（替换显示内容）、`invisible`、`help-echo`（悬停提示）、
`before-string` / `after-string`（在区间前后插显示内容，不影响 buffer 文本）、
`evaporate`（空了就自动删）、`priority`（重叠时谁在上面）。

## 11.5 什么时候用哪个

| 场景 | 用 | 理由 |
|---|---|---|
| 语法高亮（跟着词走） | 文本属性 | 编辑时自动跟着文本移动 |
| 临时高亮（搜索命中、选中） | overlay | 编辑时位置不跟着跑（通常正是想要的） |
| 给整行加个图标/箭头 | overlay + `before-string` | 不污染 buffer 内容 |
| 折叠/隐藏一段 | overlay + `invisible` | 可随时开关 |
| 链接（可点击） | 文本属性 + `keymap`/`mouse-face` | 要跟字符走 |

实际项目里两者常混用：font-lock 用文本属性，`hl-line` / `isearch` / `flymake` 用 overlay。

## 11.6 常用属性名

```
help-echo = "点我"
长度不受显示影响: 3
```

| 属性 | 作用 |
|---|---|
| `face` | 字体/颜色（第 16 章的字体锁就是加这个） |
| `font-lock-face` | 同上，但会被 font-lock 管理 |
| `invisible` | 不显示 |
| `display` | 用别的内容替换显示 |
| `help-echo` | 鼠标悬停时的提示（也可以是函数，动态生成） |
| `keymap` | 这段文本上的局部按键绑定 |
| `mouse-face` | 鼠标悬停时的高亮 face |
| `read-only` | 这段文本不可修改 |
| `field` | 把一段文本当作一个整体（比如按钮） |

## 11.7 【坑】invisible 只是不显示

```
长度不受显示影响: 3
```

`invisible` 的文本**仍然在 buffer 里**：`buffer-string` 拿得到、`buffer-size` 算它、`point` 会走进去、
正则能匹配到。所以「用 invisible 实现折叠」时，所有遍历 buffer 的代码都要额外处理它
（看 `buffer-invisibility-spec`）。这一点很多人会想当然搞错。

---

# 第 12 章 文件与目录

> 示例：`examples/12-files.el`

## 12.1 【坑】相对路径相对谁

```
default-directory = "~/code/programming/emacs/build/"
```

这是本章第一条也是最重要的一条：**相对路径是相对 `default-directory` 解析的，而它是每个 buffer 一份的**。
所以同一段代码在不同 buffer 里跑，可能读写完全不同的文件。

```elisp
(expand-file-name "data.txt")     ; 相对当前 default-directory
(expand-file-name "data.txt" "/tmp/")   ; 相对指定目录
```

写扩展时的纪律：**只在 `default-directory` 明确的时候用相对路径**，否则一律传绝对路径，
或者显式 `let` 一下：

```elisp
(let ((default-directory "/tmp/"))
  (write-region ... "out.txt"))    ; 确定写到 /tmp/out.txt
```

## 12.2 路径运算：file-name-*

这些全是**纯字符串运算，不碰磁盘**，所以在文件不存在时也能用：

```elisp
(file-name-directory "/tmp/a/report.tar.gz")   ; → "/tmp/a/"
(file-name-nondirectory "...")                 ; → "report.tar.gz"
(file-name-extension "...")                    ; → "gz"
(file-name-sans-extension "...")               ; → "/tmp/a/report.tar"
(file-name-base "...")                         ; → "report"
(file-name-as-directory "/tmp/a")              ; → "/tmp/a/"
(file-name-relative "/tmp/a/b.txt" "/tmp/a/")  ; → "b.txt"
(expand-file-name "data.txt" "/tmp/emacs-demo") ; → "/tmp/emacs-demo/data.txt"
```

```
文件名: "report.tar.gz"
扩展名: "gz"，去掉扩展名: "/tmp/emacs-demo/sub/report.tar"
换扩展名: "/tmp/emacs-demo/sub/report.tar.zip"
拼路径: "/tmp/emacs-demo/data.txt"
取相对路径: "a.txt"
```

注意 `file-name-extension` 只取**最后一个**点之后的部分（`report.tar.gz` → `gz`）。

## 12.3 判断文件状态

```elisp
(file-exists-p path)
(file-directory-p path)
(file-regular-file-p path)
(file-readable-p path)
(file-writable-p path)
```

```
本文件存在: t，/tmp 是目录: t
```

## 12.4 一次性写文件：with-temp-file

```elisp
(with-temp-file "/tmp/x.txt"
  (insert "第一行\n")
  (insert (format "写于 Emacs %s\n" emacs-version)))
```

```
写入 ".../hello.txt"，大小 28 字节
读回内容: "第一行
写于 Emacs 31.1
"
嵌套写入成功: t
```

`with-temp-file` 新建一个临时 buffer，执行 body，然后**把 buffer 内容原子性地写进文件**
（先写临时文件再 rename，所以不会因为中途崩溃留下半个文件）。

但它**不会自动创建父目录** —— 父目录不存在就直接报错。需要自己先建：

```elisp
(make-directory (file-name-directory path) t)   ; 第二个参数 t = 递归创建
```

## 12.5 读文件

```elisp
(with-temp-buffer
  (insert-file-contents "/tmp/x.txt")     ; 读进当前 buffer
  (buffer-string))

(with-temp-buffer
  (insert-file-contents "/tmp/x.txt" nil 0 10)   ; 只读前 10 个字节
  ...)
```

`insert-file-contents` 的参数是 `(file &optional visit beg end replace)`，后两个可以只读一段。

## 12.6 写一段区域：write-region

```elisp
(write-region start end filename)          ; 写 buffer 的 [start,end) 到文件
(write-region start end filename t)        ; 第 5 个参数 t = **追加**
```

```
追加后内容: "第一行
写于 Emacs 31.1
追加的一行
"
```

`write-region` 比 `with-temp-file` 底层：它不新建 buffer，直接把**指定区域**写出去。
追加模式（第 5 个参数）是它独有的能力。

## 12.7 遍历目录

```elisp
(directory-files dir)                  ; 含 "." 和 ".."
(directory-files dir t "\\.txt\\'")    ; t = 返回绝对路径；正则匹配文件名
(directory-files-recursively dir "\\.el\\'")   ; 递归
```

```
目录内容（含 . 和 ..）: ("." ".." "hello.txt" "nested")
只要 .txt（正则 + 不要 . ..）: (".../hello.txt")
递归全部文件: ("note.txt" "deep" "nested" "hello.txt")
```

坑在默认行为：`directory-files` **不过滤 `.` 和 `..`**，也不过滤目录。所以遍历时要：

```elisp
(directory-files dir t "\\`[^.]")     ; 用锚定的正则排除点开头的
```

## 12.8 「访问文件」≠「读文件」

```elisp
(let ((buf (find-file-noselect "/tmp/x.txt")))
  ...)
```

```
buffer 名 = "hello.txt"，关联文件 = ".../hello.txt"，已修改 = nil
```

`find-file-noselect` 返回**与该路径关联的 buffer**，如果之前已经打开过就复用同一个 buffer。
它不切换窗口。这是扩展里要「拿到文件对应的 buffer」时的正确函数 ——
`find-file` 会真的切窗口，不适合在后台代码里调。

相关函数：`(buffer-file-name buf)` 拿 buffer 关联的文件，`(file-name-base ...)` 拿 buffer 名。

## 12.9 复制、重命名、删除

```elisp
(copy-file from to)              ; 第三个参数 t = 覆盖已存在的
(rename-file from to)
(delete-file path)               ; 删文件
(delete-directory path)          ; 删目录（第 2 个参数 t = 递归）
(make-directory path t)          ; 建目录（t = 递归）
```

```
重命名后目录: ("hello.txt" "renamed.txt")
清理后目录还在吗: nil
```

## 12.10 临时文件

```elisp
(make-temp-file "prefix-")       ; 返回一个新建的唯一文件路径
(temporary-file-directory)       ; 系统的临时目录
```

```
temporary-file-directory = "/var/folders/.../T/"
user-emacs-directory = "~/.emacs.d/"
```

**规矩：示例/测试自己造的临时文件必须自己删干净。** 本仓库的 `12-files.el` 和 `26-todo-demo.el`
都在最后一步清理，并且把「清理完成」也作为输出打印出来 —— 这样万一清理失败，输出对不上，
验证脚本会发现。

`user-emacs-directory` 是用户配置目录，扩展放数据的标准位置（`{user-emacs-directory}/你的包名/`）。

---

# 第 3 部分 扩展的接入点

前面两部分是「素材」，这一部分讲**怎么挂进 Emacs**。一个扩展能做的事，说到底就是往这几个地方
注册东西：命令（`interactive`）、按键（keymap）、模式（mode）、事件（hook）、选项（`defcustom`）、
以及包装已有函数（advice）。这七章一章一个接入点。

# 第 13 章 交互式命令

> 示例：`examples/13-interactive.el`

## 13.1 interactive：把函数变成命令

一个普通的 `defun` 不能用 `M-x` 调用。要变成命令，函数体第一句写 `(interactive)`：

```elisp
(defun demo-hello ()
  "打个招呼。"
  (interactive)
  (message "Hello, Emacs!"))
```

```
1) 无参命令：
   是命令吗：t
```

`(interactive)` 的作用是**告诉 Emacs 参数从哪来** —— 从键盘、从 minibuffer 提示、从当前选区。
`commandp` 判断一个函数是不是命令。

## 13.2 参数提示码

`interactive` 的字符串里，每个字符代表一个参数的来源：

| 码 | 参数类型 | 提示什么 |
|---|---|---|
| `s` | 字符串 | 在 minibuffer 里输入 |
| `n` | 数字 | 输入一个数，Emacs 保证是真数字 |
| `p` | 数字 | **前缀参数**（`C-u 5` → 5，没按 → 1） |
| `P` | 原始前缀 | `C-u` → `(4)`，没按 → `nil` |
| `r` | 两个整数 | 选区的起点和终点 |
| `f` / `F` | 文件名 | 已存在 / 可以是新文件 |
| `D` | 目录名 | — |
| `b` | buffer 名 | 已存在的 buffer |
| `d` | 位置 | 一个 point 位置 |
| `m` | mark | 当前 mark |

实测：

```
2) "s" 字符串参数：
    -> 你好, Emacs!
3) "n" 数字参数：
    -> 21 * 2 = 42
5) "r" 选区参数：
    -> 选区 [1, 6) 共 5 个字符
6) "f" 文件参数：
    -> 文件 /tmp 存在: t
```

提示串的写法有约定：**以冒号 + 空格结尾**，比如 `"你的名字: "`。这是 `checkdoc` 会检查的，
也是让提示在读起来自然的关键。

## 13.3 【重点】p 与 P 的区别

这是写命令时最容易搞错的一对：

```
4) "p" / "P" 前缀参数：
    -> p 收到: 1（没按 C-u 时是 1）
    -> p 收到: 4（没按 C-u 时是 1）
    -> P 收到: nil，转成数字是 1
    -> P 收到: (4)，转成数字是 4
```

- **`p`** 给的是一个**数字**，没按前缀参数时是 `1`（不是 nil！）。适合「重复 N 次」这种场景。
- **`P`** 给的是**未经处理的原始值**：没按时是 `nil`，`C-u` 时是 `(4)`，`C-u 5` 时是 `5`。
  适合需要区分「用户到底按没按前缀」。

想让 `P` 也拿到数字，用 `(prefix-numeric-value arg)` 转换。

## 13.4 用代码算参数

参数需要计算时，`interactive` 可以是一个表达式而不是字符串：

```elisp
(defun demo-upcase-region ()
  "把选区转成大写。"
  (interactive)
  (let ((beg (if (use-region-p) (region-beginning) (point-min)))
        (end (if (use-region-p) (region-end) (point-max))))
    (upcase-region beg end)))
```

```
7) 自定义参数计算：
    -> 已转换 11 个字符
```

形式是 `(interactive (list 表达式1 表达式2 ...))`，列表的每个元素依次对应一个参数。

## 13.5 区分「被 M-x 调用」还是「被 Lisp 调用」

```elisp
(defun demo-fn (&optional x)
  (interactive "sX: ")
  (if (called-interactively-p 'interactive)
      (message "人调用的，X = %s" x)
    "被 Lisp 调用"))
```

```
8) interactive-form: (interactive "s你的名字: ")
   普通函数: nil
    -> 被 Lisp 调用，X = abc
```

`called-interactively-p` 在需要「交互时弹提示、程序调用时静默」的场景很有用。
`interactive-form` 则能取出命令的 interactive 声明，元编程时会用到（比如自动生成文档）。

## 13.6 【坑】忘写 interactive

```
10) 没写 interactive 的函数：commandp = nil
```

函数能正常定义、能被别的 Lisp 调用，但 `M-x` 里找不到它，绑到按键上也没反应。
**这是「代码看起来没问题但 M-x 找不到」的头号原因。**

## 13.7 命令的 docstring 有额外规范

因为命令会出现在 `M-x` 的补全列表和 `C-h f` 里，docstring 的**第一行必须是完整的一句话**，
而且要能独立看懂。`checkdoc` 会检查这些。示例：

```elisp
(defun demo-do-a ()
  "命令 A。"
  (interactive))
```

---

# 第 14 章 keymap 与按键绑定

> 示例：`examples/14-keymaps.el`

## 14.1 kbd：把「人写的按键」编译成 Emacs 内部表示

```elisp
(kbd "C-c x")      ; 两个元素的 key 序列
(kbd "M-x")
(kbd "C-<tab>")
(kbd "RET")
```

```
kbd "C-c x"   = "C-c x"（内部是 2 个元素的序列）
kbd "M-x"     = "M-x"
kbd "C-<tab>" = "C-<tab>"
kbd "RET"     = "RET"
kbd "C-M-s"   = "C-M-s"
kbd "<f5>"    = "<f5>"
```

`kbd` 是**宏**，参数必须是编译期已知的字符串常量。写按键就用它，**不要手写
`[?\C-c ?x]` 这种向量** —— 前者可读、跨平台一致（`RET` vs `\r`），后者容易写错。

> **注意** 上面那些 `= "C-c x"` 是 `key-description` 的输出。如果你用 `%S` 直接打印 `(kbd "C-c x")`，
> 得到的是含原始控制字节的 `"^Cx"` —— 这正好触发第 0.3 节的「控制字符」判定，所以展示键序列一律
> 先过 `key-description`。

## 14.2 keymap 就是一个 list

```
空 keymap: (keymap)
绑定后: (keymap (3 keymap (98 . demo-do-b) (97 . demo-do-a)))
```

car 是符号 `keymap`，后面的条目形如 `(字符 . 命令)` 或 `(字符 keymap ...)`（子前缀）。
看懂这个结构对调试很有帮助 —— 遇到「按键不生效」时直接打印 keymap 就能看出问题。

## 14.3 绑定与查询

```elisp
(define-key demo-map (kbd "C-c a") #'demo-do-a)
(lookup-key demo-map (kbd "C-c a"))        ; → demo-do-a
(lookup-key demo-map (kbd "C-c z"))        ; → nil
```

```
lookup "C-c a" = demo-do-a，"C-c z" = nil
```

- `define-key` 绑定；绑到 `nil` 就是解绑；
- `lookup-key` 只在**一个** keymap 里查，找不到返回 `nil`（不会往上找父 map）；
- 想查「在当前 buffer 里最终会执行什么」，用 `key-binding`（见 14.6）。

## 14.4 前缀键

```
define-prefix-command: find-file
前缀下的绑定: demo-do-a / demo-do-b
```

`C-c` 就是一个前缀 —— 一个键下面挂着一整棵子 keymap。定义自己的前缀：

```elisp
(define-prefix-command 'demo-map)
(define-key global-map (kbd "C-c d") 'demo-map)   ; C-c d 变成前缀
(define-key demo-map (kbd "r") #'demo-run)        ; 于是 C-c d r
```

`C-c` 后跟一个字母（`C-c a` 到 `C-c z`，不加其他修饰）是**保留给用户**的，
扩展**不应该占用**（见 14.9）。

## 14.5 keymap-parent：继承

```elisp
(set-keymap-parent child-map parent-map)
```

```
子 map 继承来的绑定: demo-do-a
```

子 map 里查不到的键会到父 map 里找。`define-derived-mode` 生成的 keymap 就自动把 parent 设成了
父 mode 的 keymap —— 这是「新 mode 自动拥有父 mode 所有按键」的实现方式。

## 14.6 【重点】一次按键到底触发谁

查询顺序（从高到低）：

1. 当前启用的 **minor mode** 的 keymap（按 `minor-mode-map-alist` 的顺序，后启用的优先）
2. 当前 buffer 的 **local keymap**（major mode 的 keymap）
3. **global-map**

实测：

```
global-map 里 C-x C-f 绑的是: find-file
global-set-key 之后: demo-do-a
local map 生效: demo-do-b
local-set-key 之后: demo-do-b
```

同一个键既在 local 又在 global 绑了，**local 赢** —— 这就是为什么 mode 可以覆盖全局快捷键。
想知道某个键最终执行什么：

```elisp
(key-binding (kbd "C-x C-f"))    ; → find-file
```

## 14.7 绑定到 global / local

```elisp
(global-set-key (kbd "C-c g") #'demo-do-a)       ; 全局
(local-set-key  (kbd "C-c l") #'demo-do-b)       ; 当前 buffer
```

扩展的纪律：**不要随便 `global-set-key`**。它会污染用户的全局环境并且和别的包冲突。
正确做法是定义自己的 map，然后挂到某个 mode 的 keymap 或 minor mode 上。

## 14.8 解绑与屏蔽

```elisp
(define-key map (kbd "C-c x") nil)          ; 解绑（回到继承来的绑定）
(define-key map (kbd "C-c x") #'undefined)  ; 屏蔽（彻底不响应，也不往上找）
```

```
解绑后 lookup = nil
```

区别在于：绑到 `nil` 只是删掉这一层的绑定，查询会继续往上找父 map；
绑到 `#'undefined` 则明确表示「这个键就是要无效」。

## 14.9 【坑】C-c + 单个字母是用户的

Emacs 官方约定：

| 键区 | 归属 |
|---|---|
| `C-c` + 字母 | **用户**保留（用户自己的快捷键） |
| `C-c C-<字母>` | 给 major mode 用 |
| `C-c` + 非字母字符 | 给少数特例（`C-c /` 之类） |

所以你的扩展要绑键，应该用 `C-c C-x` 这种**带修饰**的形式，或者自己造前缀（`C-c d` 那种）。
占用 `C-c a` 会和用户的配置打架，而且用户会很不高兴 —— 这是社区里有共识的礼节。

```
global-map 里 C-x C-f 绑的是: find-file
```

## 14.10 给用户提示

```elisp
(substitute-command-keys "\\[find-file]")
```

```
去掉属性之后: "C-x C-f"
```

`substitute-command-keys` 把 docstring 里的 `\[命令名]` 替换成**用户当前实际绑定的键**。
所以写 docstring 时应该写：

```elisp
(defun demo-run ()
  "运行当前项。\\[demo-run] 可以重新运行。"
  (interactive))
```

用户改了绑定之后，docstring 里显示的也是改后的键 —— 这比自己写死 `C-c r` 好得多。

```
命令的 docstring: "命令 A。"
```

> `substitute-command-keys` 会往字符串上加 `help-key-binding` 属性（好让 `C-h f` 里显示成一个
> 按钮）。想在纯文本输出里用，要先 `substring-no-properties` 去掉属性。

---

# 第 15 章 minor mode

> 示例：`examples/15-minor-mode.el`

minor mode 就是「一个可以开关的附加功能」。绝大多数「我给 Emacs 加了个小功能」的场景，
正确的形态就是一个 minor mode。

## 15.1 define-minor-mode 一次生成四样东西

```elisp
(define-minor-mode demo-lint-mode
  "检查当前 buffer 的拼写。"
  :lighter " Lint"
  :keymap demo-lint-mode-map
  (if demo-lint-mode
      (demo-lint-start)
    (demo-lint-stop)))
```

生成的是：

1. **`demo-lint-mode` 函数** —— 也就是 `M-x demo-lint-mode` 这个命令，负责开关；
2. **`demo-lint-mode` 变量** —— 布尔状态，`t` 表示开着。**它就是状态本身，别另外再定义一个布尔量**；
3. **`demo-lint-mode-map`** —— 由 `:keymap` 指定的按键表；
4. **`demo-lint-mode-hook`** —— 开关时运行的 hook。

```
minor-mode-map-alist 里有没有 demo-lint-mode: (demo-lint-mode keymap (3 keymap ...))
minor-mode-alist（mode-line 显示）: (demo-lint-mode " Lint")
```

`:lighter` 是 mode-line 上显示的名字，**推荐前面加一个空格**（`" Lint"`），否则会和前一个指示器粘在一起。

## 15.2 buffer-local：一个 buffer 开不影响别的

```
  demo-lint-mode 已打开，buffer = "demo-a"
A 里: t，keymap 命中: 1
B 里: nil（不受影响）
```

默认 `define-minor-mode` 生成的变量是 buffer-local 的 —— 这正是「minor mode」的本意：
它是**当前 buffer 上**的一个附加状态。

## 15.3 body 里同时写开关两支

```
  demo-lint-mode 已关闭，buffer = " *temp*"
关闭后: nil
```

body 在**每次切换时**执行一次，`demo-lint-mode` 变量已经是新值。所以标准写法是：

```elisp
(defun demo-lint-toggle-body ()
  (if demo-lint-mode
      (add-hook 'after-change-functions #'demo-lint-check nil t)   ; 开：装东西
    (remove-hook 'after-change-functions #'demo-lint-check t)))    ; 关：拆干净
```

> **注意 add-hook 的 LOCAL 参数**。minor mode 的 body 是 buffer 局部的，所以它装的 hook
> 也应该用 `(add-hook ... nil t)` 装成 buffer 局部的 —— 否则关掉这个 buffer 的 mode 时会把
> **所有** buffer 的 hook 一起删掉。

## 15.4 :global t

```
  全局 mode 现在是: t
全局开关: t, 计数 = 1
```

```elisp
(define-minor-mode demo-global-mode
  "全局生效的 mode。"
  :global t
  (if demo-global-mode (demo-start) (demo-stop)))
```

区别：全局 mode 的变量**不是** buffer-local，一个开关控制所有 buffer。
它适合「影响整个 Emacs 的行为」（比如 `global-flycheck-mode`），不适合「这个文件要不要检查」。

> 【坑】`:global t` 时，`define-minor-mode` 会把开关变量定义成一个 special 变量，
> 所以你要在 body 里对它做操作时别用 `let` 去「临时改」—— 那会改到全局值。

## 15.5 【坑】keymap 变量名必须严格匹配

```
kill-all-local-variables 会连 minor mode 一起关掉
```

- keymap 变量名必须是 `<mode 名>-map`，**一个字都不能差**；
- `kill-all-local-variables` 会把所有 buffer-local 的 minor mode 关掉 —— 这通常是你想要的
  （切 mode 时旧功能的残留会清掉）。但如果你**不希望**它被关，就得在 mode 的 body 里处理，
  或者用 `(put '<mode> 'permanent-local t)`。

## 15.6 【坑】body 里不要写 message

mode 会在**每个** buffer 里各跑一次（比如切 mode、`kill-all-local-variables` 时），
如果 body 里有 `(message ...)`，用户会看到一堆莫名其妙的回显，而且会污染你的 batch 输出。
要调试就写进 `*Messages*` 之外的地方，或者用 `(message nil)` 清空。

## 15.7 更轻量的选择

```
已定义的 minor mode 里含 demo-lint-mode: t
```

如果只是想给几个键加绑定、不需要开关状态，**不一定要写 mode**。两个更轻的方案：

- 直接用 `with-eval-after-load` + `define-key`（第 24 章）；
- 用 `local-set-key` 在某个 hook 里绑。

只有需要「用户能开关」「有状态」「mode-line 有指示器」这几个特性时，才值得写一个 minor mode。

---

# 第 16 章 major mode

> 示例：`examples/16-major-mode.el`

major mode 是「一个 buffer 的主语言/主用途」。一个 buffer 同时只有一个 major mode。
写 major mode 是「支持一门新语言/新格式」的标准做法。

## 16.1 四个组成部分

一个 major mode 要做四件事：

1. **语法表**（syntax table）—— 告诉 Emacs 哪些字符是注释、字符串引号、词的组成；
2. **字体锁**（font-lock）—— 用正则给不同部分上不同 face；
3. **`-mode` 函数** —— 设置上面两样东西；
4. **`-mode-hook`** —— 给用户/别的包插入自己配置的点。

## 16.2 语法表

```elisp
(defvar demo-note-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\; "<" st)     ; ; 开始一个注释
    (modify-syntax-entry ?\n ">" st)     ; 换行结束注释
    (modify-syntax-entry ?- "w" st)      ; - 算作词组成字符
    st))
```

```
5) ';' 的语法类别 = "."（'< ' 表示注释起始）
   '-' 的语法类别 = "w"（'w' 表示单词组成）
```

语法类别速查：

| 类别 | 含义 |
|---|---|
| `w` | 词组成字符（`forward-word` 会跳过） |
| `-` / `_` | 符号组成字符 |
| `.` | 标点 |
| `(` `)` | 配对括号 |
| `"` | 字符串引号 |
| `<` `>` | 注释的起止 |
| `\` | 转义 |
| ` ` | 空白 |

`char-syntax` 返回的就是类别的字符（比如 `.` 表示标点）。

## 16.3 字体锁关键字

```elisp
(defvar demo-note-font-lock-keywords
  `(("\\<TODO\\>" . warning)                    ; 整个匹配用 warning face
    ("\\<DONE\\>" . success)
    ("\\[\\([0-9]+\\)\\]" (1 'font-lock-constant-face))))  ; 只给第 1 组上色
```

```
6) TODO 处被着上的 face = warning
   DONE 处被着上的 face = success
   普通正文的 face = nil
```

两种写法：

- `(正则 . face)` —— 整个匹配都上这个 face；
- `(正则 (子组号 face ...) ...)` —— 只给指定子组上色，这是更常见的需求。

`font-lock-ensure` 强制把整个 buffer 着色一遍（异步字体锁平时是懒加载的，测试时必须显式调）。
**在 batch 模式下字体锁能正常工作** —— 这一点值得知道，因为它意味着高亮逻辑可以写进自动化测试。

> 【坑】**不是所有 major mode 的父类都会自动打开 font-lock**。`prog-mode` / `text-mode`
> 会自动开，但 `special-mode` 不会。派生自 `special-mode` 的 mode 需要自己在 body 里写
> `(font-lock-mode 1)`，否则 `font-lock-defaults` 设了也不生效。这个坑在写「只读列表型 mode」时必踩。

## 16.4 define-derived-mode

```elisp
(define-derived-mode demo-note-mode text-mode "Note"
  "一个极简的笔记文件主模式。"
  (setq-local font-lock-defaults '(demo-note-font-lock-keywords t))
  (set-syntax-table demo-note-mode-syntax-table)
  (add-hook 'after-save-hook #'demo-note-check nil t))
```

生成了：

- `demo-note-mode` 函数；
- `demo-note-mode-map`（parent 自动设成 `text-mode-map`）；
- `demo-note-mode-syntax-table`（parent 自动设成 `text-mode-syntax-table`）；
- `demo-note-mode-hook`，并且**在 mode 函数末尾自动 run 它**。

```
7) hook 触发顺序：
   "hook 跑了"，当前 mode = demo-note-mode，mode-name = "Note"
10) keymap 名 = demo-note-mode-map，hook 名 = demo-note-mode-hook
```

「hook 在 body 之后 run」这个顺序很重要：它保证用户挂在 `demo-note-mode-hook` 上的配置
能看到你在 body 里设好的一切。

## 16.5 派生关系怎么查

```elisp
(get 'demo-note-mode 'derived-mode-parent)    ; → text-mode
(derived-mode-p 'text-mode)                   ; 当前 buffer 里：→ text-mode
```

```
4) 派生关系: parent 属性 = text-mode
   derived-mode-p: text=text-mode prog=nil fundamental=nil
```

- `derived-mode-p` 返回的是**匹配到的那个 mode 符号**（不是 `t`），沿整条继承链往上找；
- 【坑】**当 parent 是 `fundamental-mode` 时，`derived-mode-parent` 属性是 nil** ——
  `fundamental-mode` 是根，`define-derived-mode` 不为它记录父关系。所以别用
  `(get 'xxx 'derived-mode-parent)` 去判断「是不是某个 mode 的子类」，要用 `derived-mode-p`。

## 16.6 关联文件后缀

```elisp
(add-to-list 'auto-mode-alist '("\\.note\\'" . demo-note-mode))
```

```
8) auto-mode-alist 新增前是否已有关联: nil
   加完之后: ("\\.note\\'" . demo-note-mode)
```

打开 `.note` 文件时自动进入这个 mode。注意**正则要用 `\\'` 锚定结尾**（不是 `$`），
否则 `.notebook` 这种也会被匹配上。

## 16.7 【坑】命名规范

- major mode 名必须**以 `-mode` 结尾**，而且**全局唯一**；
- 别的包的成员函数/变量一律加前缀（`demo-note-`），避免撞名；
- 私有函数用双横线（`demo-note--internal`）表示「不打算给外面用」。

```
9) 【坑】major mode 的命名必须以 -mode 结尾，且是全局唯一的
```

## 16.8 一个 mode 该提供什么的检查表

```
10) 一个 mode 该提供什么（checklist）：
```

写新 major mode 时逐条对照：

- [ ] `xxx-mode` 函数（用 `define-derived-mode`）
- [ ] `xxx-mode-syntax-table`（有特殊语法时）
- [ ] 字体锁关键字，并在 body 里开 font-lock
- [ ] `xxx-mode-map`，parent 设成合适的父 mode
- [ ] `auto-mode-alist` 关联（可选，通常是用户在配置里做）
- [ ] `imenu` 支持（能按结构跳转）
- [ ] `indent-line-function`（缩进规则）
- [ ] docstring 里写清用法

---

# 第 17 章 hook

> 示例：`examples/17-hooks.el`

hook 是「在某个事件发生时，按顺序跑一串函数」的机制。它是**无侵入式扩展**的关键 ——
你不需要改别人的代码，只要往他的 hook 里加函数。

## 17.1 hook 就是一个函数列表

```elisp
(add-hook 'demo-hook #'demo-first)
(remove-hook 'demo-hook #'demo-first)
(run-hooks 'demo-hook)
```

```
4) hook 里装的是符号: (demo-first)
```

约定：hook 变量以 `-hook` 结尾，里面装的是**函数符号**而不是 lambda。

> 【坑】**永远不要把 lambda 直接加进 hook**。原因有二：`remove-hook` 比的是对象身份，
> 匿名 lambda 每次都是新对象，加进去就摘不掉；而且 `run-hooks` 对 lambda 的处理在不同版本/是否
> 字节编译下有所不同。**具名函数是唯一正确的写法。**

## 17.2 【坑】默认是插到最前面

```elisp
(add-hook 'demo-hook #'demo-first)
(add-hook 'demo-hook #'demo-second)
```

```
1) 按加入顺序（默认插在最前面，所以后加的先跑）：
    [second] 执行
    [first] 执行
2) 传 t 之后（后加的后跑）：
    [first] 执行
    [second] 执行
```

`add-hook` 默认把新函数**插到列表最前面**，所以执行顺序是**后加的先生效** —— 这和「按加入顺序」
的直觉相反。想按加入顺序执行，第 3 个参数传 `t`（append）：

```elisp
(add-hook 'demo-hook #'demo-first)
(add-hook 'demo-hook #'demo-second t)     ; 追加到末尾
```

## 17.3 add-hook 是幂等的

```
3) 加了两次，hook 里只有 1 个函数
```

重复 `add-hook` 同一个函数不会加两次。但**这有个副作用**：如果同一个函数被两个包用不同的
「顺序参数」加过，第二次的调用只改顺序不加函数，结果可能和预期不同。

## 17.4 带参数的 hook（abnormal hook）

普通 hook 里的函数**不接收参数**，`run-hooks` 只是无参调用它们。要传参得用 abnormal hook：

```elisp
;; 名字以 -functions 结尾（不是 -hook）的通常是 abnormal hook
(add-hook 'demo-save-functions #'demo-on-save)

(defun demo-on-save (filename)
  (princ (format "    [on-save] 保存了 %S\n" filename)))

(run-hook-with-args 'demo-save-functions "/tmp/a.txt")
```

```
    [on-save] 保存了 "/tmp/a.txt"
```

命名约定：

| 后缀 | 含义 |
|---|---|
| `-hook` | 普通 hook，函数无参 |
| `-functions` | abnormal hook，函数接收参数 |
| `-function` | 单个函数（不是列表） |

## 17.5 直到成功 / 直到失败

```
6) until-success 传 'b: "B 接下了"
   until-failure 传 'b: nil
```

`run-hook-with-args-until-success` / `-until-failure` 会给每个函数传参，**遇到第一个返回非 nil
（或 nil）的就停下**。适合做「谁来负责处理这件事」的分派 ——
比如 `find-file-not-found-functions` 就是：第一个成功打开的包负责到底，后面的不再跑。

## 17.6 精确控制顺序：DEPTH

```elisp
(add-hook 'demo-hook #'demo-first  -10)    ; 数字更小的更早跑
(add-hook 'demo-hook #'demo-second 10)
```

```
7) 按 depth 排序后: (demo-second demo-first)
```

第 3 个参数是整数 `DEPTH`（-100..100），更小的先跑。这比 `append` 更精细，适合
「我的扩展必须在某类包之前/之后初始化」的场景。

## 17.7 buffer 局部 hook

```elisp
(add-hook 'demo-hook #'demo-first nil t)    ; 第 4 个参数 t = 只对当前 buffer 生效
```

```
8) buffer A 里的 hook: (t demo-first)
   buffer B 里的 hook: (demo-second demo-first)（不受影响）
```

第 4 个参数 `LOCAL` 为 `t` 时，hook 只加在当前 buffer 上。**这是写 mode / minor mode 时必须
注意的**：mode 是 buffer 局部的，它装的 hook 也应该局部，否则会互相干扰。

Buffer A 的 hook 里出现了 `t`，这是 buffer-local 绑定在默认值上的标记 —— 打印出来看到
「列表里混了个 `t`」是正常的。

## 17.8 「一次性」hook

```elisp
(let ((demo-hook (list #'demo-temp)))     ; 动态绑定覆盖 hook 变量
  (demo-run-temp-hook))
;; 出了 let 自动恢复
```

```
9) 临时替换 hook：
    [临时] 只跑这一次
   退出 let 后恢复为: (demo-first)
```

利用 `let` 对 special 变量的动态绑定（第 3.4 节）：`let` 期间 hook 里只有你想跑的那个函数，
退出后自动恢复。这比「加进去再摘掉」安全得多（中途出错也不会漏摘）。

## 17.9 常用内置 hook

```
10) find-file-hook 里现在有 2 个函数
```

| hook | 时机 |
|---|---|
| `find-file-hook` | 打开文件之后 |
| `before-save-hook` / `after-save-hook` | 保存前 / 后 |
| `kill-buffer-hook` | 关闭 buffer 前 |
| `after-change-functions` | buffer 内容变化后 |
| `post-command-hook` | 每条命令之后 |
| `prog-mode-hook` / `text-mode-hook` | 进入对应 mode 时 |
| `window-configuration-change-hook` | 窗口布局变化 |
| `emacs-startup-hook` / `after-init-hook` | 启动完成后 |

## 17.10 【坑】高频 hook

```
11) post-command-hook 和 after-change-functions 每次击键都会跑
```

这两个 hook **每次按键都跑**。在里面做重活会立刻让 Emacs 卡顿。如果确实需要，
用定时器延后（第 21 章的空闲定时器）或者加节流。

---

# 第 18 章 可定制选项 defcustom

> 示例：`examples/18-custom.el`

一个「能用」的扩展和一个「好用」的扩展，差别常常就在有没有把该暴露的东西做成 `defcustom`。

## 18.1 defgroup 与 defcustom

```elisp
(defgroup demo-timer nil
  "演示用的定时器功能。"
  :group 'tools
  :prefix "demo-timer-")

(defcustom demo-timer-interval 25
  "两次提醒之间的分钟数。"
  :type 'integer
  :group 'demo-timer)
```

`defcustom` 比 `defvar` 多了三样东西：

1. **`:type`** —— 告诉 customize 界面该显示成什么控件；
2. **`:group`** —— 归到哪个分组；
3. **`:set` / `:initialize`** —— 值变化时的回调。**这是 `defcustom` 最有价值的部分**：
   用户改配置时你能立刻做出反应（重设定时器、重建 buffer、刷新显示）。

```
11) 本示例共有 6 个自定义选项
```

## 18.2 :type 常用类型

```elisp
:type 'integer
:type 'string
:type 'boolean
:type '(choice (const :tag "关闭" nil) (const :tag "警告" warn) (const :tag "报错" error))
:type '(repeat string)
:type '(alist :key-type symbol :value-type string)
:type 'file
:type 'directory
:type 'face
```

```
9) demo-timer-interval 的 :type = integer
   它的标准值（未改过的默认值）= 25
```

## 18.3 【坑】defcustom 不会覆盖已有值

```
5) 手动 setq 成 50 之后: 50
```

和 `defvar` 一样 —— 变量已经有值了就不覆盖。这是**故意的**：用户设置过的东西不能被包升级重置。

## 18.4 【重点】setq 不触发 :set，customize-set-variable 才触发

这是本章最实用的一节，也是很多人踩过的坑：

```elisp
(defcustom demo-timer-label "默认"
  "..."
  :type 'string
  :set (lambda (sym val)
         (set-default sym val)              ; ← 一定要真的把值设上
         (setq demo-timer-applied (1+ demo-timer-applied))))  ; 再做副作用
```

```
6) 对比两种改法：
   改之前 applied = 0
   setq 之后 applied = 0（没有触发 :set）
    [:set 触发] demo-timer-label 变成 "走 customize"
   customize-set-variable 之后 applied = 1
7) custom-set-variables：
    [:set 触发] demo-timer-label 变成 "批量设置"
   applied = 2，当前值 = "批量设置"
```

| 改法 | 触发 `:set` 吗 | 用于 |
|---|---|---|
| `(setq demo-timer-label "x")` | **不会** | 内部代码临时改 |
| `(customize-set-variable 'demo-timer-label "x")` | 会 | 程序化地「像用户改配置一样」改 |
| `(custom-set-variables '(demo-timer-label "x"))` | 会 | Emacs 写进 custom-file 的形式 |
| customize 界面 | 会 | 用户手点 |

关键结论：**`defcustom` 的 `:set` 只保证「通过 customize 机制改」时被调用。**
如果你的代码里需要「改了选项就立刻生效」，要么用 `customize-set-variable`，
要么在改完之后显式调用生效函数。指望 `setq` 触发 `:set` 是不行的。

`:set` 函数里的 `set-default` 也不能忘 —— 忘了的话值根本没被设上，只有副作用发生了。

## 18.5 判断「是不是用户选项」

```elisp
(custom-variable-p 'demo-timer-interval)     ; → t
(custom-variable-p 'demo-timer-applied)      ; 普通 defvar → nil
```

```
8) demo-timer-interval 是用户选项吗: t
   普通 defvar 的: nil
```

相关函数：`custom-variable-type` 取类型定义（注意它需要 `custom` 已加载，
并且在字节编译时需要 `declare-function`，否则会报未定义警告）。

## 18.6 defface

```elisp
(defface demo-timer-face
  '((t :foreground "orange" :weight bold))
  "演示用的 face。"
  :group 'demo-timer)
```

```
10) face 定义好了: t
```

`defface` 的用法和 `defcustom` 类似，`(custom-set-faces ...)` 改它，`(facep 'xxx)` 判存在。
`'((t :foreground "orange"))` 里的 `t` 表示「所有终端类型都适用」（老式写法，
现在基本都写 `t`）。

写 face 时注意：**只设前景色**通常是最安全的做法，让用户主题的背景色透出来；
如果要设背景色，记得同时考虑深色/浅色主题。

## 18.7 打包建议

- 所有 `defcustom` **集中放在文件靠前的位置**，方便用户阅读和 `customize` 分组；
- 每个 `defcustom` 的 docstring 写清**取值范围和含义**（会显示在 customize 界面里）；
- `defgroup` 的 `:prefix` 让你的选项在 customize 里聚在一起；
- 不要用 `setq` 去改用户选项 —— 用 `customize-set-variable`。

---

# 第 19 章 advice：不改源码改行为

> 示例：`examples/19-advice.el`

advice 让你**在不修改函数源码**的情况下改变它的行为。它是「另一个包的行为不合我意」
这种情况下唯一的正规手段。

## 19.1 六种 advice

```elisp
(advice-add 'demo-save :before  #'demo-log-before)
(advice-add 'demo-save :after   #'demo-log-after)
(advice-add 'demo-save :filter-args   #'demo-fix-args)
(advice-add 'demo-save :filter-return #'demo-fix-return)
(advice-add 'demo-save :around  #'demo-around)
(advice-add 'demo-save :override #'demo-override)
```

| 类型 | 作用 | 能改参数 | 能改返回值 |
|---|---|---|---|
| `:before` | 原函数**之前**跑 | 否 | 否 |
| `:after` | 原函数**之后**跑 | 否 | 否 |
| `:filter-args` | 修改**传给**原函数的参数 | **是** | 否 |
| `:filter-return` | 修改原函数的**返回值** | 否 | **是** |
| `:around` | 把原函数**包起来** | **是** | **是** |
| `:override` | **整个替换**掉原函数 | **是** | **是** |

实测一次调用同时挂了 `:before` `:after` `:around` 时：

```
6) 现在一次调用会依次触发：
    [before] 参数 = ("F" 6)
    [after] 参数 = ("F" 6)
    [around] 耗时 0.000021 秒，返回值 "saved F=6 [advised]"
7) :override 之后: "被 override 了"（其它 advice 全被短路）
```

## 19.2 :before / :after

```elisp
(defun demo-log-before (&rest args)
  (princ (format "    [before] 参数 = %S\n" args)))
```

```
    [before] 参数 = ("a" 1)
1) :before 之后调用: "saved a=1"
```

它们接收的**参数和原函数完全相同**，返回值被忽略（`:before` 的返回值不影响原函数的参数，
`:after` 的返回值也不影响最终结果）。想改东西必须用下面四种。

## 19.3 :filter-args 与 :filter-return

```elisp
(defun demo-fix-args (args)
  "注意：接收的是**参数列表**，返回的也必须是参数列表。"
  (list (upcase (car args)) (cadr args)))
```

```
3) 加 :filter-args 后传 "c": "saved C=3"
```

```elisp
(defun demo-fix-return (ret)
  "接收返回值，返回新的返回值。"
  (concat ret " [advised]"))
```

```
4) 加 :filter-return: "saved D=4 [advised]"
```

`:filter-args` 的接口很容易写错：它接收的**不是**散开的参数，而是**一个参数列表**，
返回的也必须是参数列表。

## 19.4 :around：最强的一个

```elisp
(defun demo-around (orig &rest args)
  "第一个参数是原函数（一个可 funcall 的对象）。"
  (let ((t0 (float-time)))
    (prog1 (apply orig args)             ; 一定要调用 orig，否则原函数不跑
      (princ (format "    [around] 耗时 %.6f 秒\n" (- (float-time) t0))))))
```

```
    [around] 耗时 0.000023 秒，返回值 "saved E=5 [advised]"
```

`:around` 能做所有事：改参数、改返回值、决定要不要调用原函数、调用几次、包错误处理。
**计时、缓存、重试、包 `condition-case` 都是 `:around` 的活。**

## 19.5 【坑】advice 是全局且看不见的

```
9) 【坑】advice 是全局的、看不见的改动。三条纪律：
```

坦白说 advice 是**有风险**的手段，三条纪律：

1. **优先用 hook / 配置 / 包装函数**。advice 是最后手段 —— 因为它绕过了原作者的所有假设；
2. **一定要能撤掉**。用 `unwind-protect` 包起来（见 19.6），或者在扩展卸载时 `advice-remove`；
3. **具名函数**，不要用 lambda（见 19.7）。

调试时如果怀疑某个函数被 advice 了：`C-h f 函数名` 会显示 advice 信息，
`(advice-member-p #'fn #'target)` 判断某个 advice 是否还挂着。

## 19.6 临时 advice 的正规写法

```elisp
(let ((orig (symbol-function #'demo-save)))
  (unwind-protect
      (progn
        (advice-add #'demo-save :filter-return #'demo-temp-suffix)
        (demo-use-it))
    (advice-remove #'demo-save #'demo-temp-suffix)))
```

```
10) 临时 advice: "saved i=9 [临时]"
   摘掉后: "saved j=10"，还挂着吗: nil
```

`unwind-protect` 保证**即使中途出错**也会摘掉 advice —— 这是它和「加完再手动摘」的本质区别。

## 19.7 【坑】lambda advice 摘不掉

```
11) lambda advice 摘不掉，调用结果: "saved k=11"
   结论：advice 一律用具名函数
```

```elisp
(advice-add #'demo-save :filter-return (lambda (r) (concat r " [x]")))
(advice-remove #'demo-save (lambda (r) (concat r " [x]")))   ; ← 删不掉！
```

`advice-remove` 比较的是**函数对象是否 `eq`**，而匿名 lambda 每次求值都是新对象 ——
所以永远删不掉。**advice 一律用具名 `defun`**，这条没有例外。

## 19.8 移除

```elisp
(advice-remove 'demo-save #'demo-log-before)      ; 移一个
(advice-mapc (lambda (a _) (advice-remove 'demo-save a)) 'demo-save)  ; 移全部
```

```
8) demo-log-before 还挂着吗: t
   全部移除后: "saved h=8"，还挂着吗: nil
```

没有 `advice-remove-all` 这个函数。要移全部就用 `advice-mapc` 遍历。

> 【坑】`advice-member-p` 返回的**不是 `t`**，而是整个 advice 对象（内含字节码）。
> 直接 `%S` 打印会带裸控制字节，触发验证脚本的「控制字符」判定。要么转布尔
> `(and (advice-member-p ...) t)`，要么别打印它。

---

# 第 4 部分 与外部世界

扩展能力的天花板，很大程度上取决于它能不能调用外部工具、能不能处理时间、能不能优雅地失败。
这三章分别对应 `process`、`timer` 和错误处理。

# 第 20 章 子进程

> 示例：`examples/20-processes.el`

## 20.1 跨平台前提

```elisp
(princ (format "0) shell = %S, switch = %S\n" shell-file-name shell-command-switch))
```

```
0) shell = "/bin/bash", switch = "-c"
```

**不要写死 `cmd.exe` / `/bin/sh`。** 用 `shell-file-name` 和 `shell-command-switch`，
Emacs 会填好当前平台的值。这是让扩展跨平台的第一个前提。

## 20.2 同步调用

```elisp
(call-process "echo" nil t nil "hello")        ; 输出进当前 buffer，同步等待
(shell-command-to-string "echo hello")         ; 只想要输出字符串
(call-process "make" nil "*out*" nil "all")    ; 输出进指定 buffer
(call-process "make" nil "/tmp/log.txt" nil "all")   ; 输出直接进文件
```

```
1) call-process 退出码 = 0，输出 = "sync-hello"
2) shell-command-to-string: "from-shell"
3) 文件里的结果: "written-to-file"
```

`call-process` 的参数是 `(program &optional infile destination display &rest args)`：

| destination | 含义 |
|---|---|
| `nil` | 丢弃输出 |
| `t` | 插到当前 buffer 的 point 处 |
| 字符串 | 这是 buffer 名（不存在则新建） |
| `(file . name)` | 写进文件 |
| 函数 | 用函数接收输出 |

**同步调用会卡住 Emacs。** 只适合几毫秒能返回的命令。跑 `make` / `git` / 语言服务器一律用异步。

## 20.3 【坑】命令和参数必须分开传

```elisp
;; 正确
(call-process "git" nil t nil "log" "--oneline")

;; 错误：把整串交给 shell，文件名里有空格/引号就会出问题
(call-process shell-file-name nil t nil "-c" "git log --oneline")
```

理由：分开传时**不经过 shell**，所以参数里的空格、引号、`$`、`;` 都是普通字符，不需要转义，
也不会有命令注入风险。只有确实需要 shell 特性（管道、重定向、通配符）时，才显式地用 shell。

## 20.4 先查可执行文件

```elisp
(executable-find "echo")        ; → "/bin/echo"
(executable-find "no-such-bin") ; → nil
```

```
5) executable-find "echo" = "/bin/echo"
   找一个不存在的: nil
```

**调用外部程序之前一定先查一次**，查不到就给出清晰的错误提示（而不是让用户看到
`Searching for program: No such file or directory`）。

## 20.5 异步进程：make-process

```elisp
(make-process
 :name "demo"
 :buffer nil                              ; nil = 不自动插进 buffer
 :command (list "echo" "async-hello")
 :filter (lambda (proc chunk) ...)        ; 收到输出时调用
 :sentinel (lambda (proc event) ...))     ; 状态变化时调用
```

```
6) 异步收到: "async-hello"，进程还活着吗: nil
```

它是**立刻返回**的：Emacs 不会阻塞，进程的输出通过 `:filter` 回调送达。

## 20.6 【坑】sentinel 的 event 末尾带换行

```elisp
(defun demo-sentinel (proc event)
  (princ (format "7) sentinel 收到的 event: %S\n" event)))
```

```
7) sentinel 收到的 event: ("finished
")
   退出码 = 0
```

`event` 是形如 `"finished\n"` / `"exited abnormally with code 1\n"` 的字符串 ——
**末尾有换行**。要判断状态别用 `string=` 整串比，用 `string-match-p` 或者
`(process-exit-status proc)`。

想拿退出码用 `process-exit-status`。`process-live-p` 判是否还活着。

## 20.7 老 API：start-process

```elisp
(start-process "name" "*buffer*" "cmd" "args")
(set-process-sentinel proc #'demo-sentinel)
```

```
8) start-process 输出: "old-api

Process demo-old finished"
```

它把输出直接收集进一个 buffer（所以简单场景很方便），但没有 filter 的灵活性。
新代码优先用 `make-process`。

## 20.8 给进程喂输入

```elisp
(process-send-string proc "通过 stdin 喂进去的一行\n")
(process-send-eof proc)          ; 关掉 stdin，很多程序靠这个才开始处理
```

```
9) cat 回显: "通过 stdin 喂进去的一行"
```

**别忘了 `process-send-eof`** —— 像 `cat`、`grep` 这种从 stdin 读的程序，收不到 EOF 就会一直等着。

## 20.9 超时与杀进程

```elisp
(when (process-live-p proc)
  (delete-process proc))         ; 温和终止
;; (kill-process proc) 发信号
```

```
10) 启动 sleep 30: 活着 = (run open listen connect stop)
    delete-process 之后: 活着 = nil
```

**外部工具挂住是很常见的**（网络请求、等锁、交互式提示），所以一定要有超时兜底：

```elisp
(let ((deadline (+ (float-time) 5)))
  (while (and (process-live-p proc) (< (float-time) deadline))
    (accept-process-output proc 0.1))
  (when (process-live-p proc)
    (delete-process proc)
    (error "命令超时")))
```

## 20.10 清理

```
11) 临时目录已清理: t
```

进程、临时文件都要在结束时清理干净。写扩展时用 `unwind-protect` 包住，
或者把进程对象挂在 buffer-local 变量上、在 `kill-buffer-hook` 里清理。

---

# 第 21 章 定时器

> 示例：`examples/21-timers.el`

## 21.1 【重要前提】batch 模式下定时器不会自己触发

```
0) batch 模式下定时器要靠 sleep-for 推动
```

Emacs 的 batch 模式**没有事件循环**，所以定时器不会「自己」到点执行。要让它跑，必须用
`sleep-for` 把时间推进过去：

```elisp
(let ((fired 0))
  (run-with-timer 0.05 nil (lambda () (setq fired (1+ fired))))
  (sleep-for 0.3)                ; ← 这段时间里定时器才有机会执行
  (princ (format "fired = %d\n" fired)))
```

```
1) 0.05 秒后触发一次，fired = 1
```

交互模式下不需要这个 —— 有真正的事件循环。但**写测试时这条一定要记住**，
否则会看到「定时器没跑」的假象。

## 21.2 一次性与重复

```elisp
(run-with-timer 0.05 nil #'fn)      ; 0.05 秒后一次
(run-with-timer 0.05 0.1 #'fn)      ; 0.05 秒后开始，每 0.1 秒一次
```

```
2) 每 0.05 秒一次，0.25 秒后 fired = 5
   cancel 之后再等 0.2 秒，fired = 0（不再增加）
```

第 2 个参数给间隔就是重复定时器。**重复定时器一定要 `cancel-timer`**，
否则它会在 Emacs 退出前一直跑着。

## 21.3 传参数

```elisp
(run-with-timer 0.05 nil #'demo-handle "hello" 42)
```

```
3) 定时器传过来的参数: ("hello" 42)
```

第 4 个参数之后都是传给函数的实参。

## 21.4 【坑】定时器里的错误被吃掉

```
4) timer 里的错误不会打断主流程（已演示）
```

定时器函数里报错，Emacs **不会**中断主流程，只是把错误写进 `*Messages*`。
好处是不会崩，坏处是**错误容易被忽略**。所以在定时器函数里要自己包 `condition-case` 并
至少打印出来（见第 22 章）。

## 21.5 立即 / 尽快

```elisp
(run-at-time nil nil #'fn)          ; 立即（下一轮事件循环）
(run-at-time "23:00" nil #'fn)      ; 指定绝对时间
(run-at-time "5 min" 60 #'fn)       ; 5 分钟后开始，之后每 60 秒 —— 字符串能被解析
```

```
5) run-at-time nil（立即），fired = 1
```

`run-at-time` 的第一个参数可以是秒数、`nil`（立即），或者人写的字符串（`"5 min"`、`"23:00"`）。
它比 `run-with-timer` 更通用。`run-with-timer` 只是 `run-at-time` 的便捷包装。

## 21.6 【坑】idle timer 在 batch 下永不触发

```elisp
(run-with-idle-timer 0.05 t #'fn)
```

```bash
$ emacs -Q --batch --eval '(progn (setq r 0)
                            (run-with-idle-timer 0.05 t (lambda () (setq r (1+ r))))
                            (sleep-for 0.3)
                            (princ (format "idle fired=%S\n" r)))'
idle fired=0
```

**batch 模式下 idle timer 永远不会触发** —— 因为「空闲」的定义是「没有输入事件等待处理」，
而 batch 模式没有输入的概念。实测确认是 0 次。

## 21.7 idle timer 的正经用途

```
7) idle timer 的正经用途：把「每次击键都要做」的重活延后到用户停下来时做
```

交互模式下，它解决的是第 17.10 节的「高频 hook」问题：`post-command-hook` 每次击键都跑，
如果在里面直接做重活会卡；改成「每次击键时重设定时器，0.3 秒后执行」，
用户连续打字期间就只会执行最后一次。

## 21.8 sit-for 与 sleep-for

```elisp
(sleep-for 0.5)     ; 睡 0.5 秒，期间处理进程输出，**不重绘**
(sit-for 0.5)       ; 睡 0.5 秒，处理输入/进程输出，**会重绘**，有输入则提前返回
```

```
8) sleep-for 不处理 redisplay；sit-for 会
```

- 在脚本/batch 里推进定时器 → `sleep-for`；
- 在交互代码里想「等一下并让界面刷新」 → `sit-for`。

## 21.9 【坑】lambda 定时器取消不掉

```
9) 【坑】定时器持有的是函数对象，如果传 lambda 就取消不掉（同 advice）
```

和 advice 完全一样的道理（第 19.7 节）：`cancel-timer` 需要你**手里有那个 timer 对象**。
所以正确姿势是：

```elisp
(setq demo-timer (run-with-timer 1 1 #'demo-tick))   ; 存下来
(cancel-timer demo-timer)                            ; 才能取消
```

传 lambda 的话你就没有可靠的「同一个函数对象」可用来做判断了。

## 21.10 清理

```
10) 当前还有 0 个活跃 timer
```

`(length timer-list)` 可以看当前有多少活跃定时器。写扩展时把所有 timer 存进一个列表，
在 `kill-buffer-hook` 或扩展卸载时统一 `cancel-timer`。

## 21.11 三者怎么选

```
11) 选择依据：轮询用 timer，空闲用 idle-timer，外部输出用 process
```

| 需求 | 用什么 |
|---|---|
| 定时/轮询某件事 | `run-with-timer` |
| 「用户停下来之后」再做事 | `run-with-idle-timer`（交互模式） |
| 等外部程序的输出 | `process` + filter/sentinel |
| 「每次击键之后」 | `post-command-hook`（配合 idle timer 节流） |

---

# 第 22 章 错误处理

> 示例：`examples/22-errors.el`

## 22.1 错误的形状

Emacs 的错误 = **错误符号** + **数据**。比如：

```elisp
(condition-case err (+ 1 "x") (error (princ (format "%S\n" err))))
;; err = (wrong-type-argument number-or-marker-p "x")
```

第一个元素是错误符号（一个符号，可以有「父类」），后面是相关数据。
`error-message-string` 把它转成人读的字符串。

## 22.2 condition-case

```elisp
(condition-case err
    (可能出错的代码)
  (error (处理它，err 是错误对象)))
```

```
2) 捕获 error: (caught "出错了：演示")
```

`error` 是所有「正常错误」的父类，捕获它就等于捕获所有。想拿完整的错误对象，
第一个参数必须是个符号（不能用 `nil`）。

## 22.3 精准捕获

```elisp
(condition-case err
    (+ 1 "x")
  (void-function '没有这个函数)
  (wrong-type-argument '类型不对))
```

```
3) 精准捕获 wrong-type-argument: (caught "Wrong type argument: number-or-marker-p, \"不是数字\"")
   不匹配的 handler 会继续往上抛: 外层接住了
```

handler 按**书写顺序**匹配，第一个匹配的执行。都不匹配就继续往外抛。
**只捕获你知道怎么处理的错误** —— 一个全捕获的 `(error ...)` 会把真正的 bug 一起吃掉。

## 22.4 【坑】condition-case nil 会丢掉错误详情

```elisp
(condition-case nil
    (foo)
  (error '出错了))       ; ← 拿不到错误消息
```

```
4) 【坑】(condition-case nil ...) 用 nil 当变量时会忽略错误详情
```

第一个参数写 `nil` 时无法访问错误对象。只想「知道出错了」还行，但**日志和调试**时一定要用符号。

## 22.5 ignore-errors

```elisp
(ignore-errors (/ 1 0))    ; → nil
(ignore-errors (* 1 2))    ; → 6
```

```
5) ignore-errors 正常: 3，出错: nil
```

比 `condition-case` 简洁，但**把错误彻底吞掉了**。适合「这个操作失败也没关系」的场景
（比如读一个可能不存在的文件、删一个可能不存在的 buffer）。

## 22.6 unwind-protect：清理

```elisp
(unwind-protect
    (干活)
  (清理))                  ; 无论正常返回还是出错，都会执行
```

```
6) ("干活" "清理")
```

这是**资源清理的唯一正确方式**。`unwind-protect` 保证：

- body 正常结束 → 执行清理；
- body 报错并往外抛 → 执行清理后继续抛；
- body 里 `throw` 出去 → 执行清理。

所以「临时改全局变量 / 挂 advice / 建临时文件 / 起进程」的清理一律放这儿。

## 22.7 自定义错误类型

```elisp
(define-error 'demo-timeout "操作超时" 'error)
(signal 'demo-timeout (list "连接超时" 30))
```

```
7) 自定义错误: (caught "超时: \"连接超时\", 30")
```

`define-error` 的第 3 个参数是**父错误符号**（这里是 `error`）。所以：

- 用户可以用 `(condition-case e ... (demo-timeout ...))` 精准捕获；
- 也可以用 `(error ...)` 兜住它；
- `C-h f`-式的帮助里会显示「超时: ...」这样的消息。

**给自己的扩展定义错误类型是好习惯** —— 调用方就能区分「你的扩展超时了」和「Emacs 抛了别的错」。

## 22.8 user-error

```elisp
(user-error "请先选中一段文本")
```

```
8) user-error: "请先选中一段文本"
```

`user-error` 专门用于「用户操作不当」的情况。它的特别之处是**不会进入 debugger** ——
即使用户开了 `debug-on-error`，`user-error` 也不弹 backtrace。所以：

- 「你没选中文本」「这个文件不是你的格式」→ `user-error`；
- 「内部状态坏了」→ `error`。

这样开发者调试自己的代码时不会被用户的误操作干扰。

## 22.9 catch / throw：提前退出

```elisp
(catch 'done
  (dolist (x items)
    (when (found-p x) (throw 'done x)))
  'not-found)
```

```
9) catch/throw: "在 3 处跳出"
10) 没有 throw 时: 3
```

Elisp 没有 `return` / `break`。**`catch` + `throw` 是唯一的「提前跳出去」手段**，
在深层嵌套里特别有用。

如果执行到 `catch` 末尾都没有 `throw`，`catch` 返回 body 最后一个表达式的值。

```elisp
(condition-case e
    (throw 'no-such-tag 1)
  (error (error-message-string e)))
```

```
    没有 catch 时: "No catch for tag: no-such-tag, 1"
```

`throw` 找不到对应的 `catch` 会 signal 一个 `no-catch` 错误。

> 【坑】字节编译器**不认识** `no-catch` 这个错误符号，写 `(condition-case e (throw ...) (no-catch ...))`
> 会得到 "reference to free variable" 之类的警告。用 `(error ...)` 兜住即可。

## 22.10 断言

```elisp
(cl-assert (= 1 1) nil "不该失败")        ; 通过
(cl-assert (= 1 2) nil "断言失败")        ; 报错
```

```
11) cl-assert 通过: "ok"
    cl-assert 失败: 断言失败
```

`cl-assert` 用于「这里一定为真」的检查。

> 【坑】**`cl-assert` 在字节编译时如果 `debug` 是关的，某些情况下会被优化掉。**
> 所以不要用 `cl-assert` 做「必须有副作用」的检查 —— 要保证执行就用
> `(unless cond (error ...))`。

## 22.11 调试开关

```
12) 开发期建议 M-x toggle-debug-on-error
```

| 开关 | 作用 |
|---|---|
| `toggle-debug-on-error` | 未捕获的错误弹 backtrace |
| `debug-on-message` | 匹配某个正则的 message 时弹 |
| `debug-on-quit` | `C-g` 时弹 |

开发时打开 `toggle-debug-on-error`，能立刻看到出错位置和完整调用栈 ——
这比在代码里到处插 `princ` 高效得多。

---

# 第 5 部分 工程化

最后一部分是「怎么写一个正经的包」：宏（写出好用的接口）、模块与加载（组织代码）、
测试（保证它一直能用）。

# 第 23 章 宏

> 示例：`examples/23-macros.el`

## 23.1 宏和函数的根本区别

```elisp
(defun demo-add-one (n) (1+ n))          ; 参数先求值，再传进函数体
(defmacro demo-inc (place) `(setq ,place (1+ ,place)))   ; 参数不求值，直接塞进展开式
```

```
1) 宏展开结果: (setq demo-n (1+ demo-n))，执行后 n = 11
```

- **函数**：参数先求值，函数体拿到的是**值**；
- **宏**：参数**不求值**，宏体拿到的是**表达式本身**，返回一个新表达式，然后那个表达式被求值。

所以宏能做函数做不到的事：**发明新的控制结构**（`when`、`if-let`、`with-temp-buffer` 都是宏）。

```
10) 函数是 nil，宏是 t —— 宏不能当值传
```

判断：`(functionp 'foo)` 对宏是 `nil`，`(macrop 'foo)` 是 `t`。**宏不能 `funcall`、不能
`mapcar`、不能存进变量**（因为它是「编译期的东西」）。

## 23.2 backquote：拼表达式的工具

```elisp
`(setq demo-n (1+ demo-n))          ; 反引号：像 quote，但可以「打开」一部分
`(let ((x ,value)) ,@body)          ; , 插入一个值，,@ 把列表摊开插入
```

```
2) backquote 写法展开: (setq demo-n (1+ demo-n))
   执行后 n = 12
```

- `` ` `` 类似于 `'`，构造一个列表但**不阻止求值**；
- `,expr` —— 求值 expr 并把结果插进这个位置；
- `,@expr` —— 求值 expr（必须是个列表）并把它的元素摊开插进去。

`,@` 是写宏时最常用的东西，用来把 `&rest body` 展开到生成的结构里。

## 23.3 宏的价值：发明控制结构

```elisp
(defmacro demo-when-let (spec &rest body)
  "如果 SPEC 里绑定的值都是真，就执行 BODY。"
  (declare (indent 1))
  `(let ,(list spec)
     (when ,(car spec) ,@body)))
```

```
3) when-let 展开: (let ((x 5)) (when x (princ x)))
```

这类「先绑定、绑定成功才执行」的结构用函数写不出来。**只有需要「改变求值时机/次数」时才写宏**
—— 如果只是想把代码收敛一下，用函数。

## 23.4 【大坑】变量捕获

```elisp
(defmacro demo-bad-capture (body)
  `(let ((x 99))        ; ← 这里用了固定的名字 x
     ,body))
```

```
4) 展开式: (let ((x 99)) x)
   调用方 (let ((x 1)) ...) 里拿到: (99 1)  <- 期望 (1 1)，实际第一个被劫持
```

调用方的 `x` 被宏内部的 `x` 覆盖了 —— 而且从调用方的代码完全看不出为什么。
这叫**变量捕获（variable capture）**，是写宏最容易犯的错。

## 23.5 修法：make-symbol

```elisp
(defmacro demo-good-capture (body)
  (let ((sym (make-symbol "x")))       ; 造一个「未 interned」的符号
    `(let ((,sym 99))
       ,body)))
```

```
5) 展开式: "(let ((#:x 99)) x)"
   调用方的 x 不受影响: (1 1)
```

`make-symbol` 生成的符号**不在符号表里**，跟任何用户写的符号都不 `eq`，所以不可能撞名。
展开式里显示成 `#:x`（带 `#` 前缀的就是未 interned 的符号）。

> `print-gensym` 控制是否显示 `#:` 前缀。默认 `t`，所以调试宏时一眼就能看出哪些符号是
> 「宏自己生成的」。

## 23.6 【坑】参数求值次数

```elisp
(defmacro demo-twice (expr)
  `(+ ,expr ,expr))          ; expr 被求值两次！
```

```
6) 求值两次: 结果 = 2，副作用执行了 2 次
```

宏的参数会被**原封不动地塞进展开式**，出现几次就被求值几次。所以：

- 如果参数是 `(f)` 这种有副作用的表达式，会被执行多次；
- 如果参数求值很贵，也会浪费。

**正确做法**：用 `let` 把它绑一次：

```elisp
(defmacro demo-twice-safe (expr)
  (let ((sym (make-symbol "e")))
    `(let ((,sym ,expr))
       (+ ,sym ,sym))))
```

这也是为什么 `cl-lib` 的 `cl-incf` 之类的宏都有一堆「先绑定再操作」的展开。

## 23.7 调试宏的三个工具

```elisp
(macroexpand-1 '(demo-when-let (x 5) (princ x)))   ; 展开一层
(macroexpand   '(demo-when-let (x 5) (princ x)))   ; 展开到底
```

```
7) macroexpand-1: (let ((a 1)) (when a a))
   macroexpand:   (let ((a 1)) (when a a))
```

- `macroexpand-1` 只看一层展开；
- `macroexpand` 递归展开到底（但仍不会展开被调用的宏里的宏）；
- 在 `*scratch*` 里边写边 `C-j` 看展开结果 —— 这是写宏最有效的工作方式。

## 23.8 【坑】宏在编译期展开

```
8) eval-when-compile: "compiled-by-emacs-31"
```

宏在**编译期**展开，所以宏体里只能用到「编译期已知」的东西。想在编译期算一个常量：

```elisp
(defmacro demo-version-tag ()
  (eval-when-compile (format "compiled-by-emacs-%d" emacs-major-version)))
```

`eval-when-compile` 让这段代码在**编译时**求值一次，把结果直接嵌进展开式（运行时不再计算）。

## 23.9 declare

```elisp
(declare (indent 1))        ; 缩进规则：body 缩进 1 格
(declare (debug ...))       ; edebug 的调试规格
(declare (doc-string 2))    ; 第 2 个参数是 docstring
```

```
9) declare (indent 1) 决定缩进，本示例的 demo-when-let 就用了
```

`(declare (indent 1))` 让 `M-x indent-region` 和 `newline-and-indent` 知道怎么缩进你的宏 ——
不然它的缩进会很难看，用户会以为写错了。

## 23.10 什么时候不该写宏

```
10) 什么时候不该写宏：
```

只在**必须**的时候写宏：

- 需要改变**求值时机**（比如 `when` 的 body 只在条件成立时求值）；
- 需要改变**求值次数**（求值 0 次或多次）；
- 需要**发明语法**（`pcase` 的 `PATTERN` 那种）。

不需要上面任何一条时，**写函数**。宏的代价是：不能 `funcall`、不可读（要 mentally expand）、
出错难调、字节编译的警告更难懂。

---

# 第 24 章 模块、加载与打包

> 示例：`examples/24-packages.el`

## 24.1 feature：Elisp 的「模块」

```elisp
(provide 'demo-math)          ; 声明「这个文件提供了 demo-math」
(require 'demo-math)          ; 「我需要 demo-math」，没有就加载它
(featurep 'demo-math)         ; 已加载吗？
```

```
1) 'seq 已加载吗: t，'cl-lib 呢: t
4) require 之后: featurep = t, demo-add(3,4) = 7
```

`provide` 是文件的**出口声明**，`require` 是入口。Elisp 用「特性符号」而不是文件名来标识模块 ——
所以 `(require 'demo-math)` 时 Emacs 会去 `load-path` 里找「提供 `demo-math` 的文件」，
并按 `demo-math.el` / `demo-math.elc` 的名字去找。

## 24.2 load-path

```elisp
(add-to-list 'load-path "/path/to/your/package")
```

```
3) load-path 现在有 26 个目录，刚加的在最前面: "emacs-lib-tDEnn7"
```

`require` / `load` 会按 `load-path` 的顺序找文件。`add-to-list` 默认插到最前面，
所以你的目录会**优先**被搜到（可以用来覆盖内置的库，谨慎使用）。

## 24.3 【坑】require 找不到文件会报错

```elisp
(require 'demo-nope-nope)          ; → 报错！
(require 'demo-nope-nope nil t)    ; → nil（不报错）
```

```
6) require 不存在的（noerror=t）: nil
   不加 noerror 就会报错: 确实报错了
```

`require` 的第 3 个参数 `noerror` 为 `t` 时，找不到就返回 `nil` 而不是报错。
「有就用、没有就降级」的场景要写 `(require 'xxx nil t)`。

## 24.4 【重要】顶层 require 在编译期就会执行

这是本示例里最重要的一条经验，也是我写这个示例时实际踩到的坑：

```elisp
;; 这样写，如果运行期才生成的模块还不存在，编译就会失败！
(require 'demo-math)

(defun demo-use () (demo-add 3 4))
```

编译时报（实测）：

```
In toplevel form:
demo-package.el:2:11: Error: Cannot open load file: No such file or directory, demo-math
```

因为**顶层表单在字节编译时会被求值**（编译器需要知道符号的定义才能生成正确的代码）。
解决办法有两个：

- 把 `require` 挪进**函数体**里（函数体不会在编译期执行）；
- 或者用 `declare-function` 告诉编译器「这个函数将来会有」：

```elisp
(declare-function demo-add "demo-math" (a b))

(defun demo-use ()
  (require 'demo-math)          ; 挪进函数体，编译期不求值
  (demo-add 3 4))
```

改完之后编译零警告 —— 实测确认。

```
4) 下面这段整体包在一个函数里 —— 这是本示例最重要的一条经验
```

一般包的写法是：**依赖别人（内置库）的 `require` 放顶层**（编译期肯定存在），
**依赖「运行期才生成的东西」放进函数体**。

## 24.5 传递依赖自动处理

```elisp
;; demo-greet.el
(require 'demo-math)
(provide 'demo-greet)
```

```
5) 依赖被自动处理，demo-hi(10) = "hi, 11"
```

`require` 一个模块时，它内部的 `require` 也会被执行 —— 而且已经加载过的直接跳过。
这就是为什么 `provide` / `require` 能构成一个正确的依赖图。

## 24.6 load 与 load-file

```elisp
(load "demo-math")                                  ; 按 load-path 找，可不给扩展名
(load "demo-math" nil nil t)                        ; 第 4 个参数 t = 静默
(load-file "/abs/path/demo-math.el")                ; 按绝对路径加载
```

```
7) load-file 之后 featurep = t（重复加载不影响 feature）
```

区别：

| 函数 | 找文件的方式 | 管不管 `provide` |
|---|---|---|
| `require` | load-path，**按 feature 匹配，已加载则跳过** | 管 |
| `load` | load-path | **不管** |
| `load-file` | 绝对路径 | **不管** |

`load` / `load-file` 每次都会**重新执行**文件内容（调试时正好用得上）。

> 【坑】`load` 默认会往 stderr 打一行 `Loading xxx.el (source)...`。写脚本时要静音，
> 用 `load` 的第 4 个参数（NOMESSAGE）：
> ```elisp
> (load "demo-math" nil nil t)      ; 最后一个 t = 不打印
> ```
> 顺便说一句：老的 `load-verbose` 变量在 Emacs 31 里**已经不存在了**（`boundp` 返回 nil），
> 用 `let` 绑它不会报错但也不起作用。

## 24.7 autoload：启动快的关键

```elisp
;;;###autoload
(defun demo-heavy-command ()
  "..."
  (interactive))
```

```
8) autoload cookie 写法见上面注释
```

`;;;###autoload` 这个**注释**会被 `loaddefs-generate`（打包时则是 `package-generate-autoloads`）
扫出来，把「函数名 → 文件路径」的映射写进 `xxx-autoloads.el`。这样 Emacs 启动时只登记映射、
**不加载**你的文件；只有用户第一次调用那个命令时，才真正加载。

这是让「装了一堆包但启动还是很快」的机制。写包时**所有用户会直接调用的命令都应该加这个标记**。

## 24.8 with-eval-after-load

```elisp
(with-eval-after-load 'demo-math
  (princ "    demo-math 加载完成后执行这句\n"))
```

```
9) with-eval-after-load：
    demo-math 加载完成后执行这句
```

「等某个 feature 加载完之后再做配置」。这是 `eval-after-load` 的现代形式，
用户配置里非常常用（避免为了配一个包而提前加载它）。

## 24.9 package.el

```elisp
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/"))
(package-install 'some-package)
```

```
10) package-user-dir = "~/.emacs.d/elpa"
    package-archives 有 2 个源: ("gnu" "nongnu")
```

`package.el` 是内置的包管理器。相关的还有 `use-package`（第三方，但几乎是事实标准）——
它把「安装 + 配置 + 延迟加载」收在一个声明式结构里。

## 24.10 一个 .el 文件的标准头部

```
11) 文件头规范见上面注释，M-x checkdoc 会逐条检查
```

```elisp
;;; demo-package.el --- 一句话说明这个包做什么  -*- lexical-binding: t; -*-

;; Copyright (C) 2026  Your Name

;; Author: Your Name <you@example.com>
;; Version: 1.0.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: tools convenience
;; URL: https://example.com/demo-package

;; This file is not part of GNU Emacs.

;;; Commentary:

;; 这里是较长的说明：这个包做什么、怎么用、有什么已知限制。

;;; Code:

;; ... 你的代码 ...

(provide 'demo-package)
;;; demo-package.el ends here
```

`M-x checkdoc` 会逐条检查这些（docstring 格式、第一行是否为完整句子、
函数/变量的命名前缀等），`package-lint` 检查打包规范。**提交到 MELPA 之前必须过这两关。**

## 24.11 清理

```
12) 清理完成，临时目录还在吗: nil，demo-math 还是 feature 吗: nil
```

`(unload-feature 'demo-math)` 能把一个 feature 摘掉（它会撤销 `provide` 并恢复
被重新定义的函数）。写测试时很有用。

---

# 第 25 章 测试

> 示例：`examples/25-tests.el`

## 25.1 ERT 基础

`ert` 是 Emacs 内置的测试框架：

```elisp
(require 'ert)

(ert-deftest demo-math-add ()
  "加法应该正确。"
  (should (= (+ 1 1) 2))
  (should (= (+ 2 3) 5)))
```

用例名字约定**以包名开头**（`demo-math-...`），这样才能按前缀批量筛选。

## 25.2 should 家族

```elisp
(should expr)                  ; expr 为真则通过
(should-not expr)              ; expr 为假则通过
(should-error (error "x"))     ; 期待报错；可以指定错误符号
(should (equal got 'expected))
```

这四种覆盖了绝大多数断言需求。

`should-error` 可以带 `:type` 精确要求错误类型：

```elisp
(should-error (demo-fail) :type 'demo-timeout)
```

## 25.3 【重点】测试 buffer 相关代码要隔离

```elisp
(ert-deftest demo-render-test ()
  (with-temp-buffer            ; ← 一定要用这个
    (demo-mode)
    (demo-render)
    (should (string-match-p "..." (buffer-string)))))
```

原因：测试会改当前 buffer 的内容，不用 `with-temp-buffer` 就会破坏用户正在编辑的东西
（在 CI 里则是破坏别的测试的状态 —— 造成「单独跑能过、一起跑就挂」的诡异现象）。

## 25.4 mock：cl-letf

```elisp
(ert-deftest demo-uses-mock ()
  (cl-letf (((symbol-function 'demo-network-call)
             (lambda (&rest _) "fake-response")))
    (should (equal (demo-fetch) "fake-response"))))
```

```
4) 用 cl-letf 临时改写函数，做「mock」。
```

`cl-letf` 临时换掉函数实现，**出了 `let` 自动恢复** —— 所以不会污染其他测试。
测试网络、时间、外部进程这类「不可控依赖」时必须 mock。

## 25.5 构造测试场景：let 动态绑定

```elisp
(let ((demo-config '((mode . "test"))))     ; demo-config 是 defvar 的，所以这是动态绑定
  (should (equal (demo-current-mode) "test")))
```

```
5) 用 let 临时改写变量（动态绑定）来构造测试场景
```

利用第 3.4 节的规则：对 `defvar` 过的变量，`let` 是临时改全局值、退出自动恢复。
这是构造「不同配置下」测试的标准手段。

## 25.6 skip-unless

```elisp
(ert-deftest demo-needs-network ()
  (skip-unless (demo-network-available-p))
  ...)
```

```
6) skip-unless：某些环境不满足时跳过，而不是失败。
```

环境不满足（没有网络、不是某个平台、缺某个外部工具）时**跳过**而不是失败 ——
这样在别人的机器和 CI 上不会出现假的红色。

## 25.7 运行测试

```
7) 跑完全部用例：共 7 个，符合预期 6 个，不符合 1 个
   （要看每条用例的详情，就用命令行跑 -f ert-run-tests-batch-and-exit）
```

| 入口 | 用途 |
|---|---|
| `M-x ert` | 交互式，能看到每条用例和失败详情，可重跑 |
| `M-x ert-run-tests-batch-and-exit` | 命令行/CI，退出码反映成败 |
| `(ert-run-tests 't (lambda ...))` | 程序化调用，自己控制输出 |

**为什么示例里不用 `ert-run-tests-batch-and-exit`？** 因为它把结果写到 **stderr** ——
实测：

```bash
$ emacs -Q --batch -l test.el 2>/dev/null
      # ← stdout 是空的
$ emacs -Q --batch -l test.el 2>&1 1>/dev/null
Running 1 tests (2026-09-16 16:15:44+0800, selector 't-ok')
   passed  1/1  t-ok (0.000107 sec)

Ran 1 tests, 1 results as expected, 0 unexpected
```

在「stderr 必须为空」的判定下这会失败。所以示例里用了**静默监听器**，
自己统计并打印：

```elisp
(let ((stats (ert-run-tests 'demo-todo-test (lambda (&rest _args) nil))))
  (princ (format "7) 单元测试：共 %S 个用例，失败 %S 个\n"
                 (ert-stats-total stats)
                 (ert-stats-completed-unexpected stats))))
```

这算是一个通用的经验：**ERT 的默认输出是给人看的，不是给程序读的** ——
要把测试结果接进自己的流水线，就自己接 `ert-stats-*`。

## 25.8 按选择器筛选

```elisp
(ert-run-tests "^demo-todo" ...)      ; 名字匹配正则的
(ert-run-tests '(member demo-a demo-b) ...)   ; 指定的几个
(ert-run-tests '(tag :slow) ...)      ; 带某个 tag 的
```

```
8) 只跑名字含 heading 的用例：2 个
```

## 25.9 故意失败与 :failed

```
9) 故意失败的用例被标记为 :failed，ERT 记录为「符合预期」: t
```

`(should-error ...)` 之外，ERT 还支持把某个用例标记成「本来就应该失败」
（`ert-deftest` 的 `:expected-result :failed`）。用于记录已知的 bug：
它不会让构建变红，但你也没忘记它。

## 25.10 断言的粒度

```
10) 一个 ert-deftest 里第一个 should 失败就停，想全看就拆用例
```

一个用例里**第一个** `should` 失败，后面的就不再执行了。所以：

- 想一次看到所有问题 → 拆成多个小用例；
- 一个用例测「一件事」→ 更容易定位失败原因。

## 25.11 测试文件放哪

```
11) 测试文件命名：foo-tests.el，放 test/ 目录下
```

约定：

```text
my-package/
├── my-package.el
└── test/
    └── my-package-tests.el
```

命名用 `-tests.el` 后缀，这样 `M-x ert` 的默认选择器和各种构建工具都能识别。

---

# 第 6 部分 把一切串起来

# 第 26 章 完整示例：一个 todo 扩展

> 示例：`examples/26-todo-demo.el`

前面的 25 章都是零件。这一章把零件拼成一个**可用的扩展**，并且展示真实开发里
「一个功能需要哪几样东西配合」的完整清单。

## 26.1 这个扩展长什么样

一个记录待办的小工具，具备：

- 内存中的数据结构（`cl-defstruct`）
- 持久化（`read` / `prin1` 到文件）
- 一个 major mode 来显示列表（`define-derived-mode` + 字体锁）
- 键盘操作（keymap + 交互式命令）
- 单元测试（`ert`）

## 26.2 数据结构与持久化

```elisp
(cl-defstruct (demo-todo-item (:constructor demo-todo-item-create))
  title done)

(defun demo-todo-save ()
  (with-temp-file demo-todo-file
    (prin1 demo-todo-items (current-buffer))))   ; prin1 = 可被 read 回来

(defun demo-todo-load ()
  (with-temp-buffer
    (insert-file-contents demo-todo-file)
    (goto-char (point-min))
    (setq demo-todo-items (read (current-buffer)))))
```

```
3) 存盘后清空内存，再读回来：
    -> 已保存 3 条到 demo-todo-OKvImD.eld
   清空后总数 = 0
    -> 已读取 3 条
   读回后总数 = 3，未完成 = 2
   标题顺序 = ("回复邮件" "买咖啡" "写 Emacs 教程")
```

**`prin1` + `read` 是 Elisp 里最省事的数据持久化方式**：`prin1` 写出的文本能被 `read` 读回来,
不需要自己写序列化/反序列化。文件名用 `.eld` 后缀是 Emacs 的惯例（「Emacs Lisp Data」）。
内置的 `savehist` / `desktop` 都是这么做的。

## 26.3 major mode 与渲染

```elisp
(define-derived-mode demo-todo-mode special-mode "Todo"
  "待办列表的主模式。"
  ;; 【坑】special-mode 不会自动打开 font-lock，要自己开。
  (setq font-lock-defaults '(demo-todo-font-lock-keywords t))
  (font-lock-mode 1))
```

```
4) 渲染成 buffer 并检查高亮：
   buffer 内容:
[ ] 回复邮件
[x] 买咖啡
[ ] 写 Emacs 教程
   第 1 行（未完成的回复邮件）标题的 face = font-lock-string-face
   第 2 行（已完成的买咖啡）标题的 face = font-lock-comment-face
   第 2 行的下标属性 = 1
```

两处值得注意：

1. **`special-mode` 不会自动开 font-lock**，必须自己 `(font-lock-mode 1)`。派生自
   `prog-mode` / `text-mode` 的 mode 则是自动开的 —— 这个差异很容易忽略（第 16.3 节也提过）。
2. **每个列表项都带一个「下标」文本属性**（`demo-todo--index-at-point`），
   这样命令就知道「光标在哪一项上」。这是「行列表」型 mode 的标准做法 ——
   用文本属性把「显示」和「数据」关联起来，而不是靠数行号。

## 26.4 键盘操作

```elisp
(goto-char (point-min))
(forward-line 2)
(demo-todo-toggle-at-point)      ; 标记完成
```

```
5) 在列表 buffer 里用键盘命令操作：
    -> 完成：写 Emacs 教程
    -> 共 3 条，未完成 1 条
   切换后未完成 = 1
    -> 已删除：回复邮件
    -> 共 2 条，未完成 0 条
   删除后总数 = 2，剩下的 = ("买咖啡" "写 Emacs 教程")
```

模式是「命令改数据 → 重新渲染 → 光标回到原来的项」。这是「数据结构是真相、buffer 只是视图」
的思路 —— 比「直接在 buffer 里改文本再解析回来」健壮得多，也是**大多数成熟 mode 的做法**。

## 26.5 清理

```
6) 清理已完成：
    -> 清掉了 2 条已完成
   清理后总数 = 0
8) 临时数据文件已清理: t
```

## 26.6 单元测试

```
7) 单元测试：共 4 个用例，失败 0 个
```

测试覆盖了「增删改、持久化往返」这些核心路径。**扩展有测试和没测试的差别，
在于你敢不敢改它** —— 改完之后跑一遍，就知道有没有破坏别的地方。

## 26.7 一个扩展的完整清单

把这一章的东西抽象一下，就是写任何扩展都可以照抄的清单：

| 需要什么 | 用什么 | 本指南章节 |
|---|---|---|
| 数据结构 | `cl-defstruct` / alist | 9.6 / 7.9 |
| 持久化 | `prin1` + `read` | 26.2 |
| 用户选项 | `defcustom` | 18 |
| 显示 | major mode + font-lock | 16 |
| 操作 | `interactive` 命令 + keymap | 13 / 14 |
| 状态关联 | 文本属性 / overlay | 11 |
| 扩展点 | hook | 17 |
| 后台任务 | timer / process | 20 / 21 |
| 健壮性 | `condition-case` + `unwind-protect` | 22 |
| 组织 | `provide` / `require` | 24 |
| 保证不坏 | `ert` | 25 |

---

# 附录 A 常见坑速查

按「症状 → 原因 → 解法」排列。这些全部来自本仓库示例的开发过程。

## A.1 编译/验证类

| 症状 | 原因 | 解法 |
|---|---|---|
| batch 模式跑了但什么都没输出 | 用了 `message`，它走 stderr | 改用 `(princ (format ...))` |
| 「stderr 为空」判定失败 | 字节编译产生了警告 | 看 `.compile.err`，逐条消掉 |
| 输出里有乱码/控制字符 | `%S` 打印了键序列或 advice 对象 | 用 `key-description` / `(and x t)` |
| 编译报 Cannot open load file | 顶层 `require` 一个运行期才存在的东西 | 挪进函数体 / `declare-function` |
| 编译报 Unused lexical variable | `dotimes` 的 RESULT 表达式没用循环变量 | 让结果式引用它，或改用 `let` |
| 编译报 reference to free variable | 用了编译器不认识的错误符号（如 `no-catch`） | 用 `error` 兜 |
| batch 里定时器不触发 | 没有事件循环 | 用 `sleep-for` 推进 |
| batch 里 idle timer 不触发 | 没有「空闲」概念 | 无解，改交互式测 |

## A.2 语义类

| 症状 | 原因 | 解法 |
|---|---|---|
| `(eq 1.0 1.0)` 是 nil | `eq` 比对象身份 | 数字用 `=`，结构用 `equal` |
| `alist-get` 对字符串 key 总返回 nil | 它默认用 `eq` 比 | `(alist-get k a nil nil #'equal)` |
| `assq` 查不到字符串 key | 同上 | 用 `assoc` |
| `(if x ...)` 里 0 走了 then | 0 在 Elisp 里是真 | 显式判 `(/= x 0)` |
| `(substring "abc" 0 99)` 没报错 | 越界被截断 | 自己检查范围 |
| `(string-to-number "abc")` 是 0 | 转换失败不报错 | 用正则先校验 |
| `split-string` 把空字段吃掉了 | 默认丢空串 | 第 3 个参数传 `t` |
| `(delete x list)` 后 `list` 还是旧的 | `delete` 可能返回新头 | 接收返回值 `(setq list (delete ...))` |
| 改了 `y` 的 `x` 也变了 | `setq` 共享结构 | `copy-tree`（深）或 `copy-sequence`（浅） |
| closure 全都捕获到同一个值 | 循环变量是 `defvar` 过的 special 变量 | 别 `defvar` 循环变量 |

## A.3 编辑器对象类

| 症状 | 原因 | 解法 |
|---|---|---|
| 相对路径写到了奇怪的地方 | `default-directory` 是 buffer 局部的 | 传绝对路径或 `let` 指定 |
| `directory-files` 结果里有 `"."` `".."` | 默认不过滤 | 用锚定正则 `"\\`[^.]"` |
| font-lock 设了但不生效 | 父类是 `special-mode`，不自动开 | body 里显式 `(font-lock-mode 1)` |
| `search-forward` 之后替换了错的地方 | point 停在匹配**末尾** | 配合 `replace-match`，或先取 `match-beginning` |
| `invisible` 的文本还能被搜索到 | 它只是不显示 | 处理 `buffer-invisibility-spec` |
| `derived-mode-parent` 是 nil | parent 是 `fundamental-mode` | 用 `derived-mode-p` 判断 |
| `equal` 认为带 face 的字符串相等 | `equal` 忽略文本属性 | `equal-including-properties` |
| 「按键不生效」 | 被更优先的 keymap 覆盖 | 按 minor → local → global 顺序查 |

## A.4 扩展机制类

| 症状 | 原因 | 解法 |
|---|---|---|
| `M-x` 里找不到自己的函数 | 忘了 `(interactive)` | 加上 |
| hook 执行顺序和预期相反 | `add-hook` 默认插到最前面 | 第 3 个参数传 `t`，或用 DEPTH |
| 摘不掉 hook 里的函数 | 加的是 lambda | 一律用具名函数 |
| 关掉 mode 后别的 buffer 受影响 | hook 装成了全局的 | `(add-hook ... nil t)` |
| `advice-remove` 删不掉 | advice 是 lambda | 用具名 `defun` |
| advice 摘不掉 / 卸载后还生效 | 没用 `unwind-protect` | 包在 `unwind-protect` 里 |
| `setq` 改了 `defcustom` 但没生效 | `:set` 只有 customize 路径才触发 | 用 `customize-set-variable` |
| `:set` 里 `set-default` 忘了写 | 只执行了副作用 | 先 `set-default` |
| `cancel-timer` 取消不掉 | 没存 timer 对象 | `(setq timer (run-with-timer ...))` |
| `require` 不存在的库把整个加载搞挂 | 默认会报错 | `(require 'x nil t)` |

## A.5 进程/异步类

| 症状 | 原因 | 解法 |
|---|---|---|
| sentinel 里判断状态失败 | event 末尾带换行 | 用 `process-exit-status` |
| 子进程一直不返回 | 没发 EOF | `process-send-eof` |
| Emacs 卡住 | 用了同步 `call-process` | 改 `make-process` 异步 |
| 参数里的空格被拆开了 | 整串交给了 shell | 命令和参数分开传 |
| 定时器里的错看不到 | 错误被 Emacs 吃掉 | 自己 `condition-case` 并打印 |
| 找不到外部命令时错误难懂 | 没预检查 | `(executable-find ...)` 先查 |

---

# 附录 B 命令与变量速查

## B.1 交互式命令

| 命令 | 作用 |
|---|---|
| `M-x eval-buffer` | 重新加载当前 buffer 的代码 |
| `M-x eval-defun` / `C-M-x` | 重新求值当前函数 |
| `M-x toggle-debug-on-error` | 出错时弹 backtrace |
| `M-x checkdoc` | 检查 docstring/注释规范 |
| `M-x package-lint-current-buffer` | 检查打包规范（需装包） |
| `M-x ert` | 交互式跑测试 |
| `M-x profiler-start` / `profiler-report` | 性能分析 |
| `M-x list-faces-display` | 看所有 face 长什么样 |
| `M-x describe-key` / `C-h k` | 看某个键绑了什么 |
| `M-x describe-function` / `C-h f` | 看某个函数（含它的 advice） |
| `M-x describe-variable` / `C-h v` | 看某个变量的值和文档 |
| `M-x byte-compile-file` | 手动编译一个文件 |

## B.2 batch 命令行

```bash
# 加载文件
emacs -Q --batch -l file.el

# 求值一个表达式
emacs -Q --batch --eval '(princ "hi\n")'

# 字节编译（会检查警告）
emacs -Q --batch --eval '(byte-compile-file "file.el")'

# 跑 ERT 测试（结果写 stderr，退出码反映成败）
emacs -Q --batch -l file.el -f ert-run-tests-batch-and-exit

# 编译出的 .elc 直接加载
emacs -Q --batch -l file.elc
```

## B.3 常用变量

| 变量 | 含义 |
|---|---|
| `load-path` | `require` / `load` 的搜索路径 |
| `user-emacs-directory` | 用户配置目录（默认 `~/.emacs.d/`） |
| `temporary-file-directory` | 系统临时目录 |
| `default-directory` | 当前 buffer 的相对路径基准（buffer 局部） |
| `shell-file-name` / `shell-command-switch` | 当前平台的 shell |
| `minor-mode-map-alist` / `minor-mode-alist` | minor mode 的 keymap / mode-line 显示 |
| `auto-mode-alist` | 文件后缀 → major mode |
| `features` | 已加载的 feature 列表 |
| `timer-list` / `timer-idle-list` | 活跃的定时器 |
| `emacs-major-version` / `emacs-minor-version` | 版本号 |
| `most-positive-fixnum` | 最大的 fixnum（超过会变 bignum） |
| `print-gensym` | `%S` 是否把未 interned 符号显示成 `#:x` |

## B.4 判定标准（本仓库）

跑 `./run-all.sh` 或 `.\build.ps1 -All` 时，每个示例要过四关：

1. 字节编译退出码为 0；
2. 编译 stderr 为空（等价于零警告）；
3. 运行退出码为 0，运行 stderr 为空；
4. stdout 无多余控制字符，且有结束标记 `==== NN 结束 ====`。

---

## 写完之后

到这里你已经有了写扩展需要的全部工具。接下来最好的练习是**找一件你自己每天都烦的事**，
把它做成一 `defcustom` + 一个命令 + 一个 minor mode 的小包。真实需求会逼你把上面这些机制
一个个用起来 —— 而且你会遇到本指南里没写的坑，那很正常。等你遇到的时候，
回来读一读相关的那一章，再回去改。

Emacs 的扩展生态就是这样长出来的：一个人解决自己的问题，然后分享出去。

