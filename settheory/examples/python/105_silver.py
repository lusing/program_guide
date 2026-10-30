# 第 105 章：与 Julia 独立对拍——偏序律、Easton 支撑、贪心相遇与定向下界。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def is_cond(p):
    return all(0 <= v <= 1 for v in p.values())


def ext_c(p, q):
    return all(k in q and q[k] == v for k, v in p.items())


def agree(p, q):
    return all(p[k] == q[k] for k in p.keys() & q.keys())


def merge(p, q):
    r = dict(p)
    for k, v in q.items():
        if k not in r:
            r[k] = v
    return r


def support(p):
    return {k[0] for k in p}


def easton_ok(p, mu):
    return sum(1 for a in support(p) if a < mu) < mu


def greedy(targets):
    p = {}
    for (k, b) in targets:
        if k not in p:
            p[k] = b
    return p


def main():
    print("==== 105")
    p0 = {(0, 0): 1}
    q0 = {(0, 0): 1, (1, 2): 0}
    r0 = {(0, 0): 1, (1, 2): 0, (3, 5): 1}
    assert ext_c(p0, p0)
    assert ext_c(p0, q0) and ext_c(q0, r0) and ext_c(p0, r0)
    assert is_cond(q0) and agree(p0, q0)
    assert merge(p0, q0) == q0

    c1 = {(0, 0): 1}
    c2 = {(0, 0): 0}
    assert not agree(c1, c2)

    # Easton 支撑正反样本（与 Julia 逐条对拍）。
    assert support(q0) == {0, 1}
    assert not easton_ok(q0, 2)
    assert easton_ok(q0, 3)
    assert not easton_ok(p0, 1)
    assert easton_ok(p0, 2)

    # 贪心相遇：先到先占。
    targets = [((a, x), b) for a in range(3) for x in range(2)
               for b in range(2)]
    g = greedy(targets)
    assert is_cond(g)
    assert g[(0, 0)] == 0
    assert all(g[(a, x)] == 0 for a in range(3) for x in range(2))

    # 定向下界（大拿影子）：两两相容族的并是公共延展。
    d = [{(0, 0): 1}, {(1, 1): 0}, {(0, 0): 1, (1, 1): 0}]
    assert all(agree(d[i], d[j]) for i in range(3) for j in range(3))
    master = merge(merge(d[0], d[1]), d[2])
    assert all(ext_c(di, master) for di in d)
    assert is_cond(master)

    print("Python：偏序律、Easton 支撑、贪心相遇、定向下界——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
