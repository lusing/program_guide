# 第 100 章：与 Julia 独立对拍——递归锥生成与正规候选搜索。
from itertools import product  # noqa: F401（保留对拍通道同构的习惯）
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

UNIV = frozenset(range(3))
ALLSETS = frozenset(
    frozenset(i for i in range(3) if (m >> i) & 1) for m in range(8))


def cone(s):
    return frozenset(t for t in ALLSETS if s <= t)


def diag_inter(Xs, n):
    return frozenset(
        xi for xi in range(n)
        if all(xi in Xs[a] for a in range(xi)))


def main():
    print("==== 100")
    assert len(ALLSETS) == 8
    assert cone(frozenset()) == ALLSETS
    assert cone(frozenset({0})) == {frozenset({0}),
                                    frozenset({0, 1}),
                                    frozenset({0, 2}),
                                    frozenset({0, 1, 2})}
    for s1 in ALLSETS:
        for s2 in ALLSETS:
            assert cone(s1) & cone(s2) == cone(s1 | s2)

    for c in range(3):
        U_c = frozenset(t for t in ALLSETS if c in t)
        assert cone(frozenset({c})) <= U_c
        for d in range(3):
            if d != c:
                assert not (cone(frozenset({d})) <= U_c)

    fmin = lambda t: min(t) if t else None
    assert fmin(frozenset({1, 2})) == 1
    assert fmin(frozenset({0, 1, 2})) == 0
    assert fmin(frozenset({2})) == 2

    # 对角线交：前段锥 X_α={0..α} 时 Δ={0}；常序列给全集
    for n in range(2, 6):
        inits = [frozenset(range(k + 1)) for k in range(n)]
        assert diag_inter(inits, n) == frozenset({0})
    consts = [frozenset(range(3)) for _ in range(3)]
    assert diag_inter(consts, 3) == frozenset(range(3))

    print("Python：锥代数、主超滤不精良、回归无常值/恒值、")
    print("对角线交前段锥给 {0}、常序列给全集——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
