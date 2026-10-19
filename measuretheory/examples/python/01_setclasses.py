import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 01 setclasses")

# 第 01 章：集类封闭性枚举（与 Julia 对拍：用 frozenset 而非位掩码）。

UNIV = frozenset(range(1, 7))

# 区间半环 (a, b]（1-based 元素）
def interval(a, b):
    return frozenset(range(a + 1, b + 1))

intervals = [frozenset()]
a_ = 0
while a_ < 6:
    for b in range(a_ + 1, 7):
        intervals.append(interval(a_, b))
    a_ += 1
intervals = list(dict.fromkeys(intervals))

inC = lambda s: s in intervals

# π-系
assert all(inC(s & t) for s in intervals for t in intervals), "区间族对交封闭"
print(f"区间族对交封闭（π-系）: OK，共 {len(intervals)} 个成员")

# 半环：差 ≤ 2 片不交区间
def diff_decomposes(s, t):
    d = s - t
    if not d:
        return True
    for u in intervals:
        for v in intervals:
            if u.isdisjoint(v) and u | v == d:
                return True
    return False

assert all(diff_decomposes(s, t) for s in intervals if s for t in intervals), "半环条件"
print("半环条件（差 ≤ 2 片不交区间）: OK")

# 不是环
s = interval(0, 2)
t = interval(3, 5)
assert not inC(s | t), "{1,2} ∪ {4,5} 不是区间"
print("反例：{1,2} ∪ {4,5} ∉ C —— 区间半环不是环")

# 不交并闭包迭代
def closure_disjoint_union(C):
    S = set(C)
    frontier = True
    rounds = 0
    while frontier:
        frontier = False
        rounds += 1
        for u in list(S):
            for v in list(S):
                if u.isdisjoint(v) and (u | v) not in S:
                    S.add(u | v)
                    frontier = True
    return S, rounds

S1, rounds1 = closure_disjoint_union(intervals)
print(f"不交并闭包：{len(intervals)} → {len(S1)}，{rounds1} 轮到不动点")
assert len(S1) == 2 ** 6, "应穷尽全部 64 个子集"

# 与一般并闭包对照（一致性）
def closure_union(C):
    S = set(C)
    frontier = True
    while frontier:
        frontier = False
        for u in list(S):
            for v in list(S):
                if (u | v) not in S:
                    S.add(u | v)
                    frontier = True
    return S

assert closure_union(intervals) == S1, "两种闭包一致"
print("∪ 闭包与不交并闭包一致: OK")

print("END ====")
