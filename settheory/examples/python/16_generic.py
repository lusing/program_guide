# 第 16 章 泛型扩张：Rasiowa-Sikorski 构造与泛型实数验证

import sys
import io
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 16 泛型扩张：RS 构造")

# ------------------------------------------------------------------
# 一、Cohen 偏序与塔构造
# ------------------------------------------------------------------

def is_prefix(p, q):
    return len(p) <= len(q) and p == q[:len(p)]

def first_above(p, D):
    """D 中第一个延伸 p 的条件（线性扫描）"""
    for q in D:
        if is_prefix(p, q):
            return q
    return p

def rs_tower(p0, D_list):
    """Rasiowa-Sikorski 塔构造（引理 16.1 的算法核心）"""
    p = list(p0)
    chain = [list(p)]
    for D in D_list:
        p = first_above(p, D)
        chain.append(list(p))
    return chain

# ------------------------------------------------------------------
# 二、有限偏序上的泛型滤波器验证
# ------------------------------------------------------------------

# 偏序 P = 全体 ≤4 位 0/1 序列（包括空序列）
P = [list(s) for n in range(5) for s in product([False, True], repeat=n)]

# 稠密集族：D_n = {p : |p| ≥ min(n, 4)}
dense_family = []
for n in range(1, 5):
    Dn = [p for p in P if len(p) >= min(n, 4)]
    dense_family.append(Dn)

# 构造塔
chain = rs_tower([], dense_family)
print(f"  塔构造：起始 ∅，{len(dense_family)} 层后长度 = {len(chain[-1])}")
print(f"  塔链：{[len(p) for p in chain]}")

# 验证泛型滤波器公理 (16.2)
G = chain  # 塔就是（有限版的）泛型滤波器
# (i) 非空
assert len(G) > 0
# (ii) 链性（前缀两两可比较）
for i in range(len(G)):
    for j in range(i+1, len(G)):
        assert is_prefix(G[i], G[j]) or is_prefix(G[j], G[i]), (i, j)
# (iii) 有向：塔的公共下方 = 前面的元素
for i, j in [(0, 2), (1, 3), (0, 3)]:
    lo = min(i, j)
    assert is_prefix(G[lo], G[i]) and is_prefix(G[lo], G[j])
print("  (16.2) 三公理验证 ✓（非空/链性/有向）")

# 验证泛型性 (16.3)(ii)：G ∩ D_n ≠ ∅
for n, D in enumerate(dense_family):
    hit = any(p in D for p in G)
    assert hit, f"layer {n} missed"
print("  (16.3)(ii) 泛型性 ✓：每层塔命中对应稠密集")

# ------------------------------------------------------------------
# 三、Cohen 实数的"新"（讲义）
# ------------------------------------------------------------------

print("\n  定理 39/40 的语义（讲义）：")
print("  𝔐[G] ⊨ ZFC（泛型模型定理）")
print("  𝔐[G] ⊨ σ ⟺ ∃p∈G, p ⊩ σ（力迫定理）")
print("  f = ⋃G 是新实数：D_g = {p : ∃n, p(n) ≠ g(n)} 稠密")
print("  ⟹ f ≠ g 对一切地面模型 g（Cohen 1963 的引擎）")

print("END ====")
