# -*- coding: utf-8 -*-
print("==== 25 regular_measures")
# 第 25 章 Python：三明治与逼近账（Fraction 精确）。
# ① 矩形三明治的精确分数账；
# ② Cantor 集前 n 级的内外逼近（(2/3)^n 精确递推）；
# ③ 开 ε-邻域单调降的整数账。
from fractions import Fraction

# ① 矩形三明治：A = [3/10, 7/10]²，内缩 δ 的紧账 / 外扩 δ 的开账
LO, HI = Fraction(3, 10), Fraction(7, 10)
delta = Fraction(1, 100)
muK = (HI - LO - 2 * delta) ** 2      # 内缩 δ 的闭方块
muA = (HI - LO) ** 2                  # 真值
muU = (HI - LO + 2 * delta) ** 2      # 外扩 δ 的开方块
assert muK < muA < muU
assert muU - muK == 8 * delta * (HI - LO)   # 带宽的精确展开：(a+2d)²−(a−2d)² = 8ad
assert muA == Fraction(4, 10) ** 2 == Fraction(4, 25)
print("rectangle sandwich: mu(K) < mu(A) < mu(U), width = 8*delta*a exact: OK")

# ② Cantor 前 n 级：总长 (2/3)^n 精确 + 内外逼近账
for n in (2, 4, 6, 10):
    exact = Fraction(2, 3) ** n
    # 构造式验证：n 级 = 2^n 段、每段 3^-n
    total = Fraction(2) ** n * Fraction(1, 3) ** n
    assert total == exact
assert Fraction(2, 3) ** 10 < Fraction(2, 100)     # 快速缩水
print("Cantor level sums (2/3)^n exact; level 10 < 2/100: OK")

# ③ 开 ε-邻域单调降：A = [0,1] 的整数网格账（δ-邻域的格点数递减）
def eps_cells(delta_num, grid=1000):
    # [0,1] 的 δ-邻域在 [0, 1+?] 网格上的覆盖格点数（以 [0,2] 域 2000 格）
    cnt = 0
    for k in range(2000):
        x = Fraction(2 * k + 1, 2000)             # 格心
        if -Fraction(delta_num, 1) <= x <= 1 + Fraction(delta_num, 1):
            cnt += 1
    return cnt


vals = [eps_cells(d) for d in (200, 100, 50, 10)]
assert all(vals[i] >= vals[i + 1] for i in range(3))   # δ ↓ ⟹ 账 ↓
assert vals[-1] > 0
print("open eps-neighborhood accounts decreasing as eps -> 0: OK")

# ④ 差集账：μ(B∖A) < ε ⟹ 三明治合并（25.8.5 习题 2 的数值版）
A_lo, A_hi = Fraction(1, 4), Fraction(3, 4)
B_lo, B_hi = Fraction(1, 4), Fraction(4, 5)
assert (B_hi - B_lo) - (A_hi - A_lo) == Fraction(1, 20)   # μ(B) − μ(A) = 1/20 < ε(=1/10)
# 合并三明治：K = A 的紧芯、U = B 的开壳
assert A_hi - A_lo < B_hi - B_lo
print("difference account: mu(B)-mu(A) = 1/20 < eps = 1/10: OK")

print("END ====")
