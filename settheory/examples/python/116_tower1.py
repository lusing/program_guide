# 第 116 章：荟萃塔 I——与 Julia 独立对拍：club 与荟萃的有限刻画、
# 轮换最小性、塔链搜索、等价类机制与泛型相遇。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = (0, 1, 2)
SUBSETS = tuple(frozenset(i for i in range(3) if (m >> i) & 1) for m in range(8))
FUNS = tuple(product(U, repeat=3))


def feval(f, x):
    return f[x]


def fevalimg(f, A):
    return frozenset(feval(f, a) for a in A)


def club(f):
    return frozenset(A for A in SUBSETS if fevalimg(f, A) <= A)


def gcyc(x):
    return (0, 1, 2)[(x + 1) % 3]


def smn(X):
    return all(set(X) & c for c in CCLUBS.values())


CCLUBS = {f: club(f) for f in FUNS}


def main():
    print("==== 116")

    sizes = {}
    for f in FUNS:
        n = len(club(f))
        sizes[n] = sizes.get(n, 0) + 1
    print("[club] 27 函数 club 大小分布（大小→函数数）: "
          + " ".join(f"{n}→{sizes[n]}" for n in sorted(sizes)))

    gc = (1, 2, 0)
    print(f"[轮换] C_g 大小 = {len(club(gc))}（恰 {{}},{{U}}——最小 club）")

    smn_char = all(smn([A]) == (not A or A == frozenset(U)) for A in SUBSETS)
    print(f"[荟萃刻画] 单成员族 {{{{A}}}} 荟萃 ⟺ A=∅ 或 A=U: {smn_char}")

    X2 = [frozenset(set(U) - {i}) for i in U]
    print(f"[非平凡反例] X₂ = 三点余单点族 荟萃? {smn(X2)}"
          "（轮换 club 与之交空）")

    # 塔序（支撑面）与链搜索
    def supp(X):
        s = set()
        for A in X:
            s |= set(A)
        return frozenset(s)

    def le(X, Y):
        return supp(Y) <= supp(X)

    T1 = [frozenset({0}), frozenset({1}), frozenset(U)]
    T2 = [frozenset({1}), frozenset({2}), frozenset(U)]
    glb2 = [A for A in T1 if A in T2]
    print(f"[塔序] supp 单调 ≤ 自反: {le(T1, T1)}；"
          f"glb（成员交）≤ 两者: {le(glb2, T1) and le(glb2, T2)}（同高同支撑）")

    chain = [list(X2)]
    cur = list(X2)
    while len(cur) > 1:
        cur = [frozenset(U)]
        chain.append(list(cur))
    ok_chain = all(le(chain[i], chain[i + 1]) for i in range(len(chain) - 1))
    print(f"[塔链] X₂ ≤ {{U}}: {le(X2, [frozenset(U)])}；"
          f"贪心链长 {len(chain)} 全程 ≤: {ok_chain}")

    # 等价类机制（~_G）
    G = lambda B: 0 in B  # 主滤子 F₀

    def feq(f, g):
        return G(frozenset(b for b in U if feval(f, b) == feval(g, b)))

    ok_refl = all(feq(f, f) for f in FUNS)
    ok_sym = all(feq(f, g) == feq(g, f) for f in FUNS for g in FUNS)
    ok_trans = all(not (feq(f, g) and feq(g, h) and not feq(f, h))
                   for f in FUNS for g in FUNS for h in FUNS)
    print(f"[~_G] 自反 {ok_refl} 对称 {ok_sym} 传递 {ok_trans}（主滤子 F₀）")

    ok_const = all(
        feq(f, (c, c, c)) == G(frozenset(b for b in U if feval(f, b) == c))
        for f in FUNS for c in U)
    print(f"[常值刻画] feq f c ⟺ 相等集∈G: {ok_const}")

    # 泛型相遇（G_X 的相容性）
    down = lambda B, X: frozenset(set(B) & set(X))
    up = lambda A, Y: frozenset(set(A) | set(Y))
    ok_a = all(down(B, frozenset({0, 1})) <= frozenset({0, 1})
               for B in [frozenset({0}), frozenset(U)])
    ok_b = all(A <= up(A, frozenset(U)) for A in [frozenset({0}), frozenset({1})])
    print(f"[相容] (a) 降落封闭 {ok_a}；(b) 提升复原 {ok_b}")

    assert (smn_char, ok_refl, ok_sym, ok_trans, ok_const, ok_chain) == (
        True, True, True, True, True, True)
    assert not smn(X2) and le(X2, [frozenset(U)])

    print("club 分布/轮换最小/荟萃刻画/反例；塔序+链+glb；~_G 三律+常值；降落提升")
    print("END ====")


if __name__ == "__main__":
    main()
