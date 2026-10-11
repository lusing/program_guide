"""第 04 章 · Riesz 表示定理的数值实验（Conway I.3）——scipy 通道。

对应 docs/04-riesz.md。
- 有限维：从 L 的基值重构表示向量 h0，验证 L(y) = <y, h0> 与 ||L|| = ||h0||；
- "解方程找表示向量"：给定泛函采样，最小二乘恢复 h0；
- L² 的 Parseval 预告：||g||² = Σ|系数|²。
"""

import numpy as np

rng = np.random.default_rng(2718)

print("==== 04 riesz (Python) ====")

# --- 实验 1：表示向量的构造（Isabelle 通道 rep_vec 的数值版）--------------
# L 由 3 个基值决定：h0 = (L(e1), L(e2), L(e3))
L = lambda y: 3 * y[0] + 4 * y[1] - y[2]
h0 = np.array([3.0, 4.0, -1.0])
ok = True
for _ in range(100):
    y = rng.standard_normal(3)
    ok &= abs(L(y) - y @ h0) < 1e-12
print("L(y) == <y, h0>:", "PASS" if ok else "FAIL")
assert ok
assert abs(L(h0) / np.linalg.norm(h0) - np.linalg.norm(h0)) < 1e-12

# --- 实验 2：从采样恢复表示向量（"Riesz 逆问题"）---------------------------
# 随机矩阵 Y 的列是采样点，L(Y) 已知，解最小二乘 Y^T h0 = L(Y)
Y = rng.standard_normal((3, 7))
samples = np.array([L(Y[:, j]) for j in range(7)])
h0_rec, *_ = np.linalg.lstsq(Y.T, samples, rcond=None)
print("recovered h0 =", np.round(h0_rec, 8), " true =", h0)
assert np.linalg.norm(h0_rec - h0) < 1e-10

# --- 实验 3：L²([0,1]) 的 Parseval 预告 ------------------------------------
# g(t) = sin(2πt) + 0.5cos(6πt)，Fourier 系数 (1, 0.5)（按规范正交基
# {sin(2πt), cos(2πt) 的倍频}），||g||² = 1/2 + 0.25/2 = 5/8
n = 400_000
t = rng.uniform(0, 1, n)
g = lambda s: np.sin(2 * np.pi * s) + 0.5 * np.cos(6 * np.pi * s)
norm_sq = np.mean(g(t) ** 2)
print("||g||_L2^2 numeric =", f"{norm_sq:.5f}", " exact = 5/8 =",
      f"{5/8:.5f}")
assert abs(norm_sq - 5 / 8) < 1e-2

print("==== 04 riesz END ====")
