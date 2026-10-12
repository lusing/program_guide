import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(6666)
print("==== 66 Banach 刚性 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：Grothendieck 刚性（子空间的 sup 范数随维度增长）。
# L²[0,1] 的 m 维随机子空间：min‖f‖_∞/‖f‖₂ 随 m 指数下降。
# ---------------------------------------------------------------
# 嵌入常数 K_m = max{‖f‖_∞ : ‖f‖₂ = 1, f ∈ S_m}（恒等映射 S_m→L∞ 的范数）。
# Grothendieck 的数值面：K_m 随维度无界增长（Dirichlet 型核取到 max）
# ⟹ 无穷维极限中恒等映射不可能有界 ⟹ 闭子空间被迫有限维。
def trig_embed_constant(modes, n=2048):
    th = np.arange(n) * 2 * np.pi / n
    D = np.ones(n)
    for k in range(1, modes):
        D += 2 * np.cos(k * th)           # Dirichlet 型核
    hth = 2 * np.pi / n
    l2 = np.sqrt(np.sum(D ** 2) * hth / (2 * np.pi))
    linf = np.max(np.abs(D))
    return linf / l2                       # 单位 L² 向量的 sup（≥ K_m 的下界 = 实际取等）

for mm in (4, 16, 64):
    K = trig_embed_constant(mm)
    if mm == 4:
        K4 = K
    if mm == 64:
        K64 = K
assert K64 > 2 * K4                       # 嵌入常数随维度增长
print(f"实验1 三角子空间嵌入常数 K_m：m=4 时 {K4:.1f} → m=64 时 {K64:.1f}"
      f"（~√m 增长——无穷维极限恒等映射无界 ⟹ Grothendieck 刚性）")

# ---------------------------------------------------------------
# 实验 2：Bishop 反对称集（解析 vs 自伴三角代数）。
# ---------------------------------------------------------------
m = 1024
th = np.arange(m) * 2 * np.pi / m
# 目标 g = cos(−θ) 的等价物：仅含负频率的函数 cos θ 用正频率表出才需要 e^{-iθ}
# 正确判据：disk algebra（k≥0 的复代数）不含 e^{-iθ}。
# 数值：g = e^{-iθ} 的实部 cos θ 恰在实代数中——改用"删负频率后误差"：
g_complex = np.exp(-1j * th)              # e^{-iθ}（负频率单频）
# 解析代数（span{e^{ikθ}, k≥0} 的实形态：cos_k 与 sin_k 成对，k≥1）
A_ana = np.array([np.cos(k * th) for k in range(0, 20)] +
                 [np.sin(k * th) for k in range(1, 20)]).T
# g_complex 是复的：分别逼近实虚部
for comp_name, gv in [("Re", g_complex.real), ("Im", g_complex.imag)]:
    coef, *_ = np.linalg.lstsq(A_ana, gv, rcond=None)
    dist = np.linalg.norm(A_ana @ coef - gv) / np.linalg.norm(gv)
    if comp_name == "Im":
        dist_im = dist
    else:
        dist_re = dist
# Re(e^{-iθ}) = cos θ 在代数中（距离 0）——但 Im = -sin θ 也在！
# 实代数过于大。真正的 disk algebra 用复系数：e^{ikθ} 的线性组合
# 表不出 e^{-iθ}：等价于"频率 -1 落在 span{0,1,...,19} 之外"。
# 干净的数值判据：Fourier 系数支撑
Ghat = np.fft.fftshift(np.fft.fft(g_complex) / m)
freqs = np.fft.fftshift(np.fft.fftfreq(m) * m).astype(int)
neg_energy = np.sum(np.abs(Ghat[freqs < 0]) ** 2) / np.sum(np.abs(Ghat) ** 2)
assert abs(neg_energy - 1.0) < 1e-10      # e^{-iθ} 的能量全在负频率
pos_energy = np.sum(np.abs(Ghat[freqs > 0]) ** 2) / np.sum(np.abs(Ghat) ** 2)
assert pos_energy < 1e-10
# 对照 e^{+iθ}：能量全在正频率（属于 disk algebra 的稠密子）
g_pos = np.exp(1j * th)
Ghat2 = np.fft.fftshift(np.fft.fft(g_pos) / m)
pos2 = np.sum(np.abs(Ghat2[freqs > 0]) ** 2) / np.sum(np.abs(Ghat2) ** 2)
assert abs(pos2 - 1.0) < 1e-10
print(f"实验2 e^{{-iθ}} 能量 {neg_energy*100:.0f}% 在负频率（disk algebra 之外，"
      f"距离正频率代数有正下界）；e^{{+iθ}} {pos2*100:.0f}% 在正频率（代数内）"
      f"——Bishop：A-反对称集 = T 整体 ⟹ 逼近失败")

# ---------------------------------------------------------------
# 实验 3：Lyapunov bang-bang（线性规划解在端点）。
# ---------------------------------------------------------------
from scipy.optimize import linprog
n = 200
t = np.linspace(0, 1, n)
gfun = np.exp(-((t - 0.3) ** 2) / 0.01)   # 目标集中区
c_target = 0.25                            # ∫u = c
# max ∫gu ⟺ min -∫gu；约束 Σu·h = c，0 ≤ u ≤ 1
h = 1 / n
res = linprog(-gfun * h, A_eq=[[h] * n], b_eq=[c_target],
              bounds=[(0, 1)] * n, method="highs")
assert res.success
u_star = res.x
# bang-bang：解几乎只取 0/1
frac01 = np.mean((u_star < 1e-6) | (u_star > 1 - 1e-6))
assert frac01 > 0.95                       # 端点解（特征函数）
print(f"实验3 最优控制 LP：{frac01*100:.0f}% 分量在端点 {0,1}"
      f"——bang-bang（端点=特征函数，Lyapunov 的对偶读法）")

# ---------------------------------------------------------------
# 实验 4：Lebesgue 常数 L_n ~ (4/π²)log n。
# ---------------------------------------------------------------
for n in (32, 128, 512, 2048):
    mm = 8 * n
    thg = np.arange(mm) * 2 * np.pi / mm
    D = np.sin((n + 0.5) * thg) / np.maximum(np.sin(thg / 2), 1e-300)
    D[0] = 2 * n + 1
    Ln = np.sum(np.abs(D)) * (2 * np.pi / mm) / (2 * np.pi)
    if n == 32:
        L32 = Ln
    if n == 2048:
        L2048 = Ln
assert L2048 > 3.0                          # log 增长
assert L2048 / L32 > 1.3                    # 64 倍 n → 常数 ×~1.6
print(f"实验4 Lebesgue 常数 L₃₂={L32:.2f} → L₂₀₄₈={L2048:.2f}"
      f"（~(4/π²)log n：删负频率投影无界 ⟹ disk algebra 不可余）")

print("END ====")
