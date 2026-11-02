# -*- coding: utf-8 -*-
print("==== 30 stirling")
# 第 30 章 Python：Stirling 公式的精确与数值账。
# ① 主式与修正项的相对误差幂律（~1/12n 与 ~1/288n²）；②
#    C(2n,n)/4ⁿ vs 1/√(πn)；③ 平票双模型（0.73% vs 10⁻⁵⁴）；
# ④ 穷汉上下界与几何均值；⑤ n!^{1/n} vs n/e。
from math import comb, exp, factorial, log, pi, sqrt


def stirling(n, corrected=True):
    # 对数域计算（n=10⁶ 时 n^n 溢出 int→float）
    lv = n * log(n) - n + log(2 * pi * n) / 2
    if corrected:
        lv += log1p(1 / (12 * n))
    return lv


def relerr(n, corrected=True):
    """Stirling 与 log(n!) 的相对偏差（对数域）。"""
    return abs(exp(stirling(n, corrected) - lgamma(n + 1)) - 1)


# ① 相对误差幂律：主式误差 ≈ 1/(12n)、修正后 ≈ 1/(288n²)
from math import lgamma, log1p

for n in (10, 100, 1000, 10 ** 6):
    e0 = relerr(n, corrected=False)
    e1 = relerr(n, corrected=True)
    assert e0 < 1.1 / (12 * n)                     # 主式界
    assert e1 < 1.1 / (288 * n * n)                # 修正项界
print("stirling error laws: ~1/(12n) raw, ~1/(288n^2) corrected: OK")

# ② C(2n,n)/4ⁿ vs 1/√(πn)（三位对齐）
for n in (10, 100, 1000):
    lhs = comb(2 * n, n) / 4 ** n
    rhs = 1 / sqrt(pi * n)
    assert abs(lhs / rhs - 1) < 1 / (8 * n)        # 修正项 1−1/(8n) 的量级
print("C(2n,n)/4^n ~ 1/sqrt(pi n) with 1/(8n) correction: OK")

# ③ 平票双模型
n = 6001
p_equal = comb(2 * n, n) / 2 ** (2 * n)            # 精确（大整数除法）
assert abs(p_equal - 0.0072829) < 1e-7
assert abs(p_equal - 1 / sqrt(pi * n)) / p_equal < 1e-4   # Stirling 近似
# 57%-43% 模型：C(2n,n)·0.57ⁿ·0.43ⁿ 的对数账
logp = (log(comb(2 * n, n)) + n * log(0.57) + n * log(0.43))
assert abs(logp - log(1.877e-54)) < 0.01
print("2008 primary tie: 0.73% (equal) vs 1.9e-54 (57-43): OK")

# ④ 严格积分夹逼：e(n/e)^n <= n! <= en(n/e)^n（对数域验证）。
# 下界是 ∫_1^n log(x)dx；上界把 log(n!) 写成 log(n)+Σ_{k<n}log(k)。
for n in (10, 50, 200):
    lm = n * log(n) - n
    lf = lgamma(n + 1)
    assert lm + 1 <= lf <= lm + 1 + log(n)
# 这个夹逼只确定几何平均的主项 n/e；因子 n 的缝隙不能推出 sqrt(2pi*n)。
assert all(abs(exp((lgamma(n + 1)) / n) / (n / exp(1)) - 1) < 0.5
           for n in (10, 100))
print("integral sandwich: e(n/e)^n <= n! <= en(n/e)^n: OK")

# ⑤ n!^{1/n} vs n/e
for n in (10, 100):
    lhs = factorial(n) ** (1 / n)
    assert lhs > n / exp(1) and lhs < n / exp(1) * (1 + 4 / n)  # 差 ~log(2πn)/(2n)
print("n!^(1/n) ~ n/e within 1+4/n: OK")

print("END ====")
