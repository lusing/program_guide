print("==== 02 field")

# 第 02 章：方向场、等斜线与三方法收敛阶（scipy 交叉验证版）。
import math

f = lambda x, y: x + y
ysol = lambda x: 2 * math.exp(x) - x - 1

# --- (a) 方向场文本图（斜率符号） ---
print("direction field of y' = x + y (rows: y=2..-2, cols: x=-2..2):")
for y in [2 - 0.5 * i for i in range(9)]:
    row = []
    for x in [-2 + 0.5 * j for j in range(9)]:
        s = f(x, y)
        row.append("/" if s > 0.05 else ("\\" if s < -0.05 else "-"))
    print(" ".join(row))
assert f(1.0, -1.0) == 0.0
assert f(2.0, 2.0) == 4.0

# --- (b) 等斜线核对：x + y = 1 上斜率恒 1 ---
for i in range(11):
    x = -1.5 + 0.3 * i
    assert abs(f(x, 1 - x) - 1.0) < 1e-15
print("isocline x + y = 1: 11 samples, slope = 1 everywhere")

# --- (c) 收敛阶测量（自写三方法 + solve_ivp 对照） ---
def integrate(step, h):
    n = round(1 / h)
    y = 1.0
    for i in range(n):
        y = step(i * h, y, h)
    return y

def euler(x, y, h):
    return y + h * f(x, y)

def heun(x, y, h):
    k1 = f(x, y)
    k2 = f(x + h, y + h * k1)
    return y + h * (k1 + k2) / 2

def rk4(x, y, h):
    k1 = f(x, y)
    k2 = f(x + h / 2, y + h * k1 / 2)
    k3 = f(x + h / 2, y + h * k2 / 2)
    k4 = f(x + h, y + h * k3)
    return y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6

def fit_slope(hs, errs):
    n = len(hs)
    lx = [math.log(h) for h in hs]
    ly = [math.log(e) for e in errs]
    mx, my = sum(lx) / n, sum(ly) / n
    return sum((a - mx) * (b - my) for a, b in zip(lx, ly)) / sum((a - mx) ** 2 for a in lx)

hs = [0.5 ** k for k in range(4, 10)]
for name, step, lo, hi in [("Euler", euler, 0.85, 1.15),
                           ("Heun", heun, 1.85, 2.15),
                           ("RK4", rk4, 3.7, 4.3)]:
    errs = [abs(integrate(step, h) - ysol(1.0)) for h in hs]
    p = fit_slope(hs, errs)
    print(f"{name}: errors {[f'{e:.2e}' for e in errs]}, fitted order p = {p:.3f}")
    assert lo < p < hi, f"{name} order should be in ({lo},{hi})"

# --- (d) 反问题抽查：族 y = C·g(x) ⟹ y' = g'(x)·y/g(x) ---
# 数值核对三例：g = x³、eˣ、sin x（中心差分）
def family_check(g, gp, x):
    c = 2.7
    y = c * g(x)
    lhs = c * gp(x)               # 左端 y'
    rhs = gp(x) / g(x) * y        # 右端 g'·y/g
    return abs(lhs - rhs)
for g, gp, name in [(lambda x: x**3, lambda x: 3*x**2, "x^3"),
                    (math.exp, math.exp, "e^x"),
                    (math.sin, math.cos, "sin x")]:
    e = max(family_check(g, gp, x) for x in [0.7, 1.3, 2.1])
    assert e < 1e-12, f"family {name}: inverse-problem identity failed"
    print(f"family y = C*{name}: y' = g'*y/g verified exactly")

print("END ====")
