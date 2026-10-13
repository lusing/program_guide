# 第 05 章 选择公理：无穷下降序列与良序的对照实验（引理 5.2）
#
# 良序 ⟺ 无无穷下降序列（DC 下）。本文件在有限结构上对照：
# 1. 良序集的下降序列必然终止（强归纳可用）；
# 2. 非良序集可以永久下降（ℤ 的例子）；
# 3. 可数选择的失败案例构造：一族非空集的"选择"为什么不是数据。

import sys
import io
import random

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 05 选择公理：下降序列与良序")

# ------------------------------------------------------------------
# 一、良序集上的下降必然终止
# ------------------------------------------------------------------

def descending_in_wellorder(n0):
    """在 ℕ（良序）上从 n0 开始贪心下降：步数 ≤ n0"""
    steps = 0
    n = n0
    while n > 0:
        n -= 1                      # 唯一能走的下降方向
        steps += 1
    return steps

for n0 in [10, 100, 1000]:
    steps = descending_in_wellorder(n0)
    assert steps == n0
print("  ℕ 上从 n0 下降恰走 n0 步——良序保证下降链有限")

# ------------------------------------------------------------------
# 二、非良序：ℤ 上可以永久下降
# ------------------------------------------------------------------

def descending_in_integers(n0, limit=50):
    """在 ℤ（非良序）上可以构造任意长的严格下降序列"""
    return list(range(n0, n0 - limit, -1))

seq = descending_in_integers(0, 10)
print(f"  ℤ 上从 0 出发的下降序列（10 步仍不终止）：{seq}")
assert len(seq) == 10 and all(seq[i] > seq[i + 1] for i in range(9))
print("  ℤ 无极小元 → 非良序 → 下降序列可无穷（引理 5.2 的 (a)）")

# ------------------------------------------------------------------
# 三、良序的"下降即归纳"：强归纳法验证
# ------------------------------------------------------------------

def strong_induction_check(P, upto):
    """P(0) 与 ∀n(∀k<n P(k) → P(n)) 逐点验证"""
    vals = [False] * (upto + 1)
    for n in range(upto + 1):
        if all(vals[:n]):           # 所有更小者成立
            vals[n] = P(n)
        else:
            vals[n] = False         # 前提断裂（不应发生）
    return vals

P = lambda n: n * n >= 0            # 恒真谓词
vals = strong_induction_check(P, 20)
assert all(vals)
print("  强归纳在 ℕ 上可用——良序的推论（定理 15 的使用侧）")

# ------------------------------------------------------------------
# 四、选择函数的"数据 vs 公理"： Vitali 式构造的影子
# ------------------------------------------------------------------

# ℚ/ℤ 的等价类（x~y ⟺ x-y∈ℤ）：每类选一个代表需要选择
# 在 [0,1) 的有限网格上模拟等价类划分
from fractions import Fraction

grid = [Fraction(k, 60) for k in range(60)]
# 模 1/6 的等价类（x~y ⟺ x-y ∈ (1/6)ℤ）——6 个类
classes = {}
for x in grid:
    r = x % Fraction(1, 6)
    classes.setdefault(r, []).append(x)

print(f"\n  [0,1) 网格模 1/6 的等价类：{len(classes)} 个")
reps = [min(v) for v in classes.values()]     # 选择函数 = 最小元
print(f"  用『最小元』选择函数取代表：{[str(r) for r in sorted(reps)]}")
assert len(reps) == 10 and all(len(v) == 6 for v in classes.values())

# 关键对照：最小元选择函数存在是因为每个类是**良序的有限集**；
# 对 ℚ/ℤ（可数无穷多个稠密集），最小元不存在（类在 ℝ 中稠密
# 无最小），必须诉诸 AC——这就是 Vitali 构造的"选择点"。
print("  对照：Vitali 的 ℚ-等价类在 ℝ 中稠密、无最小元——")
print("  最小元策略失效，代表的存在必须诉诸 AC。")

print("END ====")
