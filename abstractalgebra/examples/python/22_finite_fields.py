# 第 22 章 · 商环与有限域 —— Python 通道

from itertools import product, permutations

print("==== 22 商环与有限域")


# ---------- GF(p^d) 引擎 ----------
def polymul_mod(f, g, mp, p):
    r = [0] * (len(f) + len(g) - 1)
    for i, a in enumerate(f):
        for j, b in enumerate(g):
            r[i + j] = (r[i + j] + a * b) % p
    while len(r) >= len(mp) and any(r):
        s = len(r) - len(mp)
        c = r[-1]
        for j, mv in enumerate(mp):
            r[s + j] = (r[s + j] - c * mv) % p
        while len(r) > 1 and r[-1] == 0:
            r.pop()
    while len(r) > 1 and r[-1] == 0:
        r.pop()
    return r if r else [0]


def gf_elements(p, d):
    for cs in product(range(p), repeat=d):
        yield list(cs)


# ---------- GF(4) 全景 ----------
p4, mp4 = 2, [1, 1, 1]
ones = [1]
alpha = [0, 1]
a2 = polymul_mod(alpha, alpha, mp4, p4)
assert a2 == [1, 1]                 # α² = α+1
a3 = polymul_mod(a2, alpha, mp4, p4)
assert a3 == [1]                    # α³ = 1
# 域公理抽查：非零元 × 非零元 ≠ 0 且每非零元有逆
nonzero = [e for e in gf_elements(2, 2) if any(e)]
for u in nonzero:
    for v in nonzero:
        assert any(polymul_mod(u, v, mp4, 2))
    assert any(polymul_mod(u, w, mp4, 2) == [1] for w in nonzero)
print("GF(4)：α² = α+1、α³ = 1、非零元全可逆 ✓")

# ---------- GF(8) 双实现同构 ----------
mp8a, mp8b = [1, 1, 0, 1], [1, 0, 1, 1]     # x³+x+1 与 x³+x²+1
def norm(e, d):
    e = list(e) + [0] * (d - len(e))
    return tuple(e[:d])

def mulT(u, v, mp, p):
    d = len(mp) - 1
    return norm(polymul_mod(list(u), list(v), mp, p), d)

def order_of(u, mp, p):
    d = len(mp) - 1
    cur, one = norm([1], d), norm([1], d)
    for k in range(1, p ** d):
        cur = mulT(cur, u, mp, p)
        if cur == one:
            return k
    return None

elsA = [norm(e, 3) for e in gf_elements(2, 3)]
one = norm([1], 3)
alphaA = norm([0, 1, 0], 3)
assert order_of(alphaA, mp8a, 2) == 7
# 在双实现中找 β（mp8b 下的 7 阶元）
betaB = next(e for e in elsA if any(e) and order_of(e, mp8b, 2) == 7)

# 同构由 α ↦ β 决定：i ↦ mulT(α,i) 的索引置换
perm = {}
for e in elsA:
    perm[elsA.index(e)] = elsA.index(mulT(e, alphaA, mp8a, 2))
# φ 的定义：e ↦ 以 β 为底的"同指数"元素——用乘法表直验
# 简单做法：验证映射 idx ↦ elsA.index(mulT(e, alphaA, mp8a)) 保乘法不成立时
# 换成一般搜索。直接做严格验证（8! = 40320 可行）：
TA = {(i, j): mulT(elsA[i], elsA[j], mp8a, 2) for i in range(8) for j in range(8)}
TB = {(i, j): mulT(elsA[i], elsA[j], mp8b, 2) for i in range(8) for j in range(8)}
found = None
for pm in permutations(range(8)):
    if pm[0] != 0:                        # 零 ↦ 零
        continue
    if pm[elsA.index(one)] != elsA.index(one):   # 1 ↦ 1
        continue
    ok = True
    for i in range(8):
        for j in range(8):
            if pm[elsA.index(TA[(i, j)])] != elsA.index(TB[(pm[i], pm[j])]):
                ok = False
                break
        if not ok:
            break
    if ok:
        found = pm
        break
assert found is not None
print("GF(8)：双实现 x³+x+1 与 x³+x²+1 均有原根 α 且表同构命中 ✓")

# ---------- GF(9) 原根计数 ----------
mp9 = [1, 0, 1]                    # x²+1
prim = sum(1 for e in gf_elements(3, 2)
           if any(e) and order_of(e, mp9, 3) == 8)
assert prim == 4                   # φ(8) = 4
print("GF(9)：ℤ₃[x]/(x²+1)，原根恰 φ(8) = 4 个 ✓")

print("END ====")
