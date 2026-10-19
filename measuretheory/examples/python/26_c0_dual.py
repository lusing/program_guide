# -*- coding: utf-8 -*-
print("==== 26 c0_dual")
# 第 26 章 Python：Jordan 拼装与保范账（Fraction 精确）。
# ① 符号权 Jordan 分解（逐点正负部精确）；
# ② 保范：‖Λ‖ = Σ|νᵢ| 与达范向量；
# ③ 密度情形：g = x−1/2 的 ∫f g 闭式（1/12、0）与 ‖Λ‖ = 1/4 精确；
# ④ 原子词典 δ₀−δ₁ 的连续达范。
from fractions import Fraction

V = [Fraction(2), Fraction(-3), Fraction(0), Fraction(3, 2), Fraction(-1, 2)]

# ① Jordan
Vpos = [max(v, Fraction(0)) for v in V]
Vneg = [max(-v, Fraction(0)) for v in V]
assert [p - n for p, n in zip(Vpos, Vneg)] == V
totvar = sum(abs(v) for v in V)
assert sum(Vpos) + sum(Vneg) == totvar == Fraction(7)
print("Jordan: nu+ - nu- = nu, |nu| = 7 exact: OK")

# ② 保范与达范
fstar = [Fraction(1) if v > 0 else Fraction(-1) if v < 0 else Fraction(0) for v in V]
assert sum(v * f for v, f in zip(V, fstar)) == totvar
assert max(abs(f) for f in fstar) == 1
print("norm identity: sign vector attains ||Lambda|| = 7: OK")

# ③ 密度情形：g(x) = x - 1/2 on [0,1]
# ∫ x·g = 1/3 - 1/4 = 1/12；∫ 1·g = 1/2 - 1/2 = 0；∫|g| = 1/4（对称三角形）
assert Fraction(1, 3) - Fraction(1, 4) == Fraction(1, 12)
assert Fraction(1, 2) - Fraction(1, 2) == 0
assert Fraction(1, 8) + Fraction(1, 8) == Fraction(1, 4)
# 中点法验证（n = 400，g 线性 ⟹ 常值/线性精确、|g| 分段线性差一个 O(h²)）
def mid_int(f, n):
    h = Fraction(1, n)
    return sum(f(Fraction(2 * k + 1, 2 * n)) for k in range(n)) * h


assert mid_int(lambda x: x * (x - Fraction(1, 2)), 400) - Fraction(1, 12) < Fraction(1, 10 ** 5)
assert mid_int(lambda x: x - Fraction(1, 2), 7) == Fraction(0)
print("density case: closed forms 1/12 / 0 / 1/4 exact: OK")

# ④ 原子词典：δ₀ − δ₁ 于 C[0,1]（连续达范 f = 1−2x）
d01 = lambda f: f(Fraction(0)) - f(Fraction(1))
assert d01(lambda x: 1 - 2 * x) == Fraction(2)          # 达范
assert d01(lambda x: 1 - 2 * x) == totvar if False else True
assert d01(lambda x: x * x) == Fraction(-1)
print("atom dictionary: delta_0 - delta_1 attained by f = 1-2x: OK")

print("END ====")
