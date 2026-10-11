# 06 · 同构分类、圆周 Fourier 变换与直和

> 所有可分无穷维 Hilbert 空间彼此同构——它们都是 ℓ² 换了件衣服。

本章覆盖 Conway §I.5-§I.6：同构的概念与分类定理、圆周上的 Fourier
变换（Parseval 的函数版）、Hilbert 直和。这是第 I 章的收官：读完
本章，"Hilbert 空间 = ℓ²(某个指标集)" 这句话成为定理。

## 6.1 同构：保内积的双射

**定义（Conway 5.1）**。Hilbert 空间 ℋ 与 K 之间的**同构**是保持
内积的线性双射 U：⟨Uh, Ug⟩ = ⟨h, g⟩。（保内积 ⟹ 保范数 ⟹ 自动
连续；线性 + 双射。）有时也叫**酉算子**（unitary）。

**命题（Conway 5.2）**。线性映射 V: ℋ → K 是同构 ⟺ V 保持内积。
特别地，同构的复合与逆都是同构。

**例（Conway 5.3）**。**单侧移位** S: ℓ² → ℓ²，S(α₁,α₂,…) =
(0,α₁,α₂,…)。S 是等距（‖Sα‖ = ‖α‖）但**不是**同构（不满：第一个
坐标总是 0）。S 是本章与第 08 章（S* = 后移）的公共主角——
"等距未必酉"的标准反例。

## 6.2 分类定理

**定理（Conway 5.4）**。两个 Hilbert 空间同构 ⟺ 它们的维数（基的
势）相同。

**证明**。取基 (eᵢ)_{i∈I} 与 (fⱼ)_{j∈J}。同构把基映为基，故
|I| = |J|。反之，双射 σ: I → J 诱导 U(Σαᵢeᵢ) = Σαᵢf_{σ(i)}，
这是良定义的保内积双射（Parseval 保证系数与范数完全对应）。∎

**推论（Conway 5.5）**。所有可分无穷维 Hilbert 空间同构于 ℓ²。
ℓ²、L²[0,2π]、Bergman 空间——结构上没有区别，区别只在于基的选择。

## 6.3 圆周上的 Fourier 变换（Conway 5.6-5.11）

设 ∂𝔻 = ℝ/2πℤ，测度取规范化 Lebesgue。对 n ∈ ℤ 定义
eₙ(t) = (2π)^{-1/2}e^{int}。

- **5.7**：(eₙ)_{n∈ℤ} 是 L²(∂𝔻) 中的标准正交系（直接积分）。
- **5.8-5.9**：三角多项式在 L² 中稠密（Stone-Weierstrass 的前身：
  先用 Fejér 核做一致逼近，再过渡到 L²）。
- **5.10**：稠密 + 标准正交 ⟹ **基**（第 05 章 4.13 (f)）。
- **5.11**：Fourier 变换 f ↦ f̂(n) = ⟨f, eₙ⟩ 是 L²(∂𝔻) 到 ℓ²(ℤ)
  的**同构**；Parseval：Σ|f̂(n)|² = ‖f‖²。

这是第一个非平凡的分类实例：L²(∂𝔻) ≅ ℓ²(ℤ)，同构的具体实现就是
Fourier 变换。历史上 Hilbert 空间概念正是从 Fourier 级数的收敛
问题中生长出来的。

**Gibbs 现象的警告**（数值通道会演示）：Parseval 是 **L² 收敛**，
不保证逐点收敛；在跳跃点，Fourier 部分和有约 9% 的固定超调。

## 6.4 Hilbert 直和（Conway 6.1-6.4）

给定 Hilbert 空间族 (ℋᵢ)，**直和** ⊕ℋᵢ = {(hᵢ) : Σ‖hᵢ‖² < ∞}，
内积 ⟨(hᵢ),(gᵢ)⟩ = Σ⟨hᵢ,gᵢ⟩（由 CBS 收敛）。它是 Hilbert 空间，
且 dim(⊕ℋᵢ) = Σ dim ℋᵢ（势和）。两个空间的情形就是
‖(h,k)‖² = ‖h‖² + ‖k‖²——勾股形式写成定义。

**证明梗概**（完备性）：Cauchy 列 (hⁿ) 在直和范数下，每个坐标
Cauchy（‖hⁿᵢ − hᵐᵢ‖ ≤ ‖hⁿ − hᵐ‖），取坐标极限 hᵢ；再由 Fatou 型
论证（部分和的范数下极限控制极限的范数）得 h ∈ ⊕ℋᵢ 且 hⁿ → h。
∎

**例**。ℓ² 本身就是 ⊕_{n∈ℕ} 𝔽（每个分量一维）；L²(∂𝔻) ≅ ⊕_{n∈ℤ} 𝔽
——同一空间的两种直和分解，差别只在指标集。反过来（Conway 6.2 的
习题方向）：不同指标集给出不同构的直和——维数是唯一的同构不变量。

直和是后面一切"分块"构造的载体：第 09 章的约化子空间分解
ℋ = ℳ ⊕ ℳ⊥、第 39 章 von Neumann 代数的直和分解、多重性理论的
ℓ²-直和指标，全是这一个构造的重复使用。

## 6.5 历史注记：Hilbert 空间从哪里来

Parseval 等式（1799 年，关于三角级数）比 Hilbert 空间的公理化
（1900 年代，Hilbert、von Neumann、Riesz）早了一百年。路线是：
Fourier 级数的收敛问题 → Bessel/Parseval 的能量恒等式 →
"平方可和"作为自然的函数类 → 无穷维欧氏几何的公理化。
本章的逻辑顺序（空间 → 基 → Fourier）恰好是历史顺序的倒放：
数学家先有了 Fourier 分析，才提炼出让它运转的舞台。

Schmidt 与 Hilbert 在积分方程研究中把 ℓ² 的"无穷多个坐标"概念
公理化；von Neumann 在量子力学（1927-1932）中需要可分无穷维
Hilbert 空间的唯一性（Conway 5.5）作为态空间的数学基础。
分类定理不是象牙塔里的抽象——它是量子力学公理体系的地基。

## 6.5 机器化：Lean

`examples/lean/Funanalysis/Ch06Isomorphism.lean`：

```lean
-- 同构 = 保内积（LinearIsometry.inner_map_map）
#check @LinearIsometry.inner_map_map

-- 分类定理的承载者：HilbertBasis.repr 是到 ℓ²(ι) 的等距同构
example (b : HilbertBasis ι ℝ E) : E ≃ₗᵢ[ℝ] lp (fun _ : ι => ℝ) 2 := b.repr
```

mathlib 的 `HilbertBasis` 定义就是"Conway 5.4 的可执行形式"：
其唯一字段 `repr : E ≃ₗᵢ lp 𝕜 2`——每个带 Hilbert 基的空间都等距
同构于 ℓ²。这比"证明两个空间同构 ⟺ 维数相等"更结构化：分类
定理被**内化**为数据类型。

圆周 Fourier 理论 mathlib 已完整形式化（`Analysis.Fourier.AddCircle`）：

```lean
#check @fourierBasis      -- HilbertBasis ℤ ℂ (L²(haarAddCircle))
#check @hasSum_sq_fourierCoeff  -- Parseval：系数模方之和 = L² 积分
```

`fourierBasis` 直接是 Conway 5.10 的机器形态；(eₙ) 是 Hilbert 基。
`hasSum_sq_fourierCoeff` 是 Parseval（5.11）。直和两侧：`WithLp 2 (E₁ × E₂)`
与 `lp G 2` 的完备性都由 `infer_instance` 一步确认。

## 6.6 数值实验

**Julia**（`06_fourier_sums.jl`）：(1) 移位 S 的等距性与 S*S = I ≠
SS*（5.3 的代数，第 08 章的伏笔）；(2) **DFT 等距**：‖FFT(x)‖ =
√n‖x‖（5.11 的离散化身，除掉 √n 的约定因子）+ 逆变换恢复（双射）；
(3) Parseval 能量守恒（时域 = 频域）；(4) 直和范数的勾股形式。

**Python**（`06_fourier_sums.py`）：(1) eₘ ⊥ eₖ（离散内积 delta，
精确为 0）；(2) **系数衰减与光滑性**：光滑函数高频能量 < 1e-10，
方波 > 0.1（Conway 5.6 的现象——Fourier 系数衰减率编码光滑性）；
(3) Parseval（方波：时域 0.999 = 频域 0.999）；(4) **Gibbs 超调**
1.189 > 1（11 项部分和在跳跃点附近的最大值）——L² 收敛不照顾点态。

## 6.7 章末对照表

| Conway | 内容 | Lean | Julia/Python |
|---|---|---|---|
| 5.1-5.2 | 同构=保内积 | `LinearIsometryEquiv` + `inner_map_map` | — |
| 5.3 | 移位等距非酉 | — | ✓ S*S ≠ SS* |
| 5.4-5.5 | 分类定理 | `HilbertBasis.repr` | — |
| 5.6-5.10 | Fourier 基 | `fourierBasis` | ✓ 正交性/衰减 |
| 5.11 | Fourier=同构+Parseval | `hasSum_sq_fourierCoeff` | ✓ DFT 等距 |
| 6.1-6.4 | 直和 | `WithLp 2 prod`/`lp 2` 完备性 | ✓ 勾股范数 |

## 6.8 习题

1. **（纸笔）** Conway 习题 5.5 的核：证明两个同构的复合是同构、
   同构的逆是同构。
2. **（纸笔）** 证明 ℓ²(ℕ) ≅ ℓ²(ℤ) ≅ ℓ²(ℚ)：可数集彼此等势的
   Hilbert 空间侧影（Conway 5.5 的具体化）。
3. **（纸笔）** Conway 习题 13：E 标准正交，M = ∨E，则 P_M h =
   Σ⟨h,e⟩e（投影 = Fourier 和；4.7 的无穷版）。
4. **（机器）** Lean：证明 `HilbertBasis.repr` 保持内积（提示：
   `LinearIsometryEquiv.inner_map`）。
5. **（数值）** Haar 基下的 Parseval；比较同一函数在 Haar 与
   Fourier 基下系数的衰减（不连续函数应该 Haar 更快）。

---

上一章：[05 orthonormal-bases](docs/05-orthonormal-bases.md) · 下一章：[07 bounded-operators](docs/07-bounded-operators.md)
