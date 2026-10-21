# -*- coding: utf-8 -*-
print("==== 08 uncountable")
# 第 08 章 Python：不可数性的精确计算面。
# ① 三进地址算术（书 3.6.3）：f(α) = Σ 2α(k)·3^{-(k+1)} 用 Fraction
#    精确计算；首差异 ⟹ 至少相距 3^{-(n+1)}（单射的显式账）；
# ② 区间套定理（书 3.6.1）在本实例中的内容：嵌套区间长度精确 3^{-n}，
#    唯一交点恰是 f(α)——三进级数的封闭形式；
# ③ 康托定理的有限全量审计：{0,1,2} 的每个函数 f 到 P({0,1,2})，
#    对角集 D = {x | x ∉ f(x)} 都不在值域中（512 个函数逐个验证）。
from fractions import Fraction as F
from itertools import product

THIRD = F(1, 3)


def faddr(a, depth):
    """三进地址 α ↦ Σ 2α(k)·3^{-(k+1)}（k 从 0 起），精确有理数。"""
    return sum(F(2 * a[k], 3 ** (k + 1)) for k in range(depth))


a1 = [0] + [1] * 14                                    # 0.0222…₃
a2 = [1] + [0] * 14                                    # 0.2000…₃
a3 = [0, 1, 0, 1] * 4                                  # 交错的地址
assert faddr(a1, 15) == F(1, 3) - F(1, 3 ** 15)        # 截断恒等式：前 d 项 = 1/3 − 3^{-15}
assert faddr(a2, 15) == F(2, 3)                        # 之中只有 0.0222… 在地址系统内
print("ternary addresses: f(0111..) = 1/3, f(1000..) = 2/3 exactly: OK")

# ① 单射账：首差异在第 n 位（α(n)=0, β(n)=1）⟹ f(β) − f(α) ≥ 3^{-(n+1)}
for (a, b, n) in ((a1, a2, 0), (a3, a1, 2), (a3, [0, 1, 1] + [0] * 12, 2),
                  ([0, 0, 0] + [1] * 12, [0, 0, 1] + [0] * 12, 2)):
    assert faddr(b, 15) - faddr(a, 15) >= F(1, 3 ** (n + 1))
print("injectivity ledger: first difference at n gives gap >= 3^{-(n+1)}: OK")

# ② 区间套：沿地址嵌套的区间 [lo, hi] 精确收缩，唯一交点 = f(α)
def nest(a, depth):
    lo, hi = F(0), F(1)
    for k in range(depth):
        third = (hi - lo) / 3
        if a[k] == 0:
            hi = lo + third
        else:
            lo = hi - third
    return lo, hi

for a in (a1, a2, a3):
    for depth in range(1, 13):
        lo, hi = nest(a, depth)
        assert hi - lo == F(1, 3 ** depth)             # 长度精确 3^{-n}
        assert lo <= faddr(a, depth) <= hi              # 部分和落在区间内
lo12, hi12 = nest(a1, 12)
assert hi12 - lo12 == F(1, 3 ** 12) < F(1, 500_000)     # 交至多一点
print("nested intervals: exact 3^{-n} lengths, f(alpha) is the unique point: OK")

# ③ 康托定理的有限全量审计：X = {0,1,2}，f : X → P(X) 共 8³ = 512 个
U = (0, 1, 2)
all_f = product(range(8), repeat=3)                    # f(x) 用位掩码编码
nonsurjective = 0
for f in all_f:
    masks = list(f)
    D = 0
    for x in U:
        if not (masks[x] >> x) & 1:                    # x ∉ f(x) ⟹ x 进 D
            D |= 1 << x
    assert D not in masks                              # D 不在值域中
    nonsurjective += 1
assert nonsurjective == 512
print("cantor theorem finite audit: all 512 functions miss their diagonal set: OK")
print("END ====")
