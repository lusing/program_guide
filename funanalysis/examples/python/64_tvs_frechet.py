import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(6464)
print("==== 64 TVS 与 Fréchet 空间 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：Montel 紧性的数值面。
# 圆盘上有界族（Σ|aₖ|²(1+|k|) ≤ 1）：高阶系数被半范数自动压低。
# ---------------------------------------------------------------
n = 400
# 在族中采样：权重 (1+|k|)^-1 缩放的随机相位系数
for trial in range(50):
    coefs = rng.standard_normal(n)
    # 投影进族：Σ|aₖ|²(1+|k|) ≤ 1（族约束，归一化实现）
    coefs /= np.sqrt(np.sum(coefs ** 2 * (1 + np.arange(n))))
    # 半范数 p_r(f) = sup_{|z|=r}|f| ≤ Σ|aₖ|r^k
    for r in (0.5, 0.8, 0.95):
        val = np.sum(np.abs(coefs) * r ** np.arange(n))
        # 族约束 Σ|aₖ|²(1+k) ≤ 1 ⟹ 每项 |aₖ| ≤ (1+k)^{-1/2}
        assert val <= np.sum((1 + np.arange(n)) ** -0.5 * r ** np.arange(n)) + 1e-9
    # 高阶系数衰减：|aₖ| ≤ (1+k)^{-1/2}（族有界 ⟹ 逐系数一致界）
    assert np.max(np.abs(coefs) * np.sqrt(1 + np.arange(n))) < 2.0
print("实验1 有界族采样：p_r(f) ≤ Σ(1+k)^{-1/2}r^k 一致界成立；"
      "系数逐项受控（Montel 的数值影子）")

# ---------------------------------------------------------------
# 实验 2：C^∞ 的半范数层级。
# f = exp(-1/t²)：p_k = max|f^(k)| 逐层有限；
# g = |t-1/2|：一阶分布导数（delta），落在所有 p_k (k≥1) 之外。
# ---------------------------------------------------------------
def dnf(x, k):
    h = x[1] - x[0]
    v = np.exp(-1.0 / np.maximum(x, 1e-3) ** 2)
    for _ in range(k):
        v = np.gradient(v, h)
    return np.max(np.abs(v))          # 数值微分：k ≤ 3 内可靠

x = np.linspace(1e-3, 1, 2000)
# 注：数值微分到 k≈3 为止（浮点放大污染更高阶——真 pₖ 增长超指数）
pks = [dnf(x, k) for k in (0, 1, 2, 3)]
assert all(np.isfinite(pk) for pk in pks)    # 各层有限
assert pks[1] > pks[0] and pks[2] > pks[1]   # 层级单调增长

# 不光滑函数：一阶导在 1/2 处不收敛（差分逼近 delta：峰值 ~ C/m·h^{-2}?）
# 用中心差分在断点的峰值随加密增长（二阶差分 ~ 2/h）
for m in (200, 1600):
    xx = np.linspace(0, 1, m)
    g = np.abs(xx - 0.5)
    d2 = np.diff(g, 2) / (xx[1] - xx[0]) ** 2
    gmax_m = np.max(np.abs(d2))
    if m == 200:
        g200 = gmax_m
assert gmax_m > g200 * 5                      # 二阶差分 ~ 2/h 爆破
print(f"实验2 exp(-1/t²)：p_k 逐层有限增长（p₁/p₀ = {pks[1]/pks[0]:.0f}）；"
      f"|t-1/2| 的 D² 爆破（{g200:.0f}→{gmax_m:.0f}）——拓扑之外")

# ---------------------------------------------------------------
# 实验 3：商范数的数值实现。
# X = R⁶，N = 前三维子空间：‖π(x)‖ = ‖后三分量‖。
# ---------------------------------------------------------------
X = rng.standard_normal((6, 6))
Q, _ = np.linalg.qr(X)
N_basis = Q[:, :3]                             # 随机 N 的正交基
for _ in range(10):
    v = rng.standard_normal(6)
    qn = np.linalg.norm(v - N_basis @ (N_basis.T @ v))   # 商范数 = 到 N 的距离
    # 商范数的定义式 inf_{z∈N}‖v−z‖ 在正交基下由投影取等
    for zcoef in rng.standard_normal((5, 3)):
        z = N_basis @ zcoef
        assert np.linalg.norm(v - z) >= qn - 1e-10       # 投影最优
print("实验3 商范数 ‖π(x)‖ = dist(x,N)：投影最优性（10×5 组，1e-10）")

# ---------------------------------------------------------------
# 实验 4：L^p（p<1）零对偶的数值验证。
# sup{|∫cf| : Δ(f) ≤ 1} = ∞：尺度族 f_t = t·sign(c) 的攻击。
# ---------------------------------------------------------------
p = 0.5
m = 400
t_grid = np.linspace(0, 1, m)
c = rng.standard_normal(m)
Delta = lambda f: np.sum(np.abs(f) ** p) / m
Lam = lambda f: np.sum(c * f) / m
worst = 0.0
for t in (1.0, 1e2, 1e4, 1e8):
    f = t * np.sign(c)
    worst = max(worst, abs(Lam(f)) / Delta(f))
assert worst > 1e3                             # t^{1-p} = t^{1/2} → ∞
# 对照 p = 2（赋范）：比率有界（= ‖c‖₂/‖·‖₂ 常数）
Delta2 = lambda f: np.sqrt(np.sum(f ** 2) / m)
worst2 = max(abs(Lam(t * np.sign(c))) / Delta2(t * np.sign(c)) for t in (1.0, 1e2, 1e4))
assert worst2 < 5.0                            # 有界（连续）
print(f"实验4 p=0.5：|Λ|/Δ 攻击达 {worst:.0f}（→∞，零对偶）；"
      f"p=2 对照有界 {worst2:.2f}（连续）——Kolmogorov 判据的两面")

print("END ====")
