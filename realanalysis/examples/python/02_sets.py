# 第 02 章 集合论：Python 通道。
# 有限论域上的并交补与德摩根律，以及索引族区间的截断实验：
# 无限并/交在机器上只能截断到有限 N，极限点永远差一步。
# 运行：python -I 02_sets.py
from fractions import Fraction

print("==== 02 sets ====")

# --- 1. 有限论域 U = {1,...,9} 上的集合运算 ------------------------
U = set(range(1, 10))
A = {1, 3, 5, 7}
B = {2, 3, 4, 7}
comp = lambda S: U - S

assert A <= (A | B) and (A & B) <= A
assert (A <= B) == ((A | B) == B)
assert (A <= B) == ((A & B) == A)
assert comp(A | B) == comp(A) & comp(B)
assert comp(A & B) == comp(A) | comp(B)
assert (set() & A) == set() and set() <= A
print("finite-universe De Morgan and distributivity verified")

# 分配律 A ∪ (B ∩ Aᶜ) = (A ∪ B) ∩ (A ∪ Aᶜ)
assert A | (B & comp(A)) == (A | B) & (A | comp(A))

# --- 2. 区间漏洞：(1,3) ∪ (3,5) ≠ (1,5) ---------------------------
grid = [Fraction(1) + Fraction(k, 4) for k in range(17)]   # 1.00 .. 5.00
open_interval = lambda a, b: {x for x in grid if a < x < b}
gap = open_interval(1, 3) | open_interval(3, 5)
assert Fraction(3) not in gap and Fraction(3) in open_interval(1, 5)
print("open intervals: point 3 is the gap in (1,3) union (3,5)")

# --- 3. 索引族 A_n = (-1/(n+1), 1/(n+1))：递减族的并 ---------------
N = 100
def Aseq(n):
    return (-Fraction(1, n + 1), Fraction(1, n + 1))

lo, hi = Aseq(0)
for n in range(1, N + 1):
    a, b = Aseq(n)
    lo, hi = min(lo, a), max(hi, b)
assert lo == -1 and hi == 1
print(f"A_n nested union truncated at N={N}: ({lo}, {hi})")

# --- 4. 索引族 B_n = [0, 2 - 1/(n+1)]：递增族 ----------------------
def Bseq(n):
    return (Fraction(0), 2 - Fraction(1, n + 1))

right_ends = [Bseq(n)[1] for n in range(N + 1)]
assert all(right_ends[i] <= right_ends[i + 1] for i in range(N))
assert max(right_ends) < 2                      # 有限截断永远够不到 2
assert max(right_ends) == 2 - Fraction(1, N + 1)
print("B_n truncated union supremum =", max(right_ends), "< 2 (gap remains)")
assert min(right_ends) == Bseq(0)[1] == 1       # 截断交 = B_0 = [0,1]
print("B_n truncated intersection = [0,", min(right_ends), "]")

# --- 5. 索引族德摩根律的有限影子 -----------------------------------
E = [{1, 2}, {2, 3}, {4, 5}]
union_e = set().union(*E)
inter_comp = U
for s in E:
    inter_comp &= comp(s)
assert comp(union_e) == inter_comp
print("indexed-family De Morgan checked on 3 finite sets")

print("END ====")
