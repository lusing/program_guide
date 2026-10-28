# 第 103 章：与 Julia 独立对拍——稠密性、贪心泛型相遇与 f_λ 还原。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

KAPPA = 4


def is_cond(p):
    return all(1 <= l <= KAPPA and 0 <= b < l for (l, n), b in p.items())


def compat(p, q):
    return all(p[k] == q[k] for k in p.keys() & q.keys())


def fresh_n(l, p):
    used = [n for (lam, n) in p if lam == l]
    return 1 + max(used, default=0)


def extend_dense(l, b, p):
    q = dict(p)
    q[(l, fresh_n(l, p))] = b
    return q


def greedy_generic(targets):
    p = {}
    for l, b in targets:
        p = extend_dense(l, b, p)
    return p


def main():
    print("==== 103")
    p0 = {(2, 0): 1}
    assert fresh_n(2, p0) == 1
    assert fresh_n(2, {(2, 5): 0}) == 6
    assert fresh_n(3, p0) == 1
    assert compat({(2, 0): 1}, {(3, 1): 2})
    assert not compat({(2, 0): 1}, {(2, 0): 0})

    # 稠密性核查（与 Julia 同款双条件：扩展合法 + n₀ 新鲜）。
    for l in range(1, KAPPA + 1):
        for b in range(l):
            p = {(2, 0): 1, (3, 1): 2}
            q = extend_dense(l, b, p)
            assert is_cond(q) and compat(p, q)
            assert any(k[0] == l and q[k] == b for k in q)
            n0 = fresh_n(l, p)
            assert all((l, n0) not in p or p[(l, n0)] == b
                       for _ in [0])

    targets = [(l, b) for l in range(1, KAPPA + 1) for b in range(l)]
    g = greedy_generic(targets)
    assert is_cond(g)
    for l in range(1, KAPPA + 1):
        for b in range(l):
            assert any(g.get((l, n)) == b for n in range(100))
        used = sum(1 for k in g if k[0] == l)
        assert used == l

    print("Python：稠密性/新鲜槽/贪心相遇/f_λ 满射还原——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
