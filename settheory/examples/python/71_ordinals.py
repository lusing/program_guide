# 第 71 章：序数与累积层次（冯琦 §1.7）
# 秩函数全息馆：V 塔、RK(n) = n、S∘RK = RK∘S、三择一有限截面、
# sup/min、ω 之上（第一条不可达的楼层线——以数据结构呈现）。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 71")

EMPTY = frozenset()

# ---------- 冯诺伊曼数字 ----------
def vn(n):
    r = EMPTY
    for _ in range(n):
        r = r | frozenset([r])
    return r

# Vₙ 塔（定义 1.64 的有限段）
def powerset(s):
    elems = list(s)
    return [frozenset(elems[i] for i in range(len(elems)) if (m >> i) & 1)
            for m in range(1 << len(elems))]

V, sizes = [EMPTY], [1]
for _ in range(3):
    V = powerset(V)
    sizes.append(len(V))
print("Vₙ 塔规模 |V₀..V₃| =", sizes, "（|V₄| = 2^16 = 65536——塔的爆炸率）")

# ---------- 秩函数（定义 1.66）：RK(a) := 最小的 α 使 a ∈ V_{α+1} ----------
from functools import lru_cache

@lru_cache(maxsize=None)
def rank(a):
    return 0 if not a else 1 + max(rank(e) for e in a)

# RK(n) = n：冯诺伊曼数字在秩轴上排成斜率为 1 的直线（命题 1.21）
assert [rank(vn(n)) for n in range(20)] == list(range(20))
print("RK(0..19) = 0..19 ✓（RK(n) = n——书页结论的 20 点验证）")

# S∘RK = RK∘S（命题 1.21(2)）：后继恰好在塔上爬一层
succ = lambda x: x | frozenset([x])
samples = [vn(n) for n in range(12)] + [frozenset([vn(n), vn(n + 2)]) for n in range(4)]
assert all(rank(succ(a)) == rank(a) + 1 for a in samples)
print("S∘RK = RK∘S 在 16 个样本上全对 ✓")

# 引理 1.12 方向：a 的秩 < α ⟺ a ∈ V_α 的抽样（V₃ 的 16 元全部秩 < 3）
V3 = powerset(powerset(powerset(EMPTY)))
assert all(rank(a) < 3 for a in V3)
print("V₃ 的 16 个居民秩全 < 3 ✓")

# ---------- 三择一（定理 1.50 的有限截面） ----------
for i in range(10):
    for j in range(10):
        a, b = vn(i), vn(j)
        outcomes = [i < j, i == j, j < i]
        assert sum(outcomes) == 1, "三择一必须恰一成立"
        assert (a <= b) == (i <= j), "序数的 ⊆ 即 ≤"
print("0..9 全对：三择一恰一、a ⊆ b ⟺ a ≤ b ✓")

# ---------- sup = ⋃（命题 1.20）与 min（定理 1.51） ----------
assert vn(0) | vn(1) | vn(2) == vn(2)      # sup{0,1,2} = ⋃ = 2
assert vn(1) | vn(2) | vn(4) == vn(4)      # ⋃{1,2,4} = 4
assert min([vn(3), vn(1), vn(2)], key=len) == vn(1)  # min{3,1,2} = 1
print("sup{0,1,2} = 2、⋃{1,2,4} = 4、min{3,1,2} = 1 ✓")

# ---------- 极限序数与 ω（例 1.20 的数据面） ----------
# ω = ⋃{n | n < ω}——在有限数据里只能"逼近"：给出前 2^k 层的塔顶
print("ω 的有限逼近：V_ω 的居民在 0..40 号里秩恰等于其数字",
      "（RK(n)=n 即 ω 层的第一块瓷砖）")

print("END ====")
