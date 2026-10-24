# 第 75 章：传递化：刚性与有秩关系（冯琦 §1.10）——Python 通道
# 传递化定理（定理 1.97/1.100）的可执行化：有限有秩外延关系经
# π(a) = {π(z) | z ∈ ext(a)} 递归坍缩成彻底有限集合（嵌套 frozenset
# 的 HF 世界）；刚性定理（定理 1.95）的计算面：同构不同集的坍缩像
# 相等；自同一性（定义 1.99）破坏时坍缩相撞的现场（例 1.34 的
# {2,3,{2}}）；秩函数分层器（定理 1.98：ρ(a) = sup{ρ(y)+1}）与
# 2-循环的永不分层见证（良基 ⟺ 可分层的反向）。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 75")

# ---------- HF 世界：彻底有限集合 = 嵌套 frozenset ----------
EMPTY = frozenset()
def hf(*xs): return frozenset(xs)
def vn(n):            # 冯诺伊曼数字：0=∅、n+1 = n∪{n}
    s = EMPTY
    for _ in range(n): s = s | {s}
    return s

# ---------- 坍缩引擎（定理 1.100：π(a) = {π(z) | z ∈ ext(a)}） ----------
def is_extensional(nodes, ext):
    """自同一（定义 1.99）：A 内 R-外延相同者相等。"""
    seen = {}
    for a in nodes:
        key = ext.get(a, EMPTY)
        if key in seen and seen[key] != a:
            return False, (seen[key], a)
        seen[key] = a
    return True, None

def rank_layers(nodes, ext):
    """定理 1.98 的分层迭代：F(0)=∅，F(β+1) = {a | ext(a) ⊆ F(β)}。
    返回 (rank 映射, 未覆盖节点)——未覆盖非空即非有秩。"""
    covered, rank = set(), {}
    layer = 0
    while len(covered) < len(nodes):
        new = [a for a in nodes if a not in covered
               and all(z in covered for z in ext.get(a, EMPTY))]
        if not new:
            return rank, [a for a in nodes if a not in covered]
        for a in new:
            rank[a] = layer
        covered.update(new)
        layer += 1
    return rank, []

def collapse(nodes, ext):
    """π 的记忆化递归；返回 (π, M=像)。"""
    pi = {}
    def go(a):
        if a not in pi:
            pi[a] = frozenset(go(z) for z in ext.get(a, EMPTY))
        return pi[a]
    for a in nodes:
        go(a)
    return pi, frozenset(pi.values())

def is_transitive(M):
    """M 传递：x ∈ y ∈ M → x ∈ M。"""
    return all(x in M for y in M for x in y)

def check_collapse(nodes, ext, pi, M):
    """定理 1.100 的逐条验收：像传递、π 保关系、π 单射。"""
    assert is_transitive(M), "坍缩像不传递"
    for a in nodes:
        for z in ext.get(a, EMPTY):
            assert pi[z] in pi[a], "π 不保关系（正向）"
        for z in nodes:
            if pi[z] in pi[a]:
                assert z in ext.get(a, EMPTY), "π 不保关系（反向）"
    assert len({pi[a] for a in nodes}) == len(nodes), "π 不单射"

# ---------- 现场一：偶数链坍缩（例 1.35 的有限段） ----------
# E₄ = {0,2,4,6}，关系 = ∈ 的限缩：ext(2n) = {2k | k<n} → π(2n) = n
nodes1 = [0, 2, 4, 6]
ext1 = {2 * n: frozenset(2 * k for k in range(n)) for n in range(4)}
ok, wit = is_extensional(nodes1, ext1)
assert ok, f"偶数链应自同一：{wit}"
rank1, leftover1 = rank_layers(nodes1, ext1)
assert leftover1 == []
pi1, M1 = collapse(nodes1, ext1)
check_collapse(nodes1, ext1, pi1, M1)
assert all(pi1[2 * n] == vn(n) for n in range(4))
assert M1 == vn(4)                      # 像 = {0,1,2,3} = 4（传递 ✓）
print("偶数链 {0,2,4,6}：π(2n) = n，坍缩像 = 4（冯诺伊曼）✓（例 1.35）")
print(f"  分层：{[rank1[2*n] for n in range(4)]}——秩 = 位次（定理 1.98）")

# ---------- 现场二：刚性（定理 1.95）的计算面 ----------
# 两个同构不同集：{0,2,4,6} 与 {1,3,5,7}（结构相同、元素不同）坍缩到同一 M
nodes2 = [1, 3, 5, 7]
ext2 = {2 * n + 1: frozenset(2 * k + 1 for k in range(n)) for n in range(4)}
pi2, M2 = collapse(nodes2, ext2)
assert M2 == M1
print("刚性：{0,2,4,6} 与 {1,3,5,7} 坍缩到同一 M = 4——同构的传递化像相等 ✓")

# ---------- 现场三：自同一性破坏 → 坍缩相撞（例 1.34） ----------
# A = {2,3,{2}}：ext(3) = {2} = ext({2}) 但 3 ≠ {2}——外延性在 A 内失效
a2, a3, a23 = "2", "3", "{2}"
nodes3 = [a2, a3, a23]
ext3 = {a2: EMPTY, a3: frozenset({a2}), a23: frozenset({a2})}
ok, wit = is_extensional(nodes3, ext3)
assert not ok and set(wit) == {a3, a23}
pi3, M3 = collapse(nodes3, ext3)
assert pi3[a3] == pi3[a23] == hf(EMPTY)   # 相撞：两个节点同一个像 1
print("例 1.34 {2,3,{2}}：不自同一 → π(3) = π({2}) = {∅} 相撞 ✓（定理前提缺一不可）")

# ---------- 现场四：秩分层与 2-循环的永不分层 ----------
# 有秩 + 自同一的依赖图（注意：菱形 a←b,a←c,{b,c}←d 不自同一——
# b,c 外延相同，会被坍缩引擎当场抓包；这里给每点配不同外延）
nodes4 = ["a", "b", "c", "d"]
ext4 = {"a": EMPTY, "b": frozenset({"a"}), "c": frozenset({"a", "b"}),
        "d": frozenset({"a", "c"})}
rank4, leftover4 = rank_layers(nodes4, ext4)
assert leftover4 == [] and rank4 == {"a": 0, "b": 1, "c": 2, "d": 3}
pi4, M4 = collapse(nodes4, ext4)
check_collapse(nodes4, ext4, pi4, M4)
assert pi4["d"] == hf(EMPTY, hf(EMPTY, hf(EMPTY)))   # {0, 2}
assert pi4["d"] not in [vn(k) for k in range(5)]     # 像不是序数
print(f"外延 DAG 分层 {rank4} ✓；π(d) = {{0,2}}——非序数的传递集合居民 ✓")

# 2-循环：a 依赖 b、b 依赖 a——永远没有起点，分层覆盖率为零
nodes5 = ["x", "y"]
ext5 = {"x": frozenset({"y"}), "y": frozenset({"x"})}
rank5, leftover5 = rank_layers(nodes5, ext5)
assert rank5 == {} and set(leftover5) == {"x", "y"}
print("2-循环 x⇄y：分层永远漏掉它——非有秩 ⟺ 不可分层的反向见证 ✓（定理 1.98）")

print("END ====")
