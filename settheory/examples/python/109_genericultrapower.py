# 第 109 章：与 Julia 独立对拍——理想力迫、泛型超滤子候选与有限 Łoś。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

IDEAL = frozenset({0b000, 0b001})        # I = {∅, {0}}（位掩码）


def pos(m):
    return m not in IDEAL


IPOS = [m for m in range(8) if pos(m)]   # 6 个正测集


def le(C, D):
    return (C & ~D) in IDEAL             # C ≤ D ⟺ C − D ∈ I


def eqv(X, Y):
    return (X ^ Y) in IDEAL              # X ≡ Y ⟺ X△Y ∈ I


def G(a):
    return frozenset(m for m in IPOS if (m & (1 << a)) != 0)


def dense(Ds):
    return all(any(le(Y, X) for Y in Ds) for X in IPOS)


def fval(f, a):
    return f[a]


def truth_lt(f, g):
    return (fval(f, 0) < fval(g, 0)) | ((fval(f, 1) < fval(g, 1)) << 1) | ((fval(f, 2) < fval(g, 2)) << 2)


def truth_eq(f, g):
    return (fval(f, 0) == fval(g, 0)) | ((fval(f, 1) == fval(g, 1)) << 1) | ((fval(f, 2) == fval(g, 2)) << 2)


def main():
    print("==== 109")
    # 序：自反 + 传递全量 + 样本。
    assert le(0b010, 0b011)              # {1} ≤ {0,1}
    assert not le(0b111, 0b011)          # U ≰ {0,1}
    assert all(le(C, C) for C in IPOS)
    for C in IPOS:
        for D in IPOS:
            for E in IPOS:
                if le(C, D) and le(D, E):
                    assert le(C, E)

    # 商关系与商代数。
    assert eqv(0b111, 0b110)             # U ≡ {1,2}
    assert eqv(0b011, 0b010)             # {0,1} ≡ {1}
    classes = set()
    for m in range(8):
        bits12 = m & 0b110
        classes.add(7 if bits12 == 0b110 else bits12)
    assert classes == {0, 2, 4, 7}       # P(U)/I ≅ 4 元布尔代数

    # 泛型超滤子候选与四公理 (a)-(d)。
    assert G(1) == frozenset({0b010, 0b011, 0b110, 0b111})
    assert G(2) == frozenset({0b100, 0b101, 0b110, 0b111})
    for a in (1, 2):
        g = G(a)
        assert 7 in g and 0 not in g                       # (a)
        assert all((C & D) in g for C in g for D in g)     # (b)
        assert all(E in g for C in g for E in IPOS if le(C, E))  # (c)
        assert all((C in g) or ((7 & ~C) in g) for C in IPOS)    # (d)

    # 稠密集全相遇（泛型性）。
    denses = []
    for mask in range(64):
        D = frozenset(IPOS[i] for i in range(6) if (mask >> i) & 1)
        if dense(D):
            denses.append(D)
    assert denses and all(dense(D) for D in denses)
    for a in (1, 2):
        for D in denses:
            assert G(a) & D                # 候选滤子遇遍每个稠密集

    # 有限 Łoś：27×27 函数对 × 双滤子。
    funcs = [(x, y, z) for x in range(3) for y in range(3) for z in range(3)]
    for a in (1, 2):
        for f in funcs:
            for g in funcs:
                assert ((truth_lt(f, g) & (1 << a)) != 0) == (fval(f, a) < fval(g, a))
                assert ((truth_eq(f, g) & (1 << a)) != 0) == (fval(f, a) == fval(g, a))

    # 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点。
    for a in (1, 2):
        assert (1 << a) in G(a)

    # 下降链：严格链至多 2 级（引理 2.30(3) 的有限影子）。
    best = 1
    stack = [(c, 1) for c in IPOS]
    while stack:
        c, n = stack.pop()
        best = max(best, n)
        for d in IPOS:
            if d != c and le(d, c) and not le(c, d):
                stack.append((d, n + 1))
    assert best == 2

    print("Python：序自反/传递全量；商代数 4 元；超滤子四公理；")
    print("稠密集全相遇；有限 Łoś 27×27×2 双滤子；严格下降链至多 2 级——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
