# 01_prelim.py —— 第 01 章：典型方程、定解问题与依赖区间（Python 通道，独立复算）

import math

print("==== 01 prelim")

# ---------- (1) 二阶方程分类引擎 ----------
def classify(a, b, c):
    d = a * c - b * b
    if d > 0:
        return "elliptic"
    if d < 0:
        return "hyperbolic"
    return "parabolic"

assert classify(1.0, 0.0, 1.0) == "elliptic"
assert classify(1.0, 0.0, 0.0) == "parabolic"
assert classify(1.0, 0.0, -1.0) == "hyperbolic"
# 书上例外的两个：一阶对流方程（双曲，看成方程组 A=[-a] 有实特征值）；
# C-R 方程组（椭圆）。二阶框架外的这两个在第 02/07 章再机器化。
print("classify: Laplace elliptic / heat parabolic / wave hyperbolic")

cwave = 2.0
F = lambda s: math.exp(-s * s)
for k in range(11):
    t = 0.1 * k
    x = 4.0 - cwave * t
    assert abs(F(x + cwave * t) - F(4.0)) < 1.0e-14
print("characteristic check: F(x + c t) constant along x + c t = const")

# ---------- (2) D'Alembert 公式 ----------
gfun = lambda x: math.exp(-(x - 1.0) ** 2)
hfun = lambda x: math.sin(x)

def simpson(f, a, b, n):
    hh = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 == 1 else 2) * f(a + i * hh)
    return s * hh / 3

def dalembert(x, t, c=cwave, n=2000):
    base = 0.5 * (gfun(x + c * t) + gfun(x - c * t))
    return base + simpson(hfun, x - c * t, x + c * t, n) / (2 * c)

def dalembert_exact_h(x, t, c=cwave):
    lo, hi = x - c * t, x + c * t
    return 0.5 * (gfun(x + c * t) + gfun(x - c * t)) + (math.cos(lo) - math.cos(hi)) / (2 * c)

for (x, t) in ((0.7, 0.3), (1.2, 0.5), (0.0, 0.4)):
    err = abs(dalembert(x, t) - dalembert_exact_h(x, t))
    assert err < 1.0e-10, err
print("D'Alembert: trapezoid vs closed-form integral agree to 1e-10")

x0, t0 = 0.6, 0.25
def wave_resid(dh):
    utt = (dalembert(x0, t0 + dh) - 2 * dalembert(x0, t0) + dalembert(x0, t0 - dh)) / dh**2
    uxx = (dalembert(x0 + dh, t0) - 2 * dalembert(x0, t0) + dalembert(x0 - dh, t0)) / dh**2
    return abs(utt - cwave**2 * uxx)

r1, r2 = wave_resid(1.0e-2), wave_resid(5.0e-3)
assert 3.5 < r1 / r2 < 4.5, f"ratio should be ~4 ({r1 / r2})"
print(f"D'Alembert residual u_tt - c^2 u_xx: h->h/2 ratio = {r1 / r2:.3f}  (2nd order)")

# ---------- (3) 依赖区间 ----------
lo, hi = x0 - cwave * t0, x0 + cwave * t0
def g2(x):
    extra = 100.0 * (x - (lo - 0.05)) ** 2 if x < lo - 0.05 else 0.0
    return math.exp(-(x - 1.0) ** 2) + extra

def dalembert_g(gx, x, t, c=cwave, n=2000):
    base = 0.5 * (gx(x + c * t) + gx(x - c * t))
    return base + simpson(hfun, x - c * t, x + c * t, n) / (2 * c)

u1 = dalembert_g(gfun, x0, t0)
u2 = dalembert_g(g2, x0, t0)
assert abs(u1 - u2) < 1.0e-14, "perturbation outside the interval should not matter"
print("domain of dependence: perturbing g outside [x0-ct0, x0+ct0] leaves u(x0,t0) unchanged")

def g3(x):
    extra = 1.0 if abs(x - (x0 + cwave * t0)) < 0.05 else 0.0
    return math.exp(-(x - 1.0) ** 2) + extra

u3 = dalembert_g(g3, x0, t0)
assert abs(u3 - u1) > 0.4
print(f"perturbing g at the endpoint x0+ct0 changes u(x0,t0) by {abs(u3 - u1):.3f}")

def h3(x):
    extra = 1.0 if abs(x - x0) < 0.1 else 0.0
    return hfun(x) + extra

u4 = (0.5 * (gfun(x0 + cwave * t0) + gfun(x0 - cwave * t0))
      + simpson(h3, x0 - cwave * t0, x0 + cwave * t0, 4000) / (2 * cwave))
assert abs(u4 - u1) > 0.05
print(f"perturbing h inside the interval changes u(x0,t0) by {abs(u4 - u1):.3f}")

print("END ====")
