# -*- coding: utf-8 -*-
print("==== 12 goodstein")
# 第 12 章 Python：古德斯坦定理的机器面（书 4.5）。
# ① S_n：超底展开后底 +1（定义 4.5.1）——书例 S₂(89) 精确复算；
# ② g_n 序列（定义 4.5.6）——书载 m=13 的九个值全部精确复现；
# ③ f_n：底换 ω 的序数赋值（定义 4.5.4）——嵌套 CNF 表示
#    （指数本身也是序数）；
# ④ 定理 4.5.7 的引擎审计：f_{n+1}(g_n(m)) 沿 n 严格下降——
#    "序数无下降链"在样本上的显形；
# ⑤ m ≤ 3 的完整终止 + m=4 的不可行说明（步数 3·2^402653211−3）。

# 序数表示：嵌套 CNF——tuple of (coeff, exponent)，exponent 递归。
# 0 = ()；自然数 k = ((k, ()),)（即 k·ω⁰）。
def onat(k):
    return ((k, ()),) if k else ()


def fn(m, n):
    """m 的 n 进超底展开，底换 ω（定义 4.5.4）。"""
    if m < n:
        return onat(m)
    # m = k·n^t + b，t 是最大指数，k 是首位数字，b 是余部
    t = 0
    while n ** (t + 1) <= m:
        t += 1
    k = m // (n ** t)
    b = m - k * n ** t
    return merge(onat(k), fn(t, n), fn(b, n))


def merge(k, e, rest):
    """ω^e·k + rest 的 CNF 合并（e 是指数序数）。"""
    out = list(rest)
    if out and out[-1][1] == e:
        out[-1] = (out[-1][0] + k, e)
    else:
        out.append((k, e))
    return tuple(out)


def olt(a, b):
    """嵌套 CNF 比较：高位指数优先。"""
    a, b = canon(a), canon(b)
    if not a:
        return bool(b)
    if not b:
        return False
    (ca, ea), (cb, eb) = a[-1], b[-1]
    if ea != eb:
        return olt(ea, eb)                    # 指数先比
    if ca != cb:
        return ca < cb
    return olt(a[:-1], b[:-1])


def canon(a):
    return tuple(term for term in a if term[0])


def S(m, n):
    """超底换底函数 S_n（定义 4.5.1）。"""
    if m < n:
        return m
    t = 0
    while n ** (t + 1) <= m:
        t += 1
    k = m // (n ** t)
    b = m - k * n ** t
    return k * (n + 1) ** S(t, n) + S(b, n)


def g(m, n):
    """g_n(m)：底 n 的换底值减一（定义 4.5.6）。"""
    s = S(m, n)
    return s - 1 if s > 0 else 0


# ① 书例 4.5.2：S₂(89) = 213516729579718
assert S(89, 2) == 213516729579718
print("S2(89) = 213516729579718 (book example 4.5.2 exact): OK")

# ② 书载 g 序列（m=13）的九个值精确复现。
# 机器自纠：书（OCR）第 7 项作 134219591，但书载第 8 项 3486786855
# 只能从 134219479 推出（S₇(5765998)=8^9+1752−1）——原值应如机器。
table = [13, 108, 1279, 16092, 280711, 5765998,
         134219479, 3486786855, 100000003325]
vals = [13]
cur = 13
for n in range(2, 11):
    cur = g(cur, n) if cur else 0
    vals.append(cur)
assert vals[:9] == table, vals
print("g-sequence of 13: 9 book values exact (7th corrected by machine): OK")

# ③④ f 值严格下降（定理 4.5.7 的引擎）
cur = 13
prev = fn(13, 2)
descents = []
for n in range(2, 11):
    cur = g(cur, n) if cur else 0
    nxt = fn(cur, n + 1)
    descents.append(olt(nxt, prev))
    prev = nxt
assert all(descents)
print("ordinal descent: f_{n+1}(g_n(13)) strictly decreases for 9 steps: OK")

# 练习 4.5.3：S₃(4)
# 4 = 1·3¹ + 1 → S₃(4) = 1·4¹ + S₃(1) = 5
assert S(4, 3) == 5
print("S3(4) = 5 (exercise 4.5.3): OK")

# ⑤ 小值的完整终止
for m0 in (1, 2, 3):
    cur, n, steps = m0, 2, 0
    while cur > 0:
        cur = g(cur, n)
        n += 1
        steps += 1
        assert steps < 200
    print("goodstein(%d) terminates at step %d" % (m0, steps))
# goodstein(4) 需要 3·2^402653211-3 步——只在注释里存在
print("full termination for m <= 3; goodstein(4) needs 3*2^402653211-3 steps: OK")
print("END ====")
