print("==== 15 daniell")
# 第 15 章 Python 通道：Fraction 精确版有限 Daniell 流水线。
# Ω = {1..8}，三块划分 B1={1,2}, B2={3,4}, B3={5,6,7,8}。
# ① C = 块代数（8 集），μ*(A) = 命中块权和（覆盖下确界的有限形态）；
# ② 表示定理：I(f) = Σ v_i μ(B_i) 精确（随机 300 个阶梯）；
# ③ Stone 唯一性：换权 ⟹ 换 μ；
# ④ 非 Stone 瘦格：B3 质量对 I' 不可见——唯一性失败。

from fractions import Fraction as Fr
import random

BLOCKS = ([1, 2], [3, 4], [5, 6, 7, 8])
W = (Fr(1, 2), Fr(1, 3), Fr(1, 6))

def Ifun(t, w=W):
    return sum(v * wi for v, wi in zip(t, w))

def mu_star(A):
    return sum(w for w, B in zip(W, BLOCKS) if set(A) & set(B))

# --- ① C 与 μ* ---
block_algebra = []
for m in range(8):
    s = set()
    if m & 1: s |= set(BLOCKS[0])
    if m & 2: s |= set(BLOCKS[1])
    if m & 4: s |= set(BLOCKS[2])
    block_algebra.append(s)
assert len(block_algebra) == 8
for C in block_algebra:
    assert mu_star(C) == Ifun(tuple(1 if set(B) <= C else 0 for B in BLOCKS))
# 覆盖下确界口径：任意 A 的 μ* = 命中块权和（有限世界精确）
for A in ([1], [1, 3], [5], [2, 4, 6], list(range(1, 9)), []):
    hit = sum(1 for B in BLOCKS if set(A) & set(B))
    assert mu_star(A) == sum(W[i] for i in range(3) if set(A) & set(BLOCKS[i]))
print("C = block algebra (8 sets), mu* = hit-block weight sum (exact): OK")

# --- ② 表示定理（随机 300 个阶梯） ---
random.seed(15)
for _ in range(300):
    t = tuple(random.randint(-3, 3) for _ in range(3))
    integral = sum(v * mu_star(B) for v, B in zip(t, BLOCKS))
    assert Ifun(t) == integral
print("representation I(f) = integral f dmu exact on 300 random steps: OK")

# --- ③ Stone 唯一性方向 ---
W2 = (Fr(1, 5), Fr(1, 2), Fr(3, 10))
assert Ifun((1, 0, 0)) == Fr(1, 2) != Fr(1, 5) == Ifun((1, 0, 0), W2)
print("weights determine mu: changing I changes mu (uniqueness direction): OK")

# --- ④ 非 Stone 瘦格：唯一性失败 ---
# H' = {(a, b, 0)}：I'(f) = a/2 + b/3；B3 质量任意都不影响 I'
def Iprime(a, b):
    return Fr(a, 2) + Fr(b, 3)
for w3 in (Fr(1, 6), Fr(7, 10), Fr(0)):
    # H' 中的函数在 (w1,w2,w3) 测度下的积分与 I' 一致（B3 上恒 0）
    for (a, b) in ((1, 0), (0, 1), (2, -1)):
        t = (a, b, 0)
        assert Ifun(t, (Fr(1, 2), Fr(1, 3), w3)) == Iprime(a, b)
print("non-Stone thin lattice: same I' with any B3 mass (uniqueness fails): OK")

print("END ====")
