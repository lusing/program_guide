# 第 08 章 奇异基数：eventual dominance 范数的计算实验
#
# Galvin-Hajnal（定理 24）的引擎：关系 φ < ψ（club-模意义上
# "ψ 最终支配 φ"）是良基的，rank = ‖φ‖（范数）。
# 有限域的代理：最终支配（eventual dominance）+ 严格降链终止。

import sys
import io
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 08 奇异基数：支配范数")

# ------------------------------------------------------------------
# 一、最终支配关系 <*
# φ <* ψ ⟺ 对充分大的 i：φ(i) < ψ(i)
# ------------------------------------------------------------------

def eventually_dominates(psi, phi, threshold=None):
    """ψ 最终支配 φ：存在 B 使 i ≥ B ⟹ φ(i) < ψ(i)"""
    n = len(psi)
    for B in range(n):
        if all(phi[i] < psi[i] for i in range(B, n)):
            return True
    return False

f = (1, 5, 2, 9, 3)
g = (2, 6, 7, 8, 4)
assert eventually_dominates(g, f)      # 从 0 起就支配
print(f"  g={g} 最终支配 f={f} ✓（从 0 起逐点大）")

h = (9, 9, 1, 1, 1)
assert eventually_dominates(f, h)      # f 从 2 起支配 h
print(f"  f={f} 最终支配 h={h} ✓（前 2 个点不管，其后逐点大）")

# ------------------------------------------------------------------
# 二、严格降链终止（良基性的数值影子）
# φ > φ1 > φ2 > ... （<* 意义下）必有限——有限域显然，
# 无穷域由 club 滤子的 σ-完备性保证（§8 (8.7) 后的论证）。
# ------------------------------------------------------------------

def chain_length(phi):
    """贪心降链：每步取'逐点 -1'直到零——终长度是 max(φ)+1"""
    steps = 0
    cur = list(phi)
    while any(v > 0 for v in cur):
        cur = [max(v - 1, 0) for v in cur]
        steps += 1
    return steps

print(f"\n  [3,1,4,1,5] 的降链长度 = {chain_length([3,1,4,1,5])}（= max+1）")
assert chain_length([3, 1, 4, 1, 5]) == 5

# ------------------------------------------------------------------
# 三、范数分层的应用形态（引理 8.7 的使用侧）
# |F| ≤ ℵ_{ω₁} + ‖φ‖：把几乎不交族按范数分箱，每箱有界。
# ------------------------------------------------------------------

def norm_class(phi):
    """范数的粗分类（有限代理）：max(φ)"""
    return max(phi)

phis = [(1, 2, 3), (5, 5, 5), (9, 1, 1), (0, 0, 0), (4, 4, 4)]
bins = {}
for p in phis:
    bins.setdefault(norm_class(p), []).append(p)
for k in sorted(bins):
    print(f"  范数 {k} 的箱：{len(bins[k])} 个函数 {bins[k]}")
print("  ‖φ‖=0 ⟺ φ 在平稳集上为 0（引理 8.5 的情形）")
print("  范数每升一层，箱的上界抬一档（归纳结构）——Silver 链条。")

print("END ====")
