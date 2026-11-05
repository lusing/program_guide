# 第 45 章 Python：级数收敛的精确分数账（Fraction 全程）。
# ① 二进块调和证书：H_{2n} - H_n >= 1/2 对一切 n（调和发散的机器版）
#    与 1/k^2 <= 1/(k(k-1)) 逐项望远镜（收敛的上界 2 - 1/n）；
# ② 三级数三账在 d=1 与 d=3 下的对照（稀疏跳跃序列，固定种子）；
# ③ Feller 条件 nP(|X|>n) 的精确判定（beta=2 趋 0、beta=1 趋 1）；
# ④ Kronecker 引理的数值验证（b_n = n^2）。
print("==== 45 three_series")
from fractions import Fraction as F
import random


def harmonic(n):
    return sum((F(1, k) for k in range(1, n + 1)), F(0))


# ---------- ① 二进块证书与望远镜上界 ----------
print("① 精确分数账：")
for n in [8, 64, 512]:
    block = harmonic(2 * n) - harmonic(n)
    assert block >= F(1, 2)
    print("   H_%d - H_%d = %s >= 1/2（二进块证书）" % (2 * n, n, float(block)))
for n in [10, 100, 1000]:
    sq = sum((F(1, k * k) for k in range(2, n + 1)), F(0))
    tele = F(1) - F(1, n)              # Σ 1/(k(k-1)) = 1 - 1/n
    assert sq <= tele
    print("   Σ_{k=2}^{%d} 1/k^2 = %.6f <= 1 - 1/%d = %.6f（望远镜上界）"
          % (n, float(sq), n, float(tele)))

# ---------- ② 三级数三账（固定种子） ----------
rng = random.Random(4501)
def three_series(d, n):
    a = 0
    b = F(0)
    c = F(0)
    for k in range(1, n + 1):
        if rng.random() < F(1, k * k):
            x = F(10) if rng.random() < F(1, 2) else F(-10)
        else:
            x = F(0)
        if abs(x) >= d:
            a += 1
        else:
            b += x
            c += x * x
    return a, b, c


print("② 三级数三账（稀疏跳跃：P(跳)=1/k^2，跳幅 ±10）：")
for d in [1, 3]:
    a, b, c = three_series(F(d), 2000)
    print("   d=%d：(a)=%d，(b)=%s，(c)=%s" % (d, a, b, c))
# d=1 与 d=3 的差别只可能出现在跳幅 10 的项：它们在两个 d 下都越线，三账应全同
a1, b1, c1 = three_series(F(1), 500)
a3, b3, c3 = three_series(F(3), 500)
assert (a1, b1, c1) == (a3, b3, c3)
print("   d=1 与 d=3 的三账逐项相同（跳幅远大于 d 时阈值不敏感）")

# ---------- ③ Feller 条件精确判定 ----------
print("③ Feller 条件 nP(|X|>n)（尾 = (1+n)^(-beta)）：")
for beta in [1, 2]:
    vals = [F(n, (1 + n) ** beta) for n in [10, 100, 1000]]
    print("   beta=%d：n=10,100,1000 时 %s" % (beta, [str(float(v)) for v in vals]))
    if beta == 2:
        assert vals[2] < vals[1] < vals[0]
    else:
        assert vals[2] > F(99, 100)

# ---------- ④ Kronecker 引理 ----------
print("④ Kronecker 引理（b_n = n^2，Σ (a_k/b_k) 绝对收敛 => (1/b_n)Σ b_k x_k？）：")
# 取 x_k = (-1)^k：Σ (x_k·k)/k^2 = Σ (-1)^k/k 收敛；(1/n^2)Σ_{k<=n} (-1)^k·k -> 0
for n in [100, 1000]:
    s = sum(((-1) ** k) * k for k in range(1, n + 1))
    assert abs(s / (n * n)) < 1.0 / n
    print("   n=%d：|(1/n^2)·Σ(-1)^k k| = %.6f <= 1/n" % (n, abs(s / (n * n))))
print("END ====")
