print("==== 29 fredholm")

# 第 29 章：积分方程（scipy 对照版）。
import math
from scipy.integrate import quad

# (a) 退化核 Fredholm：K=1，y = 1/(1-lambda)
lam = 0.5
y = 1.0
for _ in range(60):
    y = 1.0 + lam * y
assert abs(y - 2.0) < 1e-12
print("degenerate kernel: iteration converges geometrically to y = 2")

# 共振发散
y2, diverged = 1.0, False
for _ in range(80):
    y2 = 1.0 + 2.0 * y2
    if abs(y2) > 1e10:
        diverged = True
        break
assert diverged
print("lambda(b-a) = 2: Neumann series diverges (resonance)")

# (b) Volterra：y = 1 + int_0^x (x-t)y dt -> y = cosh x
def volterra_iter(N, ngrid=400):
    xs = [i / ngrid for i in range(ngrid + 1)]
    h = 1 / ngrid
    y = [1.0] * (ngrid + 1)
    for _ in range(N):
        ynew = [1.0] * (ngrid + 1)
        for i in range(1, ngrid + 1):
            x = xs[i]
            s = 0.0
            for j in range(i + 1):
                t = xs[j]
                w = 0.5 if j in (0, i) else 1.0
                s += w * (x - t) * y[j]
            ynew[i] = 1.0 + s * h
        y = ynew
    return y[-1]

yv = volterra_iter(30)
assert abs(yv - math.cosh(1.0)) < 1e-4
print(f"Volterra K=x-t: y(1) = {yv:.6f} vs cosh(1) = {math.cosh(1):.6f}")

# (c) 差核 Laplace：y = 1 + int e^{-(x-t)}y -> y = 1 + x
def diffkernel(N, ngrid=400):
    xs = [2 * i / ngrid for i in range(ngrid + 1)]
    h = 2 / ngrid
    y = [1.0] * (ngrid + 1)
    for _ in range(N):
        ynew = [1.0] * (ngrid + 1)
        for i in range(1, ngrid + 1):
            x = xs[i]
            s = 0.0
            for j in range(i + 1):
                t = xs[j]
                w = 0.5 if j in (0, i) else 1.0
                s += w * math.exp(-(x - t)) * y[j]
            ynew[i] = 1.0 + s * h
        y = ynew
    return y, xs

y3, xs3 = diffkernel(40)
for i in [100, 200, 400]:
    assert abs(y3[i] - (1 + xs3[i])) < 2e-3
print("difference kernel via Laplace: y = 1 + x matches iteration")

print("END ====")
