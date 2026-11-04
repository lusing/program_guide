# 第 18 章 · 环同态 —— Python 通道

from random import seed, randint

print("==== 18 环同态")

# ---------- mod 同态 ℤ₁₂ → ℤ₄ ----------
f124 = lambda k: k % 4
for a in range(12):
    for b in range(12):
        assert f124((a + b) % 12) == (f124(a) + f124(b)) % 4
        assert f124((a * b) % 12) == (f124(a) * f124(b)) % 4
ker = [k for k in range(12) if f124(k) == 0]
im = sorted(set(f124(k) for k in range(12)))
assert ker == [0, 4, 8] and len(im) == 4 and 12 == len(ker) * len(im)
print("ℤ₁₂ → ℤ₄：144 对全查；核 {0,4,8}，12 = 3×4 ✓")

# ---------- 求值同态核统计 ----------
def peval(f, a, p=7):
    v = 0
    for c in reversed(f):
        v = (v * a + c) % p
    return v

cnt = 0
for a in range(7):
    for b in range(7):
        for c in range(7):
            if peval([a, b, c], 2) == 0:
                cnt += 1
assert cnt == 49 and 343 == cnt * 7
print("φ₂ : ℤ₇[x]≤2 → ℤ₇：核恰 49 = 7²（343 = 49×7）✓")

# ---------- 非同态反例 ----------
sq = lambda a: a * a % 7
assert sq(2) != (sq(1) + sq(1)) % 7
print("非同态：平方映射在 1+1 处保乘不保加 ✓")

# 高斯范数
def Ni(a, b):
    return a * a + b * b

assert Ni(2, 2) == 8 and Ni(1, 1) + Ni(1, 1) == 4      # 非加性
seed(20261104)
for _ in range(100):
    z = (randint(-5, 5), randint(-5, 5))
    w = (randint(-5, 5), randint(-5, 5))
    zw = (z[0] * w[0] - z[1] * w[1], z[0] * w[1] + z[1] * w[0])
    assert Ni(*zw) == Ni(*z) * Ni(*w)
print("高斯范数：N 非加性；N(zw) = N(z)N(w)（100 对）✓")

# ---------- ℚ(i) 序对自同构 ----------
def qmul(z, w):
    return (z[0] * w[0] - z[1] * w[1], z[0] * w[1] + z[1] * w[0])

qs = [(0, 0), (1, 0), (0, 1), (0, -1)]
for phi in (lambda z: z, lambda z: (z[0], -z[1])):
    for z in qs:
        for w in qs:
            assert phi(qmul(z, w)) == qmul(phi(z), phi(w))
print("ℚ(i)：恒等与共轭两个自同构保乘（16 对 × 2）✓")

# ---------- ℤ → ℤ/mℤ 核清单 ----------
for m in range(2, 13):
    fm = lambda k, m=m: k % m
    assert sorted(set(fm(k) for k in range(0, 3 * m))) == list(range(m))
print("ℤ → ℤ/mℤ：m = 2..12 像恰为完系 ✓")

print("END ====")
