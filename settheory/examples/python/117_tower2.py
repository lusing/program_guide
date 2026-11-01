# 第 117 章：荟萃塔 II——与 Julia 独立对拍有限投影表示、两种树表示、
# 见证提升与临界点小模型表；不把三层穷举冒充无限定理。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = (0, 1, 2)
FUNS = tuple(product(U, repeat=3))


def proj(k, x):
    if k == 0:
        return 0
    if k == 1 and x == 2:
        return 1
    return x


def evaluate(f, x):
    return f[x] if isinstance(f, tuple) else f(x)


def lift(k, f):
    return lambda x: evaluate(f, proj(k, x))


def rep(k, f):
    return evaluate(f, k)


def word(A):
    return tuple(int(x in A) for x in U)


def prefix_tree(A):
    w = word(A)
    return tuple(w[:n] for n in range(4))


def branch_table(A):
    return tuple(enumerate(word(A)))


def from_prefix(T):
    return frozenset(x for x in U if T[x + 1][x] == 1)


def from_branch(B):
    return frozenset(x for x, bit in B if bit == 1)


def main():
    print("==== 117")
    pairs = ((0, 1), (0, 2), (1, 2))
    reps_ok = all(rep(l, lift(k, f)) == f[k]
                  for k, l in pairs for f in FUNS)
    comp_ok = all(lift(l, lift(k, f))(x) == lift(k, f)(x)
                  for k, l in pairs for f in FUNS for x in U)
    restrict_ok = all(lift(1, f)(x) == f[x] for f in FUNS for x in (0, 1))
    print(f"[投影表示] 27 函数×3 层对: 代表值保持 {reps_ok}；"
          f"复合兼容 {comp_ok}；低支撑复原 {restrict_ok}")

    subsets = tuple(frozenset(x for x in U if (m >> x) & 1) for m in range(8))
    trees_ok = all(from_prefix(prefix_tree(A)) == A
                   and from_branch(branch_table(A)) == A
                   and from_prefix(prefix_tree(A)) == from_branch(branch_table(A))
                   for A in subsets)
    trees_injective = (len({prefix_tree(A) for A in subsets}) == 8
                       and len({branch_table(A) for A in subsets}) == 8)
    print(f"[两树表示] 8 个子集: 前缀树/分支表复原一致 {trees_ok}；"
          f"表示各自单射 {trees_injective}")

    def jfin(x):
        return x if x < 1 else x + 1

    crit_table = [(x, jfin(x)) for x in U]
    crit_ok = jfin(0) == 0 and jfin(1) == 2 and jfin(1) != 1
    print(f"[临界点表] {crit_table}；固定下方并移动临界点 {crit_ok}")
    f = lambda x: (2, 0, 1)[x]
    print(f"[见证提升] f=(2,0,1), 0→2 层代表值: "
          f"{rep(0, f) == 2}→{rep(2, lift(0, f))}")

    assert reps_ok and comp_ok and restrict_ok
    assert trees_ok and trees_injective and crit_ok
    print("三级投影表示/复合；前缀树↔分支表；临界点表与见证提升")
    print("END ====")


if __name__ == "__main__":
    main()
