# 02_fourier.py —— 第 02 章：Fourier 变换与复数矩阵（Python 通道，独立复算）

import math
import numpy as np

print("==== 02 fourier")

def simpson(f, a, b, n):
    h = (b - a) / n
    s = f(a) + f(b)
    for i in range(1, n):
        s += (4 if i % 2 == 1 else 2) * f(a + i * h)
    return s * h / 3

L, n = 8.0, 4000
u = lambda x: math.exp(-x * x)
uhat = lambda k: math.exp(-k * k / 4) / math.sqrt(2.0)

for k in (0.0, 0.5, 1.0, 2.0):
    re = simpson(lambda x: u(x) * math.cos(k * x), -L, L, n) / math.sqrt(2 * math.pi)
    assert abs(re - uhat(k)) < 1.0e-8, (k, re, uhat(k))
    im_ = simpson(lambda x: -u(x) * math.sin(k * x), -L, L, n) / math.sqrt(2 * math.pi)
    assert abs(im_) < 1.0e-12
print("gauss pair: numeric FT of exp(-x^2) matches exp(-k^2/4)/sqrt(2) to 1e-8")

x0 = 0.7
inv = simpson(lambda k: uhat(k) * math.cos(k * x0), -10.0, 10.0, 5000) / math.sqrt(2 * math.pi)
assert abs(inv - u(x0)) < 1.0e-8
print("inverse FT at x0 = 0.7 recovers u(x0) to 1e-8")

dup = lambda x: -2 * x * math.exp(-x * x)
for k in (0.3, 1.0, 2.5):
    lhs_re = simpson(lambda x: dup(x) * math.cos(k * x), -L, L, n) / math.sqrt(2 * math.pi)
    lhs_im = simpson(lambda x: -dup(x) * math.sin(k * x), -L, L, n) / math.sqrt(2 * math.pi)
    rhs_re = -k * simpson(lambda x: -u(x) * math.sin(k * x), -L, L, n) / math.sqrt(2 * math.pi)
    rhs_im = k * simpson(lambda x: u(x) * math.cos(k * x), -L, L, n) / math.sqrt(2 * math.pi)
    assert abs(lhs_re) < 1.0e-12
    assert abs(lhs_re - rhs_re) < 1.0e-8
    assert abs(lhs_im - rhs_im) < 1.0e-8
print("derivative rule: Re F[u'](k) = -k Im(uhat), Im F[u'](k) = k Re(uhat)")

lhs = simpson(lambda x: u(x) ** 2, -L, L, n)
rhs = simpson(lambda k: uhat(k) ** 2, -L, L, n)
assert abs(lhs - rhs) < 1.0e-8
assert abs(lhs - math.sqrt(math.pi / 2)) < 1.0e-8  # int e^{-2x^2} = sqrt(pi/2)
print(f"Parseval: int|u|^2 = int|uhat|^2 = sqrt(pi/2) = {lhs:.6f}")

A_jordan = np.array([[1.0, 1.0], [0.0, 1.0]])
R_rot = np.array([[math.cos(0.7), -math.sin(0.7)], [math.sin(0.7), math.cos(0.7)]])
S_sym = np.array([[2.0, 1.0], [1.0, 2.0]])

for name, M in (("rotation(unitary)", R_rot), ("symmetric(hermite)", S_sym)):
    nrm = np.linalg.norm(M, 2)
    rho = max(abs(np.linalg.eigvals(M)))
    assert abs(nrm - rho) < 1.0e-12, name
    print(f"{name}: ||A||_2 = {nrm:.6f} = rho(A)")
nj = np.linalg.norm(A_jordan, 2)
rhoj = max(abs(np.linalg.eigvals(A_jordan)))
assert nj > rhoj + 0.5
print(f"jordan(not normal): ||A||_2 = {nj:.6f} > rho(A) = {rhoj}")

for r in (0.2, 0.5, 0.49):
    for s in (0.1, 0.5, 1.0):
        G = np.array([[-8 * r * s, 1.0], [1.0, 0.0]])
        assert max(abs(np.linalg.eigvals(G))) > 1.0 + 1.0e-12
print("Richardson growth matrix: max|eig| > 1 for every r,s (always unstable)")

U = np.array([[1.0, 1.0], [1.0, -1.0]]) / math.sqrt(2)
assert np.abs(U.conj().T @ S_sym @ U - np.diag([3.0, 1.0])).max() < 1.0e-14
assert np.abs(U.conj().T @ U - np.eye(2)).max() < 1.0e-14
print("hermite S = [2 1; 1 2]: U^H S U = diag(3, 1), U unitary (Hadamard)")

print("END ====")
