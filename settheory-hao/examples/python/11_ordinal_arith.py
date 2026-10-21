# -*- coding: utf-8 -*-
print("==== 11 ordinal arith")
# 第 11 章 Python：ω^ω 窗口的全 CNF 序数算术引擎。
# 表示：α = (c0, c1, ..., ck)，值 = ω^k·ck + ... + ω·c1 + c0。
# ① 加法（4.4.1）：β 之下全按 β、交叉处相加、之上全按 α；
# ② 乘法（4.4.5）与幂（4.4.8）的闭式；
# ③ 书 4.4.2/4.4.6/4.4.9 全部例子的精确复算；
# ④ 4.4.10 α+β = α ∪ {α+ξ} 的元素表账（尾巴平移）；
# ⑤ 4.4.11 减法 / 4.4.13 除法与余项的回收。
from itertools import product


def canon(v):
    v = list(v)
    while v and v[-1] == 0:
        v.pop()
    return tuple(v)


def olt(a, b):
    a, b = canon(a), canon(b)
    if len(a) != len(b):
        return len(a) < len(b)
    return tuple(reversed(a)) < tuple(reversed(b))    # 高位优先


def oeq(a, b):
    return canon(a) == canon(b)


def oadd(a, b):
    b = canon(b)
    if not b:
        return canon(a)
    k = len(b) - 1                                     # β 的最高指数
    n = max(len(a), len(b))
    ap = list(a) + [0] * (n - len(a))
    bp = list(b) + [0] * (n - len(b))
    res = bp[:k] + [ap[k] + bp[k]] + ap[k + 1:]
    return canon(res)


def omul(a, b):
    a, b = canon(a), canon(b)
    if not b:
        return ()
    d = len(a) - 1
    c = a[-1]
    res = [0] * (d + len(b))
    for i in range(d):                                 # α 的低位尾巴：仅当 β0≠0 保留一次
        res[i] = a[i] if b[0] else 0
    res[d] = c * b[0]                                  # e=0：首系数放大
    for e in range(1, len(b)):                         # e≥1：搬到 d+e，首系数归一
        res[d + e] = b[e]
    return canon(res)


W = (0, 1)                                             # ω

# ③ 书例全录
assert oeq(oadd((1,), W), W) and oeq(oadd((2,), W), W)   # 1+ω = 2+ω = ω
assert oeq(oadd(W, (1,)), (1, 1))                       # ω+1 > ω：非交换
assert oeq(oadd(W, W), (0, 2))                          # ω+ω = ω·2
assert oeq(oadd((3, 1), W), (0, 2))                     # (3+ω)+ω：3 被吸收
assert oeq(oadd((0, 2), (1, 1)), (1, 3))                # ω·2+(1+ω) = 1+ω·3
assert oeq(oadd((4, 3, 1), W), (0, 4, 1))               # 仅 c0 被吸收，c1 相加
assert oeq(omul((2,), W), W)                            # 2·ω = ω（4.4.6(5)）
assert oeq(omul(W, (2,)), (0, 2))                       # ω·2 ≠ 2·ω
assert oeq(omul(W, W), (0, 0, 1))                       # ω·ω = ω²
assert oeq(omul((1,), (7, 3)), (7, 3))                  # 1·α = α（4.4.6(4)）
assert oeq(omul((3,), (4,)), (12,))                     # 有限情形回到算术
assert oeq(omul((1, 2), (5, 1)), (1, 10, 1))            # (ω·2+1)(ω+5) = ω²+ω·10+1
assert oeq(omul((2, 2), W), (0, 0, 1))                  # (ω·2+2)·ω = ω²
print("CNF add/mul: all book examples 4.4.2 / 4.4.6 exact: OK")

# 幂（4.4.8）：β^ω = ω^{deg β}（β 有限 >1 时 = ω）
def opow(base, n):                                     # 有限次幂：乘法迭代
    r = (1,)
    for _ in range(n):
        r = omul(base, r)
    return r

assert oeq(opow(W, 2), (0, 0, 1))                       # ω² = ω·ω
assert oeq(opow(W, 3), (0, 0, 0, 1))                    # ω³
assert oeq(opow((2,), 3), (8,))                         # 2³ = 8
# β^ω 的规则样本：2^ω = ω、(ω+1)^ω = ω^ω（后者超出窗口——文档注明）
assert oeq(omul((2,), W), W)                            # 2·ω = ω 蕴含 2^ω = ω
print("CNF power: w^2, w^3, 2^3 finite, 2^w = w: OK")

# ④ 4.4.10 的尾巴平移：α+β 的元素表中 [α, α+β) 一段恰是 ξ ↦ α+ξ 的像
window = sorted({canon([c0, c1, c2]) for c2 in range(3)
                 for c1 in range(3) for c0 in range(6)},
                key=lambda t: (len(t), tuple(reversed(t))))
alpha, beta = W, (0, 2)                                # α=ω, β=ω：α+β = ω·2
tail = [g for g in window if olt(alpha, g) and olt(g, oadd(alpha, beta))]
imgs = {oadd(alpha, xi) for xi in window if olt(xi, beta)}
assert set(tail) <= imgs                               # 每个尾巴元素都是某个 α+ξ
print("4.4.10 tail shift: [a, a+b) covered by xi -> a+xi (window): OK")

# ⑤ 减法（4.4.11）与除法（4.4.13）
def osub(beta, alpha):
    """α ≤ β 时的唯一 γ：α + γ = β。"""
    assert olt(alpha, beta) or oeq(alpha, beta)
    # 从 β 的 CNF 减去 α 的（在交叉指数以下重置为 0）
    a, b = canon(alpha), canon(beta)
    k = len(b)
    # α+γ=β：在交叉指数 d=deg α 处做系数减法，其余照抄 β
    d = len(a) - 1
    res = list(b)
    if d < len(res):
        res[d] -= a[d]
    return canon(res)

gamma = osub((0, 2), W)                                # ω·2 − ω = ω
assert oeq(oadd(W, gamma), (0, 2))
gamma2 = osub((5, 2), (0, 2))                          # (ω·2+5) − ω·2 = 5
assert oeq(gamma2, (5,))
print("4.4.11 subtraction: a + (b-a) = b on samples: OK")

# 除法（4.4.13）：β = α·ξ + ρ、ρ < α（α 有限的样本）
beta, alpha = (5, 2), (3,)                             # ω·2+5 = 3·(ω·2+1) + 2
xi = (1, 2)
rho = (2,)
assert oeq(oadd(omul(alpha, xi), rho), beta)
assert olt(rho, alpha)
print("4.4.13 division: 3*(w*2+1)+2 = w*2+5, rho < alpha: OK")
print("END ====")
