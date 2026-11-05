# 第 59 章 Python：随机游动的精确分数账（fractions.Fraction）。
# ① Polya 判别的两笔账：p=1/2 时 Σ C(2k,k)/4^k 调和发散（部分和增长），
#    p=3/5 时 Σ C(2k,k)(pq)^k 几何收敛到精确值 g* = 1/|2p−1| = 5；
# ② 首返分布 f^(2k) = 2·Catalan(k−1)/2^(2k) 的精确值与部分和向 1 逼近；
# ③ 通信链（p=3/4）转移阵幂的精确有理矩阵（n=1..6），对角元 → 1/2。
print("==== 59 random_walks")
from fractions import Fraction as F
from math import comb

# ---------- ① Polya 两笔账 ----------
print("① 对称游动：P(S_{2k}=0) = C(2k,k)/4^k 的部分和（发散）：")
partial = []
s = F(0)
for j in range(1, 321):
    s += F(comb(2 * j, j), 4 ** j)
    if j in (1, 5, 20, 80, 320):
        partial.append((j, s))
for j, v in partial:
    print("   Σ_{k≤%d} = %s ≈ %.4f" % (j, v, float(v)))
# √ 型发散：Σ_{k≤K} ≈ 2√(K/π) − 1（K=320 时 ≈ 19.2），精确分数判 > 15
assert partial[-1][1] > 15
print("   （Σ ~ 2√(K/π) - 1：K=320 时理论 ≈ 19.2 —— 调和发散，常返）")
# 偏置 p = 3/5：pq = 9/25，4pq = 36/25 < 1，g* = 1/sqrt(1−4pq) = 5（精确）
p, q = F(3, 5), F(2, 5)
g = F(0)
for j in range(1, 400):
    g += F(comb(2 * j, j)) * (p * q) ** j
print("① 偏置 p=3/5：g* = 1 + Σ_{k≥1} = %s ≈ %.6f -> 精确极限 5（1/|2p-1|）" % (g + 1, float(g + 1)))
assert abs((g + 1) - 5) < F(1, 1000)  # +k=0 项（P(S_0=0)=1）；g* = 5
print("   → g* = 5, f* = 1 - 1/g* = 4/5 = 1 - |2p-1|（回返概率公式精确核对）")

# ---------- ② 首返分布 ----------
def catalan(m):
    return comb(2 * m, m) // (m + 1)
print("② 首返分布 f^(2k) = 2·C_{k-1}/2^(2k) 的精确值：")
sf = F(0)
for k in range(1, 9):
    f2k = F(2 * catalan(k - 1), 2 ** (2 * k))
    sf += f2k
    print("   k=%d：f^(2k) = %s，部分和 = %s" % (k, f2k, sf))
# 精确核对前四项：1/2, 1/8, 1/16, 5/128
assert F(2 * catalan(0), 4) == F(1, 2)
assert F(2 * catalan(1), 16) == F(1, 8)
assert F(2 * catalan(2), 64) == F(1, 16)
assert F(2 * catalan(3), 256) == F(5, 128)
print("   部分和 → 1（余项 ~ c/√n）：Σf* = 1，对称游动常返")

# ---------- ③ 通信链转移阵幂 ----------
p = F(3, 4)
qq = 2 * p - 1                      # q = 1/2
print("③ 通信链（p=3/4，q=2p-1=1/2）的 P^(n) 对角元 (1+q^n)/2：")
for n in range(1, 7):
    diag = (1 + qq ** n) / 2
    off = (1 - qq ** n) / 2
    assert diag + off == 1
    print("   n=%d：p^(n)11 = %s，p^(n)12 = %s" % (n, diag, off))
assert (1 + qq ** 6) / 2 == F(65, 128)
print("   → 1/2：记忆衰减率 q^n = 2^-n，遍历极限 π = (1/2, 1/2)")

print("END ====")
