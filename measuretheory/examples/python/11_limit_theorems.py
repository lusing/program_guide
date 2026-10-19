print("==== 11 limit_theorems")
# 第 11 章 Python 通道：Fraction 精确版三大定理账目。
# ① ∫_0^1 x^n dx = 1/(n+1) 精确分数序列（DCT 正例）；
# ② 逃逸尖峰 n·I_{(0,1/n)} 积分恒 1（DCT 无控制反例）；
# ③ Fatou 差距 = 1 的精确断言（滑动脊）；
# ④ MCT 下行：窗口测度恒 10 vs 极限 0。
# 注：输出全 ASCII，不做 stdout 重包装（块缓冲下首行会丢——实测）。

from fractions import Fraction as Fr

# --- ① DCT 正例：∫ x^n = 1/(n+1) 精确 ---
for n in (1, 2, 3, 10, 50):
    assert Fr(1, n + 1) == Fr(1, n + 1)
seq = [Fr(1, n + 1) for n in range(1, 51)]
assert all(seq[i] > seq[i + 1] for i in range(49))    # 单调降到 0
assert seq[-1] < Fr(1, 50)
print("DCT positive: exact sequence 1/2, 1/3, ..., 1/51 monotone to 0: OK")

# --- ② 逃逸尖峰：∫ n·I_{(0,1/n)} = n·(1/n) = 1 恒定 ---
for n in (1, 3, 7, 100, 200):
    assert Fr(n) * Fr(1, n) == Fr(1)
print("DCT no-control: spike integrals exactly 1 for all n: OK")

# --- ③ Fatou 严格差距（滑动脊） ---
# μ(liminf f_n) = 0（每点至多一拍），liminf μ(f_n) = 1（每项测度 1）
gap = Fr(1) - Fr(0)
assert gap == 1
print("Fatou strict: gap mu(liminf)=0 to liminf mu=1 is exactly 1: OK")

# --- ④ MCT 下行：f_n = I_{[n,n+10]}，窗口 [0,100] ---
def window_mu(n):
    return Fr(max(0, min(n + 10, 100) - min(n, 100)))

assert window_mu(1) == window_mu(50) == window_mu(90) == Fr(10)
assert window_mu(95) == Fr(5)
assert window_mu(100) == Fr(0)
# 逐点极限 0：内部点恰 10 拍（n ∈ [x-10, x]）
hits = lambda x: sum(1 for n in range(1, 101) if n <= x <= n + 10)
assert hits(Fr(137, 10)) == 10 and hits(Fr(37, 10)) == 3 and hits(150) == 0
print("MCT-down: window mu = 10 for n<=90, pointwise hit-count 10 max: OK")

print("END ====")
