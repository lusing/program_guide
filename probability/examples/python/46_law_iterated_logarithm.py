# 第 46 章 Python：重对数律的精确账（Fraction 尾概率 + 定长游走）。
# ① 分级点 n = 2^j 的精确二项尾分数（分子分母全整数）与多项式界对照；
# ② 整数证书：2^n >= n^3 的最小 n（Lean 已对一切 n >= 10 证明）；
# ③ 慢尺度演示：一条 10^5 步轨道的 T_n 在不同 n 处的取值（远小于 1）；
# ④ 尾事件频率：max T_k > c 的比例随 N 的变化（c 越大越慢）。
print("==== 46 lil")
from fractions import Fraction as F
from math import comb, log, sqrt
import random


def binom_tail_frac(n, t):
    """P(S_n >= t) = P(Bin(n,1/2) >= (n+t)/2) 的精确分数（S = 2B - n）。"""
    idx = (n + t + 1) // 2
    num = sum(comb(n, i) for i in range(idx, n + 1))
    return F(num, 2 ** n)


# ---------- ① 分级二项尾精确分数 ----------
print("① 分级点 n=2^j 的精确二项尾 vs 界 (j·ln2)^(-2)：")
for j in [4, 6, 8, 10, 12]:
    n = 2 ** j
    thr = int(sqrt(2 * n * 2 * log(log(n)))) + 1
    tail = binom_tail_frac(n, thr)
    bound = 1.0 / (j * log(2)) ** 2
    print("   j=%-2d n=%-5d 阈=%-3d 尾=%s ≈ %.6f，界=%.6f%s"
          % (j, n, thr, tail, float(tail), bound, "（<= 界）" if float(tail) <= bound else "（未过）"))
    assert float(tail) <= bound
assert binom_tail_frac(16, 10) == F(697, 65536)   # S>=10 ⟺ Bin>=13，Lean 件同一账

# ---------- ② 整数证书 ----------
print("② 整数证书：2^n >= n^3 与 2^n >= n^5 的最小 n：")
for k in [3, 5]:
    n0 = next(n for n in range(2, 200) if 2 ** n >= n ** k and 2 ** (n - 1) < (n - 1) ** k)
    print("   2^n >= n^%d 且此后恒成立的最小 n = %d（ Lean 已证 n^3 情形对一切 n >= 10）" % (k, n0))
assert next(n for n in range(2, 200) if 2 ** n >= n ** 3 and 2 ** (n - 1) < (n - 1) ** 3) == 10

# ---------- ③ 慢尺度 ----------
print("③ 慢尺度（种子 4601，T_n = S_n/sqrt(2n·lnln n)）：")
rng = random.Random(4601)
s = 0
marks = {}
for k in range(1, 100001):
    s += 1 if rng.random() < 0.5 else -1
    if k >= 16 and k in (16, 100, 10 ** 3, 10 ** 4, 10 ** 5):
        marks[k] = s / sqrt(2 * k * log(log(k)))
for k, v in marks.items():
    print("   n = %-6d：T_n = %.4f" % (k, v))
assert all(abs(v) < 1.5 for v in marks.values())

# ---------- ④ 尾事件频率 ----------
print("④ 尾事件频率（100 轨道 × N = 2×10^4）：")
for c in [0.4, 0.7]:
    cnt = 0
    for i in range(100):
        r = random.Random(4600 + i)
        s2 = 0
        best = -9.9
        for k in range(1, 20001):
            s2 += 1 if r.random() < 0.5 else -1
            if k >= 16:
                v = s2 / sqrt(2 * k * log(log(k)))
                best = max(best, v)
        cnt += best > c
    print("   c = %.1f：比例 = %.2f（limsup = 1 => 比例随 N -> 1）" % (c, cnt / 100))
print("END ====")
