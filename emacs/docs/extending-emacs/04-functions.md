# 04 · 函数

> 所属部分：第 1 部分 · 语言基础
>
> 示例：`examples/04-functions.el`

函数在 Elisp 里是**一等对象**：能存进变量、能当参数传、能放进数据结构。本章从定义一路讲到「把函数当数据用」——后者是写扩展时最常用的手法。

## 4.1 基本定义与 docstring

```elisp
(defun demo-square (n)
  "返回 N 的平方。"
  (* n n))
(princ (format "square(7) = %S\n" (demo-square 7)))
```

```
square(7) = 49
```

docstring 不是可选的装饰：`C-h f`、eldoc（光标停在调用处时在 echo area 显示签名）、`checkdoc`、`package-lint` 全都读它。**公开函数必须写**，约定是第一行一句话说完、不超过 80 列。交互式命令的 docstring 还有额外作用——它是 `M-x` 补全时显示的说明（第 13 章）。

## 4.2 可选参数与变参

```elisp
(defun demo-greet (name &optional greeting)
  "用 GREETING（默认 \"Hello\"）问候 NAME。"
  (format "%s, %s!" (or greeting "Hello") name))
(princ (format "%S / %S\n" (demo-greet "Emacs") (demo-greet "Emacs" "你好")))
```

```
"Hello, Emacs!" / "你好, Emacs!"
```

`&optional` 后面的参数省略时是 `nil`，所以用 `or`（或 `if`）给默认值。参数一多位置就记不住，这时换 `cl-defun` 的 `&key`（第 9 章）会好很多。

`&rest` 把剩余参数收成一个列表：

```elisp
(defun demo-sum (&rest numbers)
  "返回 NUMBERS 的和。"
  (apply #'+ numbers))
(princ (format "sum(1 2 3 4) = %S，sum() = %S\n" (demo-sum 1 2 3 4) (demo-sum)))
```

```
sum(1 2 3 4) = 10，sum() = 0
```

`(apply #'+ nil)` 是 0，所以空参调用也正确——`apply` 和 `&rest` 是天生搭档。

参数列表完整形式：`(defun f (a &optional b (c 5 c-supplied-p) &rest rest) ...)`——可选参数可以直接给默认值，还能加第三个名字接收「调用方到底传没传」的布尔。

## 4.3 没有多返回值

Elisp 函数只有一个返回值。要返回多个值就打包成 `cons` 或 `list`，调用方解构：

```elisp
(defun demo-divmod (a b)
  "返回 (商 . 余)。"
  (cons (/ a b) (mod a b)))
(princ (format "divmod(17 5) = %S\n" (demo-divmod 17 5)))
```

```
divmod(17 5) = (3 . 2)
```

两个值用 `cons`（一个 cons 单元就够，`list` 要两个），取值 `(car r)` / `(cdr r)`；更多值用 `list` 打包，配合 `pcase-let` 或 `cl-destructuring-bind` 解构（第 5、9 章）。

## 4.4 lambda、funcall 与 apply

```elisp
(princ (format "funcall: %S\n" (funcall (lambda (x) (* x 2)) 21)))
(princ (format "apply:   %S\n" (apply #'max '(3 9 2))))
(princ (format "apply 混着传: %S\n" (apply #'list 1 2 '(3 4))))
```

```
funcall: 42
apply:   9
apply 混着传: (1 2 3 4)
```

区别：`funcall` 逐个传参；`apply` 的**最后一个参数必须是列表**，它会被展开成「最后一批参数」。两者都能调用「存在变量里的函数」——这是把函数当数据用的入口。

`apply-partially` 造「固定前几个参数」的新函数，是函数式组合的常用件：

```elisp
(princ (format "apply-partially: %S\n"
               (funcall (apply-partially #'* 10) 5)))
```

```
apply-partially: 50
```

## 4.5 【坑】`#'` 与 `'` 的差别

对**具名函数**，`#'foo` 和 `'foo` 都能用（`#'` 提示编译器「这是函数」，`'` 只是引用符号，调用时也能找到函数）。但对 **lambda 表达式**，差别是「对」和「错」：

```elisp
(princ (format "mapcar + #': %S\n" (mapcar #'demo-square '(1 2 3 4))))
```

```
mapcar + #': (1 4 9 16)
```

> 规则只有一条：**凡是「把函数当值传」的地方，lambda 一律写 `#'(lambda ...)`，或者直接写 `(lambda ...)` 不加任何 quote。** 用 `'` 去 quote lambda 是明确错误的——在 `lexical-binding: t` 下，`'` 得到的裸列表不会被当成闭包编译，自由变量的绑定会丢失，而且字节编译器不检查、不警告。

`#'` 读作 sharp-quote，写全就是 `(function (lambda ...))`。它和 `'`（即 `(quote ...)`）的差别只在「编译器知不知道这是个函数」。

## 4.6 函数存在变量里：分派表

把函数存进 alist，用 key 查出来 `funcall`——比一长串 `cond` 好维护得多：

```elisp
(defvar demo-ops (list (cons "+" #'+) (cons "*" #'*)))
(princ (format "分派表: %S\n"
               (mapcar (lambda (cell) (funcall (cdr cell) 6 7)) demo-ops)))
```

```
分派表: (13 42)
```

`(cons "+" #'+)` 把「加号函数」存进列表，`(cdr cell)` 取出来直接 `funcall`。这个模式在扩展里随处可见：第 16 章的字体锁、第 20 章的进程 filter、各种「按键 → 动作」的映射，底层都是它。key 是符号时，查找记得用 `assq`（第 6 章的坑）。

## 4.7 defalias：给函数起别名

```elisp
(defalias 'demo-sq #'demo-square)
(princ (format "defalias 别名: %S, functionp = %S\n"
               (demo-sq 9) (functionp #'demo-square)))
```

```
defalias 别名: 81, functionp = t
```

两个经典用途：

- 给长命令起短名（或者反过来，给内部函数起个对外的名字）；
- **覆盖内置函数**：`(defalias 'foo #'my-foo)` 之后，别的代码调用 `foo` 会走你的实现。调试和「临时打补丁」时很有用，正式包里慎用——用户可以用 `M-x foo` 发现不了。第 19 章的 advice 是更干净的替代。

`functionp` 判断「是不是函数对象」——注意它只对「可调用的函数对象」为真，`(functionp 'demo-square)`（quote 而非 sharp-quote）在某些情况下不为真，这也是该用 `#'` 的一个佐证。

## 4.8 本章小结

| 形式 | 用途 |
|---|---|
| `defun` + docstring | 定义函数（公开函数必须写 docstring） |
| `&optional` / `&rest` | 可选参数 / 变参 |
| `lambda` + `funcall` | 匿名函数 + 定参调用 |
| `apply` | 列表展开成最后一批参数 |
| `apply-partially` | 固定前几个参数，造新函数 |
| `#'` | 「这是函数」的标记，lambda 必须加 |
| `defalias` | 起别名 / 覆盖函数 |

---

上一章：[03 · 变量与绑定](03-variables.md)　｜　下一章：[05 · 控制流](05-control-flow.md)　｜　返回：[Emacs 扩展开发指南](README.md)
