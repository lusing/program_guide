import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
import scipy.sparse as sp
import scipy.sparse.linalg as spla

rng = np.random.default_rng(4848)
print("==== 48 Lax-Milgram 与变分法 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：二维 Poisson 五点差分的 SPD 性质与 Lax-Milgram 范数界。
# A = (1/h²)(I⊗T + T⊗I)，T = tridiag(−1,2,−1)。断言：
#   (a) A 对称；(b) 最小特征值 ≈ 2π²（连续谱底，离散从下方逼近）；
#   (c) 对随机右端 ‖u‖ ≤ ‖f‖/λ₁（强制常数 = λ₁ 的范数界）。
# ---------------------------------------------------------------
def exp1_poisson2d():
    n = 40                                   # 每维内点数
    h = 1.0 / (n + 1)
    T = sp.diags([-np.ones(n - 1), 2 * np.ones(n), -np.ones(n - 1)], [-1, 0, 1])
    A = (sp.kron(sp.identity(n), T) + sp.kron(T, sp.identity(n))) / h**2
    assert abs(A - A.T).max() < 1e-14        # (a) 对称
    lam1 = spla.eigsh(A, k=1, which='SA', return_eigenvectors=False)[0]
    assert abs(lam1 / (2 * np.pi**2) - 1) < 5e-3   # (b) 谱底 2π²
    worst = 0.0
    for _ in range(20):
        f = rng.standard_normal(n * n)
        u = spla.spsolve(A.tocsr(), f)
        worst = max(worst, np.linalg.norm(u) / (np.linalg.norm(f) / lam1))
    assert worst <= 1.0 + 1e-10              # (c) ‖u‖ ≤ ‖f‖/λ₁
    return lam1, worst

lam1, worst1 = exp1_poisson2d()
print(f"实验1 λ₁={lam1:.4f}≈2π²，20 次随机最坏 ‖u‖·λ₁/‖f‖ = {worst1:.6f} (≤1)")

# ---------------------------------------------------------------
# 实验 2：二维 Zaremba 引理 ‖f‖₀ ≤ d‖∇f‖₁。
# 域 (0,2)×(0,1)，d = 2。函数 = 随机高斯鼓包 × 截断因子
# x(2−x)y(1−y)（边界严格为零），离散梯度用 np.gradient。
# ---------------------------------------------------------------
def exp2_zaremba2d():
    d = 2.0
    nx, ny = 120, 60
    xs = np.linspace(0, 2, nx); ys = np.linspace(0, 1, ny)
    X, Y = np.meshgrid(xs, ys, indexing='ij')
    dx, dy = xs[1] - xs[0], ys[1] - ys[0]
    cutoff = X * (2 - X) * Y * (1 - Y)
    ok = True
    for _ in range(5):
        x0 = 0.8 + 0.4 * rng.standard_normal()
        y0 = 0.5 + 0.2 * rng.standard_normal()
        s = 0.10 + 0.06 * rng.random()
        f = np.exp(-((X - x0)**2 + (Y - y0)**2) / s**2) * cutoff
        gx, gy = np.gradient(f, dx, dy)
        n0 = np.sqrt(np.sum(f**2) * dx * dy)
        n1 = np.sqrt(np.sum(gx**2 + gy**2) * dx * dy)
        ok &= (n0 <= d * n1 * (1 + 1e-12))
    return ok

assert exp2_zaremba2d()
print("实验2 五个随机紧支鼓包：‖f‖₀ ≤ d‖∇f‖₁ 全部成立（d=2）")

# ---------------------------------------------------------------
# 实验 3：Riesz 表示与 Lax-Milgram 表示的差异。
# 同一泛函 l(x) = xᵀf：
#   Riesz（B = 欧氏内积）    → y_R = f；
#   Lax-Milgram（B(x,y)=xᵀMy，M 非对称强制）→ y_L = M⁻¹f。
# 断言 y_R ≠ y_L（真推广），且两条路线给出同一泛函值。
# ---------------------------------------------------------------
def exp3_two_representations():
    M = np.array([[1.0, 0.7, 0.0],
                  [0.1, 1.0, 0.6],
                  [0.0, 0.2, 1.0]])
    b = np.linalg.eigvalsh((M + M.T) / 2).min()
    assert b > 0.4                            # 强制（对称部分谱底 > 0）
    assert np.linalg.norm(M - M.T) > 0.3      # 非对称
    f = rng.standard_normal(3)
    yR = f.copy()
    yL = np.linalg.solve(M, f)
    assert np.linalg.norm(yR - yL) > 0.1      # 两个表示向量确实不同
    worst = 0.0
    for _ in range(50):
        x = rng.standard_normal(3)
        lhs = x @ yR                          # Riesz 值
        rhs = x @ (M @ yL)                    # Lax-Milgram 值
        worst = max(worst, abs(lhs - rhs))
    assert worst < 1e-12                      # 同一泛函
    return worst

w3 = exp3_two_representations()
print(f"实验3 y_R ≠ y_L 而 ⟨x,y_R⟩ = B(x,y_L)（50 次抽查最大偏差 {w3:.1e}）")

# ---------------------------------------------------------------
# 实验 4：离散 Green 函数与正交分解（48.5 的格点化身）。
# 1D −u″ 的差分矩阵 K（含 1/h 缩放）之逆 G：
#   (a) G 对称正定（离散 Green 函数的自伴性与正性）；
#   (b) G 的中列从中心向两边单调下降；
#   (c) 离散调和向量（线性函数 t）与紧支向量 z 的能量内积为 0：
#       Σ (t_{i+1}−t_i)(z_{i+1}−z_i)/h · (1/h) = 0（ telescoping）。
# ---------------------------------------------------------------
def exp4_green_orthogonality():
    m = 60
    h = 1.0 / (m + 1)
    K = (np.diag(2 * np.ones(m)) - np.diag(np.ones(m - 1), 1)
         - np.diag(np.ones(m - 1), -1)) / h
    G = np.linalg.inv(K)
    assert np.abs(G - G.T).max() < 1e-10                      # (a) 对称
    assert np.linalg.eigvalsh(G).min() > 0                    # (a) 正定
    col = G[:, m // 2]                                        # (b) 中列衰减
    half = col[m // 2:]
    assert np.all(np.diff(half) < 1e-12)
    ts = (np.arange(1, m + 1)) * h                            # 线性函数=离散调和
    z = np.zeros(m)
    z[20:40] = 1.0                                            # 紧支向量
    dt = np.diff(np.concatenate([[0.0], ts, [1.0]]))          # 每条边 Δt = h
    dz = np.diff(np.concatenate([[0.0], z, [0.0]]))           # 含边界零的 Δz
    energy_inner = np.sum(dt * dz) / h                        # ⟨∇t,∇z⟩ 离散
    assert abs(energy_inner) < 1e-12                          # (c) 正交
    return col[m // 2] / col.max()

gmax = exp4_green_orthogonality()
print(f"实验4 Green 对称正定、中列单调衰减（中心/最大 = {gmax:.3f}），调和⊥紧支 = 0")

print("END ====")
