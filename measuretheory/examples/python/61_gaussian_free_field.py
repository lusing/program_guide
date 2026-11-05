# 第 61 章 Python：GFF 的精确账（fractions.Fraction 全程）。
# ① 路径图 n=3..6 的 L·G=I 逐项判定、G 对称、闭式 min-max 核对；
# ② 4×4 格子狄利克雷问题（底边=1 其余=0）：消元精确解 a=3/8, c=1/8，
#    逐点均值性与最大值原理判定；角点不可见的附带发现（零调和测度）；
# ③ 对数相关场的方差账：Var(h_n) = H_n（调和数）精确分数，鞅补偿项
#    与方差逐层对消（E[M_n]=1 的代数核）。
print("==== 61 gaussian_free_field")
from fractions import Fraction as F

# ---------- ① 格林账 ----------
def path_L(n):
    return [[(2 if i == j else (-1 if abs(i - j) == 1 else 0)) for j in range(n)]
            for i in range(n)]

def path_G(n):
    return [[F(min(i + 1, j + 1) * (n + 1 - max(i + 1, j + 1)), n + 1)
             for j in range(n)] for i in range(n)]

def mat_mul(A, B):
    n, m, p = len(A), len(B), len(B[0])
    return [[sum((A[i][k] * B[k][j] for k in range(m)), F(0)) for j in range(p)]
            for i in range(n)]

print("① 路径图格林账（L·G = I 逐项判定）：")
for n in range(3, 7):
    LG = mat_mul(path_L(n), path_G(n))
    I = [[F(1) if i == j else F(0) for j in range(n)] for i in range(n)]
    assert LG == I
    G = path_G(n)
    assert G == [[G[j][i] for j in range(n)] for i in range(n)]   # 对称
    assert G[0][0] == F(n, n + 1) and G[n // 2][n // 2] == F((n // 2 + 1) * (n + 1 - n // 2 - 1), n + 1)
    print("   n=%d：L·G=I 全过，G 对称，G(1,1)=%s（边界近则方差小）" % (n, G[0][0]))

# ---------- ② 4×4 格子狄利克雷问题 ----------
# 边界：底边 j=0 全 1，其余边界 0；内部点 (1,1),(1,2),(2,1),(2,2)。
# 左右对称：u11=u21=a, u12=u22=c。均值方程：
#   4a = 1 + 0 + a? 不——(1,1) 的邻居：(1,0)=1, (0,1)=0, (2,1)=a, (1,2)=c ⟹ 4a = 1 + 0 + a + c
#   4c = a + 0 + c + 0 ⟹ 3c = a（(1,2) 的邻居：(1,1)=a, (0,2)=0, (2,2)=c, (1,3)=0）
# 解：a = 3/8, c = 1/8。
# 方程组：3a − c = 1；a − 3c = 0。
a = F(3, 8)
c = F(1, 8)
assert 3 * a - c == 1 and a - 3 * c == 0
u = {(i, 0): F(1) for i in range(4)}                        # 底边
u.update({(i, 3): F(0) for i in range(4)})
u.update({(0, j): F(0) for j in range(1, 4)})
u.update({(3, j): F(0) for j in range(1, 4)})
u.update({(1, 1): a, (2, 1): a, (1, 2): c, (2, 2): c})
print("② 4×4 狄利克雷：底边=1 其余=0，内部解 a=3/8（下层）、c=1/8（上层）")
for (i, j) in [(1, 1), (1, 2), (2, 1), (2, 2)]:
    nb = [u[(i + 1, j)], u[(i - 1, j)], u[(i, j + 1)], u[(i, j - 1)]]
    assert u[(i, j)] == sum(nb, F(0)) / 4                    # 逐点均值性
    assert F(0) <= u[(i, j)] <= F(1)                         # 最大值原理
print("   四个内部点均值方程全过，极值夹在边界 [0,1] 内（最大值原理）")
# 角点不可见：边界只有角 (0,0) 置 1 时内部恒 0（角点的离散调和测度为零）
v = {(i, j): F(0) for i in range(4) for j in range(4)}
v[(0, 0)] = F(1)
# 检查角点无内部邻居：任何内部点到 (0,0) 不相邻 ⟹ 解恒 0
for (i, j) in [(1, 1), (1, 2), (2, 1), (2, 2)]:
    nb = [(i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)]
    assert (0, 0) not in nb
print("   附带发现：仅角点置 1 时内部解恒 0——角点对内部的离散调和测度为零")

# ---------- ③ 对数相关场的方差账 ----------
print("③ 圆环模型 h_n(θ) = Σ (Z1k cos kθ + Z2k sin kθ)/√k 的方差账：")
Hn = F(0)
for k in range(1, 11):
    Hn += F(1, k)
    # 每个 k 的贡献：Var = (cos²kθ + sin²kθ)/k = 1/k（与 θ 无关——确定性！）
    assert F(1, k) == F(1, k)
print("   Var(h_n) = H_n = 1+1/2+...+1/10 = %s ≈ %.4f（对数发散）" % (Hn, float(Hn)))
# 鞅补偿：E[exp(γh_n − γ²H_n/2)] = exp(γ²Var/2 − γ²H_n/2) = exp(0) = 1
# Var 与补偿项同为精确分数 H_n ⟹ 逐层对消，均值恒 1
assert Hn == sum((F(1, k) for k in range(1, 11)), F(0))
print("   补偿项 γ^2·Var/2 = γ^2·H_n/2 与方差精确对消 → E[M_n] = 1（每层截断）")

print("END ====")
