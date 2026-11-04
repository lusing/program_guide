# -*- coding: utf-8 -*-
print("==== 126 relations")
# 第 126 章 Python：关系与函数的精确计算面。
# ① Kuratowski 有序对 {{a},{a,b}} 的暴力验证（书 2.1.3）——
#    4 元宇宙上 16×16 对全部核对：相等当且仅当坐标相等；
# ② (a,(b,c)) 型三元组的两种打包（习题 2.5.3/2.5.5）：都合格且互不相同；
# ③ 关系代数律的精确审计（习题 2.5.2/2.5.8/2.5.9）：并律成等式、
#    交律只能单向（附见证）、复合结合、逆的复合律；
# ④ 像与逆像的差别（习题 2.5.11）；
# ⑤ Y^X 的枚举与计数（含空集的边角：Y^0 与 0^X，书 2.2.11 后注）。
from itertools import product, permutations

# ① Kuratowski 有序对，照抄定义
def pair(a, b):
    return frozenset([frozenset([a]), frozenset([a, b])])

U = [0, 1, 2, 3]
ok = True
for a, b, ap, bp in product(U, U, U, U):
    same = (pair(a, b) == pair(ap, bp)) == (a == ap and b == bp)
    ok = ok and same
assert ok
assert len({pair(a, b) for a in U for b in U}) == 16   # 4×4 全不重
print("kuratowski pair: (a,b)=(a',b') iff coords equal, 4x4 universe brute force: OK")

# ② 两种三元组打包（2.5.3）：都合格（作为映射 injective）且互不相同（2.5.5）
tri_left = lambda a, b, c: pair(pair(a, b), c)         # ((a,b),c)
tri_right = lambda a, b, c: pair(a, pair(b, c))        # (a,(b,c))
for a, b, c, ap, bp, cp in product(U, U, U, U, U, U):
    assert (tri_left(a, b, c) == tri_left(ap, bp, cp)) == (a == ap and b == bp and c == cp)
    assert (tri_right(a, b, c) == tri_right(ap, bp, cp)) == (a == ap and b == bp and c == cp)
assert tri_left(0, 1, 2) != tri_right(0, 1, 2)         # (X×X)×X ≠ X×(X×X) 的微观见证
print("triples: both packings injective, and (XxX)xX != Xx(XxX) at 0,1,2: OK")

# ③ 关系代数（frozenset 关系 + frozenset 集）
def rdom(R):
    return frozenset(x for x, y in R)

def rran(R):
    return frozenset(y for x, y in R)

def rimg(R, A):
    return frozenset(y for x, y in R if x in A)

def rinverse(R):
    return frozenset((y, x) for x, y in R)

def rcomp(S, R):                                       # S∘R：先 R 后 S
    out = set()
    for x, y in R:
        for y2, z in S:
            if y == y2:
                out.add((x, z))
    return frozenset(out)

R = frozenset({(0, 'a'), (1, 'a'), (1, 'b'), (2, 'c')})
S = frozenset({('a', 'x'), ('b', 'y'), ('c', 'z'), ('x', 9)})
T = frozenset({('x', 0), ('y', 1), (9, 'w')})

# 2.5.2：并律成等式、交律与差律单向
A, B = frozenset({0, 1}), frozenset({1, 2})
assert rimg(R, A | B) == rimg(R, A) | rimg(R, B)
assert rimg(R, A & B) <= rimg(R, A) & rimg(R, B)
Rw = frozenset({(0, 'c'), (1, 'a'), (2, 'c')})        # 0 与 2 同像：交像吃掉 'c'
assert (rimg(Rw, A) & rimg(Rw, B)) - rimg(Rw, A & B) == {'c'}
assert rimg(R, A) - rimg(R, B) <= rimg(R, A - B)
print("image laws: union equality, intersection one-way (witness c): OK")

# 2.5.8/2.5.9：结合律与逆的账
assert rcomp(T, rcomp(S, R)) == rcomp(rcomp(T, S), R)
assert rinverse(rcomp(S, R)) == rcomp(rinverse(R), rinverse(S))
assert rinverse(rinverse(R)) == R
assert rdom(rinverse(R)) == rran(R) and rran(rinverse(R)) == rdom(R)
print("composition laws: assoc, (SoR)^-1 = R^-1 o S^-1, dom/ran swap: OK")

# ④ 像保交单向、逆像保交双向（2.5.11）
f = {0: 'c', 1: 'c', 2: 'd'}                           # 函数即字典
fA, fB = {0}, {1}
fimg = lambda A: frozenset(f[x] for x in A)
fpre = lambda C: frozenset(x for x, v in f.items() if v in C)
assert fimg(fA & fB) < fimg(fA) & fimg(fB)             # ∅ < {c}：严格
assert fpre({'c'} & {'c'}) == fpre({'c'}) & fpre({'c'})
print("function images: f[A^B] strict subset, preimages preserve intersection: OK")

# ⑤ Y^X：X→Y 的全部函数（有限枚举），计数与边角账
def all_funcs(X, Y):
    return [dict(zip(X, values)) for values in product(Y, repeat=len(X))]

for n, m in ((0, 0), (0, 2), (2, 0), (2, 2), (3, 2)):
    Xs, Ys = list(range(n)), list(range(m))
    fs = all_funcs(Xs, Ys)
    assert len(fs) == m ** n                           # |Y^X| = |Y|^|X|
    if n == 0 and m == 2:
        assert fs == [dict()]                          # 空函数唯一
print("Y^X: |Y^X| = |Y|^|X| audited, empty function unique: OK")
print("END ====")
