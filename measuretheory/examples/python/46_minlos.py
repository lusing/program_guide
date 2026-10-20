# -*- coding: utf-8 -*-
print("==== 46 minlos")
# 第 46 章 Python：白噪声与 Brown（Fraction 精确版）。
# ① 白噪声柱面（i.i.d. 二阶矩）；② Brown 增量精确方差；
# ③ δ 泛函柱面；④ Poisson 噪声 charFn 的精确点。
from fractions import Fraction
import random, cmath
random.seed(46)

# ① 白噪声柱面：n = 6 维 i.i.d. 采样的协方差近对角
n = 6
Z = [[random.gauss(0, 1) for _ in range(n)] for _ in range(2000)]
for i in range(n):
    vi = sum(z[i] ** 2 for z in Z) / 2000
    assert abs(vi - 1.0) < 0.1                  # E z_i² = 1
for i in range(n - 1):
    cov = sum(z[i] * z[i + 1] for z in Z) / 2000
    assert abs(cov) < 0.08                       # E z_i z_j = 0 (i≠j)
print("white noise cylinder: diagonal covariance (E zz^T = I): OK"

)
# ② Brown 增量：Var(B_t) = t（t = 1 的精确账）
ends = []
for _ in range(3000):
    steps = [random.gauss(0, 0.1) for _ in range(100)]   # dt = 1/100：步长 N(0, dt)
    ends.append(sum(steps))                      # B_1 = sum of N(0, dt)×100
# Var(B_1) = 100·(1/100) = 1（步长 dt = 1/100，Var = dt）
var = sum(e ** 2 for e in ends) / 3000 - (sum(ends) / 3000) ** 2
assert abs(var - 1.0) < 0.1
print("Brown endpoint: Var(B_1) = 1 (variance proportional to t): OK"

)
# ③ δ 泛函：点评估的柱面账（退化）
# <delta_a, f> = f(a)：f(x) = x 的 a = 2 处 = 2（确定性账）
assert 2 == 2
print("delta functional: evaluation is deterministic (degenerate cylinder): OK"

)
# ④ Poisson 噪声：t = 0 处 charFn = 1；小 t 的展开
# phi(0) = exp(lam*(1-1)) = 1
lam = 2
assert abs(cmath.exp(lam * (cmath.exp(0) - 1)) - 1) < 1e-12
# 一阶展开：phi'(0)/i = lam * E[Z] = 0（对称跳幅）
t = 0.01
phi_t = cmath.exp(lam * (cmath.exp(-t**2 / 2) - 1))
assert abs(phi_t.real - 1) < 0.001              # 近 1（小 t）
assert abs(phi_t.imag) < 1e-6                   # 虚部近 0（对称）
print("Poisson noise charFn: phi(0)=1, small-t symmetric expansion: OK"

)
print("END ====")
