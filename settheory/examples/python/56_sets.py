# 第 56 章：朴素集合的机器化（Makinson Ch1）
# frozenset 代数 + 特征函数 ↔ 位串 + 广义并交 + De Morgan 家族验证
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import product, combinations

print("==== 56")

U = frozenset(range(3))                     # 局部宇宙 {0,1,2}
POW = [frozenset(c) for k in range(4) for c in combinations(U, k)]

# 一、交并差的定律穷举（8×8×8 全部子集三元组）
ok = True
for A, B, C in product(POW, repeat=3):
    ok &= (A & B == B & A)
    ok &= (A | B == B | A)
    ok &= (A & (B | C) == (A & B) | (A & C))
    ok &= (A | (B & C) == (A | B) & (A | C))
    ok &= (A & (A | B) == A == A | (A & B))
    ok &= (A - (B | C) == (A - B) & (A - C))
    ok &= (A - (B & C) == (A - B) | (A - C))
print("  交并差七律（8^3 穷举）：", "全部成立 ✓" if ok else "有反例！")

# 二、A ⊆ B iff A∩B = A iff A∪B = B
fix_ok = all(
    (A <= B) == (A & B == A) == (A | B == B)
    for A in POW for B in POW
)
print("  A⊆B ⟺ A∩B=A ⟺ A∪B=B（64 对穷举）：", "成立 ✓" if fix_ok else "失败！")

# 三、补与 De Morgan（相对局部宇宙 U）
comp = lambda X: U - X
dm_ok = all(
    comp(B | C) == comp(B) & comp(C) and comp(B & C) == comp(B) | comp(C)
    for B in POW for C in POW
)
print("  De Morgan 双律（相对 U={0,1,2}）：", "成立 ✓" if dm_ok else "失败！")

# 四、特征函数观点：子集 ↔ 位串 ↔ 幂集
bits = lambda X: "".join("1" if i in X else "0" for i in sorted(U))
tab = {bits(X): X for X in POW}
print("  特征函数字典（8 个位串 ↔ 8 个子集）：", sorted(tab))
assert len(tab) == 8 == 2 ** len(U)
print("  |P(U)| = 2^|U| = 2^3 = 8 ✓")

# 五、广义并/交与 De Morgan 家族版
fam = [frozenset(c) for k in (1, 2) for c in combinations(U, k)]
gU = frozenset().union(*fam)
gI = frozenset(U).intersection(*fam)
print("  广义并 ⋃族 =", set(gU), " 广义交 ⋂族 =", set(gI))
print("  -⋃族 =", set(comp(gU)), " ⋂(-B) =", set(frozenset().intersection(*[comp(B) for B in fam])))
assert comp(gU) == frozenset().intersection(*[comp(B) for B in fam])

# 六、两两不交 ≠ 整体不交：X={1,2}, Y={3}, Z={1,4} 三元反例（64 章 Δ 引理伏笔）
X, Y, Z = frozenset({1, 2}), frozenset({3}), frozenset({1, 4})
pairwise = not (X & Y or Y & Z or X & Z)
print("  三元反例：X∩Y=Y∩Z=∅ 但整体非两两不交（X∩Z={1}）→", "两两不交=" , pairwise)

# 七、指数爆炸：穷举子集的代价
print("  指数爆炸警示：n=4→16，n=10→1024，n=20→1048576，n=40→约 1.1e12")
print("END ====")
