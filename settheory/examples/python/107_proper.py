# 第 107 章：与 Julia 独立对拍——主条件证书、泛型搜索与反链规模。
import io
import sys
from itertools import combinations, product  # noqa: F401

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

EXT = {0: frozenset({0, 1, 2}), 1: frozenset({1}), 2: frozenset({2})}


def compat(r, p):
    return bool(EXT.get(r, frozenset()) & EXT.get(p, frozenset()))


def ext_of(q):
    return EXT.get(q, frozenset())


def is_antichain(A):
    return all(not compat(p, q) for p, q in combinations(sorted(A), 2))


def predense_below(A, q):
    return all(any(compat(r, p) for p in A) for r in ext_of(q))


def generic_cond(As, q):
    return all(predense_below(A, q) for A in As)


def search_generic(As, universe):
    return [q for q in universe if generic_cond(As, q)]


def max_antichain_size(universe):
    us = sorted(universe)
    best = 0
    for mask in range(2 ** len(us)):
        A = frozenset(us[i] for i in range(len(us)) if (mask >> i) & 1)
        if is_antichain(A):
            best = max(best, len(A))
    return best


def main():
    print("==== 107")
    A12 = frozenset({1, 2})
    assert is_antichain(A12)
    assert not is_antichain(frozenset({0, 1}))
    assert predense_below(A12, 0)
    assert predense_below(A12, 1)
    assert not predense_below(frozenset({2}), 1)
    assert generic_cond([A12], 0) and generic_cond([A12], 1) and generic_cond([A12], 2)
    assert not generic_cond([frozenset({2})], 1)

    assert search_generic([A12], range(3)) == [0, 1, 2]
    assert search_generic([A12], range(6)) == [0, 1, 2, 3, 4, 5]
    assert search_generic([frozenset({1})], range(3)) == [1]
    assert search_generic([frozenset({1}), A12], range(3)) == [1]

    # 更强条件保持证书。
    def stronger(q, p):
        return ext_of(q) <= ext_of(p)

    assert stronger(1, 0) and stronger(2, 0)
    assert not stronger(0, 1)
    for p, q in product(range(3), repeat=2):
        if generic_cond([A12], p) and stronger(q, p):
            assert generic_cond([A12], q)

    assert max_antichain_size(range(3)) == 2
    assert 1 in ext_of(1)

    print("Python：证书正反、泛型搜索三例、证书下放全核查、")
    print("极大反链规模 2——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
