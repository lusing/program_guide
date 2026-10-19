# 60 · 比较器、字典序与排序算法

对应示例（IsaTutLib 会话，四个理论）：

- `../examples/lib/T60a_comparator.thy`（Comparator + Sorting_Algorithms +
  Product_Lexorder + Option_ord + Fun_Lexorder + List_Lexorder）
- `../examples/lib/T60b_prefix.thy`（Prefix_Order）
- `../examples/lib/T60c_subseq.thy`（Subseq_Order）
- `../examples/lib/T60d_lenlex.thy`（List_Lenlexorder）

为什么要拆四个理论：Isabelle 的类实例**唯一**——`'a list` 的 `ord`
实例全库只能有一份。字典序、前缀序、子序列序、长度优先字典序四个
理论各自抢占这个实例位，互不相容，只能分理论演示。选哪个导入，
取决于你的应用场景，这是本章第一个要记住的工程事实。

## 60.1 Comparator：把「比较」做成显式值

`Comparator` 理论把比较从序类里拆出来：三态类型
`comp = Less | Equiv | Greater`，locale `comparator` 要求自反、
Equiv 传递、Less 传递、Greater 与反向 Less 互推。typedef 把满足
条件的函数收进 `'a comparator`，投影 `compare` 是使用方法。
`linorder` 类型自带默认比较器 `default`，常用类型有代码化别名
`comparator_nat`/`comparator_bool`：

```isabelle
value "compare comparator_nat (2::nat) 3"     (* Less *)
value "compare comparator_nat (3::nat) 3"     (* Equiv *)
value "compare comparator_nat (4::nat) 3"     (* Greater *)
value "compare comparator_bool False True"    (* Less *)
```

关键设计：`Equiv` 只承诺「等价」不承诺「相等」。这使比较器比
`linorder` 更强——可以按某个投影比较，把原值不同但投影相同的
元素归入同一等价类，排序时保持它们原有的相对顺序（稳定性，
60.2 有实测）。

三个组合子覆盖常见改造：`reversed` 反转、`key` 按投影比较、
`prod_lex` 字典序拼合。它们各自带 `[simp]` 应用规则
（`prod_lex` 那条 `compare_prod_lex_apply` 例外，要显式 add），
等式命题一行化简：

```isabelle
lemma "compare (reversed comparator_nat) (2::nat) 3 = Greater"
  by simp

lemma "compare (key length comparator_nat) [1::nat, 2] [5] = Greater"
  by simp

lemma "compare (prod_lex comparator_nat comparator_bool) (1::nat, True) (1, False) = Greater"
  by (simp add: compare_prod_lex_apply)
```

第二行按长度比：[1,2] 长度 2 > [5] 长度 1，元素内容无关——这就
是「Equiv ≠ 相等」的活例。第三行先比第一分量（1 与 1 打平），
再比第二分量（False < True）。

## 60.2 Sorting_Algorithms：一次验证，三种算法

`Sorting_Algorithms` 的架构值得细读，它是「抽象规范 + 多实现」
的教科书示范：

- **规范层只有插入排序** `Sorting_Algorithms.sort`，定义即
  `foldr (insort cmp) xs []`；
- 正确性三件套对规范一次证好：多重集不变
  `mset_sort: mset (sort cmp xs) = mset xs`、结果有序
  `sorted_sort: sorted cmp (sort cmp xs)`、稳定性
  `stable_sort: stable_segment cmp x (sort cmp xs) = stable_segment cmp x xs`
  （与 x 等价的元素段排序前后原封不动）；
- `quicksort` 与 `mergesort` 在逻辑层**就是** sort
  （`quicksort_is_sort`、`mergesort_is_sort` 是定义展开的 simp），
  各配一条 `[code]` 等式：quicksort 取中点 pivot 三路划分，
  mergesort 对半切分再 `merge`。

于是「证明一次，跑三种实现」：

```isabelle
value "Sorting_Algorithms.sort comparator_nat [3::nat, 1, 2, 5, 4]"
value "Sorting_Algorithms.quicksort comparator_nat [3::nat, 1, 2, 5, 4]"
value "Sorting_Algorithms.mergesort comparator_nat [3::nat, 1, 2, 5, 4]"
```

三个输出都是 `[1, 2, 3, 4, 5]`，但代码生成走的是各自的快路径。
多重集不变性一条 simp 即可调用：

```isabelle
lemma "mset (Sorting_Algorithms.sort comparator_nat [3::nat, 1, 2]) = {#3, 1, 2#}"
  by simp
```

稳定性的可观察效果——按第一分量排序，同键元素不换序：

```isabelle
value "Sorting_Algorithms.sort (key fst comparator_nat)
  [(1::nat, ''b''), (0, ''a''), (1, ''c'')]"
```

输出 `[(0, ''a''), (1, ''b''), (1, ''c'')]`：两个键 1 的元素
保持 `(1,''b'')` 在前。排序谓词 `Sorting_Algorithms.sorted` 与
Main 的 `List.sorted` 同名不同签名（多一个比较器参数），引用
带前缀：

```isabelle
value "Sorting_Algorithms.sorted comparator_nat [1::nat, 2, 3]"   (* True *)
value "Sorting_Algorithms.sorted comparator_nat [1::nat, 3, 2]"   (* False *)
```

本章还有一条漂亮的收尾定理，它是「基数排序」（低位优先逐位稳定
排序）的正确性原理——先按第二分量稳定排序、再按第一分量稳定
排序，等于一次字典序积排序：

```text
sort (key fst cmp1) ∘ sort (key snd cmp2) = sort (prod_lex cmp1 cmp2)
  （sort_comp_fst_snd_eq_sort_prod_lex）
```

## 60.3 List_Lexorder：列表的字典序

`List_Lexorder` 把列表实例化进序类：`xs < ys` 定义为
`(xs, ys) ∈ lexord {(u, v). u < v}`（Main 的 `lexord` 关系），
逐元素比较、第一处不同定胜负、空表最小。类链一路给全：
`linorder` 实例、`distrib_lattice`（min/max 即 ⊓/⊔）、
`order_bot`（`[]` 是底）：

```isabelle
value "[1, 2] < ([1, 3] :: nat list)"   (* True  — 2 < 3 *)
value "[1, 2] < ([0, 9] :: nat list)"   (* False — 1 > 0，后面不看 *)
value "[5] < ([1, 2] :: nat list)"      (* False — 首元素 5 > 1 *)
value "[] < ([0] :: nat list)"          (* True  — 空表最小 *)

lemma "([1::nat, 2] < [1, 3])"
  by simp
```

第三行是对比锚点：字典序完全不看长度，首元素定胜负。60.7 的
lenlex 版本对同一对列表结论相反。还要记住字典序**不是**良序：
nat 列表有无穷降链 `[1] > [0,1] > [0,0,1] > …`（每步左侧补 0），
所以没有 `wellorder` 实例——需要字符串归纳时看 60.7bis。

## 60.4 Product_Lexorder 与 Fun_Lexorder

`Product_Lexorder` 给积类型装字典序（先比 `fst`，平了再比
`snd`），同样一路实例到 `linorder`、`distrib_lattice`、
`bot`/`top`、乃至 `wellorder`（两边良序则积良序）：

```isabelle
value "(1, 2) < ((1, 3) :: nat × nat)"        (* True *)
value "((2, 0) :: nat × nat) > (1, 9)"        (* True — fst 2 > 1 *)

lemma "((1, 2) :: nat × nat) ≤ (1, 3)"
  by simp
```

注意第二行的类型标注必须罩住**整个二元组**：写成
`((2::nat), 0)` 只钉住第一分量，`0` 仍是多态数字，求值报
「free dictionaries」（59 章 Coset 处踩过的姊妹坑）。

函数类型的字典序是另一回事。Main 已给函数装了**逐点**序
（`f ≤ g ⟷ (∀x. f x ≤ g x)`），所以 `Fun_Lexorder` 刻意**不**
注册类实例，只给出定义：

```text
less_fun f g ⟷ (∃k. f k < g k ∧ (∀k' < k. f k' = g k'))
```

在「第一处不同」的参数上分胜负（参数侧须 `linorder`，充当字典的
字母表）：

```isabelle
lemma "less_fun (%n::nat. n) (%n. if n = 2 then 100 else n)"
  by (auto simp: less_fun_def intro!: exI [of _ 2])
```

两函数在 0、1 处相同，在 2 处 2 < 100，故前者小于后者。三分律
`less_fun_trichotomy` 要求两函数的**差异集有限**（否则「第一处
不同」未必存在）。函数字典序是字典序在「无穷词」上的对应物，
在项序（termination order）文献里反复出现。

## 60.5 Option_ord：None 垫底

`Option_ord` 给 `'a option` 装典范序：`None` 小于一切 `Some`，
`Some` 之间回到元素序。于是 `⊥` 就是 `None`，`⊤` 是 `Some ⊤`
（元素有顶才有顶），并一路实例到 `wellorder`：

```isabelle
value "None < Some (0::nat)"           (* True *)
value "Some (2::nat) ≤ Some 3"         (* True *)
value "None ≤ (Some 5 :: nat option)"  (* True *)

lemma "(⊥ :: nat option) = None"
  by (simp add: bot_option_def)
```

偏函数的序因此有了着落：逐点比较两个 `'a ⇀ 'b` 时，缺键
（`None`）自动是最小值。

## 60.6 Prefix_Order：前缀即 ≤

`Prefix_Order` 把列表的 `prefix` 关系注册成 `order` 类实例：
`xs ≤ ys` 读作「xs 是 ys 的前缀」，`xs < ys` 是严格前缀
（`strict_prefix`）。前缀序是偏序而非线序——`[1,2]` 与 `[1,3]`
互不可比：

```isabelle
lemma "([1, 2] :: nat list) ≤ [1, 2, 3]"  by simp

lemma "¬ ([1, 2] :: nat list) ≤ [1, 3] ∧ ¬ ([1, 3] :: nat list) ≤ [1, 2]"
  by simp

value "([1, 2] :: nat list) < [1, 2, 3]"   (* True *)
value "([2, 1] :: nat list) < [1, 2, 3]"   (* False *)
```

空表是普遍前缀（`Nil_prefix`，行为类似底元素），长度单调：

```isabelle
lemma "[] ≤ (xs :: 'a list)"  by simp

lemma prefix_len: "xs ≤ ys ⟹ length xs ≤ length ys"
  for xs ys :: "'a list"
  by (rule prefix_length_le)
```

Sublist 里前缀一族的引理全部做了 `[folded less_eq_list_def]`
改写重新绑定（`Cons_prefix_Cons`、`prefix_snoc` 等），所以在
本理论里直接拿 `≤`/`<` 形态的引理用，不必手工换算。

## 60.7 Subseq_Order：子序列即 ≤

`Subseq_Order` 是前缀序的放松：`xs ≤ ys` 读作「xs 是 ys 的
**子序列**」——从 ys 里删掉若干元素（不必连续）能得到 xs，
但相对顺序必须保留。与前缀的关键差别是中间可以「跳」：

```isabelle
value "([1, 3] :: nat list) ≤ [1, 2, 3]"   (* True  — 跳过 2 *)
value "([3, 1] :: nat list) ≤ [1, 2, 3]"   (* False — 相对顺序不可换 *)
value "([1, 3] :: nat list) < [1, 2, 3]"   (* True  *)
```

第一句在前缀序下是 `False`——两种序的分野就在这一跳。计算
等式 `le_list_Cons2_iff` 就是经典的「逐头匹配，不等则丢右头」
递归；严格子序列长度严格增长：

```isabelle
lemma subseq_len: "xs < ys ⟹ length xs < length ys"
  for xs ys :: "'a list"
  by (rule less_list_length)

lemma "([1, 3] :: nat list) < [1, 2, 3]"  by eval
```

与函子的配合现成：`le_list_filter`（过滤必得子序列）、
`le_list_map`（映射保持子序列关系）。

## 60.7bis List_Lenlexorder：长度优先的字典序

`List_Lenlexorder` 是字典序变体：**先比长度，等长再逐元素**
（底层是 Main 的 `lenlex` 关系）。它同样独占列表的序类实例位。
行为对照立竿见影——60.3 里判负的例子这里翻案：

```isabelle
lemma "([5] :: nat list) < [1, 2]"          (* 长度 1 < 2，5 > 1 无妨 *)
  by (simp add: Cons_less_Cons)

lemma "([1, 2] :: nat list) < [1, 3]"       (* 等长，退回逐元素 *)
  by (simp add: Cons_less_Cons)

lemma "¬ ([2, 1] :: nat list) < [1, 3]"     (* 等长，2 > 1 判负 *)
  by (simp add: Cons_less_Cons)
```

注意本理论的 `Cons_less_Cons` 没有 `[simp]` 标记（长度分支让
递归等式不再适合无条件 simp），要显式 add。

为什么需要这个变体？为了**良序**。普通字典序下 nat 列表有无穷
降链；长度优先后，降链的长度必须严格下降，触底即止。底层是
Main 的 `wf_lenlex: wf r ⟹ wf (lenlex r)`，本理论顺势给出
`instance list :: (wellorder) wellorder`。需要字符串归纳时
（形式语言、重写系统），这是直接可用的武器——前缀序与子序列
序都只是偏序，给不了这个。

## 60.8 坑位清单（实测）

1. **同名谓词。** `Sorting_Algorithms.sorted`/`sort` 与 Main 的
   `List.sorted`/`sort_key` 同名不同签名（比较器版多一个
   `'a comparator` 参数），混用后引用写全称。
2. **列表序类实例唯一。** List_Lexorder、Prefix_Order、
   Subseq_Order、List_Lenlexorder 四个理论两两互斥（都抢占
   `list :: ord` 实例位），一个理论只能导入其一——本章因此
   拆成四个示例理论。
3. **Equiv 不是相等。** `key` 投影排序时同键异值元素都判
   Equiv；稳定性保证不换序，但 `Equiv ⟹ x = y` 不成立。
4. **`compare_prod_lex_apply` 不是 simp 规则**（其余组合子的
   应用规则是），用时要显式 `simp add:`。
5. **quicksort/mergesort 在逻辑层就是 sort。** 证明性质对着
   `sort` 证，`quicksort_is_sort`/`mergesort_is_sort` 自动衔接；
   快的是各自的 `[code]` 等式。
6. **lenlex 的 `Cons_less_Cons` 无 `[simp]`**（长度分支使递归
   等式不宜默认启用），lex 版则有。
7. **⊥/⊤/⊓/⊔ 的开关。** Isabelle2025-2 起这四个记号收在
   `lattice_syntax` bundle，Main 默认不激活
   （`unbundle no lattice_syntax`）。项里直接写 `\<bottom>`
   报 Inner lexical error；要么 `unbundle lattice_syntax`
   （本教程 T60a 的做法），要么写 `bot`/`top` 标识符。
8. **元组里的数字要整体标注。** `(1::nat, 2)` 只钉住第一分量，
   `2` 仍是多态数字；求值/证明报 free dictionaries 或留下
   多态剩余目标。写 `((1, 2) :: nat × nat)` 罩住整个元组。

## 60.9 与其他章的接口

- 第 23 章偏序与格：本章所有序都是那里类族的实例；
  `distrib_lattice`/`wellorder` 的层级在 lex 与 lenlex 的分叉
  上体现得最清楚。
- 第 45 章 multiset：`mset_sort` 是「排序保持内容」的标准表述，
  多重集是排序正确性证明的通用语言。
- 第 57 章 fmap、第 59 章红黑树：`linorder` 键约束、
  `sorted_list_of_*` 一族接口的序理论地基都在本章。
- 第 19/37 章代码生成：`[code]` 等式三件套（规范+quicksort+
  mergesort）是「数学层一份、执行层多份」的范式。
