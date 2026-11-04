# 17 多项式环

**对应原书 §3.3（pp. 232-239）。**

---

## 17.1 多项式：形式对象还是函数？

> **定义** 域（或交换环）R 上的多项式是**形式表达式**
> f(x) = s₀ + s₁x + s₂x² + ⋯ + sₙxⁿ，系数 sᵢ ∈ R，只有有限个非零。
> x 是**不定元**（indeterminate）——一个形式符号，不代入任何值。

为什么执着于"形式"？因为**多项式 ≠ 多项式函数**：在 ℤ/5ℤ 上
f(x) = x⁵ − x 与零函数处处相等（费马小定理！），但作为形式多项式
x⁵ − x ≠ 0。系数、次数、相等（逐系数）都是形式层面的概念。
mathlib 的 `Polynomial R` 正是形式实现（系数的 `Finsupp`），而
"求值"是额外的映射 eval。

**运算**：加法逐系数、乘法是卷积——

  (fg)(x) = Σ_k (Σ_{i+j=k} sᵢtⱼ) xᵏ。

> **定理 3.2x** R 交换环 ⟹ R[x] 交换环；R 整环 ⟹ R[x] 整环。
> **次数公式** deg(f + g) ≤ max(deg f, deg g)；deg(fg) ≤ deg f + deg g，
> 且**整环上取等**（首项系数 sₘtₙ ≠ 0 靠无零因子）。

次数公式在非整环上退化：ℤ/4ℤ 中 (2x+1)² = 4x²+4x+1 = 1，
次数 2 的平方次数 0——这是"系数环有零因子"的又一次收费。

## 17.2 带余除法：第三次登场

> **定理 3.2x（多项式除法算式）** f, g ∈ F[x]，g ≠ 0（F 域），则
> 存在**唯一** q, r 使 f = qg + r，且 r = 0 或 deg r < deg g。

证明是长除法的严格化：若 deg f ≥ deg g，用 f 的首项减去
(首项系数比)·x^{deg f − deg g}·g 的首项，次数严格下降，归纳终止。
唯一性：两式相减得 (q−q′)g = r−r′，左边要么 0 要么次数 ≥ deg g，
右边 < deg g，只能同为 0。∎

**除法算式需要首项系数可逆**——这就是定理要求 F 是域的原因；
ℤ[x] 中 2x+1 除以 2x 都做不了（商 1 余 −1? 2x+1 = 1·2x + 1 ✓ 可以，
但 x² 除 2x 商须 x/2 ∉ ℤ[x]）。"除法算式 ⟹ 一切因子理论"的
模式（第 03 章预告）开始第三轮重演。

**推论（余式定理）** f(a) = f mod (x − a) 的余式——代入即得；
特别地 (x − a) ∣ f ⟺ f(a) = 0（因子定理，第 19 章的主角）。

## 17.3 多项式函数与求值同态

> **命题 3.2x（求值同态）** 固定 a ∈ R，映射 φₐ : R[x] → R，
> f ↦ f(a) 是环同态（把 x 映到 a）。

求值同态是"形式与函数的桥梁"：多项式函数 = 形式多项式过 φₐ 的像。
有限域上这个同态有核（x⁵ − x ∈ ker φ），无限域（整环）上
**单射**——形式多项式与多项式函数在无限域上可以划等号
（习题：ℚ 上两多项式函数相等 ⟹ 系数全等）。

## 17.4 机器验证一：Lean——Polynomial R

**文件：`examples/lean/Abstractalgebra/Ch17Polynomials.lean`。**
mathlib 的 `Polynomial R` + 定向引理：

```lean
-- 乘法次数公式（整环上取等）
example {R : Type*} [CommRing R] [IsDomain R] {f g : Polynomial R}
    (hf : f ≠ 0) (hg : g ≠ 0) :
    (f * g).natDegree = f.natDegree + g.natDegree :=
  Polynomial.natDegree_mul hf hg

-- 除法算式：mathlib 的 Polynomial.divByMonic / modByMonic
example {F : Type*} [Field F] (f : Polynomial F) :
    f = Polynomial.mul X (f / Polynomial X) + f % Polynomial.X := ...
```

（首行引理 `natDegree_mul` 是 17.1 次数公式的正式化；第二行以
monic 版除法呈现——mathlib 的除法工具链围绕首一多项式组织，
一般情形乘常数归一化。）具体算例：(x+1)² 在 ℤ[x] 展开系数逐项
decide；x²+x+1 在 ℤ₂ 上除以 x+1 的商余 decide；ℤ/4ℤ 中
(2x+1)² = 1 的次数塌缩（17.1 的反例机器版）。

## 17.5 机器验证二：Julia——长除法实现

**文件：`examples/julia/17_polynomials.jl`** 系数向量版实现
（低位在前，与第 02 章分圆多项式同构）：

```julia
"""f ÷ g = (q, r)：长除法，deg r < deg g 或 r = 0。"""
function polydiv(f::Vector{Int}, g::Vector{Int}, m)   # 系数 mod m
    g = copy(g); trim!(g)
    q = zeros(Int, max(0, length(f) - length(g) + 1))
    r = copy(f)
    while length(r) >= length(g) && any(!=(0), r)
        shift = length(r) - length(g)
        c = r[end] * modinv(g[end], m) mod m          # 首项系数比
        q[shift + 1] = c
        for (j, gv) in enumerate(g)
            r[shift + j] = mod(r[shift + j] - c * gv, m)
        end
        trim!(r)
    end
    trim!(q), r
end
```

断言组：(1) ℤ₇[x]：x⁵−1 除以 x²+x+1，商 x³−x²+1? 手算核对——
机器给 (q, r)，验证 f = qg + r 与 deg r < 2；(2) 唯一性：随机
f, g 跑 100 组，两组独立除法结果相同；(3) **余式定理**：f mod
(x − a) 的余数 = f(a)（f(a) 逐点求值对拍，F = ℤ₇, a = 1..6）；
(4) **次数塌缩**：ℤ₄[x] 中 (2x+1)² = 1（次数 2 → 0）；
ℤ₇[x] 中 x⁵ − x 在 7 个点上取值全 0 但多项式非零（形式 ≠ 函数）；
(5) 求值同态：φₐ(f + g) = φₐ(f) + φₐ(g)、φₐ(fg) = φₐ(f)φₐ(g)
随机抽查。

## 17.6 机器验证三：Python 与 Prolog

**文件：`examples/python/17_polynomials.py`**：sympy 双通道——
`div(f, g, domain=GF(7))` 与自实现 polydiv 对拍（随机 500 组）；
`Poly.nth()` 系数抽取与次数公式核对；ℤ/4ℤ 的次数塌缩演示；
`expand((x+1)**2)` 的系数表 vs 手写卷积。

**文件：`examples/prolog/17_polynomials.pl`**：

```prolog
% 长除法一步：消最高次项
div_step(R, F, G, Q1, F1) :-
    last(F, Fc), last(G, Gc),
    inv(R, Gc, Ginv),            % 首项系数的逆（域！）
    C is Fc * Ginv mod R,
    length(F, NF), length(G, NG),
    Shift is NF - NG,
    shift_mul_sub(R, G, C, Shift, F, F1),
    nth0(Shift, Q1, C, _).
```

文件在 ℤ₅[x]/ℤ₇[x] 上断言除法算式的存在与唯一（f = qg + r、
deg r < deg g、两组除法一致）、余式定理 5 点核对。

## 17.7 要点回顾

1. 多项式是**形式**对象（Finsupp 系数）；有限域上形式 ≠ 函数
   （x⁵ − x ≠ 0 但函数恒 0），无限整环上可划等号。
2. R[x] 继承 R 的性质：环 → 环，整环 → 整环；次数公式
   deg(fg) = deg f + deg g 在整环上取等、有零因子时塌缩。
3. 除法算式（域系数！）：f = qg + r，deg r < deg g，唯一——
   长除法的严格化，因子理论的发动机第三次点火。
4. 余式定理：f(a) = 余式；(x−a) ∣ f ⟺ f(a) = 0。
5. 求值同态 φₐ : R[x] → R 把"形式"送到"函数"，有限域有核、
   无限域单射。

*对应示例：`examples/lean/Abstractalgebra/Ch17Polynomials.lean`、
`examples/julia/17_polynomials.jl`、`examples/python/17_polynomials.py`、
`examples/prolog/17_polynomials.pl`。*

---

上一章：[16 域与分式域](16-fields-fractions.md) · 下一章：[18 环同态](18-ring-homs.md)
