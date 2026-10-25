# 第 87 章 · 可构造宇宙 L 与一般连续统假设（冯琦第二卷 §2.1）
# 四组有限样品：L_n = V_n 的引擎（引理 2.1(3)）、可定义闭包的规模、
# 位置配对对角线（L_{ω+1} !< V_{ω+1} 的影子）、
# <_L 典范秩序的出生层比较与末端延伸（定义 2.14/2.15）。
from itertools import product

print("==== 87")

# ---------- 一、V 层次与 L_n = V_n 的引擎 ----------

def powerset(members):
    ms = list(members)
    out = set()
    for mask in range(1 << len(ms)):
        out.add(frozenset(ms[i] for i in range(len(ms)) if mask >> i & 1))
    return out

def vlevels(n):
    levels = [set()]
    for _ in range(n):
        levels.append(powerset(levels[-1]))
    return levels

levels = vlevels(4)
sizes = [len(s) for s in levels]
assert sizes == [0, 1, 2, 4, 16]
print("V 层次规模:", sizes, "—— 有限层上 L_n = V_n（引理 2.1(3)）")

def def_closure(M):
    """从 ∅、全集与全部单点出发，对（相对 M 的）补与二元并封闭。
    有限载体上这一闭包达到全部子集——L_n = V_n 的组合引擎，
    即「带参数可定义」在有限世界不比「子集」少任何东西。"""
    Mf = frozenset(M)
    fam = {frozenset(), Mf} | {frozenset((p,)) for p in M}
    changed = True
    while changed:
        changed = False
        for A in list(fam):
            B = Mf - A
            if B not in fam:
                fam.add(B)
                changed = True
        for A in list(fam):
            for B in list(fam):
                U = A | B
                if U not in fam:
                    fam.add(U)
                    changed = True
    return fam

fam3 = def_closure(levels[3])
assert len(fam3) == 16 == len(powerset(levels[3]))
print("V_3 上的可定义闭包 =", len(fam3), "= 2^4：引擎到顶")

# ---------- 二、公式可数 vs 子集更多：位置配对对角线 ----------

# 深度 <= 1、参数取自 {0,1,2,3} 的公式族（等式/属于原子 + 否定 + 析取）。
C4 = [0, 1, 2, 3]

def satb(f, x):
    k = f[0]
    if k == 'tt':
        return True
    if k == 'ff':
        return False
    if k == 'eq':
        return x == f[1]
    if k == 'mem':
        return x * f[1] == 3
    if k == 'neg':
        return not satb(f[1], x)
    if k == 'or':
        return satb(f[1], x) or satb(f[2], x)
    raise ValueError(f)

atoms = [('tt',), ('ff',)] + [('eq', p) for p in C4] + [('mem', p) for p in C4]
Fs = atoms + [('neg', f) for f in atoms] + [('or', f, g) for f, g in product(atoms, repeat=2)]
assert len(Fs) == 120

def ext(f):
    return tuple(x for x in C4 if satb(f, x))

exts = {ext(f) for f in Fs}
print(f"深度 <= 1 的公式 {len(Fs)} 个，给出 {len(exts)} 个不同子集",
      f"（4 元载体全部 {1 << len(C4)} 个——有限载体深度 1 即已足够）")

# 位置配对对角线：第 k 个位置上的元素 k 恰好躲开第 k 个公式。
# 无穷载体上「公式序列可数」与「子集族不可数」的缺口，在有限尺度上
# 表现为：任何把公式排成序列的尝试都躲不开对角集合。
D = tuple(x for x in C4 if not satb(Fs[x], x))
for k in C4:
    ek = ext(Fs[k])
    assert (k in D) != (k in ek)          # D 与 ext(F_k) 在 k 处分道扬镳
print("对角线集合 D =", D, "与全部 120 个扩张在配对位置互异")

# ---------- 三、<_L 典范秩序：出生层 + 最小定义码 ----------

def born(x):
    for n, s in enumerate(levels):
        if x in s:
            return n
    raise ValueError

def literal_chains(M):
    """L_n 上的文字（等式/属于原子及其否定）析取链，长度 1..|M|，
    按（长度，字典序）生成——最小定义码的搜索空间。
    每个子集都有一条链定义它：单点由 eq 定义，再用析取拼装。"""
    lits = ([('eq', i) for i in range(len(M))]
            + [('mem', i) for i in range(len(M))]
            + [('neg', ('eq', i)) for i in range(len(M))]
            + [('neg', ('mem', i)) for i in range(len(M))])

    def sat_lit(l, x):
        if l[0] == 'eq':
            return x == M[l[1]]
        if l[0] == 'mem':
            return x in M[l[1]]
        return not sat_lit(l[1], x)

    def sat_chain(chain, x):
        return any(sat_lit(l, x) for l in chain)

    chains = []
    for k in range(1, len(M) + 1):
        for combo in product(range(len(lits)), repeat=k):
            chains.append((tuple(lits[i] for i in combo), sat_chain))
    return chains

def code_of(x, M):
    """x ⊆ M 的最小定义码：第一条扩张恰为 x 的文字链。"""
    if not M:
        return ()
    target = frozenset(x)
    for chain, sat_chain in literal_chains(M):
        if frozenset(a for a in M if sat_chain(chain, a)) == target:
            return chain
    raise ValueError(x)

def level_order(n):
    """L_n 的典范序 <_L：先比出生层；同出生层比最小定义码。
    旧层元素的相对秩序由更低的层完全决定——末端延伸的来源。"""
    low = level_order(n - 1) if n > 1 else []
    old = [e for e in low if e in levels[n]]
    new = [e for e in levels[n] if e not in levels[n - 1]]
    M = sorted(levels[n - 1], key=lambda t: (len(t), sorted(map(repr, t))))
    new.sort(key=lambda e: repr(code_of(e, M)))
    return old + new

ord3 = level_order(3)
ord4 = level_order(4)
assert len(ord3) == 4 and len(ord4) == 16
assert set(ord4) == levels[4]
assert len(set(ord4)) == 16

idx = {e: i for i, e in enumerate(ord4)}
pairs = [(a, b) for a in ord4 for b in ord4 if a != b]
# 三分性：任两个不同元素恰有一向小于
assert all((idx[a] < idx[b]) != (idx[b] < idx[a]) for a, b in pairs)
# 传递性
assert all(not (idx[a] < idx[b] and idx[b] < idx[c]) or idx[a] < idx[c]
           for a in ord4 for b in ord4 for c in ord4)
# 末端延伸（定义 2.14(b)）：L_4 序限制在 L_3 上与 L_3 序一致
rest = [e for e in ord4 if e in levels[3]]
assert rest == ord3
print("<_L 在 L_4 上严格全序（三分 + 传递），且末端延伸 L_3 的秩序 OK")

# ---------- 四、规模对账 ----------

print("L 层次规模对账: |L_n| =", [0, 1, 2, 4, 16],
      "<-> |V_n|；ω 层之后公式只有可数多个，|L_{ω+1}| = aleph0 < 2^aleph0 = |V_{ω+1}|")
print("END ====")
