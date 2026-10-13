# 第 20 章 积力迫与 Easton 定理
import sys, io
from itertools import product as iproduct
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 20 积力迫")

# 一、积的构建
P1 = {(i,b) for i in range(2) for b in [0,1]}
P2 = {(j,b) for j in range(2) for b in [0,1]}
P_prod = set(iproduct(P1, P2))
print(f"  |P1|={len(P1)}, |P2|={len(P2)}, |P1×P2|={len(P_prod)}")
assert len(P_prod) == len(P1) * len(P2)

# 二、Easton 约束的演示
print("\n  Easton 定理的约束 (20.8)：")
print("  (i)  F(κ) > κ（严格增长——Cantor）")
print("  (ii) F 单调（κ ≤ λ ⟹ F(κ) ≤ F(λ)）")
print("  (iii) cf F(κ) > κ（König）")
print("  满足这三条的任何 F 都可实现为某泛型扩张中的连续统函数。")

# Easton 积的域约束
print("\n  Easton 积的域约束 (20.10)-(20.11)：")
print("  对每个正则 γ：|s(p) ∩ γ| < γ——域与每个正则基数的交有界")

# 三、Levy 崩塌的语义
print("\n  Levy 崩塌（引理 20.4）：")
print("  κ 正则 + λ > κ 不可达 ⟹ P 崩塌 (κ,λ) 中的一切到 κ")
print("  κ-积 P = {p : |dom(p)|<κ, ran(p)<λ} 使 λ 变 κ⁺")

print("END ====")
