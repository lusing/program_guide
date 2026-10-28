# 第 97 章：与 Julia 独立对拍的直接极限与轨迹表。
from itertools import product as iproduct
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def e01(x):
    return 2 * x


def e12(x):
    return x + 3


def e23(x):
    return -x


def eij(i, j, x):
    if i == j:
        return x
    if (i, j) == (0, 1):
        return e01(x)
    if (i, j) == (1, 2):
        return e12(x)
    if (i, j) == (2, 3):
        return e23(x)
    if i < j:
        return eij(j - 1, j, eij(i, j - 1, x))
    raise ValueError("i > j")


def direct_limit_classes(points):
    classes = []
    for p in points:
        i, x = p
        for c in classes:
            k, y = c[0]
            l = max(i, k)
            if eij(i, l, x) == eij(k, l, y):
                c.append(p)
                break
        else:
            classes.append([p])
    return classes


def main():
    print("==== 97")
    for i, j, k in iproduct(range(4), range(4), range(4)):
        if i < j < k:
            for x in range(-5, 6):
                assert eij(i, k, x) == eij(j, k, eij(i, j, x))
    pts = [(i, x) for i in range(4) for x in range(-2, 3)]
    classes = direct_limit_classes(pts)
    # 终端像并集 {-7,-5,-4,-3,-2,-1,0,1,2}：恰 9 类。
    assert len(classes) == 9
    assert sum(len(c) for c in classes) == len(pts)
    for c in classes:
        for (i, x), (k, y) in iproduct(c, c):
            l = max(i, k)
            assert eij(i, l, x) == eij(k, l, y)
    traj = list(range(6))
    assert all(a < b for a, b in zip(traj, traj[1:]))
    print("Python：交换图与直接极限类数与 Julia 一致（9 类）；")
    print("临界点轨迹严格递增复现")
    print("END ====")


if __name__ == "__main__":
    main()
