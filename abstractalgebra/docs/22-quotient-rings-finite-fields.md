# 22 商环与有限域

**对应原书 §3.8（pp. 288-304）。**

---

## 22.1 商环：取商手法第四次登场

> **定理 3.7x（商环良定义）** I 是交换环 R 的理想。陪集 a + I 的
> 集合 R/I 对 (a+I) + (b+I) = (a+b)+I 与 (a+I)(b+I) = ab+I 成环，
> 当且仅当 I 是理想（吸收性保证乘法良定义）。

与商群（第 12 章）完全平行的剧情：**正规子群之于群 = 理想之于环**
——都是"商运算良定义"的通行证。第 05 章 ℤ/mℤ 现在彻底现出原形：
**ℤ/mℤ = ℤ/mℤ（mℤ 是理想）**，取商手法家族四世同堂
（ℤ/mℤ、商群、分式域、商环）。

> **定理 3.8x（第一同构定理，环版）** φ : R → S 环同态，
> R/ker φ ≅ im φ。

## 22.2 主理想环与最大理想的判定

> **命题 3.8x** F[x] 的每个理想都是主理想（f) := f·F[x]——
> 除法算式的又一次免费午餐（理想的最低次非零元整除全部元素）。

**造域定理**是本节的高潮：

> **定理 3.8x（F[x]/(p) 是域）** p ∈ F[x]。R = F[x]/(p) 是域 ⟺
> p 不可约。此时 [x] 在 R 中是 p 的一个根，|R| = |F|^{deg p}。

**证明要点**：(p) 最大 ⟸ 不可约：包含 (p) 的理想由某个 g ∣ p
生成，g 只能是单位（理想 = 全环）或相伴（相等）——"最大理想"
的定义级验证。域 ⟸ 最大：a ∉ (p) 时 gcd(a, p) = 1，贝祖给
sa + tp = 1，陪集 [s][a] = 1（[a] 可逆）。∎

**造域的威力**：ℝ[x]/(x²+1) ≅ ℂ（[x] 就是 i——复数的"发明"
成了陪集运算！）；ℤ₂[x]/(x²+x+1) = GF(4)；ℤ₃[x]/(x²+1) = GF(9)。
每个不可约 d 次多项式都造出一个 q^d 元域——有限域的存在性
一揽子解决。

## 22.3 有限域画像：GF(pⁿ)

> **定理 3.8x（有限域结构初步）** 有限域 F 的阶是素数幂 pⁿ
> （char p）；F 是 ℤ_p[x]/(某个 n 次不可约) 的实现；**乘法群
> F* 循环**（原根存在，习题/第 31 章正式证明）。

GF(4) 全表（本节的掌上明星）：

+ / × | 0 1 α α+1          （α² = α + 1，即 α² + α + 1 = 0）
α³ = α·α² = α(α+1) = α²+α = 1 ✓ 乘法群 {1, α, α+1} 循环 3 阶。

**元素计数**：|GF(pⁿ)*| = pⁿ − 1；每个元素的阶整除 pⁿ − 1
（拉格朗日第 10 章的环上应用）；原根 = pⁿ − 1 阶元，恰 φ(pⁿ−1)
个。ℤ₈、ℤ₁₂ 永远不是域（8 = 2³ 但 ℤ 型零因子），GF(8) 必须走
ℤ₂[x]/(不可约三次) 的路——第 15 章"有限域皆素幂阶"的实验观察
在此定案。

## 22.4 机器验证一：Lean——Quotient 与 GF

**文件：`examples/lean/Abstractalgebra/Ch22QuotientRings.lean`。**

```lean
-- 商环构造：mathlib 的 Ideal.quotient
example {R : Type*} [CommRing R] (I : Ideal R) (a b : R) :
    (Ideal.Quotient.mk (a * b) : R ⧸ I)
      = (Ideal.Quotient.mk a : R ⧸ I) * (Ideal.Quotient.mk b : R ⧸ I) :=
  Ideal.Quotient.mk_mul ..

-- ℂ ≅ ℝ[x]/(x²+1)
example : (Polynomial (Polynomial ℝ) ... ) -- 以 AdjoinRoot 呈现
noncomputable example : ℝ[AdjoinRoot.root (X ^ 2 + 1)] ≃ℂ := ...
```

（mathlib 用 `AdjoinRoot.root` 承担"[x] 是根"的构造——ℂ =
ℝ adjoin i 的分式化实现。）GF(4) 侧：mathlib 的 `GaloisField 2 2`
或 `ZMod 2[AdjoinRoot ...]`；文件以序对模型 (a, b) ∈ ℤ₂² 直接定义
GF(4) 的运算并断言域公理（decide 级），α³ = 1 与乘法群循环 3 阶
一并核验。

## 22.5 机器验证二：Julia——GF(pⁿ) 完整实现

**文件：`examples/julia/22_finite_fields.jl`**：

```julia
"""GF(p^d) = ℤ_p[x]/(p(x))：元素 = 次数 < d 的多项式（系数向量 mod p）。"""
struct GF
    p::Int; d::Int; modpoly::Vector{Int}
    coeff::Vector{Int}
end

# 乘法：多项式乘 + 模 p(x) 归约（长除法取余）
function Base.:*(u::GF, v::GF)
    prod = polymul(u.coeff, v.coeff; p = u.p)
    _, r = polydiv(prod, u.modpoly, u.p)
    GF(u.p, u.d, u.modpoly, r)
end

inv(u::GF) = ...
```

断言组：(1) **GF(4) 全景**：加法表、乘法表打印，域公理全查
（复用第 15 章检查器），α³ = 1，非零元 = {1, α, α+1} 循环群；
(2) **GF(8) = ℤ₂[x]/(x³+x+1)**：8 元域公理全过、乘法群 7 阶循环
（找原根 α：α, α², …, α⁷ = 1 全表）、x³+x²+1 造出**另一个** GF(8)
——与第一个同构（双射搜索命中）；(3) **GF(9) = ℤ₃[x]/(x²+1)**：
9 元域、乘法群 8 阶循环、恰 φ(8) = 4 个原根；(4) **ℂ 模型**：
ℝ[x]/(x²+1) 的序对实现 = 复数算术（(a,b) ↔ a+bi，乘法核对）；
(5) **ℤ₁₂ vs GF(16)**：ℤ₁₂ 有零因子（非域），GF(16) =
ℤ₂[x]/(x⁴+x+1) 是域——"素数幂阶的两个命运"对照。

## 22.6 机器验证三：Python 与 Prolog

**文件：`examples/python/22_finite_fields.py`**：复算 GF(4)/GF(8)/
GF(9) 全套；sympy `galois_residue...`? —— 改用 `sympy.Poly(
modulus=2)` 的 GF(2) 算术与自实现对拍；GF(8) 双实现的同构搜索
（8! 可行）。

**文件：`examples/prolog/22_finite_fields.pl`**：

```prolog
% GF(4)：元素 0,1,al,al1；运算表直接事实化
gf4_add(0, X, X).
gf4_add(X, 0, X).
gf4_add(1, 1, 0).  gf4_add(al, al, 0).  gf4_add(al1, al1, 0).
...
gf4_mul(0, _, 0).  gf4_mul(1, X, X).
gf4_mul(al, al, al1).  gf4_mul(al, al1, 1).  ...
```

文件断言：GF(4) 域公理全查（加乘双表 16×2 组合）、α 的阶 = 3、
非零乘法群循环；GF(8) 以 ℤ₂[x]/(x³+x+1) 的多项式表驱动实现，
域公理 + 原根 α 存在 + 7 个非零元全在 ⟨α⟩ 中。

## 22.7 要点回顾

1. 商环良定义 ⟺ 理想——正规子群（群）与理想（环）的完美对称；
   第一同构定理环版把 |R| = |ker|·|im| 正式化。
2. F[x] 是主理想环（除法算式的赠品）；(p) 最大 ⟺ p 不可约 ⟺
   F[x]/(p) 是域。
3. 造域 = 陪集算术：ℝ[x]/(x²+1) ≅ ℂ；GF(pⁿ) = ℤ_p[x]/(n 次不可约)。
4. 有限域：阶 = 素数幂；乘法群循环（原根 φ(pⁿ−1) 个）；不同实现
   互相同构（GF(8) 双造一域的实验）。
5. 造新对象的取商家族合账：ℤ/mℤ、商群、分式域、商环——四次
   同一手法，一次比一次快。

*对应示例：`examples/lean/Abstractalgebra/Ch22QuotientRings.lean`、
`examples/julia/22_finite_fields.jl`、`examples/python/22_finite_fields.py`、
`examples/prolog/22_finite_fields.pl`。*

---

上一章：[21 不可约性判别](21-irreducibility.md) · 下一章：[23 一个数学旅程](23-journey.md)
