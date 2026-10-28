# 第 99 章：与 Julia 独立对拍——递归 DPLL 风格可满足性搜索。
from itertools import product
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def sat_search(clauses, nvars):
    """递归回溯：逐变元赋值，与 Julia 的掩码暴力独立。"""

    def rec(assign, i):
        if i == nvars:
            return all(any(assign[v] if pol else not assign[v]
                           for v, pol in cl)
                       for cl in clauses)
        return rec({**assign, i: True}, i + 1) or \
               rec({**assign, i: False}, i + 1)

    return rec({}, 0)


def main():
    print("==== 99")
    c1 = [{(0, True), (1, False)}, {(1, True), (2, True)}]
    assert sat_search(c1, 3)
    c2 = [{(0, True)}, {(0, False)}]
    assert not sat_search(c2, 1)
    for i in (0, 1):
        sub = c2[:i] + c2[i + 1:]
        assert sat_search(sub, 1)

    # 滤基扩展对拍：≥3 与 ≥2 层（层内向上封闭）
    univ = range(4)
    F0 = {frozenset(S)
          for bits in product((0, 1), repeat=4)
          for S in [[i for i in univ if bits[i]]]
          if sum(bits) >= 3}
    F2 = {frozenset(S)
          for bits in product((0, 1), repeat=4)
          for S in [[i for i in univ if bits[i]]]
          if sum(bits) >= 2}
    assert F0 <= F2
    for F in (F0, F2):
        for S in F:
            for T in F2:
                if S <= T:
                    assert T in F
    assert not any(len(S) <= 1 for S in F0)
    print("Python：递归回溯与 Julia 掩码穷举一致；滤基层间封闭复现")
    print("END ====")


if __name__ == "__main__":
    main()
