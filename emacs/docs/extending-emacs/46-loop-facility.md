# 46 · cl-loop：Loop 宏的完整语法

> 所属部分：第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

> 示例：`examples/46-loop-facility.el`

`cl-loop` 是 CL 扩展里最著名的宏，也是手册 5.7 用整整六节（Loop  Basics / Examples / For Clauses / Iteration Clauses / Accumulation Clauses / Other Clauses）讲完的东西。它在 Lisp 表达式语法里嵌入了一门**专门描述循环的小语言**：`for`、`while`、`until`、`collect`、`if`、`named`、`finally` 这些词不是函数也不是变量，而是 Loop 宏的**保留字**，彼此串成子句；宏在编译期把整个子句序列一次性翻译成等价的、手工写出来的 `while` 循环——没有闭包、没有解释器、运行时零额外开销。

本章把手册的每个例子、每条规则在 Emacs 31.1 上实测一遍，包括 `in-ref`、`being the symbols` 这些手册明说的 Emacs 专属扩展。开工前先亮三个**只有实测才能发现**的 31.1 事实：其一，迭代器协议住在 `generator.el`（`iter-defun`/`iter-yield`/`iter-do`），`make-iterator` 根本不存在，而且 `cl-loop` 的 `iter-by` 子句要靠 `(require 'generator)` 才注册，不 require 直接报 `Expected a 'for' preposition, found iter-by`；其二，`obarray` 在 31.1 已升级为独立类型，旧写法 `(make-vector 17 nil)` 会被 `intern` 拒绝（`wrong-type-argument obarrayp`），必须用 `obarray-make`；其三，`always` 子句失败时**直接 return nil，`finally` 整个跳过**——手册 5.7.4 只说了一句 "return nil immediately"，实测才看清它连 finally 都不执行。每条都在下文附真实输出。

## 46.1 计数与列表遍历：`to` / `below` / `downto` / `in`

任何 Loop 表达式都以 `cl-loop` 开头，后面跟若干子句。示例第 1 节从最常用的计数与列表遍历入手：

示例第 1 节：

```elisp
(princ (format "  (cl-loop for x to 10 collect x) → %S\n"
               (cl-loop for x to 10 collect x)))
(princ (format "  (cl-loop for x below 10 collect x) → %S\n"
               (cl-loop for x below 10 collect x)))
(princ (format "  (cl-loop for x from 5 downto 1 collect x) → %S\n"
               (cl-loop for x from 5 downto 1 collect x)))
(princ (format "  (cl-loop for x in '(1 2 3 4 5 6) collect (* x x)) → %S\n"
               (cl-loop for x in '(1 2 3 4 5 6) collect (* x x))))
(princ (format "  by 'cddr 隔一个取一个 → %S\n"
               (cl-loop for x in '(1 2 3 4 5 6) by 'cddr collect (* x x))))
(princ (format "  不带累积/return 的循环返回 nil：%S\n"
               (cl-loop for x below 3 do (ignore x))))
```

运行结果：

```
  (cl-loop for x to 10 collect x) → (0 1 2 3 4 5 6 7 8 9 10)
  (cl-loop for x below 10 collect x) → (0 1 2 3 4 5 6 7 8 9)
  (cl-loop for x from 5 downto 1 collect x) → (5 4 3 2 1)
  (cl-loop for x in '(1 2 3 4 5 6) collect (* x x)) → (1 4 9 16 25 36)
  by 'cddr 隔一个取一个 → (1 9 25)
  不带累积/return 的循环返回 nil：nil
  to 含端点、below 不含；by 步长恒为正；in 走元素、可换遍历函数。
```

逐点读：

**`for x to 10`：从 0 数到 10，含端点。** 手册 5.7.3 规定 `for var [from expr] to expr`：起点省略就是 0，终点**包含在内**——所以第一行收集了 11 个数。`below` 则不含终点，`for x below 10` 恰好十个。`from 5 downto 1` 把起点和方向都指定：`downto` 递减、同样含端点，得 `(5 4 3 2 1)`。

**`in` 走列表元素，`by` 换步长/换遍历函数。** `for x in '(1 2 3 4 5 6)` 每轮把一个**元素**交给 `x`。后面可以跟 `by step`（数值步长）或 `by function`：第四行实验 `by 'cddr` 把「前进方式」从 `cdr` 换成 `cddr`，于是每两轮取一个，`x` 依次是 1、3、5，平方后得 `(1 9 25)`。手册原文：`by` 提供的函数作用于「当前位置」，默认对 cons 序列就是 `cdr`。

**`collect` 是累积子句：有它，循环的返回值就是它攒出来的列表。** 前五行的返回值全部来自 `collect`。反过来说，最后一行 `for x below 3 do (ignore x)` 既没有累积也没有 `return`，手册规定这种情况返回 `nil`——实测确认。`do exprs…` 就是「每轮执行这些表达式、不要返回值」，相当于手写循环体。

**保留字不分大小写、`as` 是 `for` 的同义词。** 手册 5.7.1 特意说明：Loop 里的关键字（`for`、`to`、`collect`……）不是函数也不是变量，只是宏的语法词，写 `FOR` 或 `To` 都行；`as` 和 `for` 完全同义。这门小语言的「词汇表」就是本章接下来十一节的目录。

## 46.2 `for on` 与 `for = then`：更一般的遍历

`in` 走元素、`to` 走数字，但 Loop 真正的通用迭代器是 `for var = expr then step-expr`。示例第 2 节：

示例第 2 节：

```elisp
(princ (format "  for x on '(1 2 3 4) 走 cons cell → %S\n"
               (cl-loop for x on '(1 2 3 4) collect x)))
(princ (format "  for x = 表 then (cddr x) + while（手册等价例）→ %S\n"
               (cl-loop for x = '(1 2 3 4 5 6) then (cddr x)
                        while x collect (car x))))
(princ (format "  for x = expr 无 then：每轮重算 → %S\n"
               (let ((seed 0))
                 (cl-loop for x = (setq seed (1+ seed))
                          when (>= x 3) return x))))
```

运行结果：

```
  for x on '(1 2 3 4) 走 cons cell → ((1 2 3 4) (2 3 4) (3 4) (4))
  for x = 表 then (cddr x) + while（手册等价例）→ (1 3 5)
  for x = expr 无 then：每轮重算 → 3
  on 遍历 cons cell；= then 是通用迭代器，本身不带终止条件，
  常配 while/until/return 使用。
```

逐点读：

**`on` 遍历的是 cons cell 本身，不是元素。** 手册 5.7.3 的例子原样实测：`for x on '(1 2 3 4)` 里 `x` 依次拿到 `(1 2 3 4)`、`(2 3 4)`、`(3 4)`、`(4)`——每个是列表的连续后缀。想「看着尾巴判断还剩几个」时用 `on`，想拿元素时用 `in`。`on` 同样可以配 `by`。

**`for x = expr then step` 是万能迭代器。** 第二行是手册给的等价例：`for x = '(1 2 3 4 5 6) then (cddr x) while x collect (car x)`——第一轮 `x` 取 init 表达式，之后每轮 `x` 取 `then` 后面的步进式；`while x` 负责终止（`x` 走到 `nil` 就停）。实测得 `(1 3 5)`，和 46.1 里 `by 'cddr` 的结果一字不差。手册明说：`for x in l` ≡ `for x on l` 再取 `car`，`for x to n` 也只是 `= then` 的语法糖——**所有 for 子句底层都是「初始值 + 步进式 + 终止条件」三件套**。

**没有 `then` 时，init 每轮重新求值。** 第三行 `for x = (setq seed (1+ seed))` 不带 `then`，手册规定此时该表达式**每轮都算一次**——于是 `x` 依次是 1、2、3，`(when (>= x 3) return x)` 在第三轮带走 3。这个形态适合「每轮都要重算的派生值」，而不是「沿一条序列前进」。

**`= then` 自身不带终止条件。** 对比 `to`/`below`/`in`（走完即停），`= then` 永远不会自己停下来，所以实测里必须配 `while` 或 `return`，否则就是无限循环。手册给的终止式是 `while condition` / `until condition`（46.7 节细讲）。

## 46.3 顺序 for 与 `and` 并行 for：一个 `let*` 与 `let` 的区别

同一个循环里写两个 `for` 子句，连续写和用 `and` 链接，语义完全不同。示例第 3 节用一对几乎相同的表达式把这个差别钉死：

示例第 3 节：

```elisp
(princ (format "  for x below 5 for y = nil then x → %S\n"
               (cl-loop for x below 5 for y = nil then x collect (list x y))))
(princ (format "  for x below 5 and y = nil then x → %S\n"
               (cl-loop for x below 5 and y = nil then x collect (list x y))))
```

运行结果：

```
  for x below 5 for y = nil then x → ((0 nil) (1 1) (2 2) (3 3) (4 4))
  for x below 5 and y = nil then x → ((0 nil) (1 0) (2 1) (3 2) (4 3))
  连续 for 串行（≡ let*+setq）；and 链接则并行（≡ let+cl-psetq），
  y 看到的 x 是上一轮留下的旧值。
```

逐点读：

**两个实验只差一个词：`for` 还是 `and`。** 子句都是「`x` 从 0 数到 4；`y` 初始 `nil`，之后每轮取 `x`」。第一行连续写两个 `for`，第二行用 `and` 把第二个 for 并进第一个。结果却不同：串行版 `y` 是 `(nil 1 2 3 4)`，并行版 `y` 是 `(nil 0 1 2 3)`。

**手册的等价式：连续 for ≡ `let*` + 串行 `setq`；`and` ≡ `let` + `cl-psetq`。** 串行时，`y` 的步进式 `(setq y x)` 在 `x` 的步进**之后**执行，所以 `y` 拿到的是本轮已经推进过的 `x`（第一轮 `x` 变 1，`y` 才第一次执行 `then`，得 1）。并行时，两个步进式像第 45 章 `cl-do` 的 step 一样按 `cl-psetq` 同时求值——`y` 拿到的 `x` 还是上一轮的旧值，于是整体错开一拍。这正是第 44/45 章反复出现的「串行赋值 vs 并行赋值」分界在 Loop 里的再现。

**记住这条，Loop 里所有「变量互相引用」的困惑都能自解。** 需要「本轮新值」就连续写 `for`；需要「上一轮旧值」或者多个变量按旧值互相推导（比如滑动窗口），就用 `and` 链接。

## 46.4 `for` 的解构：变量位可以写 lambda-list

`for` 的变量位不一定是一个符号，可以写 `(x y)`、`(key . value)` 这样的**解构模式**。示例第 4 节：

示例第 4 节：

```elisp
(princ (format "  for (x y) in '((2 3) (4 5) (6 7)) collect (+ x y) → %S\n"
               (cl-loop for (x y) in '((2 3) (4 5) (6 7)) collect (+ x y))))
(princ (format "  for (key . value) in alist collect key/value → %S\n"
               (cl-loop for (key . value) in '((a . 1) (b . 2))
                        collect (cons key value))))
(princ (format "  nil 占位丢弃对应列 → %S\n"
               (cl-loop for (x nil y) in '((1 2 3) (4 5 6))
                        collect (list x y))))
```

运行结果：

```
  for (x y) in '((2 3) (4 5) (6 7)) collect (+ x y) → (5 9 13)
  for (key . value) in alist collect key/value → ((a . 1) (b . 2))
  nil 占位丢弃对应列 → ((1 3) (4 6))
  for 的变量位可以写 lambda-list：值多丢弃、变量多补 nil，
  nil 当占位符。和第 42 章宏参数解构同一套语法。
```

逐点读：

**`(x y)` 把每个元素（本身是列表）拆开。** 第一行是手册 5.7.3 的原例：`for (x y) in '((2 3) (4 5) (6 7))` 让 `x`、`y` 分别拿到每个二元列表的两列，`(+ x y)` 得 `(5 9 13)`。

**`(key . value)` 拆 cons cell。** 第二行遍历 alist：每个元素是 `(a . 1)` 这样的 cons，`key` 拿 `car`、`value` 拿 `cdr`，重新 `cons` 回去验证绑定正确——输出 `((a . 1) (b . 2))`。

**`nil` 是占位符，表示「这一列我不要」。** 第三行 `(x nil y)` 跳过中间列，直接拿第一、三列，得 `((1 3) (4 6))`。手册规定：解构模式里的 `nil` 就是「丢弃对应位置」；反过来，若模式的变量比值的元素**多**，多出来的变量绑 `nil`；**少**则多余的值丢弃。

**这套规则和 `cl-defmacro`/`cl-destructuring-bind` 完全同源。** 第 42 章讲宏参数解构时立的规矩——「按 lambda-list 的形状拆，拆不满补 nil，多余丢」——在 Loop 的 `for` 位原样适用。会一处就会三处。顺带一提：字节编译时解构里绑了却没用的变量会触发 unused lexical 警告，真要丢弃就老实写 `nil`，别占个名字。

## 46.5 `across`、`being the elements` 与 `in-ref`：向量、字符串与就地修改

列表之外，Loop 还能走向量和字符串，甚至能**就地改**它们的元素。示例第 5 节：

示例第 5 节：

```elisp
(princ (format "  for x across \"aeiou\" 走字符串 → %S\n"
               (cl-loop for x across "aeiou" collect x)))
(princ (format "  being the elements + using (index i) → %S\n"
               (cl-loop for e being the elements of '(10 20 30)
                        using (index i) collect (list i e))))
(let ((l (list 1 2 3)))
  (cl-loop for x in-ref l do (cl-incf x))
  (princ (format "  in-ref 就地改列表 → %S\n" l)))
(let ((v (vector 1 2 3)))
  (cl-loop for x across-ref v do (cl-incf x))
  (princ (format "  across-ref 就地改向量 → %S\n" v)))
```

运行结果：

```
  for x across "aeiou" 走字符串 → (97 101 105 111 117)
  being the elements + using (index i) → ((0 10) (1 20) (2 30))
  in-ref 就地改列表 → (2 3 4)
  across-ref 就地改向量 → [2 3 4]
  in-ref/across-ref 是 Emacs 扩展：循环变量是对元素的 setf 引用，
  直接接上第 44 章的 place 体系。
```

逐点读：

**`across` 走向量，也走字符串。** 手册 5.7.3：`for x across vector` 逐元素遍历任意序列。实测对字符串 `"aeiou"` 用 `across`，每个「元素」是字符的**整数码**——得 `(97 101 105 111 117)`。想拼回字符就 `(char-to-string x)` 或 `concat`。

**`being the elements of` 是 `in` 的正式写法，`using` 附带索引。** 手册原文说 CL 风格里 `being the` 可以出现在某些子句前，本包里 `being`/`the` 都是可选词。第二行用完整形态 `for e being the elements of '(10 20 30)`，再挂一个 `using (index i)`——`i` 是元素下标，实测收集出 `((0 10) (1 20) (2 30))`。`using` 是「给这类遍历配辅助变量」的统一语法，46.6 的 `hash-values`、`key-bindings` 全靠它。

**`in-ref` / `across-ref`：循环变量是「对元素的引用」，不是元素的拷贝。** 这是手册明说的 **Emacs 扩展**：`for x in-ref l` 里 `x` 是一个 place——`(cl-incf x)` 直接改列表本体，实测 `l` 从 `(1 2 3)` 变 `(2 3 4)`；`across-ref` 对向量同理，`v` 原地变 `[2 3 4]`。没有这两个子句，就地改列表得手写 `(setf (nth i l) …)` 并自己维护索引。第 44 章讲的广义变量体系在这里和 Loop 接上了：**`in-ref` 就是把循环变量做成 `nth` 的 setf 引用**。注意手册提醒：`ref` 系列遍历期间别对序列做增删结构操作。

## 46.6 Emacs 专属 for 子句：符号、哈希表、键码、interval、buffer

Loop 的 for 子句家族里有一批**手册明说是 Emacs 专属**的扩展，遍历的是 Emacs 自己的对象。示例第 6 节一次测五种：

示例第 6 节：

```elisp
(let ((ob (obarray-make 17)))
  (intern "mapcar" ob) (intern "map" ob) (intern "sort" ob)
  (princ (format "  being the symbols（按名过滤）→ %S\n"
                 (sort (cl-loop for s being the symbols of ob
                                when (string-match "\\`map" (symbol-name s))
                                collect s)
                       (lambda (p q) (string< (symbol-name p) (symbol-name q)))))))
(let ((h (make-hash-table :test 'equal)))
  (puthash "a" 1 h) (puthash "b" 2 h)
  (princ (format "  hash-keys using hash-values → %S\n"
                 (sort (cl-loop for k being the hash-keys of h
                                using (hash-values v) collect (cons k v))
                       (lambda (p q) (string< (car p) (car q)))))))
(let ((m (make-sparse-keymap)))
  (define-key m "a" 'cmd-a)
  (define-key m "b" 'cmd-b)
  (princ (format "  key-codes using key-bindings → %S\n"
                 (sort (cl-loop for c being the key-codes of m
                                using (key-bindings b) collect (cons c b))
                       (lambda (p q) (< (car p) (car q)))))))
(let ((s (copy-sequence "abcdef")))
  (put-text-property 0 3 'face 'bold s)
  (princ (format "  intervals of 串 property 'face → %S\n"
                 (cl-loop for (a . b) being the intervals of s
                          property 'face collect (list a b)))))
(princ (format "  being the buffers → %S\n"
               (cl-loop for b being the buffers collect (buffer-name b))))
```

运行结果：

```
  being the symbols（按名过滤）→ (map mapcar)
  hash-keys using hash-values → (("a" . 1) ("b" . 2))
  key-codes using key-bindings → ((97 . cmd-a) (98 . cmd-b))
  intervals of 串 property 'face → ((0 3) (3 6))
  being the buffers → ("*scratch*" " *Minibuf-0*" "*Messages*" " *load*")
  symbols/hash/keymap/overlay/interval/frame/window/buffer——
  手册明说这些都是 Emacs 专属扩展，同类子句一个循环里只能来一个。
  31.1 实测：obarray 已升级为独立类型，旧写法 (make-vector 17 nil)
  会被 intern 拒绝（wrong-type-argument obarrayp），必须 obarray-make。
```

逐点读：

**`being the symbols of obarray`：遍历符号表。** 第一行造一个私有 obarray，intern 三个符号，循环里用 `when` 按名字前缀过滤，收出 `(map mapcar)`。不写 `of ob` 时默认遍历**全局** obarray——写「扫一遍所有 Emacs 符号」的体检脚本就用这个子句。

**`being the hash-keys of table using (hash-values v)`：哈希表双变量遍历。** 第二行是标准搭配：`k` 走键、`v` 同步走值，实测收出 `(("a" . 1) ("b" . 2))`。没有 `using` 时只遍历键；`being the hash-values of table` 也可以单独走值。

**`being the key-codes of keymap using (key-bindings b)`：遍历键绑定。** 第三行把稀疏 keymap 的「键码 → 命令」对收出来：`"a"` 的键码是 97，绑定 `cmd-a`，得 `((97 . cmd-a) (98 . cmd-b))`。写「导出/检查某个 keymap 全部绑定」的工具时，这个子句比手写 `where-is-internal` 循环干净得多。

**`being the intervals of string property 'face`：遍历文本属性区间。** 第四行给字符串 `"abcdef"` 的 0–3 位置打 `face` 属性，循环用 `(a . b)` 解构拿到每个区间的起止位置，收出 `((0 3) (3 6))`——「有属性的一段」和「没属性的剩下整段」各成一个 interval。这是处理 `put-text-property` 数据（overlay 同理，用 `being the overlays of buffer`）的专用遍历。

**`being the buffers`：遍历所有 buffer。** 第五行收出当前 Emacs 会话的全部 buffer 名。batch 模式下就是输出里那四个（`*scratch*`、两个内部 buffer、`*load*`）；同类还有 `being the frames`、`being the windows`。手册特意提醒：这类子句的遍历顺序不保证，示例里凡结果可能不确定的（symbols、hash、keymap、buffers）都先 `sort` 再打印，保证输出可复现。

**两条手册级约束。** 其一，这一族子句（`symbols`/`hash-keys`/`key-codes`/`overlays`/`intervals`/`frames`/`windows`/`buffers`）是 **Emacs 扩展**，Common Lisp 标准 Loop 里没有；其二，**同一类子句一个循环只能出现一次**——你不能在一个 loop 里同时 `being the hash-keys of h1` 又 `being the hash-keys of h2`。

**31.1 实测坑：obarray 不再是普通向量。** 示例注释里记了踩坑现场：旧教程惯用 `(make-vector 17 nil)` 造 obarray，在 31.1 上 `intern` 会直接拒绝并报 `wrong-type-argument obarrayp`——`obarray` 已升级为独立类型，正路是 `obarray-make`（清空用 `obarray-clear`，判类型用 `obarrayp`）。凡遍历符号表的代码，这是必须改的一行。

## 46.7 `iter-by`、`repeat`、`while`、`until`：迭代控制子句

手册 5.7.4 讲「不是 for、但控制循环怎么转」的四个子句。示例第 7 节：

示例第 7 节：

```elisp
(iter-defun ch46-gen (lst)
  "生成器：逐个 yield 列表元素。"
  (dolist (x lst) (iter-yield x)))
(princ (format "  iter-by 接 generator 迭代器 → %S\n"
               (cl-loop for x iter-by (ch46-gen '(10 20 30))
                        collect x)))
(princ (format "  repeat 20（手册 Yowsa 例改计数）→ %S\n"
               (let ((n 0)) (cl-loop repeat 20 do (setq n (1+ n))) n)))
(princ (format "  while 版 ≡ 原生 while：%S\n"
               (let ((l (list 1 2 3)) (acc nil))
                 (cl-loop while l do (push (pop l) acc))
                 (nreverse acc))))
(princ (format "  until 在前可零次：%S；do 在前至少一次：%S\n"
               (let ((n 3)) (cl-loop until (= n 3) do (setq n (1+ n))) n)
               (let ((n 3)) (cl-loop do (setq n (1+ n)) until (= n 4)) n)))
```

运行结果：

```
  iter-by 接 generator 迭代器 → (10 20 30)
  repeat 20（手册 Yowsa 例改计数）→ 20
  while 版 ≡ 原生 while：(1 2 3)
  until 在前可零次：3；do 在前至少一次：4
  手册原话：until 放 do 前「立即检查」、放 do 后「至少跑一次」。
  31.1 实测：迭代器协议住在 generator.el（iter-defun/iter-yield/iter-do），
  make-iterator 不存在；cl-loop 的 iter-by 子句要靠 require generator 注册。
```

逐点读：

**`iter-by` 把任意迭代器接进 Loop。** 手册 5.7.4 说 `for x iter-by iterator-form` 会反复调用迭代器的 `step` 方法直到 `iteration-end`。31.1 的迭代器协议住在 `generator.el`：`iter-defun` 定义协程函数、`iter-yield` 吐值、`iter-do` 消费。第一行实验用 `iter-defun` 造了个逐个 yield 列表元素的生成器，`cl-loop for x iter-by (ch46-gen '(10 20 30))` 收出 `(10 20 30)`。

**两个实测硬坑：`make-iterator` 不存在；`iter-by` 子句要靠 require 注册。** 手册提到 `make-iterator` 可以帮普通序列造迭代器——31.1 里这个函数**根本没有**，迭代器只能来自 `generator.el` 的 `iter-defun` 或 `iter-make`。更隐蔽的是：`iter-by` 这个「for 前置词」是 `generator.el` 加载时才向 `cl-loop` 注册的，示例文件顶部没有 `(require 'generator)` 的话，编译期直接报 `Expected a 'for' preposition, found iter-by`。本章示例第 16 行就放着这句 require。

**`repeat count`：无变量循环 N 次。** 手册给的是 `(repeat (random t))` 随机次数的 Yowsa 彩蛋例，示例改成确定性的 `repeat 20` 配计数，得 20。它等价于 `for x below 20` 但不要变量。

**`while cond` / `until cond`：纯终止条件。** 第三行 `cl-loop while l do (push (pop l) acc)` 就是原生 `while` 循环的 Loop 写法，弹出顺序 push 再 `nreverse`，得 `(1 2 3)`。`while` 是「条件为假就停」，`until` 是「条件为真就停」。

**`until` 放 `do` 前还是后，是「零次」和「至少一次」的区别。** 手册 5.7.4 的原话：`until` 出现在任何 `do` 之前则「立即检查」，出现在 `do` 之后则「至少执行一次」。第四行实测两版：`n` 初值 3，`until (= n 3)` 在前——第一轮还没跑条件就成立，循环零次，`n` 保持 3；`do (setq n (1+ n)) until (= n 4)`——先跑一次体再检查，`n` 变 4 后停，得 4。

## 46.8 `always` / `never` / `thereis`：三个「带返回值」的量词

手册 5.7.4 末尾有三个既是迭代控制、又自带返回语义的子句。示例第 8 节把它们的正常行为和一条短路怪癖全测了：

示例第 8 节：

```elisp
(princ (format "  always 全真 → %S\n"
               (cl-loop for x in '(2 4 6) always (> x 1))))
(princ (format "  always 有假 → %S\n"
               (cl-loop for x in '(2 4 6) always (> x 3))))
(princ (format "  never 全假 → %S\n"
               (cl-loop for x in '(2 4 6) never (> x 10))))
(princ (format "  thereis 第一个非 nil → %S\n"
               (cl-loop for x in '(1 2 3 4) thereis (and (> x 2) x))))
(princ (format "  always 失败短路（finally 不跑）→ %S\n"
               (cl-loop for x in '(1 2 3) always (> x 1)
                        finally do (princ "    [finally-RAN]\n"))))
(princ (format "  always 全真跑完 finally return → %S\n"
               (cl-loop for x in '(2 4) always (> x 1)
                        finally return 'fin)))
```

运行结果：

```
  always 全真 → t
  always 有假 → nil
  never 全假 → t
  thereis 第一个非 nil → 3
  always 失败短路（finally 不跑）→ nil
  always 全真跑完 finally return → fin
  always/never 是谓词量词，thereis 是「找第一个」；
  注意：always 失败时直接 return nil，finally 不执行（手册 5.7.4）。
```

逐点读：

**`always` 是「对所有元素，条件恒真吗」。** 每轮求值条件表达式，任何一轮为 `nil` 就立刻结束循环、返回 `nil`；全部为真则返回 `t`。实测前两行分别得 `t` 和 `nil`。`never` 语义相反——「所有元素都不满足」才返回 `t`，第三行 `(> x 10)` 全假得 `t`。

**`thereis` 是「找第一个满足的」。** 每轮求值表达式，返回第一个非 `nil` 的**值**（不是 `t`），找不到返回 `nil`。第四行 `(and (> x 2) x)` 在 `x=3` 时第一次为真，整个循环就返回 3——这就是「取列表里第一个大于 2 的数」的 Loop 写法。

**怪癖实测：`always` 失败时 `finally` 整个跳过。** 第五行故意让 `always` 在 `x=1` 时失败，并挂了一个会打印 `[finally-RAN]` 的 `finally do`——看输出：只有一行 `→ nil`，**`[finally-RAN]` 根本没打印**。手册 5.7.4 那句 "if any evaluation returns nil, return nil immediately" 的 "immediately" 是字面意思：`always` 的失败退出走的是 `return` 路径，而 `return` 类退出不执行 `finally`（46.12 会再验证一次）。第六行对照组里 `always` 全真跑完，`finally return 'fin` 正常生效、返回 `fin`。想「检查失败也要收尾」，别用 `always`，用 `unless ... return` 加显式清理。

## 46.9 累积子句全家福：`collect` 到 `minimize`

手册 5.7.5 列了十一个累积子句，每个都同时做两件事：攒值、定义循环返回值。示例第 9 节全部过一遍：

示例第 9 节：

```elisp
(princ (format "  collecting（collect 同义词）→ %S\n"
               (cl-loop for x below 3 collecting x)))
(princ (format "  append → %S\n"
               (cl-loop for x in '((1) (2 3)) append x)))
(princ (format "  nconc → %S\n"
               (cl-loop for x in '((4) (5 6)) nconc x)))
(princ (format "  concat → %S\n"
               (cl-loop for s in '("ab" "cd") concat s)))
(princ (format "  vconcat → %S\n"
               (cl-loop for v in '((1 2) (3)) vconcat v)))
(princ (format "  count → %S\n"
               (cl-loop for x in '(1 2 3 4) count (> x 2))))
(princ (format "  sum → %S\n" (cl-loop for x in '(1 2 3) sum x)))
(princ (format "  maximize → %S；minimize → %S\n"
               (cl-loop for x in '(3 9 1 7) maximize x)
               (cl-loop for x in '(3 9 1 7) minimize x)))
(princ (format "  手册 Steele 例（collect+append 同池）→ %S\n"
               (cl-loop for name in '(fred sue alice joe june)
                        for kids in '((bob ken) () () (kris sunshine) ())
                        collect name
                        append kids)))
```

运行结果：

```
  collecting（collect 同义词）→ (0 1 2)
  append → (1 2 3)
  nconc → (4 5 6)
  concat → "abcd"
  vconcat → [1 2 3]
  count → 2
  sum → 6
  maximize → 9；minimize → 1
  手册 Steele 例（collect+append 同池）→ (fred bob ken sue alice joe kris sunshine june)
  累积结果默认就是返回值；同类累积可以汇进同一个「池」。
```

逐点读：

**列表/串/向量三类「拼接池」。** `collect`（`collecting` 是同义词，第一行验证）把每轮的值攒成新列表；`append` 把每轮的值（应为列表）拼进池——`(1)` 和 `(2 3)` 得 `(1 2 3)`；`nconc` 同 `append` 但**就地**改各列表的尾巴，实测结果一样 `(4 5 6)`，差别在会不会动你的原数据；`concat` 攒字符串片段得 `"abcd"`；`vconcat` 攒序列得向量 `[1 2 3]`。

**数值类：`count`、`sum`、`maximize`、`minimize`。** `count` 只数非 `nil` 的轮次——`(> x 2)` 对 `(1 2 3 4)` 有两次为真，得 2；`sum` 累加数值，`(1 2 3)` 得 6；`maximize`/`minimize` 取极值，`(3 9 1 7)` 分别得 9 和 1。手册规定：这些子句要求每轮的值是数（或 `nil`，跳过不比较），`maximize`/`minimize` 用 `>`/`<` 比较。

**同类累积汇进同一个「池」——手册的 Steele 经典例。** 最后一行同时用 `collect` 和 `append`：`name` 逐个 collect，`kids` 逐个 append，两者写在一起、按执行顺序汇入**同一个列表**——`fred` 后紧跟它的孩子 `bob ken`，`sue` 没有孩子就光秃秃一个。实测输出 `(fred bob ken sue alice joe kris sunshine june)` 与手册一字不差。这就是「名字-孩子」配对展开的 Loop 写法。

**没有 `into` 时，累积结果就是循环的返回值；多个累积子句共存时，返回值是「最后一个」子句的池吗？** 不——手册 5.7.5 规定：不带 `into` 的多个累积子句**共享同一个结果变量**（Steele 例正是如此），但 `count`/`sum`/`maximize` 这类数值池和列表池是**分开**的，若同时存在多个独立池又没写 `into`，手册的措辞是结果未定义——想要多池共存，老实写 `into`（下一节）。

## 46.10 `into` 与 `with`：具名累积池和循环外变量

累积子句挂上 `into var` 就不再自动返回，而是把池子存进一个具名变量；`with` 则给循环加一个外层绑定。示例第 10 节：

示例第 10 节：

```elisp
(princ (format "  into + finally return → %S\n"
               (cl-loop for x below 5 collect x into all
                        when (cl-oddp x) collect x into odds
                        finally return (list all odds))))
(princ (format "  手册 with res push 例 → %S\n"
               (cl-loop for x in '(1 2 3) with res
                        do (push x res)
                        finally return res)))
(princ (format "  with 绑在循环外层 → %S\n"
               (cl-loop for i below 3 with x = 17 collect (+ i x))))
```

运行结果：

```
  into + finally return → ((0 1 2 3 4) (1 3))
  手册 with res push 例 → (3 2 1)
  with 绑在循环外层 → (17 18 19)
  into 把累积存进具名变量，但不再自动返回——必须 finally return；
  with ≡ 循环外的 let，全程只绑一次。
```

逐点读：

**`into` 造出两个互不干扰的池。** 第一行 `collect x into all` 攒全部，`when (cl-oddp x) collect x into odds` 只攒奇数——两个 `collect` 因为 `into` 不同而各进各池，`finally return (list all odds)` 把两池一起带走，得 `((0 1 2 3 4) (1 3))`。**关键语义：一旦写了 `into`，该累积子句就不再是返回值**——不配 `finally return`，循环返回值归 `nil`。这是手册 5.7.5 的原话，也是 46.9 末尾「多池共存」的正解。

**`with` 是「循环外的 let」：只绑定一次，全程存活。** 第二行是手册 5.7.6 的原例：`with res`（初值 `nil`）配体内 `push`，循环正常结束后 `finally return res`——因为 `push` 是倒着挂，返回的是 `(3 2 1)` 而不是 `(1 2 3)`。`with` 变量和累积池的区别在于它没有「每轮自动攒」的语义，纯靠体内表达式操作；适合「跨轮维护一个累加器/缓冲区」的场景。第三行 `with x = 17` 给了初值，`x` 在循环外绑定一次，每轮 `(+ i x)` 得 `(17 18 19)`——手册强调 `with` 的绑定**不在循环体内**，每轮不会重新初始化，这正是它和 `for = then` 的分界。

## 46.11 Loop 里的 `if` / `when` / `unless`：`and`、`else`、`end` 与 `it`

手册 5.7.6 把条件语句也搬进了小语言：`if cond-clause else-clause`，子句之间用 `and` 链接，`end` 收束嵌套。示例第 11 节用手册的 funny-numbers 例做主菜：

示例第 11 节：

```elisp
(let ((funny-numbers '(6 13 -1)))
  (princ (format "  手册例第一跑（oddp 为原生函数）→ %S\n"
                 (cl-loop for x below 10
                          if (oddp x)
                            collect x into odds
                            and if (memq x funny-numbers) return (cdr it) end
                          else
                            collect x into evens
                          finally return (vector odds evens)))))
(let ((funny-numbers '(6 7 13 -1)))
  (princ (format "  7 进了 funny 提前 return → %S\n"
                 (cl-loop for x below 10
                          if (oddp x)
                            collect x into odds
                            and if (memq x funny-numbers) return (cdr it) end
                          else
                            collect x into evens
                          finally return (vector odds evens)))))
(princ (format "  when/unless + it → %S\n"
               (cl-loop for x in '(1 2 3 4 5)
                        when (cl-evenp x) collect it into evens
                        unless (> x 10) collect x into smalls
                        finally return (list evens smalls))))
```

运行结果：

```
  手册例第一跑（oddp 为原生函数）→ [(1 3 5 7 9) (0 2 4 6 8)]
  7 进了 funny 提前 return → (13 -1)
  when/unless + it → ((t t) (1 2 3 4 5))
  it 拿到条件的那个非 nil 值；end 用来消歧嵌套 if 的 else 归属。
```

逐点读：

**先读这个循环在干什么。** `x` 从 0 数到 9；`if (oddp x)` 为真时：先把 `x` collect 进 `odds` 池，**并且**（`and`）再嵌套一个 `if (memq x funny-numbers)`——若 `x` 在 funny 名单里，立刻 `return (cdr it)`；为假时（`else`）collect 进 `evens`。正常跑完由 `finally return (vector odds evens)` 交出两个池。

**第一跑：funny 名单 `(6 13 -1)` 里没有奇数，循环善终。** `oddp` 是 Emacs 原生函数（CL 的 `oddp` 对应 `cl-oddp`，手册例用的是原生版）。10 以内奇数 1、3、5、7、9 全进 `odds`，偶数全进 `evens`，`finally` 打包成向量返回：`[(1 3 5 7 9) (0 2 4 6 8)]`——和手册输出一致。

**第二跑：把 7 加进名单，循环在 `x=7` 时提前 `return`。** `(memq 7 '(6 7 13 -1))` 返回**包含 7 的那个尾巴** `(7 13 -1)`——这就是 `it` 的值；`(cdr it)` 得 `(13 -1)`，实测输出正是 `(13 -1)`。两个信息：其一，`return` 一旦执行，`finally` 不跑（46.8 的怪癖在这里第二次现身，输出里没有任何 `finally` 的痕迹）；其二，嵌套 `if` 的条件值也能被 `it` 拿到——`it` 永远指「当前这一层条件表达式求出的那个非 nil 值」。

**`end` 的作用：消歧 `else` 归谁。** 嵌套的 `and if … end` 若没有 `end`，后面的 `else` 会被编译器判给**内层** `if`（手册 5.7.6 原文：`else` 默认属于最近的 `if`）。写上 `end` 明确「内层 if 到此为止」，`else` 才能正确挂回外层。手册还补了一句：`end` 同时终止 `and` 链接。

**`when`/`unless` 是 `if` 的无 else 变体，`it` 统一适用。** 第三行：`when (cl-evenp x) collect it` 把「条件为真时的那个真值」收进池——`cl-evenp` 返回 `t`，所以 `evens` 是 `(t t)`（两个偶数各贡献一个 `t`）；`unless (> x 10) collect x` 收集所有不大于 10 的数得 `(1 2 3 4 5)`。想收「条件值本身」用 `it`，想收别的就用普通表达式——`it` 是 `when`/`unless`/`if` 家族共用的保留字。

## 46.12 `named`、`initially`、`finally`、`return`：一条时间轴

手册 5.7.6 的最后一族子句定义了循环的「生命周期」。示例第 12 节把时序完整打点：

示例第 12 节：

```elisp
(princ (format "  named 起块名 + cl-return-from → %S\n"
               (cl-loop named ch46-out for x below 100
                        when (= x 3) do (cl-return-from ch46-out 'found))))
(princ (format "  正常跑完 → %S\n"
               (cl-loop for x below 3
                        initially do (princ "    [initially]\n")
                        collect x
                        finally do (princ "    [finally-do]\n")
                        finally return (list 'ret x))))
(princ (format "  return 提前退出 → %S\n"
               (cl-loop for x below 3
                        do (princ "    [body]\n")
                        when (= x 1) return 'early
                        finally do (princ "    [finally-SKIPPED]\n"))))
```

运行结果：

```
  named 起块名 + cl-return-from → found
    [initially]
    [finally-do]
  正常跑完 → (ret 3)
    [body]
    [body]
  return 提前退出 → early
  named 给隐式块命名；initially 循环前跑、finally 正常结束后跑；
  return（含 always 的短路）直接跳出，finally 整个跳过。
```

逐点读：

**`named name`：给循环的隐式块起个名字。** 第 45 章讲过 `cl-loop` 整体包在隐式 `nil` 块里、`cl-return` 跳的是它；`named` 把块名从 `nil` 换成 `ch46-out`，于是体内可以用 `cl-return-from ch46-out` 精确退出——实测 `x=3` 时带走 `'found`。当你的 `cl-loop` 外面还套着别的隐式块（比如 `cl-defun` 的函数名块、外层 `cl-block`），`named` + `return-from` 比裸 `cl-return` 更不容易「跳错层」。

**`initially` 在循环开始前跑一次；`finally` 在循环正常结束后跑。** 第二行的打点输出把顺序摆得清清楚楚：先打印 `[initially]`，循环体静默 collect（`collect` 不打印），跑完先 `[finally-do]`、再返回 `finally return` 的值。注意返回值 `(ret 3)`：`finally` 求值时循环变量 `x` 已经推进到**终值 3**（`below 3` 走完时 `x` 是 3）——手册 5.7.6 特意提醒 `finally` 里能看到循环变量的终值，别指望它还是最后一次进入循环体的值。

**`finally do` 与 `finally return` 可以并存，各跑各的。** 第二行同时挂了 `finally do`（打印）和 `finally return`（定返回值），实测两者都执行、顺序是 do 在前 return 在后。

**`return` 提前退出：`finally` 整个跳过。** 第三行体内 `x=1` 时 `return 'early`，挂着的 `finally do` 打印 `[finally-SKIPPED]`——看输出：只有两行 `[body]`（`x=0`、`x=1` 各进一次，`x=2` 没跑到），**没有任何 finally 打印**。这和 46.8 的 `always` 短路是同一机制：`return`（以及 `cl-return-from`）是直接跳出，不走收尾。手册 5.7.6 的措辞是 `finally` 只在「循环正常终止」时执行。

**把时间轴背下来，Loop 的返回语义就通了。** 顺序是：`initially` → 若干轮（for/while/if/do/累积）→ 正常结束则 `finally`（先 do 后 return）→ 返回；任何一轮里 `return` / `always` 短路 / `cl-return-from` 触发，直接跳出、`finally` 不执行、返回 `return` 的值。

## 46.13 小结

本章覆盖手册 5.7 全部六节，Loop 子句一览：

| 类别 | 子句 | 关键语义（实测） |
|---|---|---|
| for 遍历 | `to` / `below` / `downto` / `in` / `on` / `across` | to/downto 含端点，below 不含；`by` 换步长或遍历函数 |
| for 通用 | `= expr then step` | 不带终止条件，须配 while/until/return；无 then 则每轮重算 |
| for 并行 | `for … and …` | 串行 for ≡ let*+setq；and ≡ let+cl-psetq（旧值） |
| for 解构 | `(x y)` / `(key . value)` / `nil` 占位 | 与宏参数解构同一套 lambda-list 规则 |
| Emacs 扩展 | `in-ref` / `across-ref` | 循环变量是 setf 引用，就地改元素 |
| Emacs 扩展 | `being the symbols/hash-keys/key-codes/intervals/overlays/buffers…` | 配 `using (index i)` / `(hash-values v)` 等；同类一个循环只能一个 |
| 迭代控制 | `iter-by` / `repeat` / `while` / `until` | until 在 do 前可零次、在 do 后至少一次 |
| 量词 | `always` / `never` / `thereis` | always 失败短路返回 nil 且 **finally 不跑** |
| 累积 | `collect` / `append` / `nconc` / `concat` / `vconcat` / `count` / `sum` / `maximize` / `minimize` | 默认即返回值；同类可汇同一池 |
| 具名 | `into var` / `with var` | into 取消自动返回，必须 finally return；with ≡ 循环外 let |
| 条件 | `if` / `and` / `else` / `end` / `when` / `unless` / `it` | it=条件的那个非 nil 值；end 消歧 else 归属 |
| 生命周期 | `named` / `initially` / `finally` / `return` | return 类退出跳过 finally；finally 里循环变量是终值 |

三条 31.1 实测坑，再强调一遍：`iter-by` 子句由 `generator.el` 注册，不 `(require 'generator)` 直接报错，且 `make-iterator` 不存在；`obarray` 已是独立类型，造 obarray 必须 `obarray-make`，旧写法 `(make-vector 17 nil)` 被 `intern` 拒绝；`always` 失败时走 `return` 路径，`finally` 整个跳过——想「检查失败也要收尾」就别用 `always`。

至此手册第 5 章（Loop Facility 所在的「扩展概览」）全部讲完。从下一章起进入手册的独立章节：第 10 章 Sequences 与第 11 章 Lists——`cl-map`、`cl-reduce`、`cl-remove-duplicates` 这些「函数式序列操作」，以及 `cl-pushnew`、`cl-adjoin`、splice 家族这些「列表构造与就地修改」。它们和第 44 章的 place 体系、第 46 章的遍历子句互为表里。

上一章：[45 · 作用域与控制流：cl-flet、cl-block 与多值](45-scoping-control.md)　｜　下一章：[47 · 序列与列表：cl-map、cl-reduce 与列表构造](47-sequences-lists.md)　｜　返回：[Emacs 扩展开发指南](README.md)
