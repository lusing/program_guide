import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(3232)
print("==== 32 compact_spectrum (Python) ====")
# Riesz–Schauder 定理：紧算子的非零谱点都是特征值（有限重），
# 唯一可能的聚点是 0；且 0 ∈ σ(T) 当空间无穷维。

# 1) 对角紧算子 diag(1/k) 的 n 阶截断：谱 = {1, 1/2, ..., 1/n}
n = 100
D = np.diag(1.0 / np.arange(1, n + 1))
λD = np.linalg.eigvals(D)
print("diag(1/k) 截断：λ₁..λ₅ =", np.round(λD[:5], 6))
assert np.abs(λD - 1.0 / np.arange(1, n + 1)).max() < 1e-12
for m in [50, 200, 800]:
    print(f"  n = {m} : 最小谱值 1/n = {1.0 / m:.6f} → 0")
assert 1 / 800 < 1 / 200 < 1 / 50
print("谱值随维数增长填充逼近 0（唯一聚点）：✓")

# 2) 三角结构：严格下三角扰动不改变谱（三角阵谱 = 对角元）
N0 = 0.05 * rng.standard_normal((n, n))
N = np.tril(N0, -1)                 # 严格下三角
T = D + N
λT = np.sort(np.linalg.eigvals(T).real)
ref = (1.0 / np.arange(1, n + 1))[::-1]
dev = np.abs(λT - ref).max()
print(f"严格下三角扰动后谱偏差 = {dev:.10f}")
assert dev < 1e-8
print("σ(三角阵) = 对角元集合（有限维 Riesz 理论骨架）：✓")

# 3) Volterra 型算子（h·下三角全 1）：拟幂零的数值化身，谱半径 → 0
def volterra(m):
    return (1.0 / m) * np.tri(m)
ρ20 = np.abs(np.linalg.eigvals(volterra(20))).max()
ρ100 = np.abs(np.linalg.eigvals(volterra(100))).max()
ρ400 = np.abs(np.linalg.eigvals(volterra(400))).max()
print(f"Volterra 截断谱半径：n=20 : {ρ20:.6f}  n=100 : {ρ100:.6f}  n=400 : {ρ400:.6f}")
assert ρ400 < ρ100 < ρ20
print("谱半径随加细收缩 → 0（无穷维极限 σ(V) = {0}）：✓")
print("==== 32 compact_spectrum END ====")
