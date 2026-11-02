# -*- coding: utf-8 -*-
"""第 31 章：识别、偏差—方差分解与正态方差估计的风险。"""
from fractions import Fraction
import numpy as np

print("==== 31 estimation_models")


def scaled_variance_risk(c, n):
    """正态模型中 E[(c*S^2-sigma^2)^2]/sigma^4，nu=n-1。"""
    nu = n - 1
    return (1 + Fraction(2, nu)) * c ** 2 - 2 * c + 1


n = 10
coefficients = {
    "unbiased": Fraction(1),
    "mle": Fraction(n - 1, n),
    "risk_optimal": Fraction(n - 1, n + 1),
}
risks = {name: scaled_variance_risk(c, n)
         for name, c in coefficients.items()}
assert risks["unbiased"] == Fraction(2, n - 1)
assert risks["mle"] == Fraction(2 * n - 1, n ** 2)
assert risks["risk_optimal"] == Fraction(2, n + 1)
assert risks["risk_optimal"] < risks["mle"] < risks["unbiased"]
print("exact normalized risks:", {k: str(v) for k, v in risks.items()})


# 偏差—方差分解：a*xbar 估计正态均值 mu。
a, mu, sigma2, size = Fraction(3, 4), Fraction(2), Fraction(5), 10
bias = (a - 1) * mu
variance = a ** 2 * sigma2 / size
direct_risk = (a - 1) ** 2 * mu ** 2 + a ** 2 * sigma2 / size
assert bias ** 2 + variance == direct_risk == Fraction(17, 32)


# 不可识别例：只有两个参数之和进入 Bernoulli 成功概率。
def linked_bernoulli_probability(a, b):
    return 1 / (1 + np.exp(-(a + b)))


assert linked_bernoulli_probability(0.2, 0.3) == linked_bernoulli_probability(0.5, 0.0)
assert linked_bernoulli_probability(0.2, 0.3) != linked_bernoulli_probability(0.2, 0.4)
print("identification: only a+b is identified: OK")


# 模拟只审计 n=10 时的风险；精确排序已经由上面的公式决定。
rng = np.random.default_rng(31)
reps, sigma = 100_000, 2.0
samples = rng.normal(loc=3.0, scale=sigma, size=(reps, n))
s2 = np.var(samples, axis=1, ddof=1)
for name, c in coefficients.items():
    estimates = float(c) * s2
    simulated = np.mean((estimates - sigma ** 2) ** 2) / sigma ** 4
    assert abs(simulated - float(risks[name])) < 0.012
print("fixed-seed n=10 risk simulation: OK")
print("END ====")
