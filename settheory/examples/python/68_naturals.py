# 第 68 章：自然数与第一递归定义定理（冯琦 §1.3）
# 第一递归定理与强递归推论的可执行化身；三明治引理（希尔伯特旅馆）；
# 双归纳交换律网格验证；鸽子笼枚举。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import product

print("==== 68")

# ---------- 一、定理 1.12 / 推论 1.2 的可执行化身 ----------

def primrec(a, g, N):
    """第一递归定义定理：f(0)=a; f(n+1)=g(f(n), n)"""
    f = {0: a}
    for n in range(N):
        f[n + 1] = g(f[n], n)
    return f

def corec(g, N):
    """推论 1.2（强递归）：f(n) = g(f|n)——由之前所有值决定"""
    f = {}
    for n in range(N + 1):
        f[n] = g([f[i] for i in range(n)])
    return f

fact = primrec(1, lambda x, n: x * (n + 1), 10)
fib = corec(lambda p: p[-1] + p[-2] if len(p) >= 2 else (1 if len(p) == 1 else 0), 12)
catalan = corec(lambda p: sum(p[i] * p[len(p) - 1 - i] for i in range(len(p))) if p else 1, 10)
print("阶乘  :", [fact[n] for n in range(6)])
print("Fibonacci:", [fib[n] for n in range(9)])
print("Catalan :", [catalan[n] for n in range(8)], "（强递归的招牌：f(n)=Σf(i)f(n-1-i)）")

# ---------- 二、三明治引理（引理 1.4）：希尔伯特旅馆 ----------
# A ⊇ B，f(x)=x+2 双射 A→f[A]。递归 A_{n+1}=f[A_n]、B_{n+1}=f[B_n]，
# E = ⋃(A_n − B_n)，D = A − E；拼合 g = "E 段压一层、D 段不动"。
An, Bn = set(range(24)), set(range(1, 24))
Es = []
for n in range(10):
    En = {x for x in (An - Bn) if x < 20}   # 截去边界装饰，看芯
    Es.append(sorted(En))
    An = {x + 2 for x in An}
    Bn = {x + 2 for x in Bn}
assert Es == [[2 * n] for n in range(10)], Es
E = set(range(0, 24, 2))                     # 偶数段
D = set(range(1, 24, 2))                     # 奇数段
g = lambda x: x + 2 if x % 2 == 0 else x
img = sorted(g(x) for x in range(24))
assert img == list(range(1, 25))
print("E_n = {2n}（芯前 10 步）✓   拼合双射 g: 0↦2, 1↦1, 2↦4, 3↦3 …")
print("g 把 ℕ 双射到 ℕ∖{0}（24 步截段验证 ✓）——三明治引理现场")

# ---------- 三、双归纳交换律（定理 1.16(1)）网格验证 ----------
def vadd(m, n):          # 定理 1.15 的原始递归：递归在第二变元
    r = m
    for _ in range(n):
        r += 1
    return r

for m in range(15):
    for n in range(15):
        assert vadd(m, n) == vadd(n, m) == m + n
print("vadd 交换律 15×15 网格全对 ✓")

# ---------- 四、鸽子笼枚举（定理 1.10） ----------
maps43 = list(product(range(3), repeat=4))
maps33 = list(product(range(3), repeat=3))
n43 = sum(1 for v in maps43 if len(set(v)) == 4)
inj33 = [v for v in maps33 if len(set(v)) == 3]
print("4→3 映射数 =", len(maps43), " 单射数 =", n43)
print("3→3 单射数 =", len(inj33), " 全部满射 =", all(set(v) == {0, 1, 2} for v in inj33))

print("END ====")
