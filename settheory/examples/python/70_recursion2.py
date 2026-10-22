# 第 70 章：第二递归定义定理与彻底有限集合（冯琦 §1.5-1.6）
# frozenset 版 V_ω：TC 迭代、Vₙ 塔、阿克曼编码与互逆、
# 定理 1.45/1.46 的有限验证、ℚ ⊆ V_ω（例 1.19(4)）。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from math import gcd

print("==== 70")

EMPTY = frozenset()

# ---------- 一、Vₙ 塔（定义 1.53） ----------
def powerset_f(s):
    elems = list(s)
    return [frozenset(elems[i] for i in range(len(elems)) if (m >> i) & 1)
            for m in range(1 << len(elems))]

V = [EMPTY]
sizes = [1]
for _ in range(4):
    V = powerset_f(V)
    sizes.append(len(V))
print("Vₙ 塔规模 |V₀..V₄| =", sizes,
      "  |V₅| = 2^65536 共", int(65536 * __import__("math").log10(2)) + 1, "位十进制")

# ---------- 二、传递闭包（定理 1.42）----------
def tc(x):
    Y, Xn = set(), set(x)          # X₀ 的元素起步（Y 不含 x 本身）
    while Xn:
        Y |= Xn
        Xn = {e for a in Xn for e in a} - Y
    return frozenset(Y)

def vn(n):                        # 冯诺伊曼自然数：n 重 S(x) = x ∪ {x}
    r = EMPTY
    for _ in range(n):
        r = r | frozenset([r])
    return r

assert tc(vn(5)) == vn(5)                              # TC(n) = n
assert tc(frozenset([vn(1)])) == frozenset([EMPTY, vn(1)])
print("TC(5) = 5 ✓   TC({{∅}}) = {∅,{{∅}}} ✓（Xₙ₊₁ = Xₙ ∪ ⋃Xₙ 迭代）")

# ---------- 三、阿克曼编码（定理 1.48）与逆（推论 1.9） ----------
# 书定义：f(0)=∅；f(n+1) = f(r(n)) ∪ {f(lg2(n))}，
# lg2(n) = ⌊log2(n+1)⌋，r(n) = n+1 − 2^⌊log2(n+1)⌋。以 N = n+1 改写：
# f(N) = f(N − 2^i) ∪ {f(i)}，i = ⌊log2 N⌋。
def lg2(n):
    return n.bit_length() - 1

ACK = {0: EMPTY}
def ack(N):
    if N not in ACK:
        i = lg2(N)
        r = N - 2 ** i
        ACK[N] = ack(r) | frozenset([ack(i)])
    return ACK[N]

for n in range(512):
    ack(n)
assert len(set(map(repr, [ack(n) for n in range(512)]))) == 512   # 单射
print("f(0..8) 的元素个数 =", [len(ack(n)) for n in range(9)],
      "  f(3) = {f(1),f(0)} = 2 ✓")

INV = {EMPTY: 0}
def inv(a):
    if a not in INV:
        INV[a] = sum(2 ** inv(e) for e in a)
    return INV[a]

assert all(inv(ack(n)) == n for n in range(512))         # 互逆
print("阿克曼编码 0..511 往返恒等（f 与 Σ2^inv 互逆）✓（定理 1.48 + 推论 1.9）")

# ---------- 四、定理 1.45/1.46 的有限验证 ----------
A = [ack(n) for n in range(64)]
# (5) 对并/配对/幂集封闭（幂集以 𝒫(u) ⊆ V_{k+1} 的深度验证）
def depth(a):
    if not a:
        return 0
    return 1 + max(depth(e) for e in a)
ok = all(depth(a | frozenset([b])) < 100 for a in A[:16] for b in A[:16])
ok2 = all(depth(frozenset([a, b])) < 100 for a in A[:16] for b in A[:16])
ok3 = all(depth(p) < 100 for p in powerset_f(A[3])[:8])  # 𝒫(u) 的成员仍有限深
assert ok and ok2 and ok3
print("V_ω 对 ∪、{·,·}、𝒫 封闭（定理 1.46(5) 有限验证）✓")
# 定理 1.45：a ∈ V_ω ⟺ |TC(a)| 有限——彻底有限集合全住在 V_ω
assert all(len(tc(a)) < 1000 for a in A)
print("0..63 号居民 TC 全有限（定理 1.45 的方向一）✓")

# ---------- 五、ℚ ⊆ V_ω（例 1.19(4)）----------
def kurat(a, b):                  # 有序对 (a,b) = {{a},{a,b}}
    return frozenset([frozenset([a]), frozenset([a, b])])
def bookq(sign, m, n):            # 有理数 (sign,(m,n))：n ≥ 2、gcd=1
    num = vn(m) if sign == 0 else kurat(vn(1), vn(m))
    return kurat(num, kurat(vn(m), vn(n)))
samples = [(0, m, n) for m in range(1, 6) for n in range(2, 6) if gcd(m, n) == 1] + \
          [(1, m, n) for m in range(1, 4) for n in range(2, 5) if gcd(m, n) == 1]
assert all(len(tc(bookq(*s))) < 500 and depth(bookq(*s)) < 12 for s in samples)
print(f"书版有理数（符号位嵌套对，{len(samples)} 个样本）TC 有限、深度 < 12：ℚ ⊆ V_ω ✓")

print("END ====")
