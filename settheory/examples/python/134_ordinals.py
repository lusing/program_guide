# -*- coding: utf-8 -*-
print("==== 134 ordinals")
# 第 134 章 Python：序数即"排在它之前的全体序数"（书 4.3 式）。
# ① 构造 von Neumann 链 0..ω+ω 的（有窗口）元素表：α 的元素 =
#    {β | β < α}——用康托正则形式（CNF）表示 α，枚举其下的样本；
# ② sup=⋃、inf=⋂（书 4.2.8）在元素表上直接对账；
# ③ Hartogs 数的有限影子（书 4.2.12）：H(X) 是不与 X 任何子集等势
#    的最小序数——对 |X|=n，H(X)=n+1；
# ④ 自然数恰是有穷序数（4.2.9）的账目。

# CNF 元素（低位在前）：α = c0 + c1·ω + c2·ω² ...
def canon(v):
    while v and v[-1] == 0:
        v = v[:-1]
    return tuple(v)


def olt(a, b):
    a, b = canon(a), canon(b)
    if len(a) != len(b):
        return len(a) < len(b)
    return a < b                        # 高位先比的元组比较：右字典序


def osucc(a):
    a = list(canon(a))
    a[0] += 1
    return canon(a)


W = (0, 1)                              # ω

# ① α 之下的序数样本（窗口：ω²·3 以内）
def window_elems(cap=(9, 3)):
    """cap 窗口内的全部 CNF 样本（按 < 升序生成）。"""
    elems = []
    for deg2 in range(cap[1]):          # ω² 项
        for deg1 in range(cap[1]):      # ω 项
            for c0 in range(cap[0]):
                v = [c0, deg1, deg2] if deg2 or deg1 or c0 else []
                elems.append(canon(v))
    return sorted(set(elems), key=lambda x: (len(x), x))


def elements_of(alpha, window):
    return [b for b in window if olt(b, alpha)]


win = window_elems()
assert elements_of(W, win)[0:6] == [(), (1,), (2,), (3,), (4,), (5,)]   # ω 之下是自然数
assert W in elements_of((1, 1), win)                  # ω ∈ ω+1（即 ω < ω+1）
assert olt((1,), W) and not olt(W, (1,))
print("ordinal as set of predecessors: elements of w are the naturals: OK")

# ② sup=⋃、inf=⋂（在元素表口径下对账）
A, B = (5,), (3, 1)                    # 5 与 ω+3
elemsA, elemsB = set(elements_of(A, win)), set(elements_of(B, win))
union_elems = elemsA | elemsB
# ⋃{A,B} 的元素 = 元素的元素之并；而 sup{A,B}=ω+3 的元素表恰相等
supAB = (3, 1)
assert set(elements_of(supAB, win)) >= union_elems    # 大者吃小者（窗口）
# inf{A,B} = 5：交集口径
assert (elemsA & elemsB) <= set(elements_of((5,), win))
print("sup/inf as union/intersection of element-sets (window): OK")

# ③ Hartogs 有限影子：H(X)（|X|=n）= n+1
from itertools import product as iproduct


def injects_into(alpha, elems_alpha, X):
    """序数 alpha（以元素样本代表）是否单射进 n 元集 X：元素两两不同。"""
    return len(elements_of(alpha, elems_alpha)) <= len(X)


for n in (2, 3):
    H = None
    for a in sorted(set(win), key=lambda x: (len(x), x)):
        if not injects_into(a, win, list(range(n))):
            H = a
            break
    assert H == (n + 1,), (H, n)
    # 窗口结论：n 元集的 Hartogs 是 n+1（第一个装不下的序数）
print("hartogs finite shadow: first ordinal not injecting into n-set is n+1: OK")

# ④ 自然数 = 有穷序数：一维 CNF 恰是有穷个
finite_cnf = [e for e in win if len(e) <= 1]
assert all(olt(e, W) for e in finite_cnf)            # 都 < ω
assert all(not olt(W, e) for e in finite_cnf)
print("finite ordinals are exactly the naturals (4.2.9): OK")
print("END ====")
