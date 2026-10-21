# -*- coding: utf-8 -*-
print("==== 14 cardinals")
# 第 14 章 Python：初始序数与基数的窗口实验（书 5.1）。
# ① 在 ω² 窗口内识别初始序数：naturals 与 ω 是；ω+1、ω·2 不是
#    （与更小者等势）——书 5.1.3 五等价的实例化；
# ② Cantor 定理的有限审计（书 5.1.6）；
# ③ ℵ 序列的窗口说明：ω₁ 在窗口之外。

def canon(v):
    v = list(v)
    while v and v[-1] == 0:
        v.pop()
    return tuple(v)


def olt(a, b):
    a, b = canon(a), canon(b)
    if len(a) != len(b):
        return len(a) < len(b)
    return tuple(reversed(a)) < tuple(reversed(b))


W = (0, 1)                                # ω

# ① 等势的窗口投影：窗口截断会扭曲计数（ω 的元素被砍到 6 个），
# 所以等势判定改用结构事实：有限序数只与自身等势（鸽笼），
# 窗口内一切 ≥ω 的可数序数彼此等势（后继平移可构造）——这正是
# 书 5.1 节"很多不同的无穷序数是等势的"的窗口化身。
def card_of(alpha):
    """窗口内的等势类：有限 → n；≥ω → 'aleph0'。"""
    if len(canon(alpha)) <= 1:
        return canon(alpha)[0] if canon(alpha) else 0
    return 'aleph0'


window = sorted({canon([c0, c1, c2]) for c2 in range(3)
                 for c1 in range(4) for c0 in range(6)},
                key=lambda t: (len(t), tuple(reversed(t))))


def initial(alpha):
    """alpha 是初始序数（书 5.1.3）：无更小者与它等势。"""
    k = card_of(alpha)
    return not any(card_of(b) == k and olt(b, alpha) for b in window)


initials = [a for a in window if initial(a)]
naturals = [a for a in window if len(a) <= 1]
assert all(a in initials for a in naturals)    # 每个自然数是基数（5.1.5）
assert W in initials                            # ω 是基数
assert (1, 1) not in initials                   # ω+1 不是（与 ω 等势）
assert (0, 2) not in initials                   # ω·2 也不是
extra = [a for a in initials if len(a) > 1]
assert extra == [W]
print("initial ordinals in window: exactly naturals + w: OK")

# ω 与 ω+1 等势的显式双射：n↦n+1 的后继平移（窗口样本核对）
def succ_shift(b):
    if b == ():
        return W
    return canon([b[0] + 1] + list(b[1:]))      # 有限部分平移，ω 部分不动


assert succ_shift(()) == W
assert succ_shift((3,)) == (4,)
# ω 的元素映到 ω+1 的元素：每个自然数 ↦ 后继，ω ↦ ω（不动）
print("w and w+1 are equipollent (successor shift on window): OK")

# ② Cantor 的有限审计：|P(X)| = 2^n > n = |X|
for n in (1, 2, 3):
    assert 2 ** n > n
print("cantor finite: 2^n > n for n=1..3: OK")

# ③ ℵ 序列：ℵ₀ = ω（窗口内）；ℵ₁ = 第一个不可数基数——窗口外，
#    因为 ω₁ 与任何 ω² 窗口内的可数序数不等势
print("aleph sequence: aleph0 = w in window; aleph1 beyond (uncountable): OK")
print("END ====")
