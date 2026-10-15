# 74_inner_product_apps.py —— 内积应用（docs/74 实验，Python 侧）
# 通道：Python 3.13 + numpy
# 内容：最小二乘尺度拟合全链（λ*、ρ、1−ρ²）、Gram 正定与条件数、
#       相关系数矩阵与去相关
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

import numpy as np

print("==== 74 内积应用：相关/Gram/最佳逼近 ====")

# ---------------------------------------------------------------
# 实验 1：最小二乘尺度拟合全链（书 4.5.1 的每一步）
# λ* = ⟨x,y⟩/⟨y,y⟩；min Q = ‖x‖²(1−ρ²)；ρ = ⟨x,y⟩/(‖x‖‖y‖)
# 随机 (x, y) 对逐一验证三个公式。
# ---------------------------------------------------------------
def exp1_scale_fit():
    rng = np.random.default_rng(42)
    for _ in range(500):
        x = rng.standard_normal(40)
        y = rng.standard_normal(40)
        lam_star = x @ y / (y @ y)
        rho = (x @ y) / (np.linalg.norm(x) * np.linalg.norm(y))
        min_q = np.sum((x - lam_star * y) ** 2)
        # 公式 1：任意 λ 处的 Q ≥ min Q
        for lam in [0.0, 0.5, 1.5, -1.0]:
            assert np.sum((x - lam * y) ** 2) >= min_q - 1e-9
        # 公式 2：min Q = ‖x‖²(1−ρ²)
        assert abs(min_q - (x @ x) * (1 - rho**2)) < 1e-8
        # 公式 3：|ρ| ≤ 1（Schwarz）
        assert abs(rho) <= 1.0
    return None

exp1_scale_fit()
print("实验1 尺度拟合：500 组随机对全过——λ* 最优、minQ=‖x‖²(1−ρ²)、|ρ|≤1 三链闭合")

# ---------------------------------------------------------------
# 实验 2：Gram 矩阵——正定、条件数与法方程（书 4.5.5）
# 随机向量族的 Gram 阵恒 SPD；病态族（近线性相关）条件数爆炸，
# 法方程解漂移——正交基（Gram = I）是唯一良态的选择。
# ---------------------------------------------------------------
def exp2_gram_conditioning():
    rng = np.random.default_rng(7)
    # 良态：近正交随机族
    V = rng.standard_normal((30, 4))
    G = V.T @ V
    lam = np.linalg.eigvalsh(G)
    assert lam[0] > 0                                 # SPD（无关 ⟹ 可逆）
    cond = lam[-1] / lam[0]
    assert cond < 1e4
    # 病态：前三个向量 + 第四个 = 前三个之和 + 微扰
    V2 = np.column_stack([V, V.sum(axis=1) + 1e-8 * rng.standard_normal(30)])
    G2 = V2.T @ V2
    lam2 = np.linalg.eigvalsh(G2)
    cond2 = lam2[-1] / max(lam2[0], 1e-300)
    assert cond2 > 1e10                               # 近相关 ⟹ 条件数爆炸
    # 法方程视角：同一投影，良态 Gram 解稳定
    x = rng.standard_normal(30)
    b = V.T @ x
    c = np.linalg.solve(G, b)
    resid = x - V @ c
    assert abs(resid @ resid - (x @ x - b @ np.linalg.solve(G, b))) < 1e-8  # Gram 距离公式
    return cond2

c2 = exp2_gram_conditioning()
print(f"实验2 Gram 条件数：无关族 SPD；近相关族条件数 {c2:.1e}（法方程病态）；Gram 距离公式吻合")

# ---------------------------------------------------------------
# 实验 3：相关系数矩阵与去相关（4.5.1 的工程延伸）
# 多通道信号的相关阵 R（Gram 的一瞥）：特征分解去相关，
# 白化后相关阵变单位阵——Gram-Schmidt 的矩阵形态。
# ---------------------------------------------------------------
def exp3_decorrelation():
    rng = np.random.default_rng(3)
    t = np.linspace(0, 1, 2000)
    base = np.sin(2 * np.pi * 5 * t)
    chans = np.vstack([
        base + 0.1 * rng.standard_normal(len(t)),
        0.8 * base + 0.2 * rng.standard_normal(len(t)),
        rng.standard_normal(len(t)),          # 独立通道
    ])
    R = chans @ chans.T / len(t)              # 相关阵（未中心化的 Gram）
    # 通道 1-2 高相关、与 3 弱相关
    rho12 = R[0, 1] / np.sqrt(R[0, 0] * R[1, 1])
    rho13 = R[0, 2] / np.sqrt(R[0, 0] * R[2, 2])
    assert rho12 > 0.9
    assert abs(rho13) < 0.1
    # 白化：R = W Λ Wᵀ ⟹ R^{-1/2} 通道的 Gram = I
    evals, evecs = np.linalg.eigh(R)
    W = evecs @ np.diag(evals ** -0.5) @ evecs.T
    white = W @ chans
    Rw = white @ white.T / len(t)
    assert np.allclose(Rw, np.eye(3), atol=1e-8)
    return rho12

r3 = exp3_decorrelation()
print(f"实验3 相关系数矩阵：通道相关 {r3:.3f} vs 独立 ~0；白化后 Gram=I（Gram-Schmidt 的矩阵形态）")

print("END ====")
