# 第 67 章：传递集合与形式理论（冯琦 引言+§1.1-1.2）
# Hilbert 推导检查器 + 罗素定理有限剧场（万有集不存在）+ 同一律。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import combinations

print("==== 67")

# ---------- 一、Hilbert 推导检查器（定义 1.22 + 1.23） ----------
# fml 的元组表示：("var", n) / ("imp", p, q) / ("neg", p)

def is_axc(f):
    """公理 (c)：P → (Q → P)——内层后件须等于外层前件"""
    return (isinstance(f, tuple) and f[0] == "imp"
            and isinstance(f[2], tuple) and f[2][0] == "imp"
            and f[1] == f[2][2])

def is_axa(f):
    """公理 (a)：((P→(Q→R)) → ((P→Q) → (P→R)))"""
    def imp(t):
        return isinstance(t, tuple) and t[0] == "imp"
    if not imp(f):
        return False
    lhs, rhs = f[1], f[2]
    if not (imp(lhs) and imp(lhs[2]) and imp(rhs) and imp(rhs[1]) and imp(rhs[2])):
        return False
    P, Q, R = lhs[1], lhs[2][1], lhs[2][2]
    return (P == rhs[1][1] and P == rhs[2][1]
            and Q == rhs[1][2] and R == rhs[2][2])

def check(steps):
    """每步是公理实例，或 mp(i, j)：第 i 步 X→Y、第 j 步 X，本步 Y"""
    proven = []
    for f, just in steps:
        if just == "axA":
            ok = is_axa(f)
        elif just == "axC":
            ok = is_axc(f)
        else:
            i, j = just
            x2y, x = proven[i], proven[j]
            ok = (isinstance(x2y, tuple) and x2y[0] == "imp"
                  and x2y[1] == x and f == x2y[2])
        if not ok:
            return False
        proven.append(f)
    return True

# ---------- 67.6 的五步链 ----------
P = ("var", 0)
chain = [
    (("imp", P, ("imp", ("imp", P, P), P)), "axC"),
    (("imp", ("imp", P, ("imp", ("imp", P, P), P)),
          ("imp", ("imp", P, ("imp", P, P)), ("imp", P, P))), "axA"),
    (("imp", ("imp", P, ("imp", P, P)), ("imp", P, P)), (1, 0)),
    (("imp", P, ("imp", P, P)), "axC"),
    (("imp", P, P), (2, 3)),
]
labels = ["1: P→((P→P)→P)        [公理 c]",
          "2: (1)→((P→(P→P))→(P→P))  [公理 a]",
          "3: (P→(P→P))→(P→P)    [MP 1,2]",
          "4: P→(P→P)            [公理 c]",
          "5: P→P                [MP 4,3]"]
for lab in labels:
    print("  " + lab)
print("五步链验证:", check(chain))

bad = chain[:4] + [(("imp", P, P), (3, 2))]
print("篡改链（MP 实参交换）被拒绝:", not check(bad))
bad2 = chain[:4] + [(("imp", P, P), "axC")]
print("伪装公理步被拒绝:", not check(bad2))

# ---------- 二、罗素定理有限剧场（例 1.4：没有万有集合） ----------
# 对每个有限集合 x，罗素类 R(x) = {a ∈ x | a ∉ a} 都不在 x 内。
def powerset(s):
    return [frozenset(c) for r in range(len(s) + 1)
            for c in combinations(s, r)]

U = powerset({1, 2, 3})
for x in U:
    R = frozenset(a for a in x if a not in a)
    assert R not in x
print(f"对 {len(U)} 个有限集合逐一检验：罗素类从不在集合内 —— 没有万有集合的有限影子")

# ---------- 三、同一律（命题 1.1） ----------
import random
random.seed(67)
for _ in range(200):
    A = set(random.sample(range(10), 3))
    B = set(random.sample(range(10), 3))
    assert (A == B) == (A <= B and B <= A)
print("随机集合 200 次：A==B ⟺ A⊆B ∧ B⊆A ✓")

print("END ====")
