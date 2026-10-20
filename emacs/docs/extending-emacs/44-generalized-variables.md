# 44 · 广义变量：setf、cl-letf 与就地修改

> 所属部分：第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

> 示例：`examples/44-generalized-variables.el`

`setq` 只能给变量赋值。但 Lisp 里能「存值」的位置远不止变量：列表的 `car`、第 `n` 个元素、向量的某个槽、符号的属性、哈希表的某个键……Common Lisp 把这些可存值的位置统称为**广义变量**（generalized variable，本章简称 place），并用一个宏 `setf` 把「对所有可存值位置的赋值」统一成同一种语法。CL 手册第 5.1 节（Assignment）与第 5.2 节（Generalized Variables）讲的就是这一整套体系：`setf` 本身、内置 place 集合、`cl-lib` 扩展的 place，以及架在 `setf` 之上的一族「修改宏」——`cl-incf`、`cl-pushnew`、`cl-rotatef`、`cl-shiftf`、`cl-letf`、`cl-callf`。

这一章在 Emacs 31.1 上把它们全部实测一遍，顺便澄清手册与 cl-lib 的几处出入——手册里的 `push`/`pop` 在 Emacs 对应的是**原生** `push`/`pop`（`cl-lib` 并不提供 `cl-push`/`cl-pop`），手册里的 `define-setf-expander` 只存在于已废弃的 `cl.el`，31.1 上定义新 place 的正路是 `gv.el` 的 `gv-define-simple-setter`。本章每一条结论都来自示例的真实输出。

示例文件开头声明了两个依赖：

```elisp
(require 'cl-lib)
(require 'gv)
```

`setf` 本身是 Emacs Lisp 内置宏，不需要任何 import；但 `cl-incf`、`cl-psetq`、`cl-letf` 这些修改宏来自 `cl-lib`；`gv`（generalized variables）是现代 Emacs 定义新 place 的机制，第 11 节会用到。

## 44.1 place 是什么：setf 的内置位置

先建立一个直觉：凡是能放在 `setf` 第一个参数位置上的形式，都是一个 place。示例第 1 节一口气对四种不同的 place 赋值——变量之外的 `car`、`nth`、`aref`、`gethash`：

示例第 1 节：

```elisp
(let ((l (list 1 2 3))
      (v (vector 10 20 30))
      (h (make-hash-table :test 'equal)))
  (princ (format "  (setf (car l) 99) 返回新值：%S\n" (setf (car l) 99)))
  (setf (nth 1 l) 77)
  (setf (aref v 0) 111)
  (setf (gethash "k" h) 'vv)
  (princ (format "  l = %S\n" l))
  (princ (format "  v = %S\n" v))
  (princ (format "  (gethash \"k\" h) = %S\n" (gethash "k" h))))
```

运行结果：

```
  (setf (car l) 99) 返回新值：99
  l = (99 77 3)
  v = [111 20 30]
  (gethash "k" h) = vv
```

逐点读：

**四种「存值位置」用同一种语法赋值。** `(setf (car l) 99)` 改的是列表第一个 cons cell 的 car 槽；`(setf (nth 1 l) 77)` 改的是列表中间的元素——`nth` 定位到第二个 cons cell 后写它的 car；`(setf (aref v 0) 111)` 改向量元素；`(setf (gethash "k" h) 'vv)` 往哈希表写一个键值。没有 `setf` 的话，这四件事要分别写 `setcar`、`nthcdr`+`setcar`、`aset`、`puthash`，语法各不相同；`setf` 把它们统一成了「读它的形式，就是写它的形式」。

**`setf` 返回刚写入的新值。** 第一行把 `(setf (car l) 99)` 直接嵌进 `format` 打印，得到 `99`——和 `setq` 一样，`setf` 的返回值就是写入的值。这一点在后面（44.10 节）看展开结果时会更直观：展开式末尾就是那个新值。

**内置 place 远不止这四个。** Emacs 的 `setf` 默认可用的位置包括：变量、`car`/`cdr`/`nth`/`nthcdr`/`caar` 等 car/cdr 组合、`aref`（数组/向量）、`gethash`、`get`（符号属性）、`symbol-value`、`symbol-function`、`default-value` 等等。手册 5.2.1 列的是 Common Lisp 标准集合，Emacs 的实现是它的超集。

## 44.2 cl-lib 额外提供的可 setf 位置

手册 5.2.1「Setf Extensions」列出了 `cl-lib` 在内置之外补充的一批 place：`cl-rest`、`cl-subseq`、`cl-get`、`cl-getf`、`cl-caaar`…`cl-cddddr`、`cl-first`…`cl-tenth`。示例第 2 节把有代表性的几个各测一次，最后还测了一条通用规则——**宏调用也能 setf**。

示例第 2 节：

```elisp
(let ((l (list 1 2 3 4 5)))
  (setf (cl-first l) 100)
  (setf (cl-rest l) (list 7 8))
  (princ (format "  (setf (cl-first l) 100) (setf (cl-rest l) '(7 8)) → %S\n" l)))
(let ((p (list :a 1)))
  (setf (cl-getf p :b) 2)
  (princ (format "  (setf (cl-getf p :b) 2) → %S（新键插到表头）\n" p)))
(setf (cl-get 'ch44-sym 'prop) 7)
(princ (format "  (setf (cl-get 'ch44-sym 'prop) 7) → %S\n"
               (get 'ch44-sym 'prop)))
(let ((v (vector 0 1 2 3)))
  (setf (cl-subseq v 1 3) (list 9 8))
  (princ (format "  (setf (cl-subseq v 1 3) '(9 8)) → %S\n" v)))
(defmacro ch44-2nd (l) `(car (cdr ,l)))
(let ((l (list 1 2 3)))
  (setf (ch44-2nd l) 99)
  (princ (format "  宏调用也是 place：(setf (ch44-2nd l) 99) → %S\n" l)))
```

运行结果：

```
  (setf (cl-first l) 100) (setf (cl-rest l) '(7 8)) → (100 7 8)
  (setf (cl-getf p :b) 2) → (:b 2 :a 1)（新键插到表头）
  (setf (cl-get 'ch44-sym 'prop) 7) → 7
  (setf (cl-subseq v 1 3) '(9 8)) → [0 9 8 3]
  宏调用也是 place：(setf (ch44-2nd l) 99) → (1 99 3)
```

逐点读：

**`cl-first`…`cl-tenth` 与 `cl-rest` 都可 setf。** 前两行把 `(list 1 2 3 4 5)` 的第一个元素改成 `100`、把 `cl-rest`（即 cdr）整体换成 `(7 8)`，得到 `(100 7 8)`——注意这不是「复制后替换」，而是就地改了原列表第一个 cons cell 的 cdr 指针。`cl-second`…`cl-tenth`、`cl-caaar`…`cl-cddddr` 这二十多个访问器全部同样可 setf，规则统一：读起来是什么形式，写回去就是什么形式。

**`cl-getf` 对 plist 赋值，新键插到表头。** `(setf (cl-getf p :b) 2)` 时 `p` 里原本没有 `:b`，于是把 `(:b 2)` 插到最前面，得到 `(:b 2 :a 1)`。这是 plist 的物理限制：中间没有「空槽」可以原地写入，新键只能 prepend。手册还有一条重要约束：**`cl-getf` 的列表参数本身必须是个 place**。`(setf (cl-getf p :b) 2)` 里 `p` 是变量，合法；如果写成 `(setf (cl-getf (some-function) :b) 2)`，`some-function` 的返回值不是 place，`setf` 无法对它做「插入新键」这种可能改变结构的操作，会直接报错。

**`cl-get` 给符号属性赋值。** `(setf (cl-get 'ch44-sym 'prop) 7)` 之后，`(get 'ch44-sym 'prop)` 读回 `7`。符号属性表是 Emacs 里大量全局状态的存放处（比如 `put 'display-buffer 'function-pure`），`setf` + `cl-get` 就是它的标准写法。

**`cl-subseq` 可 setf，但替换序列长度必须匹配。** `(setf (cl-subseq v 1 3) '(9 8))` 把向量 `v` 的下标 1、2 两个位置换成 `9`、`8`，得到 `[0 9 8 3]`。原地修改没有空间伸缩的余地，所以写入序列必须和取出的子序列**等长**，否则报错。

**任何宏调用都是「潜在 place」：`setf` 先展开宏，再对展开结果做 setf。** 这是本节最后一行的重点。`ch44-2nd` 是个自定义宏，展开成 `(car (cdr ,l))`；写 `(setf (ch44-2nd l) 99)` 时，`setf` 先把宏展开成 `(car (cdr l))`——这是个内置 place——然后照常赋值，得到 `(1 99 3)`。也就是说，只要你的宏的展开结果是个 place，这个宏调用就自动可 setf，不需要任何额外声明。这条规则也是 44.11 节自定义 place 的另一种入口（宏版）。

## 44.3 cl-incf 与 cl-decf：就地加/减

`cl-incf`/`cl-decf` 是 `setf` 最常用的两个派生宏，对应手册 5.2.2「Modify Macros」。它们把「读—算—写回」三步压成一步：

示例第 3 节：

```elisp
(let ((n 10))
  (princ (format "  (cl-incf n)   → %S（返回新值）\n" (cl-incf n)))
  (cl-incf n 5)
  (princ (format "  (cl-incf n 5) → n = %S\n" n))
  (cl-decf n 3)
  (princ (format "  (cl-decf n 3) → n = %S\n" n)))
```

运行结果：

```
  (cl-incf n)   → 11（返回新值）
  (cl-incf n 5) → n = 16
  (cl-decf n 3) → n = 13
```

逐点读：

**place 只写一次，不用先读后写。** `(cl-incf n)` 等价于 `(setq n (1+ n))`，但写法上只出现一次 `n`。当 place 是个复杂形式时差距更大：`(cl-incf (aref counters i))` 一行顶过去三行，而且 `counters`、`i` 这些子形式只被求值一次（44.10 节会实测这一点）。

**第二个参数是增量，默认 1。** `(cl-incf n 5)` 加 5，`(cl-decf n 3)` 减 3。不写增量就是 ±1。

**返回新值。** 第一行直接打印 `(cl-incf n)` 得到 `11`——和 `setf` 一样，`incf` 返回写入后的值，可以嵌进表达式用。

## 44.4 push/pop 与 cl-pushnew

手册 5.2.2 把 `push`/`pop` 也列为「修改宏」，但这里有个 Emacs 特有的事实要澄清：

示例第 4 节：

```elisp
(let ((s nil))
  (push 1 s)
  (push 2 s)
  (princ (format "  (push 1 s)(push 2 s) → %S\n" s))
  (princ (format "  (pop s) = %S，剩下 %S\n" (pop s) s)))
(let ((l '(1 2 3)))
  (cl-pushnew 3 l)
  (princ (format "  (cl-pushnew 3 l) 已存在 → %S\n" l))
  (cl-pushnew 4 l)
  (princ (format "  (cl-pushnew 4 l) 不存在 → %S\n" l)))
(let ((l '((:id 1) (:id 2))))
  (cl-pushnew '(:id 1) l :key (lambda (e) (plist-get e :id)) :test '=)
  (princ (format "  :key/:test 比较 → %S\n" l)))
```

运行结果：

```
  (push 1 s)(push 2 s) → (2 1)
  (pop s) = 2，剩下 (1)
  (cl-pushnew 3 l) 已存在 → (1 2 3)
  (cl-pushnew 4 l) 不存在 → (4 1 2 3)
  :key/:test 比较 → ((:id 1) (:id 2))
```

逐点读：

**Emacs 里 `push`/`pop` 就是原生宏，不带 `cl-` 前缀。** 这是本章实测出的第一个「手册与 Emacs 的出入」：`cl-lib` **不提供** `cl-push`/`cl-pop`（它们只存在于早已废弃的 `cl.el` 里，31.1 的 `cl-lib` 中根本没有这两个符号）。Emacs 原生的 `push`/`pop` 本来就是广义变量宏——`(push 1 s)` 展开后就是 `(setq s (cons 1 s))`，`(pop s)` 返回 `car` 并把 `s` 移到 `cdr`。所以手册里的 `push`/`pop` 在 Emacs 直接照用原生版即可。

**`cl-pushnew` 才是 `cl-lib` 新增的：判重后才插入。** 默认用 `eql` 比较：`3` 已在 `(1 2 3)` 里，`(cl-pushnew 3 l)` 什么都不做；`4` 不在，才插到表头变成 `(4 1 2 3)`。它等价于「`(cl-member element sequence :test … :key …)` 找不到，才 `push`」。

**`:key` + `:test` 可以按「提取后的值」判重。** 第三个实验里列表元素是 plist，`:key` 用 `(lambda (e) (plist-get e :id))` 从每个元素里抽出 `:id`，`:test '=` 用数值比较抽出来的值。`'(:id 1)` 的 id 是 1，列表里已有 id 1，所以不插入——输出仍是 `((:id 1) (:id 2))`。这套 `:test`/`:key` 关键字参数是 `cl-lib` 集合类函数的通用约定（`cl-member`、`cl-remove`、`cl-find` 等都用同一套）。

## 44.5 cl-psetq：并行赋值

`setq` 是**串行**赋值：从左到右逐个执行，后面的赋值能看到前面刚写入的新值。`cl-psetq` 是**并行**赋值：先把所有右侧算完，再统一写回。示例第 5 节用同一组初始值跑两遍，差别一目了然：

示例第 5 节：

```elisp
(let ((x 2) (y 3))
  (setq x 2 y 3)
  (setq x (+ x y) y (* x y))
  (princ (format "  (setq x (+ x y) y (* x y)) → x=%S y=%S（串行）\n" x y))
  (setq x 2 y 3)
  (princ (format "  (cl-psetq x (+ x y) y (* x y)) 返回 %S\n"
                 (cl-psetq x (+ x y) y (* x y))))
  (princ (format "  → x=%S y=%S（并行：y 用旧 x 算）\n" x y)))
```

运行结果：

```
  (setq x (+ x y) y (* x y)) → x=5 y=15（串行）
  (cl-psetq x (+ x y) y (* x y)) 返回 nil
  → x=5 y=6（并行：y 用旧 x 算）
```

逐点读：

**串行时 `y` 看到的是「新 `x`」。** 初始 `x=2, y=3`。`setq` 先算 `(+ x y)` 得 5 写入 `x`；接着算 `(* x y)` 时 `x` 已经是 5，于是 `y = 5*3 = 15`。这不是 bug，而是 `setq` 的文档语义——逐个从左到右求值并赋值。

**并行时 `y` 看到的是「旧 `x`」。** `cl-psetq` 先把 `(+ x y)`（=5）和 `(* x y)`（=2*3=6）都用**旧值**算完，再一起写回，所以 `x=5, y=6`。交换两个变量 `(cl-psetq a b b a)` 靠的就是这个语义，不需要临时变量。

**`cl-psetq` 永远返回 `nil`。** 手册 5.1 明确规定 `psetq` 返回 nil，实测第一行打印其返回值正是 `nil`。想要「并行赋值 + 返回新值」，用下一节的 `cl-psetf`。

## 44.6 cl-psetf / cl-rotatef / cl-shiftf：一族就地重排宏

这三个宏把「多个 place 之间搬运值」做成了标准动作。示例第 6 节各测一个：

示例第 6 节：

```elisp
(let ((l (list 1 2)))
  (cl-psetf (car l) (cadr l)
            (cadr l) (car l))
  (princ (format "  (cl-psetf (car l) (cadr l) (cadr l) (car l)) → %S\n" l)))
(let ((a 1) (b 2) (c 3))
  (princ (format "  (cl-rotatef a b c) 返回 %S\n" (cl-rotatef a b c)))
  (princ (format "  → a=%S b=%S c=%S（循环左移）\n" a b c)))
(let ((a 1) (b 2) (c 3))
  (princ (format "  (cl-shiftf a b c 9) 返回 %S（移出值）\n" (cl-shiftf a b c 9)))
  (princ (format "  → a=%S b=%S c=%S（左移补入 9）\n" a b c)))
```

运行结果：

```
  (cl-psetf (car l) (cadr l) (cadr l) (car l)) → (2 1)
  (cl-rotatef a b c) 返回 nil
  → a=2 b=3 c=1（循环左移）
  (cl-shiftf a b c 9) 返回 1（移出值）
  → a=2 b=3 c=9（左移补入 9）
```

逐点读：

**`cl-psetf` 是「setf 版的 psetq」：place 也可以是任意广义变量。** 第一行把 `(car l)` 和 `(cadr l)` 的值互换——两个 place 之间做并行赋值。`psetq` 只能作用于变量，`psetf` 作用于任意 place，这是它们的分工。

**`cl-rotatef` 循环左移，恒返回 `nil`。** `(cl-rotatef a b c)` 执行 `a←b, b←c, c←a`（所有旧值先保存，再统一写入），`1 2 3` 变成 `2 3 1`——每个值向左挪一格，最左的绕回最右。手册 5.2.2 明确规定 `rotatef` 返回 nil，实测一致。

**`cl-shiftf` 左移但「不循环」：末尾补入任意表达式，返回被移出的第一个旧值。** `(cl-shiftf a b c 9)` 执行 `a←b, b←c, c←9`，得到 `2 3 9`；`a` 的旧值 `1` 被「挤出去」，成为整个形式的返回值。这个「返回移出值」的设计让 `shiftf` 天然适合做环形缓冲：`(cl-shiftf slot0 slot1 slot2 new-item)` 返回的就是即将被覆盖的旧数据。

**记忆口诀：`rotatef` 转圈丢返回值，`shiftf` 漏底留返回值。** 两者都是「先全部读旧值，再全部写」，所以 place 之间可以任意重叠，不会互相污染。

## 44.7 cl-callf 与 cl-callf2：把任意函数变成就地修改器

手册 5.2.2 给了两个「函数套壳」宏：`(cl-callf f place args…)` 等价于 `(setf place (f place args…))`——把 `place` 的旧值塞进函数第一个参数位，结果写回原处；`(cl-callf2 f arg1 place args…)` 则把 `place` 放到**第二个**实参位。示例第 7 节：

示例第 7 节：

```elisp
(let ((n -5))
  (cl-callf abs n)
  (princ (format "  (cl-callf abs n) → %S\n" n))
  (cl-callf + n 7)
  (princ (format "  (cl-callf + n 7) → %S\n" n)))
(let ((l '(2 3)))
  (cl-callf2 cons 1 l)
  (princ (format "  (cl-callf2 cons 1 l) → %S\n" l)))
```

运行结果：

```
  (cl-callf abs n) → 5
  (cl-callf + n 7) → 12
  (cl-callf2 cons 1 l) → (1 2 3)
```

逐点读：

**`cl-callf`：place 在第一个实参位。** `(cl-callf abs n)` 就是 `(setf n (abs n))`，`-5` 变 `5`；`(cl-callf + n 7)` 就是 `(setf n (+ n 7))`，`5` 变 `12`。任何「输入旧值、输出新值」的函数——`abs`、`+`、`upcase`、`sort`——都可以直接当就地修改器用，place 写一次就够了。

**`cl-callf2`：place 挪到第二个实参位。** 为什么需要第二个变体？因为很多函数「主数据」不在第一个参数位：`cons` 的第一个参数是要插入的元素，列表才是第二个。`(cl-callf2 cons 1 l)` 等价于 `(setf l (cons 1 l))`，也就是 `(push 1 l)`。手册特别指出：`(push x place)` 与 `(cl-callf2 cons x place)` 等价——`cl-callf2` 就是 `push` 的泛化形态。

**返回值同 `setf`。** 两者都展开成 `setf` 调用，所以返回写入的新值（本节没打印，但 44.10 节会直接看 `setf` 的展开式来印证机制）。

## 44.8 cl-letf：给任意 place 临时赋值

`let` 能给变量做临时绑定，`cl-letf` 把这件事推广到**任意 place**：进入时保存旧值、写入新值，离开时（无论正常退出还是报错）恢复。这是手册 5.2.2 里最重要的宏，也是 Emacs 测试基础设施的基石。示例第 8 节五连测：

示例第 8 节：

```elisp
(let ((l (list 1 2 3)))
  (princ (format "  (cl-letf (((car l) 'tmp)) …) 内 %S 外 %S\n"
                 (cl-letf (((car l) 'tmp)) (copy-sequence l)) l)))
(princ (format "  (cl-letf ((ch44-g8 1)) …) 内 %S 外 %S\n"
               (cl-letf ((ch44-g8 1)) ch44-g8) ch44-g8))
(let ((l (list 1 2)))
  (condition-case nil
      (cl-letf (((car l) 9)) (error "boom"))
    (error nil))
  (princ (format "  体内报错后 place 仍被恢复：%S\n" l)))
(let ((l (list 1 2 3)))
  (princ (format "  cl-letf* 串行绑定 → %S\n"
                 (cl-letf* (((car l) 5) ((cadr l) (car l))) (copy-sequence l)))))
(cl-letf (((symbol-value 'ch44-g8))) (setq ch44-g8 2))
(princ (format "  单元素绑定 ((place)) 只负责事后恢复：g8 = %S\n" ch44-g8))
```

运行结果：

```
  (cl-letf (((car l) 'tmp)) …) 内 (tmp 2 3) 外 (1 2 3)
  (cl-letf ((ch44-g8 1)) …) 内 1 外 100
  体内报错后 place 仍被恢复：(1 2)
  cl-letf* 串行绑定 → (5 5 3)
  单元素绑定 ((place)) 只负责事后恢复：g8 = 100
```

逐点读：

**绑定形式是「place 当左值」。** `(cl-letf (((car l) 'tmp)) …)` 里，绑定项 `((car l) 'tmp)` 读作「把 `(car l)` 这个 place 临时设为 `tmp`」。体内 `l` 是 `(tmp 2 3)`，出了 `cl-letf` 恢复成 `(1 2 3)`——注意恢复的是**原来那个列表对象本身**，不是副本：`setf` 写回旧值 `1` 是就地改 cons cell。

**普通变量也可以走 `cl-letf`。** 第二行 `(cl-letf ((ch44-g8 1)) …)` 体内 `1`、体外 `100`，效果同 `let`。区别在于 `let` 建立的是新的局部绑定，而 `cl-letf` 是「保存旧值—写入—事后恢复」，对全局变量 `ch44-g8` 动手动脚，临时借用一下再还回去。

**体内报错，place 照样恢复。** 第三实验在 `cl-letf` 体内直接 `(error "boom")`，外面用 `condition-case` 接住。结果 `l` 仍是 `(1 2)`——`(car l)` 被临时写成 `9` 后又被还原。`cl-letf` 的恢复包在 `unwind-protect` 里，异常、`throw`、正常返回都拦不住它还原。

**`cl-letf*` 是串行版：后一个绑定能看到前一个的效果。** `(cl-letf* (((car l) 5) ((cadr l) (car l))) …)` 先把 `car` 改成 5，再把 `cadr` 改成「当前的 `car`」——也就是刚写入的 5，体内 `(5 5 3)`。对照 `cl-letf`（不带星号）：手册规定各绑定项的**值形式按书写顺序求值**，但**写入各 place 的顺序是未定义的**，所以不带星号时**不要对同一个 place 写两次**，也不要指望后一项能看到前一项的效果；要串行语义，用 `cl-letf*`。

**单元素绑定 `((place))`  ≡ `((place place))`：只负责「事后恢复」。** 最后一行 `(cl-letf (((symbol-value 'ch44-g8))) (setq ch44-g8 2))` 的绑定项只有一个元素——手册规定这等价于「用 place 的当前值绑定 place」，即进入时什么都不改，只登记旧值；体内放心 `setq` 成 2，离开时自动恢复成 100。这是「临时改一个变量、保证还原」的标准写法，比手写 `unwind-protect` 干净得多。

**一个真实的陷阱：体内返回值如果是 place 本身，你看到的是恢复后的值。** 本节实验的体内一律写成 `(copy-sequence l)` 而不是直接返回 `l`。原因：`cl-letf` 恢复 place 发生在体内表达式求值**之后、结果被外部使用之前**——如果体内直接返回 `l`（返回的是那个 cons cell 对象本身），等外面打印它时，`(car l)` 早已被还原成 `1`，你看到的「体内值」其实是体外值，实验就废了。`copy-sequence` 在体内把当前状态拍成快照，返回的是快照对象，不受事后恢复影响。理解这个时序，是用好 `cl-letf` 做实验/测试的分水岭。

## 44.9 cl-letf 给函数定义打补丁

`cl-letf` 最出场的用法来自 44.8 的机制推广：`(symbol-function 'f)` 也是一个 place（44.1 节内置列表里就有它），所以可以临时替换函数定义。示例第 9 节：

示例第 9 节：

```elisp
(defun ch44-greet () "orig")
(princ (format "  (cl-letf (((symbol-function 'ch44-greet) (lambda () \"patched\"))) (ch44-greet)) → %S\n"
               (cl-letf (((symbol-function 'ch44-greet) (lambda () "patched")))
                 (ch44-greet))))
(princ (format "  出了 letf 体 → %S\n" (ch44-greet)))
```

运行结果：

```
  (cl-letf (((symbol-function 'ch44-greet) (lambda () "patched"))) (ch44-greet)) → "patched"
  出了 letf 体 → "orig"
```

逐点读：

**打桩/mock 的标准写法。** `cl-letf` 把 `ch44-greet` 的函数定义临时换成 `(lambda () "patched")`，体内调用得到 `"patched"`；出了体，原定义 `"orig"` 自动还原，不留任何全局污染。Emacs 的测试框架（`ert` 生态）和大量「临时改写行为」的代码就是这么写的——比 `fset` + 手动还原安全，因为还原包在 `unwind-protect` 里（44.8 节已实测：报错也恢复）。

**为什么这对 `cl-letf` 成立、对 `let` 不成立。** `let` 绑定的是变量（符号的 value 槽），而函数定义存在符号的 function 槽；`cl-letf` 不关心 place 背后是哪个槽，它只要求「这个形式能 setf」。`symbol-function` 能 setf，所以能被 letf。这正是 place 抽象的威力：一旦某个「可存值位置」被纳入 setf 体系，所有建立在 setf 之上的宏（`cl-letf`、`cl-callf`、`cl-incf`……）自动对它生效。

## 44.10 setf 保证子形式只求值一次

place 形式里可能嵌套着**有副作用的子形式**（比如函数调用）。`setf` 有一条硬性保证：place 的每个子形式**恰好求值一次**，顺序为它们在 place 形式中出现的顺序。示例第 10 节用一个自带计数器的探针函数验证，并直接打印展开式看机制：

示例第 10 节：

```elisp
(defun ch44-vec () (setq ch44-cnt (1+ ch44-cnt)) (vector 0 0 0))
(let ((ch44-cnt 0))
  (setf (aref (ch44-vec) 0) 1)
  (princ (format "  (setf (aref (ch44-vec) 0) 1)：ch44-vec 求值 %S 次\n" ch44-cnt)))
(let ((ch44-cnt 0))
  (cl-incf (aref (ch44-vec) 0))
  (princ (format "  (cl-incf (aref (ch44-vec) 0))：ch44-vec 求值 %S 次\n" ch44-cnt)))
(princ (format "  (macroexpand '(setf (car l) 1)) → %S\n"
               (macroexpand '(setf (car l) 1))))
```

运行结果：

```
  (setf (aref (ch44-vec) 0) 1)：ch44-vec 求值 1 次
  (cl-incf (aref (ch44-vec) 0))：ch44-vec 求值 1 次
  (macroexpand '(setf (car l) 1)) → (let* ((v l)) (setcar v 1))
```

逐点读：

**「读旧值 + 写新值」的宏只碰子形式一次。** `setf` 本身要写、`cl-incf` 更要先读后写，直觉上 `(ch44-vec)` 可能被调用两次——实测都是 **1 次**。`ch44-vec` 每被调用一次就把计数器加一，计数器就是铁证。

**展开式揭示了机制：临时变量接管子形式。** `(macroexpand '(setf (car l) 1))` 得到 `(let* ((v l)) (setcar v 1))`——`setf` 把 place 的子形式 `l` 先绑给临时变量 `v`（求值恰好一次），后续读写都只针对 `v`。`cl-incf` 的展开同理，只是多了「读 `(aref v 0)`、加一、写回」的步骤，`ch44-vec` 依然只跑一次。

**这条保证为什么重要。** 第一，副作用正确性：如果 `(ch44-vec)` 跑两遍，不仅慢，还会返回**两个不同的向量**，写进 A 向量、读自 B 向量，语义直接错乱。第二，性能：place 越复杂（`(gethash key (lookup-table name))`），保证只求值一次省下的开销越大。写自己的 place 时也要遵守这条保证——这正是下一节 `gv-define-simple-setter` 展开式里临时变量 `v` 的作用。

## 44.11 自定义 place：gv-define-simple-setter

手册 5.2.1 教的是 Common Lisp 标准的 `define-setf-expander`。实测 Emacs 31.1 发现一个必须澄清的事实：**`define-setf-expander` 只存在于已废弃的 `cl.el`，`cl-lib` 并不提供它**。现代 Emacs 定义新 place 的正路是 `gv.el`，其中最简单的入口是 `gv-define-simple-setter`：给它一个「读函数」和一个「写函数」，读函数调用形式就自动变成 place。示例第 11 节：

示例第 11 节：

```elisp
(defun ch44-elt (key) (gethash key ch44-store))
(defun ch44-put (key val) (puthash key val ch44-store) val)
(gv-define-simple-setter ch44-elt ch44-put t)
(defun ch44-bump () (setq ch44-key-cnt (1+ ch44-key-cnt)) "a")
(let ((ch44-key-cnt 0))
  (princ (format "  (macroexpand-1 '(setf (ch44-elt (ch44-bump)) 5)) → %S\n"
                 (macroexpand-1 '(setf (ch44-elt (ch44-bump)) 5))))
  (setf (ch44-elt (ch44-bump)) 5)
  (princ (format "  实参 key 求值 %S 次；(ch44-elt \"a\") 读回 %S\n"
                 ch44-key-cnt (ch44-elt "a"))))
```

运行结果：

```
  (macroexpand-1 '(setf (ch44-elt (ch44-bump)) 5)) → (let* ((v (ch44-bump))) (progn (ch44-put v 5) 5))
  实参 key 求值 1 次；(ch44-elt "a") 读回 5
```

逐点读：

**三行定义一个 place。** `ch44-elt` 是读函数（按 key 从全局哈希表 `ch44-store` 取值）；`ch44-put` 是写函数（写入哈希表并**返回写入的值**）；`(gv-define-simple-setter ch44-elt ch44-put t)` 把两者挂钩。第三个参数 `t` 向 `gv` 声明「写函数返回它写入的值」——这个声明让 `setf` 能直接把写函数的返回值当作自己的返回值，展开式因此可以干净地写成 `(progn (ch44-put v 5) 5)`。

**展开式再次印证 44.10 的机制。** `(macroexpand-1 ...)` 显示：实参 `(ch44-bump)` 先被绑进临时变量 `v`（只求值一次），然后 `(ch44-put v 5)` 完成写入，整个 `setf` 返回 `5`。实测计数器 `ch44-key-cnt` 最终为 `1`——`ch44-bump` 这个有副作用的实参确实只跑了一次。

**定义完立刻享受整套修改宏。** 一旦 `(ch44-elt key)` 成为 place，`(cl-incf (ch44-elt "a"))`、`(cl-letf (((ch44-elt "a")) 0) …)`、`(cl-callf abs (ch44-elt "a"))` 全都自动可用——这就是 place 抽象的复利。

**和手册的对应关系。** CL 手册的 `define-setf-expander` 让你手工编写「访问环境、临时变量、存储形式」五件套，功能最强但写法繁琐；`gv.el` 把它简化成了两条路：简单的用 `gv-define-simple-setter`（本节），复杂一点的（多个子形式要分别保存、写入需要多步）用 `gv-define-setter` 或宏形式的 `gv-define-place`。在 Emacs 上写新 place，认准 `gv` 前缀即可，不必碰废弃的 `cl.el`。

## 44.12 小结

本章把 CL 手册 5.1/5.2 的「赋值与广义变量」在 Emacs 31.1 上全部实测，核心结论汇总：

| 宏 | 作用 | 返回值（实测） |
|---|---|---|
| `setf` | 对任意 place 赋值 | 新值 |
| `cl-incf` / `cl-decf` | place 就地加/减（默认步长 1） | 新值 |
| `push` / `pop` | 原生宏，cons cell 进出表头 | `push` 返回新列表；`pop` 返回弹出元素 |
| `cl-pushnew` | 判重（`:test`/`:key`）后才 push | 新列表 |
| `cl-psetq` | 变量间并行赋值 | 恒 `nil` |
| `cl-psetf` | 任意 place 间并行赋值 | —— |
| `cl-rotatef` | place 循环左移 | 恒 `nil` |
| `cl-shiftf` | place 左移、末尾补入表达式 | 被移出的第一个旧值 |
| `cl-callf` / `cl-callf2` | 把函数 `(f place …)` / `(f a1 place …)` 变就地修改 | 新值（展开为 setf） |
| `cl-letf` / `cl-letf*` | place 临时赋值，退出（含报错）恢复 | 体内值 |
| `gv-define-simple-setter` | 读函数 + 写函数 + `t` 定义新 place | —— |

三条「手册 vs Emacs 31.1」的实测出入必须记住：`cl-lib` 没有 `cl-push`/`cl-pop`（用原生）；`define-setf-expander` 只在废弃的 `cl.el`（正路是 `gv.el`）；`cl-letf` 体内若返回 place 本身，外面看到的是恢复后的旧值（体内要拍快照）。再加一条使用纪律：`cl-letf` 各绑定项的值形式按序求值，但写入顺序未定义，同一 place 不要绑两次。

place 解决了「值可以存进哪里」以及「怎么统一地存取」。下一站回到函数与控制流本身：`cl-flet` 与 `cl-labels` 的局部函数绑定、`cl-block`/`cl-return-from` 的具名退出、`cl-case` 的符号分派、`cl-multiple-value-bind` 的多值接收——手册 5.3 到 5.8 的内容，第 45 章见。

上一章：[43 · 写宏的工具：cl-eval-when、cl-once-only 与 compiler macro](43-macro-tools.md)　｜　下一章：[45 · 作用域与控制流：cl-flet、cl-block 与多值](45-scoping-control.md)　｜　返回：[Emacs 扩展开发指南](README.md)
