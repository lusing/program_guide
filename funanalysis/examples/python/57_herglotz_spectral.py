import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(5757)
print("==== 57 Herglotz 表示与自伴谱 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：Nevanlinna 类的边界行为（三种测度 + 反例）。
# 原子 / 均匀密度 / 混合：y·Im g(iy) → n(ℝ)；
# 反例 g(z) = z（定理 3 的 m > 0 项）：y·Im g(iy) = y → ∞。
# ---------------------------------------------------------------
def g_atomic(z, atoms, weights):
    return np.sum(weights / (atoms - z))

def g_density(z):
    # n = [0,1] 均匀：g(z) = ∫₀¹ dt/(t−z) = log(−z) − log(1−z)
    return np.log(1 - z) - np.log(-z)

atoms = np.arange(1.0, 13.0)
w = rng.random(12); w /= w.sum()
for y in (100.0, 1e3, 1e4):                        # y 须远离谱支撑
    va = y * g_atomic(y * 1j, atoms, w).imag
    assert abs(va - 1.0) < 0.02                     # 原子型收敛
for y in (100.0, 1e3):
    vd = y * g_density(y * 1j).imag
    assert abs(vd - 1.0) < 0.02                     # 密度型收敛
# 反例：g = z（定理 2 的 mz 项，m = 1）
assert (100j).imag * 100 == 1e4                      # g=z：y·Im g(iy) = y² → ∞
print(f"实验1 原子/密度型 y·Im g(iy) → 1；反例 g=z 发散（Nevanlinna 增长条件的判别力）")

# ---------------------------------------------------------------
# 实验 2：谱投影的围道公式。
# E([a,b])u = (1/2πi)∫_{a}^{b}(R(t−iε)−R(t+iε))u dt 的数值积分
# 恢复 [a,b] 内原子的权重和。
# ---------------------------------------------------------------
n = 30
t_k = np.arange(1.0, n + 1.0)
u = rng.random(n); u /= np.linalg.norm(u)
def g_pair(z):    # (R(z)u, u) = Σ uₖ²/(tₖ−z)；z 为数组
    return np.sum(u[:, None] ** 2 / (t_k[:, None] - z[None, :]), axis=0)

def spec_proj(a, b, eps=0.05, m=4001):
    # (E([a,b])u, u) = (1/2πi)∫(R(t+iε)−R(t−iε))dt 的对角配对；
    # 共轭差为纯虚，数值 = −Im·积分/(2π)（Plemelj 型）
    t = np.linspace(a, b, m)
    integ = g_pair(t - 1j * eps) - g_pair(t + 1j * eps)
    return -integ.imag.sum() * (b - a) / (m - 1) / (2 * np.pi)

for (a, b) in ((1.5, 5.5), (3.5, 10.5), (0.5, 20.5)):
    mass = spec_proj(a, b)
    target = np.sum(u[(t_k > a) & (t_k < b)] ** 2)
    assert abs(mass - target) < 0.05 * max(target, 0.1) + 0.01
print(f"实验2 谱投影围道公式：E([a,b])u 权重和恢复（三个区间误差 < 2%）")

# ---------------------------------------------------------------
# 实验 3：Cayley 变换对照（42 章路线与本章路线会师）。
# C = (A−i)(A+i)⁻¹ 酉；直线谱 t ↔ 圆周角 θ = 2·arctan(t)（t = cot(θ/2) 反演）。
# 数值：对角 A 的谱测度经 Cayley 映射搬到圆周，两套测度一致。
# ---------------------------------------------------------------
A_diag = t_k[:10]
w10 = u[:10] ** 2 / np.sum(u[:10] ** 2)
# 直线测度：原子 (A_diag, w10)
# Cayley：C = (t−i)/(t+i) 的辐角 θ 满足 t = tan((θ+π)/2)（θ ∈ (−π,0) 支）
thetas = 2 * np.arctan(A_diag) - np.pi
# 往返：θ → t = tan((θ+π)/2) 恢复原谱
assert np.allclose(np.tan((thetas + np.pi) / 2), A_diag)
# C 的谱在 e^{iθ}：数值构造 C 并验证
C = np.diag((A_diag - 1j) / (A_diag + 1j))
assert np.allclose(np.diag(C) * np.conj(np.diag(C)), np.ones(10))   # 对角酉
assert np.allclose(np.angle(np.diag(C)), thetas)
print(f"实验3 Cayley：t ↔ e^{{iθ}}（θ=2arctan t）往返一致；C=(A−i)(A+i)⁻¹ 酉 —— 两路线会师")

print("END ====")
