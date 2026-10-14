# 第 21 章 对称子模型：置换论证的数值演示
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 21 对称子模型")

# 一、置换的效果演示
atoms = list(range(8))  # 原子集 A = {0..7}

def swap(a, b, xs):
    """交换 a,b 的置换"""
    return [b if x == a else a if x == b else x for x in xs]

# 有限支撑 E = {0,1,2}；π 交换 3,4
E = {0, 1, 2}
pi = swap(3, 4, atoms)
print(f"  原子集 A = {atoms}")
print(f"  支撑 E = {sorted(E)}；π 交换 3,4")
print(f"  π 固定 E 的每个元素 ✓：{all(pi[x] == x for x in E)}")
print(f"  π(3) = {pi[3]}，π(4) = {pi[4]}")

# 二、例 II 的对族
pairs = [{2*k, 2*k+1} for k in range(4)]
print(f"\n  对族 P = {pairs}")
# "选择函数" f 取每对的第一个
f = {i: min(p) for i, p in enumerate(pairs)}
print(f"  f = {f}（每对的最小元）")
# 在 P₀ = {0,1} 内交换：f(P₀) = 0 变成 1
pi2 = swap(0, 1, atoms)
print(f"  π 在 P₀ 内交换 0↔1 后：f(πP₀) = π(f(P₀)) 但值改变——矛盾")

# 三、对称模型的语义
print("\n  对称模型：𝔑 = (HS)^G ⊆ M[G] ⊨ ZF（可能 ¬AC）")
print("  核心引擎：自同态引理 19.10（布尔值与 π 交换）")

print("END ====")
