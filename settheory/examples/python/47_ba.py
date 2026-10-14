# 第 47 章：B₃ 的 256 元 Lindenbaum + 有限素理想定理
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 47")

from itertools import product
import random

# ---------- B₃：公式 = 8 行真值表上的 0/1 向量 ----------
n_var = 3
n_row = 2 ** n_var
universe = list(product((0, 1), repeat=n_row))   # 256 个等价类

meet = lambda u, v: tuple(min(x, y) for x, y in zip(u, v))
join = lambda u, v: tuple(max(x, y) for x, y in zip(u, v))
bnot = lambda u: tuple(1 - x for x in u)
BOT, TOP = (0,) * n_row, (1,) * n_row
le = lambda u, v: meet(u, v) == u

print(f"B₃：{len(universe)} 元 = 2^(2^{n_var}) ✓")
atoms = [u for u in universe if sum(u) == 1]
print(f"原子数 = {len(atoms)} = 2^{n_var} ✓")

# De Morgan / 补唯一 全扫（256×256 组合）
for u in universe:
    assert bnot(bnot(u)) == u
    for v in universe:
        assert bnot(join(u, v)) == meet(bnot(u), bnot(v))
        assert bnot(meet(u, v)) == join(bnot(u), bnot(v))
        if meet(u, v) == BOT and join(u, v) == TOP:
            assert u == bnot(v)          # 补唯一
print("双重补、De Morgan、补唯一律全扫通过（256² 组合）")

# ---------- 有限素理想定理 ----------
# 有限 BA 的超滤子必主：U_a = {b : a ≤ b}，a 原子

def is_ultra(U):
    """U ⊆ universe：滤子（上闭 + ∧ 封闭 + 含顶）且超（b 与 ¬b 恰一在）"""
    if TOP not in U or BOT in U: return False
    G = set(U)
    for u in G:
        for v in universe:
            if le(u, v) and v not in G: return False
    for u in G:
        for v in G:
            if meet(u, v) not in G: return False
    return all((u in G) != (bnot(u) in G) for u in universe)

principal = {a: frozenset(b for b in universe if le(a, b)) for a in atoms}
for a, U in principal.items():
    assert is_ultra(U)
print(f"主超滤子恰 {len(principal)} 个（每原子一个），全部验证为超滤 ✓")

# 主超滤的计数检查：原子行固定 1，其余 7 行自由 → |U_a| = 2^7
for a, U in principal.items():
    assert len(U) == 2 ** (n_row - 1)
print(f"每个 |U_a| = 2^7 = {2 ** (n_row - 1)} ✓")

# PIT 有限验证：随机预滤（全体有限交 ≠ ⊥）都能扩成某个主超滤
# 注意：预滤要求"任何有限子族之交 > ⊥"——只查两两相容不够！
# （机器当场抓出反例：三元两两相容但三重交 = ⊥）
random.seed(46)

def meet_all(H):
    m = TOP
    for u in H:
        m = meet(m, u)
    return m

def is_prefilter(H):
    return bool(H) and meet_all(H) != BOT

n_try = 0
for _ in range(500):
    k = random.randint(1, 4)
    H = random.sample([u for u in universe if u != BOT], k)
    if not is_prefilter(H): continue
    n_try += 1
    # 有限 BA 原子化：总交 m ≠ ⊥ ⟹ 有原子 a ≤ m ⟹ H ⊆ U_a
    m = meet_all(H)
    assert any(a in principal and m in principal[a] and
               all(u in principal[a] for u in H) for a in atoms)
print(f"PIT 有限验证：{n_try} 个随机预滤全部扩成主超滤 ✓")
print("（有限 BA 上超滤 = 原子主超滤——无限世界里 PIT 才需要 Zorn）")

print("END ====")
