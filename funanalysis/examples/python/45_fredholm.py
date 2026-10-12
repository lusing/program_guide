import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
from scipy.linalg import null_space

rng = np.random.default_rng(4545)
print("==== 45 fredholm (Python) ====")
n = 6
I = np.eye(n)

# 秩一摄动的行列式引理：det(I + t·uv') = 1 + t·v'u
u = rng.standard_normal(n); v = rng.standard_normal(n)
print("t        det(I+tuv')   1+t·v'u")
ts = [0.1, 0.5, 1.0, 2.0]
dets = [np.linalg.det(I + t * np.outer(u, v)) for t in ts]
rhss = [1 + t * (v @ u) for t in ts]
for t, lhs, rhs in zip(ts, dets, rhss):
    print(f"{t:<6}  {lhs:<14.8f} {rhs:.8f}")
assert all(abs(l - r) < 1e-8 * (1 + abs(r)) for l, r in zip(dets, rhss))
print("行列式引理（Fredholm 摄动的解析原型）：✓")

# Fredholm 二择一：u'v = -1 时 I + uv' 奇异，且指标 = 0
w = rng.standard_normal(n)
v0 = -w / (w @ u)                # 保证 u'v0 = -1
M = I + np.outer(u, v0)
kerdim = null_space(M).shape[1]
cokerdim = null_space(M.conj().T).shape[1]
print(f"奇异情形：dim ker = {kerdim}，dim coker = {cokerdim}")
assert kerdim == 1
assert cokerdim == 1
assert kerdim - cokerdim == 0
print("有限维恒有 index = dim ker - dim coker = 0（rank-nullity）：✓")

# 无穷维指标：单侧移位 index(S) = -1 是纯无穷维现象
# 有限截断 Fₙ（前移，F eₙ = 0）：ker = 1 维，余核 = 1 维，指标 0
Fn = np.zeros((n, n))
Fn[1:, :-1] = np.eye(n - 1)
print(f"截断前移：dim ker = {null_space(Fn).shape[1]}，rank = {np.linalg.matrix_rank(Fn)}（缺 e₁，coker = 1）")
assert null_space(Fn).shape[1] == 1
assert np.linalg.matrix_rank(Fn) == n - 1
print("无穷维极限：ker(S)=0 且 ran(S) 缺 e₁ ⟹ index(S) = 0-1 = -1（解析事实）")

# 谱在紧摄动下：I + 紧 的特征值只能聚在 1
i30 = np.arange(1.0, 31.0)
H30 = 1.0 / (i30[:, None] + i30[None, :] - 1)      # 紧算子截断
for t in [0.5, 0.1, 0.02]:
    lam = np.linalg.eigvals(np.eye(30) + t * H30)
    print(f"t = {t} ：max|λ - 1| = {np.abs(lam - 1).max():.3g}（上界 t·‖H‖ = {t * np.linalg.norm(H30, 2):.3g}）")
assert np.abs(np.linalg.eigvals(np.eye(30) + 0.02 * H30) - 1).max() < 0.02 * np.linalg.norm(H30, 2) + 1e-9
print("紧摄动把谱锁在 1 附近：σ_ess(I + K) = {1}：✓")
print("==== 45 fredholm END ====")
