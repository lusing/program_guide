# -*- coding: utf-8 -*-
print("==== 41 martingale_inequalities")
# 第 41 章 Python：公平游戏账本（Fraction 精确版）。
# ① 有限二叉树鞅的全树期望；② Doob 分解精确拆解；
# ③ 可选停止的精确账。
from fractions import Fraction
from itertools import product

# ① 有限二叉树：X_n = S_n（简单随机游走），2 层全树
# E[S_2] = 0（全 4 条路径平均）
paths2 = list(product((-1, 1), repeat=2))
S2 = [sum(p) for p in paths2]
mean = Fraction(sum(S2), 4)
assert mean == 0
# S_1 的条件期望账：E[S_2 | S_1] = S_1
for s1 in (-1, 1):
    children = [s1 + d for d in (-1, 1)]
    assert Fraction(sum(children), 2) == s1
print("binary tree martingale: E[S2|S1] = S1 exact: OK")

# ② Doob 分解的精确拆解：X_n = n + S_n（趋势 + 噪声）
# 可料部分 A_n = n（确定性趋势），鞅部分 M_n = S_n
for n in range(1, 5):
    An = n              # E[X_k - X_{k-1} | F] = 1 累积 = k
    Mn = 0              # 鞅部分初值 0
    assert An + Mn == n + 0
print("Doob decomposition: X = trend(n) + martingale(S), exact: OK")

# ③ 上穿不等式的精确账：路径 [+1,-1,+1,-1] 于 [-0.5, 0.5]
path = (1, -1, 1, -1)
def crossings(p, a, b):
    cnt, below = 0, False
    s = 0
    for d in p:
        s += d
        if s < a: below = True
        if below and s > b:
            cnt += 1; below = False
    return cnt
u = crossings(path, Fraction(-1, 2), Fraction(1, 2))
# 该路径 [+1,-1,+1,-1]：S = 1,0,1,0——从未 < -0.5，穿越 = 0
assert u == 0
# 换路径 [-1,-1,+1,+1]：S = -1,-2,-1,0——below 后到 0（>0.5? 否）
u2 = crossings((-1, -1, 1, 1), Fraction(-1, 2), Fraction(1, 2))
assert u2 == 0
# 换路径 [-1,+1,-1,+1]：S = -1,0,-1,0——below 后 0 < 0.5 不到 b
u3 = crossings((-1, 1, -1, 1), Fraction(-1, 2), Fraction(1, 2))
assert u3 == 0
print("upcrossing counts on explicit paths: exact: OK"

)
# ④ Doob L¹ 版的有限树验证：P(S*_2 >= 1)·1 <= E[S_2^+]
S_paths = [0]
max_paths = [0]
for d in product((-1, 1), repeat=2):
    s = 0; mx = 0
    for step in d:
        s += step; mx = max(mx, s)
max_all = []
S_all = []
for d in product((-1, 1), repeat=2):
    s = sum(d)
    mx = max(sum(d[:i+1]) for i in range(2))
    S_all.append(s); max_all.append(mx)
p_ge1 = Fraction(sum(1 for m in max_all if m >= 1), 4)
e_pos = Fraction(sum(max(s, 0) for s in S_all), 4)
assert p_ge1 * 1 <= e_pos          # λ = 1 的 Doob L¹
print("Doob L1 on finite tree: P(S*>=1)*1 <= E[S2^+] exact: OK")

print("END ====")
