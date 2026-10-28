# 第 94 章：有限超滤递归穷举与主超幂求值（独立于 Julia）。
from itertools import product
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def subsets(n):
    return [frozenset(i for i in range(n) if mask & (1 << i))
            for mask in range(1 << n)]


def is_ultrafilter(family, ss):
    family = set(family)
    if frozenset() in family or ss[-1] not in family:
        return False
    if any(a & b not in family for a in family for b in family):
        return False
    if any(a <= b and b not in family for a in family for b in ss):
        return False
    return all(a in family or ss[-1] - a in family for a in ss)


def ultrafilters(n):
    ss = subsets(n)
    answer = []

    def visit(i, chosen):
        if i == len(ss):
            if is_ultrafilter(chosen, ss):
                answer.append(tuple(chosen))
            return
        visit(i + 1, chosen)
        visit(i + 1, chosen + [ss[i]])

    visit(0, [])
    return answer


def main():
    print("==== 94")
    for n in (2, 3):
        ufs = ultrafilters(n)
        assert len(ufs) == n
        for a in range(n):
            principal = tuple(s for s in subsets(n) if a in s)
            assert sum(set(principal) == set(u) for u in ufs) == 1
    functions = list(product((0, 1), repeat=3))
    focus = 1
    classes = {v: [f for f in functions if f[focus] == v] for v in (0, 1)}
    assert [len(classes[v]) for v in (0, 1)] == [4, 4]
    assert all(tuple([f[focus]] * 3) in classes[f[focus]] for f in functions)
    assert sorted(classes[0] + classes[1]) == sorted(functions)
    print("Python 递归穷举：有限超滤族恰为各点主超滤；n=2,3 对账 ✓")
    print("主超幂商等价于焦点求值：两个等价类，各 4 个布尔函数")
    print("END ====")


if __name__ == "__main__":
    main()
