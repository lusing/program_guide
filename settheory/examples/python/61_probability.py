# 第 61 章：有限概率的机器化（Makinson Ch6）
# 骰子对 + 辛普森（Fraction 精确）+ 贝叶斯 + 期望 + 性质八条抽查
import sys, io, random
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from fractions import Fraction as F

print("==== 61")

# ---------- 一、骰子对条件概率（Fraction 精确） ----------
S = [(a, b) for a in range(1, 7) for b in range(1, 7)]
pU = F(1, 36)
def ev(pred): return sum(pU for s in S if pred(s))
B = ev(lambda s: s[0] + s[1] == 5)
A = ev(lambda s: s[0] == 3 or s[1] == 3)
AB = ev(lambda s: s[0] + s[1] == 5 and (s[0] == 3 or s[1] == 3))
print(f"  p(B) = {B}，p(A) = {A}，p(A∩B) = {AB}")
print(f"  p(A|B) = {AB/B} > p(A) = {A}（条件化升概率）")
print(f"  p(B|A) = {AB/A} ≠ p(A|B)（不可交换）")

# ---------- 二、性质八条抽查（Exercise 6.1.2 的机器版） ----------
X = ev(lambda s: s[0] == 6); Y = ev(lambda s: s[1] > 4)
XY = ev(lambda s: s[0] == 6 and s[1] > 4)
assert F(0) == ev(lambda s: False) and F(1) == ev(lambda s: True)
assert ev(lambda s: s[0] == 6 or s[1] > 4) == X + Y - XY   # 容斥
assert 1 - X == ev(lambda s: s[0] != 6)                    # 补律
assert X + ev(lambda s: s[0] != 6) == 1                    # 不交分解
print("  补律、容斥、不交加法抽查 ✓")

# ---------- 三、辛普森（精确比值） ----------
simpson = {"女CS": (2, 8), "男CS": (1, 5), "女数": (4, 5), "男数": (6, 8)}
for k, (a, b) in simpson.items():
    print(f"    {k}: {a}/{b} = {F(a, b)}")
print(f"    合计：女 {F(6,13)} < 男 {F(7,13)} ——分系优势在合计反转")

# ---------- 四、贝叶斯 ----------
print("  癌症检查 p(C|P) =", F(1, 1) / (1 * 100 + 20 * 99) * 100 * 100 // 1
      if False else round((0.01 * 1) / (0.01 * 1 + 0.2 * 0.99), 4), "（直觉 0.83）")
print("  HIV 0.15：", round((0.9 * 0.15) / (0.9 * 0.15 + 0.03 * 0.85), 3))
print("  HIV 0.60：", round((0.9 * 0.60) / (0.9 * 0.60 + 0.03 * 0.40), 3))
print("  接线员：", round(0.9 * 0.3 / (0.6 * 0.33 + 0.7 * 0.37 + 0.9 * 0.3), 3))

# ---------- 五、期望三马 ----------
p = [0.1, 0.3, 0.6]; f = [12, -1, -1]
print("  μ =", sum(fi * pi for fi, pi in zip(f, p)), " vs 平均 =", sum(f) / 3)

# ---------- 六、蒙特卡洛复核 ----------
random.seed(7)
n = d = 0
for _ in range(200_000):
    s = (random.randint(1, 6), random.randint(1, 6))
    if s[0] + s[1] == 5:
        d += 1
        n += (s[0] == 3 or s[1] == 3)
print("  蒙特卡洛 p(A|B) ≈", round(n / d, 4), "（真值 0.5）")

print("END ====")
