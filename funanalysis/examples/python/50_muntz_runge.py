import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5050)
print("==== 50 Müntz 与 Runge (Python) ====")

# ---------------------------------------------------------------
# 实验 1：Müntz 误差表（L² + 精确 Gram）+ Gram 条件数。
# 发散族（Σ1/λ=∞）误差 → 0；收敛族停在正极限；
# 素数族发散极慢，可及范围内"看起来收敛"——Müntz 是渐近定理。
# ---------------------------------------------------------------
def muntz_l2(lams):
    n = len(lams)
    G = np.array([[1.0 / (lams[i] + lams[j] + 1) for j in range(n)]
                  for i in range(n)])
    b = np.array([1.0 / (lams[j] + 1.5) for j in range(n)])
    c = np.linalg.solve(G, b)
    return np.sqrt(max(0.5 - c @ b, 0.0))

def cond_gr(lams):
    n = len(lams)
    G = np.array([[1.0 / (lams[i] + lams[j] + 1) for j in range(n)]
                  for i in range(n)])
    return np.linalg.cond(G)

e_all = [muntz_l2(np.arange(1.0, N + 1)) for N in (2, 4, 8)]
e_two = [muntz_l2(2.0 ** np.arange(1, N + 1)) for N in (2, 4, 8)]
e_pr = [muntz_l2(np.array([2, 3, 5, 7, 11, 13, 17, 19][:N], dtype=float))
        for N in (2, 4, 8)]
assert e_all[2] < 0.01
assert e_all[0] > e_all[1] > e_all[2]
assert e_two[2] > 0.11
assert e_pr[2] > 0.04
c_all, c_two = cond_gr(np.arange(1.0, 9)), cond_gr(2.0 ** np.arange(1, 9))
assert c_all > 1e10 and 1e4 < c_two < 1e8   # 全幂=Hilbert 型病态；2^j 反而较良态
print(f"实验1 L²(N=8)：全幂 {e_all[2]:.4f}（→0）；2^j {e_two[2]:.4f}（停）；"
      f"素数 {e_pr[2]:.4f}（慢发散）")
print(f"      Gram 条件数(N=8)：全幂 {c_all:.1e}，2^j {c_two:.1e}（Müntz 基病态）")

# ---------------------------------------------------------------
# 实验 2：Runge 环域失败的最优性。
# 圆环 1/2 ≤ |z| ≤ 1 上逼近 1/z：L² 理论说最优多项式 = Laurent 的
# 非负幂部分，残差² = Σ_{j≥1} |c_{-j}|² = Σ_{j≥1} r^{-2j}·权重
# ——数值上多项式最小二乘残差停在正平台。
# 对照：同环域上 1/(z−2)（极点在孔外）收敛到机器精度。
# ---------------------------------------------------------------
def ring_ls(f, deg=40, n=4000):
    r = np.sqrt(rng.uniform(0.25, 1.0, n))          # r ∈ [1/2, 1] 均匀面积
    th = rng.uniform(0, 2 * np.pi, n)
    z = r * np.exp(1j * th)
    V = np.vander(z, deg + 1, increasing=True)
    c, *_ = np.linalg.lstsq(V, f(z), rcond=None)
    return np.sqrt(np.mean(np.abs(V @ c - f(z)) ** 2))

stall = ring_ls(lambda z: 1.0 / z)
conv = ring_ls(lambda z: 1.0 / (z - 2.0))
assert 1.30 < stall < 1.40              # L² 停滞平台（度 10/20/40 不变）
assert conv < 1e-9
print(f"实验2 环域 L² 残差：1/z 停滞 {stall:.3f}（孔内极点）；"
      f"1/(z−2) {conv:.1e}（孔外）")

# ---------------------------------------------------------------
# 实验 3：解析依赖原理（引理 50.1 的机器影子）。
# l(x) = 等距格点求积泛函，x(ζ) = w(t)e^{iζt}，w(t) = e^{-|t|}。
# 数值验证 f(ζ) = l(x(ζ)) 满足 Cauchy-Riemann：|∂ᵤf − i∂ᵥf| = O(h²)。
# ---------------------------------------------------------------
def quad_f(zeta, n=20001):
    ts = np.linspace(-30, 30, n)
    w = np.exp(-np.abs(ts))
    return np.trapezoid(w * np.exp(1j * zeta * ts), ts)

z0 = 0.7 + 0.3j
def cr_err(h):
    du = (quad_f(z0 + h) - quad_f(z0 - h)) / (2 * h)            # ∂ᵤ
    dv = (quad_f(z0 + 1j * h) - quad_f(z0 - 1j * h)) / (2 * h)  # ∂ᵥ
    return abs(du + 1j * dv)     # CR：∂ᵥf = i∂ᵤf ⟹ ∂ᵤf + i∂ᵥf = 0
err1, err2 = cr_err(0.1), cr_err(0.05)
assert err1 < 0.05 and err2 < 0.01            # CR 成立（小残差）
assert 3.0 < err1 / err2 < 5.0                # 减半 → 残差约 /4（O(h²)）
print(f"实验3 Cauchy-Riemann 残差：h=0.1 → {err1:.1e}，h=0.05 → {err2:.1e}（~×1/4）")

print("END ====")
