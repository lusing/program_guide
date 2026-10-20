# -*- coding: utf-8 -*-
print("==== 52 clt")
# 第 52 章 Python：CLT 的精确账（Fraction + erf）。
# ① Dé Moivre-Laplace：n=20 二项标准化 CDF vs Φ 的逐点对拍；
# ② Poisson CLT（习题 21.2）：P{Po(n) ≤ n} → 1/2 的收敛账；
# ③ Esseen (a) 对称化恒等式：两点分布 |φ|² = φ_{Xˢ} 的精确核对。
from fractions import Fraction
from math import comb, erf, sqrt


def phi_cdf(x):
    return 0.5 * (1.0 + erf(x / sqrt(2.0)))


# ① Dé Moivre-Laplace：Bin(20, 1/2)：P{(S−10)/√5 ≤ z} vs Φ(z)
n = 20
mu = Fraction(n, 2)
sig = sqrt(n * Fraction(1, 4))


def binom_cdf_std(z):
    k = int(mu + z * sig)
    return sum(Fraction(comb(n, j), 2 ** n) for j in range(0, k + 1))


max_err = 0.0
for z in (-1.5, -1.0, -0.5, 0.0, 0.5, 1.0, 1.5):
    F = float(binom_cdf_std(z))
    max_err = max(max_err, abs(F - phi_cdf(z)))
assert max_err < 0.12                       # n=20 的 D-L 误差（floor 格点语义：
#   中心处 P(<=10) = 0.588 vs Phi(0) = 0.5 —— 中心格点质量 0.176 主导，
#   与 Julia ① 的 sup err(25) = 0.079 同源同量级）
print("De Moivre-Laplace: max |F_bin(20) - Phi| on grid =",
      round(max_err, 4), "< 0.12 (lattice floor semantics): OK")

# ② Poisson CLT（习题 21.2）：P{Po(n) ≤ n} = e^{-n} sum_{k<=n} n^k/k! -> 1/2
def poisson_leq(n):
    # 用未归一权重 w(k) = n^k/k! 的前缀和与总量 e^n 比：改为比率递推
    # P(X<=n) 的精确分数不可行（e^n 无理）——用对数域？不行，Fraction 通道
    # 改为核对恒等式：sum_{k<=n} w(k) / sum_{k<=2n} w(k) 的有理逼近账
    w = [Fraction(1)]
    for k in range(1, 2 * n + 1):
        w.append(w[-1] * n / k)
    return sum(w[: n + 1]) / sum(w)          # P(X<=n)/P(X<=2n) 有理


for nn in (10, 50, 100):
    ratio = poisson_leq(nn)                  # = P(<=n)/P(<=2n)
    # P(X<=2n) > P(X<=n) ⟹ ratio < 1；收敛行为：P(<=n) -> 1/2, P(<=2n) -> 1
    assert ratio < 1
# 精确账改走整权恒等式：sum_{k<=n} w(k) 关于对称点的位置——
# 直接验证中位单调：P(<=n) 的近似值（float 辅助，双通道惯例的精确侧
# 只承诺恒等式）：sum_{k<=n} n^k/k! 与 sum_{k<=2n} 的比值单调上升
r10 = float(poisson_leq(10))
r50 = float(poisson_leq(50))
r100 = float(poisson_leq(100))
assert r10 > r50 > r100                       # P(<=n)/P(<=2n) 从上方单调降到 1/2
assert abs(r100 - 0.5) < 0.03                 # P(<=100)/P(<=200) ≈ 0.5266/0.999 ≈ 0.527
print("Poisson CLT tail identity: P(<=n)/P(<=2n) =",
      round(r10, 4), round(r50, 4), round(r100, 4), "-> 1/2 from above: OK")

# ③ Esseen (a) 对称化恒等式：X = ±1 各 1/2：φ(t) = cos t；
#    X^s = X - X'：支撑 {−2,0,2} 概率 {1/4,1/2,1/4}：
#    φ_{X^s}(t) = 1/2 + (1/2)cos 2t = cos²t = |φ|² —— 精确恒等式
#    （cos 在特殊角的精确值上用分数核对）
# t = pi/3: cos = 1/2; cos(2pi/3) = -1/2
lhs = Fraction(1, 2) + Fraction(1, 2) * Fraction(-1, 2)   # φ_Xs(pi/3)
rhs = Fraction(1, 2) * Fraction(1, 2)                     # cos^2(pi/3)
assert lhs == rhs == Fraction(1, 4)
# t = pi/2: cos = 0; cos(pi) = -1
lhs2 = Fraction(1, 2) + Fraction(1, 2) * Fraction(-1, 1)
rhs2 = Fraction(0, 1)
assert lhs2 == rhs2 == 0
print("Esseen symmetrization: phi_{X-X'}(t) = |phi_X(t)|^2 exact (2 angles): OK")

print("END ====")
