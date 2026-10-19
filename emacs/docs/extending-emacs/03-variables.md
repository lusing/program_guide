# 03 · 变量与绑定

> 所属部分：第 1 部分 · 语言基础

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

上一章：[02 · 类型与值](02-types.md)　｜　下一章：[04 · 函数](04-functions.md)　｜　返回：[Emacs 扩展开发指南](README.md)
