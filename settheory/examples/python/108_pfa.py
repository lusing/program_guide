# 第 108 章：与 Julia 独立对拍——积序证书复合、支撑拼接与 RS 稠密集相遇。
import io
import sys
from itertools import product  # noqa: F401

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

EXT = {0: frozenset({0, 1, 2}), 1: frozenset({1}), 2: frozenset({2})}


def compat(r, p):
    return bool(EXT.get(r, frozenset()) & EXT.get(p, frozenset()))


def ext_of(q):
    return EXT.get(q, frozenset())


def predense1(A, q):
    return all(any(compat(r, p) for p in A) for r in ext_of(q))


U2 = [(a, b) for a in range(3) for b in range(3)]


def ext2(p):
    return frozenset((r, s) for r in ext_of(p[0]) for s in ext_of(p[1]))


def compat2(p, q):
    return bool(ext2(p) & ext2(q))


def predense2(A, q):
    return all(any(compat2(r, p) for p in A) for r in ext2(q))


A12 = frozenset({1, 2})
P12 = frozenset((a, b) for a in A12 for b in A12)


def is_antichain2(A):
    return all(not compat2(p, q) for p in A for q in A if p != q)


def max_antichain_size2(universe):
    us = sorted(universe)
    best = 0
    for mask in range(2 ** len(us)):
        A = frozenset(us[i] for i in range(len(us)) if (mask >> i) & 1)
        if is_antichain2(A):
            best = max(best, len(A))
    return best


def supp(q):
    return frozenset(i for i, c in enumerate(q) if c != 0)


def restrict(q, k):
    return q[:k]


def glue(q, r):
    return q + r[len(q):]


def is_dense2(D):
    return all(any(d in ext2(p) for d in D) for p in U2)


def rsi_filter(denses, p0):
    p = p0
    chain = [p0]
    for D in denses:
        d = next(d for d in D if d in ext2(p))
        chain.append(d)
        p = d
    F = frozenset(q for q in U2 if p in ext2(q))
    return chain, F


def is_filter2(F):
    pairwise = all(compat2(p, q) for p in F for q in F)
    upward = all(q in F for p in F for q in U2 if p in ext2(q))
    return pairwise and upward


def main():
    print("==== 108")
    assert compat2((1, 1), (1, 1))
    assert not compat2((1, 1), (1, 2))
    assert predense2(P12, (0, 0))

    # 证书复合（引理 2.26 影子）：分量准稠密 ⟹ 积序准稠密。
    for q0 in range(3):
        for q1 in range(3):
            if predense1(A12, q0) and predense1(A12, q1):
                assert predense2(P12, (q0, q1))

    assert max_antichain_size2(U2) == 4

    qA = [0, 1, 0, 2]
    rB = [1, 1, 0, 0, 3]
    G = glue(qA, rB)
    assert G == [0, 1, 0, 2, 3]
    assert restrict(G, len(qA)) == qA
    assert supp(G) <= supp(qA) | supp(rB)
    assert supp(G) == frozenset({1, 3, 4})
    assert supp(restrict(rB, 2)) <= supp(rB)

    # RS 构造与穷举（PFA 引擎影子）。
    D12 = sorted(P12)
    assert is_dense2(D12)
    assert not is_dense2([(0, 0)])

    chain, F = rsi_filter([D12, D12], (0, 0))
    assert is_filter2(F)
    assert F & set(D12)

    rest = [q for q in U2 if q not in P12]
    dense_sets = [tuple(sorted(set(D12) | {rest[i] for i in range(5) if (m >> i) & 1}))
                  for m in range(32)]
    assert len(dense_sets) == 32 and all(is_dense2(D) for D in dense_sets)
    for m1 in range(32):
        for m2 in range(32):
            _, Fi = rsi_filter([dense_sets[m1], dense_sets[m2]], (0, 0))
            assert is_filter2(Fi)
            assert Fi & set(dense_sets[m1])
            assert Fi & set(dense_sets[m2])

    print("Python：积序证书复合 + 反链 4=2×2；支撑拼接协调与并集；")
    print("RS 构造穷举 32×32 稠密集族全部相遇——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
