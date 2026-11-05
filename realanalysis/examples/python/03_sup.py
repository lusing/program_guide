# 第 03 章 上确界：Python 通道。
# q-迭代逼近 √2 的精确有理数轨迹，与序列值域 {1-1/(n+1)} 的截断上确界。
# 运行：python -I 03_sup.py
from fractions import Fraction

print("==== 03 sup ====")

# --- 1. q-迭代：每步核验定理 4.1 的两条恒等式 ------------------------
# q - p = (2 - p^2)/(p+2)，q^2 - 2 = 2(p^2 - 2)/(p+2)^2。
def qstep(p):
    return (2 * p + 2) / (p + 2)

def check_identities(p):
    q = qstep(p)
    assert q - p == (2 - p * p) / (p + 2)
    assert q * q - 2 == 2 * (p * p - 2) / (p + 2) ** 2
    return q

p = Fraction(1)
traj = [p]
for _ in range(8):
    q = check_identities(p)
    assert q > p and q * q < 2
    traj.append(q)
    p = q
print("q-iteration from below, p_8 =", traj[-1])
print("gap 2 - p_8^2 =", 2 - traj[-1] ** 2)

# 对偶方向：从 2 出发，每步变小，平方仍大于 2。B 没有最小元。
p = Fraction(2)
above = [p]
for _ in range(8):
    q = check_identities(p)
    assert 0 < q < p and q * q > 2
    above.append(q)
    p = q
print("q-iteration from above, p_8 =", above[-1])
print("gap p_8^2 - 2 =", above[-1] ** 2 - 2)

# --- 2. 有限集 sup = max ----------------------------------------------
assert max(traj) == traj[-1]
assert all(t <= max(traj) for t in traj)

# --- 3. {1 - 1/(n+1)} 的截断上确界 -------------------------------------
def f(n):
    return 1 - Fraction(1, n + 1)

for N in (10, 1000, 100000):
    best = max(f(n) for n in range(N + 1))
    assert best == f(N) < 1
    assert 1 - best == Fraction(1, N + 1)
print("truncated sup stays below 1 at every finite N")

# Archimedean 核验：给定 eps 存在 n 使 1 - 1/(n+1) > 1 - eps。
import math
for eps in (Fraction(1, 10), Fraction(1, 10 ** 6)):
    n = int(1 / eps) + 1
    assert f(n) > 1 - eps
print("archimedean witness: n > 1/eps works")

# --- 4. 例 4.8：{1/(n+1)} 的截断上确界是 1，截断下确界贴着 0 --------
def g(n):
    return Fraction(1, n + 1)

for N in (10, 1000, 100000):
    vals = [g(n) for n in range(N + 1)]
    assert max(vals) == g(0) == 1
    assert min(vals) == g(N) == Fraction(1, N + 1) > 0
print("sup of {1/(n+1)} is attained at n = 0; inf is not attained")

# 中点论证：任何 γ < 3 的有理数都不是 (−∞, 3) 的上界。
gamma = Fraction(5, 2)
mid = (gamma + 3) / 2
assert gamma < mid < 3

print("END ====")
