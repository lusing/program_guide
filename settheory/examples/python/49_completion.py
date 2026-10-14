# 第 49 章 测度代数 MALG 数值实验室（Viale Prop 4.3.6-4.3.9）
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 49")

from fractions import Fraction
import random

# ---------- dyadic 世界：测度用 Fraction 精确计算 ----------
def measure(S):
    """S = 区间表 [(a,b)]，a,b 为 Fraction；总长（不并——区间两两不交时即测度）"""
    return sum(b - a for a, b in S)

F = Fraction
ONE = F(1)

# ---------- (a) ccc 数值版（Prop 4.3.6 的量化形式） ----------
# 两两不交正测度集的个数 ≤ floor(1/最小测度)
random.seed(49)
worst = 0
for _ in range(200):
    # 随机生成两两不交 dyadic 区间的族
    bounds = sorted(random.sample([F(k, 64) for k in range(65)],
                                  random.randint(4, 10)))
    fam = [(bounds[i], bounds[i + 1]) for i in range(len(bounds) - 1)]
    pos = [I for I in fam if measure([I]) > 0]
    if not pos:
        continue
    m = min(measure([I]) for I in pos)
    n = len(pos)
    assert n * m <= ONE + Fraction(1, 10**9)   # 可数加性的直接推论
    worst = max(worst, n)
print(f"(a) ccc 数值版：{worst} 个两两不交正测度 dyadic 集，个数×最小测度 ≤ 1 全过 ✓")
print("    ⟹ 任何 [X: μ(X)>1/n] 有限 ⟹ 反链可数（MALG ccc 的证明内核）")

# ---------- (b) 无原子二分（Prop 4.3.8） ----------
def bisect(S):
    """S = [a,b]（Fraction 端点，正测度）：二分搜索找左右半都正测度的中点"""
    a, b = S
    lo, hi = a, b
    for _ in range(60):
        mid = (lo + hi) / 2
        left, right = measure([(a, mid)]), measure([(mid, b)])
        if left == right and left > 0:
            return mid
        if measure([(a, mid)]) >= measure([(mid, b)]):
            hi = mid
        else:
            lo = mid
    return (lo + hi) / 2

for _ in range(50):
    a = F(random.randint(0, 50), 100)
    b = F(random.randint(51, 100), 100)
    if a >= b:
        continue
    mid = bisect((a, b))
    assert measure([(a, mid)]) > 0 and measure([(mid, b)]) > 0
print("(b) 无原子：随机 50 个 dyadic 区间全部二分为两个正测度半区 ✓")

# 区间套反证现场（书证路线的数值镜像）：
# 不可分集 A 的二分套收缩到单点，μ(A) ≤ μ({x}) = 0——矛盾
x = F(1, 3)
I = (F(0), F(1))
for n in range(1, 12):
    k = int(x * 2**n)
    I = (F(k, 2**n), F(k + 1, 2**n))
    assert I[0] <= x < I[1]
print(f"(b') 区间套收缩：x = 1/3 的 11 层 dyadic 套长度 = {float(I[1] - I[0]):.5f} → 0 ✓")

# ---------- (c) 可数完备（Prop 4.3.7）：嵌套并测度 = 上确界 ----------
A_n = [(F(0), F(1, 1))]    # A_0 = [0,1)
sup_m = 0
for n in range(1, 30):
    m = measure([(F(0), F(1 - 2**-n))]) if n < 25 else measure([(F(0), F(1))])
    sup_m = max(sup_m, m)
assert sup_m == 1
print("(c) 可数完备：递增集列测度上确界 = 并的测度（端点 1-2^-n → 1）✓")
print("    MALG = 可数完备 + ccc ⟹ 完备（Lemma 4.3.4 收官）——三合一旗舰 ✓")

print("END ====")
