# Ch01 适定性（Python 交叉通道）：Hadamard 反例 + 多重指标计数
#
# 与 julia/01_wellposed.jl 双通道交叉：
#   (a) Hadamard 反例数值再现（调和性在 Lean Ch01 已证）；
#   (b) 书 §1.5 习题 2：k 阶偏导数个数 = C(n+k-1, k)——直接枚举对账；
#   (c) 书 §1.5 习题 4 核：Leibniz 公式的二元对照 β<=α 计数。

import itertools
import math

print("==== 01")

# ---- (a) Hadamard 反例 ----
print("(a) Hadamard: u_n = sin(nx)sinh(ny)/n^2, boundary y=0 vanishing")
vals = []
for n in range(1, 22, 5):
    inner = math.sinh(n) / n**2
    vals.append((n, inner))
    print(f"    n={n:2d}: u_n(pi/2,1) = {inner:.3e}")
assert all(vals[i][1] < vals[i + 1][1] for i in range(len(vals) - 1)), "单调爆炸"
assert vals[-1][1] > 1e6, "n=21 internal value exceeds 1e6 while boundary data vanishes"

# 调和性数值核对（五点差分，与 Lean 的解析证明交叉）：
# 精确 Δu = 0 ⟹ 数值残差 = 截断项 (h^2/12)(u_xxxx + u_yyyy)
#                                = (h^2/6) n^2 |sin(nx)| sinh(ny)
def lap5(f, x, y, h=1e-3):
    return (f(x + h, y) + f(x - h, y) + f(x, y + h) + f(x, y - h) - 4 * f(x, y)) / h**2

for n in [1, 3, 7]:
    u = lambda x, y, n=n: math.sin(n * x) * math.sinh(n * y) / n**2
    r = abs(lap5(u, 0.4, 0.3))
    pred = (1e-6 / 6) * n**2 * abs(math.sin(n * 0.4)) * math.sinh(n * 0.3)
    print(f"    n={n}: |Delta_h u_n| = {r:.3e}  truncation predicted = {pred:.3e}")
    assert abs(r / pred - 1) < 0.02, "residual must equal predicted truncation"
print("    harmonic core cross-checked: residual == truncation (Lean: exact proof)")

# ---- (b) 习题 2：|alpha|=k 的多重指标个数 = C(n+k-1, k) ----
def multiindices(dim, order):
    return [c for c in itertools.combinations_with_replacement(range(dim), order)]

for (n, k) in [(2, 3), (3, 2), (3, 4)]:
    enum = len(multiindices(n, k))              # 星与隔板：with_replacement 枚举
    comb = math.comb(n + k - 1, k)
    print(f"(b) n={n}, k={k}: enumerated {enum}, C(n+k-1,k) = {comb}")
    assert enum == comb, "习题 2 的组合计数对账"

# ---- (c) Leibniz 对照计数：{beta : beta <= alpha} 的个数 = prod(a_i + 1) ----
alpha = (2, 1)
cnt = 0
for b1 in range(alpha[0] + 1):
    for b2 in range(alpha[1] + 1):
        if b1 <= alpha[0] and b2 <= alpha[1]:
            cnt += 1
prod = (alpha[0] + 1) * (alpha[1] + 1)
print(f"(c) alpha={alpha}: counted {cnt} sub-multiindices, prod(a_i+1) = {prod}")
assert cnt == prod

# 一般化：|beta| 遍历 C(|alpha| + n - 1, n - 1) 量级的分层枚举核对
alpha = (3, 2, 1)
cnt = sum(1 for b in itertools.product(*(range(a + 1) for a in alpha)))
prod = math.prod(a + 1 for a in alpha)
print(f"    alpha={alpha}: counted {cnt}, product = {prod}")
assert cnt == prod == 4 * 3 * 2

print("END ====")
