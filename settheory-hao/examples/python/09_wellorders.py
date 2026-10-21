# -*- coding: utf-8 -*-
print("==== 09 wellorders")
# 第 09 章 Python：有限良序集的实验室。
# ① 3 元素集上的全部线序（6 个排列）都是（有限）良序；
# ② 前段引理 4.1.2：真前段恰是各 W[a]；
# ③ 增函数引理 4.1.4 的穷举：严格递增映射必满足 f(a) ≥ a；
# ④ 三歧性 4.1.6：任两个良序恰居 同构/同构于前段 其一；
# ⑤ 自同构唯一与同构唯一（4.1.5）的穷举。
from itertools import permutations, product


def all_linear_orders(U):
    """U 上全部线序：以升序排列编码（位置即序）。"""
    return [tuple(p) for p in permutations(U)]


def seg(order, a):
    """W[a] = {x | x < a}（书 4.1 式 (4.1)）。"""
    return order[:order.index(a)]


U3 = (0, 1, 2)
orders3 = all_linear_orders(U3)
assert len(orders3) == 6

# ② 前段引理：线序的全部初始段 = {()} ∪ {W[a]}，真前段恰是各 W[a]
for order in orders3:
    initials = {order[:k] for k in range(len(order) + 1)}
    proper = initials - {order}
    assert proper == {seg(order, a) for a in order}
print("initial segments: proper segments are exactly W[a] for all 6 orders: OK")

# ③ 增函数引理 4.1.4 的穷举（n=3，全部 3³ 个映射）
for order in orders3:
    pos = {x: order.index(x) for x in order}
    for vals in product(range(3), repeat=3):
        f = dict(zip(order, vals))
        increasing = all(f[x] < f[y]
                         for x in order for y in order
                         if pos[x] < pos[y] and x != y)
        if increasing:
            assert all(f[x] >= pos[x] for x in order)   # f(a) ≥ a
print("increasing maps: f(a) >= a for every strictly increasing map (n=3): OK")

# ④ 三歧性：同构 ⟺ 等长；前段同构 ⟺ 严格更短（4.1.6 有限版）
def iso(o1, o2):
    return dict(zip(o1, o2)) if len(o1) == len(o2) else None


tally = [0, 0, 0]
for o1 in orders3:                                      # 3 元
    for o2 in all_linear_orders((3, 4, 5, 6)):          # 4 元
        a = iso(o1, o2) is not None
        b = len(o1) < len(o2) and iso(o1, o2[:len(o1)]) is not None   # (b) W1 ≅ W2 前段
        c = len(o2) < len(o1) and iso(o2, o1[:len(o2)]) is not None   # (c) W2 ≅ W1 前段
        assert sum((a, b, c)) == 1                      # 恰居其一
        tally[(a, b, c).index(True)] += 1
assert tally == [0, 144, 0]                             # 3<4：全部走 (b)
print("trichotomy: cases (a)/(b)/(c) exclusive, 6x24 pairs all land in (b): OK")

# ⑤ 同构唯一（4.1.5(3)）：等长有限良序间的保序双射恰一个
for o1 in orders3:
    for o2 in orders3:
        n = len(o1)
        isos = [p for p in permutations(o2)
                if all(not (i < j) or o2.index(p[i]) < o2.index(p[j])
                       for i in range(n) for j in range(n))]
        assert len(isos) == 1                           # 存在且唯一
# 自同构唯一（4.1.5(2)）：取 o2 = o1 即恒等
for order in orders3:
    n = len(order)
    autos = [p for p in permutations(order)
             if all(not (i < j) or order.index(p[i]) < order.index(p[j])
                    for i in range(n) for j in range(n))]
    assert autos == [tuple(order)]                      # 只有恒等
print("iso/automorphism uniqueness: exactly one, the identity: OK")
print("END ====")
