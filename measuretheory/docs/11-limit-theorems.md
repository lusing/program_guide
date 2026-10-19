# 11 积分号下取极限：三大定理

**对应严书 §3.2（pp. 49-52）。**

---

## 11.1 问题的形状

分析学的一切"交换极限与积分"的企图，都要回答同一个问题：**凭什么
∫lim 可以写成 lim∫？** Riemann 积分里这是的一致收敛的专利；Lebesgue
理论把专利品变成大宗商品——三大定理（单调收敛 MCT、Fatou 引理、
控制收敛 DCT）给出三个越来越实用的充分条件，彼此之间又能互相推导。
严书的呈现顺序是 MCT（3.2.1）→ 系（逐项求和）→ Fatou（3.2.4）→
DCT（3.2.5）→ 两个推广（3.2.6 单边控制、3.2.7 三明治）——本教程
保持这条线，并在数值通道把每个定理的"假设破坏即结论失效"做成
可运行的反例。

## 11.2 单调收敛定理（MCT，严书 3.2.1）

**定理** 设 fₙ ≥ 0 可测。

1. （上行）fₙ ↑ f（a.e.）⟹ μ(fₙ) ↑ μ(f)；
2. （下行）fₙ ↓ f（a.e.）且 μ(f₁) < ∞ ⟹ μ(fₙ) ↓ μ(f)。

**上行证明的对角线技巧**（严书原法）：对每个 n 取 S⁺ 逼近列
fₙ,m ↑ fₙ（m → ∞），令 gₘ = max_{i≤m} fᵢ,m ∈ S⁺。则 gₘ ↑ f
（每个 fₙ 都被某支 g 追上：fₙ ≤ g_m for m ≥ n）且 gₘ ≤ fₘ。
于是 μ(f) = lim μ(gₘ) ≤ liminf μ(fₘ) ≤ limsup μ(fₘ) ≤ μ(f)
（最后一步用逐点 fₘ ≤ f）。**"先到整数格点再取对角线"是全书
重复率最高的证明动作之一**——第 10 章的良定义性、第 18 章 Fubini
的迭代积分、第 36 章条件期望的存在性，全是它的变奏。

**下行的有限性条件不可省**：反例 fₙ = I_{[n,∞)}，在 ℝ 上
μ(fₙ) = ∞ 对一切 n，而 f = 0、μ(f) = 0——∞ 序列可以一路 ∞ 地
"下降"到 0。下行的证明把 f₁ 的有限性折成"减去有限量后用上行"：
令 gₙ = f₁ − fₙ ≥ 0 单调升（这要求 fₙ ≤ f₁ 且处处有意义，
μ([f₁ = ∞]) = 0 由 μ(f₁) < ∞ 保证）。

**系（逐项求和，3.2.2）**：μ(Σfₙ) = Σμ(fₙ)（非负项级数与积分
自由换序）——对部分和列用上行即得。这是"非负性第一次付大额账单"。

## 11.3 Fatou 引理（严书 3.2.4）

**定理** fₙ ≥ 0 可测 ⟹ μ(liminf fₙ) ≤ liminf μ(fₙ)。

证明一行：gₖ = inf_{n≥k} fₙ 单调升到 liminf fₙ，对 gₖ 用 MCT 上行
（μ(gₖ) ≤ inf_{n≥k} μ(fₙ) 由单调性），两边取极限。

**严格不等式的标准反例（滑动脊）**：fₙ = I_{[n,n+1]}，liminf fₙ = 0
（每点至多一次被脊压住）而 μ(fₙ) = 1 恒成立——0 = μ(liminf) <
liminf μ = 1。解读：**质量可以在空间里"搬家"而总量不减**——
Fatou 是"质量只会在极限中蒸发、不会凭空增加"的定量记账。

## 11.4 控制收敛定理（DCT，严书 3.2.5）

**定理** fₙ → f（a.e. 或依测度），|fₙ| ≤ g 且 g 可积，则 f 可积
且 μ(fₙ) → μ(f)。

**证明路线是第 09 章子列刻画的直接兑换**（严书原法）：a.e. 情形由
Fatou 直接拿下（0 ≤ fₙ + g、g − fₙ 都非负，两次 Fatou 夹出
limsup μ(fₙ) ≤ μ(f) ≤ liminf μ(fₙ)）；依测度情形用 2.3.4(3)/2.3.5：
任一子列有子列 a.e. 收敛到 f，故子列积分极限恒为 μ(f)，由子列
任意性得全列收敛。**"依测度收敛的处理 = 提取 a.e. 骨架"**——第
09 章的 Riesz 定理在此处收割第一茬。

**无控制的反例（逃逸尖峰）**：fₙ = n·I_{(0,1/n)} 逐点 → 0（每
x > 0 最终为 0），但 μ(fₙ) = 1 ↛ 0。|fₙ| 的"上确界函数" supₙ|fₙ|
在 (0,1) 附近无界，不可积——控制假设破坏的方式是**尖峰虽窄但
高度无限增长**。数值通道里这台机器与第 09 章共用。

## 11.5 推广形态：单边控制与三明治（3.2.6 / 3.2.7）

**3.2.6（Fatou 的可积版）**：fₙ 积分存在，fₙ ≥ g a.e. 且
μ(g) > −∞ ⟹ μ(f) ≤ liminf μ(fₙ)（下控）；对称地得上控。负方向
的"有限垫底"g 扮演非负情形里 0 的角色——证明对 fₙ − g 用 Fatou。

**3.2.7（三明治 DCT）**：hₙ ≤ fₙ ≤ gₙ a.e.，hₙ → h、gₙ → g
（a.e. 或依测度），h、g、hₙ、gₙ 可积且 μ(hₙ) → μ(h)、μ(gₙ) → μ(g)
⟹ f 可积且 μ(fₙ) → μ(f)。习题 3.2.1 的提示即证明：对 fₙ − hₙ
与 gₙ − fₙ 分别用 Fatou。特例 hₙ = 0、gₙ → 0（习题 3.2.2）给出
**L¹ 收敛版**：μ(|fₙ − f|) → 0。DCT 本体只给积分值收敛，L¹ 收敛
是其对 |fₙ − f| 的应用——第 38 章一致可积把这条线推到 Vitali
定理的完整形态。

**习题 3.2.3（逐项积分定理）**：若 Σₙ μ(|fₙ|) < ∞（或非负情形
Σ μ(fₙ) < ∞），则 μ(Σfₙ) = Σμ(fₙ) 且逐项积分合法——绝对可和性
是"无穷次换序"的又一张通行证。证明骨架：部分和列 Sₙ = Σₖ≤ₙfₖ
满足 |Sₙ| ≤ Σ|fₖ| =: g 可积，DCT 一行收割；非负情形走 11.2 的
系。这张通行证在第 35 章 Borel-Cantelli 引理的推广、第 49 章
强大数定律的证明里都是关键一步。

## 11.6 三定理的关系网

- MCT ⟹ Fatou（gₖ = inf 尾列的单调化），Fatou ⟹ DCT（正负两部
  各夹一次）。
- DCT ⟹ MCT（部分场景）：fₙ ↑ f、μ(f₁) < ∞ 时以 f 为控制……但
  MCT 上行不需要任何有限性——**上行 MCT 是三者中最原始的**，
  Fatou 与 DCT 都以它为根。
- 反例分工：滑动脊杀 Fatou 等号、逃逸尖峰杀 DCT、I_{[n,∞)} 杀
  MCT 下行——三台反例机在 Julia/Python 通道各就各位。

## 11.7 Lean：三件套正名与两发实弹

`Ch11LimitTheorems.lean` 以 `#check` 锚定四条机器件：
MCT 的 `lintegral_iSup`（⨆ 形式）与 `lintegral_tendsto_of_
tendsto_of_monotone`（极限形式，Add.lean:113）；Fatou 的
`lintegral_liminf_le`（Add.lean:231）；DCT 的
`tendsto_integral_of_dominated_convergence`（DominatedConvergence.lean:57，
Bochner 值）。

实弹一发（MCT）：狄拉克质量上的 fₙ = n ⊓ 1 常值列单调升到 1。
单调性与"最终为 1"的逐点极限是干净的手工件，机器定理一口吞下：

```lean
example : Tendsto (fun n => ∫⁻ _ : Bool, ((n : ℕ) : ℝ≥0∞) ⊓ 1
    ∂(Measure.dirac true)) atTop (𝓝 1) := by
  have key := lintegral_tendsto_of_tendsto_of_monotone
    (f := fun n (_ : Bool) => ((n : ℕ) : ℝ≥0∞) ⊓ 1) (F := fun _ => (1:ℝ≥0∞))
    (fun _ => measurable_const.aemeasurable)
    (ae_of_all (Measure.dirac (true : Bool)) fun _ i j hij =>
      min_le_min (by exact_mod_cast hij) le_rfl)
    (ae_of_all (Measure.dirac (true : Bool)) fun _ =>
      Tendsto.congr' (…eventually (min_eq_right …).symm…) tendsto_const_nhds)
  rwa [hfin] at key
```

实弹二发（DCT）：[0,1] 上 ∫xⁿ → 0，四件套（AEStronglyMeasurable、
可积控制 1、a.e. 控制 |xⁿ| ≤ 1、a.e. 极限）逐项喂给
`tendsto_integral_of_dominated_convergence`；a.e. 极限的坏集
∩[0,1] = {1} 由 `measure_mono_null` 清零——与第 09 章 Egorov
实弹同一套零测集动作。

写文件的实测坑账：`Tendsto.congr'` 的等式方向是 **f₁ =ᶠ f₂ 配
Tendsto f₁ 产 f₂**（与直觉相反，等式要 .symm 垫）；`ae_of_all`
的位置参数 μ 在定理应用的参数位上推不出来，须显式给；
`Measure.restrict_apply'` 要显式喂 MeasurableSet；ℝ 的
xⁿ ≤ 1 走 `pow_le_pow_left₀`（带 0 ≤ x），配 `one_pow` 收尾。

## 11.8 Isabelle：Fatou 正名与有限链账目

`MT11/T11_LimitTheorems.thy` 两件事：其一，Isabelle 的 Fatou 是
**`nn_integral_liminf`**（非负层，与 mathlib 的 `lintegral_liminf_le`
互为镜像），引用实例走 `proof (rule nn_integral_liminf)` +
measurability 副条件（`by measurable` 在 count_space 上一行通过）：

```isabelle
lemma fatou_const_eq:
  "(\<integral>\<^sup>+x. liminf (\<lambda>n::nat. indicator {1::nat} x)
      \<partial>count_space {0,1::nat})
   \<le> liminf (\<lambda>n. (\<integral>\<^sup>+x. indicator {1::nat} x \<partial>count_space {0,1}))"
proof (rule nn_integral_liminf)
  show "\<And>i. (\<lambda>x. indicator {1::nat} x) \<in> borel_measurable (count_space {0,1::nat})"
    by measurable
qed
```

其二，有限链的单调收敛显式账：f₁ = 0、f₂ = I{1}、f₃ = I{0}+I{1}
的积分列 0 ≤ 1 ≤ 2（`nn_integral_count_space_finite` 三连，逐项
simp）。Bochner 层的单边控制收敛在 Isabelle 侧名为
`integral_dominated_convergence`，第 16 章随 Bochner 积分一起
实弹。

## 11.9 数值与逻辑实验

**Julia（`11_limit_theorems.jl`）**三台反例机 + 一台正例机：

- **MCT 下行破坏**：fₙ = I_{[n,n+10]}（截断窗口 [0,100] 内）：
  每项窗口测度 10，逐点极限 0——μ(fₙ) ↛ 0 的窗口口径账；
- **Fatou 严格**：滑动脊 fₙ = I_{[n,n+1]}：μ(liminf) = 0 vs
  liminf μ = 1，严格差距精确记录；
- **DCT 无控制**：逃逸尖峰 n·I_{(0,1/n)}：数值积分 ∫ = 1 恒定
  vs 逐点极限 0（前 200 项的积分值全为 1）；
- **DCT 正例**：fₙ = xⁿ·I_{[0,1]}：∫ = 1/(n+1) → 0，与第 11.7
  的 Lean 结论对拍（simp/norm_num 的浮点版）。

**Python（`11_limit_theorems.py`）**：Fraction 精确版——∫xⁿ =
1/(n+1) 的精确分数序列、尖峰积分恒等于 1、Fatou 差距 = 1 的
精确断言；MCT 下行反例的截断窗口口径同样精确记账。

**Prolog（`11_limit_theorems.pl`）**：有限格上的三定理"退化检查"——
有限概率空间上非负可测列的 MCT 上行（对有限链平凡成立）、Fatou
恒等式（有限值域上 liminf 可精确计算）、DCT 的控制条件逐点核对；
如实记录：有限模型无法复现三大定理的任何反例（反例全部依赖
无穷测度或无界性）——与第 09 章的退化定理一脉相承。

## 11.10 要点回顾

1. MCT 上行 = 对角线技巧（gₘ = max_{i≤m} fᵢ,m）；下行要 μ(f₁)
   有限（减法垫底）。
2. Fatou = "质量只蒸发不增加"的记账；滑动脊是标准严格反例。
3. DCT = 可积控制 + 任意收敛方式（a.e./依测度）；证明靠子列刻画
   兑换；逃逸尖峰是无控制的标准反例。
4. 推广形态：单边控制（3.2.6，有限垫底 g）与三明治（3.2.7，
   习题 3.2.1 的 Fatou 双夹）——L¹ 收敛版是通往第 38 章 Vitali
   的桥。
5. 机器侧：MCT/Fatou 在 lintegral 层、DCT 在 Bochner 层各就各位；
   子列刻画是"依测度版"证明的通用兑换器。

*对应示例：`examples/lean/Measuretheory/Ch11LimitTheorems.lean`、
`examples/julia/11_limit_theorems.jl`、`examples/python/11_limit_theorems.py`、
`examples/prolog/11_limit_theorems.pl`。*
