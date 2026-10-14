# 第 22 章 Suslin 问题：树结构与 Δ-系统
import sys, io
from fractions import Fraction
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 22 Suslin 问题")

# 一、Aronszajn 树的有理数序列构造
def rational_node(n):
    """长度 n 的递增有理数序列（Aronszajn 树节点）"""
    return [Fraction(1, k+2) for k in range(n)]

for n in [0, 3, 5]:
    node = rational_node(n)
    print(f"  层 {n} 样本：{node[:3]}…" if len(node) > 3 else f"  层 {n}：{node}")

# 二、树的增长
print("\n  Aronszajn：height=ω₁ + 层可数 + 无不可数分支（ZFC 存在）")
print("  Suslin：再加反链可数（ZFC 独立——力迫证两边）")

# 三、Δ-系统引理（Lemma 22.6）
print("\n  Δ-系统引理：不可数族 → 不可数子族使任意两元的交相同")
print("  （Suslin 树力迫的 ccc 验证核心）")

# 演示有限 Δ-系统
sets = [frozenset([i, i+1, i+2]) for i in range(0, 20, 3)]
# 找 Δ-子族
delta_family = []
for s in sets:
    if all(len(s & t) == 0 for t in delta_family if t != s):
        if len(delta_family) < 2:
            delta_family.append(s)
# 两两不交（根为空集）
print(f"  有限 Δ-系统示例：{[sorted(s) for s in delta_family]} 两两不交")
print(f"  交的大小：{[len(delta_family[0] & delta_family[1]) if len(delta_family)>1 else 0]}")

print("END ====")
