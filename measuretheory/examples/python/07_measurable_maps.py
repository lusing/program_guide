print("==== 07 measurable_maps")
# 第 07 章 Python 通道：σ(f) 的精确集合版 + 生成系原像检查（习题 2.1.1）。
# Ω = {1..8}, f 三纤维；E 侧生成系 C = {{1},{2}}（生成 E = {1,2,3} 的幂集）。

import itertools

OMEGA = tuple(range(1, 9))
f = {1: 1, 2: 1, 3: 2, 4: 2, 5: 3, 6: 3, 7: 3, 8: 3}
fibers = {v: frozenset(k for k in OMEGA if f[k] == v) for v in (1, 2, 3)}

def sigma_of_preimages():
    """σ(f)：全体纤维并。"""
    out = set()
    for bits in itertools.product((0, 1), repeat=3):
        s = frozenset().union(*(fibers[v] for v, b in zip((1, 2, 3), bits) if b))
        out.add(s)
    return out

sigma_f = sigma_of_preimages()
assert len(sigma_f) == 8
assert frozenset({5, 6, 7, 8}) in sigma_f and frozenset() in sigma_f
# σ-代数封闭自检
for A in sigma_f:
    assert frozenset(OMEGA) - A in sigma_f
    for B in sigma_f:
        assert A | B in sigma_f
print("sigma(f) = fiber unions, |sigma(f)| = 8, closed under compl/union: OK")

# --- 习题 2.1.1 机器版：σ(f⁻¹(C)) = σ(f)，C = {{1},{2}} ---
preimages = [frozenset(k for k in OMEGA if f[k] == 1),
             frozenset(k for k in OMEGA if f[k] == 2)]
# 从 C 的原像生成：补 + 有限并闭包（Ω 有限，迭代至不动点即 σ(·)）
def close(family):
    fam = set(family)
    while True:
        new = set(fam)
        for A in fam:
            new.add(frozenset(OMEGA) - A)
        for A, B in itertools.product(fam, repeat=2):
            new.add(A | B)
        if new == fam:
            return fam
        fam = new

sigma_pre = close(preimages)
assert sigma_pre == sigma_f
print("sigma(f^-1(C)) == sigma(f) (exercise 2.1.1 machine version): OK")

# --- 因子定理（精确计数，与 Julia 对拍） ---
n_meas = 0
for g in itertools.product((0, 1, 2), repeat=8):
    gd = dict(zip(OMEGA, g))
    const_on = all(gd[i] == gd[next(iter(fibers[v]))] for v in (1, 2, 3) for i in fibers[v])
    levels = [frozenset(k for k in OMEGA if gd[k] == v) for v in set(gd.values())]
    assert const_on == all(L in sigma_f for L in levels)
    if const_on:
        n_meas += 1
assert n_meas == 27
print("factor theorem: measurable count = 27 of 6561 (matches Julia): OK")

# --- [f<a] 与 [f≤a] 的互转（实值版五条件的转换内核） ---
vals = {1: 0.5, 2: 1.5, 3: 2.5}   # 常义演示：h = f∘fibers
for a in (1.0, 2.0, 3.0):
    lt = frozenset(k for k in OMEGA if vals[f[k]] < a)
    # [f<a] = ⋃_n [f ≤ a - 1/(n+1)]
    union = frozenset()
    for n in range(1, 60):
        union |= frozenset(k for k in OMEGA if vals[f[k]] <= a - 1.0 / n)
    assert lt == union
print("strict/non-strict conversion [f<a] = Union_n [f <= a - 1/n]: OK")

print("END ====")
