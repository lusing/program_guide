import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(4646)
print("==== 46 essential_spectrum (Python) ====")

# 本质谱的 Weyl 列刻画：λ ∈ σ_ess(T) ⟺ 存在范数 1、弱→0 的
# 序列 (xₙ) 使 ‖(T-λ)xₙ‖ → 0（近似特征向量）。
# 单侧右移 S（等距）：σ(S) = 闭圆盘，点谱 = ∅，σ_ess(S) = 单位圆周。
def shift(v):
    return np.concatenate([[0.0], v[:-1]])       # 右移 (Sx)ₖ = x_{k-1}，等距

def weyl_err(lam, m):
    # 相位斜坡 xₖ ∝ λ̄^k：|λ|=1 时内部项相消，只剩边界（真 Weyl 列）；
    # |λ|<1 时几何衰减 ⟹ 相对残差 ~√((2-|λ|²)(1-|λ|²)) 有下界
    x = np.conj(lam) ** np.arange(m)
    x = x / np.linalg.norm(x)
    return np.linalg.norm(shift(x) - lam * x)     # 相对误差（‖x‖=1）

print("λ = 1（圆周上，本质谱）：")
for m in [50, 200, 800, 3200]:
    print(f"  m = {m} : ‖(S-λ)x‖ = {weyl_err(1.0 + 0j, m):.6f}")
print("λ = 0.5（圆盘内，非本质谱）：")
for m in [50, 200, 800]:
    print(f"  m = {m} : ‖(S-λ)x‖ = {weyl_err(0.5 + 0j, m):.6f}")
e1 = [weyl_err(1.0 + 0j, m) for m in [50, 800, 3200]]
e2 = [weyl_err(0.5 + 0j, m) for m in [50, 800]]
assert e1[2] < e1[1] * 0.75
assert e1[1] < e1[0] * 0.75
# 右移是等距：‖(S-λ)x‖ ≥ ‖Sx‖ - |λ|‖x‖ = (1-|λ|)‖x‖ 对一切 x 成立
assert all(e > 0.3 for e in e2)
print("圆周上有 Weyl 列（误差 ~1/√m → 0），圆盘内一致有下界：✓")

# 本质谱 = 谱模掉紧摄动：σ_ess(I + K) = σ_ess(I) = {1}
i30 = np.arange(1.0, 31.0)
H30 = 1.0 / (i30[:, None] + i30[None, :] - 1)    # 紧算子截断
t = 0.3
lam = np.linalg.eigvals(np.eye(30) + t * H30)
print(f"I + 0.3·Hilbert 的谱：max|λ-1| = {np.abs(lam - 1).max():.3g}，且聚向 1")
assert np.abs(lam - 1).max() < 0.3 * np.linalg.norm(H30, 2) + 1e-9
near1 = (np.abs(lam - 1) < 1e-3).sum()
print(f"30 个特征值中 {near1} 个落在 1 的 10⁻³ 邻域（离散谱点向本质谱坍缩）")
assert near1 >= 20
print("紧摄动只造离散谱点，本质谱不动（Weyl 定理数值面）：✓")
print("==== 46 essential_spectrum END ====")
