import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
from scipy.linalg import null_space

rng = np.random.default_rng(2727)
print("==== 27 adjoint_banach (Python) ====")
n = 6
A = rng.standard_normal((n, n))

# Banach 伴随：(ℓ¹ₙ)* = ℓ∞ₙ，A 的伴随由转置实现
# ‖A‖₁ = ‖Aᵀ‖∞（列绝对和 = 转置的行绝对和）
op1 = np.abs(A).sum(axis=0).max()
opinf_T = np.abs(A.T).sum(axis=1).max()
opinf = np.abs(A).sum(axis=1).max()
op1_T = np.abs(A.T).sum(axis=0).max()
print(f"‖A‖₁  = {op1:.6f}   ‖Aᵀ‖∞ = {opinf_T:.6f}")
print(f"‖A‖∞  = {opinf:.6f}   ‖Aᵀ‖₁ = {op1_T:.6f}")
assert abs(op1 - opinf_T) < 1e-12
assert abs(opinf - op1_T) < 1e-12
print("伴随保范：‖A*‖ = ‖A‖（按 ℓ¹/ℓ∞ 对偶实现）：✓")

# 零化子关系：ker(Aᵀ) = range(A)⊥（有限维化身，用亏秩阵才有非平凡核）
W = rng.standard_normal((n, n))[:, :5] @ rng.standard_normal((5, n))
K = null_space(W.T)
assert K.shape[1] >= 1
for _ in range(5):
    x = rng.standard_normal(n)
    assert np.abs(K.T @ (W @ x)).max() < 1e-10
print("ker(Aᵀ) ⊥ range(A)：✓")

# Banach-Stone：ℓ¹ₙ 的等距 = 符号置换矩阵
perm = rng.permutation(n)
D = np.diag(rng.choice([-1.0, 1.0], n))
T = D @ np.eye(n)[perm]
for _ in range(5):
    x = rng.standard_normal(n)
    assert abs(np.abs(T @ x).sum() - np.abs(x).sum()) < 1e-10
print("符号置换保持 ℓ¹ 范数（Banach-Stone 有限维化身）：✓")
B = rng.standard_normal((n, n)); x = rng.standard_normal(n)
ratio = np.abs(B @ x).sum() / np.abs(x).sum()
print(f"一般矩阵 ℓ¹ 范数比 = {ratio:.4f} ≠ 1")
print("==== 27 adjoint_banach END ====")
