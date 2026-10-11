import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 09 章 · 投影、幂等与不变子空间的数值实验（Conway II.3）——scipy 通道。

对应 docs/09-projections.md。
- 斜投影 vs 正交投影的范数与正交性对照；
- ran E = ker(I-E) 的矩阵实验；
- 谱分解 = 一族正交投影之和（3.3 + 第 11 章预告）；
- 不变子空间与块三角结构。
"""

import numpy as np

rng = np.random.default_rng(909)

print("==== 09 projections (Python) ====")

# --- 实验 1：斜投影 vs 正交投影（Conway 3.3 的反例方向）------------------------
E = np.array([[1.0, 1.0], [0.0, 0.0]])            # 斜投影到 x 轴
P = np.diag([1.0, 0.0])                           # 正交投影到 x 轴
assert np.abs(E @ E - E).max() < 1e-12            # 都幂等
assert np.abs(P @ P - P).max() < 1e-12
print(f"oblique ‖E‖ = {np.linalg.norm(E, 2):.4f} > 1；orthogonal ‖P‖ = {np.linalg.norm(P, 2):.1f}")
assert np.linalg.norm(E, 2) > 1.3
assert np.linalg.norm(P, 2) <= 1.0 + 1e-12
# 正交投影自伴；斜投影不自伴（实矩阵：转置不等）
assert np.abs(P.T - P).max() < 1e-12
assert np.abs(E.T - E).max() > 0.1

# --- 实验 2：ran E = ker(I - E)（Conway 3.2 (b)）--------------------------------
v = rng.standard_normal(2)
assert np.abs((np.eye(2) - E) @ (E @ v)).max() < 1e-12
print("ran E ⊆ ker(I-E): PASS")

# --- 实验 3：谱分解 = 正交投影之和（第 11 章的伏笔）-----------------------------
A = rng.standard_normal((4, 4))
H = (A + A.T) / 2                                 # 自伴：谱定理适用
evals, V = np.linalg.eigh(H)
total = np.zeros((4, 4))
for i, lam in enumerate(evals):
    cols = V[:, [i]]                               # 第 i 个特征向量（单列）
    Pk = cols @ cols.T                             # 秩一正交投影
    assert np.abs(Pk @ Pk - Pk).max() < 1e-10     # 幂等
    assert np.abs(Pk.T - Pk).max() < 1e-10        # 自伴
    total += lam * Pk
assert np.abs(total - H).max() < 1e-9
print(f"spectral decomposition H = Σ λ_k P_k over {len(evals)} rank-one projections: PASS")

# --- 实验 4：不变子空间与块三角（Conway 3.7）-----------------------------------
B = rng.standard_normal((2, 2))
C = rng.standard_normal((2, 2))
X = rng.standard_normal((2, 2))
T = np.block([[B, X], [np.zeros((2, 2)), C]])
P = np.diag([1.0, 1.0, 0.0, 0.0])
assert np.abs(P @ T @ P - T @ P).max() < 1e-12    # 不变：PTP = TP
assert np.abs(T @ P - P @ T).max() > 0.01         # 不交换：不约化
D = np.block([[B, np.zeros((2, 2))], [np.zeros((2, 2)), C]])
assert np.abs(D @ P - P @ D).max() < 1e-12        # 块对角 ⟹ 约化
print("invariant/reducing dichotomy: PASS")

print("==== 09 projections END ====")
