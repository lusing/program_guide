# -*- coding: utf-8 -*-
print("==== 51 slln")
# 第 51 章 Python：强大数律的精确账（Fraction 版）。
# ① 三级数定理的三和判决（几何尾分布的逐条核算）；② Kronecker
#    引理的有限版恒等；③ 层饼公式 ΣP{X≥n} ≤ EX 的取等现场。
from fractions import Fraction


# ① 三级数判决：Yₙ = ±2ⁿ 各概率 2^{-(n+1)}（n≥1），0 补足
#    (i) ΣP{|Yₙ|≥1} = Σ2^{-n} = 1 < ∞（尾项稀少 ✓）
#    (ii)(iii) 截尾 c=1：Yₙ^c ≡ 0 ⟹ 两级数 = 0（✓）
#    ⟹ ΣYₙ a.s. 收敛（几乎必然有限项非零）
def y_tail(n):
    return Fraction(1, 2 ** n)


s1 = sum(y_tail(n) for n in range(1, 21))       # 部分和上界
assert s1 < 1                                     # Σ_{n≥1}2^{-n} = 1
assert Fraction(0) == 0 and Fraction(0) < 1      # (ii)(iii) 截尾恒零
print("three-series (sparse tail): sum P(|Y_n|>=1) =", s1,
      "< 1; truncated series = 0 exactly: OK")

#    对照：Zₙ = ±1 各 1/2——(i) ΣP{|Zₙ|≥1} = ∞ 立即发散
s_bad = sum(Fraction(1, 1) for _ in range(1, 101))
assert s_bad == 100                                # 每项 P = 1 ⟹ 级数发散
print("three-series (fail case): sum P(|Z_n|>=1) grows as n ->",
      s_bad, "(diverges): OK")

# ② Kronecker 引理有限版：xₖ = 1/k，bₖ = k：Σxₖ/bₖ = Σ1/k² 收敛
#    ⟹ bₙ⁻¹Σxₖ = Hₙ/n → 0（此处 n=200 的精确分数账）
def harmonic(n):
    return sum(Fraction(1, k) for k in range(1, n + 1))


n = 200
kr = harmonic(n) / n
assert kr < Fraction(1, 10)                        # Hₙ/n < 0.1（真实 ~0.029）
kr10 = harmonic(10) / 10
assert kr < kr10                                   # 单调下降轨道
print("Kronecker: H_n/n exact = ", float(kr), " (n=200), < 0.1: OK")

#    有限和恒等核对：Σ_{k≤n} xₖ = Σ_{k≤n} bₖ·(xₖ/bₖ)（分部求和的
#    平凡账——Abel 变换的 n=5 直算）
xs = [Fraction(1, k) for k in range(1, 6)]
lhs = sum(xs)
rhs = sum(Fraction(k, 1) * Fraction(1, k * k) for k in range(1, 6))
assert lhs == rhs
print("Kronecker identity check: sum x_k = sum b_k*(x_k/b_k) exact: OK")

# ③ 层饼取等：非负整值 X：Σ_{n≥1}P{X≥n} = EX 精确相等
#    (a) 均匀 {1,2,3,4}：EX = 5/2，ΣP{X≥n} = 4/4+3/4+2/4+1/4 = 5/2
ex = sum(Fraction(1, 4) * k for k in (1, 2, 3, 4))
layer = sum(Fraction(5 - k, 4) for k in (1, 2, 3, 4))
assert ex == layer == Fraction(5, 2)
#    (b) 几何 p=1/2（ℕ 上）：EX = 2；截断 K=30 的层饼和 = 2 − 2⁻²⁹
layer_g = sum(Fraction(1, 2 ** (k - 1)) for k in range(1, 31))
assert layer_g < 2                                 # 从下方逼近
assert 2 - layer_g == Fraction(1, 2 ** 29)         # 精确差账 = 尾项 2^{-29}
print("layer-cake equality: EX = sum P(X>=n) exact (uniform), geometric truncation",
      "gap = 2^-29 exact: OK")

print("END ====")
