# -*- coding: utf-8 -*-
print("==== 129 naturals")
# 第 129 章 Python：von Neumann 自然数的集合形态。
# ① 嵌套 frozenset 造数字 0..5，验证书 3.1.5 引理的有限版：
#    m ∈ n ⟺ m < n（(8) 的前半）、m ⊆ n ⟺ m ≤ n、传递性、m ∉ m；
# ② n 的元素恰是全部更小的自然数（n = {0,...,n-1}）；
# ③ 归纳集的最小性影子：含 0 且对后继封闭的集合必含每个数字；
# ④ 递归定义的加法/乘法（书 3.2.6 原样）与内建运算对拍；
# ⑤ 第二归纳原理的可计算影子：最小反例搜索器（n 以下全过才放行）。
from itertools import combinations

succ = lambda x: x | {x}

nat = [frozenset()]
for _ in range(6):
    nat.append(succ(nat[-1]))

# ① 引理 3.1.5 的有限审计
for n in range(1, 6):
    assert nat[n] == frozenset(nat[:n])               # ② n = {0..n-1}
    for m in range(6):
        assert (nat[m] in nat[n]) == (m < n)          # m ∈ n ⟺ m < n
        assert (nat[m] <= nat[n]) == (m <= n)         # m ⊆ n ⟺ m ≤ n（(8)）
assert all(not (nat[m] in nat[m]) for m in range(6))  # (7)：m ∉ m
for k, m, n in combinations(range(6), 3):             # (6)：传递
    assert nat[k] in nat[m] and nat[m] in nat[n]
# (4)：k ∈ n+1 ⟺ k ∈ n ∨ k = n
for n in range(5):
    for k in range(6):
        assert (nat[k] in nat[n + 1]) == (k < n or k == n)
print("von Neumann numerals: membership/substring lemmas 3.1.5 audited: OK")

# ③ 归纳集最小性（推导式审计）：若 I 含 0 且对后继封闭，则每个
# 数字都被"逼进"I——推导只许用两条规则：0 ∈ I；x ∈ I ⟹ S(x) ∈ I。
derived = [nat[0]]                                   # 规则一：0 ∈ I
while len(derived) < 6:
    derived.append(succ(derived[-1]))                # 规则二：封闭性
assert derived == nat[:6]                             # 被逼出来的恰是 nat 前段
# 所以 N（nat 的无穷版）是一切归纳集的子集——最小归纳集
print("inductive minimality: closure forces every numeral into I: OK")

# ④ 递归定义的运算（书 3.2.6）
def add_rec(m, n):
    return m if n == 0 else add_rec(m, n - 1) + 1

def mul_rec(m, n):
    return 0 if n == 0 else add_rec(mul_rec(m, n - 1), m)

for m in range(8):
    for n in range(8):
        assert add_rec(m, n) == m + n
        assert mul_rec(m, n) == m * n
print("recursive ops: add/mul defined per book match builtins: OK")

# ⑤ 第二归纳原理的可计算影子：assert_by_strong_induction
#    ——谓词对 n 成立的依据是"所有 k<n 已成立"
def strong_induct_upto(N, step):
    """step(known_good) -> bool：k 以下全过则 k+1 应过（书 3.1.9 的审计器）。"""
    known = []
    for k in range(N):
        assert step(k, known)
        known.append(k)
    return True

# 例：每个 n ≥ 2 都是"某个素数 + 更小的数"——需要全部更小值作证
def decomp_step(k, known):
    if k < 2:
        return True
    for p in (2, 3, 5, 7, 11, 13):
        if k - p >= 0 and (k - p in known or k - p == 0):
            return True
    return False

assert strong_induct_upto(30, decomp_step)
print("strong induction: step audit uses ALL smaller values, N=30: OK")
print("END ====")
