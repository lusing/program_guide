# 24_variational.py —— 第 24 章：古典变分（Python 通道，独立复算）

import math

print("==== 24 variational")

g = 9.8

def solve_theta1():
    t = 2.0
    for _ in range(60):
        fv = t - math.sin(t) - (1 - math.cos(t))
        t -= fv / (1 - math.cos(t) + math.sin(t))
    return t

th1 = solve_theta1()
R = 1 / (1 - math.cos(th1))
T_bra = th1 * math.sqrt(R / g)
print(f"brachistochrone: theta1 = {th1:.6f}, R = {R:.6f}")
print(f"  descent time along cycloid = {T_bra:.6f} s")

def time_along(yc):
    n = 20000
    t = 0.0
    for i in range(1, n):
        x1 = (i - 1) / n
        x2 = i / n
        y1, y2 = yc(x1), yc(x2)
        ds = math.hypot(x2 - x1, y2 - y1)
        ym = max((y1 + y2) / 2, 1e-12)
        t += ds / math.sqrt(2 * g * ym)
    return t

t_line = time_along(lambda x: x)
print(f"  straight line time = {t_line:.6f} s (slower)")
assert t_line > T_bra

def time_cycloid():
    n = 20000
    t = 0.0
    for i in range(1, n + 1):
        ta = (i - 1) / n * th1
        tb = i / n * th1
        dsdth = math.hypot(1 - math.cos(ta), math.sin(ta)) * R
        ds = dsdth * (tb - ta)
        ym = max(R * (1 - math.cos((ta + tb) / 2)), 1e-12)
        t += ds / math.sqrt(2 * g * ym)
    return t

t_cyc = time_cycloid()
print(f"  cycloid parametric quadrature = {t_cyc:.6f} s")
assert abs(t_cyc - T_bra) < 2e-4, (t_cyc, T_bra)

yopt = lambda x: math.sinh(x) / math.sinh(1)
resid = 0.0
hh = 1e-3
for k in range(1, 19):
    x = 0.05 * k
    ypp = (yopt(x + hh) - 2 * yopt(x) + yopt(x - hh)) / hh**2
    resid = max(resid, abs(ypp - yopt(x)))
assert resid < 1e-5, resid
print(f"Euler equation: sinh(x)/sinh(1) satisfies y'' = y, resid = {resid:.2e}")

def Jfunc(yc):
    n = 10000
    s = 0.0
    for i in range(1, n):
        x = i / n
        dy = (yc(x + 1e-6) - yc(x - 1e-6)) / 2e-6
        s += (dy * dy + yc(x) ** 2) / n
    return s

Js = Jfunc(yopt)
print(f"J(sinh-curve) = {Js:.6f}")
for a in (0.8, 1.0, 1.3):
    Jx = Jfunc(lambda x, a=a: x ** a)
    print(f"  J(x^{a}) = {Jx:.6f} (larger)")
    assert Jx > Js

N = 50
h = 1.0 / N
u = [i * h + 0.3 * math.sin(math.pi * i * h) for i in range(N + 1)]
for it in range(1, 200001):
    grad = [0.0] * (N + 1)
    for i in range(1, N):
        sl = (u[i] - u[i - 1]) / h
        sr = (u[i + 1] - u[i]) / h
        grad[i] = sl / math.sqrt(1 + sl * sl) - sr / math.sqrt(1 + sr * sr)
    for i in range(1, N):
        u[i] -= 0.5 * h * grad[i]
maxdev = max(abs(u[i] - i * h) for i in range(N + 1))
assert maxdev < 0.02, maxdev
print(f"minimal surface: converges to straight line, dev = {maxdev:.5f}")

print("END ====")
