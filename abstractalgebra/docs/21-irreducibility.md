# 21 不可约性判别

**对应原书 §3.7（pp. 278-287）。**

---

## 21.1 问题：证明"分不开"

分解一个多项式容易（找到因子即可）；证明**不可分解**却要排除
一切可能的因子——这正是判别定理的价值。本节三件武器：
**有理根定理**（第 19 章已备）、**模 p 归约**、**艾森斯坦判别**。

## 21.2 Gauss 引理与 ℤ[x] ↔ ℚ[x]

> **定义** f ∈ ℤ[x] **本原**（primitive）：系数的最大公因子为 1。
> **Gauss 引理** 本原多项式之积仍本原。
> **命题 3.6x** f ∈ ℤ[x] 在 ℚ[x] 可约 ⟺ 在 ℤ[x] 中可约为本原
> 因子之积（次数相同）。

这条"ℤ[x] 与 ℚ[x] 的可约性等价"把有理系数问题拉回整数系数——
于是**模 p 归约**才有用武之地：

> **定理 3.6x（模 p 判别）** f ∈ ℤ[x]，p ∤ 首项系数。若 f mod p
> 在 ℤ_p[x] 不可约且 deg 保持，则 f 在 ℚ[x] 不可约。

（逆不真：可约的模 p 归约可能恰好不可约——要多试几个 p。）
理由：ℤ[x] 的分解 mod p 给出 ℤ_p[x] 的分解；次数不塌（首项系数
幸存）时因子也非平凡。

**例**：x⁴ + x³ + 1 在 ℤ₂[x] 不可约（无根 + 无二次因子，第 20 章
机器已验）⟹ 在 ℚ[x] 不可约。

## 21.3 艾森斯坦判别：一行判天下

> **定理 3.6x（Eisenstein）** f = aₙxⁿ + ⋯ + a₀ ∈ ℤ[x]。若存在
> 素数 p 使 p ∣ aᵢ (i < n)、p ∤ aₙ、p² ∤ a₀，则 f 在 ℚ[x] 不可约。

**证明**（反证 + Gauss）：设 f = gh 本原分解，mod p 后 f̄ = āₙxⁿ
是单项式，故 ḡ = x^r、h̄ = x^s（首项以外全灭）——特别地 p ∣ g₀
与 p ∣ h₀，故 p² ∣ g₀h₀ = a₀，矛盾。∎

例：x⁵ − 4x + 2（p = 2：系数 4,2 被 2 整除、首项 1 与常数 2 的
平方条件 ✓）不可约；**分圆多项式** Φ_p(x) = x^{p−1} + ⋯ + x + 1
(p 素) 不可约——对 Φ_p(x+1) = ((x+1)^p − 1)/x 用 Eisenstein（p 整除
二项系数 C(p,k)，p² ∤ p）。

**艾森斯坦的局限**：x² + 1 对任何 p 都不满足（常数 1 无素因子）——
判别定理是充分条件，不是必要的；模 p 归约与艾森斯坦互补。

## 21.4 求整系数不可约的工作流

```
f ∈ ℤ[x]
  │
  ├─ 有根？(有理根定理穷举候选) ──有──→ 可约（拔掉线性因子再来）
  │
  ├─ deg 2/3 且无根 ──→ 不可约 ✓
  │
  ├─ Eisenstein（找 p：中段系数全被 p 整除、首项幸存、常数无 p²）
  │     └─ 命中 ──→ 不可约 ✓
  │
  └─ 模 p 归约（f̄ 在 ℤ_p[x] 不可约？换几个 p 试）
        └─ 某个 p 不可约 ──→ 不可约 ✓
```

三者全部落空的高次多项式需要更重的机械（Hensel 提升现代算法的
核心）——本教程规模外，交给 sympy 的 `factor_list`。

## 21.5 机器验证一：Lean——Eisenstein 与分圆不可约

**文件：`examples/lean/Abstractalgebra/Ch21Irreducibility.lean`。**

```lean
-- mathlib 的 Eisenstein 正式化（在 Dedekind 整环/多项式框架下）
example {p : ℕ} (hp : Nat.Prime p) :
    Irreducible (Polynomial.cyclotomic p ℚ) :=
  Polynomial.isCyclotomic_irreducible_rat p ...  -- 名字以编译为准
```

（mathlib 在 `Polynomial.IsCyclotomic` 命名空间下有分圆多项式在 ℚ
上不可约的正式化——艾森斯坦 + Φ_p(x+1) 路线的机器版。）具体算例：
x⁵ − 4x + 2 的 Eisenstein 条件逐条 decide（p = 2）；
Φ₃(x) = x²+x+1 与 Φ₅ 的不可约性（对 p = 3, 5 走 Φ_p(x+1) 的
艾森斯坦参数，机器展开系数核对整除条件）；x⁴+1 在 ℤ₂ 的
(x+1)⁴ 塌缩 vs 在 ℚ 的不可约（域依赖的再演）。

## 21.6 机器验证二：Julia——判别三件套实现

**文件：`examples/julia/21_irreducibility.jl`**：

```julia
"""Eisenstein：存在素数 p 满足三条件。"""
function eisenstein(f::Vector{Int})
    for p in 2:50
        isprime(p) || continue
        f[end] % p != 0 || continue          # p ∤ 首项
        all(c -> c % p == 0, f[1:end-1]) || continue   # p ∣ 其余
        f[1] % (p * p) != 0 || continue      # p² ∤ 常数
        return p
    end
    nothing
end

"""模 p 不可约判别（deg ≤ 4：根 + 二次因子；更高走 sympy 通道）。"""
irreducible_modp(f, p) = ...
```

断言组：(1) **Eisenstein 命中表**：x⁵−4x+2 → p = 2 ✓；
2x⁴+8x³+10x²+4x+7?（中段系数被 2 整除，首项 2 被 2 整除 ✗ → p = 2
失败，程序正确返回 nothing）——正反两案；(2) **模 p 归约工作流**：
x⁴+1 → mod 2 = (x+1)⁴ 可约 ✗、mod 3 不可约 ✓ ⟹ ℚ 上不可约
（一个 p 碰壁换下一个的现场教学）；(3) **Φ_p 不可约**：p = 3, 5, 7
对 Φ_p(x+1) 跑 Eisenstein（展开系数核对二项系数被 p 整除）；
(4) **工作流闭环**：随机整系数多项式（deg ≤ 4，系数 ≤ 9）跑
三件套，命中即断言 sympy 同判（Julia 不做 sympy——改为与
穷举分解器对拍：判"不可约"者穷举找不到因子）。

## 21.7 机器验证三：Python 与 Prolog

**文件：`examples/python/21_irreducibility.py`**：sympy 主场——
`factor_list(f)` 与自实现三件套对拍（随机 300 组，deg ≤ 4）；
`isprime`、`binomial(P(p,k)) % p == 0` 核对艾森斯坦的引理需求；
Φ_p(x+1) 展开系数表打印（p = 5: C(5,k) = 5,10,10,5 全被 5 整除）。

**文件：`examples/prolog/21_irreducibility.pl`**：

```prolog
% Eisenstein 条件检查
eisenstein_p(F, P) :-
    last(F, An), An mod P =\= 0,
    init(F, Init), forall(member(C, Init), C mod P =:= 0),
    F = [A0 | _], A0 mod (P * P) =\= 0.
```

文件断言：x⁵−4x+2 的 p = 2 命中；x²+1 的全 p 落空（局限现场）；
Φ₃(x+1) = x²+3x+3 的 p = 3 命中；模 2/模 3 归约判别 x⁴+1 的
两幕剧。

## 21.8 要点回顾

1. Gauss 引理：ℤ[x] 与 ℚ[x] 的可约性等价（本原分解）——整数系数
   回家的路。
2. 模 p 归约：f̄ 在 ℤ_p[x] 不可约（次数不塌）⟹ f 在 ℚ[x] 不可约；
   单个 p 失败换下一个——充分不必要。
3. Eisenstein：素数 p 整除除首项外全部系数、p² ∤ 常数项 ⟹ 不可约；
   证明是 Gauss 引理 + mod p 的单项式论证。
4. Φ_p 不可约：平移 x ↦ x+1 后艾森斯坦——分圆多项式全部不可约
   （第 02 章 Φ₁₂ 负系数之谜的结构背景）。
5. 工作流：有根定理（拔线性）→ Eisenstein（找 p）→ 模 p（换 p 试）
   → 重机械；判别定理彼此互补，没有万能钥匙。

*对应示例：`examples/lean/Abstractalgebra/Ch21Irreducibility.lean`、
`examples/julia/21_irreducibility.jl`、`examples/python/21_irreducibility.py`、
`examples/prolog/21_irreducibility.pl`。*

---

上一章：[20 多项式的唯一分解](20-ufd.md) · 下一章：[22 商环与有限域](22-quotient-rings-finite-fields.md)
