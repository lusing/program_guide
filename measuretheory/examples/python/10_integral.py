print("==== 10 integral")
# 第 10 章 Python 通道：Fraction 精确版积分构造。
# ① Σ k·4^-k 部分和的等比-差分封闭式精确核对，极限 = 4/9；
# ② S⁺ 层表示无关性（块拆分不改积分）；
# ③ Markov 精确断言（最紧点 a=1/2，比值 27/32）；
# ④ 截断宇宙的支撑账（"积分有限 ⟹ 支撑有限"的有限影子与无限失效）。
# 注：输出全 ASCII，不做 stdout 重包装——先 print 后换 wrapper 在块缓冲
# 管道下会把首行滞留在旧缓冲里丢失（实测）。

from fractions import Fraction as Fr

W = {k: Fr(1, 2**k) for k in range(1, 41)}
OMEGA = list(range(1, 41))
FULL = sum(W.values())            # = 1 - 2^-40

def mu(A):
    return sum(W[k] for k in A)

# --- ① 精确求和：Σ_{k=1}^n k·4^-k 的封闭式 ---
def partial(n):
    return sum(Fr(k, 4**k) for k in range(1, n + 1))

x = Fr(1, 4)
for n in (5, 10, 20, 40):
    closed = x * (1 - (n + 1) * x**n + n * x**(n + 1)) / (1 - x) ** 2
    assert partial(n) == closed, (n, partial(n), closed)
tail_40 = Fr(4, 9) - partial(40)
assert 0 < tail_40 < Fr(200, 4**40)      # 尾项上界（等比估计）
print("exact summation: closed form matches; tail beyond 40 < 200*4^-40: OK")

# --- ② S⁺ 层：表示无关性 ---
# f = (1/2)·I_{1,2} + 3·I_3 + 0·I_{4,5} 的标准表示 vs 拆块表示
std_val = Fr(1, 2) * mu([1, 2]) + Fr(3) * mu([3]) + Fr(0) * mu([4, 5])
split_val = (Fr(1, 2) * mu([1]) + Fr(1, 2) * mu([2])
             + Fr(3) * mu([3]) + Fr(0) * (mu([4]) + mu([5])))
assert std_val == split_val == Fr(1, 2) * Fr(3, 4) + Fr(3) * Fr(1, 8)
print("S+ layer: representation-independence (split blocks) exact: OK")

# --- ③ Markov 精确版 ---
f = {k: Fr(k, 2**k) for k in OMEGA}
lint_f = sum(f[k] * W[k] for k in OMEGA)      # = partial(40)
true_int = Fr(4, 9)                            # 无穷级数的真值
for a in (Fr(1, 2), Fr(1, 4), Fr(1, 8)):
    tail = mu([k for k in OMEGA if f[k] >= a])
    assert a * tail <= true_int                # 对真值断言（0·∞ 无歧义）
assert mu([1, 2]) == Fr(3, 4)
# 最紧点：a = 1/2 时左端 3/8，右端 4/9，比值恰 27/32
assert (Fr(1, 2) * Fr(3, 4)) / true_int == Fr(27, 32)
print("Markov exact: tightest at a=1/2, ratio exactly 27/32: OK")

# --- ④ 支撑账 ---
# S⁺ 层：h = I_{1,2}（支撑 {1,2}，μ = 3/4 < ∞）积分有限 ✓
assert mu([1, 2]) < FULL
# 非负层的"失败影子"：f ≡ 1 在无限空间支撑无限测度、积分 ∞；
# 截断宇宙里 μ(Ω40) = 1 - 2^-40 有限——有限截断把失效遮住了，
# 但 μ(Ω60)/μ(Ω40) → 1 的比率账显示宇宙在"无限化"：
W60 = sum(Fr(1, 2**k) for k in range(1, 61))
assert W60 - FULL == Fr(1, 2**40) - Fr(1, 2**60)
print("support note: mu(Omega60) - mu(Omega40) = 2^-40 - 2^-60 (infinite shadow): OK")

print("END ====")
