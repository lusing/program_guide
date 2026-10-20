# -*- coding: utf-8 -*-
print("==== 43 local_martingales")
# 第 43 章 Python：截断与策略（Fraction 精确版）。
# ① 截断过程的精确期望；② 可料 vs 偷看策略；③ 停止语义。
from fractions import Fraction
from itertools import product

# ① 截断的全树账：乘积过程 M_n = prod(1±0.5) 两步，cap = 2.25
# 全 4 路径：[+,+]: 2.25（>= cap 冻结）；[+,-]: 0.75; [-,+]: 0.75; [-,-]: 0.25
eps = Fraction(1, 2)
cap = Fraction(9, 4)
def stopped_product(path, cap):
    m = Fraction(1)
    for d in path:
        if abs(m) >= cap:
            break                        # 停止语义：冻结
        m *= (Fraction(1) + (eps if d > 0 else -eps))
    return m
vals = [stopped_product(p, cap) for p in product((1, -1), repeat=2)]
avg = Fraction(sum(vals), 4)
assert avg == Fraction(1)                # 停止过程仍是鞅：期望 = 1（精确）
print("stopped product (cap 9/4): exact mean over full tree = 1: OK"

)
# ② 可料 vs 偷看（一步情形的精确账）
# D1, D2 iid ±1；可料策略 H2 = D1（昨日），偷看 H2 = D2（今日）
total_pred = Fraction(0)
total_cheat = Fraction(0)
for D1 in (-1, 1):
    for D2 in (-1, 1):
        total_pred += Fraction(1, 4) * D1 * D2      # E[H·D] = E[D1]E[D2] = 0
        total_cheat += Fraction(1, 4) * D2 * D2     # E[D2²] = 1
assert total_pred == 0
assert total_cheat == 1
print("predictable E[D1*D2] = 0 vs cheating E[D2^2] = 1 exact: OK")

# ③ 停止语义的正确性：冻结（非 clamp）
# 路径 [+,+,-]: 未截断 M3 = 2.25*0.5 = 1.125；截断（cap 2.25）: 冻结在 2.25
assert stopped_product((1, 1, -1), cap) == Fraction(9, 4)
assert stopped_product((1, 1, -1), Fraction(100)) == Fraction(9, 8)   # 大 cap 不触发
print("stopping semantics: freeze at crossing, not clamp: exact: OK"

)
# ④ 非负恢复：|截断 M| 的期望 ≤ cap
for p in product((1, -1), repeat=3):
    v = stopped_product(p, cap)
    assert abs(v) <= cap
print("nonnegative recovery: |stopped M| <= cap on all 8 paths: OK")

print("END ====")
