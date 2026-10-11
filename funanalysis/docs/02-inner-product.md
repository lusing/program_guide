# 02 · 内积空间初步

> Hilbert 空间是几何中有限维欧氏空间的抽象。它的性质非常规整，鲜有
> 惊讶——尽管无穷维的存在保证了某种程度的惊讶。——Conway，第 I 章开篇（意译）

Conway 第 I 章从最具体的结构讲起：内积。本章覆盖 §I.1 全部内容——
半内积与内积的定义、五大例子（含 ℓ²、L²、Bergman 空间）、CBS 不等式
及其判别式证明、范数的诞生、完备化，以及 Bergman 空间的完备性。

## 2.1 半内积与内积

**定义（Conway 1.1）**。设 𝔏 是 𝔽（= ℝ 或 ℂ）上的线性空间。函数
u : 𝔏 × 𝔏 → 𝔽 称为**半内积**（semi-inner product），若对一切
α, β ∈ 𝔽 与 x, y, z ∈ 𝔏：

- (a) u(αx + βy, z) = α u(x, z) + β u(y, z)（第一变元线性）；
- (b) u(x, αy + βz) = α̅ u(x, y) + β̅ u(x, z)（第二变元共轭线性）；
- (c) u(x, x) ≥ 0；
- (d) u(x, y) = u(y, x)‾（Hermitian 对称）。

**内积**（inner product）是还满足正定的半内积：

- (f) u(x, x) = 0 ⟹ x = 0。

记号：内积写作 ⟨x, y⟩。线性约定在第一变元（与 mathlib/物理学家相反
——见第 00 章 0.7 节的约定表；本章机器化全部取 𝔽 = ℝ，两种约定在
实数域上重合，正好避开地雷）。

从 (a)(d) 立刻得到：u(0, y) = u(0·0, y) = 0·u(0, y) = 0。

**为什么允许"半"？** 两个原因。其一，退化情形自然出现：例 2.1 后的
习题 6 表明，半内积商掉退化子空间 M = {x : u(x,x) = 0} 后就得到内积
——这与"半范数商掉零化子得范数"（第 20 章）完全平行。其二，半内积
是 CBS 不等式的自然土壤：不等式对半内积就成立，不需要正定性。mathlib
在 2025 年的重构中引入了 `PreInnerProductSpace.Core`，字段恰好就是
Conway 1.1 的 (a)(d) 加半正定——定义的"半"字在机器世界里同样有一席
之地。`examples/lean/Funanalysis/Ch02InnerProduct.lean` 的结尾用

```lean
#print PreInnerProductSpace.Core
```

打印这个结构：四个字段 `conj_inner_symm`、`re_inner_nonneg`、`add_left`、
`smul_left` 与 Conway 的 (d)(c)(a)(共轭线性) 一一对应。

**例（Conway 1.2）**。𝔏 = 有限支撑数列全体。则
u((αₙ),(βₙ)) = Σ αₙ² βₙ²（平方项做逐项乘积）是半内积而非内积；
而 ⟨(αₙ),(βₙ)⟩ = Σ αₙ βₙ 与 ⟨(αₙ),(βₙ)⟩ = Σ αₙ βₙ / n² 都是内积。
这个例子的价值在习题 4：把 𝔏 在这两个内积下完备化，分别得到 ℓ² 与
加权 ℓ²——**完备化把不同的内积送到不同的 Hilbert 空间**。

**例（Conway 1.3）**。L²(μ)：测度空间 (X, Σ, μ) 上平方可积函数，
⟨f, g⟩ = ∫ f ḡ dμ。这是泛函分析最重要的例子族。其内积的良定义性
（积分收敛）由 Hölder 不等式保证——而 Hölder 在 p = q = 2 的情形
恰好就是下面的 CBS 不等式（Conway 的原文正是这么安排的：CBS 是根，
Hölder 是叶）。

**例（Conway 1.7）**。ℓ²(I)：任意指标集 I 上满足 Σᵢ |x(i)|² < ∞ 的
函数 x : I → 𝔽（至多可数个非零值自动成立），⟨x, y⟩ = Σᵢ x(i) ȳ(i)。
I = ℕ 时记作 ℓ²。若给 I 配上计数测度，ℓ²(I) = L²(I, P(I), μ)——
两族例子在此汇合。

**例（Conway 1.8）**。𝔍 = 绝对连续、f(0) = 0、f′ ∈ L²[0,1] 的函数，
⟨f, g⟩ = ∫ f′(t) ḡ′(t) dt。这个例子出现在 Sturm-Liouville 理论
（第 12 章）的前置。注意内积用的是**导数**——函数空间的自同构把
内积结构搬来搬去，这是泛函分析的常规操作。

**例（Conway 1.10）**。Bergman 空间 L²ₐ(G)：开集 G ⊆ ℂ 上平方可积的
解析函数全体，⟨f, g⟩ = ∫_G f ż dA。解析性与 L² 的联姻出人意料地
富有成果，见 2.5 节。

## 2.2 CBS 不等式：判别式证明

**定理（Cauchy-Bunyakowsky-Schwarz，Conway 1.4）**。半内积空间上

|⟨x, y⟩|² ≤ ⟨x, x⟩·⟨y, y⟩，

且等号成立当且仅当 βx + αy 与自己正交（即 βx + αy = 0，对某个不全
为零的 α, β；具体地：x, y 线性相关）。

**证明**（Conway 原文路线）。对任意 α ∈ 𝔽：

0 ≤ ⟨x - αy, x - αy⟩ = ⟨x,x⟩ - α⟨y,x⟩ - ᾱ⟨x,y⟩ + |α|²⟨y,y⟩。

设 ⟨y,x⟩ = b e^{iθ}（b ≥ 0），取 α = e^{-iθ}t（t ∈ ℝ）。代入：

q(t) := ⟨x,x⟩ - 2bt + t²⟨y,y⟩ ≥ 0 对一切实数 t。

这是开口向上的二次多项式且处处非负，故至多一个实根，判别式非正：
0 ≥ 4b² - 4⟨x,x⟩⟨y,y⟩，即 b² = |⟨x,y⟩|² ≤ ⟨x,x⟩⟨y,y⟩。∎

这个证明的几何本质：把内积"沿 y 方向投影"得到的二次型半正定。取
t = b/⟨y,y⟩（q 的顶点）一步得到 b²/⟨y,y⟩ ≤ ⟨x,x⟩——机器化时我们
就用顶点值，省掉判别式的概念负担。

**推论（Conway 1.5）**。定义 ‖x‖ = ⟨x,x⟩^½，则：

- (a) 三角不等式 ‖x + y‖ ≤ ‖x‖ + ‖y‖；
- (b) 齐性 ‖αx‖ = |α|‖x‖；
- (c) 内积时正定：‖x‖ = 0 ⟹ x = 0。

**极化恒等式**（polar identity，贯穿全书的计算引擎）：

‖x + y‖² = ‖x‖² + 2 Re⟨x, y⟩ + ‖y‖²。

(a) 的证明：‖x+y‖² 展开，用 CBS 压掉交叉项 Re⟨x,y⟩ ≤ |⟨x,y⟩| ≤
‖x‖‖y‖，得 ‖x+y‖² ≤ (‖x‖+‖y‖)²，开方。

**度量诞生**：d(x, y) = ‖x - y‖ 是度量（三角不等式正是 (a)），内积
空间自动成为度量空间，且内积作为双线性函数对其度量连续（习题）。

## 2.3 Hilbert 空间：完备性登场

**定义（Conway 1.6）**。**Hilbert 空间** ℋ 是带内积的线性空间，且在
诱导度量下完备。

标准例子：𝔽^d、L²(μ)、ℓ²(I) 都完备（L² 的完备性是测度论的标准
结果，Riesz-Fischer 定理）。

**不完备怎么办？——完备化定理（Conway 1.9）**。内积空间关于诱导
度量的完备化上有唯一的内积延拓原内积，使之成为 Hilbert 空间。

证明思路：度量完备化（等距嵌入稠密）后，用内积的连续性（‖⟨xₙ,yₙ⟩ -
⟨x,y⟩‖ ≤ …由 CBS 控制）把内积延拓到极限点；极化恒等式保证唯一。
细节见习题 5。这一步在 mathlib 里对应 `Mathlib.Analysis.InnerProductSpace.Completion`
（内积空间的完备化仍是内积空间）。

## 2.4 Bergman 空间：一个"意外"的 Hilbert 空间

解析函数按面积测度平方可积，这样的空间为什么完备？Conway 给出的
证明是"解析性的刚性 + L² 完备性"的漂亮组合，值得完整讲述。

**引理（均值性质→积分形式，Conway 1.11）**。f 在 B(a; r) 附近解析，
则 f(a) = (1/πr²)∫_{B(a;r)} f dA。

**证明**。均值性质 f(a) = (1/2π)∫₀^{2π} f(a + te^{iθ}) dθ（对 0 < t
≤ r）关于 t 加权 2t/r² 积分，左边为 f(a)·(2/r²)∫₀^r t dt = f(a)，
右边化为面积分。∎

**推论（点值被范数控制，Conway 1.12）**。f ∈ L²ₐ(G)，a ∈ G，
0 < r < dist(a, ∂G)，则

|f(a)| = |⟨f, 1⟩_{B(a;r)}|/πr² · πr² ≤ ‖f‖_{L²(B(a;r))}/(r√π) ≤ ‖f‖/(r√π)。

第二步正是 CBS！**解析函数在 Bergman 空间里，点值是连续线性泛函**
——这是"再生核"（reproducing kernel）现象的雏形（mathlib 已有
`Analysis.InnerProductSpace.Reproducing` 一族理论）。

**定理（Conway 1.13）**。L²ₐ(G) 是 G 上闭子空间，从而完备。

**证明**。设 fₙ ∈ L²ₐ(G)，‖fₙ - f‖₂ → 0。上述点值估计给出：在任何
紧子圆盘上 |fₙ(z) - fₘ(z)| ≤ C‖fₙ - fₘ‖₂，即 (fₙ) 在紧集上一致
柯西，一致收敛到某解析 g。另一方面 L² 收敛有 a.e. 收敛子列（Riesz
定理），其极限须等于 g a.e.，故 f = g a.e.，f 解析。∎

## 2.5 机器化：Lean 里逐步复现

`examples/lean/Funanalysis/Ch02InnerProduct.lean` 是本章的机器化身。
第一件事是极化恒等式（后面一切展开的地基）：

```lean
theorem fa_polar (x y : F) : ‖x + y‖ ^ 2 = ‖x‖ ^ 2 + 2 * ⟪x, y⟫_ℝ + ‖y‖ ^ 2 := by
  have h : ⟪x + y, x + y⟫_ℝ = ⟪x, x⟫_ℝ + ⟪x, y⟫_ℝ + ⟪y, x⟫_ℝ + ⟪y, y⟫_ℝ :=
    inner_add_add_self x y
  rw [← real_inner_self_eq_norm_sq (x + y), h, ← real_inner_self_eq_norm_sq,
    ← real_inner_self_eq_norm_sq, real_inner_comm y x]
  ring
```

读法：目标是范数平方的等式；`real_inner_self_eq_norm_sq`（范数平方
= 自内积）把两侧统一到内积语言；`inner_add_add_self` 做双线性展开；
`real_inner_comm` 把 ⟨y, x⟩ 换成 ⟨x, y⟩（实数域上 Hermitian 对称
退化为交换）；剩下的纯环等式交给 `ring`。**"分析等式 = 引理改名 +
环等式"**——这是 Lean 处理初等不等式之外恒等式的标准范式。

然后是 CBS 的完整手工证明：

```lean
theorem fa_cbs_real (x y : F) : ⟪x, y⟫_ℝ ^ 2 ≤ ‖x‖ ^ 2 * ‖y‖ ^ 2 := by
  have expand : ∀ t : ℝ,
      ⟪x - t • y, x - t • y⟫_ℝ = ‖y‖ ^ 2 * t ^ 2 - 2 * ⟪x, y⟫_ℝ * t + ‖x‖ ^ 2 := by
    intro t
    rw [inner_sub_left, inner_sub_right, real_inner_smul_left, real_inner_smul_left,
      real_inner_smul_right, real_inner_smul_right, ← real_inner_self_eq_norm_sq,
      ← real_inner_self_eq_norm_sq]
    ring
  by_cases hy : y = 0
  · subst hy; simp
  · have hpos : 0 < ‖y‖ ^ 2 := by
      have h1 : ⟪y, y⟫_ℝ ≠ 0 := fun h => hy (inner_self_eq_zero.mp h)
      rw [real_inner_self_eq_norm_sq] at h1
      exact lt_of_le_of_ne (by positivity) (Ne.symm h1)
    have hnonneg : 0 ≤ ‖y‖ ^ 2 * (⟪x, y⟫_ℝ / ‖y‖ ^ 2) ^ 2
        - 2 * ⟪x, y⟫_ℝ * (⟪x, y⟫_ℝ / ‖y‖ ^ 2) + ‖x‖ ^ 2 := by
      rw [expand (⟪x, y⟫_ℝ / ‖y‖ ^ 2)]
      exact inner_self_nonneg (𝕜 := ℝ)
    field_simp
    nlinarith [hpos]
```

结构与纸笔证明逐行对应：`expand` 是二次三项式展开（四个内积线性
引理 + ring）；y = 0 平凡；y ≠ 0 时 ‖y‖² > 0（正定性 `inner_self_eq_zero`
的用武之地），在顶点 t₀ = ⟪x, y⟫/‖y‖² 处取值非负（`inner_self_nonneg`），
最后 `field_simp`（通分，除法变乘法，用到 ‖y‖² ≠ 0）+ `nlinarith`
（非线性线性算术：从 a > 0 与 c ≥ b²/a 推出 ac ≥ b²）。

两个新 tactic 值得记住：`field_simp` 处理"有分母的等式/不等式"，
自动找非零分母条件；`nlinarith` 是 `linarith` 的非线性版，会尝试
把假设里的多项式乘起来。**判别式论证在机器里就变成了这两个黑盒
之间的两行桥**。

三角不等式（`fa_triangle`）用同样的配方：CBS 给出 ⟨x,y⟩ ≤ ‖x‖‖y‖
（用 `le_of_sq_le_sq` 去绝对值），极化恒等式平方展开，`nlinarith`
收尾，最后开方用 `Real.sqrt_le_sqrt`。文末还引用了 mathlib 的一般
形式 `real_inner_mul_inner_self_le` 作对照——**手工版证明"为什么"，
库版供"以后引用"**，两条腿走路。

Hilbert 空间的例子在机器里是实例搜索：

```lean
example {n : ℕ} : CompleteSpace (EuclideanSpace ℝ (Fin n)) := by infer_instance
example : CompleteSpace (lp (fun _ : ℕ => ℂ) 2) := by infer_instance
```

第二行就是 ℓ²（mathlib 记号 `lp (fun _ : ℕ => ℂ) 2`，即 Π 型 L²）。
"ℓ² 是 Hilbert 空间"这条 Conway 习题 2，机器一行拿下——完备化与内积
的实例路径已经在库里。

## 2.6 机器化：Isabelle 的同一条路

`examples/isabelle/FA02/T02_InnerProduct.thy` 用 Isar 把同一组定理写了一遍。
CBS 的 Isar 版本结构尤其清晰（Isar 的设计初衷就是"证明叙事"；这里
q 直接取内积形式，收尾全程只用乘法，避开除法条件分支）：

```isabelle
lemma fa_cbs:
  fixes x y :: "'a::real_inner"
  shows "(inner x y)\<^sup>2 \<le> (norm x)\<^sup>2 * (norm y)\<^sup>2"
proof (cases "y = 0")
  case True
  then show ?thesis by simp
next
  case False
  define q where "q = (\<lambda>t::real. inner x x - 2 * t * inner x y + t * t * inner y y)"
  have qpos: "0 \<le> q t" for t
  proof -
    have "0 \<le> inner (x - t *\<^sub>R y) (x - t *\<^sub>R y)"
      using inner_ge_zero by blast
    moreover have "inner (x - t *\<^sub>R y) (x - t *\<^sub>R y) = q t"
      unfolding q_def
      by (simp add: inner_diff_left inner_diff_right inner_scaleR_left
          inner_scaleR_right inner_commute algebra_simps)
    ultimately show "0 \<le> q t" by simp
  qed
  ...
```

注意 `define q where`（局部定义带折叠）与 `have qpos: "0 \<le> q t" for t`
（通用量化的事实）这两个 Isar 惯用法——它们让证明的"变量结构"与
纸笔完全同构。两个系统证明同一条定理、同一个思路、两种叙事语法，
这就是"对拍"的教育价值：**读者看到的不是"某个系统的怪癖"，而是
数学本身**。

## 2.7 数值实验

三个实验（`examples/julia/02_inner.jl` 与 `examples/python/02_inner.py`）：

**实验 1：CBS 的等号与高维巧合。** 线性相关时比值
|⟨x,y⟩|/(‖x‖‖y‖) 恒为 1；随机向量则严格小于 1——但注意，维数越高
随机向量越"接近正交"（均值约 √(2/πn)）。实测 dim=300 时平均 |cos|
≈ 0.046。**高维空间里正交是常态**——这解释了为什么随机矩阵方法
（第 32 章紧算子数值）如此有效。

**实验 2：Bergman 范数的精确对照。** f(z) = z^k 在单位圆盘的 Bergman
范数平方是 π/(k+1)（极坐标直接积分）。Julia 用极坐标蒙特卡洛，
Python 用 `scipy.integrate.quad`，双双对上解析值。Monte Carlo 误差
~1/√N，quad 达到机器精度——两条数值通道的精度梯队由此建立。

**实验 3：半内积的退化与商。** Julia 里定义 u(x,y) = x₁ȳ₁ + x₂ȳ₂
（忽略第三坐标）：u(deg, deg) = 0 而 deg ≠ 0，退化子空间 M = {x :
x₁ = x₂ = 0}。两个只差 M 中向量的代表元给出相同的"商内积"——
习题 6 的构造在数值里"摸得到"。

## 2.8 章末对照表

| Conway | 内容 | Lean | Isabelle | Julia/Python |
|---|---|---|---|---|
| 1.1 | 半内积/内积定义 | `#print PreInnerProductSpace.Core` | — | 实验 3 |
| 1.2/1.7 | 例子、ℓ² | `infer_instance` ×3 | — | — |
| 1.4 | CBS | `fa_cbs_real`（手工）+ 库版 | `fa_cbs`（Isar） | 随机验证 |
| 1.5 | 极化/三角 | `fa_polar`, `fa_triangle` | `fa_polar`, `fa_triangle` | 三角随机验证 |
| 1.9 | 完备化 | （库：`Completion`） | — | — |
| 1.10-1.13 | Bergman | （库：`Reproducing`） | — | π/(k+1)、均值性质 |

## 2.9 习题

1. **（纸笔）** 补出 CBS 等号条件的证明（Conway 留给读者）。
2. **（纸笔）** 证明例 1.8 的 𝔍 完备（提示：f ↦ f′ 是 𝔍 到 L² 的一个
   子空间上的等距双射）。
3. **（纸笔）** 习题 6：半内积的退化子空间 M 是线性子空间，且
   ⟨x+M, y+M⟩ := u(x, y) 良定义，使 𝔏/M 成为内积空间。
4. **（机器）** 在 Lean 里把 `fa_cbs_real` 的等号情形补成 iff 陈述
   （参考 mathlib 的 `norm_inner_eq_norm_iff` 族）。
5. **（机器）** 在 Isabelle 里给 `fa_polar_sub`（‖x - y‖² 的展开）补
   一个证明，并用它重新导出平行四边形恒等式。
6. **（数值）** 习题 4 的机器版：数值上把例 1.2 的两个内积空间完备化
   ——取有限支撑列的截断列，观察两组范数的增长与极限空间的差异。

---

上一章：[01 prelim](docs/01-prelim.md) · 下一章：[03 orthogonality](docs/03-orthogonality.md)
