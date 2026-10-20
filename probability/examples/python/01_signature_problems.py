# -*- coding: utf-8 -*-
print("==== 01 signature_problems")
# 第 01 章 Python：三个招牌问题的精确分数账（Fraction）。
# ① 生日问题 22/23 的精确判决；② 投篮公式的精确值；
# ③ 几何级数的分数对拍；④ 对冲配平的精确解。
from fractions import Fraction


# ① 生日问题：Pₖ = 1 − 365!/((365−k)!·365^k) 的精确连乘
def birthday_collision(k):
    """k 人中至少两人生日相同的精确概率。"""
    p = Fraction(1)
    for j in range(k):
        p *= Fraction(365 - j, 365)
    return 1 - p


p22 = birthday_collision(22)
p23 = birthday_collision(23)
p24 = birthday_collision(24)
assert p22 < Fraction(1, 2) < p23          # 23 是过半的最小人数
assert p24 > Fraction(1, 2)
print("birthday exact: p22 = ", float(p22), " p23 = ", float(p23), ": OK")

# ② 投篮问题：A 胜率 = p/(1−(1−p)(1−q)) 的精确分数
p, q = Fraction(1, 2), Fraction(2, 5)
r = (1 - p) * (1 - q)                       # 一轮双失的概率
pa = p / (1 - r)
assert r == Fraction(3, 10)
assert pa == Fraction(5, 7)
print("hoops exact: r = 3/10, P(A wins) = 5/7 = ", float(pa), ": OK")

# ③ 几何级数：1 + r + ... + r^11 与 1/(1−r) 的分数间隙账
for r_num, r_den in ((3, 10), (1, 3)):
    rr = Fraction(r_num, r_den)
    partial = sum(rr ** i for i in range(12))
    limit = 1 / (1 - rr)
    gap = limit - partial
    assert 0 < gap <= rr ** 12 * limit      # 余项被 r^12/(1−r) 控制
    print("geometric r = ", rr, ": 12-term gap = ", float(gap), " <= bound: OK")

# ④ 对冲配平：票值 Giants 赢 V = 10000（原赔率 1000:1 押 10），
#    赛前可按 5:1 押 Patriots 金额 h 使两种结局净得相等
V = Fraction(10000)       # Giants 赢时票据价值
stake = Fraction(10)      # 已付票本
odds_p = Fraction(5)      # Patriots 赔率（押 1 赔 5，含本金外的 5 倍）
# Giants 赢：V − h；Patriots 赢：5h − stake。配平：
#   V − h = 5h − stake ⟹ h = (V + stake)/6
h = (V + stake) / (1 + odds_p)
net_win = V - h
net_lose = odds_p * h - stake
assert net_win == net_lose                 # 两结局净得精确相等
assert net_win == Fraction(24995, 3)
print("hedge exact: bet h = ", float(h), ", locked value = ",
      float(net_win), " both ways: OK")

print("END ====")
