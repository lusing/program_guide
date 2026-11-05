# 第 57 章 Python：Cantor 维数的整数证书（fractions.Fraction，零浮点判决）。
# ① 下界侧（s=3/5）：质量分布原理常数 c=1——每个第 n 阶区间
#    ν=2^{-n} ≤ (3^{-n})^{3/5} ⟺ 27^n ≤ 32^n（整数幂直接判定）；
# ② 上界侧（s=7/10）：覆盖和 = (2^{10}/3^7)^{n/10}，几何衰减，
#    几何级数上界 r/(1-r) 用 Fraction 精确算出；
# ③ 三档覆盖账走向（发散/临界/衰减）的整数幂表格；
# ④ Tricot 集盒计数的有限截断斜率。
print("==== 57 hausdorff")
from fractions import Fraction as F

# ---------- ① 下界证书：27^n ≤ 32^n ⟹ ν(I) ≤ d(I)^{3/5} ----------
# Cantor 测度给每个第 n 阶区间（直径 3^-n）质量 2^-n。
# 2^{-n} ≤ (3^{-n})^{3/5} ⟺ 3^{3n/5} ≤ 2^n ⟺ (3^3)^n ≤ (2^5)^n ⟺ 27^n ≤ 32^n。
for n in range(1, 16):
    assert 27**n <= 32**n                      # 整数不等式：单调显然，机器仍逐项判决
    # 等价核算（5 次幂两侧消去分数指数）：2^{-5n} ≤ 3^{-3n}
    assert F(1, 32**n) <= F(1, 27**n)
print("① 质量分布证书（s=3/5）：27^n ≤ 32^n 对 n=1..15 全部成立")
print("   → 每个第 n 阶区间 ν(I)=2^-n ≤ (3^-n)^{3/5} = d(I)^s，常数 c=1")
print("   → μH[3/5](C) ≥ 1/c = 1 > 0，故 dim_H C ≥ 3/5")

# ---------- ② 上界证书：2^{10n} < 3^{7n} ⟹ 覆盖和几何衰减 ----------
r = F(2**10, 3**7)          # 1024/2187 < 1
assert r < 1 and r.numerator == 1024 and r.denominator == 2187
total = r / (1 - r)          # Σ_{n≥1} r^n 的精确上界
print("② 覆盖账（s=7/10）：2^n·(3^-n)^{7/10} = (1024/2187)^{n/10} = r^{n/10}")
print("   Σ_n r^{n/10} ≤ Σ_n r^n = r/(1-r) =", total, "≈", float(total))
print("   → μH[7/10](C) ≤ r^{1/10}/(1-r^{1/10}) < ∞，且 δ→0 时账 → 0，dim_H C ≤ 7/10")

# ---------- ③ 三档覆盖账的整数幂表 ----------
# 每项 = (2^{10n} / 3^{10ns})^{1/10}：判据用 10 次幂的整数比较。
print("③ 覆盖账走向（整数 10 次幂比较）：")
for s, tag in [(F(3, 5), "s=3/5（发散）"), (F(7, 10), "s=7/10（衰减）")]:
    grow = []
    for n in (2, 6, 10):
        # 账项 > 1 ⟺ 2^{10n} > 3^{10ns}（s=a/b 时即 2^{10bn} vs 3^{10an}）
        lhs = 2 ** (10 * s.denominator * n)
        rhs = 3 ** (10 * s.numerator * n)
        grow.append(lhs > rhs)
    print("   ", tag, "：账项>1 于 n=2,6,10 →", grow)

# ---------- ④ Tricot 集盒计数（有限截断，数值代理） ----------
def tricot_slope(M, K):
    boxes = {M // k for k in range(1, K + 1)}
    import math
    return math.log(len(boxes)) / math.log(M)
for M, K in [(100, 2000), (400, 8000), (1600, 32000)]:
    print("④ Tricot {1/k} 盒斜率：M=", M, "→", round(tricot_slope(M, K), 3),
          "（→ 1/2：dim_H=0，dim_P≥盒下界信号）")

print("END ====")
