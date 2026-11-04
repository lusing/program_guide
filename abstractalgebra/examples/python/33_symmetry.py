# 第 33 章 · 装饰的对称 —— Python 通道
#
# 仿射等距 ((sx, sy), c) 的精确有理表示 + 带群窗口 + 点群 +
# 晶体学限制（整数矩阵阶枚举 + sympy 精确迹论证）。

import itertools
from fractions import Fraction as F

import sympy as sp

print("==== 33 装饰的对称")

# ---------- 仿射等距：((sx, sy), (cx, cy))，z ↦ (sx·x + cx, sy·y + cy) ----------
def comp(g, h):
    (sx, sy), (cx, cy) = g
    (tx, ty), (dx, dy) = h
    return ((sx * tx, sy * ty), (sx * dx + cx, sy * dy + cy))


T = ((1, 1), (F(1), F(0)))          # 单位平移
TINV = ((1, 1), (F(-1), F(0)))
RHO = ((1, -1), (F(1, 2), F(0)))    # 滑动反射
RH = ((-1, -1), (F(0), F(0)))       # 半翻转 R
AL = ((1, -1), (F(0), F(0)))        # α（x-轴反射）
BE = ((-1, 1), (F(0), F(0)))        # β（y-轴反射）
ID = ((1, 1), (F(0), F(0)))

def inv(g):
    (sx, sy), (cx, cy) = g
    return ((sx, sy), (F(-cx) / sx if sx < 0 else -cx,
                       F(-cy) / sy if sy < 0 else -cy))

# 关系式（定理 6.42 的基础代数，全部精确相等）
assert comp(RHO, RHO) == T                       # ρ² = t
assert comp(RH, RH) == ID and comp(AL, AL) == ID and comp(BE, BE) == ID
assert comp(BE, AL) == RH                        # βα = R
assert comp(AL, T) == comp(T, AL)                # αt = tα
assert comp(BE, T) == comp(TINV, BE)             # βt = t⁻¹β
assert comp(RH, T) == comp(TINV, RH)             # Rt = t⁻¹R
assert inv(T) == TINV and inv(RHO) == ((1, -1), (F(-1, 2), F(0)))
print("关系式：ρ²=t、R²=α²=β²=1、βα=R、αt=tα、βt=t⁻¹β、Rt=t⁻¹R（有理精确）✓")

# ---------- 带群窗口 ----------
def frieze_window(gens, W=3):
    gensfull = gens + [inv(g) for g in gens]
    S = {ID}
    changed = True
    while changed:
        changed = False
        for a in list(S):
            for g in gensfull:
                p = comp(a, g)
                (sx, sy), (cx, cy) = p
                if abs(cx) <= W and cy == 0:
                    if p not in S:
                        S.add(p)
                        changed = True
    return S


F1 = frieze_window([T])
F2 = frieze_window([T, RH])
F4 = frieze_window([T, AL])
F7 = frieze_window([T, RH, AL])
assert (len(F1), len(F2), len(F4), len(F7)) == (7, 14, 14, 28)
print("带群窗口：F₁=7、F₂=14、F₄=14、F₇=28（对 ⟨t⟩ 指数 1/2/2/4）✓")

# ---------- 点群 ----------
def point_group(G):
    return {lin for lin, _ in G}


assert point_group(F1) == {(1, 1)}
assert point_group(F2) == {(1, 1), (-1, -1)}
assert point_group(F4) == {(1, 1), (1, -1)}
V4 = point_group(F7)
assert V4 == {(1, 1), (1, -1), (-1, 1), (-1, -1)}
sgn_mul = lambda a, b: (a[0] * b[0], a[1] * b[1])       # 分量乘
assert all(sgn_mul(a, b) in V4 for a in V4 for b in V4)  # 乘法封闭
assert all(sgn_mul(a, a) == (1, 1) for a in V4)          # 全员自逆
assert all(sgn_mul(a, b) == sgn_mul(b, a) for a in V4 for b in V4)  # 交换 ≅ V₄
print("点群：四个子群 {1}、{1,R}、{1,α}、V₄；V₄ 封闭、自逆、交换 ✓")

# ---------- F₅ = ⟨ρ⟩ ≅ ℤ ----------
# ρ² = t ⟹ ⟨t⟩ ≤ ⟨ρ⟩ ≤ ⟨t⟩ ⊔ ρ⟨t⟩ ⟹ ρ 无限阶，⟨ρ⟩ ≅ ℤ
assert comp(RHO, RHO) == T
print("F₅ = ⟨ρ⟩：ρ² = t ⟹ 无限循环 ≅ ℤ（与 F₁ 抽象同构、几何不同）✓")

# ---------- 晶体学限制 ----------
def mat_mul(A, B):
    (a, b), (c, d) = A
    (e, f), (g, h) = B
    return ((a * e + b * g, a * f + b * h), (c * e + d * g, c * f + d * h))


def mat_order(A):
    I = ((1, 0), (0, 1))
    if A == I:
        return 1
    X = mat_mul(A, A)
    k = 2
    while k <= 12 and X != I:
        X = mat_mul(A, X)
        k += 1
    return k if X == I else 0


orders = set()
for a, b, c, d in itertools.product((-1, 0, 1), repeat=4):
    if a * d - b * c in (1, -1):
        k = mat_order(((a, b), (c, d)))
        if k:
            orders.add(k)
assert orders == {1, 2, 3, 4, 6}                    # 无 5、无 ≥7
print("晶体学限制：{−1,0,1}⁴ 可逆矩阵的阶 ⊆ {1,2,3,4,6} ✓")

# 迹论证的精确版：2cos(2π/n) ∈ ℤ 恰在 n ∈ {1,2,3,4,6}
for n, val in [(1, 2), (2, -2), (3, -1), (4, 0), (6, 1)]:
    assert sp.simplify(2 * sp.cos(2 * sp.pi / n) - val) == 0
# 阶 5：2cos(2π/5) = (√5 − 1)/2，黄金比倒数，无理
assert sp.simplify(2 * sp.cos(2 * sp.pi / 5) - (sp.sqrt(5) - 1) / 2) == 0
assert not (2 * sp.cos(2 * sp.pi / 5)).is_integer
# 阶 7 亦然
assert not (2 * sp.cos(2 * sp.pi / 7)).is_integer
print("迹论证（sympy 精确）：n ∈ {1,2,3,4,6} 迹 ∈ ℤ；n = 5 迹 = (√5−1)/2 无理 ✓")

print("END ====")
