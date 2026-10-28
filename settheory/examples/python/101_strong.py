# 第 101 章：与 Julia 独立对拍——递归秩层、强度矩阵与条款穷举。
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = tuple(range(16))


def elems(x):
    return frozenset(i for i in range(4) if (x >> i) & 1)


def level(n):
    if n == 0:
        return ()
    cur = set(level(n - 1))
    return tuple(x for x in U if elems(x) <= cur)


def main():
    print("==== 101")
    assert level(1) == (0,)
    assert level(2) == (0, 1)
    assert level(3) == (0, 1, 2, 3)
    assert level(4) == U
    assert [len(level(n)) for n in (1, 2, 3, 4)] == [1, 2, 4, 16]
    for n in range(4):
        assert set(level(n)) <= set(level(n + 1))

    # 见证条款（frozenset 对拍 Julia 的 Set）。
    def lam_strong(crit, jk, cap, l):
        return crit <= l and l < jk and l in cap

    def superstrong(jk, cap):
        return jk in cap

    witnesses = [
        (2, 3, frozenset({2})),
        (2, 5, frozenset({3})),
        (2, 5, frozenset({2, 3, 4})),
        (2, 6, frozenset({2, 3, 4, 5})),
        (2, 4, frozenset({4})),
    ]
    # 矩阵对拍：每行恰在与 Julia 相同的列点亮。
    expected = [
        [True, False, False, False, False],
        [False, True, False, False, False],
        [True, True, True, False, False],
        [True, True, True, True, False],
        [False, False, False, False, False],
    ]
    for (crit, jk, cap), row in zip(witnesses, expected):
        got = [lam_strong(crit, jk, cap, l) for l in range(2, 7)]
        assert got == row, (crit, jk, sorted(cap), got)
    assert superstrong(4, frozenset({4}))
    assert not any(superstrong(w[1], w[2]) for w in witnesses[:4])

    # 有限捕获恒非强（鸽笼）。
    for crit, jk, cap in witnesses:
        L = crit + max(cap) + 1
        assert not lam_strong(crit, jk, cap, L)
        assert not all(lam_strong(crit, jk, cap, l)
                       for l in range(crit, L + 1))
    # 边界账：超强见证在 λ=j(κ) 处非 λ-强（j(κ)>λ 是严格不等式）。
    assert not lam_strong(2, 4, frozenset({4}), 4)
    # 可测类似物：(κ,κ+1)-强 ⟺ 捕获第 κ 层且 j(κ)>κ。
    assert lam_strong(2, 3, frozenset({2}), 2)
    assert not lam_strong(2, 3, frozenset({2}), 3)

    print("Python：V 层尺寸 1,2,4,16、包含链、矩阵逐格对拍一致、")
    print("鸽笼断言、j(κ)>λ 边界与可测类似物——与 Julia 独立对拍通过")
    print("END ====")


if __name__ == "__main__":
    main()
