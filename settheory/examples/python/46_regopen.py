# 第 46 章：Sierpiński 空间与 4 点空间的正则开演算
# 验证 Viale Lemma 2.1.4（点态刻画）、幂等性、Fact 2.1.8
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 46")

from itertools import combinations, chain

def powerset(xs):
    xs = list(xs)
    return frozenset(frozenset(c) for r in range(len(xs) + 1)
                     for c in combinations(xs, r))

def cl(U, opens, Omega):
    closed = [Omega - O for O in opens]
    cands = [C for C in closed if U <= C]
    # 最小 = 之交
    out = Omega
    for C in cands:
        out &= C
    return out

def int_(U, opens):
    cands = [O for O in opens if O <= U]
    out = frozenset()
    for O in cands:
        out |= O
    return out

def reg(U, opens, Omega):
    return int_(cl(U, opens, Omega), opens)

def perp(U, opens, Omega):
    return Omega - cl(U, opens, Omega)

def check_topology(name, opens, Omega):
    assert frozenset() in opens and Omega in opens
    for A, B in combinations(sorted(opens, key=sorted), 2):
        assert (A | B) in opens, (name, "并封闭", A, B)
        assert (A & B) in opens, (name, "交封闭", A, B)
    print(f"{name}：拓扑公理自检通过（{len(opens)} 个开集）")

# ---------- 例一：Sierpiński 空间 ----------
Ω1 = frozenset({0, 1})
τ1 = frozenset({frozenset(), frozenset({1}), Ω1})
check_topology("Sierpiński 空间", τ1, Ω1)
print("  Cl({1}) =", set(cl(frozenset({1}), τ1, Ω1)),
      " Int(Cl({1})) =", set(reg(frozenset({1}), τ1, Ω1)))
# {1} 开非闭，但它是稠密集：Cl({1}) = Ω，故 Reg({1}) = Ω
# {0} 闭非开：Cl({0}) = {0}，Int({0}) = ∅，故 Reg({0}) = ∅
assert reg(frozenset({1}), τ1, Ω1) == Ω1
assert reg(frozenset({0}), τ1, Ω1) == frozenset()
print("  正则开集族 RO = {∅, Ω}——退化为 2 元布尔代数（Sierpiński 空间太小）")

# ---------- 例二：4 点空间（含"可缝合裂缝"） ----------
Ω2 = frozenset({0, 1, 2, 3})
τ2 = frozenset({frozenset(), frozenset({0}), frozenset({0, 1}),
                frozenset({2, 3}), frozenset({0, 2, 3}), Ω2})
check_topology("4 点空间", τ2, Ω2)

U = frozenset({0, 1}); V = frozenset({2, 3})
RU, RV = reg(U, τ2, Ω2), reg(V, τ2, Ω2)
print(f"  Reg({{{0},{1}}}) = {set(RU)}, Reg({{{2},{3}}}) = {set(RV)}")
assert reg(RU, τ2, Ω2) == RU and reg(RV, τ2, Ω2) == RV
print("  幂等性 Reg(Reg(·)) = Reg(·) 通过")

# 引理 2.1.4 点态刻画：x ∈ Reg(A) ⟺ ∃开 U∋x, A∩U 在 U 中稠密
def dense_in(A, W, opens, Omega):
    return W <= cl(A & W, opens, Omega)

for A in τ2:
    R = reg(A, τ2, Ω2)
    for x in Ω2:
        lhs = x in R
        rhs = any(x in W and dense_in(A, W, τ2, Ω2) for W in τ2)
        assert lhs == rhs, ("Lemma 2.1.4", set(A), x, lhs, rhs)
print("  Lemma 2.1.4 点态刻画逐点通过")

# Fact 2.1.8：U∩V ≠ ∅ ⟺ U∩Reg(V) ≠ ∅
for A, B in combinations(sorted(τ2, key=sorted), 2):
    assert bool(A & B) == bool(A & reg(B, τ2, Ω2))
    assert bool(A & B) == bool(reg(A, τ2, Ω2) & B)
print("  Fact 2.1.8 相交判据通过")

# ⊥ 五律（全部子集两两）
n = 0
for U in powerset(Ω2):
    for V in powerset(Ω2):
        if U <= V:
            assert perp(V, τ2, Ω2) <= perp(U, τ2, Ω2); n += 1
        assert perp(U | V, τ2, Ω2) == perp(U, τ2, Ω2) & perp(V, τ2, Ω2); n += 1
        assert reg(V, τ2, Ω2) == perp(perp(V, τ2, Ω2), τ2, Ω2); n += 1
        if U in τ2:
            assert perp(perp(U, τ2, Ω2), τ2, Ω2) == reg(U, τ2, Ω2); n += 1
            assert perp(perp(perp(U, τ2, Ω2), τ2, Ω2), τ2, Ω2) == perp(U, τ2, Ω2); n += 1
        if U in τ2 and V in τ2:
            assert perp(perp(U & V, τ2, Ω2), τ2, Ω2) == \
                   perp(perp(U, τ2, Ω2), τ2, Ω2) & perp(perp(V, τ2, Ω2), τ2, Ω2); n += 1
print(f"  ⊥ 五律共 {n} 条断言全部通过")

print("END ====")
