# 20 多项式的唯一分解

**对应原书 §3.6（pp. 272-277）。**

---

## 20.1 唯一分解定理（F[x] 版算术基本定理）

> **定理 3.5x（F[x] 的唯一分解）** F 域。每个非零非单位 f ∈ F[x]
> 或是不可约的，或是不可约多项式之积；且分解在不计次序与常数倍
> 的意义下唯一。

**存在性**：对 deg 归纳——f 可约则拆成低次因子，递归到底。
**唯一性**：与 ℤ 版同一台戏（第 04 章）：设 p₁⋯pₛ = q₁⋯qₜ，
p₁ 整除右边，由**欧几里得引理**（不可约 ∣ 积 ⟹ ∣ 某因子）p₁ ∣ qⱼ，
两者皆不可约故相差常数倍，约去后对因子数归纳。∎

供应链复盘：**除法算式 → 欧几里得 → 贝祖 → 欧几里得引理 →
唯一分解**——同一台发动机在 ℤ（第 03-04 章）与 F[x]（本章）各
点火一次。数学的差异只在"测量递减的量"：ℤ 用绝对值，F[x] 用次数。

**规范形**：f = c·p₁^{e₁}·p₂^{e₂}⋯pₖ^{eᵏ}，c ∈ F*、pᵢ 首一不可约、
eᵢ ≥ 1。F[x] 的"素数表"不可枚举（不像 ℤ），但判定工具下章给全。

## 20.2 不可约 = 多项式世界的素数

> **定义** f ∈ F[x] 非常数。若 f = gh ⟹ deg g = 0 或 deg h = 0，
> 称 f **不可约**。

一次多项式全部不可约；二次、三次可约 ⟺ 有根（可约必含一次因子）；
**四次起不成立**：x⁴ + 4 = (x²−2x+2)(x²+2x+2)（无实根但可约——
Sophie Germain 恒等式）。次数与可约性的关系值得记牢：

- deg ≤ 1：不可约；
- deg = 2, 3：可约 ⟺ 有根；
- deg ≥ 4：可以无根而可约。

**不可约多项式是构造域的原料**：F[x]/(p(x)) 在 p 不可约时是域
（第 22 章）——GF(4) = ℤ₂[x]/(x²+x+1)、GF(9) = ℤ₃[x]/(x²+1)……
全部有限域都是这么造出来的。"分解"与"造域"是一枚硬币的两面。

## 20.3 gcd 的指数刻画与有效计算

与 ℤ 完全平行（命题 1.52 的复刻）：

> **命题 3.5x** gcd(f, g) 的分解中，每个不可约 p 的指数 =
> min(v_p(f), v_p(g))；lcm 取 max。gcd(f,g)·lcm(f,g) = fg（首一
> 归一后）。

但注意：**理论用分解、实践用欧几里得**——算 gcd 走分解是大炮
打蚊子（分解多项式远难于欧几里得），这与 ℤ 的处境（第 04 章
"gcd 快分解难"）一模一样。分解多项式的实际算法（在有理系数上）
下节的 Hensel/Zassenhaus 是真正的深水区，本教程止步于小规模
穷举判定。

## 20.4 机器验证一：Lean——F[x] 是 UFD

**文件：`examples/lean/Abstractalgebra/Ch20UFD.lean`。**
mathlib 已证 F[x] 唯一分解（`EuclideanDomain` → `UniqueFactorizationMonoid`
机器链），文件展示这条链与具体算例：

```lean
-- F[x] 是唯一分解幺半群（mathlib 实例层）
example {F : Type*} [Field F] :
    UniqueFactorizationMonoid (Polynomial F) := inferInstance

-- 不可约的定义层：EuclideanDomain.irreducible_iff...
example {F : Type*} [Field F] {p : Polynomial F} (hp : p.Monic) :
    Irreducible p ↔ ∀ q : Polynomial F, q ∣ p → IsUnit q ∨ Associated q p :=
  irreducible_iff_forall_dvd
```

具体算例：ℚ[x] 中 x⁴ + 4 的 Sophie Germain 分解——

```lean
example : (Polynomial.X ^ 4 + 4 : Polynomial ℚ)
      = (Polynomial.X ^ 2 - 2 * Polynomial.X + 2) *
        (Polynomial.X ^ 2 + 2 * Polynomial.X + 2) := by ring
```

（ring 直接展开验证——"无根可约"的四次反例机器版。）
ℝ[x]/ℂ[x] 的对照：x²+1 在 ℝ[x] 不可约、在 ℂ[x] = (x+i)(x−i)
（不可约性依赖系数域！）；x⁴ − x 在 ℤ₂[x] 的完全分裂
x(x−1)(x²+x+1) 逐系数 decide。

## 20.5 机器验证二：Julia——小规模分解器

**文件：`examples/julia/20_ufd.jl`** 实现系数域 ℤ_p 上的**完全
分解器**（p ≤ 11、deg ≤ 4 的可行规模）：

```julia
"""ℤ_p[x] 的不可约判定：deg ≤ 3 时 = 无根；deg 4 加试 (二次)×(二次)。"""
function irreducible_zp(f, p)
    any(a -> eval_poly(f, a, p) == 0, 0:p-1) && return false
    deg(f) <= 3 && return true
    # deg 4：枚举首一二次因子对
    for g in monic_quadratics(p)
        h, r = polydiv(f, g, p)
        all(iszero, r) && return false
    end
    true
end
```

断言组：(1) **分解器**：ℤ₂[x] 的 x⁴+x+1 不可约（无根 + 无二次
因子——16 个首一二次枚举）；x⁴+x²+1 = (x²+x+1)²（ℤ₂）；
(2) **唯一性实验**：随机 f 分解两次（不同搜索顺序），规范形
（首一 + 指数排序）一致；(3) **gcd/lcm 指数律**（20.3）：对
ℤ₅[x] 的随机 f, g，由分解算的 gcd 与欧几里得算的 gcd 逐系数相同；
(4) **Sophie Germain**：ℚ[x] 上 x⁴+4 分解、x⁴+1 在 ℚ 上不可约
（但 ℤ₂ 上 x⁴+1 = (x+1)⁴!）；(5) p(x) 不可约 ⟺ ℤ_p[x]/(p) 无
零因子的抽样（为第 22 章预热）。

## 20.6 机器验证三：Python 与 Prolog

**文件：`examples/python/20_ufd.py`**：sympy `factor_list(f, modulus=p)`
与自实现分解器对拍（ℤ_p, p ∈ {2,3,5,7}，deg ≤ 4 随机 200 组）；
`Poly.gcd` 与分解版 gcd 对拍；x⁴+4 / x⁴+1 的域依赖清单（ℚ/ℝ/ℂ/ℤ₂）。

**文件：`examples/prolog/20_ufd.pl`**：

```prolog
% 无根判定（deg ≤ 3 的不可约判据）
no_roots(P, F) :- \+ root(P, F, _).

% ℤ₂ 首一二次因子枚举（deg 4 的补充检查）
monic_quadratic(2, [1,1,1]).   % x²+x+1
monic_quadratic(2, [0,1,1]).   % x²+x
monic_quadratic(2, [1,0,1]).   % x²+1
...
```

文件断言：ℤ₂[x] 次数 ≤ 4 的全部 32 个多项式的不可约谱
（恰 6 个不可约：x, x+1, x²+x+1, x³+x+1, x³+x²+1, x⁴+x+1——
对照 GF(2ⁿ) 的存在谱）；x⁴+x²+1 的分解与唯一规范形。

## 20.7 要点回顾

1. F[x] 唯一分解：不可约积 + 唯一（常数倍与次序外）；供应链 =
   除法算式 → 欧几里得 → 贝祖 → 欧几里得引理 → 唯一性，与 ℤ 同构。
2. 次数-可约性：deg 1 恒不可约；deg 2/3 可约 ⟺ 有根；deg ≥ 4
   可无根可约（x⁴+4 Sophie Germain）。
3. 不可约性**依赖系数域**（x²+1 在 ℝ/ℂ；x⁴+1 在 ℚ/ℤ₂）。
4. gcd 指数律是理论刻画，计算走欧几里得——"分解难"再次与
   "gcd 易"形成密码学级反差。
5. 不可约多项式 = 造域原料（F[x]/(p) 是域）——第 22 章的主菜。

*对应示例：`examples/lean/Abstractalgebra/Ch20UFD.lean`、
`examples/julia/20_ufd.jl`、`examples/python/20_ufd.py`、
`examples/prolog/20_ufd.pl`。*

---

上一章：[19 从数到多项式](19-numbers-to-polys.md) · 下一章：[21 不可约性判别](21-irreducibility.md)
