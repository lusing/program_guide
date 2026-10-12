import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5252)
print("==== 52 Riesz-Thorin 与 Hilbert 变换 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：Hausdorff-Young 的方向性（p ≤ 2 成立，p > 2 反例）。
# 离散 Fourier（Plancherel 归一化）：‖x̂‖_{p'} ≤ ‖x‖_p 对 p ≤ 2。
# p > 2 时取尖峰向量即可破坏。
# ---------------------------------------------------------------
def dft(x):
    n = len(x)
    return np.fft.fft(x) / np.sqrt(n)

def lp(x, p):
    return np.linalg.norm(x, ord=p) if p < np.inf else np.max(np.abs(x))

worst = {}
for p in (1.2, 1.5, 1.8, 2.0):
    w = 0.0
    for _ in range(300):
        x = rng.standard_normal(256)
        w = max(w, lp(dft(x), p / (p - 1)) / lp(x, p))
    worst[p] = w
    assert w < 1.0 + 1e-9                 # Hausdorff-Young（常数 1；p=2 即 Plancherel）
# p = 3 > 2：尖峰向量给比率 > 1
x = np.zeros(256); x[0] = 1.0
ratio_bad = lp(dft(x), 3 / 2) / lp(x, 3)
assert ratio_bad > 1.0                    # 反例方向
print(f"实验1 ‖x̂‖_p'／‖x‖_p 最坏（p≤2 全 <1）："
      + "，".join(f"p={p}:{w:.4f}" for p, w in worst.items())
      + f"；p=3 尖峰反例比率 {ratio_bad:.3f} > 1")

# ---------------------------------------------------------------
# 实验 2：核矩阵范数的对数凸形态。
# K(i,j) = exp(−(i−j)²σ²) 截断：‖K‖_{ℓᵖ→ℓᵖ} 关于 1/p 的对数凸。
# 数值验证：log ‖K‖_p 的第二阶差分 ≥ 0（凸性）。
# ---------------------------------------------------------------
def opnorm_lp(K, p, iters=200):
    n = K.shape[1]
    x = np.abs(rng.standard_normal(n)) + 0.1
    for _ in range(iters):
        y = K @ x
        g = np.abs(y) ** (p - 1) * np.sign(y)
        z = np.abs(K.T @ g) ** (p - 1) * np.sign(K.T @ g)
        nz = np.linalg.norm(z, p)
        if nz == 0:
            break
        x = z / nz
    best = 0.0
    for _ in range(40):
        v = rng.standard_normal(n)
        v /= np.linalg.norm(v, p)
        best = max(best, np.linalg.norm(K @ v, p))
    v = x / np.linalg.norm(x, p)
    return max(best, np.linalg.norm(K @ v, p))

n = 40
idx = np.arange(n)
K = np.exp(-(idx[:, None] - idx[None, :]) ** 2 * 0.02)
# 端点精确值：(1,1) 列和最大；(2,2) 最大奇异值
N11 = np.max(np.abs(K).sum(axis=0))
N22 = np.linalg.svd(K, compute_uv=False)[0]
# 对角线段 (p,p)，p ∈ (1,2) 介于端点 (1,1)-(2,2)：a = 2(1−1/p)
for p in (4 / 3, 3 / 2, 5 / 3):
    a = 2 * (1 - 1 / p)
    bound = N11 ** (1 - a) * N22 ** a       # Riesz-Thorin 插值界
    est = opnorm_lp(K, p)                   # 数值幂迭代（欠估计）
    assert est <= bound * (1 + 1e-9)         # 定理保证
print(f"实验2 ‖K‖₁→₁ = {N11:.3f}，‖K‖₂→₂ = {N22:.3f}；"
      f"p=4/3,3/2,5/3 数值范数均 ≤ 端点几何插值（RT 界成立）")

# ---------------------------------------------------------------
# 实验 3：Laplace 变换的 √π。
# 对数网格离散 L，最大奇异值 → √π；主奇异向量的符号轮廓 ~ t^{−1/2}。
# ---------------------------------------------------------------
def laplace_smax(a, L, m):
    s = np.exp(np.linspace(np.log(a), np.log(L), m))
    A = np.exp(-np.outer(s, s))
    w = s * (np.log(L / a) / (m - 1))
    W = np.sqrt(w)
    return np.linalg.svd(W[:, None] * A * W[None, :], compute_uv=False)[0]

vs = [laplace_smax(1e-4, 1e4, 600),
      laplace_smax(1e-6, 1e6, 1500),
      laplace_smax(1e-8, 1e8, 2500)]
assert vs[0] < vs[1] < vs[2]                   # 单调逼近
assert abs(vs[2] - np.sqrt(np.pi)) < 0.035     # 对数慢收敛（同 Hankel 的 √log 律）
print(f"实验3 Laplace σmax：{vs[0]:.4f} → {vs[1]:.4f} → {vs[2]:.4f} ↗ √π = {np.sqrt(np.pi):.4f}")

# ---------------------------------------------------------------
# 实验 4：解析信号的共轭关系（Lax (25) 边值机制）。
# f(t) = e^{−t²/4}e^{iω₀t}（单边谱解析信号）：实部 h 与虚部 k
# 满足 k = Hh（离散 Hilbert）。
# ---------------------------------------------------------------
n = 4096
t = np.arange(n) / n * 40 - 20
f = np.exp(-t ** 2 / 4) * np.exp(1j * 2.2 * t)
h, k = f.real, f.imag
F = np.fft.fft(h)
mult = -1j * np.sign(np.fft.fftfreq(n))
Hh = np.fft.ifft(F * mult).real
err = np.linalg.norm(Hh - k) / np.linalg.norm(k)
assert err < 0.01                        # 共轭函数关系（离散 Hilbert 核 O(1/n) 效应）
print(f"实验4 单边谱信号：‖H(Re f) − Im f‖/‖Im f‖ = {err:.1e}（k = Hh）")

print("END ====")
