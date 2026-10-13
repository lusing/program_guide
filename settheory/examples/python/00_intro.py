# 第 00 章 导引：aleph 阶梯与康托集的数值画像
#
# 本文件做两件事：
# 1. 生成 aleph 阶梯的"索引表"——ℵ_0, ℵ_1, ... 是怎么搭起来的；
# 2. 画出康托集的前几步构造数据，验证 |C| = 2^ℵ0 的数值侧影。

import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 00 导引：aleph 阶梯与康托集")

# ------------------------------------------------------------------
# 一、aleph 阶梯（数据侧影）
# aleph 函数把序数映射到无穷基数；在有限数据的边界内，
# 我们只能生成"名字与指标"，真正的 ℵ 是超穷对象。
# ------------------------------------------------------------------

names = {
    0: ("ℵ₀", "自然数集的基数：第一个无穷基数"),
    1: ("ℵ₁", "第一个不可数基数：ω₁ 的基数"),
    2: ("ℵ₂", "下一个：ℵ₁ 的后继"),
}
for k, (sym, desc) in names.items():
    print(f"  {sym}  : {desc}")

# Cantor 定理保证阶梯永无顶：κ < 2^κ；aleph 则保证"下一个无穷"总存在。
print("  ⋮     : 每一步由后继或极限产生，Cantor 定理保证永不封顶")

# ------------------------------------------------------------------
# 二、康托集的构造数据
# 第 n 步从 [0,1] 挖去 2^n - 1 个开中段；保留集的测度 → 0，
# 但保留的"端点 + 极限点"与 {0,2}^ℕ 一一对应，基数为 2^ℵ0。
# ------------------------------------------------------------------

def cantor_intervals(depth):
    """返回第 depth 步后保留的闭区间列表"""
    ivs = [(0.0, 1.0)]
    for _ in range(depth):
        nxt = []
        for (a, b) in ivs:
            third = (b - a) / 3
            nxt.append((a, a + third))
            nxt.append((b - third, b))
        ivs = nxt
    return ivs

for depth in range(5):
    ivs = cantor_intervals(depth)
    total = sum(b - a for a, b in ivs)
    print(f"  depth={depth}: 保留区间数={len(ivs):3d}, 总测度={total:.6f}")
    assert abs(total - (2 / 3) ** depth) < 1e-12

print("  总测度 (2/3)^n → 0，但基数始终是 2^ℵ0：'测度小'≠'元素少'")

# ------------------------------------------------------------------
# 三、三进制地址：康托集 ↔ {0,2}^ℕ
# ------------------------------------------------------------------

def ternary_address(x, n=12):
    """返回 x 的 n 位三进制展开数字（用 Fraction 精确计算）"""
    from fractions import Fraction
    y = Fraction(x).limit_denominator(10**9)
    ds = []
    for _ in range(n):
        y *= 3
        d = int(y)                      # floor 对 [0,1) 的分数成立
        ds.append(d)
        y -= d
    return ds

# 康托集的端点有"双地址"（如 1/3 = 0.1₃ = 0.0222...₃），
# 非端点有唯一地址，且地址中不含数字 1
from fractions import Fraction

for label, x in [("1/3", Fraction(1, 3)), ("1/9", Fraction(1, 9)),
                 ("1/2", Fraction(1, 2))]:
    ds = ternary_address(x)
    print(f"  {label} 的三进制前 12 位: {''.join(map(str, ds))}")

# 1/9 的主地址是 0.01000...₃（含 1）；端点的备选地址把尾部的
# "1000..." 换成 "0222..."——不再含数字 1，这是端点双地址现象
main_addr = ternary_address(Fraction(1, 9))
assert main_addr[:2] == [0, 1]
alt_addr = [0, 0] + [2] * 10           # 0.00 2222222222...₃
assert 1 not in alt_addr
print("  1/9 的主地址 0.01000...₃ 含 1；备选地址 0.00222...₃ 不含 1")
print("  —— 端点双地址：康托集的每个点都有不含 1 的地址")

print("要点：康托集 = 三进制展开可用 0 与 2 写出的点，")
print("     因此与 {0,2}^ℕ 一一对应——这就是 |C| = 2^ℵ0。")

print("END ====")
