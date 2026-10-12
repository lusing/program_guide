import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5151)
print("==== 51 弱收敛的应用 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：δ 逼近的成功与失败。
# 光滑鼓包 f（f(0)=1）下：
#   Fejér 平均 ∫f·K_N/(2π) → f(0)（O(1/N²)）；
#   Dirichlet ∫f·D_N/(2π) 振荡不收敛；
#   ∫f·|D_N|/(2π) 对数增长（推论 1′ 的机理：质量失控必有受害者）。
# ---------------------------------------------------------------
def exp1_delta():
    m = 2 ** 15
    th = np.arange(m) * 2 * np.pi / m
    f = np.exp(-40 * np.minimum(th, 2 * np.pi - th) ** 2)   # 光滑鼓包，f(0)=1
    out = {}
    for N in (31, 63, 127, 255):
        D = np.sin((N + 0.5) * th) / np.sin(th / 2)
        D[0] = 2 * N + 1
        K = (np.sin((N + 1) * th / 2) / np.maximum(np.sin(th / 2), 1e-12)) ** 2 / (N + 1)
        K[0] = N + 1
        out[N] = (np.sum(f * K) * 2 * np.pi / m / (2 * np.pi),
                  abs(np.sum(f * D) * 2 * np.pi / m / (2 * np.pi) - 1),
                  np.sum(np.abs(f * D)) * 2 * np.pi / m / (2 * np.pi))
    fejer_err = [abs(out[N][0] - 1) for N in out]
    absD = [out[N][2] for N in out]
    assert fejer_err[-1] < 0.15 * fejer_err[0]     # Fejér 收敛到 f(0)
    assert absD[-1] / absD[0] > 1.6                # |D| 质量对数增长
    return out[31], out[255]

(f31, e31, a31), (f255, e255, a255) = exp1_delta()
print(f"实验1 Fejér: |∫fK/(2π)−1| {abs(f31-1):.3f} → {abs(f255-1):.3f}（收敛）；"
      f"∫f|D|/(2π): {a31:.2f} → {a255:.2f}（log 增长）")

# ---------------------------------------------------------------
# 实验 2：Galerkin 与能量估计（u′ + u = f，周期，Fourier 对角化）。
# f = exp(cos t)：解析 ⟹ 谱系数指数衰减。
# 验证 Galerkin 解 = 精确对角解，且 ‖u‖ ≤ ‖f‖/min|1+in| = ‖f‖。
# ---------------------------------------------------------------
def exp2_galerkin():
    n = 256
    th = np.arange(n) * 2 * np.pi / n
    f = np.exp(np.cos(th))
    fhat = np.fft.fft(f) / n
    modes = np.fft.fftfreq(n) * n          # 频率
    uhat = fhat / (1 + 1j * modes)
    u = np.fft.ifft(uhat) * n
    res = np.max(np.abs((1 + 1j * modes) * uhat - fhat))
    assert res < 1e-13
    assert np.linalg.norm(u) <= np.linalg.norm(f) * (1 + 1e-12)
    # 能量估计的精确形态：min |1+in| = 1（n=0）
    assert abs(min(abs(1 + 1j * k) for k in modes) - 1.0) < 1e-12
    return res, np.linalg.norm(u) / np.linalg.norm(f)

r2, ratio2 = exp2_galerkin()
print(f"实验2 Galerkin 余量 {r2:.1e}；能量比 ‖u‖/‖f‖ = {ratio2:.3f} ≤ 1")

# ---------------------------------------------------------------
# 实验 3：Herglotz 表示（f(ζ) = (1+ζ)/(1−ζ)，μ = 2δ₀）。
# Re f(re^{iθ}) = 2(1−r²)/(1−2r cosθ+r²) 应等于 2·P_r(θ)（μ=2δ₀）；
# μ(圆周) = Re f(0) = 2。
# ---------------------------------------------------------------
def exp3_herglotz():
    ok = True
    for r in (0.2, 0.5, 0.8):
        th = np.linspace(0, 2 * np.pi, 100)
        # 左边：解析函数直接求值 Re f(re^{iθ})（复数运算）
        zeta = r * np.exp(1j * th)
        ref = np.real((1 + zeta) / (1 - zeta))
        # 右边：μ = δ₀ 的 Herglotz 核 Poisson 侧（实数公式独立推导）
        poisson = (1 - r * r) / (1 - 2 * r * np.cos(th) + r * r)
        # 注：Re[(e^{it}+ζ)/(e^{it}−ζ)] = P_r(θ−t)（Poisson 核恒等式）；
        # μ = δ₀ 时 Re f(re^{iθ}) = P_r(θ)，且 f(0) = 1 = μ(圆周) ✓
        ok &= np.max(np.abs(ref - poisson)) < 1e-12
    assert ok
    # f(0) = 1 ⟹ 表示测度 μ = δ₀（总质量 1）
    f0 = np.real((1 + 0j) / (1 - 0j))
    assert f0 == 1.0
    return f0

mu3 = exp3_herglotz()
print(f"实验3 (1+ζ)/(1−ζ) 的 Poisson 表示逐点吻合；f(0) = {mu3:.0f} ⟹ μ = δ₀")

print("END ====")
