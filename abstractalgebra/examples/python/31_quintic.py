# 第 31 章 · 一般五次方程的不可解性 —— Python 通道
#
# x⁵−6x+3 全案：Eisenstein → 不可约 → 恰三实根 → 伽罗瓦群 S₅ → 不可解；
# 对照 x⁵−2（M₂₀ = F₂₀ 可解）。

import sympy as sp
from sympy.combinatorics import (
    AlternatingGroup,
    Permutation,
    PermutationGroup,
    SymmetricGroup,
)

x = sp.Symbol("x")

print("==== 31 一般五次方程的不可解性")

f = sp.Poly(x**5 - 6 * x + 3, x)

# ---------- 第一步：不可约（Eisenstein p = 3） ----------
# 系数 [1, 0, 0, 0, −6, 3]：3 | −6、3 | 3、3 ∤ 1（首项）、9 ∤ 3（常数项）
coeffs = f.all_coeffs()
assert coeffs == [1, 0, 0, 0, -6, 3]
assert coeffs[-2] % 3 == 0                                  # 3 | −6
assert coeffs[-1] % 3 == 0 and coeffs[-1] % 9 != 0          # 3 | 3、9 ∤ 3
assert coeffs[0] % 3 != 0                                   # 3 ∤ 1
assert f.is_irreducible                                     # ⟹ 不可约
print("Eisenstein（p=3）：x⁵−6x+3 在 ℚ 上不可约 ⟹ 群传递、阶被 5 整除 ✓")

# ---------- 第二步：恰三实根 ----------
roots = f.nroots(n=30)
nreal = sum(1 for r in roots if abs(sp.im(r)) < 1e-25)
assert nreal == 3
# 两非实根共轭 ⟹ 复共轭限制在根集上是两个根的对接换位
print(f"实根计数：五根中恰 {nreal} 实 + 2 共轭复 ⟹ 群含对接换位 ✓")

# ---------- 第三步：置换骨架 ----------
S5 = SymmetricGroup(5)
A5 = AlternatingGroup(5)
assert S5.order() == 120 and A5.order() == 60
assert A5.is_subgroup(S5)
# 5-循环 × 对接换位生成整个 S₅（传递 + 对接换位 ⟹ S₅ 的引理内核）
G = PermutationGroup(Permutation(0, 1, 2, 3, 4), Permutation(0, 1))
assert G.order() == 120 and G.is_subgroup(SymmetricGroup(5))
# 3-循环生成 A₅
cyc3 = [Permutation(a, b, c) for a in range(5) for b in range(5)
        for c in range(5) if len({a, b, c}) == 3]
assert PermutationGroup(*cyc3).order() == 60
# 符号同态：对接换位奇、5-循环偶、3-循环偶（循环记法的 (−1)^{len−1} 规律）
assert Permutation(0, 1).signature() == -1
assert Permutation(0, 1, 2, 3, 4).signature() == 1
assert Permutation(0, 1, 2).signature() == 1
print("置换骨架：S₅=120 / A₅=60 / <5-循环,换位>=S₅ / <3-循环>=A₅ ✓")

# ---------- 第四步：A₅ 单 ⟹ S₅ 不可解（机器面：is_solvable） ----------
assert not S5.is_solvable and not A5.is_solvable
# S₅ 的正规列只有 1 ⊂ A₅ ⊂ S₅，A₅ 单且非交换 ⟹ 无交换商列
print("可解性：S₅ 与 A₅ 均不可解（A₅ 单群是链条断裂的一环）✓")

# ---------- 第五步：伽罗瓦群判定 ----------
G5, _alt = sp.galois_group(f, by_name=True)
assert G5.name == "S5"
assert not S5.is_solvable
# 若 f 根式可解 ⟺ 伽罗瓦群可解；S₅ 不可解 ⟹ f 无根式解
print("伽罗瓦群：sympy galois_group(x⁵−6x+3) = S₅（不可解）⟹ 无根式公式 ✓")

# ---------- 对照：x⁵ − 2 可解 ----------
g = sp.Poly(x**5 - 2, x)
assert g.is_irreducible                       # Eisenstein p = 2
G2, _ = sp.galois_group(g, by_name=True)
assert G2.name == "M20"                       # M₂₀ = 20 阶 Frobenius 群 F₂₀
M20 = PermutationGroup(
    Permutation(0, 1, 2, 3, 4),               # 循环部分 ℤ/5
    Permutation(1, 2, 4, 3))                  # 自同构部分 ℤ/4（2 ↦ 2² 的指数 ×2）
assert M20.order() == 20
assert M20.is_solvable
# 数值面：根 2^{1/5}·ω^k
α = 2 ** (sp.Rational(1, 5))
for k in range(5):
    z = α * sp.exp(2 * sp.pi * sp.I * k / 5)
    assert sp.Abs(sp.expand(z**5 - 2)) == 0
print("对照：x⁵−2 的群 M₂₀（=F₂₀，阶 20 可解），根 2^{1/5}ωᵏ 精确验证 ✓")

# ---------- 一般五次：换元不改变可解性 ----------
# 一般五次 x⁵+a₄x⁴+…+a₀ 的伽罗瓦群是 S₅（对 aᵢ 为独立超越元）——
# 特殊化的数值证据：随机整系数五次（不可约 + 恰一对复根 ⟹ S₅）
import random

random.seed(20261104)
s5_count = 0
trials = 0
for _ in range(40):
    cs = [1] + [random.randint(-3, 3) for _ in range(5)]
    poly = sp.Poly(sum(c * x**i for i, c in enumerate(reversed(cs))), x)
    if not poly.is_irreducible:
        continue
    trials += 1
    G_r, _ = sp.galois_group(poly, by_name=True)
    if G_r.name == "S5":
        s5_count += 1
assert trials >= 20 and s5_count >= 10
print(f"随机扫描：不可约五次 {trials} 例中 {s5_count} 例群 = S₅"
      "（通有性佐证）✓")

print("END ====")
