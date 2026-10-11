import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(2929)
print("==== 29 banach_algebra (Python) ====")
n = 5
I = np.eye(n)

# Neumann 级数：‖A‖ < 1 ⟹ (I-A)⁻¹ = Σₖ Aᵏ
A = rng.standard_normal((n, n))
A = 0.5 * A / np.linalg.norm(A, 2)      # 归一化到 ‖A‖ = 0.5 < 1
assert np.linalg.norm(A, 2) < 1
S = np.eye(n); term = np.eye(n)
for _ in range(80):
    term = term @ A
    S = S + term
print(f"‖Σ Aᵏ - (I-A)⁻¹‖ = {np.linalg.norm(S - np.linalg.inv(I - A)):.12f}")
assert np.linalg.norm(S - np.linalg.inv(I - A)) < 1e-10
print("Neumann 级数收敛到 (I-A)⁻¹：✓")

# Gelfand 谱半径公式：r(A) = lim ‖Aᵏ‖^{1/k}
rng2 = np.random.default_rng(29290)      # 固定本实验的随机状态，与上文解耦
V = np.eye(n) + 0.2 * rng2.standard_normal((n, n))
d = np.diag([0.9, 0.7, 0.5, 0.3, 0.1])
B = V @ d @ np.linalg.inv(V)
print("Gelfand 公式 r(B) = lim ‖Bᵏ‖^(1/k)（真值 0.9）：")
for k in [1, 2, 5, 10, 50, 200]:
    r = np.linalg.norm(np.linalg.matrix_power(B, k), 2) ** (1 / k)
    print(f"  k = {k} : ‖Bᵏ‖^(1/k) = {r:.6f}")
assert abs(np.linalg.norm(np.linalg.matrix_power(B, 200), 2) ** (1 / 200) - 0.9) < 3e-3

# 预解式 λ ↦ (λI - B)⁻¹ 在谱附近爆破
print("预解式范数趋近谱时爆破：")
ts = [1.0, 0.2, 0.05, 0.01]
res = [np.linalg.norm(np.linalg.inv(t * I - B), 2) for t in ts]
for t, nR in zip(ts, res):
    print(f"  λ = 0.9 + {t} : ‖(λI-B)⁻¹‖ = {nR:.4g}")
assert min(res) > 10
assert max(res) > 15
print("==== 29 banach_algebra END ====")
