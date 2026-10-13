# 第 02 章 序数：ω² 内的序数轰炸机与极限演示
#
# CNF 计算器在 Julia 通道是全功能的；Python 通道换一个视角：
# 1. 枚举 ω² 以内的全部序数（ω·a + b 的"坐标平面"），
#    观察序型的字典序结构；
# 2. 演示超穷序列的极限（Jech：lim γξ = sup）——正规函数
#    α ↦ ω·α 在可数个点上取极限的数值过程。

import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 02 序数：ω² 枚举与极限")

# ------------------------------------------------------------------
# 一、ω² 的"坐标平面"
# ω² 内每个序数唯一写成 ω·a + b（a, b ∈ ℕ）。序关系：
#     ω·a + b < ω·a' + b'  ⟺  a < a' 或 (a = a' 且 b < b')
# 这正是（垂直）字典序——Jech §2 讲 ω·β 用水平字典序，这里是
# 左乘的对应版本。
# ------------------------------------------------------------------

def key(a, b):
    return (a, b)

# 枚举 ω² 的前 N 项（按序）
def enumerate_w2(count):
    out = []
    a = 0
    while len(out) < count:
        for b in range(3):                      # 每层取 3 个代表
            if len(out) >= count:
                break
            out.append((a, b))
        a += 1
    return out

lst = enumerate_w2(12)
print("  ω² 的前 12 个代表（ω·a+b 形）：")
print("   ", "  ".join(f"ω·{a}+{b}" if a else f"{b}" for a, b in lst))

# 字典序检查：ω·a+b 的排序键
seq = [(1, 5), (2, 0), (0, 100), (1, 0), (2, 3)]
seq_sorted = sorted(seq, key=lambda t: key(*t))
print("  排序检查：", " < ".join(f"ω·{a}+{b}" for a, b in seq_sorted))
assert seq_sorted == [(0, 100), (1, 0), (1, 5), (2, 0), (2, 3)]
# 关键观察：ω·1 + 0 > ω·0 + 100（第一坐标优先——ω 吃掉任何有限差）

# ------------------------------------------------------------------
# 二、极限：α ↦ ω·α 的数值过程
# Jech：lim_{ξ→λ} γξ = sup{γξ : ξ < λ}。
# 取 γξ = ω·ξ（正规函数），在 λ = ω 处：
#     sup{ω·n : n < ω} = ω·ω = ω²
# 数值上：第一坐标无界 → 极限坐标 = (sup a, 0)
# ------------------------------------------------------------------

def w_mul_w():
    """sup_{n<ω} ω·n：第一坐标 a 无界递增，极限的 a' '本身成为指数'"""
    # ω² 的 CNF：ω^2·1——第一坐标坍缩进指数
    return "ω² = ω^2（ω·n 的 sup：坐标 a 无界 → 变成新的指数层）"

print(" ", w_mul_w())

# 更细的演示：ω·(n+1) 与 sup 的距离
for n in [1, 2, 5, 100]:
    print(f"    ω·{n} 距离 ω² 还有『无穷远』：ω² - ω·{n} 仍是 ω² 型（无有限差）")

# ------------------------------------------------------------------
# 三、后继与极限的分类（Jech 定义的数值体验）
# α 是后继 ⟺ ∃β, α = β+1；α 是极限 ⟺ α = sup_{β<α} β
# 在 ω² 坐标里：ω·a+b (b≥1) 是后继；ω·a (a≥1) 是极限
# ------------------------------------------------------------------

def classify(a, b):
    if a == 0 and b == 0:
        return "零"
    if b == 0 and a >= 1:
        return "极限"
    return "后继"

for point in [(0, 0), (0, 1), (1, 0), (1, 1), (3, 0), (3, 7)]:
    a, b = point
    label = classify(a, b)
    nm = f"ω·{a}+{b}" if a else f"{b}"
    print(f"    {nm:8s} 是 {label}")

assert classify(1, 0) == "极限"
assert classify(1, 1) == "后继"

# 极限序数的验证：ω·a = sup{ω·a' + b' : ω·a'+b' < ω·a}
# 即：第一坐标 < a 的所有点 + 第一坐标 = a 的有限 b
# 数值检查：对 a=2，点集 {(0,b)} ∪ {(1,b)} 与 (2,0) 的关系
below = [(x, y) for x in range(2) for y in range(50)]
assert all(key(*p) < (2, 0) for p in below)
print("    ω·2 下方所有 ω·1+b 都 < (2,0)：sup 定义自洽")

print("要点：ω² 是『坐标的字典序』；极限 = 新指数层的诞生。")
print("END ====")
