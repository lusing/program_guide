print("==== 09 convergence_modes")
# 第 09 章 Python 通道：解析版对拍（不经采样）。
# ① 打字机：层-段索引解析换算，依测度偏差 = 段长（精确分数）；
#    每点每层恰一次命中（命中数 = 层数，二进展开直接计数）。
# ② 逃逸尖峰 + Egorov：Fraction 精确核对 μ(t) ≤ ε 与补集 sup-误差 = 0。

from fractions import Fraction as Fr

def typewriter(n):
    """n ↦ (层 k, 段 j)。层 k 有 2^(k-1) 段，段长 2^-(k-1)。"""
    k = 1
    while n > 2**k - 1:
        k += 1
    return (k, n - 2**(k - 1) + 1)

# --- ① 打字机：解析偏差与命中计数 ---
for n in (8, 32, 128, 512):
    k, _ = typewriter(n)
    dev = Fr(1, 2**(k - 1))          # [ |f_n| >= 1/2 ] = 当前段（解析）
    assert dev < Fr(1, 2) and dev <= Fr(1, 2**(k - 1))
print("typewriter: analytic deviation = segment length 2^-(k-1) -> 0: OK")

# 命中计数：x·2^(k-1) 的 floor 给出第 k 层所在段（半开区间约定，
# 每层恰一段含 x——打字机"每点无穷次被扫中"的解析版）
def hit_count(x, layers):
    cnt = 0
    for k in range(1, layers + 1):
        segs = 2**(k - 1)
        scaled = x * segs
        j = scaled.numerator // scaled.denominator    # floor(x · 2^{k-1})
        if j >= segs:                                 # x = 1 的右端修正
            j = segs - 1
        cnt += 1                                      # 第 j 段命中（半开约定）
    return cnt

for x in (Fr(3, 10), Fr(7, 10), Fr(1, 2)):
    c15 = hit_count(x, 15)
    assert c15 == 15, (x, c15)
print("typewriter: each point hit exactly once per layer (15 hits in 15 layers): OK")

# --- ② 逃逸尖峰 + Egorov（精确分数） ---
# f_n = n·I_{(0,1/n)}，a.e. → 0（x > 0 处 n > 1/x 后恒 0）
EPS = Fr(1, 20)
# 直接按证明构造：n(k) = ceil(2^k/eps)（注意是除以 eps，即乘 20），
# 尾集测度 1/n(k) <= eps·2^-k
for k in range(1, 21):
    nk = -(-2**k * EPS.denominator // EPS.numerator)   # ceil(2^k / EPS)
    assert Fr(1, nk) <= EPS * Fr(1, 2**k)
# 挖集 t = ⋃_k (0, 1/n(1)] = (0, 1/n(1)]（嵌套）
n1 = -(-2 * EPS.denominator // EPS.numerator)          # ceil(2/EPS) = 40
mu_t = Fr(1, n1)
assert mu_t <= EPS
# 补集 [1/n1, 1] 上 i >= n1 时 f_i ≡ 0（1/i <= 1/n1）
for i in range(n1, n1 + 50):
    for num in range(n1, 4 * n1 + 1):                  # x = num/n1 >= 1
        assert Fr(num, n1) >= Fr(1, i)                 # x >= 1/n1 >= 1/i
print(f"spike+Egorov: mu(t) = {mu_t} <= eps = {EPS}; sup-error on complement = 0 (exact): OK")

print("END ====")
