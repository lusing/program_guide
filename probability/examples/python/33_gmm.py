# -*- coding: utf-8 -*-
"""第 33 章：线性矩条件、两步 GMM、最优权重与 J 统计量。"""
from fractions import Fraction as F
import numpy as np

print("==== 33 gmm")


def scalar_linear_gmm(a, g, w):
    """最小化 (a-g*theta)'*w*(a-g*theta)，返回精确标量解。"""
    numerator = sum(g[i] * w[i][j] * a[j]
                    for i in range(len(g)) for j in range(len(g)))
    denominator = sum(g[i] * w[i][j] * g[j]
                      for i in range(len(g)) for j in range(len(g)))
    assert denominator != 0
    return numerator / denominator


def scalar_sandwich(g, w, s):
    """sqrt(n) 估计误差的渐近方差，全部按一维参数公式计算。"""
    gwg = sum(g[i] * w[i][j] * g[j]
              for i in range(len(g)) for j in range(len(g)))
    gwsgw = sum(g[i] * w[i][j] * s[j][k] * w[k][ell] * g[ell]
                for i in range(len(g)) for j in range(len(g))
                for k in range(len(g)) for ell in range(len(g)))
    return gwsgw / gwg ** 2


# 三个成对观测；两个矩为 X1-theta 与 X2-theta。
pairs = [(F(1), F(2)), (F(3), F(6)), (F(2), F(1))]
n = len(pairs)
a = [sum(pair[j] for pair in pairs) / n for j in range(2)]
g = [F(1), F(1)]
identity = [[F(1), F(0)], [F(0), F(1)]]
known_s = [[F(1), F(0)], [F(0), F(4)]]
known_precision = [[F(1), F(0)], [F(0), F(1, 4)]]
assert a == [F(2), F(3)]

# 一步等权与已知总体协方差下的最优 GMM。
theta_one = scalar_linear_gmm(a, g, identity)
theta_star = scalar_linear_gmm(a, g, known_precision)
assert theta_one == F(5, 2)
assert theta_star == F(11, 5)
residual = [a[j] - g[j] * theta_star for j in range(2)]
assert residual == [F(-1, 5), F(4, 5)]
q_star = sum(residual[i] * known_precision[i][j] * residual[j]
             for i in range(2) for j in range(2))
assert q_star == F(1, 5)
assert n * q_star == F(3, 5)  # J=nQ；本例 q-p=1。

omega_one = scalar_sandwich(g, identity, known_s)
omega_star = scalar_sandwich(g, known_precision, known_s)
assert omega_one == F(5, 4)
assert omega_star == F(4, 5)
assert omega_star == 1 / sum(g[i] * known_precision[i][j] * g[j]
                            for i in range(2) for j in range(2))
print("one-step theta:", theta_one, "; optimal theta:", theta_star)
print("scaled asymptotic variances:", omega_one, omega_star,
      "; J at known optimal weight:", n * q_star)


# 从一步估计的逐观测残差构造非中心二阶矩，再做第二步。
moment_vectors = [[pair[j] - theta_one for pair in pairs] for j in range(2)]
s_hat = [[sum(moment_vectors[i][t] * moment_vectors[j][t]
              for t in range(n)) / n for j in range(2)] for i in range(2)]
assert s_hat == [[F(11, 12), F(13, 12)], [F(13, 12), F(59, 12)]]
det = s_hat[0][0] * s_hat[1][1] - s_hat[0][1] * s_hat[1][0]
assert det == F(10, 3)
w_two = [[s_hat[1][1] / det, -s_hat[0][1] / det],
         [-s_hat[1][0] / det, s_hat[0][0] / det]]
theta_two = scalar_linear_gmm(a, g, w_two)
assert theta_two == F(43, 22)
residual_two = [a[j] - theta_two for j in range(2)]
j_two = n * sum(residual_two[i] * w_two[i][j] * residual_two[j]
                for i in range(2) for j in range(2))
assert j_two == F(9, 11)
print("two-step S_hat:", s_hat, "; theta:", theta_two, "; J:", j_two)


# 同一公式用浮点矩阵接口再算一次，便于推广到 qxp 的一般线性问题。
def linear_gmm(a_array, g_array, w_array):
    """一般线性 GMM：(G'WG)^(-1)G'Wa。"""
    return np.linalg.solve(g_array.T @ w_array @ g_array,
                           g_array.T @ w_array @ a_array)


a_float = np.array([2.0, 3.0])
g_float = np.ones((2, 1))
w_float = np.diag([1.0, 0.25])
assert np.allclose(linear_gmm(a_float, g_float, w_float), [2.2])
assert np.linalg.matrix_rank(np.ones((2, 2))) == 1
print("general matrix interface and singular-weight warning: OK")
print("END ====")
