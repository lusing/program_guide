import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 20 章 · 局部凸空间。"""
import numpy as np
rng = np.random.default_rng(2020)
print("==== 20 locally-convex (Python) ====")
# 半范数族 {p_i} 分离点
p1, p2, p3 = lambda x: abs(x[0]), lambda x: abs(x[1]), lambda x: abs(x[2])
x_test = np.array([0.0, 1.0, 0.0])
assert p1(x_test) == 0.0  # p1 alone doesn't separate
assert any(p(x_test) > 0 for p in [p1, p2, p3])  # family separates
print("family {p1,p2,p3} separates: PASS")
print("==== 20 locally-convex END ====")
