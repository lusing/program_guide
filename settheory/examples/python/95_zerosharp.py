# 第 95 章：与 Julia 独立对拍的 R(3,3)=6 穷举与平移/蓝图核对。
from itertools import combinations
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def main():
    print("==== 95")
    pairs = [(i, j) for i in range(6) for j in range(i + 1, 6)]
    idx = {p: k for k, p in enumerate(pairs)}
    triples = list(combinations(range(6), 3))

    def mono_count(mask):
        c = 0
        for (i, j, k) in triples:
            if ((mask >> idx[(i, j)]) & 1) == ((mask >> idx[(i, k)]) & 1) \
               == ((mask >> idx[(j, k)]) & 1):
                c += 1
        return c

    counts = [mono_count(m) for m in range(1 << 15)]
    assert all(c > 0 for c in counts)
    assert min(counts) == 2
    witness = counts.index(2)
    assert mono_count(witness) == 2

    def c5(i, j):
        d = (i + 5 - j) % 5 if i != j else 0
        return 1 if d in (1, 4) else 0

    mask5 = 0
    for (i, j) in [(i, j) for i in range(5) for j in range(i + 1, 5)]:
        if c5(i, j):
            mask5 |= 1 << idx[(i, j)]
    for t in combinations(range(5), 3):
        i, j, k = t
        vals = ((mask5 >> idx[(i, j)]) & 1,
                (mask5 >> idx[(i, k)]) & 1,
                (mask5 >> idx[(j, k)]) & 1)
        assert len(set(vals)) > 1

    parity = lambda i, j: (i + j) % 2
    A = [0, 2, 4, 6]
    B = [1, 3, 5, 7]
    assert all(parity(i, j) == 0 for i, j in combinations(A, 2))
    assert all(parity(i, j) == 0 for i, j in combinations(B, 2))
    assert all(parity(i + 2, j + 2) == parity(i, j) for i, j in combinations(A, 2))
    assert any(parity(i, j) == 1 for i, j in combinations([0, 1, 2], 2))

    print("Python：32768 种染色全含齐一三元组，最少 2 个；C5 无齐一三元组")
    print("偶点集与奇点集同蓝图（恒 0），平移 +2 保蓝图；混合集 {0,1,2} 不齐一")
    print("END ====")


if __name__ == "__main__":
    main()
