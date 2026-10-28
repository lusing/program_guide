# 第 102 章：与 Julia 独立对拍——闭包点枚举、容斥总数与失败原因。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

DELTA = 4


def closed(f, k):
    return all(f[i] < k for i in range(k))


def witnesses(f):
    return [k for k in range(1, DELTA) if closed(f, k)]


def main():
    print("==== 102")
    allfs = list(product(range(DELTA), repeat=DELTA))
    assert len(allfs) == 256
    assert witnesses((1, 1, 1, 1)) == [2, 3]
    assert witnesses((2, 2, 2, 2)) == [3]
    assert witnesses((1, 3, 1, 1)) == []
    assert witnesses((1, 2, 3, 3)) == []

    n_with = sum(1 for f in allfs if witnesses(f))
    # 独立容斥（与 Julia 硬编码 144 双账核对）。
    a3 = 3 ** 3 * 4
    a2_only = 2 ** 2 * 4 ** 2 - 2 ** 2 * 3 * 4
    a1_only = 64 - 32 - 36 + 24
    assert n_with == a3 + a2_only + a1_only == 144

    # 见证必须随函数变化：对每个固定 κ 造敌人（常值 κ）。
    for k in range(1, DELTA):
        assert not closed((k, k, k, k), k)

    # f-谢拉赫型条款与失败原因二分类。
    def fshelah(f, kap, jfk, cap):
        return closed(f, kap) and kap < jfk and jfk in cap

    def reasons(f, kap, jfk, cap):
        cf = next((i for i in range(kap) if f[i] >= kap), None)
        return cf, jfk not in cap

    assert fshelah((1, 1, 1, 1), 2, 3, {3})
    assert reasons((1, 1, 1, 1), 2, 3, {3}) == (None, False)
    assert reasons((2, 2, 2, 2), 2, 3, {3}) == (0, False)
    assert reasons((1, 1, 1, 1), 2, 4, {3}) == (None, True)

    # 「每个函数都有见证」的有限核查：只要 cap 覆盖到位、
    # j(f)(κ) 选得高，144 个有闭包点的函数各自可配见证——
    # 但敌人函数（112 个无闭包点者）无 κ 可选：全称量词
    # 的边界在闭包一款就断。
    assert 256 - 144 == 112

    print("Python：256 函数独立枚举 144；容斥双账 108+16+20；")
    print("每个固定 κ 都有敌人；失败原因二分类——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
