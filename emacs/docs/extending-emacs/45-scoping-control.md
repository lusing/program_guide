# 45 · 作用域与控制流：cl-flet、cl-block 与多值

> 所属部分：第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

> 示例：`examples/45-scoping-control.el`

第 44 章解决了「值能存进哪里」；这一章解决另一半问题：「一个名字在什么范围内指向什么」。CL 手册第 5 章剩下的部分——5.3 Variable Bindings、5.4 Conditionals、5.5 Blocks and Exits、5.6 Iteration、5.8 Multiple Values——在 Emacs 里对应一整族 `cl-` 宏：局部函数绑定 `cl-flet`/`cl-labels`、局部宏绑定 `cl-macrolet`/`cl-symbol-macrolet`、运行时动态绑定 `cl-progv`、符号与类型分派 `cl-case`/`cl-ecase`/`cl-typecase`/`cl-etypecase`、具名非局部退出 `cl-block`/`cl-return-from`/`cl-return`、词法 goto `cl-tagbody`、通用迭代 `cl-do`/`cl-do*`/`cl-dolist`/`cl-dotimes`，以及「多值」的列表模拟 `cl-values` 家族。

本章有三个**只有实测才能发现**的 31.1 事实，先亮出来：手册示例里的裸 `return` 在 `emacs -Q` 里根本不存在（`(fboundp 'return)` 为 `nil`，正路是 `cl-return`）；旧版 Emacs 曾有过的原生 `values`/`multiple-value-bind` 家族在 31.1 已整体移除（`(fboundp 'values)` 为 `nil`），多值只剩 `cl-lib` 的列表模拟；`cl-block` 底层确实是 `catch`，但标签被藏进一个词法变量 `--cl-block-名--`，出了块体就 void——这就是手册所说「块是词法作用域」的实现机制。每条都附真实输出。

## 45.1 `cl-flet` 与 `cl-labels`：局部函数绑定

手册 5.3.2 给了两个「给函数名做 let 绑定」的宏：`cl-flet`（词法、非递归）与 `cl-labels`（词法、可递归）。示例第 1 节把它们的四条边界全部测穿：

示例第 1 节：

```elisp
(defun ch45-outer () "global")
(defun ch45-call-outer () (ch45-outer))
(princ (format "  (cl-flet ((ch45-outer () \"local\")) (ch45-outer)) → %S\n"
               (cl-flet ((ch45-outer () "local")) (ch45-outer))))
(princ (format "  #' 引用也走局部绑定：%S\n"
               (cl-flet ((ch45-outer () "local")) (funcall #'ch45-outer))))
(princ (format "  出了 flet 体 → %S\n" (ch45-outer)))
(princ (format "  被调函数体内看不到 cl-flet 绑定 → %S\n"
               (cl-flet ((ch45-outer () "local")) (ch45-call-outer))))
(defun ch45-self () "global-self")
(princ (format "  cl-flet 体内自调用走的是全局（非递归）：%S\n"
               (cl-flet ((ch45-self () (list 'local (ch45-self))))
                 (ch45-self))))
(princ (format "  cl-labels 递归阶乘 5! = %S\n"
               (cl-labels ((fact (n) (if (< n 2) 1 (* n (fact (1- n))))))
                 (fact 5))))
(princ (format "  cl-labels 互相递归 ev(6) = %S\n"
               (cl-labels ((ev (n) (if (= n 0) t (od (1- n))))
                           (od (n) (if (= n 0) nil (ev (1- n)))))
                 (ev 6))))
```

运行结果：

```
  (cl-flet ((ch45-outer () "local")) (ch45-outer)) → "local"
  #' 引用也走局部绑定："local"
  出了 flet 体 → "global"
  被调函数体内看不到 cl-flet 绑定 → "global"
  cl-flet 体内自调用走的是全局（非递归）：(local "global-self")
  cl-labels 递归阶乘 5! = 120
  cl-labels 互相递归 ev(6) = t
```

逐点读：

**绑定形式二选一：`(name expr)` 或 `(name arglist body…)`。** 本节用的是后一种——`(ch45-outer () "local")` 读作「在体内，把函数名 `ch45-outer` 换成一个无参、返回 `"local"` 的定义」。前一种形式则是把名字绑到某个表达式返回的函数值上。手册 5.3.2 明确：`cl-flet` 里定义的函数可以用 `cl-defun` 的全套参数语法，函数体也自带隐式块。

**「引用」的两种形态都走局部绑定。** 手册特意定义了什么算 reference：直接调用 `(ch45-outer)` 是一种，`(funcall #'ch45-outer)` 这种被 `function` 引用的也是一种——实测两行都返回 `"local"`。所以 `(mapcar #'ch45-outer lst)` 在 `cl-flet` 体内同样吃到局部定义。

**词法作用域：被调函数的体内看不到绑定。** 第四行是关键实验：`ch45-call-outer` 是个全局函数，它的体里写着 `(ch45-outer)`；即便调用发生在 `cl-flet` 体内，结果仍是 `"global"`。手册原话：所有对函数名的引用必须**物理地**出现在 `cl-flet` 的体内（可能在宏展开之后）。这和 44.9 节 `cl-letf` 临时换函数定义形成鲜明对照——`cl-letf` 改的是全局符号的 function 槽，被调函数也能看到；`cl-flet` 只影响体内直接写出的调用点。

**`cl-flet` 非递归的铁证：`(local "global-self")`。** 第五行在 `cl-flet` 里重新定义 `ch45-self`，而新定义体内又调用 `(ch45-self)`。如果绑定是递归的，这会无限循环；实测返回 `(local "global-self")`——体内的自引用指向的是**全局**定义，一次就返回。这正是 `flet` 与 `labels` 的经典分界：`flet` 的绑定不在「自己定义体」的作用域内。

**`cl-labels` 补上递归与互相递归。** 第六行局部阶乘 `5! = 120`，体内自调用指向局部定义；第七行 `ev`/`od` 互相调用算偶数判定，`ev(6) = t`。手册 5.3.2 还提醒：`cl-labels` 的词法闭包捕获要求 `lexical-binding` 为 `t`——我们的示例文件首行就是 `;;; -*- lexical-binding: t; -*-`，这也是全教程的统一要求。

**别和废弃的 `cl.el` 混淆。** 手册 5.3.2 末尾专门注记：旧版 `cl.el` 里的 `flet`/`labels` 是**动态**绑定，行为不同；`cl-lib` 的 `cl-flet`/`cl-labels` 才是词法的。看到老代码里动态生效的 `flet`，多半就是踩了这个坑。

## 45.2 `cl-macrolet` 与 `cl-symbol-macrolet`：局部宏绑定

手册 5.3.3 把「let 版的 defmacro」和「看起来像变量的宏」也归进变量绑定。示例第 2 节：

示例第 2 节：

```elisp
(princ (format "  cl-macrolet 局部宏：(double 21) → %S\n"
               (cl-macrolet ((double (x) `(+ ,x ,x))) (double 21))))
(setq ch45-bar '(5 . 9))
(cl-symbol-macrolet ((foo (car ch45-bar)))
  (cl-incf foo))
(princ (format "  symbol-macrolet + cl-incf：ch45-bar → %S\n" ch45-bar))
(setq ch45-bar '(5 . 9))
(cl-symbol-macrolet ((foo (car ch45-bar)))
  (setq foo 4))
(princ (format "  对符号宏 setq 等同 setf：ch45-bar → %S\n" ch45-bar))
```

运行结果：

```
  cl-macrolet 局部宏：(double 21) → 42
  symbol-macrolet + cl-incf：ch45-bar → (6 . 9)
  对符号宏 setq 等同 setf：ch45-bar → (4 . 9)
```

逐点读：

**`cl-macrolet`：绑定项就是 `cl-defmacro` 的参数。** `(double (x) `(+ ,x ,x))` 定义了一个只在体内可用的局部宏，`(double 21)` 展开成 `(+ 21 21)` 得 42。手册强调：宏天然是编译期行为，所以 `cl-macrolet` 永远是词法的；体内**其他宏展开之后**出现的调用也会被它捕获；而 `cl-macrolet` 绑定宏的展开式本身在全局环境里展开。

**符号宏：变量引用被整体替换成任意形式。** 第二个实验就是手册 5.3.3 的原例：`ch45-bar` 是 `(5 . 9)`，`cl-symbol-macrolet` 把 `foo` 声明为 `(car ch45-bar)` 的别名，体内 `(cl-incf foo)` 实际展开成 `(cl-incf (car ch45-bar))`——改的是 cons cell 本身，所以出来打印 `ch45-bar` 得到 `(6 . 9)`。`foo` 看起来是个普通变量，写起来像变量，其实是访问路径。

**对符号宏 `setq` 等同 `setf`。** 第三个实验验证手册那句「A setq of a symbol macro is treated the same as a setf」：体内 `(setq foo 4)` 实际执行了 `(setf (car ch45-bar) 4)`，得到 `(4 . 9)`。

**符号宏的两条使用纪律（手册原文）。** 其一，体内若用 `let` 重新绑定同名符号，局部变量会**遮蔽**符号宏（与 Common Lisp 一致）；其二，符号宏没有全局版（没有 `defsymbolmacro`），只能出现在宏展开式里——手册给的典型用法就是宏作者用 `cl-symbol-macrolet` 把循环变量变成「对列表元素的真引用」，让 `(my-dolist (x list) (incf x))` 能就地改列表。

## 45.3 `cl-progv`：运行时算出变量名的动态绑定

`let` 绑定的名字编译期就写死了。手册 5.3.1 给了一个按运行时数据绑定的宏 `cl-progv`：

示例第 3 节：

```elisp
(let ((names (list 'ch45-v1 'ch45-v2))
      (vals '(10)))
  (cl-progv names vals
    (princ (format "  体内 ch45-v1=%S ch45-v2=%S（值不够补 nil）\n"
                   ch45-v1 ch45-v2)))
  (princ (format "  体外 ch45-v1=%S ch45-v2=%S\n" ch45-v1 ch45-v2)))
```

运行结果：

```
  体内 ch45-v1=10 ch45-v2=nil（值不够补 nil）
  体外 ch45-v1=outside ch45-v2=outside
```

逐点读：

**两个列表进，一组动态绑定出。** `names` 求值得到符号列表 `(ch45-v1 ch45-v2)`，`vals` 求值得到值列表 `(10)`；`cl-progv` 把前者绑到后者上。手册规定：值不够时，多出来的符号绑 `nil`（实测 `ch45-v2` 体内为 `nil`）；值多了则丢弃多余的。

**这是动态作用域专属工具。** 体内对 `ch45-v1` 的引用之所以能看到 `10`，是因为 `ch45-v1` 是 `defvar` 过的特殊变量（动态引用）。词法绑定做不到「名字运行时才算出来」——这正是 `cl-progv` 存在的理由：给「按配置/按用户输入决定绑哪个变量」的场景用，日常代码很少需要。

**出了体自动还原。** 体外打印两个变量都回到 `outside`，和 `let` 一样有借有还。

## 45.4 `cl-case`：符号/常量分派

`cond` 逐个求值条件；手册 5.4 的 `cl-case` 则是「求值一次 key，按 `eql` 匹配分支」。示例第 4 节把手册的按键示例和几条边界规则全测了：

示例第 4 节：

```elisp
(dolist (k (list ?a ?b ?\r 'x))
  (princ (format "  key=%S → %S\n" k
                 (cl-case k
                   (?a "do-a")
                   (?b "do-b")
                   ((?\r ?\n) "do-ret")
                   (t "do-other")))))
(princ (format "  otherwise 与 t 等价：%S\n"
               (cl-case 'z (a "A") (otherwise "OTH"))))
(princ (format "  想匹配字面符号 t 就得包列表：%S\n"
               (cl-case 't ((t) "literal-t") (t "fallback"))))
```

运行结果：

```
  key=97 → "do-a"
  key=98 → "do-b"
  key=13 → "do-ret"
  key=x → "do-other"
  otherwise 与 t 等价："OTH"
  想匹配字面符号 t 就得包列表："literal-t"
```

逐点读：

**分支形式是 `(keylist body…)`，比较用 `eql`。** 手册的例子正是「读一个按键，按 a/b/回车/其他分派」。实测第一组：`?a` 是整数 97、`?b` 是 98、`?\r` 是 13，`(?\r ?\n)` 这种多键写成列表。注意 key 是符号 `'x` 时，`?a` 这类整数键都不匹配，落到 `t` 分支。

**单键可以裸写，但三个例外必须包列表。** 手册规定：恰好一个值、且它不是 cons cell、不是 `nil`、不是 `t` 时，才能裸写。后两个实验验证了边界：`(a "A")` 里 `a` 裸写合法；而想匹配**字面符号 `t`** 本身，必须写 `((t) …)`——第三实验的 key 就是符号 `t`，`((t) "literal-t")` 先匹配，得到 `"literal-t"` 而不是 `"fallback"`。同理想匹配 `nil` 也要包成 `(nil)`。

**默认分支：`t` 或 `otherwise`。** 手册说最后几个分支可以用 `t` 当 keylist 表示默认，`otherwise` 是它的别名——第二组实验用 `(otherwise "OTH")` 得到 `"OTH"`，验证等价。

**无匹配返回 `nil`，且所有键值必须互不相同。** 这两条是手册 5.4 的原文约束：`cl-case` 不像 `cond` 那样有「全部条件为假」的语义负担，它直接返回 nil；重复键则属于错误写法。想要「不匹配就报错」，用下一节的 `cl-ecase`。

## 45.5 `cl-ecase`：不匹配即报错

示例第 5 节：

```elisp
(princ (format "  (cl-ecase 'b (a 1) (b 2)) → %S\n" (cl-ecase 'b (a 1) (b 2))))
(princ (format "  无匹配 → %S\n"
               (condition-case err
                   (cl-ecase 'c (a 1) (b 2))
                 (error (error-message-string err)))))
```

运行结果：

```
  (cl-ecase 'b (a 1) (b 2)) → 2
  无匹配 → "cl-ecase failed: c, (a b)"
```

逐点读：

**`cl-ecase` = `cl-case` + 必须穷尽。** 手册 5.4 一句话讲完区别：key 不匹配任何分支时，`cl-ecase` 发出错误而不是返回 `nil`。实测错误消息是 `cl-ecase failed: c, (a b)`——把 key 和全部合法键一起报出来，定位「漏了哪个分支」非常方便。

**什么时候用哪个。** 状态值可枚举、漏分支就是 bug 时用 `cl-ecase`（比如模式变量只可能是 `:idle`/`:busy`）；key 是任意输入、需要兜底时用 `cl-case` + `t`。

## 45.6 `cl-typecase` 与 `cl-etypecase`：按类型分派

`cl-case` 按键的**值**分派，手册 5.4 的 `cl-typecase` 按键的**类型**分派。示例第 6 节：

示例第 6 节：

```elisp
(dolist (v (list 1 1.0 "42" '(1)))
  (princ (format "  %S → %S\n" v
                 (cl-typecase v
                   (integer "int")
                   (float "float")
                   (string (number-to-string (1+ (string-to-number v))))
                   ((or symbol cons) "sym-or-cons")
                   (t "anything")))))
(princ (format "  cl-etypecase 无匹配 → %S\n"
               (condition-case err
                   (cl-etypecase :kw (integer "int"))
                 (error (error-message-string err)))))
```

运行结果：

```
  1 → "int"
  1.0 → "float"
  "42" → "43"
  (1) → "sym-or-cons"
  cl-etypecase 无匹配 → "cl-etypecase failed: :kw, (integer)"
```

逐点读：

**分支形式是 `(type body…)`，判断走 `cl-typep`。** 手册 5.4 的例子（`integer`/`float`/`string`/`t`）原样实测：整数 1 走 `int`，浮点 1.0 走 `float`，字符串 `"42"` 走 `string` 分支（体内把它转数加一再转回，得 `"43"`），列表 `'(1)` 是 cons 走合并分支。类型说明符的完整语义在第 48 章讲，这里只需知道：分支里写的就是类型名。

**`(or …)` 合并多个类型。** 手册原文：想一个分支覆盖多种类型，用 `(or type1 type2 …)` 类型说明符——实测 `(1)`（cons cell）被 `((or symbol cons) …)` 接住。

**`t`/`otherwise` 兜底，`cl-etypecase` 报错版。** 和 case 家族完全对称：`cl-typecase` 无匹配返回 nil，`cl-etypecase` 无匹配报错，实测消息 `cl-etypecase failed: :kw, (integer)`。

## 45.7 `cl-block` 与 `cl-return-from`：具名非局部退出

`catch`/`throw` 是 Emacs 的动态非局部退出；手册 5.5 的 `cl-block`/`cl-return-from` 提供**词法版**。示例第 7 节：

示例第 7 节：

```elisp
(princ (format "  双层循环命中即整体退出：%S\n"
               (cl-block ch45-blk
                 (let ((hits nil))
                   (dolist (i '(1 2 3))
                     (dolist (j '(10 20 30))
                       (push (list i j) hits)
                       (when (= j 20)
                         (cl-return-from ch45-blk (nreverse hits)))))
                   :not-found))))
(princ (format "  不触发时返回最后一个形式：%S\n" (cl-block ch45-b2 1 2 3)))
(princ (format "  体内 lambda 里也能 return-from：%S\n"
               (cl-block ch45-b3
                 (funcall (lambda () (cl-return-from ch45-b3 'from-lambda))))))
(princ (format "  展开看机制：块名被做成一个词法变量：%S\n"
               (macroexpand '(cl-block ch45-b4 (cl-return-from ch45-b4 1)))))
(princ (format "  块名不在词法范围内 → 引用不存在的块变量：%S\n"
               (condition-case err
                   (eval '(cl-return-from ch45-nowhere) t)
                 (error (error-message-string err)))))
```

运行结果：

```
  双层循环命中即整体退出：((1 10) (1 20))
  不触发时返回最后一个形式：3
  体内 lambda 里也能 return-from：from-lambda
  展开看机制：块名被做成一个词法变量：(cl--block-wrapper (let ((--cl-block-ch45-b4-- (cons '--cl-block-ch45-b4-- nil))) (catch --cl-block-ch45-b4-- (cl-return-from ch45-b4 1))))
  块名不在词法范围内 → 引用不存在的块变量："Symbol’s value as variable is void: --cl-block-ch45-nowhere--"
```

逐点读：

**第一实验：这就是「跳出双层循环」的标准解。** 普通 `dolist` 嵌套里想从内层直接结束整个搜索，要么设标志位层层判断，要么 `catch`/`throw`。`cl-block` 给外层起个名字 `ch45-blk`，内层命中时 `(cl-return-from ch45-blk (nreverse hits))` 一步跳出全部循环并带走结果 `((1 10) (1 20))`。

**不触发退出时，`cl-block` 就是 `progn`。** 第二实验 `(cl-block ch45-b2 1 2 3)` 返回最后一个形式 `3`——手册 5.5 原文「The forms are evaluated as if by a progn」。

**体内 lambda 里的 `return-from` 依然有效。** 第三实验：`(cl-return-from ch45-b3 'from-lambda)` 写在体内 lambda 里，`funcall` 它照样跳出块、返回 `from-lambda`。手册特意划定了边界：`return-from` 可以出现在体内、宏展开式里、体内的 lambda 里，但**不能出现在被调用的其他函数里**——下一行的报错正是这条边界的机器证明。

**展开式揭示机制：标签被藏进词法变量。** 第四实验打印 `macroexpand`：`cl-block` 展开成 `(cl--block-wrapper (let ((--cl-block-ch45-b4-- (cons '--cl-block-ch45-b4-- nil))) (catch --cl-block-ch45-b4-- …)))`。底层确实是 `catch`，但 catch 的标签不是裸符号 `ch45-b4`，而是一个**局部变量** `--cl-block-ch45-b4--` 的值（一个新鲜 cons cell）。`cl-return-from` 展开成对同一个变量的 `throw`——只有块体范围内的代码才看得见这个变量。

**词法配对的铁证：出了块就 void。** 第五实验在块外对不存在的块名做 `cl-return-from`（用 `eval` 绕开编译期检查），报错是 `Symbol’s value as variable is void: --cl-block-ch45-nowhere--`——不是「no catch for tag」。对比 `catch`/`throw`：标签是运行时求值的任意对象、动态匹配，调用栈上任何一层都能 throw 进去；块名则是不求值的符号、词法配对，别的函数休想逃进来。手册还补了一句：块名空间和 catch 标签空间**互相独立**，同名不冲突。

**性能注脚：不用就不付钱。** 手册 5.5 说明：块体里若没有任何指向它的 `cl-return`/`cl-return-from`，字节编译器会把 `catch` 整个省掉，开销归零。这也是 `cl-defun`/`cl-loop`/`cl-dolist` 敢默认包隐式块的底气。

**顺带一提 `cl-defun`/`cl-defmacro` 的隐式块。** Common Lisp 里 `defun` 自动把函数体包进以函数名命名的块，`cl-defun`/`cl-defmacro` 保留了这个行为（ Emacs 原生 `defun` 没有）：在 `cl-defun` 函数体内可以直接 `(cl-return-from 函数名 值)` 提前返回。

## 45.8 `cl-return` 与隐式 nil 块：`return` 在 Emacs 里的真相

手册 5.5 说 `cl-return` 恰如 `(cl-return-from nil result)`，而 CL 的循环宏都自带隐式 `nil` 块。示例第 8 节把这条在 Emacs 上的真实边界测清楚——这也是本章的第一个「手册 vs 31.1」大坑：

示例第 8 节：

```elisp
(princ (format "  cl-dolist 里 (cl-return 72)：%S\n"
               (cl-dolist (x '(1 2 3)) (when (= x 2) (cl-return 72)) 'cont)))
(princ (format "  原生 dolist 里没有隐式 nil 块，cl-return 报错：%S\n"
               (condition-case err
                   (eval '(dolist (x '(1 2 3)) (when (= x 2) (cl-return 72))) t)
                 (error (error-message-string err)))))
(princ (format "  手册里的裸 return 在 31.1 根本不存在：(fboundp 'return) = %S\n"
               (fboundp 'return)))
(princ (format "  cl-loop 简单形态（手册 5.6 的无限循环）：%S\n"
               (let ((n 0))
                 (cl-loop (setq n (1+ n))
                          (if (>= n 3) (cl-return n))))))
```

运行结果：

```
  cl-dolist 里 (cl-return 72)：72
  原生 dolist 里没有隐式 nil 块，cl-return 报错："Symbol’s value as variable is void: --cl-block-nil--"
  手册里的裸 return 在 31.1 根本不存在：(fboundp 'return) = nil
  cl-loop 简单形态（手册 5.6 的无限循环）：3
```

逐点读：

**`cl-dolist` 自带隐式 nil 块，`cl-return` 一步跳出。** 第一实验：`(cl-dolist (x '(1 2 3)) …)` 体内 `x=2` 时 `(cl-return 72)` 直接结束循环并返回 72（体内没走完的 `'cont` 分支根本不会执行）。手册 5.6 给的等价式是 `(cl-loop exprs…)` ≡ `(cl-block nil (while t exprs…))`，`cl-dolist`/`cl-dotimes` 同理。

**原生 `dolist` 没有隐式块——实测报错。** 第二实验把同样的 `cl-return` 放进**原生** `dolist`，报错 `Symbol’s value as variable is void: --cl-block-nil--`：原生 `dolist` 展开后没有那个词法块变量，`throw` 无处可去。手册 5.6 那句「cl-dolist 与标准 dolist 完全一样，**只是多了隐式 nil 块**」，差别就在这。

**裸 `return` 在 31.1 不存在。** 第三实验 `(fboundp 'return)` 返回 `nil`——手册示例里写的 `(return 72)` 是 Common Lisp 的写法；在 Emacs 里，`return` 只存在于已废弃的 `cl.el`，`cl-lib` 的正路是 `cl-return`。看到老教程里 `while` 配 `return` 能跑，多半是 `cl.el` 被某个包悄悄加载了。

**`cl-loop` 的简单形态：无限循环 + 隐式块。** 第四实验用手册 5.6 的简单形态：`(cl-loop exprs…)` 把所有表达式无限重复执行，整体包在隐式 nil 块里，所以体内 `(cl-return n)` 能带着值退出，得到 3。手册提醒：表达式里若出现裸符号，会被改判为第 46 章的 Loop 宏规格——这个分界下一章细讲。

## 45.9 `cl-tagbody`：带词法标签的 goto

手册 5.5 的最后一节给了 `cl-tagbody`——Common Lisp 循环的底层骨架。示例第 9 节：

示例第 9 节：

```elisp
(princ (format "  累加到 sum≥10 停止：%S\n"
               (let ((i 0) (sum 0))
                 (cl-tagbody
                   top
                   (setq i (1+ i))
                   (setq sum (+ sum i))
                   (when (< sum 10) (go top)))
                 (list i sum))))
```

运行结果：

```
  累加到 sum≥10 停止：(4 10)
```

逐点读：

**标签就是裸符号，跳转就是 `(go 标签)`。** `cl-tagbody` 里，元素若是裸符号/整数就是标签，若是列表就是语句，按序执行、丢弃返回值；`(go top)` 把控制流跳回 `top` 标签之后。实测 `i` 走到 4、`sum` 走到 10 时条件不再成立，顺序落到 tagbody 末尾，最终打印 `(4 10)`。

**词法作用域、动态 extent。** 手册原话：标签有词法作用域——`(go top)` 只能跳进物理包含它的 `cl-tagbody`，和 `cl-block` 同一套纪律。日常 Elisp 几乎不会手写 `tagbody`，但 `cl-do` 家族的展开式底层就是它，读懂 `go` 才算看懂 CL 循环宏的编译产物。

## 45.10 `cl-do` 与 `cl-do*`：通用迭代

手册 5.6 把 CL 的通用循环 `do`/`do*` 整段搬来。示例第 10 节直接用手册那道「Steele 经典例」：

示例第 10 节：

```elisp
(defun ch45-f (a b) (+ a b))
(let ((foo '(1 2 3)) (bar '(10 20 30)))
  (princ (format "  cl-do（手册例：无 body，全靠 step）：%S\n"
                 (cl-do ((x foo (cdr x))
                         (y bar (cdr y))
                         (z nil (cons (ch45-f (car x) (car y)) z)))
                        ((or (null x) (null y))
                         (nreverse z))))))
(let ((foo '(1 2 3)) (bar '(10 20 30)))
  (princ (format "  cl-do*（串行 step + body push）：%S\n"
                 (cl-do* ((xp foo (cdr xp))
                          (yp bar (cdr yp))
                          (x (car xp) (car xp))
                          (y (car yp) (car yp))
                          z)
                         ((or (null xp) (null yp))
                          (nreverse z))
                         (push (ch45-f x y) z)))))
```

运行结果：

```
  cl-do（手册例：无 body，全靠 step）：(11 22 33)
  cl-do*（串行 step + body push）：(11 22 33)
```

逐点读：

**`cl-do` 的三段式：变量规格、终止测试、体内语句。** 每个规格是 `(var init step)`：先按 `let` 绑定 init；每轮先测 end-test，为真则求值 result 形式返回；否则执行 body，再把各 var 按 step 推进。第一实验**一个 body 都没有**，全靠 step 的副作用：`x`/`y` 沿两个列表并行前进，`z` 每轮把 `(ch45-f (car x) (car y))` cons 上去，列表走完时 `(nreverse z)` 返回 `(11 22 33)`——手册说这等价于 `(cl-mapcar 'f foo bar)`。

**step 是并行赋值——这就是第 44 章 `cl-psetq` 的复用。** 手册明说：`cl-do` 的 step「as if by a cl-psetq form」，三个变量的推进同时基于旧值，`x`、`y` 各走各的 `cdr`，`z` 用旧的 `x`/`y` 累加。

**`cl-do*` 是 `let*`/`setq` 版。** 手册原话：`cl-do*` 之于 `cl-do`，如 `let*` 之于 `let`——init 串行绑定、step 串行赋值。第二实验正是手册给的另一种写法：先推进指针 `xp`/`yp`，再取 `x=(car xp)`、`y=(car yp)`（取到的是**新**指针的值），body 里 `push` 累加。两种写法殊途同归，都得 `(11 22 33)`。

**隐式 nil 块照例存在。** 手册 5.6：整个 `cl-do` 包在隐式 nil 块里，体内随时可以 `(cl-return)` 提前退出（45.8 节已实测 `cl-return` 的机制）。

## 45.11 `cl-dolist` 与 `cl-dotimes`：带块的原生替身

手册 5.6 说这两个宏「和原生 `dolist`/`dotimes` 完全一样，只是多了隐式 nil 块」。示例第 11 节把返回值语义也测了：

示例第 11 节：

```elisp
(let ((total 0))
  (princ (format "  cl-dolist 累加：%S（result 形式 'done）\n"
                 (cl-dolist (x '(1 2 3) 'done) (setq total (+ total x)))))
  (princ (format "  累加结果 = %S\n" total)))
(princ (format "  cl-dotimes 提前退出：%S\n"
               (cl-dotimes (i 10) (when (= i 4) (cl-return i)))))
(princ (format "  cl-dotimes 不带 result 跑完：%S\n"
               (cl-dotimes (i 3) i)))
```

运行结果：

```
  cl-dolist 累加：done（result 形式 'done）
  累加结果 = 6
  cl-dotimes 提前退出：4
  cl-dotimes 不带 result 跑完：nil
```

逐点读：

**result 形式是循环的正常返回值。** `(cl-dolist (x list 'done) …)` 完整跑完后返回 `'done`，而累加 `total` 是 6——result 和副作用各得其所。提前 `cl-return` 时 result 不生效（45.8 第一实验返回的是 72）。

**`cl-dotimes` 的提前退出与「跑完返回 nil」。** 第二实验体内 `i=4` 时 `(cl-return i)` 带走 4；第三实验 `(cl-dotimes (i 3) i)` 跑完返回 `nil`——手册规定：不带 result 时循环返回 nil，且带 var 的 result 用法**已废弃**（手册原文 "Use of result is deprecated"），新代码别依赖 `dotimes` 的 result。

**和原生版的唯一差别就是那块。** 45.8 已实测：原生 `dolist` 里 `cl-return` 直接 void-variable 报错；要用 `cl-return`，就换 `cl-dolist`/`cl-dotimes`。手册还列了 `cl-do-symbols`/`cl-do-all-symbols`（遍历 obarray 里的符号，同样带隐式 nil 块），日常少见，知道名字即可。

## 45.12 多值：`cl-values` 家族用列表模拟

手册 5.8 开宗明义：Common Lisp 函数可以返回零个或多个结果，而这个包**不打算**模拟真正的多返回值——Emacs 版的「多值」就是列表。示例第 12 节把这套列表模拟测完，并顺手验证了 31.1 的一个重大事实：

示例第 12 节：

```elisp
(princ (format "  (cl-values 1 2 3) 就是列表：%S\n" (cl-values 1 2 3)))
(princ (format "  cl-multiple-value-bind 按列表位置绑定：%S\n"
               (cl-multiple-value-bind (a b) (cl-values 1 2 3) (list a b))))
(princ (format "  变量多了补 nil、值多了丢弃：%S\n"
               (cl-multiple-value-bind (a b c d) (cl-values 1 2) (list a b c d))))
(let (x y)
  (cl-multiple-value-setq (x y) (cl-values 8 9))
  (princ (format "  cl-multiple-value-setq 赋给已有变量：x=%S y=%S\n" x y)))
(princ (format "  cl-multiple-value-list 原样返回：%S\n"
               (cl-multiple-value-list (cl-values 1 2 3))))
(princ (format "  cl-multiple-value-call 把列表摊平成实参：%S\n"
               (cl-multiple-value-call #'+ (cl-values 1 2 3))))
(princ (format "  31.1 里原生 values 已不存在：(fboundp 'values) = %S\n"
               (fboundp 'values)))
```

运行结果：

```
  (cl-values 1 2 3) 就是列表：(1 2 3)
  cl-multiple-value-bind 按列表位置绑定：(1 2)
  变量多了补 nil、值多了丢弃：(1 2 nil nil)
  cl-multiple-value-setq 赋给已有变量：x=8 y=9
  cl-multiple-value-list 原样返回：(1 2 3)
  cl-multiple-value-call 把列表摊平成实参：6
  31.1 里原生 values 已不存在：(fboundp 'values) = nil
```

逐点读：

**`cl-values` 就是 `list`。** 手册 5.8 原话：`The cl-values form … is a synonym for list in Emacs`。实测 `(cl-values 1 2 3)` 打印 `(1 2 3)`——没有任何特殊对象，就是一个普通列表。

**`cl-multiple-value-bind` 按位置解列表。** 手册规定：values-form 必须返回**值的列表**，然后像 `let` 一样把各元素绑给各变量；变量多于值，多出的绑 `nil`；值多于变量，多余的值丢弃。实测两行分别验证了这两条：`(a b)` 接 `(1 2 3)` 得 `(1 2)`，`(a b c d)` 接 `(1 2)` 得 `(1 2 nil nil)`。

**`cl-multiple-value-setq`：不绑定，直接 `setq` 给已有变量。** 手册 5.8 的第二宏：values-form 返回的列表按位置 `setq` 给各变量。实测 `x=8 y=9`。

**`cl-multiple-value-list` 与 `cl-multiple-value-call` 是恒等/摊平。** 前者把「多值」原样返回成列表（`(1 2 3)`），后者把列表摊平成函数实参（`(cl-multiple-value-call #'+ (cl-values 1 2 3))` = `(apply #'+ '(1 2 3))` = 6）。在「多值=列表」的模型下，这两个宏的存在感极低——它们只是让 CL 风格代码能原样搬过来。

**31.1 实测：原生 `values` 家族已整体移除。** 最后一行 `(fboundp 'values)` 返回 `nil`——旧版 Emacs 曾有过的原生 `values`/`multiple-value-bind` 机制在当前版本里不存在，`multiple-value-bind` 同样 void。手册 5.8 那句「Emacs Lisp 函数总是恰好返回一个结果」在 31.1 是字面真相。结论：**在 Emacs 里要返回多个值，就返回一个列表**；`cl-multiple-value-bind` 家族能兼容 CL 代码，但新代码直接 `nth`/解构列表更清晰。

## 45.13 小结

本章覆盖手册 5.3–5.6 与 5.8，核心宏一览：

| 宏 | 作用 | 关键语义（实测） |
|---|---|---|
| `cl-flet` | 局部函数绑定 | 词法、**非递归**；被调函数看不到 |
| `cl-labels` | 局部函数绑定 | 词法、可递归/互相递归（需 lexical-binding） |
| `cl-macrolet` | 局部宏绑定 | 体内调用展开为局部定义 |
| `cl-symbol-macrolet` | 符号宏 | 变量引用 ≡ 任意形式；setq ≡ setf |
| `cl-progv` | 运行时动态绑定 | 符号列表+值列表；值不够补 nil |
| `cl-case` / `cl-ecase` | 按值分派（eql） | 无匹配 nil / 报错；t/nil/cons 键必须包列表 |
| `cl-typecase` / `cl-etypecase` | 按类型分派 | `(or …)` 合并类型 |
| `cl-block` / `cl-return-from` | 具名词法退出 | 标签藏进词法变量；不用时编译器省掉 catch |
| `cl-return` | 退出隐式 nil 块 | 裸 `return` 在 31.1 不存在 |
| `cl-tagbody` / `go` | 词法 goto | 标签词法作用域 |
| `cl-do` / `cl-do*` | 通用迭代 | step 并行 / 串行；带隐式 nil 块 |
| `cl-dolist` / `cl-dotimes` | 带块的原生替身 | 与原生唯一差别是隐式 nil 块 |
| `cl-values` 家族 | 多值列表模拟 | `cl-values ≡ list`；原生 values 已移除 |

三条 31.1 实测坑，再强调一遍：裸 `return` 不存在（用 `cl-return`）；原生 `values` 家族不存在（多值=列表）；`cl-return-from` 的词法配对靠 `--cl-block-名--` 词法变量实现，出了块体就是 void-variable 报错。

至此，「名字指向什么」和「怎么跳出正在跑的东西」都讲完了。第 5 章还剩最后一块拼图，也是 CL 最著名的宏——`cl-loop`：一个用「迷你语言」写循环的宏。手册 5.7 整整一节全是它，下一章单独成章。

上一章：[44 · 广义变量：setf、cl-letf 与就地修改](44-generalized-variables.md)　｜　下一章：[46 · cl-loop：Loop 宏的完整语法](46-loop-facility.md)　｜　返回：[Emacs 扩展开发指南](README.md)
