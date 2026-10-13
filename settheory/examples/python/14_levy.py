# 第 14 章 Lévy 层级：nat 上的算术层级模拟
#
# Σ₁ 的直觉：可枚举定义（r.e.）。对每个"Σ₁ 定义"的谓词，
# 其见证可以逐步搜索——上绝对性的可计算化身。

import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 14 Lévy 层级：算术模拟")

# ------------------------------------------------------------------
# 一、Σ₁ 谓词 = 存在可搜索见证
# ------------------------------------------------------------------

def sigma1_divides():
    """'y | x'（y 整除 x）是 Σ₁：∃z. y·z = x——见证 z 可枚举搜索"""
    def check(x, y):
        for z in range(x + 1):
            if y * z == x:
                return z
        return None
    return check

divides = sigma1_divides()
for (x, y) in [(12, 3), (12, 5), (0, 7), (9, 3)]:
    w = divides(x, y)
    print(f"  3|12 型检查：{y}|{x} 的见证 z = {w}")

# ------------------------------------------------------------------
# 二、Π₁ 谓词 = 无限反驳（全域检查不可判定）
# ------------------------------------------------------------------

print("\nΠ₁ 的形态：∀z φ₀——要确认为真需检查一切 z：")
print("  例：'x 是素数' = ∀z<x（z∤x ∨ z=1）——有限域可判定")
def is_prime(x):
    if x < 2: return False
    return all(x % z != 0 for z in range(2, x))
assert is_prime(7) and not is_prime(9)
print("  素数性：有界的 Π₁（Δ₀）——可判定 ✓")

# ------------------------------------------------------------------
# 三、对偶与封闭（与 Julia 通道同构的 Python 版）
# ------------------------------------------------------------------

def dual(l):
    k, n = l
    return ("Δ0", 0) if k == "Δ0" else ("Π" if k == "Σ" else "Σ", n)

def ex_over(l):
    k, n = l
    if k == "Δ0": return ("Σ", 1)
    if k == "Σ": return ("Σ", n)
    return ("Σ", n + 1)

def all_over(l):
    return dual(ex_over(dual(l)))

assert dual(dual(("Σ", 3))) == ("Σ", 3)
assert ex_over(("Π", 2)) == ("Σ", 3)
assert all_over(("Σ", 2)) == ("Π", 3)
assert all_over(("Π", 5)) == ("Π", 5)
print("\n对偶/提升规则验证 ✓（引理 14.2 iii 与封闭规则）")

print("\n非绝对性的根源示例：'x 是基数'（Π₁ 非 Σ₁）")
print("  模型 M 内无双射 f: α → β ⟹ M 认为 β 是基数；")
print("  外部双射可以缺席——见证逃逸使 Π₁ 概念只向下绝对。")

print("END ====")
