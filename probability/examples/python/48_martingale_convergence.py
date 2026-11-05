# 第 48 章 Python：一致可积与选样的精确账（Fraction 全程）。
# ① 例 7.3.1 的 UI 失败账：E|X_n|·1{|X_n|>c} = 1 只要 2^n > c（精确分数）；
# ② Lévy 鞅的二进条件账：E[(X_n - Y)^2] = 1/(12·4^n) 精确分数；
# ③ 有界停时的四路径穷举：E[S_{T∧2}] = 0 精确（选样定理注 7.4.3(a)）；
# ④ 分支过程鞅的均值守恒（习题 7.1 精确面）：E[Z_n] = 2^n 逐 n 分数。
print("==== 48 martingale_convergence")
from fractions import Fraction as F


# ---------- ① 例 7.3.1 的 UI 失败账 ----------
print("① 例 7.3.1 的 UI 账（X_n = 2^n·ΠY，Y ~ Bernoulli(1/2)）：")
for c_int in [4, 16, 64]:
    n = c_int.bit_length() + 1          # 保证 2^n > c
    trunc = F(2 ** n) * F(1, 2) ** n    # E|X_n|·1{|X_n|>c} = 2^n·P(X_n = 2^n)
    assert trunc == 1
    print("   c = %d：取 n = %d（2^n > c），截断项 = %s ——sup_n 不衰减" % (c_int, n, trunc))
print("   UI 判据失败：期望 1 无家可归（轨道全部坍缩到 0）")

# ---------- ② Lévy 鞅的二进条件账 ----------
print("② Lévy 鞅（Y ~ U(0,1) 揭示前 n 位，X_n = 区间中点）：")
for n in [1, 2, 4]:
    var = F(1, 12 * 4 ** n)             # 区间长度 2^-n 的均匀方差 = (1/12)·4^-n
    print("   n = %d：E[(X_n - Y)^2] = %s = %.8f（每步除以 4）" % (n, var, float(var)))
    assert var == F(1, 12) * F(1, 4) ** n
print("   L^2 收敛 => UI（定理 7.3.2 的充分条件），且 a.s. 收敛（二进区间套住 Y）")

# ---------- ③ 有界停时四路径穷举 ----------
print("③ 有界停时（两步游走，T = 首次 S >= 1，截断 T∧2）：")
# 路径 -> (S_1, S_2) -> T∧2 处的取值
table = {
    (+1, +1): 1,   # T = 1，S_T = 1
    (+1, -1): 1,   # T = 1，S_T = 1
    (-1, +1): 0,   # S = (-1, 0)，未中，取 S_2 = 0
    (-1, -1): -2,  # 未中，取 S_2 = -2
}
vals = [F(v) for v in table.values()]
avg = sum(vals, F(0)) / 4
print("   四值 =", [str(v) for v in vals], "，E[S_{T∧2}] =", avg, "（精确 0）")
assert avg == 0
print("   E[S_{T∧2}] = E[S_2] = 0：有界停时保期望（选样定理注 7.4.3(a)）")

# ---------- ④ 分支过程鞅的均值守恒（习题 7.1） ----------
print("④ 分支过程（习题 7.1，每亲代 Binomial(4, 1/2) 个子代，均值 m = 2）：")
# E[Z_n] = m^n 逐 n 精确；W_n = Z_n/2^n 是鞅 => E[W_n] = 1
for n in [1, 2, 5]:
    ez = F(2) ** n
    w = ez / F(2) ** n
    assert w == 1
    print("   n = %d：E[Z_n] = %d，E[W_n] = %s（鞅性保均值）" % (n, 2 ** n, w))
print("   （超临界情形 P(存活) > 0，W_inf > 0 以正概率成立——与例 7.3.1 的坍缩形成对照）")
print("END ====")
