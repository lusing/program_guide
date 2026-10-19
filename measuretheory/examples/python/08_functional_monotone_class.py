print("==== 08 functional_monotone_class")
# 第 08 章 Python 通道：函数单调类定理的精确有理数模型。
# ① π-类判据的乘积封闭检验（定理 2.2.4 的假设侧，精确分数）；
# ② 非 π 类的反向验证：I2 = I12·I23 逃出 λ-闭包（线性包刻画）；
# ③ 平方根迭代 P_{n+1} = P_n + (t - P_n^2)/2 单调上升逼近 √t
#    （"闭包里造根号"，格运算的代数内核）。

from fractions import Fraction as Fr
import itertools

I12 = (Fr(1), Fr(1), Fr(0), Fr(0))
I23 = (Fr(0), Fr(1), Fr(1), Fr(0))
ONE = (Fr(1), Fr(1), Fr(1), Fr(1))

def lin_span(gens):
    """由生成元张成的线性包（精确整数系数格 [-4..4]，避免大分数环的
    O(n^2) Fraction 乘积拖慢；生成元 ≤ 2 个时覆盖所需组合）。"""
    coef_grid = [Fr(k) for k in range(-4, 5)]
    out = set()
    if len(gens) == 1:
        g0 = gens[0]
        for a in coef_grid:
            out.add(tuple(a * x for x in g0))
    else:
        g0, g1 = gens
        for a in coef_grid:
            for b in coef_grid:
                out.add(tuple(a * x + b * y for x, y in zip(g0, g1)))
    return out

# --- ① π-类判据的乘积封闭（假设侧检验） ---
# C = {∅, {1,2}, Ω} 是 π-系；Λ 闭包 ⊇ 线性包（保守下界）。
span_pi = lin_span([I12, ONE])
# 假设侧：C 中两元的乘积仍在"块常数"族内（精确判定）
def block_const(f):
    return f[0] == f[1] and f[2] == f[3]

for g1 in (I12, ONE):
    for g2 in (I12, ONE):
        prod = tuple(x * y for x, y in zip(g1, g2))
        assert block_const(prod), prod
print("pi-class: products of C-members stay block-constant (criterion holds): OK")

# --- ② 非 π 类：I2 = I12·I23 逃出 λ-闭包 ---
# λ-闭包含 I23 的线性包；若 I2 在其中，则存在 a,b 使 a·I23 + b·1 = I2。
span_np = lin_span([I23, ONE])
I2 = tuple(x * y for x, y in zip(I12, I23))   # (0,1,0,0)
assert I2 not in span_np
print("non-pi class: I_{2} = I_{1,2}*I_{2,3} escapes the lambda-closure: OK")

# 交叉验证：块常数族对乘积封闭（阶段二自举在集合刻画层面的影子）
for A in span_pi:
    for B in span_pi:
        assert block_const(tuple(x * y for x, y in zip(A, B)))
print("two-stage bootstrap shadow: block-constant family closed under product: OK")

# --- ③ 平方根迭代（多项式版，逐层误差递减） ---
# 两条实测纪律：① 精确分数版的分母每步平方级增长（d_{k+1} ≈ 2·d_k²），
# 步数必须节制（30 步 = 天文数字，实测挂死）；② 收敛比率是 1 − √t，
# t 离 1 越近越快——t = 9/10 时 12 步即达 1e-12。
def sqrt_poly_iter(t, n):
    p = Fr(0)
    for _ in range(n):
        p = p + (t - p * p) / 2
    return p

import math
for t in (Fr(9, 10), Fr(81, 100)):
    p = sqrt_poly_iter(t, 12)
    assert p * p <= t                      # 精确有理断言：恒在 √t 下方
    err = abs(float(p - math.sqrt(float(t))))
    assert err < 1e-10, (t, err)           # 浮点层面对拍（容差给舍入留量）
print("sqrt iteration P_{n+1} = P_n + (t - P_n^2)/2 rises to sqrt(t): OK")

print("END ====")
