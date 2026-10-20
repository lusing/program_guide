# 43 · 写宏的工具：cl-eval-when、cl-once-only 与 compiler macro

> 所属部分：第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

> 示例：`examples/43-macro-tools.el`

上一章把 `cl-defun`、`cl-defmacro` 的参数列表讲透了，但那些宏都只在「解释执行」时跑过一遍。真要写一个**能编译、不踩坑、还能优化**的宏，`cl-lib` 还备了一组专门「写宏用的宏」。它们对应 CL 手册第 3.2 节（`eval-when` 家族）、第 7 章（宏的辅助工具）、以及第 3.3 节与第 12 章（编译器声明与断言）。这一章把三样核心工具——`cl-eval-when`、`cl-once-only`、`cl-define-compiler-macro`——连同它们的配角全部实测一遍，每一条结论都来自 Emacs 31.1 的真实运行。

本章的示例有一个特殊之处：为了讲清「同一段代码在编译期、加载期、求值期分别发生了什么」，示例自带一个测量装置 `ch43-run3`，它把一段源码文本走三个时刻，每个时刻读一次全局状态。后面凡是涉及「时机」的小节，都靠它给出可复现的数字，而不是凭记忆断言。

## 43.0 测量装置：把「时机」变成可打印的数字

在讲 `cl-eval-when` 之前，先解决一个方法论问题。`cl-eval-when` 的意义是「控制一段代码在什么时候求值」，可「什么时候」是看不见的——你得把某个副作用（往一个全局列表里 push 一个数）当作探针，才能在三个不同时刻分别读出它的状态。`ch43-run3` 干的就是这件事。

示例第 1 节：

```elisp
(defun ch43-run3 (body read reset)
  (let* ((dir (make-temp-file "ch43-" t))
         (src (expand-file-name "probe.el" dir))
         (elc (concat src "c")))
    (unwind-protect
        (progn
          (with-temp-file src
            (insert ";;; -*- lexical-binding: t; -*-\n")
            (insert "(require 'cl-lib)\n")
            (insert body))
          (funcall reset)
          (let ((inhibit-message t)
                (byte-compile-warnings nil))
            (byte-compile-file src))
          (let ((a (funcall read)))
            (funcall reset)
            (load elc nil t)
            (let ((b (funcall read)))
              (funcall reset)
              (delete-file elc)
              (load src nil t)
              (list a b (funcall read)))))
      (delete-directory dir t))))
```

逐点读：

**三个时刻对应三个读数。** `ch43-run3` 接收三个参数：`body` 是一段源码文本（临时写成一个 `.el` 文件），`read` 是一个「读全局状态」的闭包，`reset` 是「把全局状态清零」的闭包。它依次做三件事——字节编译源文件、加载 `.elc`、加载 `.el`——每做完一件就 `funcall read` 读一次，返回 `(编译后 加载elc后 加载el后)` 三个读数。

**为什么需要 `require 'bytecomp`。** 示例文件开头有这一行：

```elisp
(require 'cl-lib)
(require 'bytecomp)
```

这不是多余的。`byte-compile-file` 是 autoload 的，第一次调用它才会真正加载 `bytecomp.el`；而 `ch43-run3` 里用 `(let ((byte-compile-warnings nil)) ...)` 想抑制编译警告。如果 `bytecomp` 还没加载，`byte-compile-warnings` 此刻还不是「动态变量」，`let` 就会把它绑成**词法**变量；等 `byte-compile-file` 触发加载、`bytecomp.el` 再对同一个符号执行 `defvar` 时，Emacs 31 会直接报错：

```
Defining as dynamic an already lexical var: byte-compile-warnings
```

先 `require 'bytecomp` 让这个变量在进入 `let` 之前就是动态的，`let` 才会建立动态绑定，错误随之消失。这是本章踩到的第一个真实坑，值得记住：**要 `let` 绑定某个库的特殊变量，先确保那个库已加载。**

**编译时抑制消息，但不改变语义。** `inhibit-message` 只是不让编译进度刷屏，`byte-compile-warnings` 设为 `nil` 只是关掉警告输出；两者都不影响「哪段代码在哪个时刻被执行」这一被测量的事实。

## 43.1 `cl-eval-when` 到底控制什么

CL 手册第 3.2 节把求值时机拆成三个独立阶段，`cl-eval-when` 的参数就是这三个名字的子集：

- `compile`——**字节编译这个文件时**求值；
- `load`——**编译产物被加载时**求值；
- `eval`——**解释执行（或在非顶层）时**求值。

手册还给了几个等价的关键词别名：`:compile-toplevel` 等于 `compile`、`:load-toplevel` 等于 `load`、`:execute` 等于 `eval`。`cl-lib` 的文档字符串原文是：

```
If `compile' is in WHEN, BODY is evaluated when compiled at top-level.
If `load' is in WHEN, BODY is evaluated when loaded after top-level compile.
If `eval' is in WHEN, BODY is evaluated when interpreted or at non-top-level.
```

注意三个限定词：`compile` 和 `load` 都强调 **top-level（顶层）**，`eval` 强调 **interpreted（解释）或非顶层**。这个「顶层」的约束是后面很多现象的根源。

先看解释执行时（当前这个 batch 会话里 `macroexp-compiling-p` 为 `nil`）`cl-eval-when` 展开成什么。示例第 2 节：

```elisp
(dolist (w '((compile) (load) (eval) (:execute) (compile load eval)))
  (princ (format "  (macroexpand-1 '(cl-eval-when %S (foo))) → %S\n"
                 w (macroexpand-1 `(cl-eval-when ,w (foo))))))
```

运行结果：

```
  (macroexpand-1 '(cl-eval-when (compile) (foo))) → nil
  (macroexpand-1 '(cl-eval-when (load) (foo))) → nil
  (macroexpand-1 '(cl-eval-when (eval) (foo))) → (progn (foo))
  (macroexpand-1 '(cl-eval-when (:execute) (foo))) → (progn (foo))
  (macroexpand-1 '(cl-eval-when (compile load eval) (foo))) → (progn (foo))
```

逐点读：

**解释执行只认 `eval`。** 因为不在编译、也不在顶层编译的语境里，`cl-eval-when` 走的是「非编译」分支：只有 `when` 列表里含 `eval` 或 `:execute` 时，才把 body 展开成 `(progn ...)`；否则整个形式展开成 `nil`。所以 `(compile)` 和 `(load)` 都变成 `nil`——它们在解释执行时本来就不该跑。

**`:execute` 与 `eval` 等价。** 第 4 行 `(cl-eval-when (:execute) (foo))` 和第 3 行 `(cl-eval-when (eval) (foo))` 展开结果一模一样，都是 `(progn (foo))`。

**含 `eval` 的组合都留下 body。** 最后一行 `(compile load eval)` 因为含 `eval`，同样展开成 `(progn (foo))`。在解释语境下，`compile`/`load` 的存在与否不影响结果，只有 `eval` 说了算。

## 43.2 七种组合的三阶段实测：时机到底怎么分

真正能体现 `cl-eval-when` 威力的，是「编译期 vs 加载期 vs 求值期」的分离。示例第 3 节用 `ch43-run3` 把七种 `cl-eval-when` 写法各配一个编号，一次跑完三个时刻。探针宏 `pp2-rec` 每被调用一次，就往全局列表 `pp2-log` 里 push 一个编号；三个时刻分别读 `pp2-log`，就能看到「哪个编号在哪个时刻被记录了」。

示例第 3 节的源码文本（`body`）：

```elisp
(eval-and-compile (defvar pp2-log nil))
(eval-and-compile (defmacro pp2-rec (n) `(push ,n pp2-log)))
(cl-eval-when (compile)         (pp2-rec 1))
(cl-eval-when (load)            (pp2-rec 2))
(cl-eval-when (eval)            (pp2-rec 3))
(cl-eval-when (compile load)    (pp2-rec 4))
(cl-eval-when (compile eval)    (pp2-rec 5))
(cl-eval-when (load eval)       (pp2-rec 6))
(cl-eval-when (compile load eval) (pp2-rec 7))
```

运行结果：

```
  编译阶段记录   = (1 4 5 7)
  载入 .elc 记录 = (2 4 6 7)
  载入 .el  记录 = (3 5 6 7)
```

逐点读：

**编译阶段 `(1 4 5 7)`：凡带 `compile` 的都当场求值。** 编号 1、4、5、7 的 `cl-eval-when` 列表里都有 `compile`，所以字节编译这个临时文件时，它们的 body 被 `eval` 执行，`pp2-rec` 被调用，编号进了日志。

**载入 `.elc` 是 `(2 4 6 7)`，注意没有 3。** 这是最反直觉的一行。编号 3 是 `(cl-eval-when (eval) ...)`，它**没有** `load`，编译期 `eval` 单独出现时会被展开成 `(progn nil)`——也就是根本不往字节码里写任何东西，加载 `.elc` 自然跑不到它。而编号 2 是 `(cl-eval-when (load) ...)`，编译期它被展开成 `(if nil nil (pp2-rec 2))` 这样的形式：编译时不跑（被 `if nil` 挡住），但这段代码留在了字节码里，加载时才真正执行。带 `compile load` 的 4、7 则两边都记——编译时跑一次，加载时又跑一次（因为 `reset` 在两个时刻之间清零，所以每个时刻各自看到自己那次）。

**载入 `.el` 是 `(3 5 6 7)`：凡带 `eval` 的都跑。** 不编译、直接解释加载源文件时，`macroexp-compiling-p` 为 `nil`，走的是 43.1 节讲的「非编译」分支：只有含 `eval`/`:execute` 的 body 展开成 `(progn ...)` 被执行。编号 3、5、6、7 都含 `eval`，所以是这四个；`compile`、`load` 的有无完全不影响。

**把三行合起来读，就得到 `cl-eval-when` 的完整语义表：**

| 组合 | 编译期 | 加载 `.elc` | 加载 `.el` |
|---|---|---|---|
| `(compile)` | 跑 | 不跑 | 不跑 |
| `(load)` | 不跑 | 跑 | 不跑 |
| `(eval)` | 不跑 | 不跑 | 跑 |
| `(compile load)` | 跑 | 跑 | 不跑 |
| `(compile eval)` | 跑 | 不跑 | 跑 |
| `(load eval)` | 不跑 | 跑 | 跑 |
| `(compile load eval)` | 跑 | 跑 | 跑 |

这张表就是手册 3.2 节的核心，也是写宏时决定「这个定义到底要活在哪几个阶段」的依据。

## 43.3 函数体内只有 `eval` 生效

43.1 节说过，`compile` 和 `load` 都带「顶层」限定。那把它们写进一个函数体里会怎样？示例第 4 节直接展开两个 lambda 看结果：

```elisp
(princ (format "  %S\n"
               (macroexpand-all
                '(lambda () (cl-eval-when (compile) (a)) (cl-eval-when (eval) (b))))))
(princ (format "  %S\n"
               (macroexpand-all
                '(lambda () (cl-eval-when (load) (c)) (cl-eval-when (:execute) (d))))))
```

运行结果：

```
  #'(lambda nil nil (progn (b)))
  #'(lambda nil nil (progn (d)))
```

逐点读：

**函数体里 `compile`、`load` 全被丢掉。** 第一个 lambda 里写了 `(cl-eval-when (compile) (a))` 和 `(cl-eval-when (eval) (b))`，展开后只剩 `(progn (b))`——`(a)` 整个消失了。第二个同理，`(c)` 消失，只留 `(progn (d))`。

**原因是 `cl--not-toplevel`。** `cl-eval-when` 的实现里有一个判断：只有在「编译且处于顶层」时才考虑 `compile`/`load`；一旦进入函数体（非顶层），就退回到「非编译」分支，只认 `eval`/`:execute`。所以函数体里写 `(cl-eval-when (compile) ...)` 等于没写。

**实践含义：** 别指望在函数体里用 `compile` 做「编译时计算」。要在编译时算一个值并嵌进函数体，用的是 `eval-when-compile`（下一节）或 `cl-load-time-value`（43.6 节），不是 `cl-eval-when`。

## 43.4 `eval-when-compile` 与 `eval-and-compile`

这两个是 Emacs Lisp 的原生宏，比 `cl-eval-when` 更早、更常用，手册 3.2 节也一并归到「When」里讲。示例第 5 节看它们的展开：

```elisp
(princ (format "  (macroexpand-1 '(eval-when-compile 3))          → %S\n"
               (macroexpand-1 '(eval-when-compile 3))))
(princ (format "  (macroexpand-all '(lambda () (eval-when-compile 3))) → %S\n"
               (macroexpand-all '(lambda () (eval-when-compile 3)))))
(princ (format "  (macroexpand-1 '(eval-and-compile 3))           → %S\n"
               (macroexpand-1 '(eval-and-compile 3))))
```

运行结果：

```
  (macroexpand-1 '(eval-when-compile 3))          → '3
  (macroexpand-all '(lambda () (eval-when-compile 3))) → #'(lambda nil '3)
  (macroexpand-1 '(eval-and-compile 3))           → '3
```

逐点读：

**`eval-when-compile` 的结果「对编译器呈现为常量」。** 它的文档原文是：编译时求值 body，结果作为 quoted 常量替换原位置；解释代码时等价于 `progn`。所以 `(eval-when-compile 3)` 展开成 `'3`——一个 quoted 的 3。放进 lambda 体里，`(lambda () (eval-when-compile 3))` 展开成 `#'(lambda nil '3)`，body 直接是常量 `'3`。这正是「编译期算好、结果内联进代码」的机制：`eval-when-compile` 常用来在编译期算表、算正则、算偏移量，避免运行期重复计算。

**`eval-and-compile` 等价于 `cl-eval-when (compile load eval)`。** 它展开也是 `'3`，但语义是「编译时和加载时都求值」。写宏时，宏定义本身必须用 `eval-and-compile` 包起来——因为编译这个文件时编译器要能展开这个宏（需要 compile），运行期调用这个宏时也要有它的定义（需要 eval）。这正是 43.2 节探针里 `(eval-and-compile (defmacro pp2-rec ...))` 的用法：不加 `eval-and-compile`，编译期 `cl-eval-when (compile)` 里调用 `pp2-rec` 就会报「函数定义 void」。

**为什么宏定义不能只用 `eval-when-compile`。** 若宏只在编译期存在，加载编译产物后宏定义就没了，运行期任何需要再次展开它的地方都会失败。所以 `defmacro` 的标准包装是 `eval-and-compile`，`cl-define-compiler-macro` 内部也正是这么做的（43.11 节）。

## 43.5 `compile` 与 `eval-and-compile` 的去向对照

43.2 节的表已经说明 `compile` 单独出现时不进入加载产物。示例第 6 节用一个更细的实验把这件事钉死：`pp5-var` 只在 `cl-eval-when (compile)` 里 `defvar`，`pp5-seen` 用 `eval-and-compile` 绑定，看两者在三个时刻分别是什么状态。

示例第 6 节的源码文本：

```elisp
(eval-and-compile (defvar pp5-seen nil))
(cl-eval-when (compile) (defvar pp5-var 42) (setq pp5-seen t))
```

`read` 用 `boundp` 判断变量是否存在（存在就取值，不存在记 `unbound`），`reset` 用 `makunbound` 把变量解绑。运行结果：

```
  三阶段读数 (pp5-var pp5-seen) = ((42 t) (unbound nil) (unbound nil))
```

逐点读：

**编译阶段 `(42 t)`：`cl-eval-when (compile)` 的 body 被显式 `eval`，`defvar` 与 `setq` 都跑了。** 注意这里 `defvar pp5-var 42` 确实把 `pp5-var` 设成了 42——因为 `cl-eval-when (compile)` 的实现是直接对 body 调用 `eval`，`defvar` 作为特殊形式被执行，而 `pp5-var` 此刻尚未绑定，`defvar` 就给它赋了初值。

**载入 `.elc`/`.el` 都是 `(unbound nil)`。** `pp5-var` 变成 `unbound`：它的 `defvar` 只写在纯 `compile` 的 body 里，而纯 `compile` 不向字节码输出任何代码（43.2 节编号 1 的现象），加载后这个变量根本不存在。`pp5-seen` 变回 `nil`：它的 `defvar` 在 `eval-and-compile` 里，会进入加载产物，每次加载都重新把它绑成 `nil`。

**这一节和 43.2 节互为印证。** `pp5-var` 与 `pp5-seen` 的不同去向，正是「compile-only」与「eval-and-compile」两种包装的分水岭。写宏时如果某个编译期辅助变量的值需要在加载后还在，就必须用 `eval-and-compile`，不能只放 `compile`。

## 43.6 `cl-load-time-value`：只在加载时算一次

手册 3.2 节还给了 `load-time-value`：它让一个 form **只在加载时求值一次**，结果对编译器呈现为一个 quoted 常量。`cl-lib` 的实现文档字符串是：

```
Like `progn', but evaluates the body at load time.
The result of the body appears to the compiler as a quoted constant.
```

用途场景：你有一个昂贵但只需算一次的表达式（比如构造一张查找表），不希望它每次被调用都重算，也不希望在编译期就固化进字节码（因为它依赖运行时环境）。`cl-load-time-value` 把它推迟到加载那一刻算一次，之后每次「用」它都直接引用那个已算好的常量。示例第 7 节：

```elisp
(eval-and-compile (defvar pp6-ctr 0))
(eval-and-compile (defvar pp6-val nil))
(defun pp6-bump () (setq pp6-ctr (1+ pp6-ctr)) (list 'stamp pp6-ctr))
(cl-load-time-value (setq pp6-val (list (pp6-bump))))
```

运行结果：

```
  三阶段读数 (pp6-ctr pp6-val) = ((0 nil) (1 ((stamp 1))) (1 ((stamp 1))))
```

逐点读：

**编译阶段 `(0 nil)`：编译时完全不算。** `cl-load-time-value` 在编译期不执行 body，只往字节码里写一条「加载时执行」的指令。所以编译刚结束时计数器 `pp6-ctr` 还是 0、`pp6-val` 还是 nil。

**载入 `.elc` 后 `(1 ((stamp 1)))`：整个 form 只求值一次。** 加载字节码时，那条延迟的 setq 被执行一次，`pp6-bump` 把 `pp6-ctr` 加到 1，结果 `((stamp 1))` 存进 `pp6-val`。

**载入 `.el` 也是 `(1 ((stamp 1)))`。** 解释加载时走 `cl-load-time-value` 的「非编译」分支：`` `',(eval form) ``，即当场求值一次并把结果当常量。同样只 bump 一次。

**它和 `eval-when-compile` 的区别：** `eval-when-compile` 在**编译期**算、把结果烧进字节码；`cl-load-time-value` 在**加载期**算、把结果作为运行时常量。前者适合「编译时就能确定」的值，后者适合「依赖加载环境、但加载后就固定」的值。

## 43.7 宏的经典陷阱：实参被求值两次

从这一节起进入「写宏的工具」本体。宏最常见、最隐蔽的 bug 是**实参重复求值**。示例第 8 节造一个反面教材：

```elisp
(defvar ch43-calls 0)
(defun ch43-next (n)
  "返回 N，顺便把 ch43-calls 加一，用来数求值次数。"
  (setq ch43-calls (1+ ch43-calls))
  n)
(defmacro ch43-square-bad (x)
  `(* ,x ,x))
```

展开与运行结果：

```
  (* (ch43-next 3) (ch43-next 3))
  结果 (值 求值次数) = (9 2)
```

逐点读：

**`x` 在模板里出现两次，实参就被代入两次。** `(ch43-square-bad (ch43-next 3))` 展开成 `(* (ch43-next 3) (ch43-next 3))`——`ch43-next` 被调用了两次。

**副作用因此发生两次。** `ch43-calls` 从 0 变成 2，所以结果是 `(9 2)`：值 9 是对的，但求值次数 2 暴露了 bug。平方本该只算一次。

**实参是常量时看不出问题，是表达式时才是灾难。** 如果传的是 `3`，展开成 `(* 3 3)`，没有副作用，一切正常；但传 `(pop lst)` 时，`pop` 会执行两次，列表被弹掉两个元素——这是宏用户绝不会预期的行为。这正是手册第 7 章花大力气讲 `once-only` 的原因。

## 43.8 `cl-once-only`：实参只求值一次

`cl-once-only` 是修 43.7 那个 bug 的标准工具。它的文档原文：

```
Generate code to evaluate each of NAMES just once in BODY.
... During macroexpansion, each NAME is bound to an uninterned
symbol. The expansion evaluates each FORM and binds it to the
corresponding uninterned symbol.
```

文档还直接给了一个和 `pop` 有关的例子，说明 `(my-cons (pop y))` 会被安全地展开成 `(let ((g1 (pop y))) (cons g1 g1))`。示例第 9 节把 `ch43-square-ok` 用 `cl-once-only` 重写：

```elisp
(defmacro ch43-square-ok (x)
  (cl-once-only (x)
    `(* ,x ,x)))
```

展开（gensym 归一化成 `G1` 便于阅读）与运行结果：

```
  (let ((G1 (ch43-next 3))) (* G1 G1))
  结果 (值 求值次数) = (9 1)
```

逐点读：

**实参被先绑到一个 gensym，模板里的 `x` 变成那个变量引用。** `cl-once-only` 在宏展开期把参数名 `x` 绑到一个 uninterned 符号（这里显示为 `G1`），生成的代码是 `(let ((G1 (ch43-next 3))) (* G1 G1))`：`(ch43-next 3)` 只求值一次并绑给 `G1`，`(* G1 G1)` 里两个 `G1` 都只是读变量。

**副作用只发生一次。** `ch43-calls` 变成 1，结果 `(9 1)`——值对、次数也对。

**`cl-once-only` 的名字写法。** 每个名字可以是 `NAME`（表示 `(NAME NAME)`，即「把实参求值一次、绑到同名 gensym」）或 `(NAME FORM)`（绑定 `FORM` 的求值结果）。它内部其实就是 `macroexp-let2`，文档末尾也提示了这一点。

## 43.9 `cl-with-gensyms`：卫生宏的另一半

`cl-once-only` 同时解决了「只求值一次」和「不撞名」。但有些宏不需要缓存实参，只需要一个**绝不会和调用方变量撞名的临时符号**，这时用 `cl-with-gensyms`。它的文档只有一句话：

```
Bind each of NAMES to an uninterned symbol and evaluate BODY.
```

示例第 10 节：

```elisp
(defmacro ch43-let-sq (value &rest body)
  "把 VALUE 绑到临时变量 TMP，再执行 BODY（TMP 用 gensym 防捕获）。"
  (cl-with-gensyms (tmp)
    `(let ((,tmp ,value))
       (* ,tmp ,tmp)
       ,@body)))
```

展开与运行结果：

```
  (let ((G1 (ch43-next 3))) (* G1 G1))
  (ch43-let-sq (ch43-next 3)) 结果 (值 次数) = (9 1)
```

逐点读：

**`cl-with-gensyms` 只负责「造符号」。** 它把 `tmp` 绑到一个 gensym，展开期模板里的 `,tmp` 就是这个 gensym。生成的 `let` 把 `value`（即 `(ch43-next 3)`）求值一次绑给它——「只求值一次」是**你自己**用 `let` 做到的，`cl-with-gensyms` 本身不缓存任何东西。

**与 `cl-once-only` 的分工。** `cl-once-only` = 造 gensym + 自动把实参放进 `let` 求值一次；`cl-with-gensyms` = 只造 gensym，`let` 结构你自己写。当宏的逻辑复杂、需要自定义绑定结构时，`cl-with-gensyms` 更灵活；单纯防重复求值时，`cl-once-only` 更省事。

**gensym 打印成裸名 `G1`。** `print-gensym` 默认是 `nil`，所以 uninterned 符号打印出来像普通符号（`g1`、`temp`、`--cl-rest--` 这类），但它没有 intern，永远不会和调用方的同名变量冲突。示例里为了对比清晰，用 `ch43-norm` 把随机 gensym 统一显示成 `G1`。

## 43.10 `cl-destructuring-bind`：宏展开期拆参数

写宏时经常从 `&rest` 里拿到一坨形式，想按「参数列表的形状」直接拆成具名变量，手册第 7 章给了 `destructuring-bind`。`cl-lib` 的 `cl-destructuring-bind` 就是它的运行期/展开期版本。示例第 11 节展开一个带 `&whole` 的解构：

```elisp
(macroexpand-all
 '(cl-destructuring-bind (&whole w a b) x
    (list w a b)))
```

展开结果：

```
  (let* ((--cl-rest-- x) (w --cl-rest--) (a (if (= (length --cl-rest--) 2) (car-safe (prog1 --cl-rest-- (setq --cl-rest-- (cdr --cl-rest--)))) (signal 'wrong-number-of-arguments (list '(&whole w a b) (length --cl-rest--))))) (b (car-safe --cl-rest--))) (list w a b))
```

两个长度错误的实测：

```
  少一个："Wrong number of arguments: (a b), 1"
  多一个："Wrong number of arguments: (&whole w a b), 3"
```

逐点读：

**展开用 `--cl-rest--` 接住整个列表。** `&whole w` 让 `w` 绑到整个列表 `--cl-rest--`，随后 `a`、`b` 从 `--cl-rest--` 逐个取出（用 `car-safe` + `prog1`/`cdr` 前移，等价于「弹出」）。`--cl-rest--` 是 `cl-lib` 内部用的稳定符号名，不是随机 gensym，所以打印出来是可读的。

**长度不对就报 `wrong-number-of-arguments`，且带上原始参数列表。** 少给一个时报 `(a b), 1`（参数模式 `(a b)`、实到 1 个），多给一个时报 `(&whole w a b), 3`。错误信息里的第一个元素就是原始解构模式，方便定位。

**它是 `cl-defmacro` 参数解构的「手动挡」。** `cl-defmacro` 在参数表里做的解构，展开后就是这一套 `let*` + `--cl-rest--`。当你在宏体里手工处理 `&rest` 收到的形式（比如把 `(op arg1 arg2)` 拆成三个变量）时，`cl-destructuring-bind` 是最直接的写法。

## 43.11 `cl-define-compiler-macro`：编译期改写函数调用

compiler macro 是 CL 手册第 3.12.7 节的概念：它长得像宏，但只在**编译调用点**时生效，用来把某个函数的调用「就地优化」成更快的等价代码，而不改变函数本身的语义。`cl-lib` 的文档原文：

```
Define a compiler-only macro.
This is like `defmacro', but macro expansion occurs only if the call to
FUNC is compiled (i.e., not interpreted). ... BODY can decide to "punt"
and leave the original function call alone by declaring an initial
`&whole foo' parameter and then returning foo.
```

示例第 12 节用 `ch43-run3` 测一个 compiler macro 在三个时刻的行为。源码文本：

```elisp
(defun ch43-trace (a b) (list 'runtime a b))
(cl-define-compiler-macro ch43-trace (a b) `(list 'compiled ,a ,b))
(defun pp7-call () (ch43-trace 2 5))
```

运行结果：

```
  三阶段读数 (pp7-call 结果 是否登记cmacro) = ((nil t) ((compiled 2 5) t) ((compiled 2 5) t))
  登记的符号属性：ch43-trace--cmacro
  (funcall (symbol-function 'ch43-trace) 2 5) = (runtime 2 5)
  (cl-compiler-macroexpand '(ch43-trace 2 5)) = (list 'compiled 2 5)
```

逐点读：

**三阶段读数里 `pp7-call` 都是 `(compiled 2 5)`。** 编译阶段第一个元素是 `nil`，因为此时 `pp7-call` 还没被定义（编译不执行 defun）；载入 `.elc` 和载入 `.el` 后 `pp7-call` 存在，两次都返回 `(compiled 2 5)`——compiler macro 生效了。

**在 31.1 里，连解释执行都会展开 compiler macro。** 文档说 compiler macro「只在编译调用时展开」，直觉上加载 `.el`（解释）时不该展开。但实测第三个阶段也是 `(compiled 2 5)`。原因是 Emacs 31 的 eager macroexpansion 加上「解释器会把 lambda 即时编译成字节码」：`(eval '(lambda () 1) t)` 在 31.1 返回的是字节码对象 `#[nil (1) (t)]`，于是 `pp7-call` 的 body 在加载时就被编译，调用点照样被 compiler macro 改写。这是 31.1 相对旧版的一个行为差异，值得注意。

**想拿到「原始调用」，直接 funcall 函数本体。** `(funcall (symbol-function 'ch43-trace) 2 5)` 返回 `(runtime 2 5)`——绕过所有编译期改写，走真正的函数体。compiler macro 只改写「`(ch43-trace ...)` 这种字面调用点」，不影响通过变量/`symbol-function` 拿到的函数对象。

**`cl-compiler-macroexpand` 手动展开。** 它像 `macroexpand` 但针对 compiler macro，返回 `(list 'compiled 2 5)`——即改写后的形式（还没求值，`compiled` 是被引用的符号）。

**命名与登记规律。** compiler macro 存成「函数名 `--cmacro`」的符号（这里是 `ch43-trace--cmacro`），挂在函数符号的 `compiler-macro` 属性上。`cl-define-compiler-macro` 的展开就是 `eval-and-compile` 包一个 `cl-defun` 定义 `--cmacro` 函数、再 `define-symbol-prop` 登记属性。第 42 章末尾看到的 `square--cmacro`（`cl-defsubst` 自动登记的那条），正是这套机制。

**`&whole` 用来「放弃改写」。** 如果某次调用不适合优化，compiler macro 可以声明 `&whole` 参数并把整个原始形式原样返回，等于「punt」，让编译器保持调用不变。

## 43.12 `cl-proclaim` 与 `cl-declaim`：对编译器下指令

compiler macro 改的是「单个调用点」，而 `proclaim`/`declaim` 改的是「一段编译策略」。手册第 3.3 节把声明分成运行期声明（`declare`）和编译期声明（`proclaim`/`declaim`）。`cl-lib` 提供 `cl-proclaim`（函数）和 `cl-declaim`（宏）。示例第 13 节看它们的展开与效果：

```elisp
(princ (format "  (macroexpand-1 '(cl-declaim (optimize (safety 0)))) → %S\n"
               (macroexpand-1 '(cl-declaim (optimize (safety 0)))))
(princ (format "  cl-proclaim 是函数：%S；cl-declaim 是宏：%S\n"
               (functionp 'cl-proclaim) (macrop 'cl-declaim)))
```

运行结果：

```
  (macroexpand-1 '(cl-declaim (optimize (safety 0)))) → (progn (cl-proclaim '(optimize (safety 0))))
  cl-proclaim 是函数：t；cl-declaim 是宏：t
```

逐点读：

**`cl-declaim` 只是把参数 quoted 后转给 `cl-proclaim`。** 展开结果 `(progn (cl-proclaim '(optimize (safety 0))))` 说明：`cl-declaim` 是宏，把它的实参原样加上引号交给 `cl-proclaim` 这个函数。所以两者的区别只是「要不要自己写引号」：`cl-declaim` 帮你省掉引号，`cl-proclaim` 要求你显式 quote 声明。

**直接裸写会报错。** 因为 `cl-proclaim` 是函数，参数会先求值；`(cl-proclaim (optimize (safety 0)))` 里 `(optimize ...)` 被当函数调用，而 `optimize` 根本不是函数：

```
  (cl-proclaim (optimize (safety 0))) → "Symbol’s function definition is void: optimize"
```

示例这里用 `(eval '(cl-proclaim ...))` 触发这个错误，是为了在字节编译示例本身时不让编译器把裸写的 `(optimize ...)` 当成「未知函数」报警告。正确写法要么是 `(cl-proclaim '(optimize ...))`（带引号），要么直接用宏 `cl-declaim`。

**`optimize` 声明实际改了哪些变量。** 在动态绑定里试 `(cl-declaim (optimize (speed 3) (safety 0)))`：

```
  (3 0 t t)
```

这四个值依次是 `cl--optimize-speed`、`cl--optimize-safety`、`byte-optimize`、`byte-compile-delete-errors`。`speed 3` 让 `byte-optimize` 变 `t`（开启优化），`safety 0` 让 `byte-compile-delete-errors` 变 `t`（允许删除错误检查），同时 `cl--optimize-speed`/`cl--optimize-safety` 记下数值 3 和 0，供后面 43.13、43.14 节验证。

## 43.13 `optimize (safety)` 如何关掉运行期检查

手册说 `safety` 声明控制「运行期检查的多少」：`safety 0` 允许编译器删掉那些「正常情况下不会触发」的检查，以换取速度。示例第 14 节用 `ch43-run3` 实测：`cl-defun` 对未知关键字的报错检查，正是被 `safety` 左右的一个典型。源码文本：

```elisp
(cl-declaim (optimize (safety 0)))
(cl-defun ch43-fast (&key a) a)
(cl-declaim (optimize (safety 3)))
(cl-defun ch43-safe (&key a) a)
```

三个函数都用 `:zz`（一个不在 `&key` 列表里的关键字）调用，看会不会报错：

```
  编译阶段   = (nil nil)
  载入 .elc  = ((returned nil) "Keyword argument :zz not one of (:a)")
  载入 .el   = ("Keyword argument :zz not one of (:a)" "Keyword argument :zz not one of (:a)")
```

逐点读：

**载入 `.elc` 那一行最能说明问题。** `ch43-fast`（`safety 0`）不检查未知关键字，直接返回 `nil`（显示为 `(returned nil)`）；`ch43-safe`（`safety 3`）则报 `"Keyword argument :zz not one of (:a)"`。同一个函数定义，唯一差别就是编译时的 `safety` 声明，行为却从「报错」变成「悄悄吞掉拼错的关键字」。

**载入 `.el` 两者都报错。** 解释执行时，`cl-defun` 的关键字检查代码总会被生成——它和 `macroexp-compiling-p` 绑定，不受 `safety` 影响。所以只有「编译产物」才会因 `safety 0` 丢掉检查。

**这就是 `safety 0` 的代价。** 省掉检查能提速，但拼错关键字这类错误也被一起省掉了，问题会悄悄潜伏。手册的建议是：只在确认是热路径、且关键字不会拼错的地方用 `safety 0`。

## 43.14 `inline`、`notinline`、`warn`、`special` 四种声明

`optimize` 之外，`proclaim`/`declaim` 还认好几种声明。示例第 15 节把它们各试一遍，读它们对编译器内部变量的影响：

```elisp
(let ((byte-compile-warnings t)
      (byte-compile-bound-variables nil))
  (cl-declaim (inline ch43-demo-fn))
  (princ (format "  inline    → byte-optimizer 属性 = %S\n"
                 (get 'ch43-demo-fn 'byte-optimizer)))
  (cl-declaim (notinline ch43-demo-fn))
  (princ (format "  notinline → 属性被清成 = %S\n"
                 (get 'ch43-demo-fn 'byte-optimizer)))
  (cl-declaim (warn (unused-variable 0)))
  (princ (format "  warn 0    → byte-compile-warnings = %S\n"
                 byte-compile-warnings))
  (cl-declaim (warn (unused-variable 1)))
  (princ (format "  warn 1    → 恢复为 %S\n" byte-compile-warnings))
  (cl-declaim (special ch43-sp))
  (princ (format "  special   → (memq 'ch43-sp byte-compile-bound-variables) = %S\n"
                 (memq 'ch43-sp byte-compile-bound-variables))))
```

运行结果：

```
  inline    → byte-optimizer 属性 = byte-compile-inline-expand
  notinline → 属性被清成 = nil
  warn 0    → byte-compile-warnings = (not unused-variable)
  warn 1    → 恢复为 (not)
  special   → (memq 'ch43-sp byte-compile-bound-variables) = (ch43-sp)
```

逐点读：

**`inline` 挂上 `byte-compile-inline-expand`。** `(cl-declaim (inline f))` 把函数符号 `f` 的 `byte-optimizer` 属性设成 `byte-compile-inline-expand`，字节编译器遇到 `f` 的调用时就地内联展开。第 42 章 `cl-defsubst` 的 `square` 也是靠这个属性实现内联。

**`notinline` 把它清成 `nil`。** 撤销内联，退回普通函数调用。

**`warn` 等级控制警告开关。** `(warn (unused-variable 0))` 把 `byte-compile-warnings` 从 `t` 改成 `(not unused-variable)`——即「除了 unused-variable 之外都警告」，也就是禁用了 unused-variable 这一类；等级 `1` 再启用回去，恢复成 `(not)`（接近默认的全开）。等级 0 表示关、1 及以上表示开。

**`special` 登记动态变量。** `(cl-declaim (special ch43-sp))` 把 `ch43-sp` 放进 `byte-compile-bound-variables`，告诉编译器它是动态绑定变量，别按词法变量优化掉它。

## 43.15 `cl-the` 与 `cl-assert`：受 speed/safety 控制的检查

手册第 12 章讲断言与类型声明，`cl-lib` 提供 `cl-the`（声明返回值类型）和 `cl-assert`（断言某表达式为真）。它们的共同点是：**检查代码是否生成，取决于 speed/safety**。`cl-the` 的文档：

```
Return FORM.  If type-checking is enabled, assert that it is of TYPE.
```

示例第 16 节看展开与触发错误：

```elisp
(princ (format "  cl-the 展开：%S\n"
               (macroexpand-all '(cl-the integer (+ 1 2)))))
(princ (format "  (cl-the integer \"abc\") → %S\n"
               (condition-case err
                   (cl-the integer "abc")
                 (error (error-message-string err)))))
(princ (format "  cl-assert 展开：%S\n"
               (macroexpand-all '(cl-assert (= 1 2)))))
(princ (format "  (cl-assert (= 1 2)) → %S\n"
               (condition-case err
                   (cl-assert (= 1 2))
                 (error (error-message-string err)))))
```

运行结果：

```
  cl-the 展开：(let* ((temp (+ 1 2))) (progn (if (integerp temp) nil (signal 'wrong-type-argument (list 'integer temp '(+ 1 2)))) temp))
  (cl-the integer "abc") → "Wrong type argument: integer, \"abc\", \"abc\""
  cl-assert 展开：(progn (or (= 1 2) (cl--assertion-failed '(= 1 2))) nil)
  (cl-assert (= 1 2)) → "Assertion failed: (= 1 2)"
```

逐点读：

**`cl-the` 展开成「先求值、再类型检查、返回该值」。** 把 `(+ 1 2)` 绑到 `temp`，用 `integerp` 检查，不对就 `signal` 一个 `wrong-type-argument`，对就返回 `temp`。所以 `cl-the` 既声明类型又保留值。

**类型不符时报 `wrong-type-argument`。** `(cl-the integer "abc")` 报 `"Wrong type argument: integer, \"abc\", \"abc\""`。

**`cl-assert` 展开成 `(or 表达式 (cl--assertion-failed ...))` 并返回 nil。** 断言失败时报 `"Assertion failed: (= 1 2)"`。它返回 `nil`（不像 `cl-the` 返回值）。

**两者都受 speed/safety 控制。** 实现里有一个判断：`(or (not (macroexp-compiling-p)) (< cl--optimize-speed 3) (= cl--optimize-safety 3))`——只有在「非编译、或 speed 不到 3、或 safety 等于 3」时才生成检查。也就是说 `speed 3` 且 `safety` 不为 3 时，整个检查消失，只留原表达式。这跟 43.13 节 `safety 0` 丢关键字检查是同一个机制的两面。

## 43.16 哪些 `cl-` 名字已经废弃

`cl-lib` 在 31.1 里把几个旧名字标了废弃。判断一个名字废没废，不用真去调用它（调用可能触发副作用），只需读它的 `byte-obsolete-info` 属性。示例第 17 节：

```elisp
(dolist (sym '(cl-gensym cl-locally cl-declare cl-with-accessors))
  (princ (format "  %-16s byte-obsolete-info = %S\n"
                 sym (get sym 'byte-obsolete-info))))
```

运行结果：

```
  cl-gensym        byte-obsolete-info = (gensym nil "31.1")
  cl-locally       byte-obsolete-info = (progn nil "31.1")
  cl-declare       byte-obsolete-info = (defvar nil "31.1")
  cl-with-accessors byte-obsolete-info = nil
```

逐点读：

**属性是 `(新名 是否函数 版本)` 三元组。** `cl-gensym` → `(gensym nil "31.1")` 表示「用 `gensym` 替代，31.1 起废弃」；`cl-locally` → `(progn nil "31.1")` 表示「用 `progn` 替代」；`cl-declare` → `(defvar nil "31.1")` 表示「用 `defvar` 替代」。

**`nil` 表示还没废弃。** `cl-with-accessors` 的 `byte-obsolete-info` 是 `nil`，说明它在 31.1 仍是可用、未废弃的名字。

**只读属性、不调用。** 这一节刻意不调用这些旧名，只查属性——因为调用废弃名本身可能产生副作用或报警告。查属性是判断「能不能用」的干净方法。

## 43.17 小结

| 工具 | 作用 | 关键实测结论 |
|---|---|---|
| `cl-eval-when` | 控制 body 在 compile/load/eval 哪些阶段求值 | `compile`/`load` 只在顶层生效；函数体内只认 `eval` |
| 三阶段语义 | 决定代码进编译期、字节码、还是解释执行 | 纯 `compile` 不进 `.elc`；纯 `load` 编译期展开成 `(if nil nil ...)` |
| `eval-when-compile` | 编译期求值，结果内联成常量 | 展开成 `'3`，用于编译期算表/算值 |
| `eval-and-compile` | 编译期 + 加载期都求值 | = `cl-eval-when (compile load eval)`，宏定义的标准包装 |
| `cl-load-time-value` | 只在加载时算一次，结果当常量 | 编译阶段不算；加载 `.elc`/`.el` 各算一次 |
| `cl-once-only` | 让宏实参只求值一次 | `(9 1)` 而非 `(9 2)`，消除重复求值 bug |
| `cl-with-gensyms` | 造不会撞名的临时符号 | 只造符号，「只求值一次」需自己用 `let` |
| `cl-destructuring-bind` | 展开期按参数列表形状解构 | 用 `--cl-rest--` 接列表，长度错报 `wrong-number-of-arguments` |
| `cl-define-compiler-macro` | 编译期改写函数调用 | 存成 `函数名--cmacro`；31.1 解释加载也展开 |
| `cl-proclaim`/`cl-declaim` | 对编译器下声明 | `declaim` 是宏、`proclaim` 是函数；裸写 `optimize` 会报错 |
| `optimize (speed/safety)` | 控制优化与运行期检查 | `safety 0` 的编译产物会丢掉 `&key` 未知关键字检查 |
| `inline`/`notinline`/`warn`/`special` | 其余四种声明 | 分别改 `byte-optimizer`、`byte-compile-warnings`、`byte-compile-bound-variables` |
| `cl-the`/`cl-assert` | 类型声明与断言 | 检查代码是否生成取决于 speed/safety |
| `byte-obsolete-info` | 判断 `cl-` 名字是否废弃 | `(新名 函数? 版本)`，`nil` 表示未废弃 |

这一章把「写宏的时机与卫生」讲完了。但宏真正强大的地方，是能把「看起来像变量」的东西当作可赋值的位置来操作——`setf`  generalized variable（广义变量）就是这套能力的核心。下一章进入手册第 5.1、5.2 节，讲 `setf`、`cl-letf` 与就地修改：为什么 `(setf (car x) 1)` 能改 `x` 的第一个元素，`cl-letf` 又怎么临时「假装」某个 place 是另一个值。

上一章：[42 · 参数列表：cl-defun、cl-defmacro 与 &key](42-argument-lists.md)　｜　下一章：[44 · 广义变量：setf、cl-letf 与就地修改](44-generalized-variables.md)　｜　返回：[Emacs 扩展开发指南](README.md)
