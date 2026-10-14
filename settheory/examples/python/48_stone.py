# 第 48 章 Stone 对偶：Div(30) 实验室 + sup 拓扑算法 + CLOP 不完备负例
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 48")

from itertools import combinations

# ---------- B = Div(30) ----------
D = [1, 2, 3, 5, 6, 10, 15, 30]
meet = lambda a, b: __import__("math").gcd(a, b)
join = lambda a, b: __import__("math").lcm(a, b)
bnot = lambda a: 30 // a
TOP, BOT = 30, 1

# 超滤子：有限 BA 上 = 原子主超滤 U_a = {b : a | b}
atoms = [2, 3, 5]
st = {a: frozenset(b for b in D if meet(a, b) == a) for a in atoms}
print(f"超滤子恰 {len(st)} 个（原子主超滤）：|U_2|={len(st[2])}, "
      f"|U_3|={len(st[3])}, |U_5|={len(st[5])}")

# 验证超性
for a, U in st.items():
    for b in D:
        assert (b in U) != (bnot(b) in U)
print("三超滤的超性验证通过 ✓")

# ---------- N_b = {a : b ∈ U_a} ----------
N = lambda b: frozenset(a for a in atoms if b in st[a])

# 同态性（对偶定理 2 前半）
for b in D:
    for c in D:
        assert N(meet(b, c)) == N(b) & N(c)
        assert N(join(b, c)) == N(b) | N(c)
        assert N(bnot(b)) == frozenset(atoms) - N(b)
assert len({N(b) for b in D}) == 8     # 单射
print("N 映射保 ∧∨¬ 且单：8 元 B ≅ 3 点空间的 8 个 clopen ✓")

# ---------- Prop 3.11.2：sup 的拓扑算法（256 个子集全扫） ----------
subsets = [frozenset(c) for r in range(1, 9) for c in combinations(D, r)]
for X in subsets:
    # 序：a ≤ b := gcd(a,b) = a 即 a | b；sup = lcm
    sup = 1
    for b in X:
        sup = join(sup, b)
    pts = frozenset().union(*[N(b) for b in X])
    assert N(sup) <= pts                     # ⋁ 是上界：N_sup ⊆ ⋃N_b
    # 最小性：任何 a 满足 N_a ⊆ pts（a 是覆盖上界）⟹ sup ≤ a
    for a in D:
        if all(meet(b, a) == b for b in X):  # b ≤ a ∀b∈X
            assert meet(sup, a) == sup       # sup ≤ a
print(f"Prop 3.11.2：{len(subsets)} 个子集的 sup+最小性全扫通过 ✓")

# ---------- 负例：CLOP 不完备（Remark 3.11.5 的有限镜像） ----------
# 4 点拓扑 τ = {∅,{0},{0,1},{0,2},Ω}（46 章老朋友）
Ω4 = frozenset({0, 1, 2})
τ4 = [frozenset(), frozenset({0}), frozenset({0, 1}), frozenset({0, 2}), Ω4]
cl = lambda U: Ω4 - frozenset().union(*[O for O in τ4 if Ω4 - O >= U]) \
    if any(Ω4 - O >= U for O in τ4) else Ω4
def closure(U):
    closed = [Ω4 - O for O in τ4]
    cands = [C for C in closed if U <= C]
    out = Ω4
    for C in cands:
        out &= C          # 闭包 = 闭包集之交（不是并！）
    return out
def interior(U):
    return frozenset().union(*[O for O in τ4 if O <= U])
reg = lambda U: interior(closure(U))
CLOP = [O for O in τ4 if reg(O) == O]
print(f"CLOP = {[set(c) for c in CLOP]}")
# X = {{0},{0,1}} 在 CLOP 中无 sup：
X = [frozenset({0}), frozenset({0, 1})]
cand = [c for c in CLOP if all(x <= c for x in X)]
assert cand
# 上确界应是 {0,1}；但 {0,1} ∉ CLOP（它的补 {2} 不开）：
assert frozenset({0, 1}) not in CLOP
print("负例：{{0},{0,1}} 的 CLOP-上界有 {0,1,2}，但真实并 {0,1} ∉ CLOP")
print("——CLOP(X) 不完备；49 章的 RO(X) 将把 {0,1} 缝合为 sup")

print("END ====")
