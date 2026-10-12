import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(4444)
print("==== 44 fourier_moments (Python) ====")

# Fourier 变换的酉性（Parseval）
# 注意：NumPy 的 fftfreq(n, d) 第二参数是采样间距（与 Julia 相反）
n, L = 1024, 32.0
dx = L / n
x = np.arange(n) * dx - L / 2            # 排除右端点：真周期网格
f = np.exp(-x**2)
F = np.fft.fft(f)
fh = F / np.sqrt(n)
print(f"Parseval 偏差 ‖f̂‖-‖f‖ = {abs(np.linalg.norm(fh) - np.linalg.norm(f)):.10f}")
assert abs(np.linalg.norm(fh) - np.linalg.norm(f)) < 1e-10

# 微分 = 无界算子，谱方法：f' = F⁻¹(iξ·Ff)
k = 2 * np.pi * np.fft.fftfreq(n, dx)
fp = np.real(np.fft.ifft(1j * k * F))
fpe = -2 * x * f
err = np.linalg.norm(fp - fpe) / np.linalg.norm(fpe)
print(f"谱方法求导相对误差 = {err:.8f}（f = e^(-x²)）")
assert err < 1e-6
print("Fourier 把无界微分算子对角化为乘 iξ：✓")

# Heisenberg 不确定性：σx·σξ ≥ 1/2（ℏ=1 约定），Gaussian 最优
def uncertainty(f):
    fn = f / np.linalg.norm(f)
    p = np.abs(fn) ** 2; p /= p.sum()
    mx = x @ p
    vx = ((x - mx) ** 2) @ p
    g = np.fft.fft(fn)
    pg = np.abs(g) ** 2; pg /= pg.sum()
    xi = np.fft.fftshift(k)
    mxi = xi @ pg
    vxi = ((xi - mxi) ** 2) @ pg
    return np.sqrt(vx * vxi)

g1 = uncertainty(np.exp(-x**2))                                             # 单 Gauss
g2 = uncertainty(np.exp(-(x - 4) ** 2) + np.exp(-(x + 4) ** 2))             # 双峰
print(f"Gaussian 的 σx·σξ = {g1:.6f}（理论下界 0.5）")
print(f"双峰的   σx·σξ = {g2:.6f}")
assert g1 > 0.49
assert g2 > 1.2 * g1
print("不确定性乘积 Gaussian 最优、双峰显著变大：✓")

# 矩问题：Hankel 矩阵半正定 ⟺ 序列是测度的矩
for sz in [2, 3, 4]:
    idx = np.arange(sz)
    H = 1.0 / (idx[:, None] + idx[None, :] + 1)      # [0,1] 均匀分布的矩
    assert np.linalg.eigvalsh(H).min() > -1e-12
print("均匀分布矩序列的 Hankel 矩阵全半正定：✓")
bad = [1.0, 0.0, 0.0, 1.0, 0.0, 0.0]                # 非矩序列（方差 0 却有高阶矩）
Hb = np.array([[bad[i + j] for j in range(3)] for i in range(3)])
print(f"反例序列 Hankel 最小特征值 = {np.linalg.eigvalsh(Hb).min():.4f} < 0")
assert np.linalg.eigvalsh(Hb).min() < 0
print("非矩序列 ⟹ Hankel 失去半正定（Hamburger 定理的否命题）：✓")
print("==== 44 fourier_moments END ====")
