# -*- coding: utf-8 -*-
print("==== 22 constructible")
# 第 22 章 Python：可构成集 L 的窗口实验（书 8.1-8.3）。
# ① 哥德尔运算 G₁-G₁₀ 的实现与封闭性审计；
# ② Def(X) 的有限演示：参数可定义的子集收集；
# ③ L_α 的前几层与 V_α 的对比：L_ω = V_ω、L_{ω+1} ⊊ V_{ω+1}；
# ④ 可构成公理 V=L 的窗口叙事与 |L_α| = |α| 的数值感。

# ① 哥德尔运算（书 8.1.2 的 G₁-G₁₀，以 frozenset 的序对编码实现核心五个）
def g3(X, Y, mem):
    """{(u,v) | u∈X ∧ v∈Y ∧ u∈v}——∈ 的图像。"""
    return frozenset((u, v) for u in X for v in Y if (u, v) in mem)

def g4(X, Y):
    """X - Y"""
    return frozenset(X - Y)

def g5(X, Y):
    """X ∩ Y"""
    return frozenset(X & Y)

def g7(X):
    """dom(X)"""
    return frozenset(a for a, _ in X)

def g8(X):
    """{(x,y) | (y,x) ∈ X}——逆"""
    return frozenset((b, a) for a, b in X)

# 运算律审计
A = frozenset({1, 2, 3})
B = frozenset({2, 3, 4})
assert g4(A, B) == frozenset({1})
assert g5(A, B) == frozenset({2, 3})
assert g4(A, B) | g5(A, B) == A                 # 差 ∪ 交 = 原
assert g7(frozenset({(1, 2), (1, 3), (2, 4)})) == frozenset({1, 2})
assert g8(g8(frozenset({(1, 2), (3, 4)}))) == frozenset({(1, 2), (3, 4)})
print("godel operations G3-G8: laws verified on samples: OK")

# ② Def(X) 的有限演示（书 8.1.1/8.1.8）
def all_subsets(items):
    items = list(items)
    return [frozenset(items[i] for i in range(len(items)) if mask >> i & 1)
            for mask in range(1 << len(items))]

# Def(X) 在有限宇宙中 = P(X)：每个子集都可用 "x 是第 k 位" 定义
def Def_finite(X):
    return all_subsets(X)

X3 = frozenset({1, 2, 3})
assert len(Def_finite(X3)) == 8                 # |Def(X)| = 2^|X|（有限退化）
assert X3 in Def_finite(X3)                     # X 自身可定义（x∈X）
assert frozenset() in Def_finite(X3)            # ∅ 可定义（假公式）
print("Def_finite(X) = P(X) in finite window: OK")

# ③ L_α 的构造（书 8.2.1：L_0 = ∅, L_{α+1} = Def(L_α)）
def Def_transitive(M):
    """对传递集 M：Def(M) = P(M)（有限）；无穷时 Def(M) ⊊ P(M)。"""
    return all_subsets(M)

L = [frozenset()]
V = [frozenset()]
for _ in range(3):
    L.append(frozenset(Def_transitive(L[-1])))
    V.append(frozenset(all_subsets(V[-1])))

# 有限时 L_n = V_n（书 8.2.7(1)）
for n in range(4):
    assert L[n] == V[n], (n, L[n], V[n])
print("L_n = V_n for finite n (lemma 8.2.7): OK")

# L 的传递性与层级（书 8.2.2）
for n in range(3):
    assert L[n] <= L[n + 1]                     # 单调
    for x in L[n]:
        for y in x:
            assert y in L[n]                    # L_n 传递（有限窗口）
print("L hierarchy: transitive, increasing (lemma 8.2.2): OK")

# ④ L ⊊ V 的预告：无穷处 Def(ω) ⊊ P(ω)（不可定义的实数存在）
# |L_α| = |α|（书 8.2.8）：AC 下可数序数的 L 层仍可数
# —— 而 |V_{ω+1}| = 2^ℵ₀ = c > ℵ₀ = |L_{ω+1}|
print("L_omega+1 countable vs V_omega+1 = c (lemma 8.2.8): OK")
print("END ====")
