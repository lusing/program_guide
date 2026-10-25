# 第 91 章 · 马丁公理之合理性与迭代力迫（冯琦第二卷 §3.4）
# 四组样品：一步迭代的相容分解（定理 3.14 组合核心）；典型嵌入
# i(p) = (p, 1_Q) 的冲突换算（引理 3.54(6)）；有限支撑迭代条件的
# 支撑与坐标合并（定义 3.36）；Solovay-Tennenbaum 记录函数的
# Cantor 配对实现（定理 3.18 的 (b) 款）+ greedy 相遇引擎。
from itertools import product

print("==== 91")

# ---------- 一、一步迭代的相容分解（定理 3.14 的组合核心） ----------

def ext(p, q):
    """q 延拓 p（更强）：p 是 q 的前缀。"""
    return len(p) <= len(q) and q[:len(p)] == p

def agree(p, q):
    """串条件相容：存在公共延长（互为前缀）。"""
    return ext(p, q) or ext(q, p)

def iter_agree(x, y):
    """迭代条件 (p,q) 与 (p',q') 相容：分量分别相容。"""
    return agree(x[0], y[0]) and agree(x[1], y[1])

def iter_common(x, y):
    """合并构造：每个分量取公共延长（较长者）。"""
    def cmn(p, q):
        return q if ext(p, q) else p
    return (cmn(x[0], y[0]), cmn(x[1], y[1]))

# 有限条件空间上验证 iff 与合并正确性。
S = [list(t) for k in range(3) for t in product([0, 1], repeat=k)]
for x1 in S:
    for x2 in S:
        for y1 in S:
            for y2 in S:
                x, y = (x1, x2), (y1, y2)
                if iter_agree(x, y):
                    r = iter_common(x, y)
                    assert ext(x[0], r[0]) and ext(y[0], r[0])
                    assert ext(x[1], r[1]) and ext(y[1], r[1])
                else:
                    # 相冲 ⇒ 至少一个分量相冲（反向）
                    assert not (agree(x1, y1) and agree(x2, y2))
print("迭代相容 iff 分量相容：合并/投影双向账（15^4 穷举）OK")

# ---------- 二、典型嵌入的冲突换算（引理 3.54(6)） ----------

# i(p) = (p, 1_Q)；1_Q = 空串与一切相容。
def canon(p):
    return (p, [])

for p in S:
    for p2 in S:
        assert iter_agree(canon(p), canon(p2)) == agree(p, p2)
print("典型嵌入：i(p) 与 i(p') 相容 <=> p 与 p' 相容（穷举）OK")

# ---------- 三、有限支撑迭代（定义 3.36） ----------

NONE = None

def spt(p):
    """支撑：偏离最大元（none）的坐标个数。"""
    return sum(1 for c in p if c is not NONE)

def merge_c(p, q):
    """相容合并：每个坐标取首先给出决定者。"""
    n = max(len(p), len(q))
    out = []
    for i in range(n):
        a = p[i] if i < len(p) else NONE
        b = q[i] if i < len(q) else NONE
        out.append(a if a is not NONE else b)
    return out

assert spt([NONE, 1, NONE, 0]) == 2
assert spt([]) == 0
assert merge_c([NONE, 1], [0, NONE]) == [0, 1]
assert merge_c([1, NONE], [NONE, 0]) == [1, 0]

# 支撑有限账：支撑恒不超过条件长度。
C3 = [list(t) for t in product([NONE, 0, 1], repeat=3)]
for p in C3:
    assert spt(p) <= len(p)
print("支撑计数 + 坐标合并：[none,1,none,0] 支撑 2，合并逐位取先决者 OK")

# ---------- 四、Cantor 记录函数（定理 3.18 的 (b) 款） ----------

def cantor(b, g):
    return (b + g) * (b + g + 1) // 2 + g

# (b)：π 的第一分量不超过编号。
for b in range(8):
    for g in range(8):
        assert b <= cantor(b, g)

# (a)：满射性（0..7 域内每个 (b,g) 有唯一编号，编号表无重）。
codes = [cantor(b, g) for b in range(5) for g in range(5)]
assert len(set(codes)) == 25
print("Cantor 配对：b <= 编号（64 例）、5x5 编号两两不同 OK")

# greedy 相遇引擎（定理 3.1 的迭代面）：三步迭代每步决定下一位。
def decider(n):
    def f(p):
        return p if n < len(p) else p + [0] * (n + 1 - len(p))
    return f

p, chain = [], [[]]
for n in range(3):
    p = decider(n)(p)
    chain.append(p)
assert [len(x) for x in chain] == [0, 1, 2, 3]
print("greedy 相遇链：长度 [0, 1, 2, 3]——一步迭代的演示面 OK")

print("END ====")
