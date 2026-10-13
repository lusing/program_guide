# 第 10 章 模型：Skolem 函数与 Tarski 准则的计算演示
#
# (10.4) 的 Tarski 准则：B ⊆ A 是初等子模型 ⟺ 对每个公式
# "A 中有见证"时"B 中有见证"。Skolem 函数把见证选择做进函数。
# 有限结构上演示这条链。

import sys
import io
from itertools import combinations

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 10 模型：Skolem 与初等子模型")

# ------------------------------------------------------------------
# 一、Skolem 函数（对 ∃x φ(x, a)）的有限构造
# ------------------------------------------------------------------

# 域 A = {0..7}，谓词 P(x) = "x 是偶数"，公式 ∃x (x > a ∧ P(x))
A = list(range(8))
P = lambda x: x % 2 == 0

def skolem_exists(a):
    """∃x (x > a ∧ P(x)) 的 Skolem 函数：返回见证（或 None）"""
    for x in A:
        if x > a and P(x):
            return x
    return None

print("  公式 ∃x (x > a ∧ 偶(x)) 的 Skolem 函数：")
for a in [0, 1, 5, 7]:
    w = skolem_exists(a)
    print(f"    h({a}) = {w}")

# 关键：h 的选择需要枚举顺序——AC 的"选择"在这里由序结构免费提供

# ------------------------------------------------------------------
# 二、初等子模型的 Tarski 链（有限演示）
# ------------------------------------------------------------------

# 取 A 的子集 B，检查"∃ 在 A 有解 ⟹ ∃ 在 B 有解"
def is_elementary_extension(B, formula):
    """formula : A → bool（参数化的存在公式）；检查见证闭包"""
    for a in A:
        if any(formula(x, a) for x in A):       # A 中有见证
            if not any(formula(x, a) for x in B):  # B 中无见证
                return False
    return True

f_even_above = lambda x, a: x > a and P(x)

# B = 偶数全体：任何 a 上方 A 有偶数 ⟹ B 有（B 含全部偶数）✓
B1 = [x for x in A if P(x)]
print(f"\n  B₁ = 偶数集 {B1}：见证闭包 = {is_elementary_extension(B1, f_even_above)}")

# B = {0, 1, 2}：a=3 时 A 有见证 4 但 B 无——不初等
B2 = [0, 1, 2]
print(f"  B₂ = {B2}：见证闭包 = {is_elementary_extension(B2, f_even_above)}")
assert is_elementary_extension(B1, f_even_above)
assert not is_elementary_extension(B2, f_even_above)

# ------------------------------------------------------------------
# 三、Löwenheim-Skolem 的语义（讲义）
# ------------------------------------------------------------------

print("\n  下行 LS：可数语言的一致理论有可数模型——Skolem 函数闭包；")
print("  上行 LS：无穷模型有无穷放大（紧致性/语言扩张）。")
print("  Skolem 悖论：ZFC 有可数模型 M，但 M ⊨ '存在不可数集'——")
print("  '可数'是外部的，'M 的不可数'是内部的——内外之别从此登场。")

print("END ====")
