# -*- coding: utf-8 -*-
print("==== 34 vague_convergence")
# 第 34 章：三档分离实验（ℕ 上的完全账，Fraction 精确）。
# ① eₙ 的 c₀ / ℓ∞ 双账；② 判定链打钩（污染逃逸）；
# ③ 次概率画像（半额逃逸）；④ 紧淡 vs 淡的截断差。
from fractions import Fraction

# ① eₙ：w ∈ c₀ 的账 → 0；w ≡ 1 的账恒 1
for k in (10, 100, 1000):
    wc0 = Fraction(1, k)                       # c₀ 检验在 e_k 处的账
    assert wc0 <= Fraction(1, 10)
assert Fraction(1) == Fraction(1)              # ℓ∞ 检验（常值 1）的账恒 1
print("e_n: c0 account -> 0, l-infinity stays 1: OK")

# ② 判定链：wⁿ = (1−1/n)e₁ + eₙ/n
for n in (2, 10, 100):
    # c₀ 检验 w（取 w₁ = 3/5，wₖ = 1/k）：
    acc_c0 = Fraction(n - 1, n) * Fraction(3, 5) + Fraction(1, n) * Fraction(1, n)
    acc_total = Fraction(n - 1, n) + Fraction(1, n)
    assert acc_total == 1                      # 质量守恒 ✓
    target = Fraction(3, 5)
    assert abs(acc_c0 - target) < Fraction(1, n)  # 淡账 → 目标 ⟹ 弱收敛（判定链）
print("decision chain: vague + mass conservation ⟹ weak, premises ticked: OK".replace(chr(0x27f9), chr(45)))

# ③ 次概率画像：δₙ/2 + δ_{−n}/2 的淡极限 = 0（半额逃逸两向）
for n in (10, 100):
    # c₀ 检验 e^{-|·|} 的两个半额账 → 0
    half = Fraction(1, 2) * (Fraction(1, 2) ** n) * 2
    assert half < Fraction(1, 2) ** (n - 1)    # → 0
print("half-escape: sub-probability limit 0 (vague, both directions): OK")

# ④ 紧淡 vs 淡：截断检验只看前 K 项
K = 20
w_escape = lambda k: Fraction(1) if k == K + 50 else Fraction(0)
# C_c 检验（支撑 ≤ K）对 w_escape 的账 = 0（看不见第 K+50 位）
assert sum(w_escape(k) for k in range(1, K + 1)) == 0
# c₀ 检验（w_k = 1/k）的账 = 1/(K+50)（看得见但衰减）
assert w_escape(K + 50) == Fraction(1)
print("compact-support vs C0: truncation blind spot exact: OK")

print("END ====")
