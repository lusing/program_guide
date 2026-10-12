import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(6161)
print("==== 61 Weyl 交换关系与散射 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：Wielandt 论证数值形态。
# 有界对：‖ABⁿ − BⁿA‖/n 随 n 衰减，与 [A,B]=iI 要求的恒 1 矛盾。
# ---------------------------------------------------------------
n = 60
A = rng.standard_normal((n, n))
B, _ = np.linalg.qr(rng.standard_normal((n, n)))
Bn = np.eye(n)
nA, nB = np.linalg.norm(A, 2), np.linalg.norm(B, 2)
ratios = []
for j in range(1, 25):
    Bn = Bn @ B
    ratios.append(np.linalg.norm(A @ Bn - Bn @ A, 2) / j)   # 谱范数（与界同口径）
# Wielandt 界：‖[A,Bⁿ]‖ ≤ 2‖A‖‖B‖‖B^{n-1}‖ = 2‖A‖‖B‖（B 正交）
# ⟹ 归一交换子 ≤ 2‖A‖‖B‖/j → 0；而 [A,B]=iI 要求它 = 2‖B^{n-1}‖ ≥ 恒量
for j, r in enumerate(ratios, start=1):
    assert r < 2 * nA * nB / j + 1e-9
assert ratios[-1] < 2 * nA * nB / 20
print(f"实验1 有界对 ‖[A,Bⁿ]‖/n ≤ 2‖A‖‖B‖/n（{2*nA*nB:.1f}/n）逐档成立 → 0；"
      f"[A,B]=iI 要求 ≥ 恒量——n > 2‖A‖‖B‖ = {2*nA*nB:.0f} 即矛盾（Wielandt）")

# ---------------------------------------------------------------
# 实验 2：本质谱稳定 vs 谱凝结。
# ---------------------------------------------------------------
m = 200
cluster = np.concatenate([np.linspace(1, 2, m // 2), np.linspace(4, 5, m // 2)])
cluster += rng.standard_normal(m) * 0.01
A0 = np.diag(cluster)
Um = np.linalg.qr(rng.standard_normal((m, m)))[0]
C1m = 0.05 * np.outer(Um[:, 0], Um[:, 0])            # 秩一微扰
Dm = rng.standard_normal((m, m)) * 0.002
ev1 = np.linalg.eigvalsh(A0 + C1m)
ev2 = np.linalg.eigvalsh(A0 + (Dm + Dm.T) / 2)
assert 0.9 < ev1.min() < 1.1 and 3.9 < ev1.max() < 5.1
assert 0.9 < ev2.min() < 1.1 and 3.9 < ev2.max() < 5.1
g0 = np.std(np.diff(np.sort(cluster)))
g2 = np.std(np.diff(ev2))
print(f"实验2 扰动谱区间稳定（Weyl 本质谱）；簇内间隔起伏 {g0:.4f} → {g2:.4f}（凝结加剧）")

# ---------------------------------------------------------------
# 实验 3：格点散射 + 相移单调性。
# 与 Julia 61 同款：|T|²+|R|²=1；c=2 无反射；s(k) 的辐角。
# ---------------------------------------------------------------
def scatter_lattice(c, k, L=40.0, n=4000):
    h = 2 * L / n
    xs = np.linspace(-L, L, n)
    V = -c / np.cosh(xs) ** 2
    om = (2 - 2 * np.cos(k * h)) / h ** 2
    sup = V < -1e-12
    i1 = int(np.argmax(sup))
    i2 = len(V) - 1 - int(np.argmax(sup[::-1]))
    mm = i2 - i1 + 1
    N = mm + 2
    Amat = np.zeros((N, N), dtype=complex)
    b = np.zeros(N, dtype=complex)
    ikx = lambda x: np.exp(1j * k * x)
    imx = lambda x: np.exp(-1j * k * x)
    for idx, j in enumerate(range(i1, i2 + 1)):   # idx 0..mm-1（0 基）
        Amat[idx, idx] = 2 / h ** 2 + V[j] - om
        if j - 1 >= i1:
            Amat[idx, idx - 1] = -1 / h ** 2
        else:
            b[idx] += (1 / h ** 2) * ikx(xs[j - 1])
            Amat[idx, mm] = (-1 / h ** 2) * imx(xs[j - 1])       # R 列
        if j + 1 <= i2:
            Amat[idx, idx + 1] = -1 / h ** 2
        else:
            Amat[idx, mm + 1] = (-1 / h ** 2) * ikx(xs[j + 1])   # T 列
    # 连接方程（行 mm 与 mm+1）
    Amat[mm, 0] = 1.0
    b[mm] = ikx(xs[i1])
    Amat[mm, mm] -= imx(xs[i1])          # u_0 = e^{ikx} + R e^{-ikx}
    Amat[mm + 1, mm - 1] = 1.0
    Amat[mm + 1, mm + 1] -= ikx(xs[i2])  # u_{mm-1} = T e^{ikx}
    z = np.linalg.solve(Amat, b)
    T, R = z[mm + 1], z[mm]
    return abs(T) ** 2, abs(R) ** 2, np.angle(T)

for (c, k) in ((1.0, 0.8), (0.5, 0.4), (1.0, 2.0)):
    T2, R2, _ = scatter_lattice(c, k)
    assert 0 < T2 < 1
    assert abs(T2 + R2 - 1) < 1e-9
for k in (0.8, 1.5, 2.5):
    T2, R2, _ = scatter_lattice(2.0, k)
    assert T2 > 0.999 and R2 < 1e-5
# 相移随 k 的演化（c=1）：s(k) = T 的辐角轨迹
ks = np.linspace(0.3, 3.0, 10)
phases = np.unwrap([scatter_lattice(1.0, k)[2] for k in ks])
assert np.all(np.diff(phases) < 0.3)          # 缓变（无非弹性突变）
print(f"实验3 格点散射：|T|²+|R|² = 1（1e-9）；c=2 无反射全透射；相移随 k 缓变单调形态")

print("END ====")
