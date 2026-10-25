# 第 90 章 · 力迫基本理论与 CH/AC 独立性（冯琦第二卷 §3.1-3.3）
# 四组样品：定理 3.1 的相遇链引擎（决定型稠密集序列 + 递归链 +
# 相遇记账）；例 3.3 的对角避让（泛型不属于地基）；Fn(3,2) 的
# 27 个条件与 8 个全函数（ccc 有限计数）；力迫关系的原子形态
# （决定集稠密 + 前缀保持 = 真值引理原子条款）。
from itertools import product

print("==== 90")

# ---------- 一、相遇链（定理 3.1 的递归引擎） ----------

# 条件：有限 0/1 串（Fn(omega,2) 的成员，表 = 已定义的前缀）。

def ext(p, q):
    """q 延拓 p（更强）：p 是 q 的前缀。"""
    return len(p) <= len(q) and q[:len(p)] == p

# 决定型稠密集 D_n 的选择函数：把 p 延拓到第 n 位被决定（补 0）。
def decider(n):
    def f(p):
        return p if n < len(p) else p + [0] * (n + 1 - len(p))
    return f

def dense_decide(n):
    """D_n = {p : n 属于 dom p}，extend 是其上的选择函数。"""
    return (lambda p: n < len(p), decider(n))

# 递归链：p_0 = 空条件，p_{k+1} = extend_k(p_k)。
def chain(ds):
    p, out = [], [[]]
    for (D, extf) in ds:
        p = extf(p)
        out.append(p)
    return out

ds = [dense_decide(n) for n in range(4)]
ch = chain(ds)
assert [len(p) for p in ch] == [0, 1, 2, 3, 4]
assert all(ext(ch[k], ch[k + 1]) for k in range(4))
assert all(D(ch[k + 1]) for k, (D, _) in enumerate(ds))   # 相遇记账
print("相遇链：决定型稠密集逐层相遇，链长", [len(p) for p in ch])

# ---------- 二、泛型对角避让（例 3.3 的对角稠密集） ----------

def flip(b):
    return 1 - b

def gen_build_from(bs):
    """第 k 步在位置 k 翻转 b_k 的比特（对角避让构造）。"""
    out = []
    for k, b in enumerate(bs):
        out.append(flip(b[k]))
    return out

# 地基分支表：n 个长度 n 的分支；泛型在第 k 位翻转 b_k——
# 有限尺度上「对角避开」即 g 与每个 b_k 都不同。
ground = [[1, 0, 1, 0], [0, 0, 0, 0], [1, 1, 0, 0], [0, 1, 1, 1]]
g = gen_build_from(ground)
assert g == [0, 1, 1, 0]
assert all(g[k] != ground[k][k] for k in range(len(ground)))
assert all(g != b for b in ground)
print("泛型分支", g, "：与每个地基分支恰在第 k 位不同")

# ---------- 三、Fn(3,2) 计数（ccc 有限引擎） ----------

def compat(f, g):
    """相容：公共定义域上取值一致（None = 未定义）。"""
    return all(not (a is not None and b is not None and a != b)
               for a, b in zip(f, g))

# 全体条件：每个坐标 None / 0 / 1，共 3^3 = 27 个。
conds = [list(t) for t in product([None, 0, 1], repeat=3)]
assert len(conds) == 27

# 零填充：None 补 0。
fill0 = lambda f: tuple(0 if x is None else x for x in f)
totals = {fill0(f) for f in conds}
assert len(totals) == 8                      # 全函数恰 2^3 个

# 相冲 => 填充不同（反链经零填充单射进 2^3）。
for f, g in product(conds, repeat=2):
    if not compat(f, g):
        assert fill0(f) != fill0(g)
print("Fn(3,2)：27 个条件，零填充像至多 2^3 = 8 个（ccc 计数账）")

# 例 3.3 的极大反链 A_f：对每个全函数 f，
# A_f = {p : p 前 n 位与 f 一致，第 n 位恰与 f 分歧}——
# 任何条件 q 必与 f 首次分歧于某位 n，于是与 A_f 的第 n 个成员可比较。
def antichain_A(f):
    out = []
    for n in range(len(f)):
        out.append(f[:n] + [flip(f[n])])
    return out

f = [1, 0, 1]
Af = antichain_A(f)
assert len(Af) == 3
assert all(not compat(a, b) for a, b in product(Af, repeat=2) if a != b)
print("A_f 反链（n 个两两相冲条件，与 f 首次分歧于各位）：", Af)

# 书里 D_h 的稠密性：对每个分支 h，{p : p 在某位与 h 分歧} 稠密——
# 有限账：任何条件都能延拓出与 h 的分歧位。
for h in ground:
    for p in map(list, conds[:8]):
        k = len(p)
        q = p + [flip(h[k])] if k < len(h) else p + [flip(h[0])]
        assert any(a != b for a, b in zip(q, h))
print("对角集 D_h 稠密：任何条件都能延拓到与 h 分歧 OK")

# ---------- 四、力迫关系的原子形态（真值引理的原子条款） ----------

def forces_bit(p, n, b):
    """p 力迫「第 n 位 = b」：p 已决定该位。"""
    return n < len(p) and p[n] == b

# 串式条件空间：2^omega 的各层前缀（长度 = 定义域）。
strconds = [list(t) for k in range(4) for t in product([0, 1], repeat=k)]

# 决定集稠密：任何条件都能延长到决定第 n 位。
for p in strconds:
    for n in range(3):
        q = decider(n)(p)
        assert any(forces_bit(q, n, b) for b in [0, 1])

# 前缀保持：p 力迫的比特在一切更强条件（含 p 的泛型）上保持。
for p, q in product(strconds, repeat=2):
    if ext(p, q):
        for n in range(len(p)):
            assert q[n] == p[n]
print("决定集稠密 + 前缀保持：p 力迫 g(n)=b 时一切泛型满足 OK")

print("END ====")
