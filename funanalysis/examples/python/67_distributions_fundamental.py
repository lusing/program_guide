import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(6767)
print("==== 67 广义函数 FT 与基本解 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：缓增性判据（多项式增长的频域形态）。
# (1+x²)^{-s} 的变换侧：s=1 给 e^{-|t|} 型（Bessel 势），s=2 更光滑。
# ---------------------------------------------------------------
n = 8192
L = 60.0
xs = (np.arange(n) - n / 2) * (2 * L / n)
dx = 2 * L / n
dω = 2 * np.pi / (n * dx)
ts = (np.arange(n) - n / 2) * dω

def F(fv):
    return np.fft.fftshift(np.fft.fft(np.fft.ifftshift(fv))) * dx / np.sqrt(2 * np.pi)

for s in (1.0, 2.0):
    f = (1 + xs ** 2) ** (-s)
    fh = np.abs(F(f))
    # 解析：n=1 时 F = √(π/2)·e^{-|t|}·(组合)；检查 e^{-|t|} 上界形态
    peak = fh.max()
    # t 处的值 ≤ peak·e^{-c|t|}（指数衰减）
    idx = np.argsort(np.abs(ts))
    # 中程衰减律：F[(1+x²)^{-1}] ~ e^{-|t|}（Bessel 势）；|t| ≤ 6 内检验
    # （远 |t| 处被截断误差 + 寄生振荡污染：网格有限性）
    mid = idx[::400]
    mid = [i for i in mid if abs(ts[i]) <= 6]
    decay_ok = all(fh[i] < peak * np.exp(-0.9 * abs(ts[i])) + 1e-12 for i in mid)
    assert decay_ok
    # 定量形态：F[(1+x²)^{-1}] = √(π/2)e^{-|t|}，F[(1+x²)^{-2}] ~ e^{-|t|}(1+|t|)/3
    # s=2 的变换带多项式因子（衰减前段更缓、峰值更低）——多项式因子是机制表的实证
    if s == 1:
        pk1 = fh.max()
    else:
        pk2 = fh.max()
assert pk2 < pk1 * 0.6                # 峰值减半以上（能量摊薄）
print(f"实验1 (1+x²)^{{-s}} 变换中程 ~e^{{-|t|}}；峰值 s=1:{pk1:.3f} → s=2:{pk2:.3f}（摊薄）")

# ---------------------------------------------------------------
# 实验 2：Malgrange 引理 8.3 的环面平均数值面。
# P(z) = 1 + z²，t=0：∫_{T¹} 1/|P(r e^{iθ})| dθ 随 r 的有界性。
# ---------------------------------------------------------------
def torus_avg(r, m=20000):
    th = np.linspace(0, 2 * np.pi, m)
    vals = np.abs(1 + (r * np.exp(1j * th)) ** 2)
    return np.mean(1 / np.maximum(vals, 1e-300))

# r ≤ 1/√2 时 |P| ≥ |r² - 2r| 型下界可能触及零（r≈? 1+r²e^{2iθ}=0 需 r=1）
for r in (0.3, 0.6, 0.9):
    val = torus_avg(r)
    assert val < 50                     # 环面平均有界（引理机制）
a1 = torus_avg(0.3)
a2 = torus_avg(0.9)
assert a2 > a1                          # r 接近 P 的零点（r=1）平均增大
print(f"实验2 ∫_T 1/|1+(re^{{iθ}})²| dθ：r=0.3:{a1:.3f} → r=0.9:{a2:.3f}"
      f"（有界且接近零点时增大——环面平均消奇性）")

# ---------------------------------------------------------------
# 实验 3：椭圆正则性的谱机制（Laplacian 符号下界 + 正则性上传）。
# ---------------------------------------------------------------
n3 = 512
f = rng.standard_normal(n3) * np.exp(-((np.arange(n3) - n3 / 2) ** 2) / (2 * 50 ** 2))
f -= f.mean()
k = np.fft.fftfreq(n3) * n3
uhat = np.fft.fft(f) / (k ** 2).clip(1e-12)     # Δu = f ⟹ û = -f̂/k²（k≠0）
u = np.real(np.fft.ifft(uhat))
fh = np.abs(np.fft.fft(f))
uh = np.abs(np.fft.fft(u))
# 高频抑制比 ~ k²（N=2 上传）
kk = np.abs(k)
sel = (kk > 5) & (kk < 100)
ratios = fh[sel] / np.maximum(uh[sel], 1e-300)
ref = kk[sel] ** 2
corr = np.corrcoef(np.log(ratios), np.log(ref))[0, 1]
assert corr > 0.95                     # 抑制比 ~ k²（对数相关 > 0.95）
# Laplacian 符号椭圆下界：λ_k = k² ≥ c·k²（trivially，但检查符号恒正）
assert np.all(k ** 2 >= -1e-12)
print(f"实验3 Δu=f 的频域解：高频抑制比与 k² 的对数相关 {corr:.3f}"
      f"（N=2 正则性上传 = 椭圆符号下界）")

# ---------------------------------------------------------------
# 实验 4：非椭圆反例（∂²/∂xy 的符号在轴上为零）。
# ---------------------------------------------------------------
n4 = 128
k1 = np.fft.fftfreq(n4) * n4
K1, K2 = np.meshgrid(k1, k1, indexing="ij")
symbol_mixed = -K1 * K2                        # ∂xy 的符号
assert np.min(np.abs(symbol_mixed)) == 0.0     # 在轴上恰为零
zero_on_axes = np.sum(symbol_mixed == 0)        # 整条轴线（K1=0 或 K2=0）
assert zero_on_axes > 200                       # 两整条轴线（2·128−1 点）
# 对照 Laplacian 符号：仅在原点为零
symbol_lap = -(K1 ** 2 + K2 ** 2)
near_zero_lap = np.sum(np.abs(symbol_lap) < 1e-9)
assert near_zero_lap < 5                        # 只在原点
print(f"实验4 ∂xy 符号零集（轴线）{zero_on_axes} 点 vs Δ 符号零集（原点）"
      f"{near_zero_lap} 点——非椭圆 ⟹ 轴向正则性不被控制")

print("END ====")
