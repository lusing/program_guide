print("==== 13 lp_spaces")
# 第 13 章 Python 通道：Fraction 精确版离散 Lp 账目。
# 权与函数值全取 2 的幂，使 p-范数（p=1,2,4）保持精确分数/整数。
# ① Minkowski 精确（p ∈ {1,2,4}）；
# ② Schwarz 取等构造（g = 2f 比值恰 1，整数平方比较）；
# ③ L² 截断列差范数精确归零；
# ④ 对偶方向取到 ‖T‖（整数账）。

from fractions import Fraction as Fr

W = [Fr(1, 2**k) for k in range(1, 7)]      # 1/2..1/64
N = 6

def normp(f, p):
    return sum(w * Fr(abs(x) ** p) for w, x in zip(W, f))

def inner(f, g):
    return sum(w * x * y for w, x, y in zip(W, f, g))

# --- ① Minkowski（p=1 幂和=范数，精确；p=2,4 取根后浮点比较） ---
# 注意：normp 是 p 次幂和，Minkowski 对范数（取 1/p 根后）成立——
# p≠1 时根超出有理数域，账目分两档。
f = [Fr(1), Fr(1, 2), Fr(1, 4), Fr(1), Fr(1, 4), Fr(1, 8)]
g = [Fr(1, 4), Fr(1), Fr(1, 8), Fr(1, 2), Fr(1, 8), Fr(1)]
lhs1 = normp([x + y for x, y in zip(f, g)], 1)
rhs1 = normp(f, 1) + normp(g, 1)
assert lhs1 <= rhs1                            # p=1：幂和即范数，精确
for p in (2, 4):
    lhs = normp([x + y for x, y in zip(f, g)], p) ** (1.0 / p)
    rhs = normp(f, p) ** (1.0 / p) + normp(g, p) ** (1.0 / p)
    assert lhs <= rhs + 1e-12
print("Minkowski: exact at p=1, float-root check at p in {2,4}: OK")

# --- ② Schwarz 取等（g = 2f：⟨f,2f⟩ = 2‖f‖² = ‖f‖‖2f‖） ---
g2 = [2 * x for x in f]
ip = inner(f, g2)
assert ip == 2 * normp(f, 2)
assert ip * ip == normp(f, 2) * normp(g2, 2)   # 平方比较，整数等式
print("Schwarz exact equality at g=2f (integer squared comparison): OK")

# --- ③ L² 截断列差范数（平方账）精确归零 ---
for n in range(N + 1):
    trunc = [f[k] if k < n else Fr(0) for k in range(N)]
    d = normp([x - y for x, y in zip(f, trunc)], 2)   # 平方距离账
    if n < N:
        assert d > 0
    else:
        assert d == 0                            # 第 6 步精确归零
print("L2 truncation tail squared-norm hits exactly 0 at full step: OK")

# --- ④ 对偶表现（p = q = 2：‖T‖ = ‖g‖₂，f = g 方向取到） ---
gv = [Fr(1), Fr(2), Fr(4), Fr(8), Fr(16), Fr(32)]
T_of = inner(gv, gv)                              # T(g) = ⟨g,g⟩ = ‖g‖²（平方账）
assert T_of == normp(gv, 2)
fh = [Fr(1), Fr(1), Fr(1), Fr(1), Fr(1), Fr(1)]
ipfg = inner(fh, gv)
assert ipfg * ipfg <= normp(fh, 2) * normp(gv, 2)   # Cauchy 平方账（精确整数比较）
assert T_of * T_of == normp(gv, 2) * normp(gv, 2)   # f = g 处取等
print("dual: Cauchy |<f,g>|^2 <= ||f||^2||g||^2 exact, attained at f=g: OK")

print("END ====")
