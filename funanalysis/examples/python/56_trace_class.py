import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5656)
print("==== 56 迹类与 Lidskii (Python) ====")

# ---------------------------------------------------------------
# 实验 1：非正规算子的 Lidskii 与 Weyl 严格不等号。
# 随机严格上三角 + 对角（特征值 = 对角元，代数重数直观）：
# tr = Σλ（Lidskii）；Σs > Σ|λ|（非正规性使奇异值更大）。
# ---------------------------------------------------------------
n = 50
D = rng.standard_normal(n)
U = np.triu(rng.standard_normal((n, n)), 1)        # 严格上三角
T = np.diag(D) + 0.5 * U
lam = np.linalg.eigvals(T)
sv = np.linalg.svd(T, compute_uv=False)
assert abs(np.trace(T) - np.sum(lam)) / max(abs(np.sum(lam)), 1e-9) < 1e-10
assert np.sum(sv) > np.sum(np.abs(lam)) * 1.05     # Weyl 严格不等号
print(f"实验1 tr = Σλ（Lidskii，机器精度）；Σ|λ|/Σs = "
      f"{np.sum(np.abs(lam))/np.sum(sv):.3f} < 1（非正规的 Weyl 缺口）")

# ---------------------------------------------------------------
# 实验 2：双基刻画 (6) 的两方向。
# 随机正交基对：Σ|(Tfₙ,eₙ)| ≤ Σs；SVD 基取等。
# ---------------------------------------------------------------
A = rng.standard_normal((n, n))
svA = np.linalg.svd(A, compute_uv=False)
worst = 0.0
for _ in range(5):
    Q1 = np.linalg.qr(rng.standard_normal((n, n)))[0]
    Q2 = np.linalg.qr(rng.standard_normal((n, n)))[0]
    worst = max(worst, np.sum(np.abs(np.diag(Q2.T @ A @ Q1))))
assert worst <= np.sum(svA) * (1 + 1e-12)          # ≤ 方向
U, S, Vt = np.linalg.svd(A)
best = np.sum(np.abs(np.diag(U.T @ A @ Vt.T)))
assert abs(best - np.sum(S)) / np.sum(S) < 1e-12   # 极基取等
print(f"实验2 双基刻画：随机基最大比值 {worst/np.sum(svA):.3f} ≤ 1；SVD 基 = 1（取等）")

# ---------------------------------------------------------------
# 实验 3：HS 类与迹类的分界。
# Volterra 核 1_{x<y}：sⱼ = 1/((j−1/2)π) ~ 1/j ⟹ Σsⱼ² 收敛（HS）
# 但 Σsⱼ 发散（非迹类）；且它拟幂零（λⱼ 全 0）而对角为零测——
# tr = 0 = Σλ，Lidskii 平凡成立。
# min(x,y) 核：sⱼ ~ 1/j² ⟹ 迹类。
# ---------------------------------------------------------------
def kernel_svals(Kfun, n=300):
    xs = (np.arange(n) + 0.5) / n
    K = Kfun(xs[:, None], xs[None, :]) / n
    sv = np.linalg.svd(K, compute_uv=False)
    return sv, K

volterra = lambda x, y: (x > y).astype(float)
sv_v, K_v = kernel_svals(volterra)
sv_min, K_min = kernel_svals(lambda x, y: np.minimum(x, y))
# HS 恒等式：∫∫|K|²dtds = Σsⱼ²（离散）
hs_v = np.sum(K_v ** 2)
assert abs(hs_v - np.sum(sv_v ** 2)) / hs_v < 1e-10
# 迹性判据：Σsⱼ 是否随离散加密收敛（Volterra 谐波发散，min 收敛）
sv_v2, _ = kernel_svals(volterra, 600)
sv_min2, _ = kernel_svals(lambda x, y: np.minimum(x, y), 600)
assert np.sum(sv_v2) - np.sum(sv_v) > 0.15          # Volterra：Σs ~ (2/π)log n 发散（绝对增量）
assert abs(np.sum(sv_min2) - np.sum(sv_min)) < 1e-9   # min：Σs 收敛到 1/2（迹类）
# Volterra 的 Lidskii：特征值全 0（拟幂零），tr = 对角积分 = 0
lam_v = np.linalg.eigvals(K_v)
assert np.max(np.abs(lam_v)) < 1e-10               # 拟幂零（离散 O(h) 残留）
assert abs(np.trace(K_v)) < 1e-12                  # 对角恒零 ⟹ tr = 0 = Σλ
print(f"实验3 HS 恒等式（1e-10）；Σs 随 n=300→600："
      f"Volterra {np.sum(sv_v):.3f}→{np.sum(sv_v2):.3f}（发散），"
      f"min 核 {np.sum(sv_min):.6f}→{np.sum(sv_min2):.6f}（迹类）；"
      f"Volterra λ 全 0、tr = 0（Lidskii 平凡取等）")

print("END ====")
