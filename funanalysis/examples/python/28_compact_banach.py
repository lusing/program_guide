import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(2828)
print("==== 28 compact_banach (Python) ====")
# 紧算子 = 有限秩算子的范数极限。Hilbert 矩阵是紧积分算子的有限截断
n = 60
i = np.arange(1, n + 1)
H = 1.0 / (i[:, None] + i[None, :] - 1)
σ = np.linalg.svd(H, compute_uv=False)
print("Hilbert 矩阵奇异值：σ₁..σ₅ =", np.round(σ[:5], 4))
print(f"σ₂₀ = {σ[19]:.4g}   σ₆₀ = {σ[59]:.4g}")
assert σ[59] < σ[0] * 1e-15
print("奇异值 → 0：可被有限秩一致逼近（紧性判据）：✓")

# Eckart–Young：最佳 k 秩逼近误差恰为 σ_{k+1}
U, S, Vt = np.linalg.svd(H)
k = 10
Hk = U[:, :k] @ np.diag(S[:k]) @ Vt[:k, :]
err = np.linalg.norm(H - Hk, 2)
print(f"‖H - H₁₀‖₂ = {err:.4g} = σ₁₁ = {S[10]:.4g}")
assert abs(err - S[10]) < 1e-12

# 紧算子谱：非零谱点均为特征值，唯一可能聚点是 0
m = 1000
μ = 1.0 / np.arange(1, m + 1)
print(f"diag(1/k) 的谱：λ₉₉₉ = {μ[998]:.6f}，λ₁₀₀₀ = {μ[999]:.6f} → 0")
print("非零谱点全是特征值，唯一聚点 0：✓")
assert μ[m - 1] < 1e-2
print("==== 28 compact_banach END ====")
