import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5353)
print("==== 53 Wiener Tauberian (Python) ====")

# ---------------------------------------------------------------
# 实验 1：逼近失败的最优性（圆周版，障碍才是严格的）。
# 目标 g = 1；基族 = 周期核 f 的循环平移。
# f 周期无零点 Fourier：误差 → 0；f 均值为零：基元均值全为零
# ⟹ 最优逼近恰为 0，误差停在恰 1。
# ---------------------------------------------------------------
def span_err_circ(f, N, n=512):
    g = np.ones(n)
    shifts = np.linspace(0, n, N, endpoint=False).astype(int)
    A = np.column_stack([np.roll(f, j) for j in shifts])
    c, *_ = np.linalg.lstsq(A, g, rcond=None)
    return np.linalg.norm(A @ c - g) / np.linalg.norm(g)

idx5 = np.arange(512)
f_ok = np.exp(-((idx5 - 256) ** 2) / 3) + 0.3       # 周期核，谱宽 ⟹ f̂ 无小值
f_zm = f_ok - f_ok.mean()                            # 零均值：f̂[0] = 0
e_good = [span_err_circ(f_ok, N) for N in (16, 64, 256)]
e_bad = [span_err_circ(f_zm, N) for N in (16, 64, 256)]
assert e_good[2] < 1e-4
assert abs(e_bad[2] - 1.0) < 1e-5                    # 基元均值全零 ⟹ 最优解 = 0
print(f"实验1 目标=1（圆周）：无零点核 {e_good[0]:.3f}→{e_good[2]:.1e}（张成）；"
      f"零均值核 {e_bad[0]:.3f}→{e_bad[2]:.6f}（结构性停在恰 1）")

# ---------------------------------------------------------------
# 实验 2：圆周版 Wiener（ℤ/n 上 = 循环矩阵可逆性）。
# f 的循环平移为列的 circulant 矩阵在 Fourier 基下对角化，
# 特征值恰为离散 Fourier 变换 f̂——可逆 ⟺ f̂ 无零点。
# ---------------------------------------------------------------
def circulant_eigs(f):
    return np.fft.fft(f)

n = 256
idx = np.arange(n)
f_ok = np.exp(-((idx - n / 2) ** 2) / 3)       # 窄核：谱宽（min|f̂| ≈ 0.29 > 0）
f_zero = (idx - n / 2) * np.exp(-((idx - n / 2) ** 2) / 3)
# f_zero 均值为 0 ⟹ f̂[0] = 0
lam_ok = np.abs(circulant_eigs(f_ok))
lam_bad = np.abs(circulant_eigs(f_zero))
assert lam_ok.min() > 1e-3                     # 无零点：可逆
# 平移张成：解 C x = g 误差 ~ 机器精度
C = np.zeros((n, n))
for j in range(n):
    C[:, j] = np.roll(f_ok, j)
g = rng.standard_normal(n)
x = np.linalg.solve(C, g)
assert np.linalg.norm(C @ x - g) / np.linalg.norm(g) < 1e-10
assert lam_bad.min() < 1e-10                   # 有零点：奇异
print(f"实验2 圆周 Wiener：min|f̂| = {lam_ok.min():.4f} > 0 ⟹ circulant 可逆"
      f"（解精度 1e-10）；零均值核 min|f̂| = {lam_bad.min():.1e} ⟹ 奇异")

# ---------------------------------------------------------------
# 实验 3：引理 12 的 Fourier 域机制（除法反演）。
# m̂ 紧支的 m；ᶠ 无零点：g = F^{-1}(m̂/ᶠ) 满足 f*g = m。
# ---------------------------------------------------------------
n3 = 512
k = np.fft.fftfreq(n3) * n3
mhat = np.where(np.abs(k) <= 20, np.exp(-k ** 2 / 50), 0.0)  # 紧支
f3 = np.exp(-((np.arange(n3) - n3 / 2) ** 2) / 3)             # 窄核：谱宽无小值
fhat = np.fft.fft(f3)
assert np.min(np.abs(fhat)) > 1e-6
ghat = mhat / fhat
g3 = np.fft.ifft(ghat)
m3 = np.fft.ifft(mhat)
# 循环卷积 f*g = F^{-1}(f̂·ĝ) = m
fg = np.fft.ifft(fhat * ghat)
err = np.linalg.norm(fg - m3) / np.linalg.norm(m3)
assert err < 1e-10
# 对照：f̂ 有零点时除法崩溃
fhat_bad = fhat.copy()
fhat_bad[10] = 0
try:
    _ = mhat / fhat_bad                        # 出现 inf/nan
    ratio = np.max(np.abs(mhat / fhat_bad))
    assert ratio == np.inf
except (ZeroDivisionError, RuntimeWarning):
    pass
print(f"实验3 Fourier 域反演：‖f*g − m‖/‖m‖ = {err:.1e}（ᶠ 无零点 ⟹ 除法可行）")

print("END ====")
