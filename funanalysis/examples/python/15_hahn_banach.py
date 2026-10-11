import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 15 章 · Hahn-Banach 定理的数值实验（Conway III.5-6）——scipy 通道。"""
import numpy as np
rng = np.random.default_rng(1515)
print("==== 15 hahn-banach (Python) ====")
# 保范延拓
M = np.zeros((5, 2)); M[0,0] = 1; M[1,1] = 1
f_M = np.array([3.0, 4.0])
ext = M @ f_M
assert np.linalg.norm(ext) == np.linalg.norm(f_M) == 5
assert np.dot(ext, M[:,0]) == f_M[0] and np.dot(ext, M[:,1]) == f_M[1]
print(f"extension norm = {np.linalg.norm(ext)}, restriction norm = {np.linalg.norm(f_M)}")
# 分离超平面
x0 = np.array([3.0, 0.0])
sep = x0 / np.linalg.norm(x0)
pts = rng.standard_normal((1000, 2))
pts /= np.linalg.norm(pts, axis=1, keepdims=True)
assert np.all(pts @ sep < x0 @ sep - 0.5)
print(f"separation: ball < {x0 @ sep:.4f}")
print("==== 15 hahn-banach END ====")
