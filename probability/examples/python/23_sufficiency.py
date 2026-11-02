# -*- coding: utf-8 -*-
print("==== 23 sufficiency")
# 第 23 章 Python：充分统计量与数据简化。
# ① Bernoulli：给定 Σx 的条件分布与 p 无关（Fraction 精确枚举）
# ② Poisson：给定 Σx 的条件分布 = 多项分布(s; 1/n,...)，与 λ 无关
# ③ 正态：同 (Σx, Σx²) 的两组样本，似然比恒为 1（sympy 符号）
# ④ U(0,θ)：最大值充分；条件分布与 θ 无关（KS 双样本）
# ⑤ 最小充分性：似然比准则；非完备反例 N(θ,θ²)；Basu；Rao–Blackwell
from fractions import Fraction
from itertools import product
from math import comb, factorial, exp
import numpy as np
import sympy as sp
from scipy import stats

rng = np.random.default_rng(23)

# ---------------------------------------------------------------- ① Bernoulli
n = 4


def lik_bern(x, p):
    s = sum(x)
    return p ** s * (1 - p) ** (n - s)


def cond_dist(p):
    """返回 {t: {x: P(X=x | T=t)}}。"""
    out = {}
    for x in product((0, 1), repeat=n):
        out.setdefault(sum(x), {})[x] = lik_bern(x, p)
    for t, d in out.items():
        tot = sum(d.values())
        out[t] = {x: v / tot for x, v in d.items()}
    return out


ps = [Fraction(1, 3), Fraction(1, 2), Fraction(3, 4), Fraction(1, 97)]
dists = [cond_dist(p) for p in ps]
for d in dists[1:]:
    assert d == dists[0]
for t in range(n + 1):
    assert all(v == Fraction(1, comb(n, t)) for v in dists[0][t].values())
# 总 pmf 因子分解：P(X=x) = P(T=t) * h(x)，h(x)=1/C(n,t)
for p in ps:
    for x in product((0, 1), repeat=n):
        t = sum(x)
        assert lik_bern(x, p) == comb(n, t) * p ** t * (1 - p) ** (n - t) / comb(n, t)
print("Bernoulli n=4: P(x | sum=t) = 1/C(4,t) for p in {1/3,1/2,3/4,1/97}: exact, p-free: OK")

# 对照：非充分统计量 T'=x1 + x2（只用前两个观测）→ 条件分布依赖 p
def cond_first_given_partial(p):
    # P(X1=1 | X1+X2+X3+X4 的信息丢失…) 改用 T'=X1+X2 看 X1+X3 的条件概率
    num = den = Fraction(0)
    for x in product((0, 1), repeat=n):
        if x[0] + x[1] == 1:
            den += lik_bern(x, p)
            if x[2] == 1:
                num += lik_bern(x, p)
    return num / den


assert cond_first_given_partial(Fraction(1, 3)) == Fraction(1, 3)
assert cond_first_given_partial(Fraction(3, 4)) == Fraction(3, 4)
print("T'=x1+x2 is not sufficient for the rest: P(x3=1 | T') = p depends on p: OK")

# ---------------------------------------------------------------- ② Poisson
# n=3，S=Σx=5：P(x | S=5) = 5!/(x1!x2!x3!) / 3^5，与 λ 无关
def pois_pmf(k, lam):
    return Fraction(lam) ** k * Fraction(1, factorial(k))   # 略去公共因子 e^{-λ}，比值中约去


n3, S = 3, 5
for lam in (Fraction(1, 2), Fraction(2), Fraction(7, 3)):
    weights = {}
    for x in product(range(S + 1), repeat=n3):
        if sum(x) == S:
            w = Fraction(1)
            for k in x:
                w *= pois_pmf(k, lam)
            weights[x] = w
    tot = sum(weights.values())
    for x, w in weights.items():
        multi = Fraction(factorial(S), factorial(x[0]) * factorial(x[1]) * factorial(x[2]) * 3 ** S)
        assert w / tot == multi
print("Poisson n=3, sum=5: conditional pmf = Multinomial(5; 1/3,1/3,1/3), lambda-free: OK")

# ---------------------------------------------------------------- ③ 正态
mu_s, s2_s = sp.symbols("mu sigma2", real=True)
xa = [1, 5, 6]
xb = [2, 3, 7]
assert sum(xa) == sum(xb) and sum(v * v for v in xa) == sum(v * v for v in xb)
logf = lambda xs: sum(-(v - mu_s) ** 2 / (2 * s2_s) for v in xs)
assert sp.simplify(logf(xa) - logf(xb)) == 0
xc = [1, 5, 7]          # 和不同
assert sp.simplify(logf(xa) - logf(xc)) != 0
# 因子分解：Σ(x-μ)² = Σx² − 2μΣx + nμ²
xs_sym = sp.symbols("x1 x2 x3")
lhs = sum((v - mu_s) ** 2 for v in xs_sym)
rhs = sum(v ** 2 for v in xs_sym) - 2 * mu_s * sum(xs_sym) + 3 * mu_s ** 2
assert sp.expand(lhs - rhs) == 0
print("Normal: samples with equal (sum, sum of squares) have likelihood ratio 1 for every (mu,sigma2): OK")

# σ² 已知时 X̄ 单独充分：只要和相同比值为 exp(μ(Σx−Σy)/σ²) = 1
logf1 = lambda xs: sum(-(v - mu_s) ** 2 / 2 for v in xs)
assert sp.simplify(logf1([1, 5, 6]) - logf1([4, 4, 4])) == -7   # 和相同(=12)：对数似然差是不含 μ 的常数 −(62−48)/2

# ---------------------------------------------------------------- ④ U(0,θ)
N, nn = 60_000, 5


def cond_ratios(theta):
    x = rng.random((N, nn)) * theta
    m = x.max(axis=1)
    # 去掉最大值那一项后，其余 n−1 个除以 max，应为 U(0,1)
    arg = x.argmax(axis=1)
    mask = np.ones_like(x, dtype=bool)
    mask[np.arange(N), arg] = False
    rest = (x / m[:, None])[mask]
    return rest, m


r1, m1 = cond_ratios(1.0)
r5, m5 = cond_ratios(5.0)
assert stats.ks_2samp(r1, r5).pvalue > 0.001
assert stats.kstest(r1, "uniform").statistic < 0.004
# max 的分布：P(M≤m) = (m/θ)^n
assert abs(np.mean(m5 <= 4.0) - (4.0 / 5.0) ** nn) < 0.006
# X1 单独不充分：给定 X1 之外的信息…示意：均值 X̄ 的条件信息含 θ（X̄ 不能确定 max ≤ θ 的边界）
# 精确的“不是 X̄”：两个样本 x̄ 相同而 max 不同，似然 1/θ^n·1{max≤θ} 的比在 θ 位于两 max 之间时为 0 或 ∞
xa_, xb_ = [1.0, 2.0, 6.0], [3.0, 3.0, 3.0]
assert sum(xa_) == sum(xb_) and max(xa_) != max(xb_)
theta = 4.0
lik = lambda xs, th: (1 / th) ** len(xs) * (max(xs) <= th)
assert lik(xa_, theta) == 0 and lik(xb_, theta) > 0
print("U(0,theta): X_i/max given max is U(0,1) for theta=1 and 5 (KS), P(max<=m)=(m/theta)^n; mean not sufficient: OK")

# ---------------------------------------------------------------- ⑤ 最小充分、完备、Basu、RB
# 最小充分：Bernoulli，似然比 f(x)/f(y) 与 p 无关 ⇔ Σx = Σy
pts = list(product((0, 1), repeat=3))
for x in pts:
    for y in pts:
        ratios = {lik_bern_ratio for lik_bern_ratio in
                  [(Fraction(p) ** sum(x) * (1 - Fraction(p)) ** (3 - sum(x))) /
                   (Fraction(p) ** sum(y) * (1 - Fraction(p)) ** (3 - sum(y)))
                   for p in (Fraction(1, 5), Fraction(1, 2), Fraction(4, 5))]}
        assert (len(ratios) == 1) == (sum(x) == sum(y))
print("Bernoulli n=3: likelihood ratio free of p  <=>  equal sums (minimal sufficiency): OK")

# 完备性反例 1：n=2 Bernoulli 的 T=(X1,X2) 充分但不完备，g=X1−X2 期望恒零
for p in (Fraction(1, 7), Fraction(1, 2), Fraction(5, 6)):
    e = sum(lik_bern_n2 * (x[0] - x[1]) for x in product((0, 1), repeat=2)
            for lik_bern_n2 in [p ** sum(x) * (1 - p) ** (2 - sum(x))])
    assert e == 0
# 完备性：T=ΣX~Bin(n,p)，多项式 Σ g(t)C(n,t)p^t(1-p)^(n-t) ≡ 0 ⇒ g≡0。验证系数矩阵满秩
nT = 4
pvals = [Fraction(k, 10) for k in range(1, nT + 2)]
M = sp.Matrix([[sp.Rational(comb(nT, t)) * sp.Rational(p.numerator, p.denominator) ** t *
                (1 - sp.Rational(p.numerator, p.denominator)) ** (nT - t) for t in range(nT + 1)]
               for p in pvals])
assert M.det() != 0
print("Bernoulli: E_p g(T)=0 for p=.1..(n+1)/10 forces g=0 (Vandermonde-type matrix nonsingular); T=(X1,X2) not complete: OK")

# 完备性反例 2：N(θ,θ²)，(X̄,S²) 极小充分但不完备：g = n/(n+1) X̄² − S² 期望恒 0
th, nsym = sp.symbols("theta n", positive=True)
EXb2 = th ** 2 + th ** 2 / nsym
ES2 = th ** 2
assert sp.simplify(nsym / (nsym + 1) * EXb2 - ES2) == 0
nn2 = 6
Xs = rng.normal(2.0, 2.0, size=(300_000, nn2))              # θ=2，σ=θ
gval = nn2 / (nn2 + 1) * Xs.mean(axis=1) ** 2 - Xs.var(axis=1, ddof=1)
assert abs(gval.mean()) < 0.03
print("N(theta,theta^2): E[ n/(n+1) Xbar^2 - S^2 ] = 0 for all theta (not complete): OK")

# Basu：N(μ,1) 下 X̄ 完备充分、S² 辅助 ⇒ 独立；U(0,θ) 下 max 完备充分、min/max 辅助 ⇒ 独立
Xn = rng.normal(0.0, 1.0, size=(100_000, 6))
assert abs(np.corrcoef(Xn.mean(axis=1), Xn.var(axis=1, ddof=1))[0, 1]) < 0.01
for theta in (1.0, 7.0):                                     # S² 的分布不随 μ 变（辅助）
    Xmu = rng.normal(theta, 1.0, size=(100_000, 6))
    assert abs(Xmu.var(axis=1, ddof=1).mean() - 1) < 0.01
Un = rng.random((200_000, 5))
Mx, Mn = Un.max(axis=1), Un.min(axis=1)
assert abs(np.corrcoef(Mx, Mn / Mx)[0, 1]) < 0.01
# Basu 的用途：E[Mn] = E[Mn/Mx]·E[Mx] ⇒ E[Mn/Mx] = E[Mn]/E[Mx] = (θ/(n+1))/(nθ/(n+1)) = 1/n
assert abs((Mn / Mx).mean() - 1 / 5) < 0.003
assert abs(Mn.mean() - (Mn / Mx).mean() * Mx.mean()) < 0.003
print("Basu: corr(Xbar,S^2)~0 for N(mu,1); corr(max, min/max)~0 for U(0,theta); S^2 location-invariant: OK")

# Rao–Blackwell：Bernoulli，估计 p：δ=X1，E[δ|T]=T/n，方差 p(1−p) → p(1−p)/n（精确）
for p in (Fraction(1, 5), Fraction(1, 2), Fraction(2, 3)):
    nb = 5
    var_delta = p * (1 - p)
    pmf = {t: comb(nb, t) * p ** t * (1 - p) ** (nb - t) for t in range(nb + 1)}
    mean_rb = sum(Fraction(t, nb) * w for t, w in pmf.items())
    var_rb = sum((Fraction(t, nb) - mean_rb) ** 2 * w for t, w in pmf.items())
    assert mean_rb == p and var_rb == var_delta / nb
    # E[δ|T=t] 直接由条件分布得到：P(X1=1 | T=t) = t/n
    for t in range(1, nb):
        num = comb(nb - 1, t - 1)
        assert Fraction(num, comb(nb, t)) == Fraction(t, nb)
# Poisson：估计 e^{−λ}，δ=1{X1=0}，RB 后 ((n−1)/n)^T
lam, npo = 1.3, 6
tgrid = np.arange(0, 120)
w = stats.poisson.pmf(tgrid, npo * lam)
rb = ((npo - 1) / npo) ** tgrid
assert abs((w * rb).sum() - exp(-lam)) < 1e-10
var_rb = (w * rb ** 2).sum() - exp(-2 * lam)
var_delta = exp(-lam) * (1 - exp(-lam))
assert 0 < var_rb < var_delta
# U(0,θ)：δ=2X̄ 不是 max 的函数；E[2X̄ | X(n)] = (n+1)/n · X(n)，方差 θ²/(3n) → θ²/(n(n+2))
nu_, th_ = 5, 3.0
Uu = rng.random((400_000, nu_)) * th_
d0 = 2 * Uu.mean(axis=1)
d1 = (nu_ + 1) / nu_ * Uu.max(axis=1)
assert abs(d0.mean() - th_) < 0.01 and abs(d1.mean() - th_) < 0.01
assert abs(d0.var() - th_ ** 2 / (3 * nu_)) < 0.01
assert abs(d1.var() - th_ ** 2 / (nu_ * (nu_ + 2))) < 0.005
assert Fraction(1, 3 * 5) > Fraction(1, 5 * 7)
print("Rao-Blackwell: Bernoulli var p(1-p) -> p(1-p)/5 exact; Poisson 1{X1=0} -> ((n-1)/n)^T unbiased, var %.4f < %.4f: OK"
      % (var_rb, var_delta))

print("END ====")
