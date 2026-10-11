# 01 · 预备知识：拓扑、网、Zorn 与 Baire 纲

Conway 在附录 A 里压缩了本书需要的全部一般拓扑与代数预备。本教程把它们
提前到正文第 01 章，理由有二：其一，后面每个非平凡的定理都要用这里的
工具（Baire 纲驱动三大原理，Zorn 驱动 Hahn-Banach，网/滤子驱动弱拓扑）；
其二，这些工具恰好是**机器形式化最见功力的地方**——滤子在 mathlib 与
Isabelle 里都是一等公民，用它们讲极限，机器证明与纸笔数学的距离最近。

本章假定你熟悉点集拓扑的基本语言（开集、闭集、稠密、连续、紧性）。
不熟悉也没关系：我们只用这些概念的标准定义，用到时给出。

## 1.1 完备性与 Baire 纲定理

**定义（无处稠密与贫集）**。拓扑空间 X 中，集合 A 称为**无处稠密**
（nowhere dense），若其闭包内部为空：int(cl A) = ∅。可数个无处稠密集
之并称为**贫集**（meagre，第一纲）；不是贫集的集合称为第二纲。

直观：无处稠密的集合"到处都够薄"——任何开球里都有一块完全不含它。
有理数集 ℚ 在 ℝ 中稠密但它的每个单点集无处稠密，而 ℚ 可数，所以 ℚ
是 ℝ 中的贫集。贫集是"拓扑意义下的小"。

**定理（Baire 纲定理，闭集形式）**。非空完备度量空间 (X, d) 不能写成
可数个内部为空的闭集之并。

**证明**（标准对角线构造）。设 X = ⋃ₙ Fₙ，每个 Fₙ 闭且 int Fₙ = ∅。
归纳构造闭球套：取 B₀ = B(x₀; r₀) ⊆ X 任意（r₀ ≤ 1）。因 F₀ 无处
稠密，B₀ 内有不落在 F₀ 的点，取其一个小闭球 B₁ = B̄(x₁; r₁) ⊆ B₀∖F₀
且 r₁ ≤ 1/2。一般地，因 Fₙ₊₁ 无处稠密而 Bₙ 是非空开集的闭包，可在
Bₙ∖Fₙ₊₁ 内取闭球 Bₙ₊₁，半径 ≤ 1/(n+1)。球套定理（中心 xₙ 是柯西列，
半径趋于 0，完备性给出极限 x）给出 ⋂ₙ Bₙ = {x}。由 Bₙ₊₁ ∩ Fₙ₊₁ = ∅
得 x ∉ ⋃Fₙ，矛盾。∎

这个证明的引擎是**完备性**——没有它，柯西列没有极限，球套可以"塌
进洞里"。第 18、19 章的开映射定理与一致有界原理将把这一引擎开足
马力。

### 机器化：Lean 的 Baire

mathlib 把 Baire 纲组织成类型类 `BaireSpace X`，核心引理是开稠密交集
形式：可数个开稠密集之交稠密。完备度量空间自动获得此实例。我们的
`examples/lean/Funanalysis/Ch01Prelim.lean` 先确认事实存在：

```lean
-- Baire 纲定理（开稠密交集形式）：Baire 空间中可数交保持稠密
#check @dense_iInter_of_isOpen_nat

-- 实例：完备度量空间（如 ℝ）是 Baire 空间
example : BaireSpace ℝ := by infer_instance
```

然后我们把**闭集形式**完整证明一遍——它正是开稠密形式的逆否命题，
但值得手工走一遍，作为"滤子式推理"的热身：

```lean
theorem fa_baire_closed {X : Type*} [MetricSpace X] [CompleteSpace X] [Nonempty X]
    (f : ℕ → Set X) (hf₁ : ∀ n, IsClosed (f n)) (hf₂ : ∀ n, interior (f n) = ∅) :
    (⋃ n, f n) ≠ Set.univ := by
  intro h
  have hdense : Dense (⋂ n, (f n)ᶜ) :=
    dense_iInter_of_isOpen_nat
      (fun n => (hf₁ n).isOpen_compl)
      (fun n => interior_eq_empty_iff_dense_compl.mp (hf₂ n))
  rw [Set.compl_iUnion] at h
  rw [h] at hdense
  rw [dense_iff_closure_eq, closure_empty] at hdense
  exact (Set.univ_nonempty (α := X)).ne hdense.symm
```

逐行读：假设并集穷尽全空间（`intro h`）。每个余集 (f n)ᶜ 开（闭集之
补）且稠密——这里用了 mathlib 的桥梁引理 `interior_eq_empty_iff_dense_compl`
（内部为空当且仅当余集稠密），它就是"无处稠密"两种说法的等价。Baire
引理给出余集之交稠密；但 `Set.compl_iUnion`（棣摩根）把"余集之交"变成
"并集之补"，而并集是全空间，故补为空集；非空空间中空集不稠密
（`dense_iff_closure_eq` 展开稠密，`closure_empty` 是空集的闭包）。
矛盾。四行 tactic，每行对应纸笔证明的一句——这是机器证明的常态：
**骨架由引理库的"桥"承担，你只写数学的转接处**。

### 机器化：Isabelle 的 Baire

Isabelle 的 HOL-Analysis 在 `Elementary_Normed_Spaces` 理论里给出了
`theorem Baire`：对赋范空间中闭集 S 与可数个相对开稠密集，S 含于其交
的闭包。`examples/isabelle/FA01/T01_Prelim.thy` 用 `thm Baire` 确认
其形态，并附带验证完备性的最简实例：

```isabelle
lemma real_complete_instance:
  fixes X :: "real \<Rightarrow> real"
  assumes "convergent X"
  shows "cauchy (X :: nat \<Rightarrow> real)"
  using assms convergent_eq_cauchy by blast
```

`convergent_eq_cauchy` 一名在 Isabelle2025-2 里实际叫
`Cauchy_convergent`（Cauchy ⟹ convergent，用 complete_space 实例）与
`convergent_Cauchy`（反向，对任何度量空间）——`Cauchy` 谓词首字母大写
是 HOL 的命名传统。两者合起来正是"实数列收敛当且仅当柯西"。

## 1.2 序列为什么不够：网与滤子

第 23 章将遇到弱 * 拓扑，那里**序列彻底失效**：ℓ¹ 的单位球面在弱拓扑
下的闭包不能靠序列极限刻画（Schur 定理的反面）。一般拓扑空间中正确
的"广义序列"有两种等价语言：

**网（net）**：从某个有向集（directed set，带预序且任意两元有上界的
集合）到 X 的映射。收敛定义照抄：x_α → x 当且仅当对 x 的每个邻域 U，
终有 α₀ 使 α ≥ α₀ ⟹ x_α ∈ U。Conway 附录 A 用的是网。

**滤子（filter）**：X 上一个对超集与有限交封闭、不含空集的非空集族
𝓕。"𝓕 收敛于 x"当且仅当 x 的每个邻域都属于 𝓕。序列的尾段生成滤子；
网的事件集也生成滤子——滤子是两者共同的抽象。

两种语言数学上等价，但**机器友好度天差地别**：滤子是"集合的集合"，
在类型论里就是 `Set (Set X)` 上的一个结构，Lean 的 `Filter X` 与
Isabelle 的 `'a filter` 都直接用它，且收敛 `Tendsto f l₁ l₂` 可以**复合**
（极限的换序）、可以**推出**（`Filter.Eventually` 里的"终于"），全套
代数。网在类型论里要携带 directedness 证明，笨重得多。因此：

> **本教程的机器通道一律讲滤子；正文讲到网时给出滤子翻译。**

Lean 里的两个基本对象：

```lean
#check @Filter.Tendsto    -- f 沿 l₁ 终于进入 l₂ 的每个成员
#check @Filter.Eventually -- "对所有足够大的 α"的统一形式
```

一个具体的热身（Ch01Prelim.lean 的收尾）：证明 n/(n+1) → 1。纸笔上
你写"任给 ε > 0，取 N > 1/ε"；机器上我们把它拆成两个收敛事实的复合：

```lean
example : Filter.Tendsto (fun n : ℕ => (n : ℝ) / (n + 1)) Filter.atTop (nhds 1) := by
  have h0 : Filter.Tendsto (fun n : ℕ => 1 / (n + 1 : ℝ)) Filter.atTop (nhds 0) :=
    tendsto_one_div_add_atTop_nhds_0_nat
  have h1 : Filter.Tendsto (fun n : ℕ => 1 - 1 / (n + 1 : ℝ)) Filter.atTop
      (nhds (1 - 0 : ℝ)) := h0.const_sub 1
  have hkey : (fun n : ℕ => (n : ℝ) / (n + 1)) = fun n : ℕ => 1 - 1 / (n + 1 : ℝ) := by
    funext n; field_simp
  rw [hkey]
  simpa using h1
```

路线：`1/(n+1) → 0` 是库里的现成事实；减去常量保持收敛
（`h0.const_sub 1`，滤子收敛的代数）；恒等变形 n/(n+1) = 1 - 1/(n+1)
由 `field_simp` 处理（它自动处理了 n+1 ≠ 0 这类分母非零义务）。注意
`1 - 0 = 1` 由最后的 `simpa` 化简——滤子语言允许我们把"代数恒等式"
与"极限过程"完全解耦，这正是它的工程优势。

Isabelle 侧的同款实验（T01_Prelim.thy，最终版）多了两步"平移"：

```isabelle
lemma tendsto_heatup:
  "((\<lambda>n::nat. real n / (real n + 1)) \<longlongrightarrow> 1) sequentially"
proof -
  have base: "((\<lambda>m::nat. 1 / (of_nat m :: real)) \<longlongrightarrow> 0) sequentially"
    by (rule lim_inverse_n')
  have shifted: "((\<lambda>n::nat. 1 / (real (n + 1))) \<longlongrightarrow> 0) sequentially"
    using LIMSEQ_ignore_initial_segment[OF base, of 1] by simp
  have h1: "((\<lambda>n. 1 - 1 / (real (n + 1)) :: real) \<longlongrightarrow> 1 - 0) sequentially"
    by (intro tendsto_intros shifted)
  ...
qed
```

`lim_inverse_n'`（1/n → 0）、`LIMSEQ_ignore_initial_segment`（平移不变：
f ⟶ a 蕴含 f(n+1) ⟶ a）、`tendsto_intros`（极限四则的自动传播）——
两个系统对"极限代数"的组织方式惊人地一致，这本身说明了滤子语言的
普适。注意 Isabelle 里序列滤子叫 `sequentially`；`1 - 0` 这样的
"目标形状"是 tendsto_intros 的接口习惯（它按表达式结构逐项合成），
最后由 simp 化简到 1。

## 1.3 Zorn 引理

**Zorn 引理**。设偏序集 (P, ≤) 非空且每条链（全序子集）有上界，则 P
有极大元。

它与选择公理等价（在 ZF 内）。泛函分析里它几乎只干一件事：**把有限
/可数的构造推到极大**。三个预告：

- Hahn-Banach 延拓定理（第 15 章）：把子空间上定义的线性泛函沿"多
  一次一维"的偏序推到极大，极大性逼迫定义域是全空间；
- 标准正交基的存在（第 05 章）：标准正交集按包含构成偏序，极大元即
  基（Conway I.4.2）；
- Banach-Alaoglu 定理（第 23 章）经 Tychonoff 乘积定理（与选择公理
  等价）。

Prolog 通道的依赖图（第 00 章）已经把这条势力范围画出来了：
`choice` 的后裔包括 hahn_banach、alaoglu、krein_milman、gelfand_duality
等 11 条定理。**泛函分析的"经典公理支柱"只有两根：完备性（Baire 系）
与选择（Zorn 系）**——记住这个二分，全书的结构就清晰了。

机器化方面，mathlib 有 `Zorn.nonempty_preorder_maximal`?（以
`Zorn` 命名的一族引理），Isabelle 有 `Zorn_Lemma`。用到时（第 15 章）
再正式展开，此处留个锚点。

## 1.4 度量空间速查与赋范空间预备

后面反复用的度量事实，一并列出（证明都是标准的，此处从略或见习题）：

1. 完备度量空间的闭子集完备；完备子集必闭。
2. 度量空间中：紧 ⟺ 完全有界且完备。两个方向都要记住——第 23 章
   Alaoglu 定理之后，"弱 * 紧"与"弱 * 闭 + 完全有界"的互换是家常便饭。
3. 一致连续映射把柯西列送成柯西列；连续映射只需把"收敛对"送成
   "收敛对"。
4. ⋂ₙ ⋃ₘ≥ₙ Eₘ 型的"上极限集"语言：Borel-Cantelli 式的推理在
   Baire 论证中反复出现。

赋范空间 (X, ‖·‖)：线性空间 + 满足三角不等式与绝对齐性的范数，度量
d(x,y) = ‖x-y‖ 自动生成。Banach 空间 = 完备赋范空间。这是第 14 章的
主角，此处只立名词。

## 1.5 本章机器化清单

| 文件 | 内容 |
|---|---|
| `examples/lean/Funanalysis/Ch01Prelim.lean` | Baire 闭集形式完整证明、滤子热身 |
| `examples/isabelle/FA01/T01_Prelim.thy` | `thm Baire` 确认、实数完备性、极限代数 |

## 1.6 习题

1. **（纸笔）** 证明：ℚ 作为 ℝ 的子空间是贫集；一个贫集的补（余集）
   在 ℝ 中稠密。
2. **（纸笔）** 证明度量空间中"紧 ⟹ 完全有界"，并给出一个完全有界
   但不完备的具体例子（提示：ℚ ∩ [0,1]）。
3. **（机器）** 在 Lean 中把 `fa_baire_closed` 的假设 `hf₂` 改写成
   无处稠密语言（`Dense (f n)ᶜ`），重写证明。
4. **（数值）** Julia/Python：实现一个"塌陷的球套"实验——在不完备
   空间 ℚ ∩ [0,1]（用有理数近似）里构造半径 1/n 的闭球套使交集为空，
   数值展示"极限点不存在"。

---

上一章：[00 intro](docs/00-intro.md) · 下一章：[02 inner-product](docs/02-inner-product.md)
