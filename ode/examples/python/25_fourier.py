print("==== 25 fourier")

# 第 25 章：Fourier 级数（numpy 版）。
import math
import numpy as np

# (a) 方波系数 b_n = 4/(pi n)（数值积分）
sq = lambda x: np.where(x < 0, -1.0, 1.0)
for n in [1, 3, 5]:
    xs = np.linspace(-math.pi, math.pi, 400001)
    integrand = sq(xs) * np.sin(n * xs)
    bn = np.trapezoid(integrand, xs) / math.pi
    assert abs(bn - 4 / (math.pi * n)) < 1e-4
print("square wave: b_n = 4/(pi n) at n = 1, 3, 5")

# (b) 收敛：跳跃点 → 中点 0；π/2 → 1
def sq_partial(x, N):
    s = 0.0
    for n in range(1, N + 1, 2):
        s += 4 / (math.pi * n) * math.sin(n * x)
    return s

assert abs(sq_partial(0.0, 1001)) < 1e-12
assert abs(sq_partial(math.pi / 2, 1001) - 1.0) < 5e-3
print("convergence: jump point -> midpoint 0, x = pi/2 -> 1")

# (c) Gibbs：过冲 = 8.95% × 跳跃 2 ≈ 0.179
for N in [200, 1000]:
    xs = np.linspace(0.0001, 2 * math.pi / N, 400)
    vals = np.abs([sq_partial(x, N) for x in xs])
    over = vals.max() - 1.0
    assert 0.15 < over < 0.19, f"Gibbs overshoot N={N}: {over}"
print("Gibbs: overshoot ~ 0.179 = 8.95% of jump 2, persists with N")

# (d) Parseval：Σb_n^2 = (1/π)∫f^2 = 2
sumsq = sum((4 / (math.pi * n))**2 for n in range(1, 2002, 2))
assert abs(sumsq - 2.0) < 0.005
print(f"Parseval: sum b_n^2 = {sumsq:.4f} ~ 2 = (1/pi) int f^2")

# (e) 速率：x^2 的 a_n = 4(-1)^n/n^2
for n in [3, 7]:
    xs = np.linspace(0, math.pi, 200001)
    an = 2 / math.pi * np.trapezoid(xs**2 * np.cos(n * xs), xs)
    assert abs(an - 4 * (-1)**n / n**2) < 1e-4
print("rate: a_n(x^2) = 4(-1)^n/n^2 (1/n^2 decay, derivative jump)")

# (f) 复形式：c_n = (a_n - i b_n)/2 核对（取方波：a_n = 0, b_n = 4/pi）
n = 5
cn_real = 0.0
cn_imag = -(4 / (math.pi * n)) / 2
xs = np.linspace(-math.pi, math.pi, 400001)
cn = np.trapezoid(sq(xs) * np.exp(-1j * n * xs), xs) / (2 * math.pi)
assert abs(cn.real - cn_real) < 1e-4 and abs(cn.imag - cn_imag) < 1e-4
print("complex form: c_5 = -i b_5/2 verified by numerical projection")

print("END ====")
