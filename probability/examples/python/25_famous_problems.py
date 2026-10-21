# -*- coding: utf-8 -*-
print("==== 25 famous_problems")
# 第 25 章 Python：秘书问题与 Monty Hall。
# ① 秘书问题精确概率表（P(k) 扫描，k* ≈ n/e 与 1/e）；② 调和
#    级数近似的误差账；③ 秘书模拟；④ Monty Hall 精确与模拟；
# ⑤ 百万门极限；⑥ 有/无放回采样对照。
from fractions import Fraction
from math import comb, exp, log, pi, sqrt
import random as _r

_r.seed(25)

# ① 精确概率 P(k) = (k/n)·Σ_{m=k}^{n−1} 1/m
def secretary_p(n, k):
    if k == 0:
        return Fraction(0)
    return Fraction(k, n) * sum(Fraction(1, m) for m in range(k, n))


for n in (10, 100):
    ps = [secretary_p(n, k) for k in range(1, n)]
    kbest = max(range(1, n), key=lambda k: ps[k - 1])
    assert abs(kbest - n / exp(1)) <= 1            # k* ≈ n/e
    tol = 0.035 if n == 10 else 0.005                    # n=10 时有限尺寸效应（39.9%）
    assert abs(float(ps[kbest - 1]) - 1 / exp(1)) < tol  # P* → 1/e
print("secretary exact: argmax k ~ n/e, max P ~ 1/e for n=10,100: OK")

# ② 调和级数近似：Σ1/m ≈ log(ℓ) + γ + 1/(2ℓ)
gam = 0.5772156649
for ell in (100, 10 ** 6):
    s = sum(Fraction(1, m) for m in range(1, ell + 1)) if ell <= 10 ** 5 else None
    if s is not None:
        err = float(s) - (log(ell) + gam)
        assert abs(err - 1 / (2 * ell)) < 2e-5    # 1/(2ℓ) 修正项
print("harmonic approx: log(l) + gamma + 1/(2l): OK")

# ③ 秘书模拟（n=1000）
def secretary_sim(n, k, trials):
    wins = 0
    for _ in range(trials):
        order = list(range(1, n + 1))
        _r.shuffle(order)
        best_first_k = max(order[:k])
        chosen = None
        for i in range(k, n):
            if order[i] > best_first_k:
                chosen = order[i]
                break
        if chosen == n:
            wins += 1
    return wins / trials


emp = secretary_sim(1000, round(1000 / exp(1)), 20_000)
assert abs(emp - 1 / exp(1)) < 0.01
print("secretary simulation: ", round(emp * 100, 2), "% vs 36.79%: OK", sep="")

# ④ Monty Hall：精确 2/3 与模拟
assert Fraction(comb(3, 1) - 1, 3) == Fraction(2, 3)  # 换赢 = 车不在初选门 = 2/3
wins_sw = sum(1 for _ in range(100_000) if _r.randint(1, 3) != 1)  # 初选 1 号
assert abs(wins_sw / 100_000 - 2 / 3) < 0.005
print("monty hall: exact 2/3, simulated ", round(wins_sw / 1000, 1), "%: OK", sep="")

# ⑤ 百万门（模拟 10⁵ 门）
N_DOORS = 100_000
wins = 0
for _ in range(2_000):
    car = _r.randint(1, N_DOORS)
    wins += (car != 1)                              # 主持人开掉其余羊后换门
assert abs(wins / 2_000 - (N_DOORS - 1) / N_DOORS) < 0.001
print("million doors: switch wins ", round((N_DOORS - 1) / N_DOORS * 100, 3),
      "%: OK", sep="")

# ⑥ 有/无放回采样：两红三蓝罐抽两球，P(至少一红)
urn = ["R", "R", "B", "B", "B"]
# 有放回：1 − (3/5)² = 16/25
with_rep = 1 - Fraction(3, 5) ** 2
assert with_rep == Fraction(16, 25)
# 无放回：1 − C(3,2)/C(5,2) = 1 − 3/10 = 7/10
wo_rep = 1 - Fraction(comb(3, 2), comb(5, 2))
assert wo_rep == Fraction(7, 10)
assert with_rep < wo_rep                            # 16/25 < 7/10（无放回不重复消耗红球）
# 枚举验证无放回
pairs = [(a, b) for i, a in enumerate(urn) for j, b in enumerate(urn) if i < j]
enum = Fraction(sum(1 for a, b in pairs if "R" in (a, b)), len(pairs))
assert enum == wo_rep
print("sampling with (16/25) vs without (7/10) replacement: OK")
print("END ====")
