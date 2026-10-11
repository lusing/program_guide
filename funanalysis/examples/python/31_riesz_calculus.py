import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
from scipy.linalg import expm

rng = np.random.default_rng(3131)
print("==== 31 riesz_calculus (Python) ====")
n = 6
A = rng.standard_normal((n, n))

# 全纯泛函演算：f(A) = V f(D) V⁻¹，与幂级数定义一致
S = np.eye(n); term = np.eye(n)
for k in range(1, 41):
    term = term @ A / k          # term = Aᵏ/k!
    S = S + term
vals, vecs = np.linalg.eig(A)
exp_eig = vecs @ np.diag(np.exp(vals)) @ np.linalg.inv(vecs)
e1 = np.linalg.norm(S - exp_eig)
e2 = np.linalg.norm(S - expm(A))
print(f"‖Σ Aᵏ/k! - V e^D V⁻¹‖ = {e1:.8f}")
print(f"‖Σ Aᵏ/k! - exp(A)‖ = {e2:.8f}")
assert e1 < 1e-7
assert e2 < 1e-8
print("幂级数 = 谱演算 = 内置 exp(A)：✓")

# Riesz 投影：隔离谱子集的投影。取 Re λ > 0 的特征值
pos = vals.real > 0
P = vecs @ np.diag(pos.astype(float)) @ np.linalg.inv(vecs)
p2 = np.linalg.norm(P @ P - P)
ap = np.linalg.norm(A @ P - P @ A)
print(f"P² - P 的范数 = {p2:.8f}")
print(f"AP - PA 的范数 = {ap:.8f}")
assert p2 < 1e-8
assert ap < 1e-7
rank = np.linalg.matrix_rank(P)
print(f"rank P = {rank} = #(Re λ > 0) = {int(pos.sum())}")
assert rank == pos.sum()
print("Riesz 投影幂等、与 A 交换、秩 = 围道内谱点数：✓")
print("==== 31 riesz_calculus END ====")
