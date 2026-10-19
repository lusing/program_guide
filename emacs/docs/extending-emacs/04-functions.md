# 04 · 函数

> 所属部分：第 1 部分 · 语言基础

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

上一章：[03 · 变量与绑定](03-variables.md)　｜　下一章：[05 · 控制流](05-control-flow.md)　｜　返回：[Emacs 扩展开发指南](README.md)
