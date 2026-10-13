# 第 01 章 公理：Kuratowski 有序对与基数小实验
#
# 本文件的锚点实验：Kuratowski 编码 (a,b) = {{a},{a,b}} 的
# 注入性——"相等当且仅当分量相等"（Jech (1.1) 与习题 1.1）。
# 用 frozenset（可哈希、外延）实现，配合 doctest 式断言。

import sys
import io
from itertools import chain, combinations

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 01 公理：Kuratowski 有序对")

# ---------- 一、有序对 ----------

def opair(a, b):
    """Kuratowski 编码：(a,b) = {{a},{a,b}}"""
    return frozenset([frozenset([a]), frozenset([a, b])])

# 注入性：(a,b) = (c,d) ⟹ a=c ∧ b=d，对有限宇宙做穷举验证
def opair_injective_test(universe):
    import itertools
    for a, b, c, d in itertools.product(universe, repeat=4):
        if opair(a, b) == opair(c, d):
            assert (a, b) == (c, d), f"反例：({a},{b}) == ({c},{d})"
    return True

U = [0, 1, 2, 3]
assert opair_injective_test(U)
print(f"  穷举 {len(U)}⁴ 个组合：Kuratowski 编码注入性成立")

# 特例验证：a=b 时 {{a},{a,a}} = {{a}}（单点集的塌缩）
assert opair(1, 1) == frozenset([frozenset([1])])
print("  (a,a) = {{a}}：第二分量塌缩，注入性依然成立")

# ---------- 二、有序三元组的嵌套定义 ----------

def otriple(a, b, c):
    return opair(opair(a, b), c)    # (a,b,c) = ((a,b),c)

for a, b, c, d in [(0, 1, 2, 3), (3, 2, 1, 0), (1, 1, 2, 2)]:
    assert (otriple(a, b, c) == otriple(a, b, d)) == (c == d)
print("  (a,b,c) = ((a,b),c)：嵌套编码保持分量独立性")

# ---------- 三、分离公理与外延性 ----------

# 分离：性质在已有集合内划出子集
X = set(range(1, 11))
evens = {x for x in X if x % 2 == 0}
assert evens <= X                     # 分离的产物总是子集（"a subclass of a set is a set"）
print(f"  分离 {{x∈X : x 偶}} = {sorted(evens)} ⊆ X ✓")

# 外延性：Python set 按内容比较——这是"免费的外延公理"
assert {1, 2, 2, 3} == {3, 2, 1}
print("  {1,2,2,3} == {3,2,1}：程序集合天然外延")

# ---------- 四、幂集与 Cantor（有限预演） ----------

def powerset(s):
    """幂集：2^n 个子集（itertools 组合枚举）"""
    xs = list(s)
    return [set(c) for r in range(len(xs) + 1)
            for c in combinations(xs, r)]

for n in range(1, 6):
    S = set(range(n))
    P = powerset(S)
    assert len(P) == 2 ** n
    # Cantor：任何 f : S → P(S) 都不是满射（对角线）
    import itertools
    full = itertools.product(range(2 ** n), repeat=n)  # 枚举部分映射演示
print("  |P({1..n})| = 2^n 对 n≤5 穷举成立")

# 对角线的有限预演：n=3，任何 g 都漏掉 D = {x : x ∉ g(x)}
S = {0, 1, 2}
P = powerset(S)
# 取 g 为"贪心满映射"：g(x) = S - {x}（对每个 x 漏掉自己）
g = {x: S - {x} for x in S}
D = {x for x in S if x not in g[x]}
assert D == S
assert D not in [g[x] for x in S]     # D 不在 g 的像里
print(f"  对角线集 D = {sorted(D)} 不在像 {{g(x)}} 中：Cantor 有限预演 ✓")

# ---------- 五、替换公理 ----------

# 函数像限制在集合上是集合：就是 {F(x) : x ∈ X}
F = {x: x * x for x in X}
image = {F[x] for x in X}
assert image == {1, 4, 9, 16, 25, 36, 49, 64, 81, 100}
print(f"  替换：{{x² : x ∈ X}} = {sorted(image)}")

print("要点：存在公理=构造子，外延性=按内容比较，分离=推导式。")
print("END ====")
