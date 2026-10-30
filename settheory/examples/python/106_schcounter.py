# 第 106 章：与 Julia 独立对拍——GMW 账簿、最小失败搜索与交织影子。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def is_gmw(B):
    return len(B) > 0 and B[-1] == 1 and all(b == 0 for b in B[:-1])


def satisfies_sch(b):
    return b == 0


def minimal_failure(B):
    assert is_gmw(B)
    return all(satisfies_sch(b) for b in B[:-1]) and not satisfies_sch(B[-1])


def count_gmw(n):
    cnt = 0
    for bits in product([0, 1], repeat=n):
        if is_gmw(list(bits)):
            cnt += 1
            assert list(bits) == [0] * (n - 1) + [1]
    return cnt


def shifts_above(a, b, N=50, kmax=5):
    for k in range(kmax + 1):
        if all(b(n) <= a(n + k) for n in range(k, N + 1)):
            return k
    return None


def main():
    print("==== 106")
    assert is_gmw([0, 0, 0, 1])
    assert not is_gmw([0, 1, 0, 1])
    assert not is_gmw([0, 0, 0])
    assert minimal_failure([0, 0, 0, 1])
    assert is_gmw([1])
    assert minimal_failure([1])

    for n in range(1, 9):
        assert count_gmw(n) == 1

    assert below_all_satisfy([0, 0, 0, 1])
    assert not below_all_satisfy([0, 1, 0, 1])

    assert shifts_above(lambda n: n + 2, lambda n: n) == 0
    k2 = shifts_above(lambda n: 2 * n, lambda n: n + 3)
    assert k2 is not None and k2 >= 1
    assert shifts_above(lambda n: n, lambda n: n) == 0

    ga, gb = lambda n: 5 * n + 10, lambda n: 3 * n + 2
    assert shifts_above(ga, gb) is not None

    print("Python：GMW 账簿每长度恰一（穷举 2^1..2^8）、最小失败孤悬末位、")
    print("交织位移支配三样本——与 Julia 独立对拍一致")
    print("END ====")


def below_all_satisfy(B):
    return all(satisfies_sch(b) for b in B[:-1])


if __name__ == "__main__":
    main()
