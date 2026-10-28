# 第 96 章：与 Julia 独立对拍——整数规划式精确覆盖数与 BFS 闭包。
from itertools import combinations
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = list(range(6))
ALLSETS = [frozenset(i for i in U if (mask >> i) & 1) for mask in range(64)]


def min_cover(X, family):
    if not X:
        return 0
    members = [Y for Y in family if Y]
    if not X <= frozenset().union(*members):
        return float("inf")
    for k in range(1, len(members) + 1):
        for combo in combinations(members, k):
            if X <= frozenset().union(*combo):
                return k
    return float("inf")


def directed_closure(seed):
    frontier = set(seed)
    seen = set(frontier)
    while frontier:
        new = set()
        cur = list(seen)
        for Y in cur:
            for Z in cur:
                u = Y | Z
                if u not in seen:
                    new.add(u)
        seen |= new
        frontier = new
    return seen


def main():
    print("==== 96")
    for b in (1, 2, 3):
        Fb = [S for S in ALLSETS if len(S) <= b]
        for X in ALLSETS:
            want = 0 if not X else -(-len(X) // b)
            assert min_cover(X, Fb) == want, (b, X)
    Fno0 = [S for S in ALLSETS if 0 not in S]
    assert min_cover(frozenset({0, 1}), Fno0) == float("inf")
    assert min_cover(frozenset({0}), Fno0) == float("inf")
    assert min_cover(frozenset({1, 2}), Fno0) == 1
    cl = directed_closure([frozenset()] + [frozenset({i}) for i in U])
    assert len(cl) == 64 and frozenset({0, 3, 5}) in cl
    cl0 = directed_closure([frozenset()] + [frozenset({i}) for i in range(1, 6)])
    assert len(cl0) == 32
    assert all(0 not in Y for Y in cl0)
    print("Python：精确覆盖数与 Julia 公式一致；0 不可覆盖复现；")
    print("BFS 定向闭包 = 全幂集（64），缺 0 单点的闭包恒缺 0（32）")
    print("END ====")


if __name__ == "__main__":
    main()
