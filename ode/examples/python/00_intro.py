print("==== 00 intro")

# 第 00 章：解的核对——y = 2e^x - x - 1 是 y' = x + y、y(0) = 1 的解。
# Python 数值证据版（与 Julia 通道同一实验的独立实现）。

import math

def ysol(x):
    return 2 * math.exp(x) - x - 1

def rhs(x, y):
    return x + y

# --- 验证 1：代入残差（中心差商，误差 O(h²)）---
h = 1e-5
resid = max(
    abs((ysol(x + h) - ysol(x - h)) / (2 * h) - rhs(x, ysol(x)))
    for x in [i / 10 for i in range(-10, 11)]
)
assert resid < 1e-4, "代入残差应为 0（差商精度内）"
print(f"y' = x + y 代入残差（x∈[-1,1]，h=1e-5）: {resid}")

# --- 验证 2：解析导数核对 ---
def dysol(x):
    return 2 * math.exp(x) - 1

resid2 = max(
    abs(dysol(x) - rhs(x, ysol(x)))
    for x in [i / 10 for i in range(-10, 11)]
)
assert resid2 < 1e-14, "解析导数与右端应逐点相等"
print(f"解析导数核对残差: {resid2}")

# --- 验证 3：初值条件 ---
assert abs(ysol(0) - 1.0) < 1e-15, "y(0) = 1"
print(f"初值 y(0) = {ysol(0)}")

# --- 验证 4：反例——错解残差立刻暴露 ---
def wrong(x):
    return 2 * math.exp(x) - x  # 少了 -1

resid_w = max(
    abs((wrong(x + h) - wrong(x - h)) / (2 * h) - rhs(x, wrong(x)))
    for x in [i / 10 for i in range(-10, 11)]
)
assert resid_w > 0.5, "错解残差必须显著非零"
print(f"错解 2e^x - x 的残差（应 ~1）: {resid_w}")

# --- 验证 5：RK4 交叉验证（scipy.solve_ivp 独立复核）---
from scipy.integrate import solve_ivp

sol = solve_ivp(rhs, [0, 1], [1.0], rtol=1e-12, atol=1e-12)
err = abs(sol.y[0, -1] - ysol(1.0))
assert err < 1e-9, "solve_ivp 到 x=1 应咬住解析解"
print(f"solve_ivp 与解析解在 x=1 的差: {err}")

print("END ====")
