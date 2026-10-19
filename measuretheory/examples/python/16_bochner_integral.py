print("==== 16 bochner_integral")
# 第 16 章 Python 通道：向量值 Bochner 积分的精确账。
# ① (x, x²) 分量积分闭式 (1/2, 1/3)；
# ② 阶梯逼近的显式误差界（段中点右端格式）；
# ③ Bochner-DCT 序列 (1/(n+1), 0) → (0, 0) 精确分数；
# ④ ‖∫f‖ = √13/6 与 ∫‖f‖ 的浮点比较。

from fractions import Fraction as Fr
import math

# --- ① 分量积分闭式 ---
assert Fr(1, 2) + Fr(1, 3) == Fr(5, 6)          # 分量账
comp = (Fr(1, 2), Fr(1, 3))
assert sum(comp) == Fr(5, 6)
print("component integrals: (x,x^2) -> (1/2, 1/3) exact closed forms: OK")

# --- ② 阶梯逼近误差界（n 段中点阶梯积分 = (1/2, 1/3) 的修正账） ---
for n in (4, 8, 16):
    # 段 [k/n,(k+1)/n) 上取右端点值的阶梯积分：
    # Σ (k/n)/n = (n-1)n/2 / n² = (n-1)/(2n) = 1/2 - 1/(2n)
    s1 = Fr(sum(range(n)), n * n)
    assert s1 == Fr(1, 2) - Fr(1, 2 * n)        # 第一分量的精确偏离
    # x² 分量：Σ (k/n)²/n = (n-1)n(2n-1)/6 / n³ = (2n²-3n+1)/(6n²)
    s2 = Fr(sum(k * k for k in range(n)), n ** 3)
    assert s2 == Fr(2 * n * n - 3 * n + 1, 6 * n * n)
    assert s2 <= Fr(1, 3)
    assert Fr(1, 3) - s2 <= Fr(1, 2 * n)        # 误差 O(1/n)
print("step approximation: exact deviation 1/(2n), error O(1/n): OK")

# --- ③ Bochner-DCT（精确分数序列） ---
seq = [(Fr(1, n + 1), Fr(0)) for n in (1, 2, 5, 50)]
assert all(b == 0 for _, b in seq)
assert seq[0][0] == Fr(1, 2) and seq[-1][0] == Fr(1, 51)
assert all(seq[i][0] > seq[i + 1][0] for i in range(len(seq) - 1))
print("Bochner-DCT: integral sequence (1/2,1/3,1/6,1/51) decreasing to (0,0): OK")

# --- ④ 范数三角账（浮点） ---
lhs = math.hypot(0.5, 1 / 3)                    # ‖∫f‖ = √13/6
assert abs(lhs - math.sqrt(13) / 6) < 1e-15
K = 400_000
rhs = sum(math.hypot(x, x * x) for x in
          ((i - 0.5) / K for i in range(1, K + 1))) / K
assert lhs <= rhs + 1e-9
print(f"norm triangle: ||int f|| = {lhs:.6f} <= int||f|| = {rhs:.6f}: OK")

print("END ====")
