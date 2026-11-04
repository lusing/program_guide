# 19 从数到多项式：根与因子

**对应原书 §3.5（pp. 250-271）。**

---

## 19.1 大翻译：整数的定理 → 多项式的定理

第 03-04 章的整除理论几乎逐字平移到 F[x]（F 域）——因为唯一的
引擎是**除法算式**，而 F[x] 有它（第 17 章）。对照表：

| ℤ | F[x] |
|---|---|
| 除法算式 a = qb + r | f = qg + r（deg r < deg g） |
| gcd 存在（欧几里得算法） | gcd 存在（多项式欧几里得） |
| 贝祖：d = sa + tb | d = sa(x) + tb(x) |
| 欧几里得引理 | 不可约 g ∣ fg ⟹ g ∣ f 或 g ∣ g |
| 算术基本定理 | 唯一分解（第 20 章） |
| 素数 | **不可约多项式** |
| ℤ 的理想都是主理想 | F[x] 的理想都是主理想 |

"带余除法的整环"被抽象成**欧几里得整环**（Euclidean domain），
ℤ 与 F[x] 是两大初始样本——这条抽象线第 35 章正式展开。

## 19.2 根：多项式的零点算术

> **定义** a ∈ R 是 f ∈ R[x] 的**根**，若 f(a) = 0。

> **因子定理（命题 3.4x）** a 是 f 的根 ⟺ (x − a) ∣ f。
> **命题 3.4x** f 在整环 R 中至多有 deg f 个根。

证明（重数计数）：f = (x−a₁)(x−a₂)⋯(x−aₖ)·g，代 x = aᵢ 逐个
消去——整环无零因子保证每次消去合法。∎

**反例警示**：整环性必要！ℤ/8ℤ 中 x² − 1 有 4 个根（1, 3, 5, 7），
超过次数 2——零因子让"次数 = 根数上限"破产。

> **定理 3.4x（代数基本定理的实用版）** n 次复多项式恰有 n 个根
> （计重数）——ℂ[x] 的完全分裂。d 次多项式在域 F 上至多 d 个根，
> 恰 d 个 ⟺ 在 F 上完全分裂。

## 19.3 有理根与整系数多项式

整系数多项式的有理根可以**穷举**：

> **命题 3.4x（有理根定理）** f = sₙxⁿ + ⋯ + s₀ ∈ ℤ[x]，既有理根
> p/q（既约）满足 p ∣ s₀ 且 q ∣ sₙ。

例：f = 2x³ + x − 3 的候选有理根 = ±{1, 3} ÷ ±{1, 2}，逐一检验
发现 x = 1 是根（2+1−3 = 0），故 f = (x−1)(2x²+2x+3)，二次因子
判别式 4 − 24 < 0 无实根——**有理根定理 + 试除 = 三次方程的
人肉求解器**。这是第 29 章（经典公式）的土法前奏。

**不可约的传递**（习题常用）：f ∈ ℤ[x] 在 ℚ[x] 不可约 ⟺ 在
ℚ[x] 看作本原多项式（系数 gcd = 1）不可约——Gauss 引理的
内容，第 21 章展开。

## 19.4 多项式欧几里得算法与 gcd

与整数版逐字对应：反复做多项式除法，余式次数严格下降，终止于
零余式；最后一个非零余式（取首一化）即 gcd。贝祖等式
d(x) = s(x)f(x) + t(x)g(x) 由回代产生（第 03 章 extgcd 的多项式版）。

**应用一（最小公倍式）**：lcm(f,g) = fg/gcd(f,g)。
**应用二（部分分式的胚）**：1/(fg) = s/d + t/d′ 的分解依赖贝祖。
**应用三（中国剩余的环版）**：(x−a)(x−b) 互素 ⟺ a ≠ b，插值
多项式的存在性（习题：拉格朗日插值 = CRT 在 F[x] 上的实现）。

## 19.5 机器验证一：Lean——根与因子定理

**文件：`examples/lean/Abstractalgebra/Ch19Roots.lean`。**

```lean
-- 因子定理：(x − a) ∣ f ⟺ f(a) = 0
example {F : Type*} [Field F] (f : Polynomial F) (a : F) :
    (Polynomial.X - Polynomial.C a) ∣ f ↔ f.eval a = 0 :=
  Polynomial.X_sub_C_dvd_iff_eval_eq_zero f a

-- 根数 ≤ 次数（整环上）
example {R : Type*} [CommRing R] [IsDomain R] (f : Polynomial R) :
    Fintype.card f.roots ≤ f.natDegree := ...
```

（`X_sub_C_dvd_iff_eval_eq_zero` 正是因子定理的正式化；根集
`Polynomial.roots` 在整环上的基数不等式由 `Polynomial.card_roots'`
承担。）具体轨道：x³ − x 在 ℚ 上 3 根（−1, 0, 1）、在 ℤ/8ℤ 模型上
x² − 1 有 4 根的反例（以 ℤ/8ℤ 为系数环 decide 计根）；有理根定理
的实例：2x³ + x − 3 的候选 {±1, ±3, ±1/2, ±3/2} 中恰 x = 1 入选。

## 19.6 机器验证二：Julia——根搜索与欧几里得

**文件：`examples/julia/19_roots.jl`**：

```julia
"""多项式欧几里得（F = ℤ_p）：返回 (gcd, s, t) 使 d = sf + tg。"""
function poly_extgcd(f, g, p)
    old_r, r = f, g
    old_s, s = [1], [0]
    old_t, t = [0], [1]
    while any(!=(0), r)
        q, rem = polydiv(old_r, r, p)
        old_r, r = r, rem
        old_s, s = s, old_s .- polymul(q, s; p) |> x -> trim!(x)
        ...
    end
    (old_r, old_s, old_t)
end
```

断言组：(1) **根穷举**：ℤ₇[x] 中 x³ − x 的根 = {0, 1, 6}（逐点
求值），恰 3 = deg ✓；ℤ₈[x] 中 x² − 1 的根 = {1, 3, 5, 7}（4 个
> 次数——反例现场）；(2) **有理根定理机器化**：f = 2x³+x−3 的
候选集（divisor(s₀) × divisor(sₙ)）逐一求值，恰 {1} 是根；
(3) **贝祖回代**：ℤ₅[x] 中 gcd(x²+1, x+2) 的 s, t 满足
sf + tg = d（系数 mod 5 逐项核对）；(4) gcd 幂等：
gcd(f, g) = gcd(g, f mod g) 递归正确性（50 组随机对拍）；
(5) **拉格朗日插值**：ℤ₇ 上过 (1,2), (2,4), (3,0) 的二次多项式
存在且唯一（解线性方程组 vs CRT 公式双路）。

## 19.7 机器验证三：Python 与 Prolog

**文件：`examples/python/19_roots.py`**：sympy 通道——`sympy.roots`
对拍穷举（ℤ_p 手写求值）；`Poly.gcd_list`（欧几里得）与自实现
poly_extgcd 对拍；有理根定理用 `sympy.divisors` 枚举候选；
拉格朗日插值与 `sympy.interpolate` 对拍。

**文件：`examples/prolog/19_roots.pl`**：

```prolog
% 根穷举：f(a) = 0 (mod p)
root(P, F, A) :- between(0, P, A0), A is A0 mod P,
    eval_poly(P, F, A, V), V =:= 0.
```

文件断言：ℤ₇ 上 x³−x 恰 3 根、ℤ₈ 上 x²−1 恰 4 栓（反例）、
ℤ₅ 上 x²+1 无根（−1 非平方剩余——第 22 章 GF(25) 的引子）、
有理根候选枚举（divisor 对生成器）。

## 19.8 要点回顾

1. 除法算式 ⟹ 欧几里得算法 ⟹ 贝祖 ⟹ 欧几里得引理——F[x] 完整
   复刻 ℤ 的整除理论；"素数"对应"不可约多项式"。
2. 因子定理：根 ⟺ 线性因子；整环上根数 ≤ 次数（ℤ/8ℤ 反例警示
   整环性必要）。
3. 有理根定理：p ∣ 常数项、q ∣ 首项系数——候选穷举 = 人肉求解器。
4. 多项式欧几里得 + 回代给出贝祖 s(x)f + t(x)g = d(x)；lcm、
   部分分式、插值全是它的下游。
5. ℂ[x] 的 n 次多项式恰 n 根（计重数）——代数基本定理的实用形态。

*对应示例：`examples/lean/Abstractalgebra/Ch19Roots.lean`、
`examples/julia/19_roots.jl`、`examples/python/19_roots.py`、
`examples/prolog/19_roots.pl`。*

---

上一章：[18 环同态](18-ring-homs.md) · 下一章：[20 多项式的唯一分解](20-ufd.md)
