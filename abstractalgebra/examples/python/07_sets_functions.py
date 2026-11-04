# 第 07 章 · 集合、函数与等价关系 —— Python 通道

from itertools import product, permutations

print("==== 07 集合、函数与等价关系")

is_injective = lambda f: len(set(f)) == len(f)
is_surjective = lambda f, m: len(set(f)) == m

# 鸽笼：|X| = |Y| = 3
fs33 = list(product(range(3), repeat=3))
assert len(fs33) == 27
for f in fs33:
    assert is_injective(f) == is_surjective(f, 3)
assert sum(map(is_injective, fs33)) == 6
print("3 元集间 27 个函数：单 ⟺ 满（鸽笼）；双射恰 3! = 6 ✓")

# 3 → 4：有单无满
fs34 = list(product(range(4), repeat=3))
assert sum(map(is_injective, fs34)) == 24
assert sum(f for f in (is_surjective(f, 4) for f in fs34)) == 0
print("3 → 4：单射 24 个、满射 0 个 ✓")

# 4 元集：双射 24
fs44 = list(product(range(4), repeat=4))
assert sum(1 for f in fs44 if is_injective(f) and is_surjective(f, 4)) == 24
print("4 元集：双射恰 4! = 24 ✓")

# 复合结合律：(h∘g)∘f = h∘(g∘f)，2 元集全部函数三元组
fs22 = list(product(range(2), repeat=2))
for f, g, h in product(fs22, repeat=3):
    gf = tuple(g[f[i]] for i in range(2))
    lhs = tuple(h[gf[i]] for i in range(2))      # h∘(g∘f)
    hg = tuple(h[g[i]] for i in range(2))
    rhs = tuple(hg[f[i]] for i in range(2))      # (h∘g)∘f
    assert lhs == rhs
print("复合结合律：2 元集间全部函数三元组逐点成立 ✓")


# 贝尔数：划分枚举
def set_partitions(xs):
    if not xs:
        yield []
        return
    first, *rest = xs
    for p in set_partitions(rest):
        yield [[first]] + p
        for i in range(len(p)):
            q = [blk[:] for blk in p]
            q[i].append(first)
            yield q


parts4 = list(set_partitions([1, 2, 3, 4]))
assert len(parts4) == 15
for p in parts4:
    rel = {(a, b) for blk in p for a in blk for b in blk}
    assert all((a, a) in rel for a in range(1, 5))          # 自反
    assert all((b, a) in rel for (a, b) in rel)             # 对称
    assert all((a, c) in rel                                # 传递
               for (a, b) in rel for (b2, c) in rel if b == b2)
parts5 = list(set_partitions([1, 2, 3, 4, 5]))
assert len(parts5) == 52
print("贝尔数：B(4) = 15（三公理全过），B(5) = 52 ✓")

print("END ====")
