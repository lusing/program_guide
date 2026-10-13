# 第 11 章 传递模型：坍缩与反射的对照实验
#
# 1. Mostowski 坍缩的规范化实现（canonical form）；
# 2. 反射原理的引擎侧：闭包层级 M_{i+1} = M_i ∪ F[M_i]
#    （引理 11.2 的 (11.14) 构造）的数值演示。

import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 11 传递模型：坍缩与反射")

# ------------------------------------------------------------------
# 一、Mostowski 坍缩（规范化字符串版）
# ------------------------------------------------------------------

def collapse(ext, x, memo=None):
    """π(x) = {π(z) : z ∈ ext(x)}，规范化（成员排序去重）。"""
    if memo is None:
        memo = {}
    if x in memo:
        return memo[x]
    members = sorted(set(ext[x]))
    parts = sorted((collapse(ext, z, memo) for z in members), key=lambda t: (len(t), t))
    memo[x] = "{" + ",".join(parts) + "}"
    return memo[x]

# von Neumann 链
ext1 = {0: [], 1: [0], 2: [0, 1], 3: [0, 1, 2]}
for x in range(4):
    print(f"  π({x}) = {collapse(ext1, x)}")
assert collapse(ext1, 3) == "{{},{{}},{{},{{}}}}"
print("  ——0∈1∈2∈3 坍缩成 von Neumann 数 3")

# 非同构但外延同构的图：{5,6} 上 ext(6)={5}, ext(5)={}
ext2 = {5: [], 6: [5]}
print(f"  π(6) = {collapse(ext2, 6)}（6 被改名为 1）")
assert collapse(ext2, 6) == "{{}}"

# ------------------------------------------------------------------
# 二、反射构造（引理 11.2 的 (11.14)）
#    M_{i+1} = M_i ∪ F[M_i]，M = ⋃ M_i
#    F = 见证函数（Skolem 式：最小秩见证）
# ------------------------------------------------------------------

# 有限宇宙：{0..7}，公式 φ(u, x) = "x > u 且 x 是 3 的倍数"
universe = list(range(8))
phi = lambda u, x: x > u and x % 3 == 0

def witness(u):
    """最小秩见证（(9.3)/(11.11) 的 F）"""
    for x in universe:
        if phi(u, x):
            return x
    return None

def reflection_closure(M0):
    """M_{i+1} = M_i ∪ {F(u) : u ∈ M_i} 的不动点"""
    M = set(M0)
    changed = True
    while changed:
        changed = False
        for u in list(M):
            w = witness(u)
            if w is not None and w not in M:
                M.add(w)
                changed = True
    return M

M0 = {0, 1}
M = reflection_closure(M0)
print(f"\n  从 M₀={M0} 出发的反射闭包：{sorted(M)}")
# 验证反射性：u ∈ M 且 ∃x φ(u,x) ⟹ ∃x ∈ M φ(u,x)
for u in M:
    if any(phi(u, x) for x in universe):
        assert any(phi(u, x) for x in M), u
print("  见证闭包验证 ✓：M 内部已自足（引理 11.2 的引擎）")

# ------------------------------------------------------------------
# 三、讲义：定理 29 的三形态
# ------------------------------------------------------------------

print("\n  定理 29 三形态：(A) 任意 M ⊇ M₀ 反射 φ；")
print("  (B) 传递的 M = V_α 反射 φ；(C) AC 下 |M| ≤ max(|M₀|, ℵ₀)。")
print("  ——不可兼得注记：传递性与小基数性二选一。")

print("END ====")
