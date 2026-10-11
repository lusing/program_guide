# 05 · 标准正交集与基

> 本节将证明：每个 Hilbert 空间都可以坐标化——如同欧氏空间一样。
> 坐标化的载体是标准正交基。——Conway §I.4 开篇（意译）

Conway §I.4 是整个 Hilbert 空间理论的"解析引擎"：它把第 03 章的投影定理
变成一部可以不停运转的机器。本章覆盖全部核心：标准正交系的定义、
Gram-Schmidt 正交化、Bessel 不等式、Fourier 展开与 Parseval 恒等式、
基的扩张（Zorn 引理的第二次出场）、Hilbert 维数论（任意两基同势）。

## 5.1 标准正交系与 Fourier 系数

**定义（Conway 4.1）**。ℋ 中的子集 E 称为**标准正交系**（orthonormal
set），若每个 e ∈ E 是单位向量且两两正交。**基**（basis）是极大的
标准正交系。

与线性代数的 Hamel 埠不同，这里的"基"是关于内积结构的极大性——
在无穷维空间中，基永远不是 Hamel 基（习题：为什么？基向量的无穷
级数收敛到不在有限跨度中的向量）。

对标准正交系 (eᵢ) 和 h ∈ ℋ，数 ⟨h, eᵢ⟩ 叫 h 的 **Fourier 系数**
——本章与第 06 章 Fourier 分析的全部联系就在这个名字里。

**命题（Conway 4.2）**。任何标准正交系可扩张为基。证明是 Zorn
引理的机械应用（第 01 章的预告兑现）：标准正交系按包含关系构成
偏序，链的并仍标准正交，故有极大元。

**例（Conway 4.3）**。ℋ = L²[0,2π]，eₙ(t) = (2π)^{-1/2} exp(int)，
n ∈ ℤ。这是标准正交系；它是不是基，要等一小节之后的判据。

**例（Conway 4.4-4.5）**。𝔽^d 的标准单位向量；ℓ²(I) 的"单点向量"
eᵢ(j) = δᵢⱼ——后者是基（直接验证），这就是"坐标化"的原型。

**Gram-Schmidt 正交化（Conway 4.6）**。（hₙ）线性无关，则存在标准
正交系 (eₙ) 使 span(e₁..eₙ) = span(h₁..hₙ) 对一切 n。构造是递归的：
e₁ = h₁/‖h₁‖；eₙ = (hₙ − Σ_{k<n} ⟨hₙ,eₖ⟩eₖ)/‖·‖——减去已生成子空间
上的投影（第 03 章的投影公式在干活），再归一化。

**命题（Conway 4.7）**。E = (e₁..eₙ) 标准正交，h ∈ ℋ。则
Σ ⟨h,eₖ⟩eₖ 是 h 到 M = span E 的**正交投影**；特别地
‖h − Σ⟨h,eₖ⟩eₖ‖ = dist(h, M)。

**证明**。记部分和 s = Σ⟨h,eₖ⟩eₖ。则 h − s 与每个 eⱼ 正交：
⟨h − s, eⱼ⟩ = ⟨h,eⱼ⟩ − Σ⟨h,eₖ⟩⟨eₖ,eⱼ⟩ = 0。由第 03 章的刻画
（Conway 2.6），s 是投影。∎

这个简单命题是"Fourier 部分和 = 最佳逼近"的来源：截断的 Fourier
级数是在有限维子空间里能做的**最好的**事。

## 5.2 Bessel 不等式

**定理（Bessel，Conway 4.8）**。(eₙ) 标准正交序列，则

Σₙ |⟨h, eₙ⟩|² ≤ ‖h‖²。

**证明**。对部分和 s_N = Σ_{n≤N}⟨h,eₙ⟩eₙ 用勾股分解（4.7 + 2.7）：
‖h‖² = ‖s_N‖² + ‖h − s_N‖² ≥ ‖s_N‖² = Σ_{n≤N}|⟨h,eₙ⟩|²。
对 N 取极限。∎

**推论（Conway 4.9-4.10）**。Fourier 系数趋于零（Riemann-Lebesgue
引理的 Hilbert 空间版）；对任意标准正交系，使 |⟨h,e⟩| > ε 的 e 只有
有限多个。

**定义（Conway 4.11-4.12）**。对标准正交族 (eᵢ)_{i∈I}，和
Σᵢ⟨h,eᵢ⟩eᵢ 定义为有限部分和网的极限（按包含序）。它收敛当且仅当
Σᵢ|⟨h,eᵢ⟩|² < ∞（Bessel 保证 ≤ ‖h‖² 总成立）。

## 5.3 基的判据与 Parseval

**定理（Conway 4.13）**。E ⊆ ℋ 标准正交。以下等价：

- (a) E 是基（极大）；
- (b) 对每个 h，Σ_{e∈E}⟨h,e⟩e = h（Fourier 展开收敛）；
- (c) E⊥ = {0}；
- (d) ⟨h, g⟩ = Σ_{e∈E}⟨h,e⟩⟨e,g⟩（内积的坐标公式）；
- (e) ‖h‖² = Σ_{e∈E}|⟨h,e⟩|²（**Parseval 恒等式**）；
- (f) span E 稠密。

**证明要点**。设 M = ∨E（闭线性张成）。(b)⟺ h ∈ M ∀h ⟺ M = ℋ。
而 E 是基 ⟺ Eᗮ = {0}（往大里加一个向量就破坏正交性，当且仅当
没有非零向量与 E 全正交）⟺ M = ℋ（第 03 章 2.11：ℳ 稠密 ⟺ ℳ⊥ = 0）。
(d)(e) 是 (b) 配内积连续性与 h = g 的特例。∎

Parseval 恒等式是**能量守恒**：向量的全部能量等于其 Fourier 系数
携带的能量之和。Bessel 说"≤"，基性把它补成"="。

## 5.4 Hilbert 维数

**命题（Conway 4.14-4.16）**。任意两个基同势；dim ℋ := 基的势。
若 dim ℋ 无穷，则 ℋ 的 Hamel 基的势严格更大（dim ℋ 与代数维数
在无穷时分裂）；‖{h : ‖h‖ ≤ 1}‖ 紧 ⟺ dim < ∞。

**定理（Conway 5.4，提前引用）**。两个 Hilbert 空间同构 ⟺ 维数
相同。这是下一章的开场。

## 5.5 机器化：Lean 的 OrthonormalBasis 生态

mathlib 围绕这一章建了三层设施：`Orthonormal` 谓词、
`OrthonormalBasis`（有限维）、`HilbertBasis`（一般）。文件
`examples/lean/Funanalysis/Ch05Orthonormal.lean` 走一遍主线：

```lean
-- Bessel（有限版：部分和能量 ≤ 全能量）
example (v : ℕ → F) (hv : Orthonormal ℝ v) (h : F) (s : Finset ℕ) :
    ∑ i ∈ s, ‖⟪v i, h⟫_ℝ‖ ^ 2 ≤ ‖h‖ ^ 2 :=
  hv.sum_inner_products_le h

-- 无穷版
example (v : ℕ → F) (hv : Orthonormal ℝ v) (h : F) :
    ∑' i, ‖⟪v i, h⟫_ℝ‖ ^ 2 ≤ ‖h‖ ^ 2 :=
  hv.tsum_inner_products_le h
```

注意 mathlib 的 Bessel 用 `‖⟪v i, h⟫‖²`（复安全的模方形式）；实数域
上它就是 Fourier 系数的平方（docs 里的代数形式）。

```lean
-- Gram-Schmidt：线性无关组 → 标准正交组（Conway 4.6）
example (f : ℕ → F) (h₀ : LinearIndependent ℝ f) :
    Orthonormal ℝ (InnerProductSpace.gramSchmidtNormed ℝ f) :=
  InnerProductSpace.gramSchmidtNormed_orthonormal h₀
```

`gramSchmidtNormed` 就是 5.1 节的递归构造；mathlib 把"不减子空间链"
（span 相等）也证明了（`gramSchmidtSpan`）——数值通道里我们对同一条
链做了投影一致性实验。

Parseval 的有限版一句话（`OrthonormalBasis` 的方法）：

```lean
example (b : OrthonormalBasis ι ℝ F) (x : F) :
    ∑ i, ‖⟪x, b i⟫_ℝ‖ ^ 2 = ‖x‖ ^ 2 :=
  b.sum_sq_norm_inner_left x
```

基的扩张（Zorn）在有限维由 `Orthonormal.exists_orthonormalBasis_extension`
承载；一般情形由 `HilbertBasis`（下一章的主角）绕开势论直接构造。

## 5.6 机器化：Isabelle 的具体计算

`examples/isabelle/FA05/T05_Orthonormal.thy` 在 real^2 上把 Parseval
算到数字：取 x = (3,4)，Fourier 系数 (3,4)，能量 9+16 = 25 = ‖x‖²。
证明走 axis 分解 + 内积四引理展开（FA00 验证过的风格）：
每一步 `inner_add_left`、`inner_axis_axis` 的 delta 条件消解。
Bessel（9 ≤ 25）与"Gram-Schmidt 的起点"（两个不正交的具体向量，
内积 = 1）同理。

## 5.7 数值实验

**Julia**（`05_orthonormal.jl`）：(1) Gram-Schmidt 链一致性——同一
向量在 V 的前 j 列与 GS 产物 Q 的前 j 列张成的子空间上投影一致
（残差 < 1e-8），这正是"span 链相同"的数值形态；(2) Bessel 部分
能量 ≤ 全能量；(3) 完整基的 Parseval 精确成立（QR 的 Q 是正交阵）；
(4) **部分和的最优性**：Fourier 部分和的残差 ≤ 任意扰动系数的残差
（50 次随机试验）——Conway 4.7 的变分刻画。

**Python**（`05_orthonormal.py`）：把幂基 (1, x, x², x³) 在 L²[-1,1]
上 Gram-Schmidt 化，得到 **Legendre 多项式**（Conway 习题 6）：归一
化后 Gram 矩阵 ≈ I（off-diagonal < 1.2e-6）；对 f = eˣ 做 Legendre
展开，Bessel 不等式 3.6268 ≤ 3.6269 在数值容差内成立；部分和逼近
残差在 50 组扰动对照中最小。

## 5.8 章末对照表

| Conway | 内容 | Lean | Isabelle | Julia/Python |
|---|---|---|---|---|
| 4.1-4.2 | 标准正交系、扩张 | `Orthonormal` + `exists_orthonormalBasis_extension` | — | — |
| 4.3-4.5 | 例子 | `EuclideanSpace.basisFun` | ✓ axis 分解 | — |
| 4.6 | Gram-Schmidt | `gramSchmidtNormed` | ✓ 起点 | ✓ 链一致性 |
| 4.7 | 部分和=投影 | `sum_repr'` | — | ✓ 最优性 |
| 4.8-4.10 | Bessel | ✓ `sum_inner_products_le` | ✓ 数字版 | ✓ |
| 4.13 | 基判据+Parseval | `sum_inner_mul_inner`/`sum_sq_norm_inner` | ✓ 数字版 | ✓ |
| 4.14-4.16 | 维数论 | `HilbertBasis`（06 章） | — | — |

## 5.9 习题

1. **（纸笔）** Conway 习题 4：在例 1.8 的空间（⟨f,g⟩ = ∫f'ḡ'）中找
   一个无穷标准正交系。
2. **（纸笔）** Conway 习题 6：证明 Legendre 多项式是幂基的
   Gram-Schmidt 产物（数值通道已验证）。
3. **（纸笔）** Conway 习题 10：若 Σ(hₙ) 依 4.11 收敛于 h，则部分和
   序列收敛；反之不成立（给出反例）。
4. **（机器）** Lean：证明 Parseval 的内积版本（4.13 (d)）可以推出
   范数版本（(e)）（提示：取 h = g，用 `sum_sq_norm_inner_left`）。
5. **（数值）** Haar 小波 = 分段常数基的 Gram-Schmidt：实现它并验证
   Parseval；比较 Haar 系数与 Legendre 系数对不连续函数的衰减。

---

上一章：[04 riesz](docs/04-riesz.md) · 下一章：[06 fourier-sums](docs/06-fourier-sums.md)
