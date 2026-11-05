# 第 04 章 实数域（上）：Python 通道。
# Float 违反结合律、Fraction 满足全部域公理抽查、Z5 全枚举、Z 无逆元。
# 运行：python -I 04_field.py
from fractions import Fraction

print("==== 04 field ====")

# --- 1. Float64 不是域：大数吞噬小加数 --------------------------------
# (1 + (-1e100)) + 1e100 = 0，而 1 + ((-1e100) + 1e100) = 1。
left = (1.0 + -1e100) + 1e100
right = 1.0 + (-1e100 + 1e100)
assert left != right
print("float assoc counterexample:", left, "vs", right)

# --- 2. Fraction 满足域公理（抽样） -----------------------------------
qs = [Fraction(1, 2), Fraction(-3, 7), Fraction(22, 7), Fraction(0), Fraction(355, 113)]
for a in qs:
    for b in qs:
        for c in qs:
            assert (a + b) + c == a + (b + c)
            assert (a * b) * c == a * (b * c)
            assert a + b == b + a and a * b == b * a
            assert a * (b + c) == a * b + a * c
        assert a + 0 == a and a * 1 == a and a + (-a) == 0
        if a != 0:
            assert a * (1 / a) == 1
print("Fraction: field axioms verified on samples")

# --- 3. Z5 全枚举 ------------------------------------------------------
z5add = lambda a, b: (a + b) % 5
z5mul = lambda a, b: (a * b) % 5
for a in range(5):
    for b in range(5):
        for c in range(5):
            assert z5add(z5add(a, b), c) == z5add(a, z5add(b, c))
            assert z5mul(z5mul(a, b), c) == z5mul(a, z5mul(b, c))
            assert z5add(a, b) == z5add(b, a) and z5mul(a, b) == z5mul(b, a)
            assert z5mul(a, z5add(b, c)) == z5add(z5mul(a, b), z5mul(a, c))
for a in range(1, 5):
    assert any(z5mul(a, b) == 1 for b in range(1, 5))
assert z5add(2, 3) == 0 and z5mul(2, 3) == 1
print("Z5: full enumeration passed (2+3=0, 2*3=1)")

# --- 4. Z 不是域 --------------------------------------------------------
assert not any(2 * z == 1 for z in range(-1000, 1001))
print("Z: no integer z with 2z = 1")

print("END ====")
