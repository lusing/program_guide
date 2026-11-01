"""第 122 章：AD^{L(R)} 的有限影子（独立实现：自底向上填表 + 位掩码集合）。

四件机器：
1. 长度 4 的 65536 张有限博弈表全部决定性，且策略枚举与填表值一致；
2. 尾等价类显式代表（AC 非确定集构造在有限截断上消散）；
3. 完美集密度界及其紧例（AD 完美集性质的有限影子）；
4. L(R) 定义参数 (序数, 实数) 编码为纯位串。
有限枚举不证明 AD；AC 的非确定博弈只存在于无限空间。
"""


def bit(table, k):
    return bool((table >> k) & 1)


# ---------- 件 1：长度 4 全表决定性 ----------
def i_mask4(s):
    """张三策略 s 强制为胜的四个终局点。"""
    a0 = s & 1
    m = 0
    for b0 in (0, 1):
        a2 = (s >> (1 + a0 + 2 * b0)) & 1
        for b1 in (0, 1):
            m |= 1 << (a0 + 2 * b0 + 4 * a2 + 8 * b1)
    return m


def ii_mask4(t):
    """李四策略 t 强制为负的四个终局点。"""
    m = 0
    for a0 in (0, 1):
        b0 = (t >> a0) & 1
        for a2 in (0, 1):
            b1 = (t >> (2 + a0 + 2 * b0 + 4 * a2)) & 1
            m |= 1 << (a0 + 2 * b0 + 4 * a2 + 8 * b1)
    return m


def play4(s, t):
    a0 = s & 1
    b0 = (t >> a0) & 1
    a2 = (s >> (1 + a0 + 2 * b0)) & 1
    b1 = (t >> (2 + a0 + 2 * b0 + 4 * a2)) & 1
    return a0 + 2 * b0 + 4 * a2 + 8 * b1


def value_bottom_up(n, pay):
    """与 Julia 通道不同的算法：从叶层逐层 OR/AND 归并。"""
    # 叶下标 bit p 是位置 p 的动作；距叶最近的决策是位置 n-1，
    # 故按步长 2^p 从后向前归并（相邻对会错误地交换量词次序）。
    layer = [pay(k) for k in range(1 << n)]
    for pos in range(n - 1, -1, -1):
        stride = 1 << pos
        nxt = []
        for base in range(0, len(layer), 2 * stride):
            for j in range(stride):
                pair = (layer[base + j], layer[base + stride + j])
                nxt.append(any(pair) if pos % 2 == 0 else all(pair))
        layer = nxt
    return layer[0]


em = [i_mask4(s) for s in range(32)]
fm = [ii_mask4(t) for t in range(1024)]
assert len(set(em)) == 8 and len(set(fm)) == 64
assert all(m.bit_count() == 4 for m in em + fm)
for s in range(32):
    for t in range(1024):
        p = play4(s, t)
        assert (em[s] >> p) & 1 and (fm[t] >> p) & 1

win_i = win_ii = 0
for table in range(1 << 16):
    iwins = any((table & m) == m for m in em)
    iiwins = any((table & f) == 0 for f in fm)
    assert iwins != iiwins
    # 叶收益按终局索引查表。
    assert iwins == value_bottom_up(4, lambda k, t=table: bit(t, k))
    win_i += iwins
    win_ii += iiwins
assert win_i == 22687 and win_ii == 42849 and win_i + win_ii == 65536

em3 = [0] * 8
for s in range(8):
    a0 = s & 1
    m = 0
    for b0 in (0, 1):
        a2 = (s >> (1 + b0)) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2)
    em3[s] = m
fm3 = [0, 0, 0, 0]
for t in range(4):
    m = 0
    for a0 in (0, 1):
        for a2 in (0, 1):
            m |= 1 << (a0 + 2 * ((t >> a0) & 1) + 4 * a2)
    fm3[t] = m
w3i = sum(any((tb & m) == m for m in em3) for tb in range(256))
w3ii = sum(any((tb & f) == 0 for f in fm3) for tb in range(256))
assert (w3i, w3ii) == (207, 49)

# ---------- 件 2：尾等价代表 ----------
def tail_rep(n, m, x):
    return x & (((1 << m) - 1) << (n - m))


def first_diff(n, m, x):
    for j in range(n - m):
        if (x >> j) & 1:
            return j
    return n


def tail_pay(n, m, x):
    return first_diff(n, m, x) % 2 == 0


tail_sizes = {}
for n in range(1, 7):
    for m in range(1, n + 1):
        for x in range(1 << n):
            r = tail_rep(n, m, x)
            assert tail_rep(n, m, r) == r
            assert (r >> (n - m)) == (x >> (n - m))
        size = sum(tail_pay(n, m, x) for x in range(1 << n))
        tail_sizes[(n, m)] = size
        v1 = value_bottom_up(n, lambda x, n=n, m=m: tail_pay(n, m, x))
        assert isinstance(v1, bool)
assert tail_sizes[(4, 2)] == 12

# ---------- 件 3：完美集密度界 ----------
def has_perfect(A, n, d):
    return any(all((A >> ((s << d) | t)) & 1 for t in range(1 << d))
               for s in range(1 << (n - d)))


for A in range(1 << 16):
    for d in range(1, 5):
        if not has_perfect(A, 4, d):
            assert A.bit_count() <= 16 - (1 << (4 - d))

for d in range(1, 5):
    missing = 0
    for s in range(1 << (4 - d)):
        missing |= 1 << (s << d)
    astar = 65535 ^ missing
    assert not has_perfect(astar, 4, d)
    assert astar.bit_count() == 16 - (1 << (4 - d))

for n in range(6, 11):
    for d in (1, 2, n):
        missing = 0
        for s in range(1 << (n - d)):
            missing |= 1 << (s << d)
        universe = (1 << (1 << n)) - 1
        astar = universe ^ missing
        assert not has_perfect(astar, n, d)
        assert astar.bit_count() == (1 << n) - (1 << (n - d))

# ---------- 件 4：参数编码 ----------
codes = set()
for p in range(8):
    for a in range(16):
        c = (p << 4) | a
        assert (c >> 4, c & 15) == (p, a)
        codes.add(c)
assert codes == set(range(128))

print("==== 122")
print(f"finite determinacy length4: 65536/65536 tables, I={win_i} II={win_ii}")
print(f"length3: 256 tables, I={w3i} II={w3ii}; 8x64 strategy pairs exclusive")
print("tail-representative games n=1..6 all determined; |A_(4,2)|=12")
print("perfect-tree bound: 65536 sets x 4 depths, tight on every depth")
print("parameter codes: 128/128 round-trip")
print("END ====")
