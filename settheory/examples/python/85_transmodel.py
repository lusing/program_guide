# 第 85 章 · 传递模型（冯琦第二卷 §1.2）。
# 例 1.7：不传递的载体可以让两个不同集合在内部看起来元素相同。
# 定理 1.22：把「后继见证」不断收进子载体，闭包回到整段序数，初等性恢复。
# 引理 1.20：单条存在公式 ∃y (y = {x}) 的秩最小见证在有限步里落进某一层 V_n。


def transitive(m):
    return all(y in m for x in m for y in x)


def same_inside(m, a, b):
    return {z for z in m if z in a} == {z for z in m if z in b}


def extensional(m):
    return all(same_inside(m, a, b) == (a == b) for a in m for b in m)


def successor_witness(x, z, universe):
    """∃y (x ∈ y ∈ z 且 y 没有严格介于 x 与 y 之间的元素)。序数上 y = x+1。"""
    for y in universe:
        if x < y < z and all(not (x < w < y) for w in universe):
            return y
    return None


def skolem_hull(seed, universe):
    hull = set(seed)
    changed = True
    while changed:
        changed = False
        for x in list(hull):
            for z in list(hull):
                y = successor_witness(x, z, universe)
                if y is not None and y not in hull:
                    hull.add(y)
                    changed = True
    return hull


def reflects_successor(carrier):
    universe = set(range(max(carrier) + 1)) if carrier else set()
    for x in carrier:
        for z in carrier:
            y = successor_witness(x, z, universe)
            if y is None:
                continue
            if successor_witness(x, z, carrier) is None:
                return False
    return True


def vee(n):
    import itertools
    levels = [set()]
    for _ in range(n):
        prev = sorted(levels[-1], key=repr)
        levels.append({frozenset(c) for r in range(len(prev) + 1)
                       for c in itertools.combinations(prev, r)})
    return levels


def rank(x):
    return 0 if not x else 1 + max(rank(y) for y in x)


def main():
    print("==== 85")
    zero = frozenset()
    a = frozenset([zero])                  # {∅}
    b = frozenset([frozenset([a])])         # {{{∅}}}
    gap = {a, b}
    print("不传递的 {a,b} 外延：", extensional(gap), "传递：", transitive(gap))
    assert not transitive(gap) and not extensional(gap)

    v4 = vee(4)[4]
    print("V_4 外延：", extensional(v4), "传递：", transitive(v4), "元素个数：", len(v4))
    assert extensional(v4) and transitive(v4)

    universe = set(range(6))
    thin = {0, 2, 4, 5}
    print("薄子集 {0,2,4,5} 对后继见证封闭：", reflects_successor(thin))
    assert not reflects_successor(thin)
    hull = skolem_hull({0, 5}, universe)
    print("斯科伦闭包 SH({0,5}) =", sorted(hull))
    assert hull == universe
    assert reflects_successor(hull)

    levels = vee(4)
    v2 = levels[2]
    witnesses = {frozenset([x]) for x in v2}
    witness_ranks = {rank(y) for y in witnesses}
    assert witness_ranks <= {1, 2}
    assert all(y in levels[3] for y in witnesses)
    print("V_2 上单元集见证的秩：", sorted(witness_ranks))
    print("这些见证全部落在 V_3：单公式镜像在第三层关闭")
    print("END ====")


if __name__ == "__main__":
    main()
