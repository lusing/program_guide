# 58 · 有限映射（下）：FSet、不相交集族与有限性的类型化

对应示例：`../examples/lib/T58_fset.thy`（IsaTutLib 会话，
依赖 `HOL-Library.Disjoint_FSets`——它同时带出 `FSet`、
`Disjoint_Sets` 与第 57 章的 `Finite_Map`）

## 58.1 把「有限」从前提搬进类型

第 57 章里，`fmdom` 的类型不是普通的 `'a set`，而是 `'a fset`。
本章就正式讲这个类型。

普通集合 `'a set` 可以无穷，所以凡是要遍历、要计数的定理，都得在
前提里挂一个 `finite A`：有限并的基数、有限和、有限折叠……写起来
重复，还容易漏。`HOL-Library.FSet` 用与 fmap 完全相同的
typedef + Lifting 流水线（第 28、29 章）定义了一个新类型
`'a fset`：它的元素恰好是**有限**普通集合的包装。于是：

- 「有限」从定理前提变成了**类型本身的承诺**——任何接收 fset 的
  操作都不必再带 `finite` 前提；
- fset 携带一整套等式理论（成员、并交差、像、基数、折叠、大算子），
  同时注册了可执行的代码等式；
- 它是第 57 章 fmap 的自然伙伴：有限映射的定义域、值域、像都是
  fset。

本章还讲两个配套理论：

- `Disjoint_Sets`：**普通集合**上的二元不相交谓词 `disjnt` 与
  「两两不相交的集族」`disjoint`；
- `Disjoint_FSets`：fset 版的二元不相交 `fdisjnt`，以及一条把
  本章与第 57 章缝合起来的定理——定义域不相交时 fmap 的并可交换。

## 58.2 构造：空集、`finsert`、字面量与 `fset_of_list`

空集是 `{||}`（注意是**两根**竖线），插入构造子叫 `finsert`，
字面量 `{|x, y, z|}` 只是它的嵌套语法糖。从列表造集用
`fset_of_list`，重复元素被吞掉：

```isabelle
value "{|1, 2, 2, 3|} :: nat fset"
value "fset_of_list [1::nat, 2, 2, 3]"
value "finsert 4 ({|1, 2, 3|} :: nat fset)"
value "finsert 2 ({|1, 2, 3|} :: nat fset)"
```

四行的求值结果分别是：

```text
"Abs_fset {1, 2, 3}" :: "nat fset"
"Abs_fset {1, 2, 2, 3}" :: "nat fset"
"Abs_fset {4, 1, 2, 3}" :: "nat fset"
"Abs_fset {1, 2, 3}" :: "nat fset"
```

打印出来的 `Abs_fset {…}` 是 typedef 自动生成的**内部构造子**，
表示「这个普通集合的有限包装」；集合的相等由外延决定，所以第二行
底层集合里虽然显示了两个 `2`，它与第一行仍是同一个 fset——普通
集合本来就忽略重复。第四行说明插回已有元素什么都不改变
（幂等性 `finsert_absorb`）。

往普通集合方向的**投影**常量就叫 `fset`；想要人类可读的列表形式，
用 `sorted_list_of_fset`（要求元素类型是 `linorder`）：

```isabelle
value "fset ({|3, 1, 2|} :: nat fset)"
value "sorted_list_of_fset ({|3, 1, 2|} :: nat fset)"
```

结果：

```text
"{3, 1, 2}" :: "nat set"
"[1, 2, 3]" :: "nat list"
```

`fset` 投影是 fset 世界通往 Main 集合库的主要出口，后面所有
transfer 证明都围绕它展开。

## 58.3 属于、有限量词与集合代数

属于关系写作 `x |∈| A`（双竖线夹个∈）。两个有限量词

```text
∀x|∈|A. P x      ∃x|∈|A. P x
```

分别展开为常量 `fBall` 与 `fBex`，定义就是对投影 `fset A` 做
普通量词。直接求值：

```isabelle
value "2 |∈| ({|1, 2, 3|} :: nat fset)"
value "∀x|∈|({|2, 4, 6|} :: nat fset). even x"
value "∃x|∈|({|1, 3, 4|} :: nat fset). even x"
```

三个结果都是 `True`：2 在集合里；{2,4,6} 全偶；{1,3,4} 里存在
偶数。

并、交、差、真/非真包含分别是 `A |∪| B`、`A |∩| B`、
`A |-| B`、`A |⊆| B` / `A |⊂| B`，它们把 lattice 类族
（第 23 章那一套半格定律）整体实例化到了 fset 上。在 `finite`
类型上还有全集 `fUNIV` 与补集（负号）：

```isabelle
value "({|1, 2|} :: nat fset) |∪| {|2, 3|}"
value "({|1, 2|} :: nat fset) |∩| {|2, 3|}"
value "({|1, 2, 3|} :: nat fset) |-| {|2|}"
value "{|1|} |⊆| ({|1, 2|} :: nat fset)"
value "(fUNIV :: bool fset) |-| {|True|}"
```

结果：

```text
"Abs_fset {1, 2, 3}" :: "nat fset"
"Abs_fset {2}" :: "nat fset"
"Abs_fset {1, 3}" :: "nat fset"
"True" :: "bool"
"Abs_fset (List.coset [True])" :: "bool fset"
```

最后一行值得停下来看看：布尔全集去掉 `{True}` 当然就是
`{|False|}`，但代码层把 fUNIV 编译成「列表的余集」
`List.coset`——用排除表表示全集，于是差集打印成
`List.coset [True]`。这不是错误，只是有限枚举类型上全集的可执行
表示；做证明时它与 `{|False|}` 经投影外延相等，不用去手动改写
这个内部形式。

## 58.4 像、单子绑定、幂集与大并

函数像写 `` f |`| A ``（`fimage`）；`fbind` 是单子式的
「先像后并」（list monad 的有限集合版）；`fPow A` 取幂集，
注意它的结果类型是**两层 fset**：`'a fset fset`；`ffUnion` 把
一族 fset 并起来；`fthe_elem` 从单元素集里取出唯一元素：

```isabelle
value "((+) 1) |`| ({|1, 2, 3|} :: nat fset)"
value "fbind ({|1, 2|} :: nat fset) (λn. {|n, n + 10|})"
value "ffUnion ({| {|1::nat, 2|}, {|2, 3|}, {|5|} |})"
value "fthe_elem ({|42|} :: nat fset)"
```

结果：

```text
"Abs_fset {2, 3, 4}" :: "nat fset"
"Abs_fset {12, 2, 11, 1}" :: "nat fset"
"Abs_fset {5, 3, 2, 1}" :: "nat fset"
"42" :: "nat"
```

第二行：从 {1,2} 的每个元素生成 {n, n+10} 再合并，得到
{1, 11, 2, 12}；打印顺序无关紧要，集合不认顺序。

`fPow` 是本章第一个**不能求值**的操作——它没有注册任何代码等式：
幂集依赖枚举整个元素类型，代码层只对 `finite` 类型才有意义。
它的结论因此写成引理，用 transfer 回普通集合层交给 auto：

```isabelle
lemma fPow_bool:
  "fPow ({|True, False|}) = {| {||}, {|True|}, {|False|}, {|True, False|} |}"
  including fset.lifting by transfer auto
```

这里第一次出现本章的固定动作 `including fset.lifting by transfer`：
`fset.lifting` 这个 bundle 打开 fset 与其底层普通集合之间的
传输规则，`transfer` 方法把目标搬到普通集合层（第 29 章），那里
`Pow {True, False}` 是 auto 算得动的。记住这个组合，58.5、58.6
还会反复用。

`fthe_elem` 在非单元素集上的行为未指定，证明里使用时要用
「恰有一个元素」的前提守住，别拿它当「随便取一个」的选择算子。

## 58.5 `ffilter`、`ffold` 与大算子 `fsum`

按谓词筛选用 `ffilter`。`ffold f z A` 是有限折叠（参数顺序：
运算、初值、集合）。在此之上，库为每一种交换幺半群装了大算子；
加法的那个叫 `fsum`——它是**前缀常量**，写成 `fsum f A`，
**没有**普通集合 `sum` 那样的 `SUM x∈A. …` 绑定记号：

```isabelle
value "ffilter even ({|1, 2, 3, 4|} :: nat fset)"
value "fsum id ({|1, 2, 3, 4|} :: nat fset)"
value "fsum (λx. x * x) ({|1, 2, 3|} :: nat fset)"
```

结果：

```text
"Abs_fset {2, 4}" :: "nat fset"
"10" :: "nat"
"14" :: "nat"
```

为什么需要大算子，不能直接折叠任意运算？因为「在集合上折叠」
默认结果必须与插入顺序无关，而这只对满足交换性的运算成立。
`ffold` 的计算等式定义在 `comp_fun_commute` 语境里，外层并不
无条件提供；对裸 `ffold (+) 0 A` 用 `value`，代码生成器会把它
展开成「在整个类型上折叠」，进而要求元素类型属于 `finite` 类，
`nat` 直接报错。对加法这种交换幺半群，正解就是用 `fsum`。

把「两者对加法一致」证明出来，需要绕两个小弯，值得完整看一遍：

```isabelle
lemma ffold_plus_is_fsum:
  "ffold (+) 0 A = fsum id (A :: nat fset)"
proof -
  have cfc: "comp_fun_commute (%(x::nat) y. x + y)"
    by standard (simp add: fun_eq_iff ac_simps)
  show ?thesis
  proof (induct A rule: fset_induct_stronger)
    case empty
    show ?case by (simp add: comp_fun_commute.ffold_empty cfc fsum.F.rep_eq)
  next
    case (insert x A)
    show ?case
      by (simp add: comp_fun_commute.ffold_finsert cfc fsum.F.rep_eq finsert.rep_eq
          insert.hyps)
  qed
qed
```

两个弯都有教学价值：

1. **交换性事实要自己证。** 库里并没有现成的
   `comp_fun_commute (+)`（不像 multiset 那条线有
   `comp_fun_commute_plus_mset`），先用 `standard` 进语境、再用
   `fun_eq_iff`（函数外延）加 `ac_simps`（加法结合交换）把
   `f (g x) = g (f x)` 化掉。
2. **语境引理是带限定的导出名。** `ffold_empty`、`ffold_finsert`
   这两个名字只存在于 `comp_fun_commute` 语境**内部**；在外面
   直接写 `simp add: ffold_empty` 会报「Undefined fact」，必须用
   导出名 `comp_fun_commute.ffold_empty` /
   `comp_fun_commute.ffold_finsert`，并把第 1 步的 `cfc` 事实
   喂给它当前提。归纳原则用 `fset_induct_stronger`，它的 insert
   情形自带 `x |∉| A`，正好满足折叠等式的前提。

`fsum.F.rep_eq` 是 Lifting 生成的投影等式（`fsum` 经
`comm_monoid_fset` 子语境安装，所以前缀是 `fsum.F`），
`finsert.rep_eq` 把 fset 插入还原成普通集合插入，于是归纳每一步
都落到普通集合的 `sum.insert` 上。

有了这条桥梁，具体的折叠计算题就交给化简器：

```isabelle
lemma "ffold (+) 0 ({|1, 2, 3, 4|} :: nat fset) = 10"
  by (simp add: ffold_plus_is_fsum fsum.F.rep_eq finsert.rep_eq)
```

顺带一个 transfer 的坑：也许你想直接
`including fset.lifting by transfer (simp add: sum.eq_fold …)`
一步搞定上面的多态恒等式。这会留下一个
`∃A. finite A ∧ …` 的存在目标——fset 的传输关系只是
right-total 而非 bi-total（FSet 源码里那条 `FIXME` 明说），
自由 fset 变量被存在化后，等式两边的底层集合不再自动认亲。
对带自由 fset 变量的目标，老老实实用 fset 自己的归纳原则，
比和 transfer 的存在量词搏斗省事得多。

## 58.6 `fcard`、幂集基数与 `fMin`/`fMax`

`fcard` 是 fset 的基数。有限性已经在类型里，不用再带 `finite`
前提；它与普通 `card` 的关系就是投影等式
`fcard.rep_eq: fcard A = card (fset A)`：

```isabelle
value "fcard ({|1, 2, 2, 3|} :: nat fset)"
```

结果是 `3`——重复在集合层只算一次。

58.4 说过 `fPow` 不能求值，但「幂集的基数 = 2 的 n 次方」照样
能作为定理拿到：先 transfer 回普通集合，再用 Main 的
`card_Pow`：

```isabelle
lemma "fcard (fPow ({|True, False|})) = 4"
  including fset.lifting by transfer (simp add: card_Pow)
```

在 `linorder` 元素上，`fMin`/`fMax` 取最小/最大元素（空集上
无定义）。它们由普通 `Min`/`Max` 经 Lifting 得到，
`fMax_in` 一类的成员定理保证取出的元素确实在集合里：

```isabelle
value "fMax ({|3, 7, 1, 2|} :: nat fset)"   (* "7" :: nat *)

lemma "fMax ({|3, 7, 1, 2|} :: nat fset) = 7"
  by simp
```

## 58.7 `Disjoint_Sets`：两两不相交的集合族

现在转到普通集合（`'a set`）上的 `Disjoint_Sets`。最底层是
**二元**谓词 `disjnt`：

```text
disjnt A B = (A ∩ B = {})
```

在它之上，`disjoint` 定义为 `pairwise disjnt`——一个集合族中
任意两个**不同**成员互不相交。另有按指标集说话的版本
`disjoint_family_on f I`：带指标的族 `f i` 在指标集 `I` 上两两
不相交（`disjoint_family f` 就是指标集取 `UNIV`）。先看求值：

```isabelle
value "disjnt {1::nat, 2} {3, 4}"
value "disjnt {1::nat, 2} {2, 3}"
value "disjoint {{1::nat, 2}, {3}, {4}}"
value "disjoint {{1::nat, 2}, {2}}"
```

结果依次是 `True`、`False`、`True`、`False`：最后一族里
{1,2} 与 {2} 共享元素 2。

一个带指标的不相交族——把 0..5 按奇偶分成两族：

```isabelle
lemma parity_partition:
  "disjoint_family_on (λb. if b then {0::nat, 2, 4} else {1, 3, 5}) UNIV"
  by (auto simp: disjoint_family_on_def)
```

注意这条定理被处理后漂亮地打印成

```text
disjoint_family (λb. if b then {0, 2, 4} else {1, 3, 5})
```

——`_on … UNIV` 形式被规范化成了不带 `_on` 的形式，两个名字
说的是同一件事。

不相交族最常用的推论是**基数可加**：两两不相交时，并的基数等于
各成员基数之和，不必做容斥：

```isabelle
lemma "card ({0::nat, 2, 4} ∪ {1, 3, 5}) =
         card {0::nat, 2, 4} + card {1, 3, 5}"
  by (simp add: card_Un_disjoint)
```

这里两边都显式标注了 `::nat`：若让系统推断成两个不同的
`'a`/``'b`，`card_Un_disjoint` 会因为两个集合类型不一致而
套不上。写集合恒等式时这是常见的小失误。

## 58.8 `Disjoint_FSets` 与 fmap 的交换律

fset 版的二元不相交叫 `fdisjnt`，定义与集合版平行：

```text
fdisjnt M N = (M |∩| N = {||})
```

直接求值：

```isabelle
value "fdisjnt ({|1, 2|} :: nat fset) {|3, 4|}"   (* True *)
value "fdisjnt ({|1, 2|} :: nat fset) {|2, 3|}"   (* False *)
```

真正把本章和第 57 章缝起来的是 `fmadd_disjnt` 这条定理：

```text
fdisjnt (fmdom m) (fmdom n) ⟹ m ++⇘f n = n ++⇘f m
```

第 57 章强调过 fmap 的并 `m ++⇘f n` 一般**右表优先**、不交换。
但若两张表的**定义域不相交**，就没有谁覆盖谁的问题，右偏左偏
结果相同，并运算于是交换：

```isabelle
lemma disjnt_maps_commute:
  "let m = fmap_of_list [(1::nat, ''a'')];
       n = fmap_of_list [(2, ''b'')]
   in fdisjnt (fmdom m) (fmdom n) ∧ m ++⇘f n = n ++⇘f m"
  by (simp add: fmadd_disjnt fdisjnt_alt_def fmupd_reorder_neq)
```

反过来，定义域有重叠时交换律确实失效。这是一个「否定」结论，
证明结构值得写出来——先分别算出两种合并在冲突键上的查找值，
再反证：

```isabelle
lemma overlap_maps_noncommute:
  "fmap_of_list [(1::nat, ''a'')] ++⇘f fmap_of_list [(1, ''b'')] ≠
   fmap_of_list [(1::nat, ''b'')] ++⇘f fmap_of_list [(1, ''a'')]"
proof -
  have l: "fmlookup (fmap_of_list [(1::nat, ''a'')] ++⇘f fmap_of_list [(1, ''b'')]) 1 = Some ''b''"
    by simp
  have r: "fmlookup (fmap_of_list [(1::nat, ''b'')] ++⇘f fmap_of_list [(1, ''a'')]) 1 = Some ''a''"
    by simp
  show ?thesis
  proof (rule notI)
    assume e: "fmap_of_list [(1::nat, ''a'')] ++⇘f fmap_of_list [(1, ''b'')] =
               fmap_of_list [(1::nat, ''b'')] ++⇘f fmap_of_list [(1, ''a'')]"
    have k: "fmlookup (fmap_of_list [(1::nat, ''b'')] ++⇘f fmap_of_list [(1, ''a'')]) 1 = Some ''b''"
      by (subst e[symmetric]) (fact l)
    with r show False by simp
  qed
qed
```

两个实测要点：其一，`l`/`r` 直接 `by simp` 就能算出具体值，
因为 `fmlookup_add`（右表优先的 if 定义）与
`fmap_of_list` 的两条等式已经在默认 simpset 里，显式
`simp add:` 反而会触发「Ignoring duplicate rewrite rule」的
警告；其二，反证内部用 `(subst e[symmetric]) (fact l)` 做纯
等式改写，而**不要**对这些具体表用 `simp add: e`——化简器会
顺手把两边的具体查找都算出数值，`Some ''b''` 与 `Some ''a''`
当场撞车，目标提前变成 `False`，反而拿不到想要的中间等式。

## 58.9 完整小案例：基数可加的三划分

把本章各件缝成一个小证明：用 fset 表达 0..5 的一个三划分，
验证「两两不相交 + 覆盖全集 ⇒ 基数之和 = 总基数」。

```isabelle
definition parts :: "nat fset fset" where
  "parts = {| {|0, 3|}, {|1, 4|}, {|2, 5|} |}"
```

先证两两不相交。注意类型层次：`parts` 是「fset 的 fset」，
而 `pairwise` 吃的是普通集合，所以先投影 `fset parts`：

```isabelle
lemma parts_partition:
  "pairwise fdisjnt (fset parts)"
  by (simp add: parts_def pairwise_def fdisjnt_alt_def)
```

再证并集恰好是 0..5（fset 外延，经 `fset_eq_iff` 化到普通
集合成员关系）：

```isabelle
lemma parts_union: "ffUnion parts = {|0::nat, 1, 2, 3, 4, 5|}"
  by (auto simp: parts_def fset_eq_iff)
```

最后用已证的并集等式接上投影基数，得到总基数：

```isabelle
lemma "fcard (ffUnion parts) = 6"
  by (simp add: parts_union fcard.rep_eq)
```

这三步是 fset 证明的典型套路：**结构性质**（不相交、属于）用
各自的 `_alt_def`/`fset_eq_iff` 化到普通集合；**计数**一律走
`fcard.rep_eq` 投影回 `card`；已有引理优先复用，避免重复展开
定义。

## 58.10 坑位清单（实测）

1. **三套字面量别混。** fset 是双竖线 `{| |}`（`{||}` 为空），
   multiset 是 `{# #}`（第 45 章），普通集合是单大括号
   `{ }`。
2. **`Abs_fset {…}` 打印是正常现象。** 那是 typedef 内部构造子；
   底层集合里显示重复元素也不影响相等。要看列表用
   `sorted_list_of_fset`，要回 Main 集合用投影 `fset A`。
3. **`fsum` 是前缀常量** `fsum f A`，没有 `SUM x:A. …` 绑定
   记号；后者是普通集合的 `sum`。fset 这条线只预装了加法这一个
   算术大算子（其他幺半群要用，得沿 `comm_monoid_fset` 语境
   自己实例化它的 `F`）。
4. **求值边界（与第 57 章同源）。** fset 操作在代码层展开成
   普通集合，凡实现依赖「枚举整个类型」的操作在无穷类型上不能
   `value`：fmap 上的 `size`/`fmimage`/`fset_of_fmap`、fset
   版的 `fPow`（干脆没有代码等式）都在此列；裸 `ffold` 对
   任意运算也没有计算式（等式只在 `comp_fun_commute` 语境
   成立），加法折叠请用 `fsum`。可求值的是字面量运算、
   `fcard`、`fsum` 等走折叠等式的操作。
5. **`fPow` 的结果有两层 fset**（`'a fset fset`），套类型时
   别只套一层。
6. **fset 族的「两两不相交」要先投影。**
   `pairwise fdisjnt (fset A)`——`pairwise` 吃普通集合；
   `pairwise fdisjnt A` 会类型不合。
7. **`disjnt` 与 `disjoint` 是两个层。** 前者是二元谓词
   `disjnt (A :: 'a set) B = (A ∩ B = {})`；后者才是族上的
   `pairwise` 性质。不存在一个大写的 `Disjoint` 常量，别凭
   印象写。fset 版对应物叫 `fdisjnt`，来自另一个理论
   `Disjoint_FSets`。
8. **`fMin`/`fMax`/`fthe_elem` 在空集（或非单元素集）上没有
   好行为**，使用前用非空（恰一元素）前提守住。
9. **`A |-| B` 是 fset 差；fmap 没有这个记号。** fmap 删除用
   `fmdrop`/`fmdrop_fset` 一族（第 57 章），别张冠李戴。
10. **fset 与 Main 集合/列表库的通关口只有三个：** 投影
    `fset A` 出去，`fset_of_list` 从列表进来，
    `sorted_list_of_fset` 从有序列表出去。证明上回到普通集合
    用 `including fset.lifting by transfer`，但带自由 fset
    变量的目标优先用 `fset_induct_stronger`——传输关系只
    right-total，transfer 会丢出存在量词。

## 58.11 与其他章的接口

- 第 28、29 章 typedef 与 Lifting/Transfer：fset 是这条流水线
  最完整的教学样本之一，`fset.lifting` bundle、`*.rep_eq`、
  `including … by transfer` 三件套贯穿全章。
- 第 57 章 fmap/Mapping：`fmdom`/`fmran`/`fmimage` 的值域类型
  就是 fset；`fmadd_disjnt` 把「不相交」与「映射并可交换」连
  起来，是这两章的合龙处。
- 第 45 章 multiset：multiset 记重数、fset 不记，两者各管一类
  需求；字面量记号也不同（`{# #}` vs `{| |}`）。
- 第 23 章偏序与半格：fset 的并交差包含是 lattice 类族的实例，
  类的定律直接可用。
- 第 59 章红黑树：可执行 fset 的后端与 `RBT_Mapping` 同源，
  有序列表接口 `sorted_list_of_fset` 正是对接点。
