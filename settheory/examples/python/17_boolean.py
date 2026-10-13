# 第 17 章 完备布尔代数：Stone 表示与完备化的数值实验

import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 17 完备布尔代数")

# 一、有限布尔代数的原子分解（习题 17.5）
# k 个生成元 → ≤ 2^{2^k} 个元素

def finite_ba_from(k):
    """从 k 个生成元构造有限布尔代数的元素表（析取范式）"""
    if k == 0:
        return [0, 1]
    n = 2 ** k
    # 元素 = 原子集的子集（每个元素是原子指标的位向量）
    from itertools import combinations
    elements = []
    for r in range(n + 1):
        for combo in combinations(range(n), r):
            mask = sum(1 << i for i in combo)
            elements.append(mask)
    return elements

for k in [0, 1, 2]:
    ba = finite_ba_from(k)
    expected = 2 ** (2 ** k)
    print(f"  k={k} 生成元：|B| = {len(ba)}（≤ 2^{2^k} = {expected}）")
    assert len(ba) == expected

# 二、完备化（讲义）
print("\n  完备化（Theorem 42）：B 嵌入完备 cBa C（正则开集代数）")
print("  分离性 (17.20)：p⊥q ⟹ ∃r≤p, r⊥q——分离性偏序的 r.o.(P)")
print("  r.o.(P) = {正则割 U：p⊑q∧q∈U→p∈U，且 p∉U 时 ∃q≤p, V_q∩U=∅}")
print("  = P 上正则开集的完备布尔代数（Lemma 17.2）")

print("END ====")
