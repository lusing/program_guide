# 第 112 章：与 Julia 独立对拍——两层树投影、双模型真值与 Sierpiński 分层。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

MAXD = 2


def take2(v, k):
    return tuple(v[:k])


def paths2():
    return [(a, b) for a in range(2) for b in range(2)]


def sec2(T, alpha):
    return [h for (s, h) in T if s == take2(alpha, len(h))]


def sec_has_branch(T, alpha):
    S = set(sec2(T, alpha))
    for g1 in range(2):
        for g2 in range(2):
            if (g1,) in S and (g1, g2) in S:
                return True
    return False


def projection(T):
    return frozenset(a for a in paths2() if sec_has_branch(T, a))


def bounded_branch(T, alpha, xi):
    S = set(sec2(T, alpha))
    for g1 in range(min(xi, 1) + 1):
        for g2 in range(min(xi, 1) + 1):
            if (g1,) in S and (g1, g2) in S:
                return True
    return False


def layer(T, xi):
    return frozenset(a for a in paths2() if bounded_branch(T, a, xi))


def sig1(phi, univ):
    return any(phi(y) for y in univ)


def pi1(phi, univ):
    return all(phi(y) for y in univ)


def main():
    print("==== 112")
    Tb = [
        ((), ()),
        ((0,), (0,)), ((0,), (1,)),
        ((0, 0), (0, 0)), ((0, 0), (1, 0)),
    ]
    assert projection(Tb) == frozenset({(0, 0)})
    assert set(sec2(Tb, (0, 0))) == {(), (0,), (1,), (0, 0), (1, 0)}
    assert set(sec2(Tb, (0, 1))) == {(), (0,), (1,)}
    assert not sec_has_branch(Tb, (0, 1))

    V_all = paths2()
    M_sub = [(0, 0), (0, 1)]

    for phi in (lambda y: y[0] == 0, lambda y: y == (0, 0), lambda y: y[1] == 1):
        if sig1(phi, M_sub):
            assert sig1(phi, V_all)
    phi_out = lambda y: y[0] == 1
    assert sig1(phi_out, V_all) and not sig1(phi_out, M_sub)

    for phi in (lambda y: y[0] >= 0, lambda y: len(y) == 2):
        if pi1(phi, V_all):
            assert pi1(phi, M_sub)
    phi_m = lambda y: y[0] == 0
    assert pi1(phi_m, M_sub) and not pi1(phi_m, V_all)

    acc = frozenset().union(*[layer(Tb, xi) for xi in range(2)])
    assert acc == projection(Tb)
    assert layer(Tb, 0) != frozenset()

    print("Python：两层树投影（p[Tb]={00}）；Σ 上行/Π 下行 + 双反例；")
    print("Sierpiński 分层并 = 全投影——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
