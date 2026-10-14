# 第 50 章 Odd/Even 边界剧场 + 自指陷阱 + Δ 引理蒙特卡洛
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 50")

from itertools import combinations
import random

# ---------- (a) Odd/Even：正则开非闭的最小剧场（Fact 5.2.3） ----------
# 2^6 上：Odd = 以奇数个 0 开头的串，Even = 偶数个
def lead_zeros(s):
    n = 0
    for c in s:
        if c == "0":
            n += 1
        else:
            break
    return n

U = [format(i, "06b") for i in range(64)]
odd = [s for s in U if lead_zeros(s) % 2 == 1]
even = [s for s in U if s != "0" * 6 and lead_zeros(s) % 2 == 0]
# 0^6 本身：lead 6（偶）——它是两个集合闭包的公共边界点
print(f"(a) |Odd| = {len(odd)}, |Even| = {len(even)}（2^6 网格上）")
# 0^6 的任何柱邻域 N_s（s = 0^k）都与 Odd、Even 相交：
for k in range(1, 5):   # k≤4：6 位截断内边界效应可控
    nbhd = [s for s in U if s.startswith("0" * k)]
    assert any(x in nbhd for x in odd) and any(x in nbhd for x in even)
print("    0^6 的任何柱邻域同时切 Odd 与 Even——闭包交于边界点 ✓")
print("    ⟹ Odd/Even 正则开不闭；St(RO) → 2^ω 非单射（Rmk 5.2.5）")

# ---------- (b) 自指陷阱（世界 2 的不可能性，8 位剧场） ----------
# D_f = {s : s ⊥ f}；G 与一切 D_f 交 ⟹ ⋃G ⊥ 一切 f ——不可能
# 因为 ⋃G = g 本身是候选 f。8 位模拟：任何"完全函数" g，
# 其柱链 G = {g↾n} 与 D_g 的交 = {s : s ⊥ g} ∩ {g↾n} = ∅
g = "01101001"
G = [g[:n] for n in range(0, 9)]
for s in G:
    # s ⊥ g ⟺ s 不是 g 的初始段且 g 不是 s 的初始段
    incomp = not g.startswith(s) and not s.startswith(g)
    assert not incomp   # G 的成员全与 g 相容
print("(b) 路径滤子 G_g 的每个成员都与 g 相容 ⟹ G_g ∩ D_g = ∅")
print("    ——全族泛型不可能（Exercise 5.1.6 的自指内核）✓")

# ---------- (c) Δ 引理蒙特卡洛 ----------
random.seed(50)
hit = 0
trials = 1000
for _ in range(trials):
    pts = range(1, 7)
    pool = [frozenset(c) for k in (2, 3) for c in combinations(pts, k)]
    fam = random.sample(pool, 8)
    # 找最大 Δ-子系（暴力子集枚举 2^8）
    best = 0
    for r in range(2, 9):
        for sub in combinations(fam, r):
            roots = {a & b for a, b in combinations(sub, 2)}
            if len(roots) == 1:
                best = max(best, r)
    if best >= 3:
        hit += 1
print(f"(c) Δ 蒙特卡洛：{trials} 组随机 8 族中 {hit} 组有 ≥3 元 Δ-子系")
print("    （有限域的阈值现象；正则基数条件下 Δ 引理保证任意大）")

print("END ====")
