# 第 04 章 实数：Cantor-Bendixson 导集迭代实验
#
# Jech 定理 14：每个不可数闭集 F = P ∪ S（P 完美、S 至多可数）。
# 求导算子 A ↦ A'（极限点集）迭代到稳定（θ 步，θ 可数）。
# 本文件在有限网格上做"求导迭代"实验，观察 θ 与分解结构。

import sys
import io
from fractions import Fraction

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 04 实数：Cantor-Bendixson 迭代")

# ------------------------------------------------------------------
# 一、求导算子：A' = 极限点集（每个邻域含 A 的其他点）
# 在网格上用阈值邻域（半径 ε）近似
# ------------------------------------------------------------------

def derivative(pts, eps):
    """返回 pts 中是自身极限点的那些（ε-尺度近似）"""
    out = []
    for x in pts:
        neighbors = [y for y in pts if y != x and abs(x - y) < eps]
        if neighbors:
            out.append(x)
    return sorted(out)

def cb_iterate(pts, eps):
    """迭代求导至稳定，返回 (稳定核, 步数, 各层剥掉的点数)"""
    layers = []
    cur = sorted(pts)
    step = 0
    while True:
        nxt = derivative(cur, eps)
        peeled = len(cur) - len(nxt)
        if peeled == 0:
            return cur, step, layers
        layers.append(peeled)
        cur = nxt
        step += 1
        if step > 100:
            return cur, step, layers

# ------------------------------------------------------------------
# 二、实验 1：稠密块 + 孤立装饰（一步求导剥孤立）
# ------------------------------------------------------------------

eps = Fraction(1, 200)

dense_block = [Fraction(k, 2000) for k in range(1000)]      # 连续网格块
decor = [Fraction(1), Fraction(3, 2), Fraction(2), Fraction(3), Fraction(4)]
pts = sorted(dense_block + decor)

once = derivative(pts, eps)
print(f"  实验一：{len(dense_block)} 点稠密块 + 5 个孤立装饰点")
print(f"    求导一次：{len(pts)} → {len(once)}（剥掉 {len(pts) - len(once)} 个孤立点）")
assert len(once) == len(dense_block)         # 块内每点的 ε-邻域都有同伴
print(f"    稠密块全保留（互为极限点），装饰点剥光 ✓")

# ------------------------------------------------------------------
# 三、实验 2：康托式完美核 + 远处装饰孤立点
# ------------------------------------------------------------------

# 康托 depth-4 网格（81 点中留 16 个）+ 三个明确远离的装饰点
cantor_pts = sorted({Fraction(k, 3**4) for k in range(3**4)
                     if all((k // 3**j) % 3 != 1 for j in range(4))})
decor2 = [Fraction(1, 2), Fraction(1, 6), Fraction(5, 6)]   # 都在挖空段中央
eps2 = Fraction(4, 81)   # 大于康托内点最小距（2/81）、小于装饰点到核的距（1/18）

core2, steps2, layers2 = cb_iterate(cantor_pts + decor2, eps2)
print(f"\n  实验二：康托 depth-4（{len(cantor_pts)} 点）+ 3 个远处装饰点")
print(f"    剥壳层 = {layers2}，稳定核 = {len(core2)} 点")
assert len(core2) == len(cantor_pts)      # 完美核保留，孤立点剥光
print(f"    断言：核恰为康托网格 ✓（定理 14 的有限影子：F = P ∪ S）")

# ------------------------------------------------------------------
# 四、定理 14 的结构总结
# ------------------------------------------------------------------

print("\n  定理 14 的结构：F = P ∪ S，P = F^(θ)（导集稳定核），")
print("  S = F - P 至多可数（每层剥掉的孤立点都有有理区间见证）。")
print("  引理 4.3：严格下降的闭集链可数长——θ 必是可数序数。")

print("END ====")
