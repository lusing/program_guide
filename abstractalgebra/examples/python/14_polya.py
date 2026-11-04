# 第 14 章 · 用群计算：伯恩赛德与 Pólya —— Python 通道
#
# 旗/项链/棋盘/赌盘四现场 + n = 1..10 项链数表与闭式对拍。

from math import gcd
from sympy import divisors, totient

print("==== 14 用群计算：伯恩赛德与 Pólya")

polya = lambda cycles_list, q: sum(q ** len(cs) for cs in cycles_list) // len(cycles_list)


def brute_orbits(pos, q, action):
    seen, orbits = set(), 0
    for code in range(q ** pos):
        c = tuple(code // q ** i % q for i in range(pos))
        if c in seen:
            continue
        orbits += 1
        seen.update(action(c))
    return orbits


# ---------- 旗子：6 条纹 3 色，翻转 ----------
assert polya([[1] * 6, [2, 2, 2]], 3) == 378
flip = lambda c: {c, c[::-1]}
assert brute_orbits(6, 3, flip) == 378
print("6 条纹 3 色旗：Pólya = 暴力 = 378 ✓")

# ---------- 项链：旋转 / 二面体 ----------
def rot_cycles(n, k):
    g = gcd(n, k)
    return [n // g] * g

for q_ in (2, 3):
    n = 6
    assert polya([rot_cycles(n, k) for k in range(n)], q_) == \
        sum(q_ ** gcd(n, k) for k in range(n)) // n
assert polya([rot_cycles(6, k) for k in range(6)], 2) == 14
# 二面体（6 珠）：循环指标 (x₁⁶+x₂³+2x₃²+2x₆+3x₁²x₂²+3x₂³)/12
dih6 = [[1] * 6, [2, 2, 2], [2, 2, 2], [3, 3], [3, 3], [6], [6],
        [1, 1, 2, 2], [1, 1, 2, 2], [1, 1, 2, 2], [2, 2, 2], [2, 2, 2]]
assert len(dih6) == 12 and polya(dih6, 2) == 13 and polya(dih6, 3) == 92
print("2 色 6 珠：旋转 14；二面体 13；3 色二面体 92 ✓")

# ---------- 4×4 双色棋盘 ----------
chess = [[1] * 16, [4, 4, 4, 4], [2] * 8, [4, 4, 4, 4]]
assert polya(chess, 2) == 16456 == (2 ** 16 + 2 ** 4 * 2 + 2 ** 8) // 4

def rot90_index(x):                    # 行 i 列 j → (j, 3−i)，0 基格号
    i, j = divmod(x, 4)
    return j * 4 + (3 - i)

def chess_action(c):
    out = {c}
    cur = c
    for _ in range(3):
        cur = tuple(cur[rot90_index(x)] for x in range(16))
        out.add(cur)
    return out

assert brute_orbits(16, 2, chess_action) == 16456
print("4×4 双色棋盘：Pólya = 暴力 = 16456（例 2.161）✓")

# ---------- 5 扇形 2 色赌盘 ----------
assert polya([rot_cycles(5, k) for k in range(5)], 2) == 8
def roulette_action(c):
    return {tuple(c[(i - k) % 5] for i in range(5)) for k in range(5)}
assert brute_orbits(5, 2, roulette_action) == 8
print("5 扇形 2 色赌盘：Pólya = 暴力 = 8 ✓")

# ---------- n = 1..10 项链数表：闭式 vs 暴力 ----------
closed = lambda n, q: sum(totient(d) * q ** (n // d) for d in divisors(n)) // n
for n in range(1, 11):
    for q_ in (2, 3):
        brute = brute_orbits(n, q_,
                             lambda c, n=n: {tuple(c[(i - k) % n] for i in range(n))
                                             for k in range(n)})
        assert brute == closed(n, q_) == \
            sum(q_ ** gcd(n, k) for k in range(n)) // n
print("n = 1..10 × 2/3 色项链：闭式 (1/n)Σφ(d)q^{n/d} = Burnside = 暴力 ✓")

print("END ====")
