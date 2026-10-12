import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(4343)
print("==== 43 stone_unbounded (Python) ====")
n = 8
I = np.eye(n)

# Stone 定理：自伴 A 生成强连续酉群 U(t) = e^{itA}
A0 = rng.standard_normal((n, n)); A = (A0 + A0.T) / 2
vals, vecs = np.linalg.eigh(A)

def U(t):
    return vecs @ np.diag(np.exp(1j * t * vals)) @ vecs.T

# 群律与酉性
print(f"群律偏差 ‖U(s)U(t)-U(s+t)‖ = {np.linalg.norm(U(0.7) @ U(0.3) - U(1.0)):.12f}")
assert np.linalg.norm(U(0.7) @ U(0.3) - U(1.0)) < 1e-12
print(f"酉性偏差 ‖U(t)*U(t)-I‖ = {np.linalg.norm(U(0.42).conj().T @ U(0.42) - I):.12f}")
assert np.linalg.norm(U(0.42).conj().T @ U(0.42) - I) < 1e-12

# 强连续：‖U(t)x - x‖ ≤ |t|·‖Ax‖（生成元的 Lipschitz 界）
x = rng.standard_normal(n)
Ax = A @ x
for t in [0.1, 0.01, 0.001]:
    assert np.linalg.norm(U(t) @ x - x) <= t * np.linalg.norm(Ax) + 1e-12
print("强连续 + 生成元界 ‖U(t)x-x‖ ≤ t‖Ax‖：✓")

# 无界谱定理化身：无界对角算子 N = diag(1², 2², ..., n²)
# 域 Dom(N) = {x : Σ n⁴|xₙ|² < ∞}——谱定理对无界自伴算子照常工作
def domsum(m):
    w = np.arange(1, m + 1, dtype=float) ** 2
    return (w**2 * (w ** -1.5) ** 2).sum()    # xₙ = n⁻³：Σ n⁻² 收敛
def domsum_out(m):
    w = np.arange(1, m + 1, dtype=float) ** 2
    return (w**2 * (w ** -0.75) ** 2).sum()   # xₙ = n^{-1.5}：Σ n 发散
print(f"域内向量的 Σ n⁴|xₙ|²：m=100：{domsum(100):.4f}，m=500：{domsum(500):.4f}（收敛）")
print(f"域外向量的 Σ n⁴|xₙ|²：m=100：{domsum_out(100):.1f}，m=500：{domsum_out(500):.1f}（发散）")
assert domsum(500) < 2.0
assert domsum_out(500) > 20 * domsum_out(100)

# 无界泛函演算：f(t) = √t 给出 √N = diag(n)，(√N)² = N
w = np.arange(1, 501, dtype=float) ** 2
sq = np.diag(np.sqrt(w))
assert np.linalg.norm(sq @ sq - np.diag(w)) < 1e-9
print("无界 f 的函数演算：√N² = N：✓")
print("==== 43 stone_unbounded END ====")
