# 第 03 章 基数：Schröder-Bernstein 的算法版
#
# Jech 定理 7 的证明（区间套）本身就是算法：给定双向单射
# f : A→B、g : B→A，构造双射 h。本文件把区间套跑起来，
# 在有限集上显式构造 h 并验证双射性。

import sys
import io
from itertools import permutations

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 03 基数：SB 区间套算法")

# ------------------------------------------------------------------
# 一、区间套构造（Jech 定理 7 的算法化）
# A₀ = A，A_{n+1} = f[A_n]，B_n = g[B_n]（看进 A 里）
# h(x) = f(x)  若 x ∈ A_n - B_n 对某 n；否则 g⁻¹(x)
# ------------------------------------------------------------------

def sb_bijection(A, B, f, g):
    """给定 f: A→B、g: B→A 双单射，返回双射 h: A→B 的字典。"""
    A_set, B_set = set(A), set(B)
    # A_0 ⊇ A_1 ⊇ ... 与 B_0 ⊇ B_1 ⊇ ...（都在 A 中看：B_n → g[B_n]）
    B_img = {g(b) for b in B_set}          # g[B_0]
    layers = []                            # ⋃(A_n - B_n) 的成员
    An, Bn = set(A_set), set(B_img)
    for _ in range(len(A_set) + 1):
        layer = An - Bn
        layers.append(layer)
        if not layer:
            break
        An = {f(x) for x in An}            # A_{n+1} = f[A_n]
        Bn = {f(x) for x in Bn}            # B_{n+1} = f[B_n]
    union_layers = set().union(*layers)
    h = {}
    for x in A_set:
        if x in union_layers:
            h[x] = f(x)
        else:
            # g⁻¹(x)
            h[x] = next(b for b in B_set if g(b) == x)
    return h

# ------------------------------------------------------------------
# 二、测试：环面 ↔ 方块（双向单射的典型例子）
# ------------------------------------------------------------------

A = list(range(8))                          # 8 个点
B = [(i, j) for i in range(3) for j in range(3)]  # 3×3 网格（9 点）

f = lambda x: (x % 3, x // 3)               # A → B：8 点嵌入 9 格
g = lambda p: p[0] * 3 + p[1]               # B → A：9 点……不单！

# 修正：9 点不能单射进 8 点！换成对称的 8 vs 8：
B = [(i, j) for i in range(4) for j in range(2)]   # 4×2 网格（8 点）
f = lambda x: (x % 4, x // 4)
g = lambda p: p[0] + 4 * p[1]

h = sb_bijection(A, B, f, g)
print("  A = 0..7, B = 4×2 网格，f,g 均单射")
print(f"  SB 构造出 h：{len(h)} 个点全部映射")
assert set(h.keys()) == set(A)
assert sorted(h.values()) == sorted(B)      # 双射（值恰为 B）
print(f"  h 的值恰好铺满 B：{sorted(h.values())}")
print("  h = ", dict(sorted(h.items())))

# ------------------------------------------------------------------
# 三、非平凡例：双向"错位"嵌入
# ------------------------------------------------------------------

# A = 素数集（前 10 个），B = 偶数集（前 10 个）
primes = [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
evens = [2 * k for k in range(1, 11)]
f2 = lambda p: 2 * (primes.index(p) + 1)        # 素数 → 偶数
g2 = lambda e: primes[evens.index(e)]           # 偶数 → 素数

h2 = sb_bijection(primes, evens, f2, g2)
assert sorted(h2.values()) == sorted(evens)
print(f"  素数 ↔ 偶数（各 10 个）：SB 构造的双射 = {dict(sorted(h2.items()))}")

# ------------------------------------------------------------------
# 四、aleph 表（Jech 记号的速查）
# ------------------------------------------------------------------

print("\n  aleph 速查：ℵ₀=|ℕ|, ℵ₁=ℵ₀⁺, ℵ_ω=sup{ℵ_n}（极限侧）")
print("  后继侧：ℵ_{α+1} = ℵ_α⁺；共尾：cf(ℵ_{α+1}) = ℵ_{α+1}（ZFC）")
print("  Cantor：κ < 2^κ 永远；CH 即 2^ℵ₀ = ℵ₁（不可判定，第 20 章）")

print("END ====")
