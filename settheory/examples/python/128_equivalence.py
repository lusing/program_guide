# -*- coding: utf-8 -*-
print("==== 128 equivalence")
# 第 128 章 Python：等价、划分与序的精确计算面。
# ① 划分生成器与 Bell 数：3 元素 5 个、4 元素 15 个——
#    等价关系的个数恰是 Bell 数（机器揭示）；
# ② 划分↔等价关系的往返（书 2.3.8/2.3.9 互逆）；
# ③ 任意关系的等价闭包；
# ④ 家族三例（书 2.3.2）：后代 D 非自反非对称但传递、"共同祖先"
#    B 自反对称不传递、同父母 S 等价；
# ⑤ 序与格：极小≠最小（P(X)−{∅} 与整除）、(P(X),⊆) 完备格
#    （含空族的 sup∅=∅、inf∅=X 账，书 2.5.24）、整除格 sup=lcm/inf=gcd。
from fractions import Fraction
from itertools import product
from math import gcd, lcm


# ① 划分生成器（递归：首元素放进已有块或另立新块）
def partitions(items):
    if not items:
        yield []
        return
    first, rest = items[0], items[1:]
    for p in partitions(rest):
        for i in range(len(p)):
            yield [b if j != i else b | {first} for j, b in enumerate(p)]
        yield p + [{first}]


parts3 = list(partitions([0, 1, 2]))
parts4 = list(partitions([0, 1, 2, 3]))
assert len(parts3) == 5 and len(parts4) == 15              # Bell(3)=5, Bell(4)=15
# 块都是 frozenset 才能进集合
parts4 = [set(map(frozenset, p)) for p in parts4]
print("bell numbers: partitions of 3/4 elements = 5/15: OK")


# ② 划分 → 关系 → 商，往返复原
def induced(p):
    return frozenset((x, y) for b in p for x in b for y in b)


def is_equivalence(rel, U):
    for x in U:
        if (x, x) not in rel:                              # 自反
            return False
        for y in U:
            if (x, y) in rel and (y, x) not in rel:        # 对称
                return False
    for x, y, z in product(U, U, U):
        if (x, y) in rel and (y, z) in rel and (x, z) not in rel:   # 传递
            return False
    return True


def quotient(rel, U):
    return {frozenset(y for y in U if (x, y) in rel) for x in U}


for p4 in parts4:
    rel = induced(p4)
    assert is_equivalence(rel, [0, 1, 2, 3])
    assert quotient(rel, [0, 1, 2, 3]) == p4               # 2.3.8/2.3.9 互逆
rels = {induced(p4) for p4 in parts4}
assert len(rels) == 15                                     # 等价关系数 = Bell 数
print("roundtrip: partition -> relation -> partition, and 15 = # of equivalences: OK")

# ③ 等价闭包：最小包含 R 的等价关系
def eq_closure(R0, U):
    R = set(R0) | {(x, x) for x in U}
    while True:
        R2 = set(R) | {(x, z) for (x, y) in R for (y2, z) in R if y == y2}
        R2 = R2 | {(y, x) for (x, y) in R2}
        if R2 == R:
            return frozenset(R)
        R = R2


U5 = [0, 1, 2, 3, 4]
c = eq_closure({(1, 2), (3, 4)}, U5)
assert c == induced([{0}, {1, 2}, {3, 4}])                 # 闭包 = 诱导关系
print("equivalence closure: closure of {(1,2),(3,4)} = induced of {{0},{1,2},{3,4}}: OK")

# ④ 家族三例（书 2.3.2(1)）——gpA/gpC 是两位祖辈，b 的父母 p1、p2 分属两家
parents = {'gpA': (), 'gpC': (), 'p1': ('gpA',), 'p2': ('gpC',),
           'b': ('p1', 'p2')}
people = list(parents)


def ancestors(x):
    out = {x}
    for p in parents[x]:
        out |= ancestors(p)
    return out


def D(x, y):                                               # y 是 x 的（严格）后代
    return x in ancestors(y) - {y}


def B(x, y):                                               # 至少共享一位祖先（含自身）
    return ancestors(x) & ancestors(y) != set()


def S(x, y):                                               # 同父母
    return parents[x] == parents[y]


assert all(not D(x, x) for x in people)                    # 非自反
assert D('gpA', 'p1') and not D('p1', 'gpA')               # 非对称
assert all(D(x, z) for x, y, z in product(people, repeat=3)
           if D(x, y) and D(y, z))                         # 传递
assert all(B(x, x) for x in people)                        # 自反
assert all(B(x, y) == B(y, x) for x, y in product(people, repeat=2))   # 对称
assert B('gpA', 'b') and B('b', 'gpC') and not B('gpA', 'gpC')         # 不传递！
relS = frozenset((x, y) for x, y in product(people, repeat=2) if S(x, y))
assert is_equivalence(relS, people)                        # S 是等价关系
print("family D/B/S: D irrefl+asymm+transitive, B not transitive, S equivalence: OK")

# ⑤ 序与格
def subset_powerset(X):
    X = list(X)
    return [frozenset(X[i] for i in range(len(X)) if mask >> i & 1)
            for mask in range(1 << len(X))]


# 极小元与最小元（P({1,2}) − {∅}：两个极小、无最小）
pos1 = [s for s in subset_powerset({1, 2}) if s]
minimal = lambda pos, le: [m for m in pos
                           if not any(le(o, m) and o != m for o in pos)]
least = lambda pos, le: [m for m in pos if all(le(m, o) for o in pos)]
le_sub = lambda a, b: a <= b
assert set(minimal(pos1, le_sub)) == {frozenset({1}), frozenset({2})}
assert least(pos1, le_sub) == []
# 整除序 {2,3,4,6,12}：素数是极小元（无穷多个的缩影）、无最小、最大 12
divs = [2, 3, 4, 6, 12]
le_div = lambda a, b: b % a == 0
assert set(minimal(divs, le_div)) == {2, 3}
assert least(divs, le_div) == [] and least(divs, lambda a, b: a % b == 0) == [12]
print("order basics: minimal != least in P-{{0}} and divisibility poset: OK")

# (P({1,2,3}), ⊆) 完备格：任意族 sup=∪、inf=∩，含空族账（书 2.5.24）：
# sup∅ = ∅（一切元素都是上界，最小者是 ∅）、inf∅ = X（一切元素都是下界，最大者是 X）
P3 = subset_powerset({1, 2, 3})
TOP = frozenset({1, 2, 3})
for fam in (P3, [frozenset({1, 2}), frozenset({2, 3})], []):
    ubs = [u for u in P3 if all(s <= u for s in fam)]
    assert least(ubs, le_sub) == [frozenset().union(*fam)]           # sup = ⋃F
    lbs = [l for l in P3 if all(l <= s for s in fam)]
    assert least(lbs, lambda a, b: b <= a) == [TOP.intersection(*fam)]   # inf = ⋂F
print("powerset lattice: sup=family union, inf=intersection, sup(empty)=empty: OK")

# 整除格 {1,2,3,6}：sup = lcm、inf = gcd
D4 = [1, 2, 3, 6]
for a in D4:
    for b in D4:
        ubs = [u for u in D4 if u % a == 0 and u % b == 0]           # 公倍数
        assert least(ubs, le_div) == [lcm(a, b)]                     # sup = lcm
        lbs = [l for l in D4 if a % l == 0 and b % l == 0]           # 公因子
        assert least(lbs, lambda p, q: p % q == 0) == [gcd(a, b)]    # inf = gcd
print("divisibility lattice: sup = lcm, inf = gcd on {1,2,3,6}: OK")
print("END ====")
