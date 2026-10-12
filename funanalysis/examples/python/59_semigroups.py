import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5959)
print("==== 59 半群与 Hille-Yosida (Python) ====")

# ---------------------------------------------------------------
# 实验 1：生成元的域（热半群差商的收敛与发散）。
# 域内（谱衰减快）向量：差商收敛；白噪声（域外）：发散。
# ---------------------------------------------------------------
n = 512
k = np.fft.fftfreq(n) * n
u_in = np.exp(-k ** 2 / 4)                    # 域内（∑k⁴|û|² 有限）
u_in /= np.linalg.norm(u_in)
u_out = rng.standard_normal(n)                # 白噪声：∑k⁴|û|² = ∞ a.s.
u_out /= np.linalg.norm(u_out)

def du_norm(u, h):
    Z = np.exp(-k ** 2 * h)
    return np.linalg.norm((Z * u - u) / h + k ** 2 * u)

for h in (1e-2, 1e-3, 1e-4):
    e_in = du_norm(u_in, h)
    e_out = du_norm(u_out, h)
    if h > 1e-4:
        pass
e_in1, e_in2 = du_norm(u_in, 1e-2), du_norm(u_in, 1e-3)
e_out = [du_norm(u_out, h) for h in (1e-2, 1e-3, 1e-4)]
assert e_in2 < e_in1 * 0.6                    # 域内：差商误差随 h 线性消失
assert min(e_out) > 1e4                       # 白噪声：差商巨幅振荡不收敛
print(f"实验1 热半群差商：域内向量误差 {e_in1:.4f}→{e_in2:.4f}（O(h) 消失）；"
      f"白噪声 {e_out[0]:.1f}/{e_out[1]:.1f}/{e_out[2]:.1f}（不收敛）——域 = {{∑k⁴|û|²<∞}}")

# ---------------------------------------------------------------
# 实验 2：von Neumann 稳定性谱判据（对流方程三格式）。
# 放大因子 g(θ)：max|g| ≤ 1 ⟺ 稳定。
# ---------------------------------------------------------------
C = 0.9                                       # CFL 数
th = np.linspace(0, 2 * np.pi, 2000)
g_fc = 1 - 1j * C * np.sin(th)                # 前向中心差分
g_up = 1.0 / (1 + C * (1 - np.exp(-1j * th))) # 隐式迎风（u_t=u_x）
g_lf = np.cos(th) - 1j * C * np.sin(th)       # Lax-Friedrichs
assert np.max(np.abs(g_fc)) > 1 + 0.3 * C ** 2   # 不稳定
assert np.max(np.abs(g_up)) <= 1.0               # 稳定
assert np.max(np.abs(g_lf)) <= 1.0 + 1e-12       # 稳定（LF 恒稳）
print(f"实验2 放大因子 max|g|：前向中心 {np.max(np.abs(g_fc)):.3f} > 1（不稳）；"
      f"隐式迎风 {np.max(np.abs(g_up)):.6f}；Lax-Friedrichs {np.max(np.abs(g_lf)):.6f} ≤ 1（稳）")

# ---------------------------------------------------------------
# 实验 3：半群律与强连续的量化。
# ‖Z(s)Z(t) − Z(s+t)‖ = 0；‖Z(t)u − u‖ = O(√t)；
# ‖Z(t) − I‖ = 2 对一切 t（范数连续失败）。
# ---------------------------------------------------------------
for (s, t) in ((0.3, 0.7), (1.5, 2.5)):
    prod = np.exp(-k ** 2 * s) * np.exp(-k ** 2 * t)
    direct = np.exp(-k ** 2 * (s + t))
    assert np.max(np.abs(prod - direct)) < 1e-15
for t in (0.01, 0.0001):
    resid = np.sqrt(np.sum((1 - np.exp(-k ** 2 * t)) ** 2 * np.abs(u_in) ** 2))
    assert resid < 3 * np.sqrt(t)
# 范数距离：谱含 0（k=0 的模 e^0 = 1 与 k=大 的模 → 0）⟹ ‖Z(t)−I‖ = sup|e^{−k²t} − 1| = 1
op_dist = np.max(np.abs(np.exp(-k ** 2 * 0.01) - 1))
assert abs(op_dist - 1.0) < 1e-12             # 恰为 1：范数不趋于 I
print(f"实验3 半群律机器精度；强连续 ‖Z(t)u−u‖ = O(√t)；‖Z(t)−I‖ = {op_dist:.6f} ≡ 1（范数连续失败）")

print("END ====")
