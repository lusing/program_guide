# 23 · 宏

> 所属部分：第 5 部分 · 工程化
>
> **本部分导读**：最后一部分是「怎么写一个正经的包」：宏（写出好用的接口）、模块与加载（组织代码）、 测试（保证它一直能用）。

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

上一章：[22 · 错误处理](22-errors.md)　｜　下一章：[24 · 模块、加载与打包](24-packages.md)　｜　返回：[Emacs 扩展开发指南](README.md)
