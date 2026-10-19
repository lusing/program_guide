# 03 · 变量与绑定

> 所属部分：第 1 部分 · 语言基础
>
> 示例：`examples/03-variables.el`

Elisp 的变量只有两个动作——**定义**和**绑定**——但「绑定的种类」比大多数语言多：全局的、局部的、动态的、词法的、buffer 局部的。这一章把它们逐个分清，重点是 3.4 节的 special/lexical 之分，它是理解 Emacs 扩展行为的钥匙。

## 3.1 setq 与 defvar：两个不同的动作

```elisp
(defvar demo-counter 0)
(setq demo-counter 10)
(princ (format "setq 之后：demo-counter = %S\n" demo-counter))
```

```
setq 之后：demo-counter = 10
```

`setq` 给**已存在**的变量赋值。`defvar` 声明一个变量并给初值——但它有个必须记住的特性：

```elisp
(defvar demo-counter 999)          ; 不会生效，上一行的 10 还在
(princ (format "再次 defvar 999 之后：demo-counter = %S\n" demo-counter))
```

```
再次 defvar 999 之后：demo-counter = 10
```

> **`defvar` 只在变量「还没有值」的时候才赋初值。** 重复执行 `defvar` 不会覆盖已有值。

这个设计是为了让「用户配置不被包的重新加载覆盖」：用户在 init 文件里 `(setq my-var 42)`，之后包重新加载时它的 `(defvar my-var 0)` 不会把用户的 42 冲掉。但写代码时如果指望「`defvar` 会重置变量」，就会困惑很久——**想强制重置用 `setq`**。

顺带：在开了 `lexical-binding: t` 的文件里，顶层直接用 `setq` 建新变量会被字节编译器警告 `reference to free variable`。所以本仓库示例的顶层变量一律先 `defvar`。

`defconst` 是类似的声明，但它承诺「这是常量，改它是不对的」——适合放真正的固定值（比如一个版本的魔数）。它同样只在未定义时生效。

## 3.2 let 与 let*：局部绑定

```elisp
(princ (format "let: %S\n" (let ((a 1) (b 2)) (+ a b))))
(princ (format "let*: %S\n" (let* ((a 10) (b (* a 2))) b)))
```

```
let: 3
let*: 20
```

区别只在**初值的求值环境**：

- `let` 的所有初值在**外层**环境求值，互相看不见（并行绑定）；
- `let*` 的每个初值能看到**前面**的绑定（串行绑定）。

所以 `(let ((a 1) (b (+ a 1))) ...)` 里的 `a` 是外层的 `a`（或不存在，报 `void-variable`）。**只要初值之间有依赖，就用 `let*`**；没有依赖时两者等价，用 `let` 表意更清楚。

`let` 的 body 可以有任意多条表达式，返回最后一条的值——它是 Elisp 里最常用的「临时状态」手段。

## 3.3 遮蔽与恢复

```elisp
(princ (format "遮蔽：%S\n"
               (let ((x "外层"))
                 (list x (let ((x "内层")) x) x))))
```

```
遮蔽：("外层" "内层" "外层")
```

内层 `let` 建立新绑定，挡住外层的同名变量；出了内层 `let`，外层绑定自动恢复。**这就是 Lisp 里「局部状态」的全部机制**——不需要手动保存/还原，栈自动搞定。写「临时改一个全局变量再改回来」的代码时，优先考虑能不能改用 `let` 包起来。

## 3.4 关键区别：special 变量 vs 词法绑定

这是本章最重要的一节。同一个 `let`，对「被 `defvar` 声明过的变量」和「普通变量」做的事**完全不同**。

先看 special 变量（被 `defvar`/`defcustom` 声明过的都是）：

```elisp
(defvar demo-greeting "hello")
(defun demo-say () (concat demo-greeting " world"))
(princ (format "平常：%S\n" (demo-say)))
(princ (format "let 动态绑定后：%S\n" (let ((demo-greeting "hi")) (demo-say))))
(princ (format "出了 let：%S\n" (demo-say)))
```

```
平常："hello world"
let 动态绑定后："hi world"
出了 let："hello world"
```

关键点：`demo-say` **没有接收** `demo-greeting` 作为参数，但它在 `let` 里被调用时，读到的是 `let` 绑定的那个值。这就是**动态作用域**（dynamic binding）：`let` 不是造一个只有本层看得见的局部变量，而是**临时改写这个全局变量的当前值**，期间任何代码读到它都是新值。

再看没被 `defvar` 声明过的变量——在 `lexical-binding: t` 的文件里，它们是**词法绑定**，`let` 造的是真正的局部变量，lambda 捕获它形成闭包：

```elisp
(defun demo-make-adder (n) (lambda (x) (+ x n)))
(princ (format "闭包：(adder 10) 5 = %S, (adder 3) 4 = %S\n"
               (funcall (demo-make-adder 10) 5)
               (funcall (demo-make-adder 3) 4)))
```

```
闭包：(adder 10) 5 = 15, (adder 3) 4 = 7
```

两次调用 `demo-make-adder` 造出两个闭包，各自捕获「当时的 `n`」（10 和 3），互不干扰。

**判断规则**（背下来）：

> 文件第一行有 `lexical-binding: t`，且变量**没被** `defvar`/`defcustom` 声明过 → 词法绑定。
> 被 `defvar`/`defcustom` 声明过 → special 变量，`let` 对它是动态绑定。

两个直接结论：

- 想要「真正的局部变量」（比如循环变量、闭包要捕获的）→ 别 `defvar`，直接 `let`；
- 想要「可以被动态绑定的全局配置」→ `defvar`。第 17 章的「一次性 hook」、`inhibit-read-only` 这类机制，全是动态绑定的应用。

> 没有 `lexical-binding: t` 的老文件里，所有 `let` 都是动态绑定。本仓库示例第一行都带这行标记，2026 年写 Elisp 也应如此。

## 3.5 buffer-local 变量：每个 buffer 一份值

Emacs 的变量还有第三种存法：**buffer 局部**。同一个变量，每个 buffer 可以有自己的一份值——这是扩展里存状态最常用的手段。

```elisp
(defvar-local demo-indent 4)
(setq-default demo-indent 4)
(let ((other (generate-new-buffer "demo-other")))
  (with-temp-buffer
    (setq demo-indent 8)
    (princ (format "buffer 内 = %S, 默认值 = %S, 另一个 buffer = %S\n"
                   demo-indent
                   (default-value 'demo-indent)
                   (buffer-local-value 'demo-indent other))))
  (kill-buffer other))
```

```
buffer 内 = 8, 默认值 = 4, 另一个 buffer = 4
```

三个概念分清：

| 概念 | 读法 | 含义 |
|---|---|---|
| 默认值 | `(default-value 'demo-indent)` | 所有 buffer 共享的底值 |
| 当前值 | `demo-indent` | 当前 buffer 的值（可能被 buffer 局部绑定覆盖） |
| 指定 buffer 的值 | `(buffer-local-value 'demo-indent buf)` | 某个 buffer 的那一份 |

配套的三个设置函数：`setq` 改当前 buffer 的值，`setq-local` 是「在 mode 函数里设当前 buffer」的标准写法（它是 `setq` 对 buffer-local 变量的语义糖），`setq-default` 改全局默认值。**在 major/minor mode 函数里设变量，一律 `setq-local`**（第 15、16 章会反复用）。

## 3.6 boundp 与 makunbound

```elisp
(princ (format "boundp demo-counter = %S, boundp 不存在的 = %S\n"
               (boundp 'demo-counter) (boundp 'demo-never-defined)))
```

```
boundp demo-counter = t, boundp 不存在的 = nil
```

`boundp` 查「变量有没有值」（对 buffer-local 变量，它查的是当前 buffer）；`fboundp` 查「函数有没有定义」。这俩是写**多版本兼容代码**的标准手段：

所以兼容写法统一是「**先问符号在不在，再用它**」。示例里问的是 `string-search`（Emacs 28 才有的函数）：

```elisp
;; fboundp 是「函数版」的 boundp。写要跨多个 Emacs 版本运行的扩展时，
;; 标准做法就是先问「这个符号在不在」，再用它。
(princ (format "fboundp 'string-search = %S, fboundp 不存在的函数 = %S\n"
               (fboundp 'string-search) (fboundp 'demo-never-defined-fn)))
(when (fboundp 'string-search)
  (princ (format "   string-search 可用: %S\n" (string-search "cad" "abracadabra"))))
```

```text
fboundp 'string-search = t, fboundp 不存在的函数 = nil
   string-search 可用: 4
```

把上面的 `#'string-search` 换成任何一个「你的扩展想用、但老版本可能没有」的函数，就是完整的多版本兼容写法。变量同理，把 `fboundp` 换成 `boundp`、`#'string-search` 换成 `'那个变量名` 即可。再配合 `emacs-major-version` / `emacs-minor-version` 做粗粒度版本判断（第 2 章），一份扩展就能同时跑在多个 Emacs 版本上。

`makunbound` 解除一个变量的绑定，让它回到「void」状态：

```elisp
(defvar demo-tmp nil "只为演示 makunbound：先给它一个值，再解除绑定。")
(setq demo-tmp 1)
(makunbound 'demo-tmp)
(princ (format "makunbound 之后 boundp = %S\n" (boundp 'demo-tmp)))
```

```text
makunbound 之后 boundp = nil
```

日常几乎不用，但知道它存在有助于理解「void-variable」错误的本质：**符号存在，只是没有值**——所以 `boundp` 返回 `nil`，而读它会报错。

## 3.7 本章小结

| 形式 | 作用 | 关键语义 |
|---|---|---|
| `setq` | 赋值 | 多个一起赋：`(setq a 1 b 2)` |
| `defvar` / `defconst` | 声明 + 初值 | **只在未定义时生效** |
| `let` | 局部绑定 | 初值并行求值，互相看不见 |
| `let*` | 局部绑定 | 初值串行，后面看得见前面 |
| `defvar-local` | buffer 局部声明 | 每个 buffer 一份值 |
| `setq-local` / `setq-default` | 设当前 buffer / 默认值 | mode 函数里用前者 |
| `boundp` / `fboundp` | 查存在 | 版本兼容的基石 |

---

上一章：[02 · 类型与值](02-types.md)　｜　下一章：[04 · 函数](04-functions.md)　｜　返回：[Emacs 扩展开发指南](README.md)
