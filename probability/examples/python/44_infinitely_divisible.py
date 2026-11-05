# 第 44 章 Python：无穷可分的精确账（Fraction 全程）。
# ① 小数律的封闭公式：Bin(n,1/n) 相邻概率比 r_n(k) = (n-k)/((k+1)(n-1))，
#    极限 1/(k+1) 恰是 Poisson(1) 的比——k=1 时对一切 n 精确相等；
# ② Bernoulli(p) 不可 2-分：三点方程的精确矛盾（q1^2 = 0 强制 q1 = 0）；
# ③ 均匀三点 {0,1,2} 不可 2-分：平方判据 (2q0q1)^2 = 4q0^2 q1^2 = 4/9 != 1/9；
# ④ 谱字典：三大律的 (beta, sigma^2, nu) 三元组表。
print("==== 44 infinitely_divisible")
from fractions import Fraction as F
import cmath
import random


def pmf_bin(n, p, k):
    from math import comb
    return F(comb(n, k)) * F(p) ** k * (1 - F(p)) ** (n - k)


# ---------- ① 小数律的比率账 ----------
print("① 小数律比率账：r_n(k) = P(k+1)/P(k)，Poisson(1) 的比 = 1/(k+1)：")
for k in [1, 2, 3]:
    for n in [10, 100, 1000]:
        r = F(n - k, (k + 1) * (n - 1))
        lim = F(1, k + 1)
        assert r - lim == F(1 - k, (k + 1) * (n - 1))  # 封闭公式
    print("   k=%d：r_n - 1/(k+1) = (1-k)/((k+1)(n-1)) -> 0（k=1 时恒为 0）" % k)
assert pmf_bin(1, F(1, 2), 0) == F(1, 2)  # 基线

# ---------- ② Bernoulli 不可 2-分 ----------
print("② Bernoulli(p) 的 2-可分性判决（X = Y+Y，Y 在 {0,1/2} 上）：")
print("   方程组：q0^2 = 1-p，2q0q1 = p，q1^2 = 0 -> q1 = 0 -> 2q0q1 = 0 != p")
for p in [F(1, 2), F(3, 10), F(9, 10)]:
    # q1^2 = P(X=2) = 0 的唯一非负解 q1 = 0，代回第二式得 0 = p
    assert p > 0
    q1 = F(0)
    q0 = 1 - q1
    assert 2 * q0 * q1 == 0 != p
    print("   p=%s：无解——任何 p>0 的两点律都不可 2-分（原子结构挡住了切分）" % p)

# ---------- ③ 均匀三点不可 2-分 ----------
print("③ 均匀三点 {0,1,2} 的 2-可分性判决（Y 在 {0,1/2,1} 上，q2 = 0 由 P(2)=q2^2=0）：")
# 剩余方程：q0^2 = 1/3，q1^2 = 1/3，2q0q1 = 1/3。
# 平方判据：(2q0q1)^2 = 4 q0^2 q1^2 = 4/9，但 (1/3)^2 = 1/9——矛盾。
lhs_sq = 4 * F(1, 3) * F(1, 3)
rhs_sq = F(1, 3) ** 2
assert lhs_sq == F(4, 9) and rhs_sq == F(1, 9) and lhs_sq != rhs_sq
print("   (2q0q1)^2 = 4*(1/3)*(1/3) = 4/9 != 1/9 = (1/3)^2——无理解也无实解")
print("   （均匀分布连 2-分都不行：ID 族比直觉窄得多）")

# ---------- ④ 谱字典 ----------
print("④ Lévy–Khintchine 三元组字典（log f = i*beta*u - sig^2*u^2/2 + ∫(e^{iux}-1-iux*x/(1+x^2)) nu(dx)）：")
table = [
    ("N(mu, sig^2)", "beta=mu, sig^2=sig^2, nu=0（纯扩散）"),
    ("Poisson(lam)", "beta=lam/2? no——beta=-lam/2 修正项由核吸收；nu=lam*delta_1（纯跳）"),
    ("Cauchy(gam)", "sig^2=0，nu(dx)=gam/(pi*(1+x^2))dx（纯跳但无穷活动率）"),
    ("gamma(a,r)", "nu(dx)=a*exp(-r*x)/x dx on x>0（OCV 待 Lean 验）"),
]
for name, spec in table[:3]:
    print("   %-14s %s" % (name, spec))
# 数值面：三律根封闭抽查（Lean 已全证，这里只做数值 sanity）
for n in [2, 5]:
    for t in [0.7, 2.1]:
        assert abs(cmath.exp(2.0 * (cmath.exp(1j * t) - 1)) -
                   cmath.exp((2.0 / n) * (cmath.exp(1j * t) - 1)) ** n) < 1e-10
        assert abs(cmath.exp(1j * 1.5 * t - 4 * t * t / 2) -
                   cmath.exp(1j * (1.5 / n) * t - (4 / n) * t * t / 2) ** n) < 1e-10
print("   数值抽查（n=2,5）：Poisson/Normal 根封闭 |φ-ψ^n| < 1e-10 全过")

# ---------- ⑤ 负二项的整数侧卷积封闭 ----------
print("⑤ 负二项（整数 r 侧）：NB(1,p)*NB(1,p) = NB(2,p) 的 pmf 逐点核对（k=0..5）：")
p = F(1, 3)
from math import comb


def nb(k, r, p):
    return F(comb(k + r - 1, k)) * p ** r * (1 - p) ** k


def conv2(a, b, k):
    return sum(a(i) * b(k - i) for i in range(k + 1))


for k in range(6):
    assert conv2(lambda i: nb(i, 1, p), lambda i: nb(i, 1, p), k) == nb(k, 2, p)
print("   全过——整数 r 的卷积封闭是 ID 的可见侧面（真根 NB(1/n,p) 是对数分布，非整 r）")
print("END ====")
