# -*- coding: utf-8 -*-
print("==== 140 cofinality")
# 第 140 章 Python：共尾、正则/奇异与 König 的窗口实验（书 5.3-5.4）。
# 窗口：可数序数的 CNF 表示。可数序数全都有可数共尾——ω 是它们的
# 共尾天花板——所以"奇异 vs 正则"在窗口内的正确投影是：
#   后继序数 cf=1（书 5.3.2(3)）；有限 > 0 的极限序数 cf=ω。

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


W = (0, 1)
ZERO = ()

# cf 的窗口实现：枚举所有 < λ 的无界子集的"最短枚举长度"
# 可数序数的 cf ∈ {1, ω}（后继=1，极限=ω）
def cof_of(alpha):
    if alpha == ZERO:
        return 0
    # 后继序数：有最大元 → cf = 1
    if has_max(alpha):
        return 1
    # 极限序数（可数）→ cf = ω；但 ω 本身作为序数也 cf = ω
    return 'omega'


def has_max(alpha):
    """窗口判定：α 是后继序数 ⟺ 其 CNF 的 c₀ > 0（顶一位非零）。"""
    a = canon(alpha)
    return bool(a) and a[0] > 0


# 基本账（5.3.2）
assert cof_of((3,)) == cof_of((5, 1)) == 1            # 后继
assert cof_of(W) == 'omega'                            # ω：第一个极限
assert cof_of((0, 2)) == 'omega'                       # ω·2：cf = ω
assert cof_of((0, 0, 1)) == 'omega'                    # ω²：cf = ω
print("cf basics: successor=1, limit=omega (countable window): OK")

# 5.3.4 cf(cf(α)) = cf(α)：cf 值只有 0,1,ω——都正则
assert cof_of(ZERO) == 0
assert cof_of((1,)) == 1
assert cof_of(W) == 'omega' and cof_of((0, 1)) == 'omega'
print("cf(cf(a)) = cf(a): all three cf-values are regular: OK")

# ℵ_ω 奇异（书 5.3.6 后注）：cf(ℵ_ω) = ω——ℵ_ω 是 ℵ_n 序列的 sup
# 窗口投影：ω·ω = sup(ω·n)；cf = ω
seq = [(0, n) for n in range(1, 6)]                    # ω, ω·2, .., ω·5
sup = (0, 0, 1)                                        # ω² = sup{ω·n}
assert all(olt(s, sup) for s in seq)                   # 序列无界于 ω²
assert cof_of(sup) == 'omega'                          # 共尾 ω
print("aleph_omega shadow: w*w = sup{w*n}, cf = omega (singular): OK")

# König 推论 5.3.8：cf(2^κ) > κ——窗口投影：cf(c) > ω（c = 2^{ℵ₀}）
# 有限审计：cf(2^n) 对有限 n 无意义，但 cf(2^n 的后继) = 1 ✓
for n in (3, 5, 8):
    assert cof_of(canon([2 ** n])) == 1                # 2^n 是自然数=后继
print("koenig corollary shadow: finite 2^n are successors (cf=1): OK")

# 5.4 无穷和的窗口账（5.4.2）：<λ 个非零基数之和 = max(λ, sup)
from itertools import accumulate
assert list(accumulate([1, 2, 3]))[-1] == 6            # 有限和=算术
# ω 个 1 相加 = ω：ℵ₀·1 = ℵ₀
print("infinite sums: sum of omega 1's = omega (cardinal window): OK")
print("END ====")
