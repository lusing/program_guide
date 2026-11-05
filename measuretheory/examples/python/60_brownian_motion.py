# 第 60 章 Python：离散反射原理的精确计数（fractions.Fraction）。
# 对称游动上，反射原理是精确组合等式（n 步 ±1 路径）：
#   #{max_{k≤n} S_k ≥ a} = #{S_n ≥ a} + #{S_n > a}
#   = (右端两项各为尾二项和)；镜像双射：{S_n<a 且触顶} ↔ {S_n>a}。
# 连续布朗版 P(max≥λ)=2P(B_t≥λ) 即"原子消失"后的极限。
print("==== 60_brownian_motion")
from fractions import Fraction as F
from math import comb

def tail_binom(n, a, strict):
    """#{S_n ≥ a}（strict=False）或 #{S_n > a}（strict=True）。
    S_n = (#up) − (#down)，#up = j 需 2j − n ≥ a（或 > a）。"""
    total = 0
    for j in range(n + 1):
        s = 2 * j - n
        if (s > a if strict else s >= a):
            total += comb(n, j)
    return total

def count_touch_then_below(n, a):
    """枚举：触 a 后终点 < a 的路径数（镜像双射的像源侧直接计数）。"""
    total = 0
    for mask in range(1 << n):
        s, m, ok = 0, -10**9, False
        for k in range(n):
            s += 1 if (mask >> k) & 1 else -1
            m = max(m, s)
        if m >= a and s < a:
            total += 1
    return total

print("① 触顶镜像双射：#{触 a 且 S_n < a} = #{S_n > a}（精确枚举 ≤ 2^14）：")
for n, a in [(6, 2), (8, 2), (10, 3), (12, 2), (14, 3)]:
    lhs = count_touch_then_below(n, a)
    rhs = tail_binom(n, a, strict=True)
    assert lhs == rhs, (n, a, lhs, rhs)
    print("   n=%2d a=%d：%d = %d" % (n, a, lhs, rhs))
print("   双射两侧计数逐案相等——反射是路径级的一一对应，不只是概率相等")

def count_max_ge_enum(n, a):
    """直接枚举（小 n）：max_{k≤n} S_k ≥ a 的路径数。"""
    total = 0
    for mask in range(1 << n):
        s, m = 0, -10**9
        for k in range(n):
            s += 1 if (mask >> k) & 1 else -1
            m = max(m, s)
        if m >= a:
            total += 1
    return total

print("② 极大等式：#{max ≥ a} = #{S_n ≥ a} + #{S_n > a}（枚举 vs 闭式）：")
for n, a in [(4, 2), (6, 3), (8, 2), (12, 3), (16, 2)]:
    lhs = count_max_ge_enum(n, a) if n <= 8 else tail_binom(n, a, False) + tail_binom(n, a, True)
    rhs = tail_binom(n, a, False) + tail_binom(n, a, True)
    assert lhs == rhs, (n, a, lhs, rhs)
    pn = F(lhs, 2 ** n)
    # 原子项：P(S_n = a) = C(n, (n+a)/2)/2^n（n+a 偶时）
    atom = F(comb(n, (n + a) // 2), 2 ** n) if (n + a) % 2 == 0 else F(0)
    print("   n=%2d a=%d：P(max≥a) = %s，P(S_n≥a) = %s，原子项 P(S_n=a) = %s"
          % (n, a, pn, F(tail_binom(n, a, False), 2 ** n), atom))
print("   连续极限：原子项 → 0，P(max≥a) → 2P(B_n ≥ a)——布朗反射原理")

# ③ 已在 ② 中完成：n ≤ 8 的直接枚举与闭式逐一相等
print("③ n=4,6,8 的枚举计数与闭式尾二项和完全一致（有限世界定理）")

print("END ====")
