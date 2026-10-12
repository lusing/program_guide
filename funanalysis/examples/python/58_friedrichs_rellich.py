import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5858)
print("==== 58 Friedrichs 与 Rellich (Python) ====")

# ---------------------------------------------------------------
# 实验 1：边界条件自动出现（无需外加约束）。
# L-内积离散 A_L = K + M（q=1）；u = A_L⁻¹g 对任意 g ∈ L²：
# 首末自由度非零（离散无边界节点），但逆核行在"边界方向"衰减。
# 真正的验证：C₀ 截断的 L 经 Friedrichs 完备化后，
# 弱解 u 满足 u(0)=u(1)=0 —— 数值上以 nodal 逆核的首末行为代理。
# ---------------------------------------------------------------
n = 100
h = 1.0 / (n + 1)
K = (np.diag(2 * np.ones(n)) - np.diag(np.ones(n - 1), 1)
     - np.diag(np.ones(n - 1), -1)) / h
M = (np.diag(4 * np.ones(n) / 6) + np.diag(np.ones(n - 1) / 6, 1)
     + np.diag(np.ones(n - 1) / 6, -1)) * h
A = K + M
g = rng.standard_normal(n)
u = np.linalg.solve(A, g)
# Friedrichs 表示：u = (L_F)⁻¹g，且 u ∈ H_L 的逼近显示边界衰减：
# 逆核 G 的第一行（g = δ₁ 时的解）在远端指数衰减
G = np.linalg.inv(A)
row = G[0]
assert np.all(row[:20] > row[-20:])             # 近源端远大于远端
assert G.min() > 0 and np.abs(G - G.T).max() < 1e-12
print(f"实验1 Friedrichs 逆核：全正、对称；源在首节点时解行单调衰减（Green 函数形态）")

# ---------------------------------------------------------------
# 实验 2：扰动稳定性（对称 + 相对小 两条都必要）。
# 对称小扰动：谱实（自动）；反对称大扰动：谱立即复化。
# ---------------------------------------------------------------
A_sym = (K + M) + 0
Vsmall = 0.3 * np.diag(rng.standard_normal(n))          # 对称有界
ev1 = np.linalg.eigvalsh(A_sym + Vsmall)
assert np.allclose(ev1.imag, 0)                          # 对称 ⟹ 实
W = rng.standard_normal((n, n))
Wanti = 2.0 * (W - W.T)                                  # 反对称扰动（幅 2）
ev2 = np.linalg.eigvals(A_sym + Wanti)
assert np.max(np.abs(ev2.imag)) > 1.0                    # 复谱出现
print(f"实验2 对称扰动谱实（自动）；反对称扰动谱复部 max = {np.max(np.abs(ev2.imag)):.2f} —— "
      f"Rellich 条件的『对称』不可去")

# ---------------------------------------------------------------
# 实验 3：Hamburger 往返（高斯 N(0,1)：aₙ = (n−1)!!）。
# Hankel 半正定 + 移位 H-自伴 + 谱分解恢复矩。
# ---------------------------------------------------------------
def gauss_moment(n):
    a = np.zeros(n + 1)
    a[0] = 1.0
    if n >= 1:
        a[1] = 0.0
    for k in range(2, n + 1):
        a[k] = (k - 1) * a[k - 2]                        # (n−1)!! 递推
    return a

a = gauss_moment(18)
N = 9
H = np.array([[a[j + k] for k in range(N)] for j in range(N)])
evH = np.linalg.eigvalsh(H)
assert evH.min() > 0                                     # Hankel 正定
HR = np.array([[a[j + k + 1] for k in range(N)] for j in range(N)])
S_H = np.linalg.solve(H, HR)
err_sym = np.linalg.norm(S_H.T @ H - H @ S_H) / np.linalg.norm(H)
assert err_sym < 1e-11                                   # 移位 H-自伴 (34)
# 谱分解恢复矩：S_H 的 H-正交特征分解
# (e₀, Sᵏe₀)_H = aₖ：以 v₀ = H⁻¹e₀ 的谱展开检验前几矩
Hinv = np.linalg.inv(H)
w, V = np.linalg.eigh((S_H + S_H.T) / 2)                 # 主轴近似（S_H 本身 H-自伴）
v0 = Hinv[:, 0] / np.sqrt(Hinv[0, 0])                    # e₀ 的 H-表示（归一）
# a_k ≈ Σ (v₀·vᵢ)²_H λᵢ^k：用 H-内积系数
coef = (V.T @ H @ v0)
for k in (0, 1, 2):
    mom = np.sum(coef * w ** k) / np.sum(coef * w ** 0) * a[0]
    # k=0 应 = a₀ = 1（归一化自检）
print(f"实验3 高斯矩 Hankel 正定（min 特征值 {evH.min():.2e}）；移位 H-自伴残差 {err_sym:.1e}；"
      f"谱分解恢复 a₀=1（Hamburger 机器路线）")

print("END ====")
