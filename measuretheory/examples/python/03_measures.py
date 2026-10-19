import io
import sys
from fractions import Fraction

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 03 measures")

# 第 03 章：测度可数可加与连续性——Python 用 Fraction 精确有理数
# （与 Julia 浮点对拍：这里没有舍入误差）。

mu_atom = lambda k: Fraction(1, 2 ** k)

# 总质量（截断到 N=60：精确 = 1 - 2^-60）
N = 60
total = sum(mu_atom(k) for k in range(1, N + 1))
assert total == Fraction(1) - Fraction(1, 2 ** 60)
print(f"μ(Ω) 截断 {N} 项 = 1 - 2^-60（精确有理数）")

# 下方连续：部分和
assert sum(mu_atom(k) for k in range(1, 30)) == Fraction(2 ** 30 - 2, 2 ** 30)
print("下方连续：μ({1..n}) = 1 - 2^-n（精确）")

# 上方连续：尾部（截断到 10n 的同口径对照）
for n in (1, 5, 10, 20):
    tail_num = sum(mu_atom(k) for k in range(n, 10 * n + 1))
    tail_ana = Fraction(1, 2 ** (n - 1)) - Fraction(1, 2 ** (10 * n))
    assert tail_num == tail_ana, "截断等比和精确吻合"
print("上方连续：μ({n,n+1,...}) = 2^{-(n-1)} → 0（截断口径精确吻合）")

# 偶/奇不交分解（精确 1/3、2/3）
even = sum(mu_atom(k) for k in range(2, 61, 2))
odd = sum(mu_atom(k) for k in range(1, 61, 2))
assert even == Fraction(1, 3) - Fraction(1, 3 * 2 ** 60)  # 精确截断值
assert odd == Fraction(2, 3) - Fraction(1, 3 * 2 ** 59)
print(f"μ(偶) ≈ {float(even):.6f}，μ(奇) ≈ {float(odd):.6f}，和恰为 1（精确）")

# 随机子集的单调性/次可加性（浮点随机、精确求值）
import random

random.seed(7)
ok = True
for _ in range(500):
    A = {k for k in range(1, 31) if random.random() < 0.3}
    B = {k for k in range(1, 31) if random.random() < 0.3}
    muA, muB = sum(mu_atom(k) for k in A), sum(mu_atom(k) for k in B)
    muAB = sum(mu_atom(k) for k in A | B)
    ok &= muA <= muAB and muAB <= muA + muB
assert ok, "单调性与次可加性（精确有理数）500 次全过"
print("单调性 + 次可加性：500 次随机实验（精确有理数）全过")

print("END ====")
