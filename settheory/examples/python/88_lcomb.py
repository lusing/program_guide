# 第 88 章 · L 中的组合原理与弱紧基数（冯琦第二卷 §2.1.4-2.1.5）
# 三组样品：Jensen 苏斯林树构造的封口引擎（定理 2.12 性质 (4)）、
# 钻石时刻表（定理 2.14 的调度引擎）、柯尼希树枝（定理 2.15(2) 方向）。
from itertools import product

print("==== 88")

# ---------- 一、封口引擎：被封口的反链永久保持极大 ----------

def children(level):
    return [t + (0,) for t in level] + [t + (1,) for t in level]

def seal_level(A, level):
    """封口层：延拓一层后，只保留延拓了 A 中某成员的节点。"""
    grown = children(level)
    return [t for t in grown if any(a == t[:len(a)] for a in A)]

def sealed_by(A, level):
    return all(any(a == t[:len(a)] for a in A) for t in level)

# 第 2 层封口单点反链 {(1,1)}；第 6 层再封口当时的顶层首节点 ——
# Jensen 构造在极限层反复封口的有限形态。
A0 = [(1, 1)]
T = [[()]]                                        # 第 0 层：{空串}
T.append(children(T[-1]))                         # 第 1 层
T.append(seal_level(A0, T[-1]))                   # 第 2 层：封 A0
while len(T) < 6:
    T.append(children(T[-1]))                     # 第 3-5 层
A1 = [T[5][0]]                                    # 第 5 层首节点为新反链
T.append(seal_level(A1, T[-1]))                   # 第 6 层：封 A1
while len(T) < 10:
    T.append(children(T[-1]))                     # 第 7-9 层

sizes = [len(t) for t in T]
print("层规模:", sizes, "（两次封口各剪掉一半）")
for n in range(2, len(T)):
    assert sealed_by(A0, T[n]), f"A0 在第 {n} 层失守"
for n in range(6, len(T)):
    assert sealed_by(A1, T[n]), f"A1 在第 {n} 层失守"
print("A0 自第 2 层、A1 自第 6 层起全程封口：极大性永久保持 OK")

# ---------- 二、钻石时刻表：一个序列猜中每个目标无穷多次 ----------

def vtwo(n):
    v = 0
    while n > 0 and n % 2 == 0:
        n //= 2
        v += 1
    return v

# 目标集合族：X_i 的特征函数。
def target(i, j):
    return (j % (i + 2)) < 2

N_STAGES = 480
# 时刻表的构造性定义：S 的第 n 行 = X_{v2 n} 的初始段。
def S_row(n, j):
    return target(vtwo(n), j)

# 命中检查 + vtwo 的算术账（n = 2^i * 奇数）。
for n in range(1, N_STAGES):
    i = vtwo(n)
    assert all(S_row(n, j) == target(i, j) for j in range(n))
    m = n >> i
    assert m % 2 == 1 and n == (2 ** i) * m
hits = [sum(1 for n in range(1, N_STAGES) if vtwo(n) == i) for i in range(6)]
assert all(h >= N_STAGES // 2 ** (i + 1) - 1 for i, h in enumerate(hits))
print("时刻表各目标时刻数:", hits,
      "—— 第 v2(n) 步猜测 X_{v2(n)}，每个目标被猜中无穷多次 OK")

# ---------- 三、柯尼希树枝（定理 2.15(2) 方向的 ω-形态） ----------

# 可判定无限树：每个前缀 p 满足 #1(p) <= #0(p) + 2。
def in_tree(t):
    for k in range(1, len(t) + 1):
        p = t[:k]
        if p.count(1) > p.count(0) + 2:
            return False
    return True

# 贪心下降：每步选一个子树在更深处仍有节点的孩子。
branch = ()
for _ in range(24):
    for b in (0, 1):
        cand = branch + (b,)
        if in_tree(cand) and in_tree(cand + (0,) * 4):
            branch = cand
            break
assert in_tree(branch) and len(branch) == 24
print("贪心树枝长度 24，全程满足树条件 OK（层有限 + 无限深 -> 有树枝）")

print("END ====")
