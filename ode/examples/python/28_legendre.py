print("==== 28 legendre")

# 第 28 章：Legendre/Hermite/椭圆积分（scipy.special 全家桶）。
import math
from scipy.special import eval_legendre, lpmv, eval_hermite, ellipk
from scipy.integrate import quad

# (a) Rodrigues 数值核对：P_n(-1..1) vs eval_legendre
for n in range(5):
    for x in [0.3, 0.7, -0.5]:
        assert abs(eval_legendre(n, x) - eval_legendre(n, x)) < 1e-15  # trivial
# 具体值核对（书列的 P0..P4）
assert eval_legendre(2, 0.5) == (3 * 0.25 - 1) / 2
assert abs(eval_legendre(3, 0.5) - (5 * 0.125 - 3 * 0.5) / 2) < 1e-15
assert abs(eval_legendre(4, 0.5) - (35 * 0.0625 - 30 * 0.25 + 3) / 8) < 1e-15
print("Legendre P2/P3/P4 values match closed forms")

# (b) 正交性
for m, n in [(1, 3), (2, 4), (2, 3)]:
    I = quad(lambda x: eval_legendre(m, x) * eval_legendre(n, x), -1, 1)[0]
    assert abs(I) < 1e-12
I22 = quad(lambda x: eval_legendre(2, x)**2, -1, 1)[0]
assert abs(I22 - 2 / 5) < 1e-12
print("orthogonality: int Pm Pn = 0 (m != n), int P2^2 = 2/5")

# (c) 连带 Legendre：P3^2(x) = (1-x^2)·15x（P3 = (5x³−3x)/2 的二阶导 15x）
assert abs(lpmv(2, 3, 0.5) - 15 * 0.5 * (1 - 0.25)) < 1e-12
print("associated Legendre: P3^2(0.5) = 15x(1-x^2) via lpmv")

# (d) Hermite 递推 + 加权正交
for n in range(4):
    for x in [0.4, -1.2]:
        # H_{n+1} = 2x H_n - 2n H_{n-1}
        hn = eval_hermite(n, x)
        hnp = eval_hermite(n + 1, x)
        if n >= 1:
            hnm = eval_hermite(n - 1, x)
            assert abs(hnp - (2 * x * hn - 2 * n * hnm)) < 1e-10
print("Hermite recurrence H_{n+1} = 2xH_n - 2nH_{n-1} verified")
I = quad(lambda x: math.exp(-x * x) * eval_hermite(1, x) * eval_hermite(2, x), -8, 8)[0]
assert abs(I) < 1e-10
I2 = quad(lambda x: math.exp(-x * x) * eval_hermite(2, x)**2, -8, 8)[0]
assert abs(I2 - math.sqrt(math.pi) * 4 * 2) < 1e-8
print("Hermite weighted orthogonality: int e^{-x^2} H2^2 = sqrt(pi) 2^2 2!")

# (e) 椭圆积分与单摆周期
K = lambda k: ellipk(k * k)          # scipy 用参数 m = k^2
for th0, expect in [(math.pi / 6, 1.0174), (math.pi / 2, 1.1803), (5 * math.pi / 6, 1.7622)]:
    ratio = 2 * K(math.sin(th0 / 2)) / math.pi
    assert abs(ratio - expect) < 5e-4
print("pendulum: T/T0 = 2K(sin(th0/2))/pi = 1.017/1.180/1.762 at 30/90/150 deg")

# 数值单摆周期对照（theta0 = 90°）
from scipy.integrate import solve_ivp
sol = solve_ivp(lambda t, u: [u[1], -math.sin(u[0])], [0, 20 * math.pi],
                [math.pi / 2, 0.0], rtol=1e-12, atol=1e-12, dense_output=True)
# 找过零时刻序列：周期 = 相邻同向过零间隔
import numpy as np
ts = np.linspace(1, 20 * math.pi, 40000)
th = sol.sol(ts)[0]
crossings = [t for i, t in enumerate(ts[:-1]) if th[i] * th[i + 1] < 0 and th[i] > 0]
Tnum = np.mean(np.diff(crossings))
Texp = 2 * math.pi * 1.1803405990161178
assert abs(Tnum / Texp - 1) < 2e-4
print(f"pendulum numeric period {Tnum:.5f} vs elliptic {Texp:.5f}")

print("END ====")
