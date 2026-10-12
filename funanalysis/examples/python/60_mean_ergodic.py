import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(6060)
print("==== 60 平均遍历与 Koopman (Python) ====")

# ---------------------------------------------------------------
# 实验 1：收敛速率谱（Fourier 求和公式逐 k 验证）。
# 无理旋转：M_N g 的第 k 个 Fourier 系数 = ĝₖ·(几何和)，
# |几何和|/N = |sin(Nπkα)|/|N sin(πkα)|。
# ---------------------------------------------------------------
n = 4096
th = np.arange(n) * 2 * np.pi / n
alpha = 0.6180339887

def rot_avg(g, N):
    acc = np.zeros(n)
    for j in range(N):
        acc += np.roll(g, -round(j * alpha * n) % n)
    return acc / N

g = np.cos(3 * th) + 0.5 * np.sin(5 * th) - 0.3 * np.cos(2 * th)
for N in (37, 149, 613):
    m = rot_avg(g, N)
    resid = np.linalg.norm(m) / np.linalg.norm(g - g.mean())
    # 理论：所有 k≠0 模的几何和因子的范数
    ks = [3, 5, 2]
    amps = [1.0, 0.5, 0.3]
    theory = sum(a ** 2 * min(1.0, 1.0 / (N * abs(np.sin(np.pi * k * alpha)))) ** 2
                 for k, a in zip(ks, amps))
    theory = np.sqrt(min(theory, sum(a ** 2 for a in amps)))
    assert resid < theory * 1.05 + 0.02 / N + 1e-9
print(f"实验1 无理旋转时间平均衰减：实测 ≤ Fourier 几何和公式（N=37/149/613 三档全过）")

# ---------------------------------------------------------------
# 实验 2：混合性对比（倍增 vs 旋转）。
# 倍增：⟨g∘Dⁿ, h⟩ → ⟨g⟩⟨h⟩ 指数快；旋转：相关只振荡不衰减。
# ---------------------------------------------------------------
n2 = 8192
xs = np.arange(n2) / n2
g2 = np.exp(-((xs - 0.3) ** 2) / 0.02)
g2 -= g2.mean()
h2 = np.sin(2 * np.pi * xs)

def doubling(v):
    return v[np.mod(np.round(2 * np.arange(n2)).astype(int), n2)]

gg = g2.copy()
corr_d = []
for _ in range(6):
    gg = doubling(gg)
    corr_d.append(abs(np.dot(gg, h2) / n2))
assert corr_d[-1] < 0.3 * corr_d[0]        # 倍增：相关衰减
# 旋转：相关 |⟨g∘Rⁿ, h⟩| 不衰减（仅依赖相位）
corr_r = []
for j in range(1, 7):
    gr = np.roll(g2, -round(j * alpha * n2) % n2)
    corr_r.append(abs(np.dot(gr, h2) / n2))
assert max(corr_r) > 0.5 * corr_r[0]       # 旋转：不衰减
print(f"实验2 倍增相关 {corr_d[0]:.3f}→{corr_d[-1]:.4f}（衰减）；"
      f"旋转相关维持 {corr_r[-1]:.3f} ≈ 初值级（振荡不衰减）——混合 ≠ 遍历")

# ---------------------------------------------------------------
# 实验 3：不变集探测（时间平均方差作为传递性统计量）。
# 传递流：不同初值的时间平均一致（方差→0）；
# 非传递流：方差停在正值。
# ---------------------------------------------------------------
def time_avg_indicator(y0, N=3000, step=0.2525):
    y = y0
    acc = 0.0
    for _ in range(N):
        acc += 1.0 if y < 0.25 else 0.0
        y = (y + step) % 1.0                 # 全圆无理旋转（传递）
    return acc / N

def time_avg_split(y0, N=3000, step=0.2525):
    blk = 0.0 if y0 < 0.5 else 0.5
    y = y0
    acc = 0.0
    for _ in range(N):
        acc += 1.0 if y < 0.25 else 0.0
        y = blk + (y - blk + step) % 0.5     # 块内旋转（非传递）
    return acc / N

va = [time_avg_indicator(y0) for y0 in rng.random(20)]
vs = [time_avg_split(y0) for y0 in rng.random(20)]
assert np.var(va) < 1e-3                     # 传递：方差 → 0
assert np.var(vs) > 0.01                     # 非传递：方差正
print(f"实验3 时间平均方差：传递流 {np.var(va):.2e}（→0）vs 非传递 {np.var(vs):.3f}（正值）")

print("END ====")
