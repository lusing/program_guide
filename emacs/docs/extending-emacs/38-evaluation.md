# 38 · 求值：quote、backquote 与 eval

> 所属部分：第 10 部分 · 对照参考手册补齐的主题

> 示例：`examples/38-evaluation.el`

「这段代码会得到什么」——这句话听起来简单，但在 Lisp 里它至少有**两层**：**读入时**（reader 把字符变成对象）和**求值时**（evaluator 把对象变成结果）。[01 · 第一个程序](01-hello.md) 讲过第一层，本章讲第二层，对应参考手册的 **Evaluation** 一章。

为什么值得单独一章？因为**宏、backquote、`eval` 这三件事，全都在跟「求值几次、什么时候求」打交道**。写宏时最常见的错误不是括号数错，而是「这个表达式会被求值两次」或者「它根本没被求值」。把求值规则想清楚，这些东西就从玄学变成了算数。

## 38.1 三种 form：自求值、符号、列表

任何 Lisp 对象被求值时，只有三种情况。示例第 1 节：

```elisp
(dolist (v (list 42 "字符串" :keyword [1 2] ?A))
  (princ (format "  自求值 %-10S -> %S\n" v (eval v))))
(princ (format "  符号 demo-dyn              -> %S\n" (eval 'demo-dyn)))
(princ (format "  列表 (+ 1 2)               -> %S\n" (eval '(+ 1 2))))
(princ (format "  列表 (1 2) 会当成函数调用  -> %S\n"
               (condition-case err (eval '(1 2))
                 (error (error-message-string err)))))
(princ (format "  空表 ()                    -> %S\n" (eval '())))
```

```
== 1) 三种 form ==
  自求值 42         -> 42
  自求值 "字符串"   -> "字符串"
  自求值 :keyword   -> :keyword
  自求值 [1 2]      -> [1 2]
  自求值 65         -> 65
  符号 demo-dyn              -> 7
  列表 (+ 1 2)               -> 3
  列表 (1 2) 会当成函数调用  -> "Invalid function: 1"
  空表 ()                    -> nil
```

- **自求值对象**：数字、字符串、关键字符号、向量、`t`、`nil`——求值结果就是自己。注意向量的例子：`[1 2]` 求值后还是 `[1 2]`，不会像列表那样被当成函数调用。**这就是「向量不需要 quote」的原因**。
- **符号**：求值是「取它的变量格」（[37 · 符号](37-symbols.md)）。`?A` 求值成 `65`，因为字符本来就是整数（[02 · 类型](02-types.md)）。
- **列表**：求值就是「调用」。列表的第一个元素决定它是函数调用、宏调用还是特殊形式。`(1 2)` 会报 `Invalid function: 1`——它试图把 `1` 当函数调用。
- **空表 `()`** 就是 `nil`，自求值，结果 `nil`。

## 38.2 quote：唯一的「不要求值」

```elisp
(princ (format "  '(+ 1 2)        = %S\n" '(+ 1 2)))
(princ (format "  (quote (+ 1 2)) = %S\n" (quote (+ 1 2))))
(princ (format "  ''a             = %S   它的 car = %S\n" ''a (car ''a)))
(princ (format "  (eval '(+ 1 2)) = %S\n" (eval '(+ 1 2))))
```

```
== 2) quote ==
  '(+ 1 2)        = (+ 1 2)
  (quote (+ 1 2)) = (+ 1 2)
  ''a             = 'a   它的 car = quote
  (eval '(+ 1 2)) = 3
```

`quote` 是**唯一的特殊形式之母**：它什么都不做，只把参数原样返回。所以 `'(+ 1 2)` 得到的就是一个三元素列表 `(+ 1 2)`，而不是 `3`。想要 `3` 就再 `eval` 一次。

`''a` 是「对 `(quote a)` 这个列表再 quote 一次」，所以它的 `car` 是符号 `quote`。打印时 Emacs 会把它缩写回 `'a`。

> 【坑】**quote 出来的列表是常量，别改它。** 示例里试了一下：
>
> ```
>   运行时改一下： (99 2 3)
>   字节编译器的警告： "‘setcar’ on constant list (arg 1)"
> ```
>
> 运行时看起来「成功了」，但这是未定义行为：字节编译器可能把 `'(1 2 3)` 和源码里另一个 `'(1 2 3)` 合并成同一个对象，也可能把它放进只读区域。**要一个可以改的列表就用 `(list 1 2 3)`**。

（示例里那个警告是**当场抓下来的**：把 `byte-compile-log-warning-function` 绑成一个收集器，再 `byte-compile` 那段代码，警告就变成了一个字符串，不会跑到 stderr 上。第 3 节、第 36 章都用了这个手法。）

## 38.3 `#'` 与 `'`：对 lambda 的差别

对普通符号，`#'foo` 和 `'foo` 完全一样（`function` 只是 `quote` 的一个「意图声明」版本）。**对 lambda 就不一样了**。示例第 3 节：

```elisp
(princ (format "  (functionp #'(lambda (x) x)) = %S\n" (functionp #'(lambda (x) x))))
(princ (format "  用 #' 的那个照样能 funcall： %S\n" (funcall #'(lambda (x) (* x 2)) 5)))
;;; 下面故意演示「用 ' 包 lambda」。为了让本文件自己编译得干净，这个被 quote
;;; 的 lambda 用 list 现场拼出来——with-no-warnings 压不住这条警告。
(let ((quoted-lambda (list 'lambda '(x) '(* x 2))))
  (princ (format "  (functionp %S) = %S，也照样能 funcall： %S\n"
                 (list 'quote quoted-lambda)
                 (functionp quoted-lambda) (funcall quoted-lambda 5))))
```

```
== 3) #' 与 ' ==
  (functionp #'(lambda (x) x)) = t
  用 #' 的那个照样能 funcall： 10
  (functionp '(lambda (x) (* x 2))) = t，也照样能 funcall： 10
  --- 区别在编译期：' 包 lambda 编译器就不再编译它 ---
  字节编译器的警告： "(lambda (x) ...) quoted with ' rather than with #'"
```

两者**在解释执行时行为一样**（都是 `functionp`、都能 `funcall`）。差别在编译期：

- `#'`（即 `(function (lambda ...))`）告诉字节编译器「**这是一个函数，请编译它**」，于是它被编译成字节码。
- `'` 只是产生一个列表。字节编译器看到 `'(lambda ...)` 会认为「这大概是要当数据用的」，**不再编译它**——于是运行时走解释器，慢，而且拿不到编译期的检查。

所以：**只要你是要当函数用的 lambda，一律写 `#'`**（包括传给 `mapcar`、`funcall`、`add-hook` 的时候）。

> 【坑】这条警告 **`with-no-warnings` 压不住**（示例里试过：把 `(functionp '(lambda (x) x))` 包进 `with-no-warnings` 照样报警）。要在本文件里演示「被 quote 的 lambda」又不产生警告，只能像示例那样用 `list` 现场拼出同样的结构。

## 38.4 backquote：模板 + 挖洞

写宏时最烦的事是「拼一个很长很长的 list」：

```elisp
;; 想要生成 (defun foo (x) (* x x))
(list 'defun 'foo '(x) (list '* 'x 'x))
```

backquote（反引号 `` ` ``）就是为这个发明的：它让你**照着结果的形状写**，只在需要「求值」的地方挖个洞。示例第 4 节用 `macroexpand` 把它展开，看清它到底变成了什么：

```elisp
(dolist (form (list '`(a b)
                    '`(a ,b)
                    '`(a ,b ,@c)
                    '`(a ,b ,@c . d)
                    '`(a ,(list 1 2))))
  (princ (format "  %-16S 展开成 %S\n" form (macroexpand form))))
```

```
== 4) backquote ==
  `(a b)           展开成 '(a b)
  `(a ,b)          展开成 (list 'a b)
  `(a ,b ,@c)      展开成 (cons 'a (cons b c))
  `(a ,b ,@c . d)  展开成 (cons 'a (cons b (append c 'd)))
  `(a ,(list 1 2)) 展开成 (list 'a (list 1 2))
```

**这就是全部秘密**：backquote 只是一个读作「生成 cons/list 代码」的 reader 宏。看展开结果就懂了：

- 没有 `,` 的部分**原样保留**（所以 `` `(a b) `` 直接变成一个 quote 过的常量）；
- `,form`（unquote）的位置换成**对 form 的求值结果**：`` `(a ,b) `` → `(list 'a b)`；
- `,@form`（splicing unquote）的位置换成「**把 form 的值（一个列表）摊开拼进去**」：`` `(a ,b ,@c) `` → `(cons 'a (cons b c))`——注意尾部直接是 `c`，因为 `cons` 的 cdr 天然就是「剩下的那串」；而 `` `(a ,b ,@c . d) `` 因为末尾还有个点对，只能用 `append`，于是 `(append c 'd)`。
- `,(list 1 2)` 里的 `list` 不是特殊的东西，它就是一个普通函数调用——`` ` `` 只负责「在哪里插入」，插进去的表达式照常求值。

实际求值的结果：

```
  --- 实际求值的结果 ---
  b=2, c=nil     -> `(a ,b ,@c) = (a 2)
  b=2, c=(1 2)   -> `(a ,b ,@c) = (a 2 1 2)
  ,@ 只展开一层：c=((1 2)) -> (a (1 2))
  --- 求值次数：, 里的式子每次都求 ---
  (((a 1) (a 2)) 2)
```

- `,@c` 在 `c` 为 `nil` 时**什么都不插入**（`(a 2)`），为 `(1 2)` 时把两个元素**摊平**进去（`(a 2 1 2)`）。这是它和 `,c`（会插入一个子列表）的唯一区别。
- **`,@` 只展开一层**：`c` 是 `((1 2))` 时结果是 `(a (1 2))`，不会变成 `(a 1 2)`。
- **`,` 里的式子每次出现都会求值一次**。最后那行演示了这一点：同一个模板求值两次，`n` 从 0 变成 2。这是 backquote 最经典的坑——**如果你在 `` ` `` 模板里对一个「有副作用的表达式」用了 `,`，它会被执行；如果模板被求值多次（比如这个宏被展开在循环里），副作用就发生多次**。宏里要小心，也正因为如此 [23 · 宏](23-macros.md) 才强调「参数在展开式里出现几次就求值几次」。

## 38.5 `eval`：把数据当代码跑

```elisp
(princ (format "  (eval '(+ 1 2))      = %S\n" (eval '(+ 1 2))))
(princ (format "  (eval (list '+ 1 2)) = %S  ; 现场拼出来的也行\n" (eval (list '+ 1 2))))
(princ (format "  (eval '(car '(1 2))) = %S\n" (eval '(car '(1 2)))))
```

```
== 5) eval ==
  (eval '(+ 1 2))      = 3
  (eval (list '+ 1 2)) = 3  ; 现场拼出来的也行
  (eval '(car '(1 2))) = 1
```

`eval` 接受**一个对象**（通常是一个 list），按求值规则跑一遍。因为 Lisp 代码就是数据，`(list '+ 1 2)` 拼出来的列表和 `'(+ 1 2)` 毫无区别。

关键限制在**作用域**。示例接着测：

```elisp
(let ((demo-lex 1))
  (princ (format "  let 里的词法变量 demo-lex 本身 = %S\n" demo-lex))
  (princ (format "  但 (eval 'demo-lex) -> %S\n"
                 (condition-case err (eval 'demo-lex)
                   (error (error-message-string err)))))
  (princ (format "  (eval 'demo-dyn)    -> %S   ; defvar 过的是动态变量，看得见\n"
                 (eval 'demo-dyn))))
```

```
  --- eval 看不见词法变量 ---
  let 里的词法变量 demo-lex 本身 = 1
  但 (eval 'demo-lex) -> "Symbol’s value as variable is void: demo-lex"
  (eval 'demo-dyn)    -> 7   ; defvar 过的是动态变量，看得见
```

**`eval` 只能看见动态变量，看不见词法变量**。原因很直接：词法变量在编译后只是栈槽或寄存器，「名字」早就不存在了；而动态变量的值按名字查一张全局表，`eval` 当然查得到。

`eval` 的第二个参数决定「用什么作用域规则去求值」：

```
  --- 第二个参数决定用哪种作用域 ---
  (eval '(let ((a 5)) (lambda () a)) nil) 再调用 -> "Symbol’s value as variable is void: a"
  (eval '(let ((a 5)) (lambda () a)) t)   再调用 -> 5
```

- `(eval form nil)`：用**动态绑定**求值。`(let ((a 5)) (lambda () a))` 里的 `a` 是动态变量，`let` 一结束就解绑，再调用那个 lambda 就报错。
- `(eval form t)`：用**词法绑定**求值。同一个表达式变成了一个**闭包**，`a` 被捕获，离开 `let` 之后再调用仍然得到 `5`。

这就是「有没有闭包」的分界线，也是为什么现代 Emacs Lisp 代码要在文件头写 `;;; -*- lexical-binding: t; -*-`（[03 · 变量与绑定](03-variables.md)）。

> 【坑】`eval` 里拼出来的代码**不受编译期检查**：拼错了要到运行时才炸，而且没有字节编译。能用宏解决的就别用 `eval`（宏在编译期展开，能被检查、能被编译）。

## 38.6 `funcall` / `apply`：把函数当值

[04 · 函数](04-functions.md) 讲过「函数是值」，这里是它的三个常用搬运工：

```elisp
(princ (format "  (funcall '+ 1 2)        = %S\n" (funcall '+ 1 2)))
(princ (format "  (funcall #'+ 1 2)       = %S\n" (funcall #'+ 1 2)))
(princ (format "  (apply '+ '(1 2))       = %S\n" (apply '+ '(1 2))))
(princ (format "  (apply '+ 1 2 '(3))     = %S   ; 最后一个参数必须是表\n"
               (apply '+ 1 2 '(3))))
(princ (format "  (apply '+ 1 2 3)        -> %S\n"
               (condition-case err (apply '+ 1 2 3)
                 (error (error-message-string err)))))
(princ (format "  (apply #'max '(1 5 3))  = %S\n" (apply #'max '(1 5 3))))
(princ (format "  (funcall (apply-partially '+ 1 2) 3) = %S\n"
               (funcall (apply-partially '+ 1 2) 3)))
(princ (format "  (func-arity #'car) = %S  (func-arity (lambda (a &optional b) (list a b))) = %S\n"
               (func-arity #'car)
               (func-arity (lambda (a &optional b) (list a b)))))
```

```
== 6) funcall 与 apply ==
  (funcall '+ 1 2)        = 3
  (funcall #'+ 1 2)       = 3
  (apply '+ '(1 2))       = 3
  (apply '+ 1 2 '(3))     = 6   ; 最后一个参数必须是表
  (apply '+ 1 2 3)        -> "Wrong type argument: listp, 3"
  (apply #'max '(1 5 3))  = 5
  (funcall (apply-partially '+ 1 2) 3) = 6
  (func-arity #'car) = (1 . 1)  (func-arity (lambda (a &optional b) (list a b))) = (1 . 2)
```

- **`funcall`**：参数已经摊在手上了，直接传。`(funcall '+ 1 2)` 和 `(funcall #'+ 1 2)` 一样——`funcall` 会自己去查符号的函数格。
- **`apply`**：**最后一个参数必须是一个列表**，它会被「摊开」接在前面那些参数后面。所以 `(apply '+ 1 2 '(3))` 等价于 `(+ 1 2 3)`。这个设计让它特别适合「参数个数不确定」的场景（比如 `(apply #'max list-of-numbers)`）。
- **`apply-partially`**：**预绑定前几个参数**，返回一个新函数（柯里化）。`(apply-partially '+ 1 2)` 得到一个「再加一个数」的函数。
- **`func-arity`**：问「这个函数要几个参数」，返回一个 cons `(最少 . 最多)`。`(1 . 2)` 表示「1 个必填、最多 2 个」；`(1 . 1)` 表示正好 1 个；**最多可以是 `many`**（带 `&rest` 的函数）。写通用包装器时用它来判断能不能安全调用。

## 38.7 宏展开发生在求值之前

```
== 7) 宏展开做一层还是做彻底 ==
  macroexpand      : (if t (progn (when t 1)))
  macroexpand-all  : (if t (progn (if t (progn 1))))
  展开后再求值      : 1
```

`when` 是个宏。它的展开结果里**还嵌着另一个宏调用**（内层的 `when`），于是：

- **`macroexpand` 只做最外层一层**，内层原样留着；
- **`macroexpand-all` 递归展开到底**，把所有宏都化掉。

想看一个宏「最终会变成什么」用 `macroexpand-all`；想调试「这一步展开了什么」用 `macroexpand`（[23 · 宏](23-macros.md) 讲过这个区别，这里是实测对照）。

时序上要记住：**宏展开在求值之前，而且通常在字节编译时就已经做完了**。所以宏里的 bug 往往是「编译期就错了」，而不是「运行时才错」。

## 38.8 谁会被求值

最后一个容易混淆的点：**不是每个位置都会被求值**。

```
== 8) 谁会被求值 ==
  (if t 1 (error "不该执行")) = 1   ; 特殊形式，else 分支不求值
  (+ 1 (error "x"))          -> "x"   ; 函数形式，每个参数都要求
  (and nil (error "x"))      = nil   ; and/or 也短路
  (list 1 (error "x"))       -> "x"   ; 换成 list 就照样报错
```

- **函数形式**（`+`、`list`、`car`…）：**每个参数都会被求值**，顺序是从左到右（手册不保证顺序，别依赖它）。所以 `(+ 1 (error "x"))` 一定会炸。
- **特殊形式**（`if`、`and`、`or`、`cond`、`quote`、`setq`、`defun`…）：**自己决定求哪些、求几次**。`if` 只求选中的那个分支；`and`/`or` 短路；`quote` 一个都不求。

这就是「为什么 `if` 不能写成函数」——**如果 `if` 是函数，两个分支都会被求值**，那就没法写递归的终止条件了。同理，`and`/`or`/`when`/`unless`/`cond` 全部只能是宏或特殊形式。

反过来也解释了宏的价值：**宏可以自己决定参数的求值时机**，这正是 `(incf (car x))`、`(push item list)` 这类「看起来像函数、其实改的是位置」的写法能成立的原因。

## 38.9 坑位清单

1. **列表求值 = 调用** —— `(1 2)` 会报 `Invalid function: 1`；向量 `[1 2]` 自求值，所以向量不用 quote。
2. **`quote` 出来的列表是常量** —— 别 `setcar` 它，字节编译器会警告 `‘setcar’ on constant list`；要可改的列表用 `list`。
3. **`#'` 和 `'` 对 lambda 不同** —— `#'` 让编译器编译它，`'` 不会。警告 `quoted with ' rather than with #'` **`with-no-warnings` 压不住**。
4. **backquote 只是「生成 cons/list 代码」的糖** —— 不信就 `macroexpand`：`` `(a ,b ,@c) `` → `(cons 'a (cons b c))`。
5. **`,@` 在值为 `nil` 时什么都不插入** —— 这是它和 `,` 的关键差别（`,` 会插入一个 `nil` 元素）。
6. **`,@` 只展开一层** —— `((1 2))` 摊开后是 `((1 2))` 里的一个元素，不是两个。
7. **`,` 里的式子每次出现都求值一次** —— 同一个模板被求值 N 次，副作用就发生 N 次。这是宏里最经典的坑。
8. **`eval` 看不见词法变量** —— 只认动态变量（用 `defvar` 声明过的）。
9. **`eval` 的第二个参数决定作用域** —— `nil` 动态（无闭包），`t` 词法（有闭包）。
10. **`apply` 的最后一个参数必须是列表** —— `(apply '+ 1 2 3)` 报 `listp` 错误；想传散的参数用 `funcall`。
11. **`macroexpand` 只展开一层** —— 要看到底用 `macroexpand-all`。
12. **特殊形式自己决定求哪些参数** —— 所以 `if`/`and`/`or` 能短路；也所以它们不能写成函数。
13. **别用 `eval` 拼代码代替宏** —— `eval` 拼出来的东西没有编译期检查，也不被字节编译。

下一章换一个「怎么存放一堆键值」的主题：**哈希表**。第 32 章用它做过词频统计，但只用了三个函数；本章会把测试函数、遍历、容量与「弱引用表」讲透，并给出「什么时候该用 alist、什么时候该用哈希表」的判据。

上一章：[37 · 符号：四个格子、属性表与 obarray](37-symbols.md)　｜　下一章：[39 · 哈希表：测试函数、遍历与弱引用](39-hash-tables.md)　｜　返回：[Emacs 扩展开发指南](README.md)
