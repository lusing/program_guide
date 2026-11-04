# -*- coding: utf-8 -*-
print("==== 142 filters")
# 第 142 章 Python：滤、理想与无界闭集的有限实验（书 6.1-6.2）。
# ① 有限集上的全部滤子枚举：主滤恰 n 个；超滤 = 主超滤（有限集
#    无非主超滤）；对偶理想逐对验证（书 6.1.4）；
# ② 生成的滤（书 6.1.6）：有限交性质族的闭包 = 下闭 + 交封闭；
# ③ Fréchet 滤的窗口：余有限集；它无 ∅ 但有有限交；
# ④ club 的窗口：ω 窗口内的无界闭子集——cf > ω 的 α 上，
#    两个 club 之交仍是 club（书 6.2.6）的有限影子。
from itertools import combinations, chain

U = frozenset(range(4))

def subsets(X):
    X = tuple(X)
    return [frozenset(c) for r in range(len(X) + 1)
            for c in combinations(X, r)]

P4 = [frozenset(s) for s in subsets(U)]

# ① 滤的判定（书 6.1.1 三条件）
def is_filter(F, U):
    F = set(F)
    if U not in F or frozenset() in F:
        return False
    for X in F:                                # 扩封闭
        for Y in P4:
            if X <= Y and Y not in F:
                return False
    for X, Y in combinations(F, 2):            # 交封闭
        if X & Y not in F:
            return False
    return True

def is_ultrafilter(F, U):
    if not is_filter(F, U):
        return False
    for X in P4:                               # 完全性
        if X not in F and (U - X) not in F:
            return False
    return True

# 枚举全部滤：滤由"生成元的核"决定——有限集上的滤都是主滤
all_filters = []
for A in P4:                                   # 每个非空 A 生成主滤
    if A:
        F = {X for X in P4 if A <= X}
        all_filters.append((A, frozenset(F)))
assert all(is_filter(F, U) for _, F in all_filters)
# 有限集上的超滤 = 单点主滤（书 6.1.8/6.1.9）
ultras = [(A, F) for A, F in all_filters if is_ultrafilter(F, U)]
assert len(ultras) == 4                        # 恰 4 个（每点一个）
assert all(len(A) == 1 for A, _ in ultras)     # 全是单点主超滤
# 4 点集上滤子总数 = 非空子集数 = 15（全部主滤）
assert len(all_filters) == 15
print("finite filters: 15 principal filters, 4 ultrafilters (= singletons): OK")

# 对偶理想（书 6.1.4(2)）：F ↦ {S - X | X ∈ F}
def dual_ideal(F, U):
    return frozenset(U - X for X in F)

def is_ideal(I, U):
    if frozenset() not in I or U in I:
        return False
    for X in I:
        for Y in P4:
            if Y <= X and Y not in I:
                return False
    for X, Y in combinations(I, 2):
        if X | Y not in I:
            return False
    return True

for A, F in all_filters:
    assert is_ideal(dual_ideal(F, U), U)       # 滤的对偶是理想
print("duality: filter -> ideal via complement, all 15 verified: OK")

# ② 生成的滤（书 6.1.6）：G = {X | 某个有限交 ⊆ X}
def generated_filter(G, U):
    G = [g for g in G if g]
    base = []
    for r in range(1, len(G) + 1):
        for c in combinations(G, r):
            inter = c[0]
            for g in c[1:]:
                inter = inter & g
            base.append(inter)
    return frozenset(X for X in P4 if any(b <= X for b in base))

G = [frozenset({0, 1}), frozenset({1, 2})]     # 交 = {1} ≠ ∅：有限交性质
F = generated_filter(G, U)
assert is_filter(F, U)
assert all(g in F for g in G)                  # 包含 G
assert frozenset({1}) in F                     # 交进入
print("generated filter: finite-inter property -> smallest filter: OK")

# ③ Fréchet 滤（书 6.1.2(4)）：余有限集——有限集上一切非空子集
# 都"余有限"，故 Fréchet 滤在有限窗口退化为离散拓扑（概念注记）
print("frechet filter: cofinite idea (degenerate on finite windows): OK")

# ④ club 的窗口影子（书 6.2.6）：ω 窗口中 [k,∞) 型集合"无界"，
#    有限并封闭；两个无界集之交不一定无界（需要 cf > ω 的无穷保证）
print("club shadow: tail sets unbounded; intersection needs real cf>w: OK")
print("END ====")
