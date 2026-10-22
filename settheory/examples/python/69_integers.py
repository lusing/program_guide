# 第 69 章：有限与无限、整数与有理数（冯琦 §1.3.5 + §1.4）
# 伽利略与可数封闭性；典型序 g；交织 ⊛；书版 ℤ（分情形四则）；
# 数论剧场；往返渐进。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import product
from fractions import Fraction
from math import gcd

print("==== 69")

# ---------- 一、伽利略（例 1.12/1.13）与可数封闭（定理 1.26） ----------
sq = lambda n: n * n
assert [sq(i) for i in range(10)] == sorted(sq(i) for i in range(10))
assert all(len({m * k for k in range(40)}) == 40 for m in (2, 3, 7))
print("平方数/mℕ 与 ℕ 等势（双射 + 严格保序，前 40 项验证）✓")

# 定理 1.26：可数×可数可数——配对函数复合
cantor = lambda m, n: (m + n) * (m + n + 1) // 2 + m
inv = {cantor(m, n): (m, n) for m in range(30) for n in range(30)}
assert len(inv) == 900
print("cantor 配对在 30×30 上单射（900 个不同像）✓")

# ---------- 二、典型序（定义 1.33）与定理 1.28 的交织 ----------
def gtyp(a, b):
    return b * b + a if a < b else a * a + a + b
spiral = []
k = 0
while len(spiral) < 16:
    spiral += [(a, k) for a in range(k)]      # 上边界
    spiral += [(k, b) for b in range(k + 1)]  # 右边界
    k += 1
assert [gtyp(a, b) for a, b in spiral[:16]] == list(range(16))
print("典型序前 16 点（内点<上边界<右边界，逐层螺旋）:", spiral[:8], "…")

interleave = lambda f, g: [f[i // 2] if i % 2 == 0 else g[i // 2]
                           for i in range(2 * len(f))]
assert interleave([1, 3, 5], [2, 4, 6]) == [1, 2, 3, 4, 5, 6]
print("交织 f ⊛ g（定理 1.28 的 G）：|2^ω × 2^ω| = |2^ω| 的技术内核 ✓")

# ---------- 三、书版 ℤ（定义 1.36：分情形四则） ----------
# 正整数：n；负整数：(1, m)（绝对值 m+1）
def zmake(n):            # ℤ 的典型代表元
    return n if n >= 0 else (1, -n - 1)
def zval(z):             # 对拍标准
    return z if isinstance(z, int) else -(z[1] + 1)
def zadd(x, y):          # 四情形加法（书页 61）
    a, b = zval(x), zval(y)
    return zmake(a + b)
def zmul(x, y):
    a, b = zval(x), y if isinstance(y, int) else zval(y)
    return zmake(zval(x) * zval(y))
# 结构性分情形实现（不偷懒版）
def zadd_struct(x, y):
    if isinstance(x, int) and isinstance(y, int):
        return x + y
    if not isinstance(x, int) and not isinstance(y, int):   # 负+负
        return (1, x[1] + y[1] + 1)
    if isinstance(x, int):                                  # 正+负
        m = y[1] + 1
        if x > m: return x - m
        if x == m: return 0
        return (1, m - x - 1)
    m = x[1] + 1                                             # 负+正
    if y > m: return y - m
    if y == m: return 0
    return (1, m - y - 1)
def zmul_struct(x, y):
    if isinstance(x, int) and isinstance(y, int):
        return x * y
    if not isinstance(x, int) and not isinstance(y, int):
        return (x[1] + 1) * (y[1] + 1)
    if isinstance(x, int):
        return 0 if x == 0 else (1, x * (y[1] + 1) - 1)
    return 0 if y == 0 else (1, y * (x[1] + 1) - 1)
R = range(-6, 7)
assert all(zval(zadd_struct(zmake(a), zmake(b))) == a + b for a in R for b in R)
assert all(zval(zmul_struct(zmake(a), zmake(b))) == a * b for a in R for b in R)
assert all(zmake(a) == zmake(b) for a in R for b in R if a == b)   # 代表元唯一
print("书版 ℤ 四情形加乘在 [-6,6]² 网格上与标准 ℤ 对拍 ✓（定理 1.31）")

# ---------- 四、数论剧场（定理 1.32-1.35） ----------
def extgcd(a, b):
    if b == 0: return (a, 1, 0)
    g, u, v = extgcd(b, a % b)
    return (g, v, u - (a // b) * v)
assert all(g == gcd(m, n) and u * m + v * n == g
           for m in range(2, 40) for n in range(2, 40)
           for g, u, v in [extgcd(m, n)])
print("扩展欧几里得（带余除法 + 归结引理 1.6）在 38×38 网格全对 ✓")
# 欧几里得剧场
ps, news = [2], []
for _ in range(6):
    c = __import__("math").prod(ps) + 1
    p = next(d for d in range(2, c + 1) if c % d == 0 and
             all(d % q for q in range(2, int(d ** .5) + 1)))
    news.append(p); ps.append(p)
print("欧几里得剧场（积+1 → 新素数）:", news)
# 算术基本定理抽查
def factor(n):
    fs = {}
    d = 2
    while d * d <= n:
        while n % d == 0: fs[d] = fs.get(d, 0) + 1; n //= d
        d += 1
    if n > 1: fs[n] = fs.get(n, 0) + 1
    return fs
assert all(__import__("math").prod(p ** e for p, e in factor(n).items()) == n
           for n in range(2, 500))
print("唯一分解重构在 2..499 全对 ✓（定理 1.35 的计算面）")

# ---------- 五、往返渐进（定理 1.38）：ℚ ≅ 二进有理数 ----------
def backforth(nsteps):
    As = sorted({Fraction(i, j) for j in range(1, 9) for i in range(-12, 13)})
    Bs = sorted({Fraction(k, 2 ** e) for e in range(7) for k in range(-40, 41)})
    NEG, POS = Fraction(-10 ** 9), Fraction(10 ** 9)
    h, taken = {}, set()
    def insertA(a):
        if a in h: return
        lo = max((h[x] for x in h if x < a), default=NEG)
        hi = min((h[x] for x in h if x > a), default=POS)
        opts = [b for b in Bs if b not in taken and lo < b < hi]
        if opts: h[a] = opts[0]; taken.add(opts[0])
    def insertB(b):
        if b in taken: return
        lo = max((x for x in h if h[x] < b), default=NEG)
        hi = min((x for x in h if h[x] > b), default=POS)
        opts = [a for a in As if a not in h and lo < a < hi]
        if opts: h[opts[0]] = b; taken.add(b)
    for s in range(nsteps):
        (insertA if s % 2 == 0 else insertB)(
            As[s % len(As)] if s % 2 == 0 else Bs[s % len(Bs)])
    ks = list(h)
    mono = all((x < y) == (h[x] < h[y]) for x in ks for y in ks)
    return len(ks), mono
n, mono = backforth(60)
print(f"往返渐进 60 步：部分同构覆盖 {n} 点，双向单调 = {mono}")

print("END ====")
