import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5454)
print("==== 54 Fredholm 行列式 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：行列式引理阶梯（秩 r = 1..4 的 uv 型核）。
# D = det(I + λ·Σ uⱼvⱼᵀ·w) 与广义引理 det(I + λV′U·w) 一致；
# 正交支撑时退化为 Π(1 + λ⟨vⱼ,uⱼ⟩w)。
# ---------------------------------------------------------------
n = 100
xs = (np.arange(n) + 0.5) / n
w = 1.0 / n
for r in (1, 2, 3, 4):
    U = rng.standard_normal((n, r))
    V = rng.standard_normal((n, r))
    K = w * U @ V.T                        # 秩 r 积分算子的离散
    lam = 0.8
    D_direct = np.linalg.det(np.eye(n) + lam * K)
    D_lemma = np.linalg.det(np.eye(r) + lam * w * (V.T @ U))   # Sylvester
    assert abs(D_direct - D_lemma) / abs(D_lemma) < 1e-10
    if r == 1:
        assert abs(D_direct - (1 + lam * w * (V.T @ U)[0, 0])) < 1e-10
print("实验1 Sylvester/det 引理：秩 1..4 离散 Fredholm 行列式与低维闭式一致（1e-10）")

# ---------------------------------------------------------------
# 实验 2：谱-零点对应（K = min(x,y)）。
# D(λ) 的数值根 = −1/λⱼ（前 4 个特征值解析已知）。
# ---------------------------------------------------------------
n2 = 300
xs2 = (np.arange(n2) + 0.5) / n2
K2 = np.minimum.outer(xs2, xs2) / n2
evs = np.linalg.eigvalsh(K2)[::-1]
analytic = 1 / ((np.arange(1, 5) - 0.5) ** 2 * np.pi ** 2)
# det(I + λK) 在 λ = −1/λⱼ 处为零：数值求 det 的最小值位置
for j in (1, 2, 3):
    lam_star = -1 / evs[j - 1]
    dgrid = np.linalg.slogdet(np.eye(n2) + (lam_star + np.linspace(-1e-3, 1e-3, 9))[:, None, None] * K2)[1]
    assert abs(np.exp(dgrid[4])) < 0.15            # 根处 det 接近 0
    assert dgrid[4] == dgrid.min()                  # 且是对数行列式最小点
    assert abs(evs[j - 1] - analytic[j - 1]) / analytic[j - 1] < 1e-3
print(f"实验2 谱-零点对应：det(I+λK) 在 λ = −1/λⱼ 处取最小（前 3 个特征值 vs 解析 <1e-3）")

# ---------------------------------------------------------------
# 实验 3：变分公式 (28) 与预解恒等式 (12)。
# (12)：(I+K)R = D·K（Fredholm 预解恒等式）——离散机器精度；
# (28)：δlog D = ∫(I+K)^{-1}δK(x,x)dx——平移核 K(x+h,x+h) 数值
# 微分与迹逐位吻合（9 位）。
# 注：角点公式 D'(a) = −R(a,a)（Lax (35)）是半无穷区间的专属结构
# （Lax 的变量代换只在 (a,∞) 上成立）；有限窗口的 dD/da 含体项，
# 我们验证其来源公式 (28)。
# ---------------------------------------------------------------
n3 = 300
a3 = 0.3
xs3 = a3 + (np.arange(n3) + 0.5) * (1 - a3) / n3
w3 = (1 - a3) / n3
K0 = np.exp(-xs3[:, None] ** 2 - xs3[None, :] ** 2) * w3
D0 = np.linalg.det(np.eye(n3) + K0)
R = D0 * np.linalg.inv(np.eye(n3) + K0) @ K0
# (12)：R + K*R - D*K = 0
res12 = np.linalg.norm(R + K0 @ R - D0 * K0) / np.linalg.norm(D0 * K0)
assert res12 < 1e-12
# (28)
def D_of_h(h):
    K = np.exp(-(xs3[:, None] + h) ** 2 - (xs3[None, :] + h) ** 2) * w3
    return np.linalg.det(np.eye(n3) + K)

h = 1e-4
dlogD = (np.log(D_of_h(h)) - np.log(D_of_h(-h))) / (2 * h)
dK = -2 * (xs3[:, None] + xs3[None, :]) * np.exp(-xs3[:, None] ** 2 - xs3[None, :] ** 2) * w3
rhs28 = np.trace(np.linalg.inv(np.eye(n3) + K0) @ dK)
assert abs(dlogD - rhs28) / abs(rhs28) < 1e-8
print(f"实验3 (12) 预解恒等式残差 {res12:.1e}；(28) 变分公式 "
      f"dlogD = {dlogD:.9f} = tr((I+K)^-1 dK) = {rhs28:.9f}")

print("END ====")
