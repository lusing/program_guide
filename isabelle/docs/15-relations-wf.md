# 15 · 关系、闭包与良基性

对应示例：`../examples/T15_relations_wf.thy`

## 15.1 关系就是二元谓词

```isabelle
'a rel  ≡  'a ⇒ 'a ⇒ bool
```

关系不是数据结构，是**二元谓词**。这跟第 14 章"集合 = 谓词"是同一件事的两面：`(a,b) ∈ r` 就是 `r a b`。

## 15.2 关系的基本运算

```isabelle
value "{(1::nat, 2::nat), (2::nat, 3::nat)}"
value "{(1::nat, 2::nat)} O {(2::nat, 3::nat)}"
value "((1::nat, 2::nat) \<in> {(1::nat, 2::nat)})"
```

实测输出：

```text
"{(1, 2), (2, 3)}"
  :: "(nat \<times> nat) set"

"{(1, 3)}"
  :: "(nat \<times> nat) set"

"True"
  :: "bool"
```

`O` 是**关系复合**：`(1,2) O (2,3) = {(1,3)}`。注意它跟函数复合相反的直觉——`r O s` 是"先走 r 再走 s"。

```isabelle
lemma relcomp_demo: "(r O s) `` A = s `` (r `` A)"
  by blast
```

```text
theorem relcomp_demo: (?r O ?s) `` ?A = ?s `` ?r `` ?A
```

` `` ` 是**像**（把关系作用在集合上）。这条定理正好印证了顺序：先 `r` 再 `s`，写起来右边就从内到外是 `r` 然后 `s`。

## 15.3 传递闭包自带归纳原理

`r\<^sup>*`（`rtrancl`）是**归纳定义**的，所以它自带一条归纳原理。把它打印出来看：

```isabelle
ML \<open>writeln (@{make_string} @{thm rtrancl_induct})\<close>
```

```text
"\<lbrakk>(?a, ?b) \<in> ?r\<^sup>*; ?P ?a; \<And>y z. \<lbrakk>(?a, y) \<in> ?r\<^sup>*; (y, z) \<in> ?r; ?P y\<rbrakk> \<Longrightarrow> ?P z\<rbrakk>
 \<Longrightarrow> ?P ?b"
```

读法：要从 `(a,b) ∈ r*` 证 `P b`，只需

1. 证 `P a`（起点成立）；
2. 证"若 `a` 可达 `y` 且 `P y` 且 `(y,z) ∈ r`，则 `P z`"（走一步保持）。

这就是**可达性证明的标准形状**。所有"经过 n 步会怎样"的命题都这么证。

两个基本引理：

```isabelle
lemma rtrancl_refl: "(a, a) \<in> r\<^sup>*"
  by (rule rtrancl_refl)

lemma rtrancl_into: "(a, b) \<in> r\<^sup>* \<Longrightarrow> (b, c) \<in> r \<Longrightarrow> (a, c) \<in> r\<^sup>*"
  by (rule rtrancl_into_rtrancl)
```

```text
theorem local.rtrancl_refl: (?a, ?a) \<in> ?r\<^sup>*

theorem rtrancl_into: \<lbrakk>(?a, ?b) \<in> ?r\<^sup>*; (?b, ?c) \<in> ?r\<rbrakk> \<Longrightarrow> (?a, ?c) \<in> ?r\<^sup>*
```

注意第一条打印成 **`local.rtrancl_refl`** 而不是 `rtrancl_refl`。因为我给新引理起了和库里已有定理**一样的名字**，Isabelle 允许这样（新名字遮蔽旧的），打印时加 `local.` 前缀区分。

这不是好事。**给引理起库里已有的名字会让读者和工具都困惑**，实测输出里那个 `local.` 就是代价。起名前先 `find_theorems name:` 查一下（第 17 章讲）。

## 15.4 良基性：递归能停的理论依据

`wf r`（良基）= `r` 上不存在无限下降链。这是"这个递归一定停"的数学说法。

```isabelle
lemma wf_less_than: "wf less_than"
  by simp

lemma wf_measure: "wf (measure f)"
  by simp

lemma measure_less: "((x, y) \<in> measure f) = (f x < f y)"
  by (simp add: measure_def)
```

```text
theorem local.wf_less_than: wf less_than

theorem local.wf_measure: wf (measure ?f)

theorem measure_less: ((?x, ?y) \<in> measure ?f) = (?f ?x < ?f ?y)
```

`measure f` 把"某个量在下降"变成良基关系：

```isabelle
measure f  ≡  {(x, y). f x < f y}
```

**方向要小心**：`(x,y) ∈ measure f` 意思是 `f x < f y`，也就是 **x 更小**。写反了（`f y < f x`）会让 `termination` 证明变成一个假命题，死活证不出来——这是本章最容易踩的一条。

`wf (measure f)` 能 `by simp` 过，是因为 `nat` 上的 `<` 良基是已知事实。这也就是为什么**几乎所有的终止性证明最后都归结到"找一个 nat 值在下降"**。

## 15.5 手写一次 termination

```isabelle
function count_down :: "nat list \<Rightarrow> nat" where
  "count_down [] = 0"
| "count_down (x # xs) = 1 + count_down xs"
  by pat_completeness auto
termination by (relation "measure length") auto
```

`function` 比 `fun` 原始：`fun` 会自动试各种终止性度量，`function` 什么都不试，把工作全留给你。两件事必须手工做：

1. `by pat_completeness auto` —— 证明方程**覆盖完全**（所有输入都匹配上了）且不重叠；
2. `termination` —— 证明递归在下降。

`termination` 后那个 `by (relation "measure length") auto` 的含义：以"列表长度"为度量，于是待证目标变成

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
((xs, x # xs) ∈ measure length)
```

展开 `measure_def` 后是 `length xs < length (x # xs)`，`simp` 直接过。

实测确认函数可用：

```text
consts
  count_down :: "nat list \<Rightarrow> nat"

"3"
  :: "nat"
```

（`value "count_down [1::nat, 2, 3]"` 得 3。）

## 15.6 自动终止性失败时怎么办

`fun` 的自动度量搜索失败时，它会留下一条带前提的方程 `f.dom`，而不是直接报错。这时三条路：

1. 手写 `relation`（如上）；
2. 换个"更能被机器识别"的写法（例如把递归参数改成显式递减的 `nat`）；
3. 改用 `partial_function`：它**根本不要求终止**，代价是方程带 `dom` 前提，用起来更麻烦。

第 16 章会展开第 3 条。

---

## 本章坑位清单（实测）

1. **`measure` 方向写反**：`(x,y) ∈ measure f` 是 `f x < f y`（前者更小）。写反了终止性证明永远过不去。
2. **给引理起库里已有的名字**：`rtrancl_refl`、`wf_less_than` 都在库里。起名撞车会打印成 `local.xxx`，后续引用容易指向错的那个。
3. **`r O s` 的顺序**：是"先 r 后 s"，跟函数复合的直觉相反。
4. **用 `simp` 证闭包性质**：`r*` 是归纳定义的，`simp` 不展开归纳，要用 `rtrancl_induct`。
5. **`termination` 忘了 `relation`**：不指定度量的话，`function` 不知道该证什么，目标会是一串不可解的元变量。
6. **以为 `function` 等于 `fun`**：`function` 必须自己证 `pat_completeness`；`fun` 帮你做。
7. **`\^sup>*` 写成 `*`**：`r*` 在 Isabelle 里不是闭包（那是乘法或别的意思），要写 `r\<^sup>*`。
8. **对非 nat 度量用 `measure`**：`measure` 要求值域是 `nat`（或其他良基序）。`int` 上的"下降"要用 `int_measure` 或显式构造。
9. **闭包归纳时忘了"起点"那条**：`rtrancl_induct` 要三个参数（可达性、起点成立、步进保持），少一个就报 `Failed to apply initial proof method`。
10. **把关系当函数用**：`r `` A` 是像，`r x y` 是应用；`r x` 单独出现会得到"缺一个参数"的类型，报 `Type unification failed`。

---

上一章：[14 · 集合与函数](14-sets.md) ｜ 下一章：[16 · 函数定义深水区](16-functions-deep.md) ｜ 返回：[README](../README.md)
