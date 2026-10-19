import io
import sys
import random
from fractions import Fraction

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 05 stieltjes")

# 第 05 章：LS 测度（与 Julia 对拍：Cantor 测度用整数三元组精确表示，
# 自相似方程精确可解）。

# --- 原子分布 ---
def F_atom(x):
    return sum(0.25 for k in (1, 2, 3, 4) if k <= x)

assert F_atom(0.5) == 0.0 and F_atom(1.0) == 0.25 and F_atom(4.0) == 1.0
muF = lambda F, a, b: F(b) - F(a)
assert abs(muF(F_atom, 0.5, 3.5) - 0.75) < 1e-15
print("原子 F：μ(0.5,3.5] = 0.75，单点质量 0.25（右连续）")

# --- Cantor 测度：精确三分递推 ---
# 深度 d 的 Cantor 集由 2^d 个长度 3^-d 的块组成，每块质量 2^-d
# 用分数精确验证自相似与总质量
def cantor_mass(depth):
    return [Fraction(1, 2 ** depth)] * (2 ** depth), Fraction(1, 3 ** depth)

blocks, blen = cantor_mass(6)
assert sum(blocks) == 1, "总质量恒为 1"
print(f"Cantor 深度 6：{len(blocks)} 块 × 长度 {float(blen):.5f}，质量各 {float(blocks[0]):.5f}")

# 自相似：前 1/3 承载 1/2
blocks5, _ = cantor_mass(5)
assert sum(blocks5[:16]) == Fraction(1, 2)
print("自相似：前 1/3 的块承载总质量 1/2（精确）")

# 中段质量为零：任意深度挖空段测度 0
# 深度 d 挖空的段在 (1/3, 2/3) 等——由构造无块覆盖
left_third = [b for b, pos in zip(*[blocks5, [i for i in range(32)]]) if pos < 16]
assert sum(left_third) == Fraction(1, 2)

# --- Cantor 函数的有限精度版（与 Julia 实现对拍） ---
def cantor_F(x, depth=40):
    if x <= 0:
        return 0.0
    if x >= 1:
        return 1.0
    acc = 0.0
    y = x
    for i in range(1, depth + 1):
        y *= 3
        dg = int(y)
        if dg == 1:
            return acc + 2.0 ** (-i)
        if dg == 2:
            acc += 2.0 ** (-i)
        y -= dg
    return acc

xs = [i / 1000 for i in range(1001)]
Fv = [cantor_F(x) for x in xs]
assert Fv[0] == 0.0 and abs(Fv[-1] - 1.0) < 1e-12
assert all(Fv[i] <= Fv[i + 1] + 1e-9 for i in range(1000)), "单调"
assert abs((cantor_F(1 / 3) - cantor_F(0.0)) - 0.5) < 1e-9
assert cantor_F(2 / 3) - cantor_F(1 / 3) < 1e-9
print("Cantor F：端点/单调/自相似/中段零 全部 OK")

# --- Cantor 抽样（二进 → 三进逆映射） ---
random.seed(5)
n = 20000
cnt_first_third = 0
cnt_middle = 0
for _ in range(n):
    u = random.random()
    x = 0.0
    for i in range(1, 31):
        u *= 2
        x += (2 if u >= 1 else 0) / 3 ** i
        if u >= 1:
            u -= 1
    if x < 1 / 3:
        cnt_first_third += 1
    elif 1 / 3 < x < 2 / 3:
        cnt_middle += 1

f1 = cnt_first_third / n
fm = cnt_middle / n
assert abs(f1 - 0.5) < 0.02, f"前 1/3 频率 {f1}"
assert fm < 0.001, f"中段频率 {fm}"
print(f"Cantor 抽样 2 万点：前 1/3 频率 {f1:.4f}（理论 0.5），中段 {fm}")

print("END ====")
