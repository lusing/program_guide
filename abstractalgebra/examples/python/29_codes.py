# 第 29 章 · 码 —— Python 通道

print("==== 29 码：分组码、线性码与译码")

# [7,4] 汉明码：列 j = j 的二进制
H = [[0, 0, 0, 1, 1, 1, 1],
     [0, 1, 1, 0, 0, 1, 1],
     [1, 0, 1, 0, 1, 0, 1]]


def syndrome(y):
    return [sum(H[i][j] * y[j] for j in range(7)) % 2 for i in range(3)]


def decode74(y):
    s = syndrome(y)
    if all(v == 0 for v in s):
        return y[:]
    for j in range(7):
        if s == [H[i][j] for i in range(3)]:
            z = y[:]
            z[j] = 1 - z[j]
            return z
    raise ValueError


def bits(code, n=7):
    return [(code >> i) & 1 for i in range(n)]


codewords = [bits(c) for c in range(128) if all(v == 0 for v in syndrome(bits(c)))]
assert len(codewords) == 16
wts = sorted(set(sum(c) for c in codewords))
assert wts == [0, 3, 4, 7]
# 最小距离：两两距离 ≥ 3 且存在 = 3
dmin = min(sum(a ^ b for a, b in zip(u, v)) for u in codewords for v in codewords if u != v)
assert dmin == 3
print("码字清单：16 个、最小距离 3、重量谱 {0,3,4,7} ✓")

# 完全码：128 = 16 × 8
cls = set()
for c in range(128):
    y = bits(c)
    best = min(codewords, key=lambda w: sum(a ^ b for a, b in zip(y, w)))
    assert sum(a ^ b for a, b in zip(y, best)) <= 1
    cls.add(tuple(best))
assert len(cls) == 16
print("完全码：128 = 16 × (1+7)，每向量到最近码字 ≤ 1 ✓")

# 译码：112 单错全恢复
for cw in codewords:
    for j in range(7):
        y = cw[:]
        y[j] ^= 1
        assert decode74(y) == cw
print("译码：16 码字 × 7 位 = 112 个受损字全部恢复 ✓")

# GF(3) [4,2,3]
def trits(code):
    return [(code // 3 ** i) % 3 for i in range(4)]


H3 = [[1, 0, 1, 1], [0, 1, 1, 2]]
cw3 = []
for c in range(81):
    y = trits(c)
    s = [sum(H3[i][j] * y[j] for j in range(4)) % 3 for i in range(2)]
    if s == [0, 0]:
        cw3.append(y)
assert len(cw3) == 9
dmin3 = min(sum(a != b for a, b in zip(u, v)) for u in cw3 for v in cw3 if u != v)
assert dmin3 == 3
print("GF(3) [4,2,3]：9 码字、最小距离 3 ✓")

# 扩展汉明 [8,4,4]
H8 = [[0, 0, 0, 1, 1, 1, 1, 0],
      [0, 1, 1, 0, 0, 1, 1, 0],
      [1, 0, 1, 0, 1, 0, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1]]


def syn8(y):
    return [sum(H8[i][j] * y[j] for j in range(8)) % 2 for i in range(4)]


cw8 = [bits(c, 8) for c in range(256) if all(v == 0 for v in syn8(bits(c, 8)))]
assert len(cw8) == 16
dmin8 = min(sum(a ^ b for a, b in zip(u, v)) for u in cw8 for v in cw8 if u != v)
assert dmin8 == 4
print("扩展汉明 [8,4,4]：16 码字、最小距离 4（检 2）✓")

print("END ====")
