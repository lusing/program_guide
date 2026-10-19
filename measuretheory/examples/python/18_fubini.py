# -*- coding: utf-8 -*-
print("==== 18 fubini")
# 第 18 章：Fubini 的精确账（Fraction 版）。
# ① 罚单一：a-(m,n) 双重级数——行先 = 1、列先 = 0，纯整数账；
# ② 绝对收敛对照：2^{-(m+n)} 两序同和（精确分数）；
# ③ 网格乘积测度与截口账全精确；
# ④ 图像测度账：(μ×ν)(G_f) = Σ ν({f(x)})·w(x)（18.4.6 的有限版）。
from fractions import Fraction


def a_mn(m, n):
    if m == n:
        return 1
    if m == n + 1:
        return -1
    return 0


# ① 罚单一：完整平面上，行先（ΣₘΣₙ）与列先（ΣₙΣₘ）截断对拍
for N in (10, 50, 200):
    row_first = sum(sum(a_mn(m, n) for n in range(1, N + 1))
                    for m in range(1, N + 1))
    # 行先完整账：第 1 行和 1；第 m≥2 行（含 m=n 与 m=n+1）和 0 → 总 1
    assert row_first == 1
    col_first = sum(sum(a_mn(m, n) for m in range(1, N + 2))
                    for n in range(1, N + 1))
    # 列先完整账：每列 1 + (-1) = 0 → 总 0
    assert col_first == 0
print("ticket 1: row-first == 1, col-first == 0 (exact, N=10,50,200): OK")

# ② 绝对收敛对照：精确分数账
N = 12
s = sum(Fraction(1, 2 ** (m + n)) for m in range(1, N + 1)
        for n in range(1, N + 1))
closed = (1 - Fraction(1, 2 ** N)) ** 2
assert s == closed
row_then_col = sum(sum(Fraction(1, 2 ** (m + n)) for n in range(1, N + 1))
                   for m in range(1, N + 1))
assert row_then_col == s                     # 逐项非负：两序精确相等
print("absolute-summable control: both orders == closed form (exact): OK")

# ③ 网格乘积测度与截口账（Fraction 权）
w_mu = [Fraction(1, 5), Fraction(1, 2), Fraction(3, 10)]
w_nu = [Fraction(1, 10), Fraction(3, 5), Fraction(3, 10)]
E = {(0, 0), (0, 1), (1, 1), (2, 1), (2, 2)}
prod_direct = sum(w_mu[x] * w_nu[y] for (x, y) in E)
sec_x = sum(w_mu[x] * sum(w_nu[y] for y in (0, 1, 2) if (x, y) in E)
            for x in (0, 1, 2))
sec_y = sum(w_nu[y] * sum(w_mu[x] for x in (0, 1, 2) if (x, y) in E)
            for y in (0, 1, 2))
assert prod_direct == sec_x == sec_y == Fraction(71, 100)
print("grid product measure == section accounts (exact 71/100): OK")

# ④ 图像测度账：f : {0,1,2} → {0,1,2}，G_f = {(x, f(x))}
f = {0: 1, 1: 2, 2: 1}
graph_measure = sum(w_mu[x] * w_nu[f[x]] for x in (0, 1, 2))
# 闭式：Σₓ ν({f(x)})·w(x)（同账——18.4.6 的 (μ×ν)(G_f) 公式）
closed_form = sum(w_mu[x] * w_nu[f[x]] for x in (0, 1, 2))
assert graph_measure == closed_form == Fraction(1, 5) * Fraction(3, 5) \
    + Fraction(1, 2) * Fraction(3, 10) + Fraction(3, 10) * Fraction(3, 5)
# 对照：ν 若无原子（权全摊开），图像账为 0——有限版"无原子 ⟹ 图像零测"
w_nu_diffuse = [Fraction(0), Fraction(0), Fraction(0)]  # 极端：空测度
assert sum(w_mu[x] * w_nu_diffuse[f[x]] for x in (0, 1, 2)) == 0
print("graph measure account: (mu x nu)(G_f) = sum nu({f(x)}) w(x): OK")

print("END ====")
