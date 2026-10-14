# 第 57 章：关系的机器化（Makinson Ch2）
# 关系代数（join/投影/选择）+ 闭包两法对照 + 划分↔等价往返 + Hasse 骨架
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import product

print("==== 57")

D3 = [0, 1, 2]
PAIRS = list(product(D3, repeat=2))

# ---------- 一、512 关系普查（与 Coq/Julia 交叉验证） ----------
def rel_of(mask):
    return frozenset(PAIRS[i] for i in range(9) if (mask >> i) & 1)

def has(r, p): return p in r
def refl(r): return all(has(r, (a, a)) for a in D3)
def sym(r): return all(not has(r, p) or has(r, (p[1], p[0])) for p in PAIRS)
def trans(r):
    return all(not (p in r and q in r and p[1] == q[0]) or (p[0], q[1]) in r
               for p in PAIRS for q in PAIRS)
def antisym(r):
    return all(not (p in r and q in r and p[1] == q[0] and q[1] == p[0]) or p[0] == q[0]
               for p in PAIRS for q in PAIRS)

census = dict(
    自反=sum(refl(rel_of(m)) for m in range(512)),
    对称=sum(sym(rel_of(m)) for m in range(512)),
    传递=sum(trans(rel_of(m)) for m in range(512)),
    反对称=sum(antisym(rel_of(m)) for m in range(512)),
    等价=sum(refl(r := rel_of(m)) and sym(r) and trans(r) for m in range(512)),
    偏序=sum(refl(r := rel_of(m)) and antisym(r) and trans(r) for m in range(512)),
)
print("  三点集普查：", census)
assert census == dict(自反=64, 对称=64, 传递=171, 反对称=216, 等价=5, 偏序=19)

# ---------- 二、关系代数：书本数字例子 + 选择 ----------
A, B, C = [2, 3, 13], [12, 15, 17], [11, 16, 21]
R = {(a, b) for a, b in product(A, B) if b % a == 0}
S = {(b, c) for b, c in product(B, C) if b % 2 == c % 2}
join = {(a, b, c) for (a, b) in R for (b2, c) in S if b == b2}
proj_A = {a for (a, b, c) in join}
proj_AC = {(a, c) for (a, b, c) in join}
selection = {p for p in R if p[0] in {2, 3}}       # 限制到 A' = {2,3}
print("  R =", sorted(R), " S =", sorted(S))
print("  |join| =", len(join), "（书本答案 4）")
print("  投影到 A：", sorted(proj_A), " 投影到 A×C：", sorted(proj_AC))
print("  选择 A'={2,3}：", sorted(selection))
assert len(join) == 4 and proj_AC == {(2, 16), (3, 16), (3, 11), (3, 21)}

# ---------- 三、闭包两法对照：迭代 vs 反复平方 ----------
def closure_iter(r, dom):
    cl = set(r)
    changed = True
    while changed:
        changed = False
        for (a, b) in list(cl):
            for (b2, c) in r:
                if b == b2 and (a, c) not in cl:
                    cl.add((a, c)); changed = True
    return frozenset(cl)

def closure_squaring(r, dom):
    cl, base = set(r), set(r)
    n = len(dom)
    while True:
        nxt = cl | {(a, c) for (a, x) in cl for (x2, c) in cl if x == x2}
        if nxt == cl: return frozenset(cl)
        cl = nxt

cycle = {(0, 1), (1, 2), (2, 0)}
ci, cs = closure_iter(cycle, D3), closure_squaring(cycle, D3)
print("  三点环闭包（迭代 = 反复平方）：", ci == cs, " 大小 =", len(ci))
assert ci == cs == frozenset(PAIRS)

# (R⁺)⁻¹ = (R⁻¹)⁺
conv = lambda r: {(b, a) for (a, b) in r}
assert conv(closure_iter(cycle, D3)) == closure_iter(conv(cycle), D3)
print("  (R⁺)⁻¹ = (R⁻¹)⁺ ✓")

# ---------- 四、划分 ↔ 等价 往返 ----------
def classes_from_rel(r, dom):
    cls = []
    for a in dom:
        s = frozenset(b for b in dom if (a, b) in r)
        if s not in cls: cls.append(s)
    return cls

def rel_from_classes(cls):
    return frozenset((a, b) for c in cls for a in c for b in c)

parity = frozenset((a, b) for a, b in product(D3, repeat=2) if a % 2 == b % 2)
parts = classes_from_rel(parity, D3)
back = rel_from_classes(parts)
print("  奇偶等价 → 划分：", sorted(map(sorted, parts)))
print("  划分 → 等价 复原：", back == parity)
assert back == parity and sorted(map(sorted, parts)) == [[0, 2], [1]]

# 同素因子集：书本 Exercise 2.5.4 (b)
def prime_factors(n):
    return frozenset(p for p in range(2, n + 1)
                     if n % p == 0 and all(p % d for d in range(2, p)))
grp = {}
for n in range(2, 17):
    grp.setdefault(prime_factors(n), []).append(n)
print("  同素因子划分（2..16）：", sorted(grp.values()))
assert len(grp) == 10

# ---------- 五、Hasse 骨架：整除于 2..13 的立即前驱 ----------
dom = list(range(2, 14))
dvd = {(a, b) for a, b in product(dom, repeat=2) if a != b and b % a == 0}
covers = {(a, b) for (a, b) in dvd
          if not any((a, x) in dvd and (x, b) in dvd
                     for x in dom if x not in (a, b))}
print("  立即前驱（书本答案 9 对）：", sorted(covers))
assert len(covers) == 9

# 极小元 = 素数（2,3,5,7,11,13）：没有任何 b ≠ a 使 b ∣ a
minimals = [a for a in dom if not any((b, a) in dvd for b in dom if b != a)]
print("  极小元（恰为素数）：", minimals)
assert minimals == [2, 3, 5, 7, 11, 13]

print("END ====")
