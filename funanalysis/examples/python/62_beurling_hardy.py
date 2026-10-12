import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(6262)
print("==== 62 Beurling 与 Hardy (Python) ====")

# ---------------------------------------------------------------
# 实验 1：内函数（有限 Blaschke）的判定。
# ---------------------------------------------------------------
def blaschke(z, a):
    return (z - a) / (1 - np.conj(a) * z)

m = 1024
th = np.arange(m) * 2 * np.pi / m
z = np.exp(1j * th)
p = blaschke(z, 0.3) * blaschke(z, -0.5) * blaschke(z, 0.2j)
assert np.max(np.abs(np.abs(p) - 1)) < 1e-14        # |p| = 1 于圆周
# 系数模：p 的 Fourier 系数（前若干项）
ph = np.fft.fft(p) / m
assert np.max(np.abs(ph[-5:])) < 0.05               # 负频尾部小（H⁺ 函数）
print(f"实验1 Blaschke(0.3)·(−0.5)·(0.2i)：圆周 |p| = 1（1e-14）；H⁺ 性（负频尾部 < 0.05）")

# ---------------------------------------------------------------
# 实验 2：正交分解 (12) 与 M 一维。
# N = span{p, zp, ..., z⁵p}；zN 的基与 N 的 Gram = m·[0|I]。
# ---------------------------------------------------------------
J = 5
basis_N = [z ** j * p for j in range(J + 1)]
basis_zN = basis_N[1:]
G = np.array([[np.vdot(u, v) for v in basis_N] for u in basis_zN])
ideal = np.zeros((J, J + 1), dtype=complex)
for i in range(J):
    ideal[i, i + 1] = m
assert np.linalg.norm(G - ideal) / m < 1e-13        # Gram 结构
for k in range(1, J + 1):
    assert abs(np.vdot(p, z ** k * p)) / m < 1e-14  # p ⊥ z^k p
# |m|² 的 Fourier 系数除直流外全零
abs2p = np.abs(p) ** 2
coeffs = np.fft.fft(abs2p)
assert np.max(np.abs(coeffs[1:])) / abs(coeffs[0]) < 1e-14
print(f"实验2 Gram = m·[0|I]（1e-13）；p ⊥ z^k p（1e-14）；|p|² 只有直流分量（1e-14）")

# ---------------------------------------------------------------
# 实验 3：外函数的 Poisson 重构。
# 模 w → u_r = exp(P_r * log w)：极值原理 + r→1 逼近。
# ---------------------------------------------------------------
w = 0.5 + 0.4 * np.cos(th)
logw = np.log(w)
dth = 2 * np.pi / m
for r in (0.5, 0.9):
    K = (1 - r ** 2) / (1 - 2 * r * np.cos(th[:, None] - th[None, :]) + r ** 2) / (2 * np.pi)
    u_r = np.exp((K @ logw) * dth)
    assert u_r.min() >= w.min() - 1e-9 and u_r.max() <= w.max() + 1e-9
K = (1 - 0.99 ** 2) / (1 - 2 * 0.99 * np.cos(th[:, None] - th[None, :]) + 0.99 ** 2) / (2 * np.pi)
u_r = np.exp((K @ logw) * dth)
assert np.max(np.abs(u_r - w)) < 0.15               # 分辨率内重构
print(f"实验3 外函数 exp(P·log w)：极值原理成立；r=0.99 重构边界模（分辨率内 {np.max(np.abs(u_r - w)):.3f}）")

print("END ====")
