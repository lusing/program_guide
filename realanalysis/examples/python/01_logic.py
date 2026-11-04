# 第 01 章 数学语言与证明技巧：Python 通道。
# 有限论域上的真值表、量词顺序、归纳公式核验与 ε-δ 数值影子。
# 运行：python -I 01_logic.py
import itertools

print("==== 01 logic ====")

# --- 1. 布尔真值表：德摩根律与逆否命题 ----------------------------
for a, b in itertools.product((True, False), repeat=2):
    assert (not (a or b)) == ((not a) and (not b))
    assert (not (a and b)) == ((not a) or (not b))
    # A→B 用 (not a) or b 表示；逆否 ¬B→¬A 与其真值表相同。
    assert ((not a) or b) == ((not (not b)) or (not a))
print("de Morgan and contrapositive: truth table verified")

# --- 2. 量词顺序：∀x ∃y 与 ∃y ∀x 完全不同 -------------------------
# 无界整数上，每个 x 都有后继 y = x+1（对应 Lean 证明里的见证 x+1）。
assert all((lambda x: x + 1)(x) > x for x in range(-1000, 1000))
# 而在任何有限网格上，不存在一个压过所有元素的 y（最大值没有后继）。
grid = list(range(-5, 5))                # -5..4
assert not any(all(y > x for x in grid) for y in grid)
print("quantifier order: forall-exists true, exists-forall false")

# --- 3. 归纳公式的数值核验 ----------------------------------------
def sum_to(n):
    return n * (n + 1) // 2

for n in range(1, 101):
    assert sum(range(1, n + 1)) == sum_to(n)
print("sum formula 1..n = n(n+1)/2 checked for n = 1..100")

# --- 4. ε-δ 直接证明的数值影子：lim_{x->2} (3x+1) = 7 --------------
for eps in (0.1, 0.01, 0.001, 1e-6):
    delta = eps / 3
    for t in (-0.9, -0.5, 0.0, 0.3, 0.89):
        x = 2 + t * delta
        if abs(x - 2) < delta:
            assert abs((3 * x + 1) - 7) < eps
print("epsilon-delta: delta = eps/3 works for every tested eps")

# 反面对照：故意取 δ = ε（太大），可以找到违反不等式的 x。
found = False
eps = 0.1
for k in range(1001):
    x = 2 - eps + 2 * eps * k / 1000
    if abs(x - 2) < eps and abs((3 * x + 1) - 7) >= eps:
        found = True
        break
assert found
print("epsilon-delta: oversized delta = eps produces a violation (sharpness)")

# --- 5. “任意接近即相等”的有限 ε 网格核验 --------------------------
x = y = 2.0 ** 0.5
assert all(abs(x - y) < eps for eps in (1.0, 1e-6, 1e-12, 1e-15))
print("arbitrarily-close principle checked on finite epsilon grid")

print("END ====")
