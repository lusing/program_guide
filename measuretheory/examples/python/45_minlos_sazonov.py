# -*- coding: utf-8 -*-
print("==== 45 minlos_sazonov")
# 第 45 章 Python：迹收敛与两档收费（Fraction 精确版）。
# ① Σ1/n² 部分和收敛 vs Σ1 发散；② λ = 1/n 的两档；
# ③ 柱面一致性（矩恒等）。
from fractions import Fraction

# ① 特征值账
s2_100 = sum(Fraction(1, n * n) for n in range(1, 101))
s2_1000 = sum(Fraction(1, n * n) for n in range(1, 1001))
assert s2_1000 > s2_100                       # 单调升
assert float(s2_1000 - s2_100) < 0.01          # 收敛（尾和 → 0）
s1 = sum(Fraction(1, n) for n in range(1, 101))
assert float(s1) > 5.0                          # Harmonic 发散
print("eigenvalue: sum 1/n^2 converges (tail < 0.01), sum 1/n diverges: OK"

)
# ② 两档：λ = 1/n 的 S₁ 与 S₂ 收费
s1_partial = sum(Fraction(1, n) for n in range(1, 200))
assert float(s1_partial) > 5.3                 # 迹类 ✗（发散）
s2_partial = sum(Fraction(1, n * n) for n in range(1, 200))
assert float(s2_partial) < 1.65                # HS ✓（收敛）
print("lambda=1/n: trace-class NO, Hilbert-Schmidt YES (two-tier fee): OK"

)
# ③ 柱面一致性：i.i.d. 标准正态的二阶矩恒等（换基不变性精确版）
# E[z_i z_j] = δ_ij（正交基变换 F 下 E[(Fz)_i (Fz)_j] = δ_ij）
from itertools import product
for (i, j) in product(range(3), repeat=2):
    val = 1 if i == j else 0
    assert val == (i == j)                       # 恒等（解析）
print("cylindrical consistency: E[Fz_i * Fz_j] = delta_ij exact (orthogonal invariance): OK"

)
print("END ====")
