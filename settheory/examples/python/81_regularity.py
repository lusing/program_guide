# 第 81 章：有限循环群上的 Vitali 式商与代表选择。
from fractions import Fraction
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

N = 24
STEP = Fraction(1, 4)
UNIVERSE = {Fraction(j, N) for j in range(N)}
TRANSLATIONS = {k * STEP for k in range(4)}


def orbit(x):
    return frozenset((x+q) % 1 for q in TRANSLATIONS)


def translate(a, q):
    return frozenset((x+q) % 1 for x in a)


def main():
    print("==== 81")
    classes = {orbit(x) for x in UNIVERSE}
    assert len(classes) == 6
    assert all(len(c) == 4 for c in classes)
    assert set().union(*classes) == UNIVERSE
    assert all(c == d or not (c & d) for c in classes for d in classes)
    selector = frozenset(min(c) for c in classes)
    assert len(selector) == 6
    assert all(len(selector & c) == 1 for c in classes)
    pieces = [translate(selector, q) for q in sorted(TRANSLATIONS)]
    assert set().union(*pieces) == UNIVERSE
    assert all(not (pieces[i] & pieces[j])
               for i in range(4) for j in range(i))
    print("Python：24 点按 1/4-平移分成 6 类；代表集 6 点，四个平移恰好分割全域")
    print("这是有限群商实验，不是实数模 Q 的 Vitali 集，也不产生不可测性")
    print("END ====")


if __name__ == "__main__":
    main()
