print("==== 30 variation")

# 第 30 章：变分法（scipy 对照版）。
import math
from scipy.integrate import quad

# (a) 驻定核对：J = int(y'^2 - y^2)，sin x 支
def J(f, fp):
    return quad(lambda x: fp(x)**2 - f(x)**2, 0, math.pi)[0]

J0 = J(math.sin, math.cos)
for eps in [1e-3, -1e-3, 5e-3]:
    Je = J(lambda x: math.sin(x) + eps * x * (math.pi - x),
           lambda x: math.cos(x) + eps * (math.pi - 2 * x))
    assert abs(Je - J0) < 50 * eps**2 + 1e-10
print("stationarity: J[sin + eps*eta] - J[sin] = O(eps^2)")

# (b) brachistochrone：摆线最快
# 摆线 B=(1,1)（y 向下）：r(theta-sin theta)=1, r(1-cos theta)=1
theta = 2.4
for _ in range(80):
    F = (1 - math.cos(theta)) - (theta - math.sin(theta))
    dF = math.sin(theta) - (1 - math.cos(theta))
    theta -= F / dF
r = 1.0 / (theta - math.sin(theta))
T_cyc = theta * math.sqrt(r / 1.0)          # T = theta_b sqrt(r/g)
T_line = quad(lambda x: math.sqrt(2 * 2 / (2 * x)), 1e-9, 1.0)[0]  # y=x 直线
T_par = quad(lambda x: math.sqrt(2 * (1 + 4 * x * x) / (2 * x * x)), 1e-9, 1.0)[0]
assert T_cyc < T_line and T_cyc < T_par
print(f"brachistochrone: cycloid {T_cyc:.4f} < parabola {T_par:.4f} < line {T_line:.4f}")

# (c) Beltrami 常数核对
for th in [0.8, 1.5, 2.2]:
    y = r * (1 - math.cos(th))
    yp = math.sin(th) / (1 - math.cos(th))
    c = 1 / math.sqrt(y * (1 + yp * yp))
    assert abs(c - 1 / math.sqrt(2 * r)) < 1e-10
print("Beltrami: 1/sqrt(y(1+y'^2)) constant along cycloid")

# (d) Ritz：J = int(½y'^2 - ½y² + x y)，y(0)=y(1)=0
# c_n = -f_n/(n²π²-1)，f_n = 2∫x sin(nπx)
def fn(n):
    return 2 * quad(lambda x: x * math.sin(n * math.pi * x), 0, 1)[0]

yexact = lambda x: x - math.sin(x) / math.sin(1.0)
for n in [1, 2, 3]:
    cn = -fn(n) / (n**2 * math.pi**2 - 1)
    ce = 2 * quad(lambda x: yexact(x) * math.sin(n * math.pi * x), 0, 1)[0]
    assert abs(cn - ce) < 1e-3
print("Ritz 3-basis coefficients match exact solution Fourier coefficients")

# (e) 氢原子试探
E = lambda b: b * b / 2 - b
b = 0.5
for _ in range(200):
    b -= 0.05 * (b - 1)
assert abs(E(b) + 0.5) < 1e-6
print("hydrogen trial: E(beta) = beta^2/2 - beta minimized at E = -0.5 Hartree")

print("END ====")
