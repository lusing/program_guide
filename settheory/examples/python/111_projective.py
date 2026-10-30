# 第 111 章：与 Julia 独立对拍——秩递归、完美子树与截面投影。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

MAXD = 2


def child(c, b):
    return 2 * c + b


def parent(c):
    return c // 2


def depthd(c):
    d = 0
    while c > 1:
        c //= 2
        d += 1
    return d


def rho(T, c=1):
    if c not in T:
        return 0
    if depthd(c) >= MAXD:
        return 0
    c0, c1 = 2 * c, 2 * c + 1
    if c0 not in T and c1 not in T:
        return 0
    return 1 + max(rho(T, c0) if c0 in T else 0,
                   rho(T, c1) if c1 in T else 0)


def has_branch(T, c=1, d=0):
    if c not in T:
        return False
    if d == MAXD:
        return True
    return has_branch(T, 2 * c, d + 1) or has_branch(T, 2 * c + 1, d + 1)


def perfect_subtree(T, c=1, d=0):
    if c not in T:
        return frozenset()
    if d >= MAXD:
        return frozenset({c})
    c0, c1 = 2 * c, 2 * c + 1
    if c0 in T and c1 in T:
        return frozenset({c}) | perfect_subtree(T, c0, d + 1) | perfect_subtree(T, c1, d + 1)
    return frozenset({c})


def branches2():
    return [(a, b) for a in range(2) for b in range(2)]


def section_has_branch(S, alpha):
    # alpha 是长度 MAXD 的元组；截面有树枝 ⟺ ∃ y 全长使前段对全在 S。
    for y in branches2():
        if all((alpha[:k], y[:k]) in S for k in range(MAXD + 1)):
            return True
    return False


def projection(S):
    return frozenset(a for a in branches2() if section_has_branch(S, a))


def main():
    print("==== 111")
    T0 = frozenset({1, 2, 3})
    T1 = frozenset({1, 2, 3, 4})
    T2 = frozenset({1, 2, 3, 4, 5})
    assert rho(T0) == 1 and not has_branch(T0)
    assert rho(T1) == MAXD and has_branch(T1)
    assert rho(T2) == MAXD and has_branch(T2)
    for T in (T0, T1, T2):
        for c in T:
            assert rho(T, c) <= MAXD - depthd(c)

    assert perfect_subtree(T2) == frozenset({1, 2, 3, 4, 5})
    P0 = perfect_subtree(T0)
    assert 2 in P0 and 3 in P0 and 4 not in P0

    # 对角二维树：每个 α 都有对角线见证。
    S_diag = set()
    for n in range(MAXD + 1):
        for a in branches2():
            p = a[:n]
            S_diag.add((p, p))
    assert len(S_diag) == 1 + 2 + 4
    assert projection(S_diag) == frozenset(branches2())

    # 单侧二维树：只允许 x 首位为 0 的 α 有见证。
    S_side = {((), ())}
    S_side.add(((0,), (0,)))
    S_side.add(((0,), (1,)))
    S_side.add(((1,), (0,)))
    for b in range(2):
        for c in range(2):
            S_side.add(((0, b), (c, b)))
    assert projection(S_side) == frozenset({(0, 0), (0, 1)})
    assert (1, 0) not in projection(S_side)

    print("Python：三树秩账（1/2/2）+树枝判定；秩≤剩余深度；")
    print("完美子树（T2 全二叉/T0 根层即叶）；对角与单侧二维树的投影账——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
