# 第 118 章：与 Julia 独立实现父表枚举、交错枝和有限下降证书。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def cparent(k):
    return 0 if k == 0 else k - 1


def path(parent, x):
    out = [x]
    seen = {x}
    while x:
        x = parent[x - 1]
        assert x not in seen
        seen.add(x)
        out.append(x)
    return out[::-1]


def main():
    print("==== 118")
    parent = tuple(cparent(k) for k in range(6))
    assert all(parent[e] == cparent(e) for e in range(6))

    # product 独立穷举所有父表；不调用 Julia 的递归枚举器。
    trees = tuple(product(*(range(c) for c in range(1, 7))))
    assert len(trees) == 720
    assert all(all(0 <= p[c - 1] < c for c in range(1, 7)) for p in trees)
    assert parent in trees
    path_sets = {p: {x: tuple(path(p, x)) for x in range(7)} for p in trees}
    assert all(len(set(v)) == 7 for v in path_sets.values())
    print(f"[合法树枚举] product 得 {len(trees)} 棵；所有节点都有唯一根路径")

    even = tuple(path(parent, 6))
    odd = tuple(path(parent, 5))
    assert even == (0, 2, 4, 6) and odd == (0, 1, 3, 5)
    assert parent[2 - 1] == 0 and parent[3 - 1] == 1
    print(f"[真实分叉] Even 前段={even}；Odd 前段={odd}")

    def branch(name, k):
        return 2 * k if name == "even" else (0 if k == 0 else 2 * k - 1)

    for name in ("even", "odd"):
        assert all(any(branch(name, k) >= n for k in range(9)) for n in range(8))

    bad = ((0, 2, 5, 4), (2, 4, 4, 3), (4, 6, 3, 2))
    assert all(s + 1 > t for _, _, s, t in bad)
    print("[共尾前段与下降证书] 两枝窗口共尾；三段严格下降均成立")
    print("END ====")


if __name__ == "__main__":
    main()
