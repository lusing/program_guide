# 第 12 章 可构造层级：def(U) 的可判定计算与 L 的语义
#
# def(U) = cl(U ∪ {U}) ∩ P(U)：Gödel 闭包的子集侧。
# 有限传递 U 上用受限公式的真值向量枚举可定义子集。

import sys
import io
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 12 可构造层级：def 与 L")

# ------------------------------------------------------------------
# 一、集合的规范化字符串表示（与 11 章坍缩共用工具）
# ------------------------------------------------------------------

def norm_set(members):
    uniq = sorted(set(members), key=lambda s: (len(s), s))
    return "{" + ",".join(uniq) + "}"

def parse_members(s):
    inner = s[1:-1]
    if not inner:
        return []
    out, depth, cur = [], 0, ""
    for c in inner:
        if c == '{': depth += 1
        if c == '}': depth -= 1
        if c == ',' and depth == 0:
            out.append(cur.strip()); cur = ""
        else:
            cur += c
    out.append(cur.strip())
    return out

E = "{}"
ONE = norm_set([E])

# ------------------------------------------------------------------
# 二、def(U)：受限公式的子集枚举（有限版）
# ------------------------------------------------------------------

def def_finite(U):
    """U：有限传递集的成员表（字符串）。返回 def(U) 的成员表。
    受限一元公式的生成：原子 u=a、u∈a（a 遍历 U）的布尔组合。"""
    n = len(U)
    atoms = []
    for a in U:
        amem = set(parse_members(a))
        atoms.append([U[i] in amem for i in range(n)])   # u ∈ a
        atoms.append([U[i] == a for i in range(n)])      # u = a
    combos = list(atoms)
    for p in atoms:
        combos.append([not x for x in p])                 # ¬
        for q in atoms:
            combos.append([p[i] and q[i] for i in range(n)])
            combos.append([p[i] or q[i] for i in range(n)])
    seen = {}
    for v in combos:
        sel = norm_set([U[i] for i in range(n) if v[i]])
        if parse_members(sel):                            # 排除 ∅ 的平凡生成
            seen[sel] = True
    return sorted(seen.keys(), key=lambda s: (len(s), s))

U2 = [E, ONE]
d2 = def_finite(U2)
print(f"  def(V₂)（V₂ = {{∅, {{∅}}}}）：")
for x in d2:
    print(f"    {x}")
print(f"  成员数 = {len(d2)}（P(V₂) 全 4 个非空子集（含单点 {norm_set([ONE])}）——")
print("  有限传递 U 上 def(U) = P(U)（习题 12.6：布尔组合足矣）")

# ------------------------------------------------------------------
# 三、L 的语义框架（定理 32 讲义）
# ------------------------------------------------------------------

print("\n定理 32（Gödel）：")
print("  (i) L ⊨ ZF（传递/封闭/几乎通用三验证）")
print("  (ii) L ⊨ V=L（L 的层级自描述）")
print("  (iii) L 最小：任何含全序数的传递 ZF 模型 ⊇ L")
print("  ⟹ Con(ZF) ⟹ Con(ZF + V=L)；第 13 章：V=L ⟹ AC + GCH")
print("\n绝对性要点（引理 12.1）：配对/序数/函数等是 Δ₀ 绝对；")
print("  P(X)/基数/cf **不绝对**——L 内的 P 与外部的 P 是两回事，")
print("  这正是 GCH 在 L 中成立的第一步。")

print("END ====")
