# 04 算术基本定理

**对应原书 §1.4（pp. 40-42）。**

---

## 4.1 唯一分解：从存在到唯一

第 01 章的定理 1.2 证明了每个 n ≥ 2 **存在**素因子分解。本节补上另一半——
分解**唯一**。两者合称：

> **定理 1.51（算术基本定理，FTA）** 每个整数 a ≥ 2 或是素数，或是素数
> 之积；而且在不计次序的意义下，分解式唯一。等价地（推论 1.52），存在
> 唯一的相异素数 p₁ < p₂ < ⋯ < p_k 与唯一的正整数指数 e₁, …, e_k 使
> a = p₁^{e₁} p₂^{e₂} ⋯ p_k^{e_k}。

**唯一性的证明（对素因子个数归纳 + 欧几里得引理）** 设
p₁p₂⋯p_s = q₁q₂⋯q_t 是两个分解。p₁ 整除左边，故整除右边；由定理 1.38
（素数整除乘积必整除某因子），p₁ 整除某个 q_j，而 q_j 是素数，故
p₁ = q_j。约去这个公因子，得 p₂⋯p_s = q₁⋯q_{j−1}q_{j+1}⋯q_t——一个
素因子个数更少的等式。由归纳假设，两边的分解不计次序相同。∎

请停下来欣赏这个证明的供应链：**唯一性 ⟵ 欧几里得引理 ⟵ 贝祖 ⟵ 良序**。
整条链没有一步用到"大小比较"——全部是结构推理。这解释了为什么同样的
定理在多项式环（第 20 章）、高斯整数环（第 35 章）里能重演：只要那里也有
带余除法（从而有欧几里得引理），唯一分解就自动到手。

一个反例衬托"欧几里得引理"这条命门有多值钱：在 ℤ[√−5] = {a + b√−5} 中，
6 = 2·3 = (1+√−5)(1−√−5) 是两个真正的不同分解——因为 ℤ[√−5] 里没有
带余除法，贝祖失效。唯一分解是一种**需要证明的特权**，不是整数的免费赠品；
第 35 章将正面回答"哪些环享有它"。

> **推论 1.53** 每个正有理数 r ≠ 1 有唯一的分解 r = Π p^{f_p}，
> f_p ∈ ℤ 且只有有限多个非零（分子指数为正、分母指数为负）。

有理数乘除法于是变成"指数向量按分量加减"——这是唯一分解送出的
第一份算法红利。

## 4.2 用指数向量做算术

把 a 与 b 写在**同一组素数** p₁, …, p_k 上（允许指数为零）：
a = Π p_i^{e_i}，b = Π p_i^{f_i}。则整除与相等完全指数化：

> **引理 1.54** a ∣ b ⟺ 对每个 i，e_i ≤ f_i。

> **命题 1.55** (a, b) = Π p_i^{min(e_i, f_i)}，lcm(a, b) = Π p_i^{max(e_i, f_i)}。

> **命题 1.56** (a, b) · lcm(a, b) = a · b。

命题 1.56 现在是一行：min + max = e + f，逐分量验证即
p^{min+max} = p^{e+f}。例：a = 168 = 2³·3·7，b = 180 = 2²·3²·5，
gcd = 2²·3 = 12，lcm = 2³·3²·5·7 = 2520，乘积 12·2520 = 30240 = 168·180 ✓。

**一个重要的"反向警告"**：命题 1.55 是**结构性定理**，不是算法建议。
要用它算 gcd，得先分解 a 与 b——而分解大数是出了名的难（至今没有多项式
时间的经典算法）。欧几里得算法算 gcd 却快得惊人（拉梅定理：步数线性于
位数）。**"gcd 容易、分解难"的不对称是整个现代密码学的地基**——下一章
的 RSA 正是把秘密藏在 N = pq 里：算 (N) 容易，把 N 撕开难。数论篇在
这里埋下了全书的第一个"应用地雷"。

## 4.3 机器验证一：Lean——mathlib 中的唯一分解

**文件：`examples/lean/Abstractalgebra/Ch04Fta.lean`。**
mathlib 把 ℕ 的素因子分解做成 `Nat.primeFactorsList`（列表）与配套引理；
我们的文件复述三条主轴：分解存在、乘积还原、gcd/lcm 指数律。

```lean
-- 每个 n ≠ 0 的素因子列表乘积还原为 n（定理 1.2 的机器版）
theorem prod_primeFactorsList_eq (n : ℕ) (hn : n ≠ 0) :
    List.prod n.primeFactorsList = n :=
  Nat.prod_primeFactorsList hn

-- 列表中每个元素都是素数
theorem prime_of_mem (n : ℕ) (p : ℕ) (hp : p ∈ n.primeFactorsList) :
    Nat.Prime p :=
  Nat.prime_of_mem_primeFactorsList hp

-- 具体算例的规范形：1728 = 2⁶·3³
example : Nat.primeFactorsList 1728 = [2, 2, 2, 2, 2, 2, 3, 3, 3] := by
  native_decide

-- gcd·lcm = a·b（命题 1.56）
example (a b : ℕ) : Nat.gcd a b * Nat.lcm a b = a * b := Nat.gcd_mul_lcm a b
```

`Nat.primeFactorsList 1728 = [2,…,2,3,3,3]` 直接算出——**唯一性在这里体现
为"算出来的答案就是那个答案"**；一般定理下的唯一性由
`UniqueFactorizationMonoid ℕ` 实例承担（`factors_unique`，文件加注对照
定理 1.51），文件里另外给出唯一性的命门片段——"素数整除素数则相等"
（`Nat.prime_dvd_prime_iff_eq`）。指数版的 gcd 刻画用
`Nat.factorization_gcd`：`(gcd a b).factorization = a.factorization ⊓
b.factorization`——`⊓` 正是逐分量取 min，命题 1.55 的直译；结尾用 168、
180 把 4.2 节的手算复算一遍。

## 4.4 机器验证二：Julia/Python——试除分解与交叉验证

**文件：`examples/julia/04_fta.jl`** 实现试除分解（除到 √n 为止——命题 1.3
的程序版），然后做三组断言：

```julia
function factorize(n::BigInt)
    fs = Tuple{BigInt,Int}[]          # (素数, 指数) 列表
    p = BigInt(2)
    while p * p <= n
        e = 0
        while n % p == 0; n ÷= p; e += 1; end
        e > 0 && push!(fs, (p, e))
        p += (p == 2 ? 1 : 2)         # 2 之后只试奇数
    end
    n > 1 && push!(fs, (n, 1))        # 剩下的自身是素因子
    fs
end
```

断言一（**还原与规范形**）：对 2 ≤ n ≤ 999 的每个 n，分解的乘积还原为 n、
素数严格递增、指数 ≥ 1。断言二（**命题 1.55 双实现**）：由分解算出的
gcd/lcm 与欧几里得算法（第 03 章 `extgcd`）给出的完全一致——结构性定义与
算法实现互相印证。断言三（**命题 1.56**）：对 200 对随机 12 位数，
gcd·lcm = a·b 逐对成立；另用梅森素数 2³¹ − 1（试除到 √n ≈ 46341 即可）
演示"分解自身 = 素数"的判定，并顺手对比 gcd(2⁶¹−1, 2³¹−1) 一步欧几里得
秒算、分解却是另一个世界。

**文件：`examples/python/04_fta.py`** 换 sympy 做对照实验：
`sympy.factorint(n)` 与自实现试除法结果逐素数逐指数比对（n ≤ 2000 全量）；
验证 Ω(n)（计重数的素因子个数）的可加性 Ω(ab) = Ω(a) + Ω(b)、
指数律 gcd/lcm 与 `math.gcd`/`math.lcm` 一致、gcd·lcm = ab、
大数抽查 2⁶¹ − 1（sympy 用强素性检验秒判素），以及呼应第 02 章的
Σ_{d∣n} φ(d) = n。

**文件：`examples/prolog/04_fta.pl`** 用回溯直译试除：

```prolog
factorize(N, Fs) :- N > 1, factor_from(N, 2, Fs).

factor_from(1, _, []) :- !.
factor_from(N, P, Fs) :-
    P * P > N, !,
    Fs = [(N, 1)].                       % 剩下的自身是素数（命题 1.3）
factor_from(N, P, Fs) :-
    N mod P =:= 0, !,
    extract_power(N, P, 0, N1, E),       % 数出 P 的指数
    next_p(P, Q),
    factor_from(N1, Q, Fs0),
    Fs = [(P, E) | Fs0].
factor_from(N, P, Fs) :-
    next_p(P, Q),                        % 2 之后只试奇数
    factor_from(N, Q, Fs).
```

四条子句分别对应"除尽则提取指数 / 试到 √n 即可 / 否则前进到下一候选"。
文件断言：n ≤ 300 分解乘积还原且素数递增、gcd/lcm 由指数 min/max 合成后
与 `gcd/3`（欧几里得版）一致且 gcd·lcm = ab、1728 的规范形恰为
[(2,6),(3,3)]。

## 4.5 要点回顾

1. FTA = 存在（定理 1.2，最小反例）+ 唯一（欧几里得引理，归纳）；
   供应链是 良序 → 贝祖 → 欧几里得引理 → 唯一性。
2. 唯一分解是需要证明的特权：ℤ[√−5] 的 6 = 2·3 = (1+√−5)(1−√−5) 是
   永久警示。
3. 指数向量把整除变不等式、gcd/lcm 变 min/max、有理数乘除变向量加减。
4. gcd·lcm = ab（命题 1.56）是 min+max 恒等式的指数版。
5. gcd 容易（欧几里得）而分解难（无已知多项式算法）——这个不对称是
   RSA 的地基，下一章兑现。

*对应示例：`examples/lean/Abstractalgebra/Ch04Fta.lean`、
`examples/julia/04_fta.jl`、`examples/python/04_fta.py`、
`examples/prolog/04_fta.pl`。*

---

上一章：[03 最大公因子](03-gcd.md) · 下一章：[05 同余](05-congruence.md)
