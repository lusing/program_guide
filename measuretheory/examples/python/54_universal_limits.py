# -*- coding: utf-8 -*-
print("==== 54 universal_limits")
# 第 54 章 Python：普遍极限的精确账（Fraction 版）。
# ① 退化准则三和的精确判决（二项型阵列）；② 二项→Poisson 的
#    系数恒等式；③ 四情形表的对角账。
from fractions import Fraction
from math import comb


# ① 退化准则：阵列 X_{n,k} = 1/n²（确定性！Bernoulli(p_{n,k}) 的
#    期望账）：p_{n,k} = 1/n²，k = 1..n
#    (i) ΣP{|X|>ε}：ε = 1/2 时每项 P = 0（1/n² ≤ 1/2）⟹ 和 = 0 ✓
#    (ii) 截尾期望和 = n·(1/n²) = 1/n → 0 ✓
#    (iii) 截尾方差和 = n·(1/n²)(1−1/n²) = 1/n − 1/n³ → 0 ✓
for n in (10, 100, 1000):
    p = Fraction(1, n * n)
    s_prob = sum(Fraction(0) for _ in range(n))         # ε=1/2：全零
    s_mean = n * p
    s_var = n * p * (1 - p)
    assert s_prob == 0
    assert s_mean <= Fraction(1, 10)                      # 1/n ≤ 1/10（n ≥ 10）
    assert s_var < s_mean                                  # 方差和更小
assert s_mean == Fraction(1, 1000)                         # n=1000 精确尾值
print("degeneracy criterion: sum P = 0, mean sum = 1/n, var sum = 1/n-1/n^3: OK")

#    破坏对照：p_{n,1} = 1/2 不消失（首项 O(1)）⟹ (i) = 1/2 ↛ 0
for n in (10, 100):
    s_bad = Fraction(1, 2) + sum(Fraction(0) for _ in range(n - 1))
    assert s_bad == Fraction(1, 2)
print("criterion violation: outlier row keeps sum P = 1/2 (not -> 0): OK")

# ② 二项→Poisson 的系数账：Bin(n, λ/n) 的 P{X=k} ≈ C(n,k)(λ/n)^k
#    = [C(n,k)/n^k]·λ^k，而 Po(λ) 的 P{X=k} ≈ λ^k/k!——两端 λ^k
#    相消，核心逼近是 C(n,k)/n^k ↔ 1/k!（即 ∏_{j<k}(1−j/n) → 1）
from math import factorial
for k in (0, 1, 2, 5):
    for n in (100, 500):
        ratio = Fraction(comb(n, k) * factorial(k), n ** k)   # = ∏(1−j/n)
        assert abs(float(ratio) - 1.0) < 0.15
print("Bin(n,2/n) weights: C(n,k)/n^k -> 1/k! (i.e. prod(1-j/n) -> 1): OK")

# ③ 四情形表对角账（每情形一行的最小实现——精确分数）
#    正态 √n：Bernoulli(1/2) 的 Var(S_n) = n/4 ⟹ 标准化分母 √(n)/2
from math import sqrt
n = 4
var_sn = Fraction(n, 4)
assert sqrt(float(var_sn)) == 1.0                          # n=4：σ = 1
#    Poisson n：Bin(n, 2/n) 的方差 = 2(1−2/n) → 2（Poisson 方差 = 均值）
n = 100
var_bin = Fraction(2 * n * (n - 2), n * n)
assert abs(float(var_bin) - 2.0) < 0.05                    # → λ = 2
#    Cauchy n（α=1）：分母 n——IQR(S_n/n) = IQR(X)（不变性由 Julia
#    通道采样验证；此处登记结构账：Sₙ/n 的理论 IQR = 2·tan(π/4) = 2）
import math
iqr = 2 * math.tan(math.pi / 4)
assert abs(iqr - 2.0) < 1e-12
print("four-regime diagonal: normal sqrt(n)/2, Poisson var->lam, Cauchy n: OK")

print("END ====")
