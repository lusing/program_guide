# 第 03 章 · 最大公因子 —— Python 通道
#
# 扩展欧几里得对拍（sympy.igcdex）+ √2 的有限证据 + 平衡三进制。

from math import gcd
from sympy import Rational, gcdex as sympy_gcdex

print("==== 03 最大公因子")


def extgcd(a, b):
    """扩展欧几里得：返回 (d, s, t) 使 d = s·a + t·b。"""
    old_r, r = a, b
    old_s, s = 1, 0
    old_t, t = 0, 1
    while r != 0:
        q = old_r // r
        old_r, r = r, old_r - q * r
        old_s, s = s, old_s - q * s
        old_t, t = t, old_t - q * t
    return old_r, old_s, old_t


# 例 1.45
d, s, t = extgcd(326, 78)
assert (d, s, t) == (2, -11, 46), (d, s, t)
assert Rational(78, 326) == Rational(39, 163)
print(f"gcd(326, 78) = {d} = {s}·326 + {t}·78；78/326 既约 = 39/163 ✓")

# 与 sympy.gcdex 对拍 + 随机批量贝祖验证
import random
random.seed(20261104)
for _ in range(10**4):
    a = random.randint(1, 10**6)
    b = random.randint(1, 10**6)
    dd, ss, tt = extgcd(a, b)
    assert dd == gcd(a, b) and ss * a + tt * b == dd
    s2, t2, d2 = sympy_gcdex(a, b)
    assert d2 == dd and s2 * a + t2 * b == d2
print("extgcd × sympy.gcdex：10⁴ 对随机数贝祖恒等式全过 ✓")

# ---------- √2 无理：有限证据（如实声明：证据非证明，证明在正文与 Lean） ----------
for b in range(1, 10**4 + 1):
    a = round(2**0.5 * b)
    assert 2 * b * b != a * a
print("√2 有限证据：b ≤ 10⁴ 内 2b² ≠ a²（证明见正文 3.2 节与 Lean 通道）")

# ---------- 欧几里得步数 + 拉梅 ----------
def euclid_steps(a, b):
    steps = 0
    while b:
        a, b = b, a % b
        steps += 1
    return steps

def fib(n):
    a, b = 0, 1
    for _ in range(n):
        a, b = b, a + b
    return a

worst = []
for n in range(5, 31):
    a, b = fib(n + 1), fib(n)
    st = euclid_steps(a, b)
    assert st <= 5 * len(str(a))
    worst.append((n, st, 5 * len(str(a))))
print(f"拉梅定理：斐波那契对 (F₃₁, F₃₀) 需 {worst[-1][1]} 步 ≤ 5×{worst[-1][2]//5} 位 = {worst[-1][2]}")

# ---------- 进制与平衡三进制 ----------
def base_digits(n, b):
    ds = []
    while n:
        ds.append(n % b)
        n //= b
    return ds[::-1]

assert base_digits(12345, 7) == [5, 0, 6, 6, 4]
print("12345 = (50664)₇ ✓")

def balanced_ternary(n):
    """平衡三进制：数字 ∈ {−1, 0, 1}（天平称量的代数化身）。"""
    digits = []
    while n:
        r = n % 3
        if r == 2:
            digits.append(-1)
            n = (n + 1) // 3
        else:
            digits.append(r)
            n //= 3
    return digits[::-1]

def eval_bt(ds):
    v = 0
    for d in ds:
        v = v * 3 + d
    return v

for n in range(1, 41):
    ds = balanced_ternary(n)
    assert eval_bt(ds) == n and all(d in (-1, 0, 1) for d in ds)
ds19 = balanced_ternary(19)
expr19 = " ".join((f"+{3**i}" if d == 1 else f"−{3**i}") if d else ""
                  for i, d in zip(range(len(ds19) - 1, -1, -1), ds19)).strip()
print(f"平衡三进制：1..40 全部可表示（19 = {expr19}）✓")

print("END ====")
