# 第 28 章 · 特征值 —— Python 通道

from sympy import Matrix, Rational, Symbol, eye, expand, factor, Poly
from random import seed, randint

print("==== 28 特征值")

# ---------- 谱计算 [[2,1],[1,2]] ----------
x = Symbol('x')
A = Matrix([[2, 1], [1, 2]])
cp = A.charpoly(x).as_expr()        # x² − 4x + 3
assert cp == x ** 2 - 4 * x + 3
assert expand(factor(cp) - (x - 1) * (x - 3)) == 0
evals = A.eigenvals()
assert set(evals) == {1, 3}
# 特征向量 (1,−1)/(1,1)
assert (A * Matrix([1, -1])) == Matrix([1, -1])
assert (A * Matrix([1, 1])) == Matrix([3, 3])
# A^k 闭式：A^k = ((3−3^k)/2)I + ((3^k−1)/2)A
for k in range(1, 11):
    Ak = ((3 - 3 ** k) // 2) * eye(2) + ((3 ** k - 1) // 2) * A
    assert Ak == A ** k
print("[[2,1],[1,2]]：谱 {1,3}、Aᵏ 闭式对拍（k ≤ 10）✓")

# ---------- Fibonacci ----------
fib = [0, 1]
for _ in range(60):
    fib.append(fib[-1] + fib[-2])
F = Matrix([[1, 1], [1, 0]])
for k in range(1, 31):
    Fk = F ** k
    assert Fk[0, 1] == fib[k] and Fk[0, 0] == fib[k + 1]
print("Fibonacci：F^k 分量 = Fibonacci 数（k ≤ 30 精确）✓")

# ---------- 凯莱–哈密顿 ----------
seed(20261104)
for _ in range(20):
    M = Matrix([[randint(-9, 9) for _ in range(3)] for _ in range(3)])
    p = M.charpoly(x).as_expr()
    coeffs = Poly(p, x).all_coeffs()[::-1]        # 低位在前
    val = Matrix.zeros(3, 3)
    for e, c in enumerate(coeffs):
        val = val + c * M ** e
    assert val == Matrix.zeros(3, 3)
print("凯莱–哈密顿：随机 3×3 整数矩阵 p_A(A) = 0（20 组精确）✓")

# ---------- GF(2) 迁移 ----------
B = Matrix([[0, 1], [1, 1]])
# 特征多项式 x²−x−1（整数）→ mod 2 = x²+x+1
pB = B.charpoly(x).as_expr()
assert pB == x ** 2 - x - 1
from sympy import GF
pB2 = Poly(pB, x, modulus=2)
assert pB2.as_expr() == x ** 2 + x + 1
assert factor(pB2.as_expr(), modulus=2) == x ** 2 + x + 1      # 不可约
# B³ = I mod 2
B3 = (B ** 3) % 2
assert B3 == eye(2)
print("GF(2) 迁移：[[0,1],[1,1]] 特征多项式 mod 2 = x²+x+1 不可约；B³ = I ✓")

# ---------- 实对称谱全实 ----------
from sympy import symbols
S3 = Matrix([[2, 1, 0], [1, 3, 1], [0, 1, 2]])
for lam in S3.eigenvals():
    assert lam.is_real
print("实对称矩阵谱全实（3×3 数值例：精确 eigenvals 全实）✓")

print("END ====")
