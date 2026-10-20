# 47 · 序列与列表：cl-map、cl-reduce 与列表构造

> 所属部分：第 11 部分 · 跟随 CL 手册：Common Lisp 扩展

> 示例：`examples/47-sequences-lists.el`

CL 手册第 10 章（Sequences）把列表、字符串、向量统称为**序列**，给出一整套带关键字参数的操作；第 11 章（Lists）专攻 cons cell 链：访问、树替换、集合运算、关联列表。两章合起来是 CL「函数式数据处理」的主力工具箱，本章把手册两章里讲到的每个函数在 Emacs 31.1 上实测一遍。

开工前先亮三个**实测才看得清**的事实：其一，`cl-member` 默认用 `eql` 比较，而原生 `member` 用 `equal`——字符串成员判断是两者的经典差异，`cl-member` 找字符串必须显式 `:test #'equal`，字节编译器看到对字面量字符串做 `memql` 还会直接警告 "called with literal string that may never match"；其二，「复制版 vs 破坏版」的分界在字符串/向量上会**退化**——不可伸缩的序列上 `cl-delete` 等破坏版只能返回拷贝，原序列不动；其三，31.1 的底层 `sort` 本来就是稳定排序，`cl-stable-sort` 实测与 `cl-sort` 等价（手册特意保留「将来换实现」的权利，言下之意别依赖这个巧合）。每条都在下文附真实输出。

## 47.1 统一关键字：`:test` / `:key` / `:count` / `:start` / `:end` / `:from-end`

手册 10.1（Sequence Basics）最重要的内容不是某个函数，而是一套**横切所有序列函数的关键字约定**。示例第 1 节用 `cl-remove`/`cl-find` 把它们一次演示完：

示例第 1 节：

```elisp
(princ (format "  cl-remove 0 :test '= ≡ cl-remove-if 'zerop → %S / %S\n"
               (cl-remove 0 '(0 1 0 2) :test #'=)
               (cl-remove-if #'zerop '(0 1 0 2))))
(princ (format "  :key 过滤视角（find 2 :key car ≡ cl-assoc 的思路）→ %S\n"
               (cl-find 2 '((1 . a) (2 . b)) :key #'car)))
(princ (format "  :count 2 只删左边两个 → %S\n"
               (cl-remove 1 '(1 2 1 3 1) :count 2)))
(princ (format "  :count 1 :from-end t 改删右边 → %S\n"
               (cl-remove 1 '(1 2 1 3 1) :count 1 :from-end t)))
(princ (format "  :start 2 :end 4 只看窗口内 → %S\n"
               (cl-remove 1 '(1 2 1 3 1) :start 2 :end 4)))
```

运行结果：

```
  cl-remove 0 :test '= ≡ cl-remove-if 'zerop → (1 2) / (1 2)
  :key 过滤视角（find 2 :key car ≡ cl-assoc 的思路）→ (2 . b)
  :count 2 只删左边两个 → (2 3 1)
  :count 1 :from-end t 改删右边 → (1 2 1 3)
  :start 2 :end 4 只看窗口内 → (1 2 3 1)
  手册约定：:test 默认 eql；:key 是「看元素的滤镜」；
  :start 含、:end 不含；-if/-if-not 变体用谓词代替 item。
```

逐点读：

**`:test` 决定「什么算相等」，默认 `eql`。** 第一行 `(cl-remove 0 '(0 1 0 2) :test #'=)` 与 `(cl-remove-if #'zerop '(0 1 0 2))` 结果同为 `(1 2)`——前者用「item 与元素满足 `:test` 谓词」判等，后者直接给谓词。手册规定每个接受 item 的序列函数都有对应的 `-if`/`-if-not` 变体，变体用一元谓词代替 item 参数，且**不再接受 `:test`**（谓词本身就表达了判定）。

**`:key` 是「看元素的滤镜」。** 第二行 `(cl-find 2 '((1 . a) (2 . b)) :key #'car)`：比较时先把每个元素过一遍 `car`，再与 2 比——命中 `(2 . b)` 这个**元素本身**（不是 `car` 的结果）。这正是 `cl-assoc` 的工作思路；区别是 `cl-assoc` 返回整个 cons，而 `:key` 写法对任意序列通用。`:key` 也作用于 item 之外的所有参与比较的值，比如 `:test` 的两边都会先过 `:key`。

**`:count` 限制操作次数，`:from-end` 换方向。** 第三行 `:count 2` 从左删起，删掉前两个 1，得 `(2 3 1)`；第四行加 `:from-end t` 从右删一个，得 `(1 2 1 3)`。注意 `:from-end` 只改变**处理顺序**，结果的元素顺序依然是原序列的顺序——它影响的是「哪些被选中」，不是「结果怎么排」。

**`:start`/`:end` 划定操作窗口：`:start` 含、`:end` 不含。** 第五行 `:start 2 :end 4` 只考察下标 2、3 两个位置（即 `(1 3)` 这段），窗口内的 1（下标 2）被删，得 `(1 2 3 1)`；窗口外的两个 1（下标 0、4）原样保留。窗口外的元素**绝不参与**任何操作——这是 `:start`/`:end` 与 `:count` 的本质区别：前者划地盘，后者数次数。

## 47.2 Mapping 家族：`cl-mapcar` / `cl-map` / `cl-maplist` / `cl-mapc` / `cl-mapcan`

手册 10.2（Mapping over Sequences）一口气给了五个映射函数。示例第 2 节：

示例第 2 节：

```elisp
(princ (format "  cl-mapcar 双序列并行、最短即停 → %S\n"
               (cl-mapcar #'+ '(1 2 3) '(10 20))))
(princ (format "  cl-map 'vector 换返回类型 → %S\n"
               (cl-map 'vector #'+ '(1 2 3) '(10 20 30))))
(princ (format "  cl-map 'string（元素是字符码）→ %S\n"
               (cl-map 'string #'1+ "abc")))
(princ (format "  cl-map nil 丢弃结果 → %S\n"
               (cl-map nil #'ignore '(1 2))))
(princ (format "  cl-maplist 每次拿到的是 CDR 链 → %S\n"
               (cl-maplist #'identity '(1 2 3))))
(princ (format "  cl-mapc 丢弃函数值、返回第一个序列 → %S\n"
               (cl-mapc #'ignore '(1 2))))
(princ (format "  cl-mapcan 把各轮列表 nconc 起来 → %S\n"
               (cl-mapcan (lambda (x) (list x (* x 10))) '(1 2))))
```

运行结果：

```
  cl-mapcar 双序列并行、最短即停 → (11 22)
  cl-map 'vector 换返回类型 → [11 22 33]
  cl-map 'string（元素是字符码）→ "bcd"
  cl-map nil 丢弃结果 → nil
  cl-maplist 每次拿到的是 CDR 链 → ((1 2 3) (2 3) (3))
  cl-mapc 丢弃函数值、返回第一个序列 → (1 2)
  cl-mapcan 把各轮列表 nconc 起来 → (1 10 2 20)
  cl-mapcar 是 CL mapcar 与原生 mapcar 的兼容超集：
  多序列、可混类型；cl-maplist 走 cons cell 本身（≡ loop 的 for on）。
```

逐点读：

**`cl-mapcar` 是原生 `mapcar` 与 CL `mapcar` 的兼容超集。** 原生 `mapcar` 只接受一个序列；`cl-mapcar` 接受任意多个，函数按「每序列一个实参」调用，**最短序列走完即停**——第一行 `(1 2 3)` 与 `(10 20)` 并行，只走了两轮，得 `(11 22)`。多序列参数还可以混类型（列表、向量、字符串任意组合），这是原生版做不到的。

**`cl-map` 的第一个参数指定返回类型。** `'vector` 返回向量（第二行 `[11 22 33]`），`'string` 返回字符串（第三行把字符码各加一，`"abc"` 变 `"bcd"`），`'list` 返回列表，而 `nil` 表示**只要副作用、丢弃结果**（第四行返回 `nil`）。`cl-map` 同样支持多序列并行。

**`cl-maplist` 走 cons cell 本身，不是元素。** 第五行 `(cl-maplist #'identity '(1 2 3))` 返回 `((1 2 3) (2 3) (3))`——函数每轮拿到的是**当前 CDR 链**，等价于第 46 章 Loop 的 `for on` 子句。想在遍历中「往前看」后续元素，用它最直接。

**`cl-mapc` 与 `cl-mapcan` 是两种「攒结果」的极端。** `cl-mapc` 完全丢弃函数值、把**第一个序列原样返回**（第六行 `(1 2)`），纯为副作用而存在；`cl-mapcan` 则要求函数每轮返回一个列表，把各轮列表用 `nconc` 串成最终结果（第七行 `(1 10 2 20)`）——注意是 `nconc` 不是 `append`，函数返回的列表会被**就地拼接**，别在后面继续引用它们。

## 47.3 量词：`cl-some` / `cl-every` / `cl-notany` / `cl-notevery`

四个量词回答「序列里是否存在/是否全部满足谓词」。示例第 3 节：

示例第 3 节：

```elisp
(princ (format "  cl-some 返回第一个非 nil 值（不是 t）→ %S\n"
               (cl-some (lambda (x) (and (> x 2) x)) '(1 2 3 4))))
(princ (format "  cl-every 全真才 t → %S / %S\n"
               (cl-every #'cl-plusp '(1 2 3))
               (cl-every #'cl-plusp '(1 -2 3))))
(princ (format "  cl-notany（全假才 t）→ %S\n"
               (cl-notany #'cl-minusp '(1 2 3))))
(princ (format "  cl-notevery（有假即非 nil）→ %S\n"
               (cl-notevery #'cl-plusp '(1 -2 3))))
```

运行结果：

```
  cl-some 返回第一个非 nil 值（不是 t）→ 3
  cl-every 全真才 t → t / nil
  cl-notany（全假才 t）→ t
  cl-notevery（有假即非 nil）→ t
  手册保证：some/every 按从左到右顺序调用，且命中即停——
  谓词里放副作用是安全的（别的序列函数不做此保证）。
```

逐点读：

**`cl-some` 返回的是谓词产生的第一个非 nil 值，不是 `t`。** 第一行谓词 `(lambda (x) (and (> x 2) x))` 对 3 求值得 3，`cl-some` 就返回 3——利用这一点可以「查找并取值」一步到位。全不满足时返回 `nil`。

**`cl-every`/`cl-notany`/`cl-notevery` 是同一件事的四种问法。** `cl-every` 全真才真（第二行 `(1 2 3)` 全真得 `t`，`(1 -2 3)` 得 `nil`）；`cl-notany` 全假才真（第三行没有负数，得 `t`）；`cl-notevery` 有假即真（第四行得 `t`）。四者满足德摩根关系：`(cl-notany p s)` ≡ `(not (cl-some p s))`，`(cl-notevery p s)` ≡ `(not (cl-every p s))`。

**手册独给量词一份顺序保证。** 示例末尾两行注释照录手册原意：`cl-some`/`cl-every` 保证**从左到右**依次调用谓词，且一旦结果确定立即停（`cl-some` 命中即停、`cl-every` 遇假即停）——所以谓词里放副作用（计数、打印、提前写文件）是安全的。手册特意声明其它序列函数**不做**这个保证：别想当然地认为 `cl-remove-if` 的谓词调用顺序可依赖。

## 47.4 `cl-reduce`：左右结合、`:initial-value` 与空序列

`cl-reduce` 把二元函数折叠到整个序列上，是映射家族之外最重要的累积函数。示例第 4 节：

示例第 4 节：

```elisp
(princ (format "  左结合：(- (- (- 1 2) 3) 4) → %S\n"
               (cl-reduce #'- '(1 2 3 4))))
(princ (format "  :from-end t 右结合：(- 1 (- 2 (- 3 4))) → %S\n"
               (cl-reduce #'- '(1 2 3 4) :from-end t)))
(princ (format "  :initial-value 100 加在最前 → %S\n"
               (cl-reduce #'- '(1 2) :initial-value 100)))
(princ (format "  单元素不调用函数直接返回 → %S\n"
               (cl-reduce #'- '(5))))
(princ (format "  空序列调用函数零次取单位元：(+) → %S\n"
               (cl-reduce #'+ '())))
```

运行结果：

```
  左结合：(- (- (- 1 2) 3) 4) → -8
  :from-end t 右结合：(- 1 (- 2 (- 3 4))) → -2
  :initial-value 100 加在最前 → 97
  单元素不调用函数直接返回 → 5
  空序列调用函数零次取单位元：(+) → 0
  手册原话：cl-loop 都能写出这些映射，编译后 cl-loop
  更快（内联、无函数调用）；cl-reduce 胜在读起来是函数式。
```

逐点读：

**默认左结合，`:from-end t` 右结合。** 减法不结合，恰好用来暴露方向：`(cl-reduce #'- '(1 2 3 4))` 算的是 `(- (- (- 1 2) 3) 4)` 得 -8；加 `:from-end t` 算 `(- 1 (- 2 (- 3 4)))` 得 -2。对 `+`、`max` 这类可结合函数两者等价，对构造类函数（如 `cons`）方向直接决定结果形状。

**`:initial-value` 在序列的开头（`:from-end` 时在末尾）先垫一个值。** 第三行 `(cl-reduce #'- '(1 2) :initial-value 100)` 算 `(- (- 100 1) 2)` 得 97。注意它和「序列多一个元素」语义相同，但**不修改原序列**。

**两种边界情形都不报错。** 单元素序列**不调用函数**直接返回该元素（第四行得 5）；空序列则调用函数**零次**取单位元——`(+)` 是 0，所以第五行得 0。若函数没有零元形式（比如 `-` 在 Emacs Lisp 里 `(-)` 会报错），空序列就会把这个错误抛出来；想避免就给 `:initial-value`。

**什么时候用 `cl-reduce`、什么时候用 `cl-loop`？** 示例末尾照录手册 10.2 的原话：这些映射操作 `cl-loop` 全能写，而且编译后的 `cl-loop` 更快（内联展开、无函数调用开销）；`cl-reduce` 们的价值在于**读起来是函数式**——意图一眼可见。追求性能的热路径用 Loop，追求表达力的地方用序列函数。

## 47.5 截取、拼接、填充、替换：`cl-subseq` / `cl-concatenate` / `cl-fill` / `cl-replace`

手册 10.3（Sequence Functions）的前四个函数管「序列的段与段之间的事」。示例第 5 节：

示例第 5 节：

```elisp
(let ((src (list 1 2 3 4)))
  (princ (format "  cl-subseq 拷贝（改结果不动原序列）→ %S，原序列 %S\n"
                 (let ((s (cl-subseq src 1 3))) (setcar s 99) s) src)))
(princ (format "  负索引（Emacs 扩展）：(cl-subseq '(1 2 3 4) -2) → %S\n"
               (cl-subseq '(1 2 3 4) -2)))
(let ((v (vector 1 2 3 4 5)))
  (setf (cl-subseq v 1 3) '(9 9))
  (princ (format "  setf cl-subseq 就地替换一段 → %S\n" v)))
(princ (format "  cl-concatenate 混类型拼成 string → %S\n"
               (cl-concatenate 'string '(?a ?b) "cd")))
(let ((v (vector 1 2 3 4)))
  (princ (format "  cl-fill 填窗口 [1,3) → %S\n"
                 (cl-fill v 0 :start 1 :end 3))))
(let ((l (list 1 2 3 4)))
  (princ (format "  cl-replace 返回 seq1 本体 → %S，l 已变 %S\n"
                 (cl-replace l '(9 8) :start1 1) l)))
```

运行结果：

```
  cl-subseq 拷贝（改结果不动原序列）→ (99 3)，原序列 (1 2 3 4)
  负索引（Emacs 扩展）：(cl-subseq '(1 2 3 4) -2) → (3 4)
  setf cl-subseq 就地替换一段 → [1 9 9 4 5]
  cl-concatenate 混类型拼成 string → "abcd"
  cl-fill 填窗口 [1,3) → [1 0 0 4]
  cl-replace 返回 seq1 本体 → (1 9 8 4)，l 已变 (1 9 8 4)
  cl-subseq 是唯一允许负 start/end 的序列函数；setf 它的
  效果等同 cl-replace。cl-fill/cl-replace 都是就地修改。
```

逐点读：

**`cl-subseq` 永远是拷贝。** 第一行截出 `(2 3)` 后把拷 `--` 贝的 `car` 改成 99，原序列纹丝不动——`(99 3)` 对 `(1 2 3 4)`。需要共享结构的「视图」请用 `nthcdr`/`cl-ldiff`（见 47.9），`cl-subseq` 只给独立副本。

**负索引是 Emacs 对 CL 的扩展。** 第二行 `(cl-subseq '(1 2 3 4) -2)` 得 `(3 4)`：负的 start/end 从尾部倒数。手册特别声明：**其它序列函数的 `:start`/`:end` 不接受负数**，这是 `cl-subseq` 独享的便利。

**`cl-subseq` 是一个 place，`setf` 它等于就地替换一段。** 第三行 `(setf (cl-subseq v 1 3) '(9 9))` 把向量下标 1、2 两位换成 9、9，得 `[1 9 9 4 5]`——效果等同 `(cl-replace v '(9 9) :start1 1)`（见第 44 章的 place 体系）。

**`cl-concatenate` 指定返回类型，可以混类型拼接。** 第四行把字符列表 `(?a ?b)` 与字符串 `"cd"` 拼成 `"abcd"`。参数里每个序列各自是什么类型无所谓，结果类型由第一个实参决定。

**`cl-fill` 与 `cl-replace` 都是就地修改，且都认窗口。** 第五行 `cl-fill` 把向量 `[1,3)` 窗口填成 0，得 `[1 0 0 4]`；第六行 `cl-replace` 把 `(9 8)` 写进 `l` 从下标 1 起的位置，返回的是 **seq1 本体**（已变 `(1 9 8 4)`），调用方 `l` 指向同一个被改过的列表。`cl-replace` 的关键字是 `:start1`/`:end1`/`:start2`/`:end2` 两对，因为它同时管两个序列的窗口。

## 47.6 复制版 vs 破坏版：`cl-remove` / `cl-delete` / `cl-remove-duplicates` / `cl-nsubstitute`

序列函数里最要紧的一对概念：**名字不带前缀的是复制版**（返回新序列、原序列不动），**`delete` 前缀或 `n` 前缀的是破坏版**（允许就地改原序列）。示例第 6 节：

示例第 6 节：

```elisp
(let ((orig (list 1 2 1 3)))
  (princ (format "  cl-remove 不动原列表：结果 %S，原列表 %S\n"
                 (cl-remove 1 orig) orig)))
(let ((l (list 0 1 2 1 3)))
  (princ (format "  cl-delete 就地剪接：结果 %S，l 变成 %S\n"
                 (cl-delete 1 l) l)))
(let ((v (vector 1 2 1 3)))
  (princ (format "  向量上 cl-delete ≡ cl-remove（不可伸缩）：%S，原向量 %S\n"
                 (cl-delete 1 v) v)))
(princ (format "  cl-remove-duplicates 保留最右 → %S\n"
               (cl-remove-duplicates '(1 2 1 3 2))))
(princ (format "  :from-end t 改留最左 → %S\n"
               (cl-remove-duplicates '(1 2 1 3 2) :from-end t)))
(let ((l (list 1 2 1 3)))
  (setq l (cl-nsubstitute 'x 1 l))
  (princ (format "  cl-nsubstitute 用 setcar 就地换 → l 变成 %S\n" l)))
```

运行结果：

```
  cl-remove 不动原列表：结果 (2 3)，原列表 (1 2 1 3)
  cl-delete 就地剪接：结果 (0 2 3)，l 变成 (0 2 3)
  向量上 cl-delete ≡ cl-remove（不可伸缩）：[2 3]，原向量 [1 2 1 3]
  cl-remove-duplicates 保留最右 → (1 3 2)
  :from-end t 改留最左 → (1 2 3)
  cl-nsubstitute 用 setcar 就地换 → l 变成 (x 2 x 3)
  规律：无前缀名=复制版（原序列不动），n 前缀或 delete
  前缀=破坏版；字符串/向量不可伸缩，破坏版退化为复制版。
```

逐点读：

**`cl-remove` 是纯函数，`cl-delete` 就地剪接。** 前两行对比一目了然：`cl-remove` 返回 `(2 3)` 而原列表 `(1 2 1 3)` 原样；`cl-delete` 返回 `(0 2 3)` 且 `l` 本身已变成 `(0 2 3)`。破坏版的返回值与原序列**共享结构**，所以正确姿势永远是 `(setq l (cl-delete … l))`——既拿结果也更新引用，两头都不丢。

**字符串/向量上破坏版退化为复制版。** 第三行是关键实测：向量 `(cl-delete 1 v)` 返回 `[2 3]`，但**原向量还是 `[1 2 1 3]`**。原因很物理：向量和字符串长度固定，删掉元素没法「伸缩」，破坏版只能退回去造新序列。手册对此的原话是：不可伸缩序列上 `cl-delete` 与 `cl-remove` 行为相同——**破坏的承诺只在列表上兑现**。

**`cl-remove-duplicates` 默认保留每组重复元素的**最右**那个。** 第四行 `(1 2 1 3 2)` 去重得 `(1 3 2)`：注意结果里 1 和 2 是原序列中**靠后**的那两份（保位、不保先）。加 `:from-end t` 改留最左，得 `(1 2 3)`。去重后元素的相对顺序保持与源一致，这点两种方向都成立。

**`cl-nsubstitute` 用 `setcar` 就地换。** 第六行把 `l` 里所有 1 换成 `x`，`l` 就地变 `(x 2 x 3)`。和 `cl-delete` 一样，示例用 `setq` 接住返回值——这是破坏版的通用写法，字节编译器也会对「返回值被丢弃的破坏版调用」发出警告，等于强制你养成这个习惯。

## 47.7 搜索：`cl-find` / `cl-position` / `cl-count` / `cl-mismatch` / `cl-search`

手册 10.4（Searching Sequences）五个函数分工明确。示例第 7 节：

示例第 7 节：

```elisp
(princ (format "  cl-find 返回元素本身，:from-end 取最右 → %S\n"
               (cl-find 1 '(1 2 1 3) :from-end t)))
(princ (format "  cl-find 未命中 → %S\n" (cl-find 9 '(1 2 3))))
(princ (format "  cl-position :start 1 仍按全序列计位置 → %S\n"
               (cl-position 1 '(1 2 1 3) :start 1)))
(princ (format "  cl-count → %S\n" (cl-count 1 '(1 2 1 3))))
(princ (format "  cl-mismatch 第一处不同（相对 seq1 的下标）→ %S\n"
               (cl-mismatch '(1 2 3) '(1 2 4))))
(princ (format "  短序列先走完也算不匹配 → %S\n"
               (cl-mismatch '(1 2) '(1 2 3))))
(princ (format "  全同 → %S；:key upcase 忽略大小写 → %S\n"
               (cl-mismatch '(1 2) '(1 2))
               (cl-mismatch "Hello" "hello" :key #'upcase)))
(princ (format "  cl-search 找子序列，返回左端起点的下标 → %S\n"
               (cl-search "el" "hello")))
```

运行结果：

```
  cl-find 返回元素本身，:from-end 取最右 → 1
  cl-find 未命中 → nil
  cl-position :start 1 仍按全序列计位置 → 2
  cl-count → 2
  cl-mismatch 第一处不同（相对 seq1 的下标）→ 2
  短序列先走完也算不匹配 → 2
  全同 → nil；:key upcase 忽略大小写 → nil
  cl-search 找子序列，返回左端起点的下标 → 1
  cl-position 的位置永远相对序列整体（哪怕用了 :start）；
  cl-mismatch 全匹配返回 nil，别当 0 用。
```

逐点读：

**`cl-find` 返回元素本身，`cl-position` 返回下标，`cl-count` 数个数。** 三者是「找」的三种取回方式。第一行 `:from-end t` 取**最右**那个 1（值还是 1，看不出方向——方向体现在「选中谁」，对 `:key` 有副作用的场景才有分别）。未命中统一返回 `nil`（第二行）。

**`cl-position` 的下标永远相对序列整体。** 第三行 `:start 1` 从下标 1 开始找，命中的 1 在下标 2——返回 2 而**不是**「窗口内的第 1 个」。示例末尾的注释把这条钉死：哪怕用了 `:start`，位置也按全序列计。

**`cl-mismatch` 返回两序列第一处不同的下标（相对 seq1），全同返回 `nil`。** 第五行 `(1 2 3)` 对 `(1 2 4)` 在下标 2 分叉，得 2；第六行 `(1 2)` 对 `(1 2 3)`——**长度不等本身就是不匹配**，短序列走完处（下标 2）就是分叉点；第七行全同得 `nil`。`:key` 照例是滤镜：`"Hello"` 对 `"hello"` 加 `:key #'upcase` 后视为全同，也得 `nil`。示例末尾提醒：全匹配返回 `nil`，**别当 0 用**——0 的含义是「第一个元素就不同」。

**`cl-search` 找子序列，返回左端起点下标。** 第八行 `"el"` 在 `"hello"` 里从下标 1 开始，得 1。它是 `cl-mismatch` 的「定位版」：一个是「从哪开始不同」，一个是「从哪开始命中」。

## 47.8 排序：`cl-sort` / `cl-stable-sort` / `cl-merge`

手册 10.5（Sorting Sequences）只有三个函数，但有两个坑。示例第 8 节：

示例第 8 节：

```elisp
(princ (format "  cl-sort 直接排序向量（原生 sort 只会排列表）→ %S\n"
               (cl-sort (vector 3 1 2) #'<)))
(princ (format "  手册例：:key downcase 忽略大小写 → %S\n"
               (cl-sort (list "Bob" "alice" "Carol") #'string-lessp :key #'downcase)))
(let ((l (list 3 1 2)))
  (setq l (cl-sort l #'<))
  (princ (format "  cl-sort 是破坏性的：排完 l = %S\n" l)))
(princ (format "  cl-merge 归并两个已序列表 → %S\n"
               (cl-merge 'list (list 1 3 5) (list 2 4) #'<)))
```

运行结果：

```
  cl-sort 直接排序向量（原生 sort 只会排列表）→ [1 2 3]
  手册例：:key downcase 忽略大小写 → ("alice" "Bob" "Carol")
  cl-sort 是破坏性的：排完 l = (1 2 3)
  cl-merge 归并两个已序列表 → (1 2 3 4 5)
  cl-sort 对任意序列可用且就地；31.1 里底层 sort 本来就
  稳定，cl-stable-sort 与之等价（手册保留将来换实现的权利）。
```

逐点读：

**`cl-sort` 对任意序列可用，且是破坏性的。** 第一行直接排向量得 `[1 2 3]`——原生 `sort` 只接受列表，`cl-sort` 补齐了向量和字符串。第三行确认破坏性：`l` 排完就是 `(1 2 3)`。和 47.6 的破坏版同理，标准写法是 `(setq l (cl-sort l #'<))`。

**`:key` 在排序里最常用的姿势是「按某个投影排」。** 第二行是手册原例：`:key #'downcase` 配 `string-lessp`，大小写被忽略，`("Bob" "alice" "Carol")` 排成 `("alice" "Bob" "Carol")`。注意谓词和 `:key` 的分工：谓词定义「谁小」，`:key` 定义「拿元素的哪部分去比」。

**`cl-stable-sort` 在 31.1 与 `cl-sort` 等价。** 示例末尾注释给出实测结论：31.1 的底层 `sort` 本来就是稳定排序，所以两个名字今天行为相同。手册的原话是「保留将来换实现的权利」——意思是**语义上仍该按需选名**：需要稳定性就写 `cl-stable-sort`，别因为「今天碰巧稳定」就写 `cl-sort`。

**`cl-merge` 把两个**已经有序**的序列归并成一个。** 第四行 `(1 3 5)` 与 `(2 4)` 归并得 `(1 2 3 4 5)`，第一个参数指定结果类型。它是归并排序的「并」那一步；输入必须已按同一谓词有序，否则结果未定义。

## 47.9 列表函数：`cl-first` … `cl-tenth`、`cl-rest`、`cl-endp`、`cl-list-length`、`cl-list*`、`cl-ldiff`、`cl-copy-list`、`cl-tree-equal`

进入手册第 11 章（Lists），主角从「任意序列」收窄到「cons cell 链」。示例第 9 节先把访问与复制函数过一遍：

示例第 9 节：

```elisp
(princ (format "  cl-first..cl-tenth ≡ car/cadr/…：%S %S %S\n"
               (cl-first '(1 2 3)) (cl-second '(1 2 3)) (cl-rest '(1 2 3))))
(princ (format "  cl-endp 对非列表报错 → %S\n"
               (condition-case err
                   (cl-endp 'sym)
                 (error (error-message-string err)))))
(let ((l (list 1 2 3)))
  (setcdr (cddr l) l)
  (princ (format "  环形列表 cl-list-length → %S（length 会死循环）\n"
                 (cl-list-length l))))
(princ (format "  cl-list* 尾参变 CDR：%S 与 %S\n"
               (cl-list* 'a 'b 'c) (cl-list* 'a 'b nil)))
(let ((x (list 1 2 3 4)))
  (princ (format "  cl-ldiff 取前段拷贝 → %S（与原列表不共享：%S）\n"
                 (cl-ldiff x (cddr x))
                 (eq (cl-ldiff x (cddr x)) x))))
(princ (format "  cl-copy-list 正确复制点列表 → %S\n"
               (cl-copy-list '(1 2 . 3))))
(princ (format "  cl-tree-equal 默认 eql：%S；:test equal：%S\n"
               (cl-tree-equal '(("a")) '(("a")))
               (cl-tree-equal '(("a")) '(("a")) :test #'equal)))
```

运行结果：

```
  cl-first..cl-tenth ≡ car/cadr/…：1 2 (2 3)
  cl-endp 对非列表报错 → "Wrong type argument: list, sym, x"
  环形列表 cl-list-length → nil（length 会死循环）
  cl-list* 尾参变 CDR：(a b . c) 与 (a b)
  cl-ldiff 取前段拷贝 → (1 2)（与原列表不共享：nil）
  cl-copy-list 正确复制点列表 → (1 2 . 3)
  cl-tree-equal 默认 eql：nil；:test equal：t
  cl-endp 是「严格版 null」；cl-tree-equal 递归比 cons 树，
  字符串元素记得给 :test 'equal（默认 eql 不比字符串内容）。
```

逐点读：

**`cl-first` … `cl-tenth`、`cl-rest` 只是 `car`/`cadr`/`cdr` 的可读别名。** 第一行 `cl-first` 得 1、`cl-second` 得 2、`cl-rest` 得 `(2 3)`，语义与原生访问子一一对应。它们的价值在自文档化：处理「列表即记录」的代码里，`cl-third` 比 `caddr` 好读。

**`cl-endp` 是「严格版 `null`」：只认 `nil` 与 cons，其余一律报错。** 第二行 `(cl-endp 'sym)` 抛 `"Wrong type argument: list, sym, x"`——注意 31.1 的报错信息**带上了形参名 `x`**，定位问题更友好。`null` 对任何非 nil 对象返回 `nil`，`cl-endp` 则要求实参必须是列表；用它做循环终止判断能提前暴露「链条混进了原子」的 bug。

**`cl-list-length` 对环形列表返回 `nil`，`length` 会死循环。** 第三行故意把列表尾接到自己头上造成环，实测返回 `nil`——这是它和原生 `length` 的唯一区别，也是存在的全部理由。任何「遍历未知来源列表」的代码都该用它。

**`cl-list*` 是「最后一个参数当 CDR」的 `list`。** 第四行 `(cl-list* 'a 'b 'c)` 得点列表 `(a b . c)`，而尾参为 `nil` 时退化回普通列表 `(a b)`。它等价于原生 `cons` 的多参展开，构造函数式返回「列表+尾巴」时最顺手。

**`cl-ldiff` 取「从表头到某条尾巴之前」的前段拷贝。** 第五行 `(cl-ldiff x (cddr x))` 得 `(1 2)`——`x` 到它的 `(cddr x)`（即 `(3 4)` 那条尾巴）之前的部分。拷贝与原列表**不共享结构**（`eq` 比较得 `nil`）。参数必须是原列表的真尾巴，否则语义未定义。

**`cl-copy-list` 只复制 cons 骨架一层，且能正确处理点列表。** 第六行 `(1 2 . 3)` 复制后还是 `(1 2 . 3)`——原生 `copy-sequence` 遇点列表会报错，`cl-copy-list` 不会。注意它**不递归**：元素若是 cons，元素本身仍共享；要深拷贝请用 `copy-tree`。

**`cl-tree-equal` 递归比较两棵 cons 树，默认 `eql`。** 第七行两棵 `("a")` 树按 `eql` 比得 `nil`（字符串不是同一个对象），加 `:test #'equal` 才得 `t`。示例末尾提醒：含字符串元素的树比较，记得给 `:test`。

## 47.10 树替换：`cl-subst` / `cl-nsubst` / `cl-sublis`

手册 11.2（Substitution of Expressions）三个函数把「替换」从序列顶层推广到整棵 cons 树。示例第 10 节：

示例第 10 节：

```elisp
(princ (format "  cl-subst 递归 CAR 与 CDR（含 dotted 尾）→ %S\n"
               (cl-subst 'x 1 '(1 (2 1) . 1))))
(let ((tree (list 1 (list 2 1))))
  (setq tree (cl-nsubst 'x 1 tree))
  (princ (format "  cl-nsubst 就地（setcar/setcdr）→ tree 变成 %S\n" tree)))
(princ (format "  cl-sublis 按 alist 批量换 → %S\n"
               (cl-sublis '((a . apple) (b . banana)) '(a b c a))))
```

运行结果：

```
  cl-subst 递归 CAR 与 CDR（含 dotted 尾）→ (x (2 x) . x)
  cl-nsubst 就地（setcar/setcdr）→ tree 变成 (x (2 x))
  cl-sublis 按 alist 批量换 → (apple banana c apple)
  cl-substitute（第 6 节）只换序列顶层；cl-subst 一族换整棵
  cons 树。old 本身是 cons 时按整体匹配、不再递归进去。
```

逐点读：

**`cl-subst` 同时递归 CAR 与 CDR，连 dotted 尾也不放过。** 第一行 `(cl-subst 'x 1 '(1 (2 1) . 1))` 得 `(x (2 x) . x)`——注意末尾那个 `. 1` 也变成了 `. x`。这是它和 47.6 的 `cl-substitute` 的本质区别：后者只看序列**顶层**元素，前者换**整棵树**的每个原子位置。

**`cl-nsubst` 是破坏版：用 `setcar`/`setcdr` 就地改。** 第二行 `tree` 就地变成 `(x (2 x))`。照例 `setq` 接住返回值（破坏版的通用纪律，见 47.6）。

**`cl-sublis` 按关联列表批量替换。** 第三行 `((a . apple) (b . banana))` 把 `(a b c a)` 换成 `(apple banana c apple)`——每个树节点拿 alist 查一遍，命中换 CDR，不中保留。可以把多个 `cl-subst` 的活一次干完。

**`old` 本身是 cons 时按整体匹配。** 示例末尾注释照录手册规则：当 `old` 是 cons（比如想替换子树 `(2 1)`），匹配按「整棵子树相等」进行，命中后**不再递归进替换结果**。想换子树就给整棵子树做 `old`，想换原子就给原子。

## 47.11 列表当集合：`cl-member` / `cl-tailp` / `cl-adjoin` / `cl-pushnew` / `cl-union` 等

手册 11.3（Lists as Sets）把列表当无序集合用：成员判断、并交差补。`cl-pushnew` 其实在手册 5.2.2（Modify Macros）——它是个修改 place 的宏，本章一并演示。示例第 11 节：

示例第 11 节：

```elisp
(princ (format "  cl-member 命中返回尾巴（不是元素）→ %S\n"
               (cl-member 2 '(1 2 3))))
(let ((needle (copy-sequence "b"))
      (hay (list "a" "b")))
  (princ (format "  字符串默认 eql 不中：%S；:test equal 才中：%S\n"
                 (cl-member needle hay)
                 (cl-member needle hay :test #'equal))))
(let ((x (list 1 2 3)))
  (princ (format "  cl-tailp 判定真尾巴 → %S / %S\n"
                 (cl-tailp (cddr x) x) (cl-tailp (list 3) x))))
(princ (format "  cl-adjoin 已在则不 cons：%S / %S\n"
               (cl-adjoin 2 '(1 2 3)) (cl-adjoin 0 '(1 2 3))))
(let ((s (list 2 3)))
  (cl-pushnew 2 s)
  (princ (format "  cl-pushnew 重复不推 → %S；" s))
  (cl-pushnew 1 s)
  (princ (format "新元素推入 → %S\n" s)))
(princ (format "  cl-union（排序后展示，顺序未定义）→ %S\n"
               (sort (cl-union '(1 2 3) '(2 3 4)) #'<)))
(princ (format "  cl-intersection → %S；cl-set-difference → %S\n"
               (sort (cl-intersection '(1 2 3) '(2 3 4)) #'<)
               (cl-set-difference '(1 2 3 4) '(2 4))))
(princ (format "  cl-set-exclusive-or → %S；cl-subsetp → %S\n"
               (sort (cl-set-exclusive-or '(1 2 3) '(2 3 4)) #'<)
               (cl-subsetp '(1 2) '(1 2 3))))
```

运行结果：

```
  cl-member 命中返回尾巴（不是元素）→ (2 3)
  字符串默认 eql 不中：nil；:test equal 才中：("b")
  cl-tailp 判定真尾巴 → t / nil
  cl-adjoin 已在则不 cons：(1 2 3) / (0 1 2 3)
  cl-pushnew 重复不推 → (2 3)；新元素推入 → (1 2 3)
  cl-union（排序后展示，顺序未定义）→ (1 2 3 4)
  cl-intersection → (2 3)；cl-set-difference → (1 3)
  cl-set-exclusive-or → (1 4)；cl-subsetp → t
  原生 member 用 equal，cl-member 默认 eql——字符串成员判断
  是两者的经典差异。集合函数结果顺序未定义，演示前先 sort。
```

逐点读：

**`cl-member` 命中返回**从命中元素开始的那条尾巴**，不是元素本身。** 第一行 `(cl-member 2 '(1 2 3))` 返回 `(2 3)`。这条尾巴既是真值又是数据：可以继续 `cdr` 往下找下一个命中，也可以直接当子列表用。

**字符串成员判断是 `cl-member` 与原生 `member` 的经典差异。** 第二行实测：默认 `eql` 下 `(cl-member needle hay)` 得 `nil`（`needle` 与列表里的 `"b"` 不是同一对象），加 `:test #'equal` 才命中 `("b")`。原生 `member` 恰好相反（默认 `equal`）。示例里 `needle` 特意用 `copy-sequence` 造一个**新字符串对象**——字节编译器看到对字面量字符串做 `memql`（`eql` 成员判断的内联形式）会直接警告 "called with literal string that may never match"，这个警告本身就是这条差异的最好注脚。

**`cl-tailp` 判定「是不是真尾巴」：必须是同一串 cons cell。** 第三行 `(cddr x)` 是 `x` 的真尾巴得 `t`；`(list 3)` 虽然内容等于 `x` 的尾巴，但**不是同一对象**，得 `nil`。`cl-tailp` 比的是 `eq` 链，不是内容。

**`cl-adjoin` 是「已在则不 cons」的 `cons`，`cl-pushnew` 是它的 place 宏版。** 第四行 2 已在 `(1 2 3)` 里，原样返回；0 不在，cons 上去得 `(0 1 2 3)`。第五行 `cl-pushnew` 把同一逻辑做成 `push` 风格的修改宏：重复推 2 无效果，推 1 才变 `(1 2 3)`。手册把它放在 5.2.2 的 Modify Macros 而非本章——它操作的是 `s` 这个 place（展开成 `(setq s (cl-adjoin 2 s))`），与 `push`/`pop`/`incf` 同族。

**`cl-union`/`cl-intersection`/`cl-set-difference`/`cl-set-exclusive-or` 的结果顺序未定义。** 手册明说这些函数不保证返回元素的顺序，所以示例里凡结果顺序未定义的（union/intersection/xor）都先 `sort` 再打印，保证输出确定：并集 `(1 2 3 4)`、交集 `(2 3)`、差集 `(1 3)`（在 `(1 2 3 4)` 里而不在 `(2 4)` 里）、对称差 `(1 4)`（只在一边出现的）。`cl-subsetp` 是纯粹的判定，得 `t`。另外注意 `cl-set-difference` 的结果顺序**反而**有保证——它按第一个列表的顺序保留元素，所以示例没给它排序。

## 47.12 关联列表：`cl-assoc` / `cl-rassoc` / `cl-acons` / `cl-pairlis`

手册 11.4（Association Lists）：元素都是 cons cell 的列表就是 alist，这是 Emacs Lisp 里最常用的「穷人哈希表」。示例第 12 节：

示例第 12 节：

```elisp
(princ (format "  cl-assoc 忽略非 cons 元素 → %S\n"
               (cl-assoc 'b '(junk (a . 1) (b . 2) nil))))
(princ (format "  cl-rassoc 按 CDR 反查 → %S\n"
               (cl-rassoc 2 '((a . 1) (b . 2)))))
(princ (format "  cl-acons ≡ (cons (cons k v) alist) → %S\n"
               (cl-acons 'a 1 '((b . 2)))))
(princ (format "  cl-pairlis 键值两表配对 → %S\n"
               (cl-pairlis '(a b) '(1 2) '((c . 3)))))
```

运行结果：

```
  cl-assoc 忽略非 cons 元素 → (b . 2)
  cl-rassoc 按 CDR 反查 → (b . 2)
  cl-acons ≡ (cons (cons k v) alist) → ((a . 1) (b . 2))
  cl-pairlis 键值两表配对 → ((a . 1) (b . 2) (c . 3))
  cl-assoc 比较键用 eql（:test 可换）；对应 -if/-if-not
  变体按谓词查。alist 就是「元素都是 cons cell 的列表」。
```

逐点读：

**`cl-assoc` 按 CAR 查，且能容忍列表里混进的非 cons 元素。** 第一行的 alist 里混了 `junk` 和 `nil`，`cl-assoc` 直接跳过它们，命中 `(b . 2)`。这个宽容度是 CL 版本与原生 `assoc` 的差异之一（原生版遇非 cons 元素同样跳过，但 `cl-assoc` 还支持 `:test`/`:key` 全套关键字）。

**`cl-rassoc` 按 CDR 反查。** 第二行用值 2 反查出 `(b . 2)`。返回的同样是**整个 cons**，不是键也不是值——拿到后 `car` 得键、`cdr` 得值，两个方向通用。

**`cl-acons` 与 `cl-pairlis` 是 alist 的两种构造捷径。** `(cl-acons 'a 1 '((b . 2)))` 就是 `(cons (cons 'a 1) '((b . 2)))` 的短写，得 `((a . 1) (b . 2))`；`cl-pairlis` 把键表、值表平行配对，还能带一个旧 alist 追加在后，得 `((a . 1) (b . 2) (c . 3))`。

**alist 的定义朴素到一句话：元素都是 cons cell 的列表。** 所以 47.11 的全部集合函数、47.1 的全部关键字约定对 alist 照样成立——`:key #'car` 的 `cl-find` 就是手写版 `cl-assoc`（47.1 已演示）。alist 查找是 O(n)，键多时换哈希表（第 46 章的 `being the hash-keys` 遍历的就是它），键少时 alist 的可读性和可打印性无可替代。

## 47.13 小结

本章覆盖手册第 10 章全部五节与第 11 章全部四节，函数一览：

| 类别 | 函数 | 关键语义（实测） |
|---|---|---|
| 关键字约定 | `:test` / `:key` / `:count` / `:start` / `:end` / `:from-end` | 默认 `eql`；`:key` 是滤镜；`:start` 含 `:end` 不含；窗口外元素绝不参与 |
| Mapping | `cl-mapcar` / `cl-map` / `cl-maplist` / `cl-mapc` / `cl-mapcan` | 多序列最短即停；`cl-map` 首参定返回类型；`maplist` 走 CDR 链；`mapcan` 是 `nconc` 拼接 |
| 量词 | `cl-some` / `cl-every` / `cl-notany` / `cl-notevery` | some 返回第一个非 nil 值；仅量词保证从左到右、命中即停 |
| 折叠 | `cl-reduce` | 默认左结合，`:from-end` 右结合；空序列调函数零次取单位元 |
| 段操作 | `cl-subseq` / `cl-concatenate` / `cl-fill` / `cl-replace` | subseq 恒拷贝、独享负索引、可作 place；fill/replace 就地 |
| 复制/破坏 | `cl-remove` vs `cl-delete`、`cl-substitute` vs `cl-nsubstitute`、`cl-remove-duplicates` | 列表上破坏版就地；字符串/向量不可伸缩，破坏版退化为复制版；去重默认留最右 |
| 搜索 | `cl-find` / `cl-position` / `cl-count` / `cl-mismatch` / `cl-search` | position 按全序列计下标；mismatch 全同返回 nil 别当 0 |
| 排序 | `cl-sort` / `cl-stable-sort` / `cl-merge` | 就地、任意序列；31.1 底层已稳定；merge 要求输入已序 |
| 列表访问 | `cl-first`…`cl-tenth` / `cl-rest` / `cl-endp` / `cl-list-length` | endp 严格报错（31.1 带形参名）；list-length 遇环返回 nil |
| 列表构造 | `cl-list*` / `cl-ldiff` / `cl-copy-list` / `cl-tree-equal` | list* 尾参当 CDR；ldiff 取前段拷贝；copy-list 只拷骨架一层 |
| 树替换 | `cl-subst` / `cl-nsubst` / `cl-sublis` | 递归 CAR 与 CDR 含 dotted 尾；old 为 cons 按整棵匹配 |
| 集合 | `cl-member` / `cl-tailp` / `cl-adjoin` / `cl-pushnew` / `cl-union` / `cl-intersection` / `cl-set-difference` / `cl-set-exclusive-or` / `cl-subsetp` | member 返尾巴；字符串须 `:test equal`；union 等结果顺序未定义 |
| 关联列表 | `cl-assoc` / `cl-rassoc` / `cl-acons` / `cl-pairlis` | assoc 按 CAR、rassoc 按 CDR、都容忍非 cons 元素；键比较默认 eql |

三条 31.1 实测要点，再强调一遍：`cl-member` 默认 `eql`、原生 `member` 默认 `equal`，字符串成员判断两者方向相反，字节编译器对字面量字符串的 `memql` 警告就是这条差异的自动哨兵；破坏版函数（`cl-delete`、`cl-nsubstitute`、`cl-sort`）永远 `(setq l (… l))` 接住返回值，且在字符串/向量上退化为复制版——「破坏」的承诺只在列表上兑现；`cl-remove-duplicates` 默认保留最右一份、`:from-end t` 改留最左，方向选错结果完全不同。

至此手册第 10、11 章讲完。第 46 章的 `cl-loop` 管「怎么遍历」，本章的序列函数管「怎么表达变换」，两者是同一批操作的命令式与函数式两张面孔。下一章回到手册前部的独立章节：类型系统（`cl-typep`、`cl-deftype`）、结构（`cl-defstruct`）、断言（`cl-assert`、`cl-check-type`）与 `cl-print` 的自定义打印——也就是 CL 手册第 2、4、9、12、13 章的内容。

上一章：[46 · cl-loop：Loop 宏的完整语法](46-loop-facility.md)　｜　下一章：[48 · 类型与结构：cl-defstruct、cl-assert 与 cl-print](48-types-structs.md)　｜　返回：[Emacs 扩展开发指南](README.md)
