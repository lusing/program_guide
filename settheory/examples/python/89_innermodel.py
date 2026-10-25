# 第 89 章 · 内模型 HOD、L[A] 与 L(ℝ)（冯琦第二卷 §2.2）
# 四组样品：OD(V_3) = V_3 的序数参数见证（例 2.2(1)）、
# 引理 2.27(3) 等价式的数值验证、谓词原子对免参定义力的提升（定义 2.21）、
# L_n[U] = V_n 与 U 属于 L[U]（引理 2.24 的计算账）。
from itertools import product

print("==== 89")

# ---------- HF 与 V 层次 ----------

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
V2, V3, V4 = levels[2], levels[3], levels[4]
NAT = [frozenset()]
for _ in range(3):
    NAT.append(frozenset(NAT))          # 冯诺依曼 0,1,2,3

# ---------- 一、OD(V_3) = V_3（例 2.2(1)）：序数参数见证 ----------

def bex(x, cond):
    return any(cond(y) for y in x)

def ball(x, cond):
    return all(cond(y) for y in x)

witnesses = {
    NAT[0]: lambda x: x == NAT[0],                                  # x = 0（免参）
    NAT[1]: lambda x: x == NAT[1],                                  # x = 1（免参）
    NAT[2]: lambda x: x == NAT[2],                                  # x = 2（免参）
    frozenset({NAT[1]}): lambda x: (ball(x, lambda y: y == NAT[1])  # x = {1}
                                    and bex(x, lambda y: y == NAT[1])),
}
assert set(witnesses) == V3
for a, phi in witnesses.items():
    ext = {x for x in V3 if phi(x)}
    assert ext == {a}, (a, ext)
print("V_3 的四个元素全部由带序数参数的 Delta_0 公式唯一见证：OD(V_3) = V_3 OK")

# ---------- 二、引理 2.27(3) 等价式的数值验证 ----------

def tcplus(x):
    seen, todo = set(), [x]
    while todo:
        y = todo.pop()
        if y in seen:
            continue
        seen.add(y)
        todo.extend(y)
    return seen

P = lambda y: y in V3               # OD 代理：秩 <= 3（上面已全部见证）

def hered_tc(x):                    # 彻底性（TC 版，定义 2.29）
    return all(P(y) for y in tcplus(x))

def hered_split(x):                 # 分解版：P x 且每个成员彻底
    return P(x) and all(hered_tc(y) for y in x)

for x in V4:
    assert hered_tc(x) == hered_split(x)
print("V_4 全体：Hered_TC(x) = (P x 且成员全 Hered)——引理 2.27(3) 等价成立 OK")

# ---------- 三、谓词原子对免参定义力的提升（定义 2.21/2.23） ----------

def sat_free(f, x, U):              # 免参公式：tt/ff/inA/布尔
    k = f[0]
    if k == 'tt':
        return True
    if k == 'ff':
        return False
    if k == 'inA':
        return x in U
    if k == 'neg':
        return not sat_free(f[1], x, U)
    if k == 'or':
        return sat_free(f[1], x, U) or sat_free(f[2], x, U)

def free_family(U, with_pred):
    atoms = [('tt',), ('ff',)] + ([('inA',)] if with_pred else [])
    fs = atoms + [('neg', a) for a in atoms]
    fs += [('or', a, b) for a, b in product(atoms, repeat=2)]
    exts = {tuple(x for x in V2 if sat_free(f, x, U)) for f in fs}
    return exts

U = frozenset({NAT[0]})             # 谓词解释：U 含 0 不含 1
no_pred = free_family(U, False)
with_pred = free_family(U, True)
assert len(no_pred) == 2 and len(with_pred) == 4
print(f"V_2 上免参可定义子集：无谓词 {len(no_pred)} 个 -> 带谓词 {len(with_pred)} 个"
      "——U 截断进入免参定义 OK")

# ---------- 四、L_n[U] = V_n 与 U 属于 L[U]（引理 2.24 的计算账） ----------

def def_closure(M, U=None):
    """带谓词的可定义闭包：单点 + 补 + 并；U 作为免参谓词原子参与
    （有限载体上参数全开放时与 87 章引擎同一结果）。"""
    Mf = frozenset(M)
    fam = {frozenset(), Mf} | {frozenset((p,)) for p in M}
    if U is not None and frozenset(U) != frozenset() and frozenset(U) != Mf:
        fam.add(frozenset(U))
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
                W = A | B
                if W not in fam:
                    fam.add(W)
                    changed = True
    return fam

LU = def_closure(V2, U)
assert LU == powerset(V2) and len(LU) == 4
assert U in V3                       # U 属于 L_3[U]（原子公式的扩张恰为 U）
print("L[U] 有限层与 V 重合；U 截断由谓词原子免参给出，U 属于 L_3[U] OK")

print("END ====")
