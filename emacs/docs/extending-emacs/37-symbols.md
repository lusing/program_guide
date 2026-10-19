# 37 · 符号：四个格子、属性表与 obarray

> 所属部分：第 10 部分 · 对照参考手册补齐的主题

> 示例：`examples/37-symbols.el`

前 36 章里，符号一直扮演「名字」：`defvar` 后面那个、`defun` 后面那个、`'quote` 后面那个。但它**不只是名字**。在 Emacs Lisp 里，符号是一个**有四个格子的对象**：

- **名字格**（print name）—— 一个字符串，`(symbol-name sym)` 取出来；
- **变量格**（value cell）—— `setq` 写进去的那个值；
- **函数格**（function cell）—— `defun` 装进去的那个函数；
- **属性表**（property list / plist）—— 一张「键 → 值」的小表，谁都能往上挂东西。

本章对应参考手册的 **Symbols** 一章，把这四个格子逐个打开。理解它的直接收益有三个：能读懂「给符号打标记」的老代码；能明白为什么 `set` 和 `setq` 不是一回事；能避开宏里那个经典的「变量名撞车」坑（[23 · 宏](23-macros.md) 讲 `gensym` 时留的伏笔，这里补上）。

## 37.1 四个格子

示例第 1 节造了一个符号，把四格都填上然后逐个读：

```elisp
(fset 'demo-four-cell (lambda () "我是函数格"))
(set 'demo-four-cell 42)
(princ (format "  (symbol-name 'demo-four-cell)     = %S\n"
               (symbol-name 'demo-four-cell)))
(princ (format "  (symbol-value 'demo-four-cell)    = %S\n"
               (symbol-value 'demo-four-cell)))
(princ (format "  (symbol-function 'demo-four-cell) = %S\n"
               (symbol-function 'demo-four-cell)))
(princ (format "  (symbol-plist 'demo-four-cell)    = %S\n"
               (symbol-plist 'demo-four-cell)))
(princ "  --- Lisp-2：同一个名字，两种取法 ---\n")
(princ (format "  直接写名字    -> %-14S ; 取变量格\n" demo-four-cell))
(princ (format "  写成 (名字)   -> %-14S ; 取函数格\n"
               (with-no-warnings (demo-four-cell))))
```

```
== 1) 符号的四个格子 ==
  (symbol-name 'demo-four-cell)     = "demo-four-cell"
  (symbol-value 'demo-four-cell)    = 42
  (symbol-function 'demo-four-cell) = #[nil ("我是函数格") (t)]
  (symbol-plist 'demo-four-cell)    = nil
  --- Lisp-2：同一个名字，两种取法 ---
  直接写名字    -> 42             ; 取变量格
  写成 (名字)   -> "我是函数格"   ; 取函数格
```

最后两行是本章的第一个重点：**同一个符号 `demo-four-cell`，变量格里是 `42`，函数格里是那个 lambda，互不干扰**。这就是 Lisp-2——「函数命名空间」和「变量命名空间」是分开的两套，所以你可以放心地给变量和函数起同一个名字（实践中别这么干，读起来太累）。

`#[nil ("我是函数格") (t)]` 是**函数对象**的打印形式：`#` 开头表示「这是个函数的打印表示」，方括号里依次是参数列表、函数体、以及交互声明。它不是列表，不能直接 `car`。判断它是不是函数用 `functionp`。

顺带说那个 `with-no-warnings`：函数是用 `fset` **运行时**装进函数格的，字节编译器在编译期看不到任何 `defun`，于是会警告「`demo-four-cell` is not known to be defined」。这是 `fset` / `fset`-类动态定义必然要付的代价：要么在调用处套 `with-no-warnings`，要么补一句 `(declare-function demo-four-cell nil)` 告诉编译器别管。

## 37.2 `set` 与 `setq`：差在一个求值

写法上只差三个字母，语义上差一次求值。示例第 2 节：

```elisp
(setq demo-a 1)
(set 'demo-b 2)
(princ (format "  (setq demo-a 1)   -> demo-a = %S\n" demo-a))
(princ (format "  (set 'demo-b 2)   -> demo-b = %S\n" demo-b))
(princ "  --- set 的第一个参数会被求值，所以能「运行时决定改哪个」---\n")
(let ((which (if (> 1 0) 'demo-a 'demo-b)))
  (set which 99)
  (princ (format "  (setq which 'demo-a) 然后 (set which 99)：demo-a=%S  demo-b=%S\n"
                 demo-a demo-b)))
(princ (format "  (setq (car '(a b)) 1) -> %S\n"
               (condition-case err (eval '(setq (car '(a b)) 1))
                 (error (error-message-string err)))))
```

```
== 2) set 与 setq ==
  (setq demo-a 1)   -> demo-a = 1
  (set 'demo-b 2)   -> demo-b = 2
  --- set 的第一个参数会被求值，所以能「运行时决定改哪个」---
  (setq which 'demo-a) 然后 (set which 99)：demo-a=99  demo-b=2
  (setq (car '(a b)) 1) -> "Wrong type argument: symbolp, (car '(a b))"
```

- **`set` 是一个普通函数**：两个参数都求值。所以要写成 `(set 'demo-b 2)`——`quote` 是为了让 `demo-b` 求值之后得到**符号本身**，而不是它的值。
- **`setq` 是一个特殊形式**：第一个参数**不求值**，直接当符号用。所以写 `(setq demo-a 1)` 不用引号。它本质就是 `(set (quote demo-a) 1)` 的缩写——名字里那个 `q` 就是 quote。
- 因为 `set` 的第一参数会被求值，**它可以「运行时决定改哪个变量」**。上面 `(set which 99)` 里 `which` 是 `let` 里的一个变量，值是符号 `demo-a`。这是 `setq` 做不到的（`setq` 的第一参数必须是写死的符号名）。
- 反过来，`setq` 的第一参数虽然不求值，但**结果必须是个符号**：`(setq (car '(a b)) 1)` 会报 `Wrong type argument: symbolp, (car '(a b))`。想「给列表的某一格赋值」得用 `setcar` / `setf`（[07 · 列表](07-lists.md)）。

## 37.3 变量格：有没有值、是哪儿的值

「这个变量现在有值吗」比看上去复杂，因为 Emacs 的变量有**局部绑定**和**默认值**两层。示例第 3 节：

```elisp
(princ (format "  (boundp 'no-such-var)          = %S\n" (boundp 'no-such-var)))
(princ (format "  (default-boundp 'no-such-var)  = %S\n" (default-boundp 'no-such-var)))
(princ (format "  defvar 后：(boundp 'demo-c)=%S  (default-value 'demo-c)=%S\n"
               (boundp 'demo-c) (default-value 'demo-c)))
(make-local-variable 'demo-c)
(setq demo-c 20)
(princ (format "  make-local + setq 后：当前值=%S 默认值=%S 是局部变量？=%S\n"
               demo-c (default-value 'demo-c) (local-variable-p 'demo-c)))
(makunbound 'demo-c)
(princ (format "  makunbound 后：(boundp 'demo-c)=%S  (default-boundp 'demo-c)=%S\n"
               (boundp 'demo-c) (default-boundp 'demo-c)))
```

```
== 3) 变量格 ==
  (boundp 'no-such-var)          = nil
  (default-boundp 'no-such-var)  = nil
  defvar 后：(boundp 'demo-c)=t  (default-value 'demo-c)=10
  make-local + setq 后：当前值=20 默认值=10 是局部变量？=t
  makunbound 后：(boundp 'demo-c)=nil  (default-boundp 'demo-c)=t
```

- `boundp` 问「**当前**有没有值」（会看 buffer 局部绑定）；`default-boundp` 问「**默认值**有没有」（不管局部）。
- `default-value` 无视当前的局部绑定，直接取默认值。
- 最后那一行是本节的精华：`makunbound` **只把当前的局部绑定清掉**，默认值毫发无损——所以清完之后 `boundp` 是 `nil` 而 `default-boundp` 还是 `t`。**`makunbound` 不是「彻底删掉这个变量」**，这是最容易误会的一点。

> 【坑】`boundp` 判断的是「有没有值」，不是「值是不是 nil」。一个被 `(setq x nil)` 赋成 nil 的变量，`boundp` 仍然返回 `t`。想区分「没设过」和「设成了 nil」，只能靠你自己约定（比如用 `defvar` 给一个非 nil 的哨兵值）。

## 37.4 函数格：四种东西共用一格

函数格里不只有「函数」。示例第 4 节：

```elisp
(princ (format "  (fboundp 'no-such-fn) = %S\n" (fboundp 'no-such-fn)))
(fset 'demo-fn (lambda (x) (* x 2)))
(princ (format "  fset 后：(fboundp 'demo-fn)=%S  (demo-fn 21)=%S\n"
               (fboundp 'demo-fn) (with-no-warnings (demo-fn 21))))
(princ (format "  (functionp 'demo-fn)=%S  (macrop 'demo-fn)=%S\n"
               (functionp 'demo-fn) (macrop 'demo-fn)))
(princ "  --- 宏、特殊形式、C 原语，函数格里的东西长得都不一样 ---\n")
(defmacro demo-macro (x) (list '* x x))
(princ (format "  宏 demo-macro：(macrop)=%S  (car (symbol-function))=%S  (consp …)=%S\n"
               (macrop 'demo-macro)
               (car (symbol-function 'demo-macro))
               (consp (symbol-function 'demo-macro))))
(princ (format "  特殊形式 if：(special-form-p 'if)=%S\n" (special-form-p 'if)))
(princ (format "  C 原语 car：(subrp (symbol-function 'car))=%S  (functionp 'car)=%S\n"
               (subrp (symbol-function 'car)) (functionp 'car)))
(princ "  --- autoload：函数格里先放一张「欠条」 ---\n")
(princ (format "  (autoloadp (symbol-function 'tetris)) = %S\n"
               (autoloadp (symbol-function 'tetris))))
(princ (format "  (nth 1 (symbol-function 'tetris))     = %S   ; 该去哪个文件里找\n"
               (nth 1 (symbol-function 'tetris))))
(princ (format "  (car (indirect-function 'tetris))     = %S\n"
               (car (indirect-function 'tetris))))
```

```
== 4) 函数格 ==
  (fboundp 'no-such-fn) = nil
  fset 后：(fboundp 'demo-fn)=t  (demo-fn 21)=42
  (functionp 'demo-fn)=t  (macrop 'demo-fn)=nil
  --- 宏、特殊形式、C 原语，函数格里的东西长得都不一样 ---
  宏 demo-macro：(macrop)=t  (car (symbol-function))=macro  (consp …)=t
  特殊形式 if：(special-form-p 'if)=t
  C 原语 car：(subrp (symbol-function 'car))=t  (functionp 'car)=t
  --- autoload：函数格里先放一张「欠条」 ---
  (autoloadp (symbol-function 'tetris)) = t
  (nth 1 (symbol-function 'tetris))     = "tetris"   ; 该去哪个文件里找
  (car (indirect-function 'tetris))     = autoload
```

函数格里能装四样东西，判断方式各不相同：

| 装的什么 | 怎么判断 | `symbol-function` 取出来长什么样 |
|---|---|---|
| 普通函数（Lisp 写的） | `functionp` | `#[...]` 或 `(closure ...)` |
| 宏 | `macrop` | 一个 cons，`(car ...)` 是符号 `macro` |
| 特殊形式（`if`、`setq`…） | `special-form-p` | 不能改，也不该看 |
| C 原语（`car`、`cons`…） | `(subrp (symbol-function …))` | `#<subr car>` |
| autoload（还没加载） | `autoloadp` | `(autoload "文件" ...)` |

**宏的表示值得记住**：它就是一个 **`(macro . 函数)`** 的 cons。所以 `(macrop x)` 的实现本质上就是「看函数格里那个东西是不是 `car` 为 `macro` 的 cons」。这也是为什么你不能把宏当函数传给 `funcall`——它根本不是函数对象，只是一个带标记的 cons。

**autoload 是 Emacs 启动快的关键**：`tetris` 这个游戏的代码并没有被加载，函数格里放的是一张「欠条」`(autoload "tetris" ...)`，等你第一次 `M-x tetris` 时 Emacs 才按欠条去加载文件。`indirect-function` 会一路「追」到底——沿着 autoload、advice、符号别名一直解引用，直到拿到真正的可调用对象（上面 `(car ...)` 还是 `autoload`，因为加载前没有更深处可追）。

最后：`fmakunbound` 是「清空函数格」，对应变量格的 `makunbound`。

## 37.5 属性表：一个符号自带的键值对

第四格是一张 **plist**（属性表）：键是符号，值随便。示例第 5 节：

```elisp
(put 'demo-fn 'demo-note "这是我挂上去的说明")
(put 'demo-fn 'demo-count 3)
(princ (format "  (get 'demo-fn 'demo-note)  = %S\n" (get 'demo-fn 'demo-note)))
(princ (format "  (get 'demo-fn 'demo-count) = %S\n" (get 'demo-fn 'demo-count)))
(princ (format "  (get 'demo-fn '没有的键)   = %S\n" (get 'demo-fn '没有的键)))
(princ (format "  (symbol-plist 'demo-fn)    = %S\n" (symbol-plist 'demo-fn)))
(princ (format "  (plist-get (symbol-plist 'demo-fn) 'demo-count) = %S\n"
               (plist-get (symbol-plist 'demo-fn) 'demo-count)))
(princ "  --- function-put / function-get：和 put / get 是同一个命名空间 ---\n")
(function-put 'demo-fn 'demo-kind '工具函数)
(princ (format "  (function-get 'demo-fn 'demo-kind) = %S\n"
               (function-get 'demo-fn 'demo-kind)))
(princ (format "  (get 'demo-fn 'demo-kind)          = %S   ; 同一个格子，能直接取到\n"
               (get 'demo-fn 'demo-kind)))
(princ (format "  (symbol-plist 'demo-fn) 现在 = %S\n" (symbol-plist 'demo-fn)))
(fmakunbound 'demo-fn)
(princ (format "  fmakunbound 只清函数格，属性表还在：%S\n"
               (symbol-plist 'demo-fn)))
```

```
== 5) 属性表（plist） ==
  (get 'demo-fn 'demo-note)  = "这是我挂上去的说明"
  (get 'demo-fn 'demo-count) = 3
  (get 'demo-fn '没有的键)   = nil
  (symbol-plist 'demo-fn)    = (demo-note "这是我挂上去的说明" demo-count 3)
  (plist-get (symbol-plist 'demo-fn) 'demo-count) = 3
  --- function-put / function-get：和 put / get 是同一个命名空间 ---
  (function-get 'demo-fn 'demo-kind) = 工具函数
  (get 'demo-fn 'demo-kind)          = 工具函数   ; 同一个格子，能直接取到
  (symbol-plist 'demo-fn) 现在 = (demo-note "这是我挂上去的说明" demo-count 3 demo-kind 工具函数)
  fmakunbound 只清函数格，属性表还在：(demo-note "这是我挂上去的说明" demo-count 3 demo-kind 工具函数)
```

- `put` / `get` 读写单个键；`symbol-plist` 取整张表（它就是一个**扁平的 `键 值 键 值 …` 列表**，和 [07 · 列表](07-lists.md) 讲的 plist 是同一种东西，所以可以用 `plist-get` 直接查）。
- **读不到的键返回 `nil`**，不报错——和 `gethash` 一样有「没这个键」和「值就是 nil」分不清的问题。
- **`fmakunbound` 只清函数格**，属性表不受影响。四个格子彼此独立。

> 【坑】`function-put` / `function-get` **不是**「函数的另一套属性」。翻 Emacs 31 的源码（`lisp/emacs-lisp/byte-run.el`）可以看到它就是一个转发：
>
> ```
> (defalias 'function-put
>   ;; We don't want people to just use `put' because we can't conveniently
>   ;; hook into `put' to remap old properties to new ones.  But for now, there's
>   ;; no such remapping, so we just call `put'.
>   #'(lambda (function prop value)
>       "Set FUNCTION's property PROP to VALUE.
> The namespace for PROP is shared with symbols.
> So far, FUNCTION can only be a symbol, not a lambda expression."
>       (put (bare-symbol function) prop value)))
> ```
>
> docstring 里那句 **`The namespace for PROP is shared with symbols`** 说得明明白白：它和 `put` 用的是同一张表（所以上面 `(get 'demo-fn 'demo-kind)` 也能取到 `function-put` 写进去的值）。之所以要包这一层，注释也写了——为了将来万一要「重映射旧属性名」时有个统一的入口可以改。**写新代码请用它**（别直接用 `put`），但心里要清楚它现在就是一回事。

属性表适合放**少量、零散的元数据**（Emacs 自己用它放 `risky-local-variable`、`side-effect-free`、`doc-string-elt` 这类给字节编译器和 `M-x describe` 看的标记）。**业务数据别往这里塞**：它是全局的、无序的、键会互相冲突。**数据量一多就用哈希表**（[第 39 章](39-hash-tables.md)）。

## 37.6 `intern`、`make-symbol` 与 obarray

「符号的唯一性」是这一节的主题。示例第 6 节：

```elisp
(princ (format "  (eq (intern \"foo\") (intern \"foo\"))           = %S\n"
               (eq (intern "foo") (intern "foo"))))
(princ (format "  (eq (make-symbol \"foo\") (make-symbol \"foo\")) = %S\n"
               (eq (make-symbol "foo") (make-symbol "foo"))))
(princ (format "  两者打印出来一模一样： %S / %S\n"
               (make-symbol "foo") (intern "foo")))
(princ (format "  (intern-soft \"no-such-symbol-xyz\") = %S\n"
               (intern-soft "no-such-symbol-xyz")))
(princ (format "  obarray 的 type-of=%S  obarrayp=%S\n"
               (type-of obarray) (obarrayp obarray)))
(princ "  --- 自建一张 obarray，看它怎么存符号 ---\n")
(let ((o (obarray-make)))
  (intern "aa" o)
  (intern "bb" o)
  (intern "cc" o)
  (let ((n 0) names)
    (mapatoms (lambda (s) (setq n (1+ n)) (push (symbol-name s) names)) o)
    (princ (format "  自建 obarray：%S 个符号，名字=%S\n" n (sort names #'string<)))))
(princ "  --- unintern 在 Emacs 31 里要两个参数 ---\n")
(let ((sym (intern "demo-tmp-symbol")))
  (princ (format "  intern 之后 (intern-soft \"demo-tmp-symbol\") = %S\n"
                 (intern-soft "demo-tmp-symbol")))
  (unintern sym obarray)
  (princ (format "  unintern 之后                              = %S\n"
                 (intern-soft "demo-tmp-symbol"))))
```

```
== 6) intern 与 obarray ==
  (eq (intern "foo") (intern "foo"))           = t
  (eq (make-symbol "foo") (make-symbol "foo")) = nil
  两者打印出来一模一样： foo / foo
  (intern-soft "no-such-symbol-xyz") = nil
  obarray 的 type-of=obarray  obarrayp=t
  --- 自建一张 obarray，看它怎么存符号 ---
  自建 obarray：3 个符号，名字=("aa" "bb" "cc")
  --- unintern 在 Emacs 31 里要两个参数 ---
  intern 之后 (intern-soft "demo-tmp-symbol") = demo-tmp-symbol
  unintern 之后                              = nil
```

**obarray（对象数组）是「符号的登记表」**。全 Emacs 默认用一张全局 obarray，变量就叫 `obarray`。每个符号被登记在上面，于是「同名的符号」永远只有一个：

- **`intern`「登记并取回」**：给它一个字符串，它在 obarray 里找同名符号——找到了就返回那个，没找到就新建一个登记进去。**所以 `(eq (intern "foo") (intern "foo"))` 是 `t`**：两次调用拿到的是同一个对象。
- **`make-symbol`「只造不登记」**：造一个全新的、谁也不知道的符号。名字可以一样，但**它不是同一个对象**——`(eq (make-symbol "foo") (make-symbol "foo"))` 是 `nil`。
- **两者打印出来都是 `foo`，看不出区别**。这是最大的坑，下一节讲怎么让它现形。
- **`intern-soft`「只查不建」**：找不到就返回 `nil`，不会污染 obarray。判断「某个名字的符号存不存在」用它。
- `unintern` 是反操作（从 obarray 里除名）。注意 **Emacs 31 里它必须给两个参数**（符号 + obarray）——只给一个会报 `wrong-number-of-arguments`。

顺带一个环境事实：**obarray 在 Emacs 30 之后不再是向量了**。`(type-of obarray)` 是 `obarray`，`obarrayp` 为 `t`，而 `(length obarray)` 会报 `wrong-type-argument sequencep`——老代码/老文章里「obarray 是个 vector，长度 1511」的说法已经不适用了。要一张自己的表就用 `(obarray-make)`，遍历用 `mapatoms`（它的第二个参数就是「遍历哪张表」）。

## 37.7 `gensym`：为什么宏里要用它

`make-symbol` 的典型用途就是**防止变量名撞车**。示例第 7 节：

```elisp
(princ (format "  (gensym)         = %S\n" (gensym)))
(princ (format "  (gensym \"x-\")    = %S\n" (gensym "x-")))
(princ (format "  print-gensym 默认 = %S\n" print-gensym))
(princ (format "  设成 t 再打印未 intern 的符号： %S\n"
               (let ((print-gensym t)) (prin1-to-string (make-symbol "tmp")))))
(princ (format "  默认情况下打印同一个符号：     %S   ; 看不出它没被 intern\n"
               (prin1-to-string (make-symbol "tmp"))))
;;; cl-lib 里那个老名字已经过时了，把字节编译器的提醒当场抓下来。
(let (warns)
  (let ((byte-compile-log-warning-function
         (lambda (string &optional _position _fill _level)
           (push string warns))))
    (byte-compile '(lambda () (cl-gensym "x-"))))
  (princ (format "  字节编译器对 cl-gensym 的提醒： %S\n" (car (nreverse warns)))))
```

```
== 7) 造一个全新的符号 ==
  (gensym)         = g0
  (gensym "x-")    = x-1
  print-gensym 默认 = nil
  设成 t 再打印未 intern 的符号： "#:tmp"
  默认情况下打印同一个符号：     "tmp"   ; 看不出它没被 intern
  字节编译器对 cl-gensym 的提醒： "‘cl-gensym’ is an obsolete function (as of 31.1); use ‘gensym’ instead."
```

- **`gensym` = `make-symbol` + 一个自增计数器**：`(gensym)` 给 `g0`，`(gensym "x-")` 给 `x-1`。它保证每次调用都是一个**全新的、没被 intern 的**符号。这正是 [23 · 宏](23-macros.md) 里写「临时变量」时要用的东西：宏展开出来的代码里如果出现 `temp`，而调用方的代码里也恰好有个 `temp`，就会互相覆盖；用 `gensym` 生成一个绝不可能撞车的名字，就没这个问题了。
- **`print-gensym` 默认是 `nil`**，所以未 intern 的符号打印出来**和 intern 的毫无区别**。想看清它，把这个变量设成 `t`，未 intern 的符号会打印成 `#:tmp`（那个 `#:` 前缀就是「这是个未 intern 的符号」）。**调试宏展开时这是必备开关**——不然你看着 `(setq tmp 1)` 怎么也想不通为什么没生效。
- **`cl-gensym` 在 Emacs 31.1 已经过时**。示例把字节编译器的提醒原文抓了下来：`‘cl-gensym’ is an obsolete function (as of 31.1); use ‘gensym’ instead.`。新代码直接用内置的 `gensym` 就行。

## 37.8 关键字符号：自求值

以冒号开头的符号叫**关键字符号**（keyword symbol），它们**求值得到自己**。示例第 8 节：

```elisp
(princ (format "  :foo 求值结果 = %S   (keywordp :foo) = %S\n" (eval :foo) (keywordp :foo)))
(princ (format "  (symbol-name :foo) = %S   (symbol-value ':foo) = %S\n"
               (symbol-name :foo) (symbol-value ':foo)))
(princ (format "  (eq :foo :foo) = %S   ; 同一张 obarray 里的同一个符号\n" (eq :foo :foo)))
```

```
== 8) 关键字符号 ==
  :foo 求值结果 = :foo   (keywordp :foo) = t
  (symbol-name :foo) = ":foo"   (symbol-value ':foo) = :foo
  (eq :foo :foo) = t   ; 同一张 obarray 里的同一个符号
```

为什么需要「求值得到自己」？因为这样**写参数时就不用 quote 了**：`(make-hash-table :test 'equal)` 里的 `:test` 如果是个普通符号，就得写成 `':test`。这也是为什么关键字符号成了「命名参数」的事实标准（[07 · 列表](07-lists.md) 的 plist、[18 · defcustom](18-custom.md) 的 `:type`、几乎每个 `cl-` 函数的可选参数，全靠它）。

注意 `(symbol-name :foo)` 是 `":foo"`——**冒号是名字的一部分**。而 `(symbol-value ':foo)` 返回 `:foo`，说明关键字的变量格里装的就是它自己。

## 37.9 `t` 与 `nil` 是常量

示例第 9 节的最后一块：

```elisp
(princ (format "  (symbol-value 'nil) = %S   (symbol-value 't) = %S\n"
               (symbol-value 'nil) (symbol-value 't)))
(princ (format "  (set 'nil 1) -> %S\n"
               (condition-case err (set 'nil 1) (error (error-message-string err)))))
(princ (format "  (set 't 1)   -> %S\n"
               (condition-case err (set 't 1) (error (error-message-string err)))))
```

```
== 9) t 与 nil 不能被赋值 ==
  (symbol-value 'nil) = nil   (symbol-value 't) = t
  (set 'nil 1) -> "Attempt to set a constant symbol: nil"
  (set 't 1)   -> "Attempt to set a constant symbol: t"
```

`nil` 和 `t` 是**常量符号**：它们的变量格里装的就是自己，且不允许被改。想改会报 `Attempt to set a constant symbol`。这也是 [02 · 类型与值](02-types.md) 说的「`nil` 一个值身兼四职」（空表、假、符号、`()`）的另一面——它是被硬编码进解释器的，不是普通变量。

## 37.10 坑位清单

1. **同一个名字，变量格和函数格是两回事** —— Lisp-2。`(setq foo 1)` 和 `(defun foo ...)` 互不覆盖，但别这么写，读代码的人会疯。
2. **`set` 求值第一参数，`setq` 不求值** —— 所以 `(set 'x 1)` 要引号、`(setq x 1)` 不要。想「运行时决定改哪个变量」只能用 `set`。
3. **`setq` 的第一参数必须是符号** —— `(setq (car '(a b)) 1)` 报 `symbolp` 错误；要改列表元素用 `setcar`/`setf`。
4. **`makunbound` 只清当前的局部绑定** —— 默认值还在（`default-boundp` 仍为 `t`）。它不是「删掉变量」。
5. **`boundp` 是「有没有值」不是「值是不是 nil」** —— 赋成 `nil` 之后 `boundp` 依然为真。
6. **宏的函数格是 `(macro . 函数)` 这种 cons** —— 不能 `funcall` 一个宏；判断用 `macrop`。
7. **`function-put` / `function-get` 和 `put` / `get` 共用同一个属性表** —— docstring 明写 `The namespace for PROP is shared with symbols`。写新代码请用它，但别以为它是另一套存储。
8. **属性表是全局且无序的** —— 适合放少量元数据，不适合放业务数据；数据量一多就换哈希表。
9. **`make-symbol` 造的符号打印出来和 `intern` 的毫无区别** —— 想看清就把 `print-gensym` 设成 `t`，未 intern 的会显示成 `#:名字`。
10. **`print-gensym` 默认是 `nil`** —— 调试宏展开前先把它打开，否则你看不出哪个变量是「临时造的」。
11. **`cl-gensym` 在 31.1 已过时** —— 用内置 `gensym`；字节编译器会主动提醒。
12. **obarray 在 Emacs 30+ 不再是向量** —— `(length obarray)` 会报 `sequencep` 错误；判断用 `obarrayp`，新建用 `obarray-make`。
13. **`unintern` 在 Emacs 31 里要两个参数** —— `(unintern sym obarray)`，只给一个会报参数个数错。
14. **关键字符号求值得到自己** —— 所以写 `:test` 不用 quote；`(symbol-name :foo)` 含冒号，是 `":foo"`。
15. **`t` 和 `nil` 不能被赋值** —— 报 `Attempt to set a constant symbol`。

下一章回到「代码是怎么跑起来的」这个根本问题：**求值**。我们会把 `quote` / backquote / `eval` / `funcall` 这一族摆在一起，看清「什么时候求、求几次」——这是写宏和写 `cl-loop` 那类 DSL 的地基。

上一章：[36 · 数字：整除、取整、bignum 与位运算](36-numbers.md)　｜　下一章：[38 · 求值：quote、backquote 与 eval](38-evaluation.md)　｜　返回：[Emacs 扩展开发指南](README.md)
