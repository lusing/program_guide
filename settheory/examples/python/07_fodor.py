# 第 07 章 滤子与 club：Solovay 分裂构造与正规函数不动点
#
# 1. 引理 7.6（Solovay 分裂）的构造内核：每个 α ∈ W（cf α = ω）
#    配收敛序列，第 n 项的"水位" a^n_α 保证平稳性；
# 2. 习题 7.8：正规函数的不动点集是 club（数值演示）。

import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 07 滤子与 club：分裂与不动点")

# ------------------------------------------------------------------
# 一、正规函数的不动点 club（习题 7.8）
#    f(α) = ω·α 的不动点：α = ω·α 的解在有限域的影子
#    用 f(n) = 2n 的不动点结构演示"不动点序列的极限是不动点"。
# ------------------------------------------------------------------

def fixed_point_closure(f, start, limit):
    """迭代逼近不动点：x ↦ f(x) 的极限链"""
    chain = [start]
    x = start
    while len(chain) < limit:
        x = f(x)
        if x in chain:
            break
        chain.append(x)
    return chain

f = lambda n: 2 * n          # f(α)=ω·α 的有限影子（增长形态相似）
chain = fixed_point_closure(f, 1, 10)
print(f"  2n 从 1 的迭代链：{chain}")
print("  （有限域无不动点；ω·α 在 α=ω²、ω³…处命中不动点——")
print("   习题 7.8：不动点集 = 新迭代链的起点，仍是 club）")

# ------------------------------------------------------------------
# 二、Solovay 分裂的构造内核（引理 7.6）
#    W = {α : cf α = ω}。每个 α ∈ W 配上升序列 (a^n_α) → α。
#    关键步骤：存在固定 n 使 {α : a^n_α ≥ γ} 平稳（一切 γ）。
#    然后对每个 γ 用 Fodor 把 {α : a^n_α = γ'} 拆成平稳片。
# ------------------------------------------------------------------

# 有限代理：α 用 [10, 100] 的合数层，a^n_α 用"第 n 大的真因子"
import sympy

def nth_divisor_from_top(alpha, n):
    """α 的第 n 小素因子（模拟 a^n_α 的分片；n=0 即最小素因子）"""
    pf = sympy.primefactors(alpha)
    return pf[n] if n < len(pf) else pf[-1]

W = [a for a in range(12, 200, 2)]       # "cf = ω"的代理层
print(f"\n  W 的大小 = {len(W)}（Solovay 分裂的域）")

# 检验分裂内核：固定 n=0，按 a^0_α 的值分片
fibers = {}
for alpha in W:
    v = nth_divisor_from_top(alpha, 0)
    fibers.setdefault(v, []).append(alpha)

big = sorted(fibers.items(), key=lambda kv: -len(kv[1]))[:3]
for v, fiber in big:
    print(f"    a⁰_α = {v} 的片大小 = {len(fiber)}")
assert max(len(f) for f in fibers.values()) >= len(W) // 8
print("  某片占 ≥1/8——分裂构造的核心：不同的 γ' 给不相交的平稳片，")
print("  κ 个 γ' ⟹ κ 个不相交平稳集（引理 7.6 完整版）。")

# ------------------------------------------------------------------
# 三、超滤的存在方式对照（Tarski vs AC）
# ------------------------------------------------------------------

print("\n  Tarski 超滤定理（定理 21）= Zorn 于滤子链；")
print("  非主超滤的'存在'永远非构造——它们是选择公理的孩子。")
print("  可数完备非主超滤 ⟹ 大基数（第 29 章正题）。")

print("END ====")
