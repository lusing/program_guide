# 23 · 宏

> 所属部分：第 5 部分 · 工程化
>
> **本部分导读**：最后一部分是「怎么写一个正经的包」：宏（写出好用的接口）、模块与加载（组织代码）、 测试（保证它一直能用）。

> 示例：`examples/23-macros.el`

宏是 Elisp 里唯一能「发明新语法」的机制。`when`、`dolist`、`if-let`、`with-temp-buffer`、`pcase` 全都是宏——它们在 `subr.el`、`cl-lib`、`pcase.el` 里躺着，用起来跟语言内置的一样自然。本章讲清楚它怎么做到的，以及写宏最容易踩的三个雷。

## 23.1 宏和函数的根本区别

示例里先写一个「把变量加 1」的宏。第一版**不用** backquote，手写 `list` 拼表达式，让你看清宏到底在干什么：

```elisp
;; 函数和宏的根本区别：
;;    函数 —— 参数先求值，再传进去；
;;    宏   —— 参数**不求值**，原样传进来，宏返回一个「新的表达式」，
;;            这个表达式在宏的位置上被求值。
;;    所以宏能做函数做不到的事：发明新的控制结构、避免参数被多次求值之外的开销。
(defmacro demo-incr (var)
  "把 VAR 加 1（宏版本，为了演示语法）。"
  (list 'setq var (list '1+ var)))

(defvar demo-n 10)
(demo-incr demo-n)
(princ (format "1) 宏展开结果: %S，执行后 n = %S\n"
               (macroexpand-1 '(demo-incr demo-n)) demo-n))
```

```text
1) 宏展开结果: (setq demo-n (1+ demo-n))，执行后 n = 11
```

关键点在这一行：

```elisp
(macroexpand-1 '(demo-incr demo-n))    ; → (setq demo-n (1+ demo-n))
```

- **函数**：参数先求值，函数体拿到的是**值**；
- **宏**：参数**不求值**，宏体拿到的是**表达式本身**（这里就是符号 `demo-n`），返回一个新表达式，然后那个表达式被求值。

`(list 'setq var (list '1+ var))` 里的 `var` 在宏展开时等于 `demo-n`，所以拼出来的是 `(setq demo-n (1+ demo-n))`。宏的返回值**就是一段代码**。

所以宏能做函数做不到的事：**发明新的控制结构**。

反过来看代价——宏不是值：

```elisp
;; 什么时候不该写宏：
;;     能用函数就用函数。函数能作为值传递、能出现在 mapcar 里、
;;     能被 advice、能进 hook —— 宏一样都不行。
;;     只在「需要控制求值时机」或「要发明新语法」时才写宏。
(princ (format "10) 函数是 %S，宏是 %S —— 宏不能当值传\n"
               (functionp #'demo-incr)
               (macrop #'demo-incr)))
```

```text
10) 函数是 nil，宏是 t —— 宏不能当值传
```

判断：`(functionp 'foo)` 对宏是 `nil`，`(macrop 'foo)` 是 `t`。**宏不能 `funcall`、不能 `mapcar`、不能存进变量**——因为它是「编译期就消失的东西」，运行时只剩下展开后的代码。

## 23.2 backquote：拼表达式的工具

手写 `(list 'setq var (list '1+ var))` 太痛苦了。backquote（`` ` ``）就是为此而生的模板语法：

```elisp
;; 手写 list 拼表达式太痛苦，用 backquote（`）：
;;      `  反引号开始模板
;;      ,  逗号 = 求值并插入
;;      ,@ 逗号@ = 求值（结果必须是列表）并**摊平**插入
;; 上面那个宏用 backquote 写就是这样 —— 可读性天差地别。
(defmacro demo-incr2 (var)
  "把 VAR 加 1（backquote 版本）。"
  `(setq ,var (1+ ,var)))
(princ (format "2) backquote 写法展开: %S\n" (macroexpand-1 '(demo-incr2 demo-n))))
(demo-incr2 demo-n)
(princ (format "   执行后 n = %S\n" demo-n))
```

```text
2) backquote 写法展开: (setq demo-n (1+ demo-n))
   执行后 n = 12
```

展开结果和第一版**逐字节相同**。三个记号：

- `` ` `` 类似于 `'`，构造一个列表但**不阻止求值**（被 `,` 标记的部分会求值）；
- `,expr` —— 求值 expr 并把结果插进这个位置；
- `,@expr` —— 求值 expr（必须是个列表）并把它的元素摊开插进去。

`,@` 是写宏时最常用的东西，用来把 `&rest body` 展开到生成的结构里——下一节就见到。

## 23.3 宏的价值：发明控制结构

下面这个 `demo-when-let`：绑定一个值，值非 nil 才执行 body。它用函数**写不出来**，因为 body 必须「条件成立时才求值」——函数的参数早就求值完了。

```elisp
;; 宏的价值在于「发明控制结构」。下面这个 unless 的孪生兄弟：
;;    只有条件为真才执行。
(defmacro demo-when-let (binding &rest body)
  "绑定 BINDING，若其值非 nil 则执行 BODY。
BINDING 形如 (VAR EXPR)。"
  (declare (indent 1) (debug (sexp body)))
  `(let ((,(car binding) ,(cadr binding)))
     (when ,(car binding)
       ,@body)))
(princ (format "3) when-let 展开: %S\n"
               (macroexpand-1 '(demo-when-let (x 5) (princ x)))))
(demo-when-let (found (seq-position '(a b c) 'b))
  (princ (format "   找到 b，位置 = %S\n" found)))
(demo-when-let (missing (seq-position '(a b c) 'z))
  (princ (format "   这行不会执行: %S\n" missing)))
```

```text
3) when-let 展开: (let ((x 5)) (when x (princ x)))
   找到 b，位置 = 1
```

三行输出各说一件事：

1. 展开式里 `,@body` 把 `(princ x)` 摊了进去；
2. 绑定成功（找到 `b`，位置 1）→ body 执行；
3. 绑定值是 `nil`（没找到 `z`）→ body **一次都没执行**，所以第三行没输出。

第 3 点就是宏的价值：如果 `demo-when-let` 是函数，`(princ ...)` 早在调用前就求值了，你没法「不执行它」。

**只有需要「改变求值时机/次数」时才写宏** —— 如果只是想把代码收敛一下，用函数。

## 23.4 【大坑】变量捕获

```elisp
;; 【大坑】变量捕获（variable capture）。
;; 宏展开时引入的绑定名，如果正好和调用方的变量名撞上，
;; 调用方的代码就会被「劫持」—— 而且完全看不出为什么。
(defmacro demo-bad-capture (body)
  "错误示范：宏内部用了固定的名字 x。"
  `(let ((x 99))
     ,body))
(princ (format "4) 展开式: %S\n" (macroexpand-1 '(demo-bad-capture x))))
(princ (format "   调用方 (let ((x 1)) ...) 里拿到: %S  <- 期望 (1 1)，实际第一个被劫持\n"
               (let ((x 1)) (list (demo-bad-capture x) x))))
;;    用 macroexpand-all 展开到底，就能看清「劫持」是怎么发生的。
(princ (format "   把调用方那行展开到底: %S\n"
               (macroexpand-all '(let ((x 1)) (list (demo-bad-capture x) x)))))
```

```text
4) 展开式: (let ((x 99)) x)
   调用方 (let ((x 1)) ...) 里拿到: (99 1)  <- 期望 (1 1)，实际第一个被劫持
   把调用方那行展开到底: (let ((x 1)) (list (let ((x 99)) x) x))
```

调用方写的明明是 `(let ((x 1)) ...)`，结果 `x` 变成了 `99`。第三行是真相——`macroexpand-all` 把调用方那一行**递归展开到底**，露出了宏塞进去的 `(let ((x 99)) x)`，内层的 `x` 把外层遮住了。

（这正是 `macroexpand-all` 相对于 `macroexpand` 的用处：后者只管顶层，`let` 不是宏调用它就不往下走了。）

调用方的 `x` 被宏内部的 `x` 覆盖了 —— 而且从调用方的代码完全看不出为什么。这叫**变量捕获（variable capture）**，是写宏最容易犯的错。

## 23.5 修法：make-symbol

```elisp
;; 修法：用 make-symbol 造一个「未 interned」的符号，
;; 它跟任何用户写的符号都不 eq，自然不可能撞名。
;; 展开式里显示为 #:x 这种带 # 前缀的形式。
(defmacro demo-good-capture (body)
  "正确示范：用 make-symbol 生成唯一符号。"
  (let ((sym (make-symbol "x")))
    `(let ((,sym 99))
       ,body)))
;; 想看清 #: 前缀，要把 print-gensym 打开（默认是 nil，
;; 于是未 intern 的符号打印出来和普通的 x 一模一样，很容易看漏）。
(princ (format "5) 展开式: %S\n"
               (let ((print-gensym t))
                 (prin1-to-string (macroexpand-1 '(demo-good-capture x))))))
(princ (format "   调用方的 x 不受影响: %S\n"
               (let ((x 1)) (list (demo-good-capture x) x))))
```

```text
5) 展开式: "(let ((#:x 99)) x)"
   调用方的 x 不受影响: (1 1)
```

`make-symbol` 生成的符号**不在符号表里**（uninterned），跟任何用户写的符号都不 `eq`，所以不可能撞名。展开式里显示成 `#:x`。

> 【坑】`print-gensym` 控制是否显示 `#:` 前缀，而它**默认是 `nil`** —— 也就是说未 interned 的符号通常打印出来和普通 `x` 一模一样，你根本看不出它其实是「宏造的」。调试宏时把它设成 `t`（示例里就是这么做的），一眼就能分辨。

## 23.6 【坑】参数求值次数

```elisp
;; 参数求值次数。宏的参数会被**直接塞进展开式**，
;; 塞几次就求值几次 —— 这是新手最容易踩的雷。
(defmacro demo-bad-double (x)
  "错误示范：X 会被求值两次。"
  `(+ ,x ,x))
(defvar demo-side-effect 0)
(defun demo-bump ()
  "带副作用的函数。"
  (setq demo-side-effect (1+ demo-side-effect))
  1)
(princ (format "6) 求值两次: 结果 = %S，副作用执行了 %S 次\n"
               (demo-bad-double (demo-bump)) demo-side-effect))
```

```text
6) 求值两次: 结果 = 2，副作用执行了 2 次
```

宏的参数会被**原封不动地塞进展开式**，出现几次就被求值几次。所以：

- 如果参数是 `(f)` 这种有副作用的表达式，会被执行多次；
- 如果参数求值很贵，也会浪费。

**正确做法**：用 `let` 把它绑一次。示例里的修法同时用上了 `make-symbol`，一次解决两个坑：

```elisp
;; 正确做法：把参数**绑一次**再用 —— 用 make-symbol 造个唯一符号当临时变量，
;; 这样既只求值一次，又不会和调用方的变量撞名（见第 5 节）。
(defmacro demo-safe-double (x)
  "正确示范：X 只求值一次。"
  (let ((sym (make-symbol "e")))
    `(let ((,sym ,x))
       (+ ,sym ,sym))))
(setq demo-side-effect 0)
(princ (format "   改成先绑一次: 结果 = %S，副作用执行了 %S 次\n"
               (demo-safe-double (demo-bump)) demo-side-effect))
```

```text
   改成先绑一次: 结果 = 2，副作用执行了 1 次
```

结果同样是 `2`，但副作用只跑了 **1 次**。这也是为什么 `cl-lib` 的 `cl-incf` 之类的宏展开出来都是「先绑定再操作」。

## 23.7 调试宏的三个工具

```elisp
;; 调试宏的三个工具：
;;    macroexpand-1  展开一层
;;    macroexpand    反复展开直到不再是宏
;;    M-x pp-macroexpand-last-sexp  在 Emacs 里漂亮地打印上个性别的展开式
(princ (format "7) macroexpand-1: %S\n"
               (macroexpand-1 '(demo-when-let (a 1) a))))
(princ (format "   macroexpand:   %S\n"
               (macroexpand '(demo-when-let (a 1) a))))
```

```text
7) macroexpand-1: (let ((a 1)) (when a a))
   macroexpand:   (let ((a 1)) (when a a))
```

- `macroexpand-1` 只展开**一层**——如果展开结果里还有别的宏，它不管；
- `macroexpand` 反复展开直到顶层不再是宏（上面两者结果相同，因为 `let`/`when` 里 `when` 也是宏，但 `macroexpand` 不递归进子表达式）；
- 在 Emacs 里 `M-x pp-macroexpand-last-sexp` 可以把光标前的表达式展开并漂亮打印 —— 这是写宏最高效的工作方式。

## 23.8 【坑】宏在编译期展开

宏在**编译期**展开，所以宏体里只能用到「编译期已知」的东西。想在编译期算一个常量，就用 `eval-when-compile`：

```elisp
;; 【坑】宏在**编译期**展开，所以它只能用到编译期已知的东西。
;; 宏体里不能引用「运行时才知道的变量」—— 那个值根本还不存在。
;; 如果确实需要在编译期算点东西，用 eval-when-compile 包起来。
(defmacro demo-compile-time-info ()
  "在编译期把版本信息烧进代码。"
  `,(eval-when-compile (format "compiled-by-emacs-%d" emacs-major-version)))
(princ (format "8) eval-when-compile: %S\n" (demo-compile-time-info)))
```

```text
8) eval-when-compile: "compiled-by-emacs-31"
```

`eval-when-compile` 让这段代码在**编译时**求值一次，把结果直接嵌进展开式（运行时不再计算）。所以上面这个宏展开后其实就是字符串常量 `"compiled-by-emacs-31"`。

> 【坑】这个值是**编译它的那个 Emacs** 的版本，不是运行它的。把 `.elc` 拷到另一台装了别的 Emacs 版本的机器上，它仍然是 `compiled-by-emacs-31`。需要「运行时的版本」就不要用 `eval-when-compile`，直接在宏体里写 `(format ... emacs-major-version)`（那样每次调用都算）。

## 23.9 declare

```elisp
;; declare 声明：
;;      (indent N)         告诉 Emacs 怎么缩进这个宏（1 = 像 when 一样）
;;      (debug SPEC)       告诉 Edebug 怎么单步
;;      (doc-string N)     第 N 个参数是文档字符串
;; 没有 (indent 1) 的话，你的宏缩进会很丑。
(princ "9) declare (indent 1) 决定缩进，本示例的 demo-when-let 就用了\n")
```

```text
9) declare (indent 1) 决定缩进，本示例的 demo-when-let 就用了
```

`demo-when-let` 的定义里就带着一个真实例子：

```elisp
(declare (indent 1) (debug (sexp body)))
```

- `(indent 1)` 让 `M-x indent-region` 和 `newline-and-indent` 知道怎么缩进你的宏 —— 不然它的缩进会很难看，用户会以为自己写错了；
- `(debug (sexp body))` 告诉 Edebug 第一个参数是普通 sexp、后面是 body，这样 `C-u C-M-x` 单步调试时能正确走进宏体；
- `(doc-string N)` 用于「第 N 个参数是文档字符串」的宏（比如你自己写的 `defxxx`）。

## 23.10 什么时候不该写宏

只在**必须**的时候写宏：

- 需要改变**求值时机**（比如 `when` 的 body 只在条件成立时求值）；
- 需要改变**求值次数**（求值 0 次或多次）；
- 需要**发明语法**（`pcase` 的 `PATTERN` 那种）。

不需要上面任何一条时，**写函数**。宏的代价是：不能 `funcall`、不可读（要在脑子里展开一遍）、出错难调、字节编译的警告更难懂。

## 23.11 坑位清单

1. 把宏当函数用（`funcall` / `mapcar` / 存变量 / 进 hook）—— 宏不是值，`functionp` 返回 `nil`。
2. 忘了宏的参数**不求值** —— 参数是一段代码，不是值。
3. 宏体里用固定变量名 —— 变量捕获，调用方的同名变量被静默劫持；用 `make-symbol`。
4. 用 `(intern (concat "demo-" 某个名字))` 手拼符号当宏内临时变量 —— 那是 **interned** 的，照样会撞名。临时变量一律用 `make-symbol` 或 `gensym`：两者在 Emacs 里都生成**未 intern** 的符号，区别只是名字（`gensym` 会带一个自增计数）。
5. 参数在展开式里出现多次 —— 被求值多次，副作用重复执行；先 `let` 绑一次。
6. 忘了 `(declare (indent N))` —— 你的宏缩进很难看，用户以为写错了。
7. 用 `macroexpand-1` 看最终结果 —— 它只展一层；要看清嵌套宏用 `pp-macroexpand-last-sexp`。
8. 在宏体里引用运行时变量 —— 宏在编译期展开，那个值还不存在；需要编译期计算用 `eval-when-compile`。
9. 用 `eval-when-compile` 记版本号 —— 记的是**编译时**的版本，换台机器跑就错了。
10. 为了「少写几行」就写宏 —— 能用函数就用函数，宏的调试成本远高于它省下的行数。

---

上一章：[22 · 错误处理](22-errors.md)　｜　下一章：[24 · 模块、加载与打包](24-packages.md)　｜　返回：[Emacs 扩展开发指南](README.md)
