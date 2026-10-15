# 第 62 章：树的机器化（Makinson Ch7）
# 有根树的显式定义验证 + BST + 表达式树 + 生成树
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 62")

# ---------- 一、书中第一棵树（图 7.1）的手术验证 ----------
# (G, R)：15 节点，R = 父→子
G = set("abcdefghijklmno")
R = {("a","b"),("a","c"),("b","d"),("d","i"),("d","j"),("d","k"),
     ("c","e"),("c","f"),("c","g"),("c","h"),("i","m"),("i","o"),
     ("k","n"),("h","l")}

def is_rooted_tree(G, R):
    if not G:
        return True
    R = {(u, v) for (u, v) in R if u in G and v in G}  # 约去 G 外的边
    indeg = {v: 0 for v in G}
    for (u, v) in R:
        indeg[v] += 1
    zeros = [v for v in G if indeg[v] == 0]
    if len(zeros) != 1:
        return False
    root = zeros[0]
    # BFS 可达性
    from collections import deque
    adj = {v: [] for v in G}
    for (u, v) in R:
        adj[u].append(v)
    seen = {root}
    q = deque([root])
    while q:
        u = q.popleft()
        for v in adj[u]:
            if v in seen:
                return False  # 两父（或圈）
            seen.add(v)
            q.append(v)
    return seen == G and indeg[root] == 0

print("  图 7.1 是有根树：", is_rooted_tree(G, R))
# 删 m 连边一起删
G2 = G - {"m"}; R2 = R - {("i","m")}
print("  删 m+边：", is_rooted_tree(G2, R2))
# 只删边（m 成孤点）
print("  只删边（m 成孤点）：", is_rooted_tree(G, R - {("i","m")}))
# 加 m→n 边（n 双父）
print("  加边 m→n：", is_rooted_tree(G, R | {("m","n")}))
# 加 c→l 边
print("  加边 c→l：", is_rooted_tree(G, R | {("c","l")}))

# 8 叶 8 分支
def leaves(G, R):
    out = {v: 0 for v in G}
    for (u, v) in R:
        out[u] += 1
    return {v for v in G if out[v] == 0}
lv = leaves(G, R)
print("  叶子：", sorted(lv), "（8 个 = 分支数）")
assert len(lv) == 8

# ---------- 二、BST：九词两序 ----------
import bisect
class N:
    __slots__ = ("l", "v", "r")
    def __init__(self, v): self.l = None; self.v = v; self.r = None
def ins(t, w):
    if t is None: return N(w)
    if w < t.v: t.l = ins(t.l, w)
    elif w > t.v: t.r = ins(t.r, w)
    return t
def ht(t): return 0 if t is None else 1 + max(ht(t.l), ht(t.r))
def cnt(t): return 0 if t is None else 1 + cnt(t.l) + cnt(t.r)
w1 = "this is how to construct a binary search tree".split()
t1 = None
for w in w1: t1 = ins(t1, w)
t2 = None
for w in sorted(w1): t2 = ins(t2, w)
print(f"  九词 BST：书本序高 {ht(t1)}，字典序高 {ht(t2)}（斜链）；节点 {cnt(t1)}")

# ---------- 三、表达式树求值 ----------
# (5+(2x))-((y-3)+(2+x))，x=4, y=7 → 13-16 = -3
env = {"x": 4, "y": 7}
e = ("-", ("+", 5, ("*", 2, "x")), ("+", ("-", "y", 3), ("+", 2, "x")))
def ev(t):
    if isinstance(t, int): return t
    if isinstance(t, str): return env[t]
    op, l, r = t
    return ev(l) + ev(r) if op == "+" else ev(l) - ev(r) if op == "-" else ev(l) * ev(r)
print("  (5+(2x))−((y−3)+(2+x)) 于 x=4,y=7 =", ev(e))

# ---------- 四、生成树（Kruskal） ----------
def spanning(edges, n):
    parent = list(range(n))
    def find(i):
        while parent[i] != i:
            parent[i] = parent[parent[i]]; i = parent[i]
        return i
    st = []
    for (u, v) in sorted(edges):
        ru, rv = find(u), find(v)
        if ru != rv:
            parent[ru] = rv
            st.append((u, v))
    return st
g = {(0,1),(1,2),(2,3),(3,4),(4,0),(0,2)}
st = spanning(g, 5)
print("  5 点 6 边图的生成树（0 基编号）：", [(u+1, v+1) for u, v in st], f"（{len(st)} = n−1 条边）")
assert len(st) == 4

print("END ====")
