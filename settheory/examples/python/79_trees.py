# 第 79 章：树、苏斯林树、马丁公理与划分定理（冯琦 §2.5–2.6）——Python 通道
# 三个场景，独立于 Julia/Coq 重写同一批有限命题：
# 场景一：itertools 枚举 K5/K6 全部边二染色，5 < R(3,3) <= 6（无单色三角形者
#         K5 恰 12 种、K6 恰 0 种）；
# 场景二：递归上界 R(s,t) <= R(s-1,t)+R(s,t-1)；
# 场景三：柯尼希引理的有限形态（二叉前缀树必有到最深层的枝）与定理 2.44 的
#         有限泛善子集（有限偏序上有限个稠密集必可全部相遇）。
import sys, io, itertools
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 79")

# ---------- 场景一：K5/K6 二染色穷举 ----------
def edges(n):
    return [(i, j) for i in range(n) for j in range(i + 1, n)]

def triples(n):
    return [(i, j, k) for i in range(n) for j in range(i + 1, n)
            for k in range(j + 1, n)]

def has_mono_triangle(col, es, tris):
    for (i, j, k) in tris:
        a, b, d = col[es.index((i, j))], col[es.index((i, k))], col[es.index((j, k))]
        if a == b == d:
            return True
    return False

def scan(n):
    es, tris = edges(n), triples(n)
    total = clean = 0
    witness = None
    for bits in itertools.product((0, 1), repeat=len(es)):
        total += 1
        if not has_mono_triangle(bits, es, tris):
            clean += 1
            witness = bits
    return total, clean, witness

# 显式五循环见证（红边 0-1-2-3-4-0）：按 edges(5) 字典序给颜色。
es5 = edges(5)
red5 = {(0, 1), (1, 2), (2, 3), (3, 4), (0, 4)}
w5 = tuple(0 if e in red5 else 1 for e in es5)
assert not has_mono_triangle(w5, es5, triples(5))     # 红、蓝各是一个五循环

t5, clean5, _ = scan(5)
assert t5 == 1024 and clean5 == 12                    # 12 个标号五循环
t6, clean6, _ = scan(6)
assert t6 == 32768 and clean6 == 0
print(f"场景一（Ramsey 穷举）：K5 共 {t5} 种，{clean5} 种无单色三角形；"
      f"K6 共 {t6} 种，{clean6} 种无 ⟹ 5 < R(3,3) ≤ 6 ✓")

# ---------- 场景二：有限 Ramsey 上界递归 ----------
from functools import lru_cache
@lru_cache(maxsize=None)
def ramsey_upper(s, t):
    if s == 2:
        return t
    if t == 2:
        return s
    return ramsey_upper(s - 1, t) + ramsey_upper(s, t - 1)

assert ramsey_upper(3, 3) == 6
assert ramsey_upper(3, 4) == 10      # 偶数和 sharpen：R(3,4)=9
assert ramsey_upper(3, 5) == 15
assert ramsey_upper(4, 4) == 20      # 偶数和 sharpen：R(4,4)≤18
print(f"场景二（上界递归）：R(3,3)≤{ramsey_upper(3,3)}、"
      f"R(3,4)≤{ramsey_upper(3,4)}（→9）、R(3,5)≤{ramsey_upper(3,5)}、"
      f"R(4,4)≤{ramsey_upper(4,4)}（→18）✓")

# ---------- 场景三：柯尼希有限形态与有限泛善子集 ----------
# (a) 深 D 的完整二叉树：必有长 D 的枝（直接构造即可），且最深层有 2^D 个节点。
D = 8
tree = {b for L in range(D + 1) for b in itertools.product((0, 1), repeat=L)}
assert len(tree) == 2 ** (D + 1) - 1
branch = tuple(itertools.repeat(0, D))
assert all(branch[:L] in tree for L in range(D + 1))

# (b) 例 2.17(3) 有限版：{0..m} 上严格下降序列树，最大枝长 m+1。
def max_desc_branch(m):
    return max(sum(1 for _ in
                   filter(lambda x: (mask >> x) & 1, range(m, -1, -1)))
               for mask in range(1 << (m + 1)))
assert all(max_desc_branch(m) == m + 1 for m in range(7))

# (c) 定理 2.44：偏序 = {1..B} 的有限子集按包含序，稠密 D_a={S : a∈S}。
# 从 ∅ 出发逐次加 a 相遇 D_a，链 ∅⊂{1}⊂…⊂{1..B} 的下闭就是泛善滤子。
B = 6
P = {frozenset(s) for L in range(B + 1)
     for s in itertools.combinations(range(1, B + 1), L)}
chain = [frozenset(range(1, a + 1)) for a in range(B + 1)]
F = {S for top in chain for S in P if S <= top}      # 链的下闭
assert F == P                                        # 顶条件是全集 ⇒ 下闭=全幂集
for q1, q2 in itertools.product(F, repeat=2):        # (1) 定向：并在 F 中
    assert q1 | q2 in F
for p in F:                                          # (2) 下闭
    assert all(q in F for q in P if q <= p)
for a in range(1, B + 1):                            # (3) 相遇每个 D_a
    assert any(a in q for q in F)
    assert any(a in q for q in chain)
print(f"场景三（柯尼希有限形态/泛善子集）：深 {D} 二叉树有枝且节点 {2**(D+1)-1}；"
      f"下降序列树最大枝长 m+1；{B} 个稠密集在有限子集偏序上全部相遇 ✓")

print("END ====")
