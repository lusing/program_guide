# 12 符号测度：Jordan-Hahn 分解与 Radon-Nikodym 定理

**对应严书 §3.3（pp. 52-62）。**

---

## 12.1 从"净质量"出发：符号测度与不定积分

测度只能称正质量；分析学更早遇到的却是**带符号的量**——电荷的
净分布、鞅的漂移、条件期望的差。**符号测度** ν : 𝓕 → [−∞, +∞]
（至多在一侧取 ∞）满足 ν(∅) = 0 与可数可加。原型是**不定积分**：
f 关于 μ 可积（或积分存在）时，ν(A) = ∫_A f dμ 是符号测度
（严书 3.3.1 引理：f⁺·μ − f⁻·μ 把它写成两个测度之差，且一侧
有限——f 的可积性恰好堵住 ∞−∞）。

符号测度继承测度的全部"有限形态"运算：单调、上下连续（对**两侧
都有限**的序列）、可数可加的级数形式——但**单调性降级为变差控制**：
ν(A) 的绝对值被 |ν|(A)（下节的全变差）管住，而非像测度那样自身
非负。严书 3.3.2-3.3.3 的两条观察值得背下：符号测度的正负两部
不可能同时触 ∞（否则某不交并给出 ∞−∞）；以及 ν 在 𝓕 上**达到
上下确界**（3.3.6，本节高潮的前奏）。

## 12.2 Jordan-Hahn 分解定理（严书 3.3.4）

**定理** 设 ν 为符号测度。定义正部、负部：

  ν⁺(A) = sup{ν(B) : B ∈ 𝓕, B ⊆ A}，ν⁻(A) = sup{−ν(B) : …}

则 ν⁺、ν⁻ 都是测度，**至少一个有限**，且 ν = ν⁺ − ν⁻；更存在
**Hahn 分解** Ω = D ⊔ Dᶜ：A ⊆ D ⟹ ν(A) ≥ 0，A ⊆ Dᶜ ⟹
ν(A) ≤ 0（D 称 ν 的正集）。此时 ν⁺(A) = ν(A ∩ D)，
ν⁻(A) = −ν(A ∩ Dᶜ)。

**D 的存在性证明**（严书路线，机器通道逐行复刻）分三步：

1. 令 𝓑 = {B ∈ 𝓕 : ν⁺(B) = 0}（"彻底负"的集：一切子集 ν ≤ 0）。
   𝓑 对可数并封闭、对子集封闭——这是 ν⁺ 的超可加性直接给的。
2. 取 Bₙ ∈ 𝓑 使 ν(Bₙ) → β := inf{ν(B) : B ∈ 𝓑}（β > −∞ 由
   单侧有限性）。令 N = ⋃Bₙ ∈ 𝓑，则 ν(N) = β（升列部分的
   差分估计：β ≤ ν(⋃Bₙ) ≤ ν(Bₘ) ≤ β + ε）。**N 是"最负的
   地方"**。
3. D := Nᶜ 上不允许有负子集：若 A ⊆ D 且 ν(A) < 0，则 A ∪ N
   仍彻底负且 ν(A ∪ N) = ν(A) + β < β——与 β 的下确界地位矛盾。

Hahn 分解**不唯一**（零测的边界可以搬动：ν ≡ 0 时任何 D 都是
Hahn 分解），但正负部 ν⁺、ν⁻ 唯一——这正是"分解不唯一、账本
唯一"的经典形态。**命题 3.3.6（达界）**：ν(D) = sup_𝓕 ν、
ν(Dᶜ) = inf_𝓕 ν——符号测度在集合格上取到最大最小值；特别地
**实值符号测度自动有界**（|ν(A)| ≤ ν⁺(Ω) + ν⁻(Ω) < ∞），
这是第 14 章 ba 空间讨论的出发点之一。

## 12.3 变差测度与极分解

|ν| := ν⁺ + ν⁻ 称**变差测度**，|ν|(Ω) = ‖ν‖_var 称全变差；
‖ν‖_var < ∞ 时称 ν 有限符号测度。**极分解**（注 3.3.5(3)）：
h = I_D − I_{Dᶜ}，则 ν = h·|ν|，|ν| = h·ν——符号信息全部装进
±1 值函数 h，|ν| 是"体积"、h 是"方向"。这与复分析 z = h·|z|、
线性代数 v = (v/‖v‖)·‖v‖ 是同一个形状：**把"带符号的测度论"
还原为"正测度 + 可测相位"**，第 16 章 Bochner 积分的值测度
讨论将直接复用这个模板。

## 12.4 绝对连续与奇异（严书 3.3.7-3.3.8）

两符号测度 ν₁ ≪ ν₂（**绝对连续**）：|ν₂|(A) = 0 ⟹ ν₁(A) = 0；
ν₁ ⊥ ν₂（**奇异**）：存在 N 使 |ν₁|(Nᶜ) = |ν₂|(N) = 0——
**两家质量住在不相交的领地上**。注 3.3.8 的等价刻画：

- ν ≪ μ ⟺ ∀ε ∃δ：‖μ‖_var(A) < δ ⟹ |ν(A)| < ε（**ε-δ 语言**
  在 ν 有限时成立——分析学最爱的连续性表述）；
- 不定积分 f·μ ≪ μ 永远成立（∫_A f dμ 被 ∫_A |f| dμ 控制，
  绝对连续性第 10 章已证）；
- ≪ 与 ⊥ 是两个极端：**Lebesgue 分解说一切中间状态都是两极端
  的直和**。

## 12.5 Lebesgue 分解定理（严书 3.3.10）

**定理** μ、ν 为有限符号测度，则 ν 唯一分解为 ν = νˢ + νᶜ，
νˢ ⊥ μ（奇异部）、νᶜ ≪ μ（绝对连续部），且 νᶜ = g·μ 是某
g ∈ L¹ 的不定积分。

**证明的 H-类机器**（严书路线，是第 08 章函数单调类的又一实例）：
设 μ 为概率测度（3.3.9 引理：h > 0、μ(h) = 1 时 μ ~ h·μ 等价，
可先归一——第 03 章 1.3.5 概率化引理的回声）。令

  H = {h ≥ 0 可测 : ∫_A h dμ ≤ ν(A) 对一切 A ∈ 𝓕}。

- **有限上端封闭**：h₁, h₂ ∈ H 时 h₁∨h₂ ∈ H——按 [h₁ ≥ h₂]
  切 A，两段分别用 h₁、h₂ 的不等式（**DCT 家族的区间分解**）；
- **单调升封闭**：hₙ ↑ h 时 h ∈ H——MCT；
- 取 g = H 中的"最大元"（列 hₙ 使 ∫hₙ → sup），令 νˢ = ν − g·μ，
则 νˢ ≥ 0 且对一切 g′ > g（在某正测集上严格），g′ ∉ H——
推出 νˢ 集中在 μ-零测集 N 上（否则 g + ε·I_N ∈ H 突破最大性，
**ε-扰动论证**）。

## 12.6 Radon-Nikodym 定理（严书 3.3.11）

**定理** μ σ-有限测度、ν ≪ μ 符号测度，则存在（μ-a.e. 唯一的）
可测 g（积分存在）使 ν = g·μ；g 为 μ-a.e. 有限 ⟺ ν σ-有限。
g 称 **Radon-Nikodym 导数** dν/dμ。

证明是 Lebesgue 分解的直读：≪ 意味着 νˢ = 0（奇异部住在
μ-零测集上，被 ≪ 吞没），故 ν = νᶜ = g·μ。唯一性：g₁·μ =
g₂·μ ⟹ μ([g₁ ≠ g₂]) = 0（正集上积分单调严格）。

**导数类比**（为何叫导数）：链式法则 d(ν₁)/dμ₃ =
(dν₁/dμ₂)·(dν₂/dμ₃)（传递性）；换基公式 μ₂ = (dμ₂/dμ₁)·μ₁；
第 36 章条件期望 E[X|𝓖] 就是 d(X·P)|𝓖 / dP|𝓖——RN 定理是
条件概率论的发动机。反例提醒：计数测度 ≪ Lebesgue 不成立
（单点 Lebesgue 零测但计数为 1），dν/dμ 存在的前提绝不可省；
σ-有限性也不可省（经典反例：[0,1] 上 ν = 计数、μ = Lebesgue，
ν ≪ μ 但 ν 非 σ-有限——此时 g 只能取 ∞）。

## 12.7 Lean：SignedMeasure 与 rnDeriv

mathlib 的 `SignedMeasure α` 是 `VectorMeasure α ℝ` 的缩写
（VectorMeasure/Basic.lean:73）；Hahn 分解在 Measure/Decomposition/
Hahn.lean（`IsHahnDecomposition` 结构 + `exists_isHahnDecomposition`，
有限测度时存在）；Lebesgue 分解与 RN 在 Decomposition/Lebesgue.lean
与 RadonNikodym.lean（`singularPart_add_rnDeriv` 给出分解方程
ν = νˢ + rnDeriv·μ；`rnDeriv` 本体是 irreducible_def——API 纪律
与 lintegral 同款）。`Ch12SignedMeasures.lean` 以 `#check` 正名
六件套，实弹两件：

```lean
/-- 密度 ⟹ 绝对连续（注 3.3.8(2) 的机器版）。 -/
example (ν : Measure Bool) (f : Bool → ℝ≥0∞) :
    ν.withDensity f ≪ ν :=
  withDensity_absolutelyContinuous ν f

/-- RN 方程（3.3.11 机器本体）：μ = f·ν 时基测度把 μ 还原为密度。 -/
example (ν : Measure Bool) (f : Bool → ℝ≥0∞) (hf : Measurable f) :
    ν.withDensity ((ν.withDensity f).rnDeriv ν) = ν.withDensity f := by
  have := Measure.haveLebesgueDecomposition_withDensity ν hf
  exact Measure.withDensity_rnDeriv_eq (ν.withDensity f) ν
    (withDensity_absolutelyContinuous ν f)
```

写文件的实测坑账（一整串）：**`withDensity_rnDeriv_eq (μ ν)` 的
结论里"基测度"是第二个参数**（μ 才是被还原者），rnDeriv 的点记号
`μ.rnDeriv ν` 极易把方向读反；`withDensity_absolutelyContinuous`
在 `MeasureTheory` 根命名空间而 `withDensity_rnDeriv_eq` 在
`MeasureTheory.Measure`——同一 import 两级命名空间，裸名与
限定名要分开写；`HaveLebesgueDecomposition` 实例引理带
`Measurable f` 前提，类型类搜索不自动生效，须 `have` 供入
（plain have 即可，`haveI` 反被 linter 点名）；具体 dirac 项代入
会让 whnf 超心跳——通用陈述（对任意 ν）既快又更贴定理本体。

## 12.8 Isabelle：RN_deriv 正名

Isabelle 的对应物在 `HOL-Analysis.Radon_Nikodym`：常值函数
`RN_deriv M N` 的定义走 **SOME-选择子**（若密度存在则选中一个），
核心引理 `RN_derivI` 只要两条——f 可测、density M f = N——即得
`density M (RN_deriv M N) = N`（密度已存在时的良定还原）；σ-有限
的存在性与唯一性在 `RN_deriv_unique_sigma_finite` 一族。`MT12/
T12_SignedMeasures.thy` 的实弹：

```isabelle
lemma rn_deriv_restore:
  fixes f :: "nat \<Rightarrow> ennreal"
  assumes meaf: "f \<in> borel_measurable (count_space {0,1::nat})"
  shows "density (count_space {0,1::nat})
           (RN_deriv (count_space {0,1::nat}) (density (count_space {0,1::nat}) f))
       = density (count_space {0,1::nat}) f"
  by (rule RN_derivI[OF meaf refl])
```

一行还原——与 mathlib 侧 `withDensity_rnDeriv_eq` 的"≪ 吞掉奇异部"
路线互为镜像：一边从绝对连续出发，一边从密度存在出发。

## 12.9 数值实验：离散 RN 与 Hahn 的穷举验证

**Julia（`12_signed_measures.jl`）**在 Ω = {1,…,6}、μ = 计数
测度上：

- **密度还原**：取权 w = [1,2,3,4,5,6]/21，ν = w·μ；机器验证
  ν(A) = Σ_{k∈A} w_k（定义式）且"解方程求 g"的离散 RN——对
  单点集 A = {k}，g(k) = ν({k})/μ({k}) = w_k 精确还原（RN 的
  构造性证明在离散世界就是除法）；
- **Hahn 穷举**：给符号权 s = [3, −1, 2, −2, 0, 1] 定义
  ν(A) = Σs_k；穷举全部 64 个子集，验证 D = {1,3,5,6}（正权位）
  满足 Hahn 条件，且 ν⁺/ν⁻ 的 sup-定义与 ν(A∩D)/−ν(A∩Dᶜ)
  逐集合吻合——**3.3.4 的构造在有限世界完全可验**；
- **变差与达界**：|ν|(Ω) = Σ|s_k| = 9，ν 的最大最小值恰为
  ν(D) = 6、ν(Dᶜ) = −3（3.3.6 达界命题的有限版）；
- **Lebesgue 分解的退化定理**：μ = 计数测度无零测非空集 ⟹
  任何 ν 的奇异部必须为 0——有限模型里分解平凡，如实记录
  （反例需要无穷空间）。

**Python（`12_signed_measures.py`）**：Fraction 精确版同题——
密度还原、Hahn 穷举（64 集合的 ν⁺/ν⁻ 定义式 vs D-公式**逐项
相等**）、变差账 9、达界 6/−3 全部精确断言；补一条**唯一性**：
扰动 D（搬动零权位点 5）仍是 Hahn 分解——分解不唯一、正负部
唯一（两个 D 给出同一对 (ν⁺, ν⁻)）。

## 12.10 要点回顾

1. 符号测度 = 净质量；不定积分是原型（一侧有限）。实值符号测度
   自动有界（3.3.6 达界）。
2. Jordan-Hahn：ν = ν⁺ − ν⁻ 唯一，Ω = D ⊔ Dᶜ 不唯一；
   证明骨架 = 最负处 N（β 下确界逼近）+ ε-矛盾。
3. 变差 |ν| = ν⁺ + ν⁻；极分解 ν = h·|ν|（h = ±1 相位）。
4. ≪（ε-δ 语言在有限时）与 ⊥（领地分离）是两极端；Lebesgue
   分解 = 极端直和；H-类机器（上端封闭 + 单调极限 + ε-扰动）。
5. RN：σ-有限 + ≪ ⟹ dν/dμ 存在唯一；条件期望与换基的发动机；
   前提反例（计数 vs Lebesgue）与 σ-有限反例都要亲手摸过。
6. 机器侧：mathlib 的 SignedMeasure/Hahn/Lebesgue 三件套、
   Isabelle 的 RN_derivI；离散世界的 RN 就是逐点除法。

*对应示例：`examples/lean/Measuretheory/Ch12SignedMeasures.lean`、
`examples/isabelle/MT12/T12_SignedMeasures.thy`、
`examples/julia/12_signed_measures.jl`、
`examples/python/12_signed_measures.py`。*

---

上一章：[11 积分号下取极限：三大定理](11-limit-theorems.md) · 下一章：[13 Lᵖ 空间：完备性、不等式与对偶](13-lp-spaces.md)
