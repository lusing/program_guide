import io
import sys
import random
from fractions import Fraction

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 06 approximation")

# 第 06 章：测度逼近与唯一性（与 Julia 对拍：二进区间用精确分数）。

# 目标集 A = [0, 1/4) ∪ [1/2, 3/4)：边界全部落在二进网格上——
# 深度 d ≥ 2 的逼近应【精确】等于真值（边界对齐时的完美逼近）
def in_target(x):
    return x < Fraction(1, 4) or (Fraction(1, 2) <= x < Fraction(3, 4))

TRUE_MU = Fraction(1, 2)

def approx_measure(d):
    n = 2 ** d
    hit = 0
    for i in range(n):
        # 网格格点 (i, i+1)/n 整体在/出集合——用区间中点判定，
        # 边界对齐时中点判定无误
        mid = Fraction(2 * i + 1, 2 * n)
        if in_target(mid):
            hit += 1
    return Fraction(hit, n)

for d in (2, 3, 5, 8, 12):
    est = approx_measure(d)
    assert est == TRUE_MU, f"深度 {d} 应精确等于 1/2（边界对齐）"
print("边界对齐集合：深度 2 起逼近即精确（二进代数逼近定理的清爽案例）")

# 边界不对齐集合：A = [0, 0.3) ∪ [0.5, 0.7)
def in_target2(x):
    return x < 0.3 or (0.5 <= x < 0.7)

def approx_measure2(d):
    n = 2 ** d
    hit = 0
    for i in range(n):
        mid = (2 * i + 1) / (2 * n)
        if in_target2(mid):
            hit += 1
    return hit / n

est_prev = approx_measure2(3)
errs = []
for d in (3, 6, 9, 12):
    est = approx_measure2(d)
    err = abs(est - 0.5)
    errs.append(err)
    print(f"  深度 {d:2d}：估计 {est:.8f}，误差 {err:.2e}")
assert errs[-1] < 4e-4, "深度 12 误差 ≤ 2 个网格"
print("不对齐边界：误差 O(2^-d) 收敛（逼近定理的一般情形）")

# --- 唯一性的统计影子：经验测度 vs Lebesgue 在二进区间族上 ---
random.seed(23)
samples = [random.random() for _ in range(500_000)]
d = 6
max_gap = 0.0
for k in range(1, 2 ** d + 1):
    lo, hi = (k - 1) / 2 ** d, k / 2 ** d
    emp = sum(1 for x in samples if lo <= x < hi) / len(samples)
    max_gap = max(max_gap, abs(emp - 1 / 2 ** d))
print(f"经验测度 vs Lebesgue（64 区间）最大偏差：{max_gap:.5f}")
assert max_gap < 0.01, "50 万样本偏差 < 1%"

# --- 生成系上的值决定一切：不同二进剖分同一值 ---
def mu_of(pieces):
    return sum(b - a for (a, b) in pieces)

coarse = [(0.0, 0.125), (0.25, 0.5), (0.625, 0.75)]
fine = [(0.0, 0.0625), (0.0625, 0.125), (0.25, 0.375), (0.375, 0.5),
        (0.625, 0.6875), (0.6875, 0.75)]
assert abs(mu_of(coarse) - mu_of(fine)) < 1e-15
print("不同剖分同一测度值：在生成系上的取值决定一切")

print("END ====")
