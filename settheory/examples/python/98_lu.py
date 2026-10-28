# 第 98 章：与 Julia 独立对拍——同一测度不同外延的层级输出。
from itertools import combinations, product
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def PA(x):
    return x % 3 == 0


def PB(x):
    return x in (0, 3, 6)


def PC(x):
    return x % 3 == 1


def definable(D, P):
    """有限 Def 算子：P-原子的布尔项定义的子集 = 规范四元组。"""
    SP = tuple(x for x in D if P(x))
    SC = tuple(x for x in D if not P(x))
    return {(), tuple(D), SP, SC}


def LU(n, P):
    return definable(list(range(min(n, 8))), P)


def main():
    print("==== 98")
    assert all(PA(x) == PB(x) for x in range(8))
    for n in (1, 2, 3):
        assert LU(n, PA) == LU(n, PB)
    assert LU(3, PA) != LU(3, PC)
    D = list(range(3))
    power = {combo
             for r in range(len(D) + 1)
             for combo in combinations(D, r)}
    assert LU(3, PA) <= power
    print("Python：外延相等 ⟹ 三层一致；外延不同 ⟹ 层级不同；")
    print("定义集 ⊆ 全域幂集（DPow ⊆ Pow 影子）")
    print("END ====")


if __name__ == "__main__":
    main()
