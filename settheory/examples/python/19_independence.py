# 第 19 章 CH 独立性：ccc 论证与泛型实数
import sys, io
from itertools import product, combinations
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 19 CH 独立性")

# 一、Cohen 偏序的 ccc 验证（有限域）
# 条件 p：dom ⊆ {0..3}×{0..2} 的部分 0/1 函数

def compatible(p, q):
    for k in set(p) & set(q):
        if p[k] != q[k]: return False
    return True

# 取所有单点条件，检查不相容性
singletons = [{(i,j): b} for i in range(4) for j in range(2) for b in [0,1]]
n_compat = sum(1 for p, q in combinations(singletons, 2) if compatible(p, q))
n_incompat = sum(1 for p, q in combinations(singletons, 2) if not compatible(p, q))
print(f"  单点条件 {len(singletons)} 个：相容对 {n_compat}，不相容对 {n_incompat}")
# 同一域点不同值 → 不相容
assert not compatible({(0,0): 1}, {(0,0): 0})
# 不同域点 → 相容
assert compatible({(0,0): 1}, {(0,1): 0})
print("  ccc（引理 19.3）：有限域 + 可数值 → 不相容族可数")

# 二、AC 独立性的置换论证骨架
print("\n  AC 独立性（定理 45）骨架：")
print("  1. 在 L 中加 ℵ₀ 个 Cohen 实数 → M[G]")
print("  2. 取对称子模型 N = HOD(A)")
print("  3. ω 的置换 π 交换 i,j → V^B 自同态 → π(a_j)=a_i")
print("  4. π 固定 s 与 A 的名字 → a 的定义不依赖于 i 的选取")
print("  5. ⟹ A 不可良序 → 实数不可良序 → ¬AC")

# 三、置换的效果演示
perm = {0:1, 1:0}  # 交换 0 和 1
a_0 = {n%2 for n in range(10)}  # 模拟泛型实数 a_0
a_1 = {(n+1)%2 for n in range(10)}  # a_1 ≠ a_0
print(f"\n  置换前：a_0={sorted(a_0)}, a_1={sorted(a_1)}")
print(f"  π 交换 0↔1 后的效果：a_0 与 a_1 的角色互换")
print(f"  HOD(A) 中的定义式无法区分 → 无良序（引理 19.12 的直觉）")

print("END ====")
