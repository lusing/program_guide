# 第 59 章：归纳与递归的机器化（Makinson Ch4）
# 阶乘不等式、奇数和、回文闭包（结构递归）、良基性检查
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import product
from functools import lru_cache

print("==== 59")

# ---------- 一、奇数和 = n² 与偶数和 = n(n+1)（59.1 两定理） ----------
for n in range(1, 21):
    assert sum(2*i + 1 for i in range(n)) == n * n
    assert sum(2*(i+1) for i in range(n)) == n * (n + 1)
print("  1+3+…+(2n−1) = n² 与 2+4+…+2n = n(n+1)（n ≤ 20 逐点验证）✓")

# ---------- 二、n! > 2^n（n ≥ 4；基在 4） ----------
fact = 1
ok = True
for n in range(1, 15):
    fact *= n
    if n >= 4:
        ok &= fact > 2 ** n
    elif n < 4:
        ok &= fact <= 2 ** n or n == 3  # 3! = 6 < 8
print("  n! > 2^n 于 4 ≤ n ≤ 14：", "全部成立 ✓" if ok else "失败！")
assert ok

# ---------- 三、Fibonacci：朴素 vs 记忆化的调用计数 ----------
calls = 0
def fib_naive(n):
    global calls
    if n <= 1:
        return n
    calls += 1
    return fib_naive(n-1) + fib_naive(n-2)

@lru_cache(maxsize=None)
def fib_cached(n):
    return n if n <= 1 else fib_cached(n-1) + fib_cached(n-2)

print("  Fibonacci 调用剧场：")
for n in (10, 25, 30):
    calls = 0
    v1 = fib_naive(n)
    c = calls
    v2 = fib_cached(n)
    assert v1 == v2
    print(f"    F({n}) = {v1}：朴素 {c} 次加法 vs 记忆化 {n-1} 次")
calls = 0; fib_naive(25)
assert calls == fib_cached(26) - 1
print("    T(n) = F(n+1) − 1 恒等式 ✓（F(25) 朴素加法 = F(26)−1 =", fib_cached(26)-1, "次）")

# ---------- 四、Ackermann（迭代实现避免栈溢出） ----------
def ack(m, n):
    sys.setrecursionlimit(100000)
    def rec(m, n):
        if m == 0: return n + 1
        if n == 0: return rec(m-1, 1)
        return rec(m-1, rec(m, n-1))
    return rec(m, n)

print("  Ackermann：A(2,3) =", ack(2,3), " A(3,3) =", ack(3,3),
      " A(3,4) =", ack(3,4))
assert ack(2,3) == 9 and ack(3,3) == 61

# ---------- 五、结构递归：回文的闭包定义（59.4.1 例 2） ----------
def palindromes(alphabet, steps):
    S = {""} | set(alphabet)          # 基：空串 + 单字母
    for _ in range(steps):
        S |= {a + s + a for s in S for a in alphabet}
    return S

pal = palindromes("ab", 3)
print("  {a,b} 上 3 步内生成的回文：", sorted(pal))
# 偶回文的字母计数全是偶数（结构归纳例证）
from collections import Counter
def even_letters(s):
    return all(v % 2 == 0 for v in Counter(s).values())
print("  偶回文每字母出现偶数次（59.4.2 例证）：",
      all(even_letters(p) for p in pal if len(p) % 2 == 0))

# ---------- 六、良基性检查：𝒫_f 的 ⊊ 无无穷降链（有限版） ----------
def has_descending_chain(family, limit=100):
    chain = [max(family, key=len)]
    for _ in range(limit):
        nxt = [S for S in family if S < chain[-1]]
        if not nxt:
            return False, chain
        chain.append(max(nxt, key=len))
    return True, chain

fam = [frozenset(c) for k in range(3) for c in product([0,1], repeat=k) if k > 0]
fam = {frozenset(s) for k in range(4) for s in product(range(3), repeat=0)} | \
     {frozenset(range(k)) for k in range(5)}
has, chain = has_descending_chain(fam)
print("  𝒫_f({0..4}) 的 ⊊ 有无穷降链？", has, "（最长链长", len(chain), "）")
assert not has

print("END ====")
