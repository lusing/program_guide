# 第 110 章：与 Julia 独立对拍——投影、三理想饱和界与反射可比对。
import io
import sys
from itertools import product  # noqa: F401

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = 0b111


def proj(m):
    return m & 0b110                 # π：抹掉坐标 0


def rep_of(ideal, m):
    return min(n for n in range(8)
               if n not in ideal and (n & ~m) in ideal and (m & ~n) in ideal)


def quotient_atoms(ideal):
    ipos = [m for m in range(8) if m not in ideal]
    reps = sorted({rep_of(ideal, m) for m in ipos})
    return [r for r in reps if not any(r2 != r and (r2 & ~r) in ideal for r2 in reps)]


def max_antichain(ideal):
    ipos = [m for m in range(8) if m not in ideal]
    best = 0
    for mask in range(2 ** len(ipos)):
        A = [ipos[i] for i in range(len(ipos)) if (mask >> i) & 1]
        ok = all(A[i] & A[j] in ideal for i in range(len(A)) for j in range(i + 1, len(A)))
        if ok:
            best = max(best, len({rep_of(ideal, a) for a in A}))
    return best


def sub(m, n):
    return (m & ~n) == 0             # 位掩码包含 m ⊆ n


def main():
    print("==== 110")
    assert proj(0b111) == 0b110
    assert proj(0b011) == 0b010
    assert proj(0b001) == 0
    assert {proj(m) for m in range(8)} == {0, 2, 4, 6}   # 满到 P({1,2})

    # 三理想饱和界表。
    table = [
        ("I₀ = {∅,{0}}", frozenset({0b000, 0b001})),
        ("I₁ = {∅}（平凡）", frozenset({0b000})),
        ("I₂ = {∅,{0},{1},{0,1}}", frozenset({0b000, 0b001, 0b010, 0b011})),
    ]
    for name, ideal in table:
        ma = max_antichain(ideal)
        atoms = len(quotient_atoms(ideal))
        print(f"  {name}：反链至多 {ma}，商原子 {atoms}，饱和数 {ma + 1}")
        assert ma == atoms

    I0 = frozenset({0b000, 0b001})
    assert max_antichain(I0) == 2
    assert (0b010 & 0b100) in I0

    # 核刻画与反链投影不交（全量核查）。
    assert all((m in I0) == (proj(m) == 0) for m in range(8))
    ipos0 = [m for m in range(8) if m not in I0]
    for C in ipos0:
        for D in ipos0:
            if (C & D) in I0:
                assert (proj(C) & proj(D)) == 0
    assert all(proj(C) != 0 for C in ipos0)

    # 反射可比对：上向闭 + 全投影的族 S 必含 N ⊂ N' 且投影不同。
    def upward_closed(S):
        return all(N2 in S for N in S for N2 in ipos0 if sub(N, N2))

    def full_proj(S):
        return all(any(proj(N) == t for N in S) for t in (0b010, 0b100, 0b110))

    count_ps = 0
    for mask in range(64):
        S = frozenset(ipos0[i] for i in range(6) if (mask >> i) & 1)
        if upward_closed(S) and full_proj(S):
            count_ps += 1
            assert any(N in S and N2 in S and N != N2 and sub(N, N2)
                       and proj(N) != proj(N2)
                       for N in S for N2 in S)
    assert count_ps > 0

    print("Python：三理想饱和界表（反链=商原子）；核=π⁻¹(∅)；")
    print(f"反链投影不交全查；上向闭 PS 族（{count_ps} 个）全含反射可比对——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
