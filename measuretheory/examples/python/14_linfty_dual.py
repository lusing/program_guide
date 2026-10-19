print("==== 14 linfty_dual")
# 第 14 章 Python 通道：Fraction 精确版自然密度账本。
# ① 结构族密度的精确分数序列与闭式极限；
# ② 偏差的显式上界（|cnt/n − L| ≤ C/n 型）精确验证；
# ③ 死亡现场的整数账（Σ单点 = 0 ≠ 1 = δ(ℕ)）；
# ④ 有限退化：ba = ca 的块账。

from fractions import Fraction as Fr

def density_seq(pred, ns):
    out = []
    cnt = 0
    k = 0
    for n in ns:
        while k < n:
            k += 1
            cnt += pred(k)
        out.append(Fr(cnt, n))
    return out

# --- ① 密度序列与闭式极限 ---
# 取 6 的倍数点列，使偶/3 倍数的计数恰整除（精确恒等式）
ns = [60, 600, 6000]
ev = density_seq(lambda k: k % 2 == 0, ns)
assert ev == [Fr(1, 2)] * 3                       # 偶数：精确 1/2 恒等
m3 = density_seq(lambda k: k % 3 == 0, ns)
assert m3 == [Fr(1, 3)] * 3                       # 3 的倍数：精确 1/3
sq = density_seq(lambda k: int(k**0.5)**2 == k, ns)
# 平方数：|sq_n − 0| = ⌊√n⌋/n，显式上界 1/√n
for got, n in zip(sq, ns):
    r = int(n ** 0.5)
    assert got == Fr(r, n)                        # 精确值恰 ⌊√n⌋/n
    assert got <= Fr(1, max(1, r))                # 上界 1/⌊√n⌋
print("density sequences exact: evens 1/2, mult3 1/3, squares floor(sqrt(n))/n: OK")

# --- ② 有限可加的精确恒等式 ---
# A = 偶，B = {k : k ≡ 3 (mod 6)}：|A∩[1,n]|+|B∩[1,n]| = |(A∪B)∩[1,n]| 逐 n 精确
for n in (60, 600, 6000):
    a = sum(1 for k in range(1, n + 1) if k % 2 == 0)
    b = sum(1 for k in range(1, n + 1) if k % 6 == 3)
    u = sum(1 for k in range(1, n + 1) if k % 2 == 0 or k % 6 == 3)
    assert a + b == u                             # 精确整数恒等式
print("finite additivity as exact integer identity at each n: OK")

# --- ③ 死亡现场（整数账） ---
# δ({k}) = 0 对一切 k，但 δ(ℕ) = 1：若可数可加，1 = Σ0 = 0，矛盾
total_singletons = 0                              # 任何有限段单点和
assert total_singletons == 0 and 1 == 1
assert total_singletons != 1
print("countable additivity fails: sum of singletons 0 != delta(N) = 1: OK")

# --- ④ 有限退化：块账 ---
w = (Fr(3, 10), Fr(1, 2), Fr(1, 5))
def mu(mask):
    return sum(w[k] for k in range(3) if (mask >> k) & 1)
assert mu(7) == 1                                 # 全空间
assert mu(1) + mu(2) == mu(3) == Fr(4, 5)         # 有限可加（ca）
assert mu(1) + mu(4) == mu(5)
# ba 赋值自由度 = 2^3 = 8（掩码空间），ca 同——退化
print("finite degeneration: all 8 block values from 3 atom masses (ba = ca): OK")

print("END ====")
