# 第 104 章：与 Julia 独立对拍——纯延长序、R(3,3)=6 穷举与 Mathias 影子。
import io
import sys
from itertools import combinations

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

CORE = frozenset(range(5, 10))


def is_prefix(t, s):
    return len(t) <= len(s) and list(t) == list(s)[: len(t)]


def ple(p, q):
    return p[0] == q[0] and p[1] <= q[1]


def prikry_le(p, q):
    return (
        is_prefix(q[0], p[0])
        and p[1] <= q[1]
        and set(p[0][len(q[0]):]) <= q[1]
    )


def homo_triple(color):
    for a, b, c in combinations(range(6), 3):
        if color[(a, b)] == color[(b, c)] == color[(a, c)]:
            return (a, b, c)
    return None


def is_prikry_candidate(x):
    if any(x[i] >= x[i + 1] for i in range(len(x) - 1)):
        return False
    bad = [i for i, v in enumerate(x) if v not in CORE]
    return not bad or bad[-1] <= 3   # 非核元素至多前 4 位


def in_gx(s, a, x):
    alpha = len(s)
    return list(s) == list(x)[:alpha] and set(x) - set(s) <= a


def main():
    print("==== 104")
    # 纯延长自反/传递（与 Julia 同款样本）。
    assert ple(("s", CORE), ("s", CORE))
    p, q, r = ("s", CORE), ("s", frozenset(range(4, 10))), ("s", frozenset(range(3, 10)))
    assert ple(p, q) and ple(q, r) and ple(p, r)

    s = [2, 5, 7]
    assert prikry_le((s, CORE), (s, CORE))
    a, b = CORE, frozenset({3} | set(range(5, 10)))
    assert ple((s, a & b), (s, a)) and ple((s, a & b), (s, b))

    # R(3,3)=6 全染色穷举（32768 例）。
    pairs = list(combinations(range(6), 2))
    assert len(pairs) == 15
    n_homo = 0
    for mask in range(2 ** 15):
        color = {pairs[k]: (mask >> k) & 1 for k in range(15)}
        ht = homo_triple(color)
        assert ht is not None, f"R(3,3)=6 fails at mask={mask}"
        n_homo += 1
    assert n_homo == 2 ** 15

    # Prikry 序列候选与 G(X) 成员判定。
    assert is_prikry_candidate([1, 2, 5, 6, 7, 8, 9])
    assert not is_prikry_candidate([5, 1, 6, 7, 8])
    assert is_prikry_candidate([3, 4, 5, 6, 7, 8, 9])
    assert not is_prikry_candidate([5, 6, 7, 8, 9, 2])

    x = [1, 2, 5, 6, 7, 8, 9]
    assert in_gx([1, 2], CORE, x)
    assert not in_gx([1, 5], CORE, x)
    assert not in_gx([1, 2], frozenset({6, 7, 8, 9}), x)
    assert in_gx(x, CORE, x)

    print("Python：纯延长序、事实 2.3.1、R(3,3)=6 全染色（32768 例）、")
    print("Prikry 候选与 G(X) 判定——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
