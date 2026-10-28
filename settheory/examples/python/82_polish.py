# 第 82 章：与 Julia 独立对拍——自底向上全表动态规划与暴力验证。
from itertools import product
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

DEPTH = 6


def solve(S):
    val = {s: (s in S) for s in product((0, 1), repeat=DEPTH)}
    for L in range(DEPTH - 1, -1, -1):
        for s in product((0, 1), repeat=L):
            kids = [val[s + (b,)] for b in (0, 1)]
            val[s] = any(kids) if L % 2 == 0 else all(kids)
    return val


def strategy(val):
    def pick(s):
        for b in (0, 1):
            t = s + (b,)
            want = val[t] if len(s) % 2 == 0 else not val[t]
            if want:
                return b
        return 0
    return pick


def verify(S):
    val = solve(S)
    pick = strategy(val)
    winner = val[()]
    if winner:
        for foe in product((0, 1), repeat=3):
            s = ()
            for b in foe:
                s = s + (pick(s), b)
            assert s in S
        return "zhang"
    for foe in product((0, 1), repeat=3):
        s = ()
        for a in foe:
            s = s + (a, pick(s + (a,)))
        assert s not in S
    return "lisi"


def main():
    print("==== 82")
    allseq = list(product((0, 1), repeat=DEPTH))
    S1 = {s for s in allseq if sum(s) >= 4}
    S4 = {s for s in allseq if s[0] == 1}
    S8 = {s for s in allseq if sum(s) % 2 == 0}
    S9 = {s for s in allseq if s[0] + s[2] + s[4] >= 2}
    assert verify(S1) == "lisi"
    assert verify(S4) == "zhang"
    assert verify(S8) == "lisi"
    assert verify(S9) == "zhang"
    val = solve(S4)
    assert val[()] and not val[(0,)]
    assert strategy(val)(()) == 1
    print("Python：全表 DP 与 Julia 递归对拍一致——同四赛局同胜方；")
    print("策略自底向上提取并经 2^3 条对手路径暴力验证")
    print("END ====")


if __name__ == "__main__":
    main()
