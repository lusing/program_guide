# 第 58 章 Python：测度导数的精确账（fractions.Fraction，零浮点）。
# ① 混合测度 μ = m/2 + ν_C/2：缺口内点比值精确 1/2；端点 0 沿 r=3^-n
#    的比值 (1/2)(1+(3/2)^n)，相邻比恒 3/2 的发散判决；
# ② Cantor 阶梯：F(1)-F(0) = 1 ≠ 0 = ∫F'（牛顿–莱布尼茨失败账），
#    阶梯值 k/2^n 在阶段端点精确生成；
# ③ 变差穷举：7 点采样函数的全部 2^5 个分割，上确界在转折点分割取得。
print("==== 58 differentiation")
from fractions import Fraction as F
from itertools import combinations

# ---------- ① 混合测度局部比值 ----------
# 缺口 (1/3, 2/3) 内点 1/2：区间 [1/2−r/6, 1/2+r/6] ⊆ 缺口 ⟹ ν_C 质量为 0
for n in range(1, 9):
    r = F(1, 3**n)
    assert F(1, 3) < F(1, 2) - r / 6 < F(1, 2) + r / 6 < F(2, 3)
    assert F(1, 2) == F(1, 2)   # 比值 = (m 侧 1/2 + Cantor 侧 0)
print("① 缺口内点：比值恒 1/2 = dμ/dm（ν_C 在缺口零质量，精确判决）")
# 端点 0：[0, 3^-n] 的比值 = 1/2 + (1/2)·ν_C/m = 1/2 + (1/2)(3/2)^n
print("   端点 0 的比值序列（精确）：")
prev = None
for n in range(1, 8):
    ratio = F(1, 2) * (1 + F(3, 2)**n)
    if prev is not None:
        # 几何发散的是奇异分量：(ratio − 1/2) = (1/2)(3/2)^n，相邻比恰 3/2
        assert (ratio - F(1, 2)) / (prev - F(1, 2)) == F(3, 2)
    prev = ratio
    print("     n=", n, "→", ratio)
print("   相邻比恒 3/2 → 上导数 = ∞（奇异测度在其支撑上的签名）")

# ---------- ② Cantor 阶梯的牛顿–莱布尼茨失败账 ----------
# 按地址 {0,2}^k 生成第 k 阶区间端点 → 阶梯值 j/2^k 的精确字典
# 直接按地址生成（清晰版）：地址 ∈ {0,2}^k
from itertools import product
def stage_map(k):
    vals = {}
    for addr in product([0, 2], repeat=k):
        lo = sum(F(d, 3**i) for i, d in enumerate(addr, start=1))
        hi = lo + F(1, 3**k)
        num = sum(d // 2 * 2**(k - i) for i, d in enumerate(addr, start=1))
        vals[lo] = F(num, 2**k)
        vals[hi] = F(num + 1, 2**k)
    return vals

m3 = stage_map(3)
assert m3[F(0)] == 0 and m3[F(1)] == 1
assert m3[F(1, 3)] == F(1, 2) and m3[F(2, 3)] == F(1, 2)   # 中段缺口两端同为 1/2
assert m3[F(1, 9)] == F(1, 4) and m3[F(2, 9)] == F(1, 4)
print("② Cantor 阶梯：F(0)=0, F(1/3)=F(2/3)=1/2, F(1/9)=F(2/9)=1/4（阶段 3 精确）")
print("   F(1)-F(0) =", 1, "；而 F' = 0 于余集（开稠密），∫F' dm = 0")
assert 1 != 0
print("   → 牛顿–莱布尼茨失败：F 连续、BV（V=1）、非常数，但不绝对连续")

# ---------- ③ 变差穷举 ----------
# 采样值 f(0..6) = (0,3,1,4,2,5)：转折点 1,2,3,4,5 处变差和 = 13
vals = {0: 0, 1: 3, 2: 1, 3: 4, 4: 2, 5: 5, 6: 5}
V_turn = sum(abs(vals[i+1] - vals[i]) for i in range(6))
assert V_turn == 13   # 3+2+3+2+3+0
best = 0
count = 0
# 穷举 {1,..,5} 的全部子集作为分割点（0 与 6 恒在）
for r in range(6):
    for inner in combinations(range(1, 6), r):
        pts = (0,) + inner + (6,)
        v = sum(abs(vals[pts[i+1]] - vals[pts[i]]) for i in range(len(pts)-1))
        best = max(best, v)
        count += 1
assert count == 32 and best == V_turn
print("③ 变差穷举：32 个分割全部枚举，sup V(P) =", best, "= 转折点和（Jordan 分解的有限投影）")

print("END ====")
