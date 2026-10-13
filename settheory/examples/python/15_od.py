# 第 15 章 OD/HOD：Berry 悖论的数值形态与 HOD 闭包
#
# Berry：用"最小不可定义"字样定义数——自指矛盾。
# OD 的参数形式（序数）为何安全：良序锚定。

import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 15 OD 与 HOD")

# ------------------------------------------------------------------
# 一、Berry 悖论的有限域模拟
# ------------------------------------------------------------------

# "用不超过 N 个字符可命名的数"：名字集合有限 ⟹ 存在不可命名数
# "最小不可命名数"的描述本身是一个名字——但长度超过 N？
# 集合论版本（习题 15.17）：Def 的定义语言里"最小不可定义"自爆。

N = 12
names = set()
# 模拟：短名字（≤N 字符）命名的数
for x in range(100):
    if len(str(x)) <= N:
        names.add(x)
    if len(hex(x)) <= N:
        names.add(x)

unnamed = [x for x in range(100) if x not in names]
print(f"  可命名数（两种命名法，≤{N} 字符）：{len(names)} 个")
print(f"  不可命名的最小数：{unnamed[0] if unnamed else '无'}")
# "the least number not nameable in at most twelve characters"
# ——这个英文短语本身超过 12 字符：悖论被长度分层消解。
desc = "least number not nameable in twelve characters"
print(f"  '最小不可命名数'的名字长度 = {len(desc)} > {N}")
print("  ——长度/复杂度分层是 Berry 悖论的经典消解；")
print("    集合论版本：'可定义'不属于对象语言（Tarski 分层）。")

# ------------------------------------------------------------------
# 二、OD 参数的安全锚（序数的 canonical 枚举）
# ------------------------------------------------------------------

print("\nOD 的参数安全性：")
print("  序数参数 α 有 canonical 名（∈-良序的位置）——")
print("  '第 α 个序数'永不自指；公式 φ(u, α₁..αₙ) 的定义性")
print("  由反射原理（V_α 层快照）等价刻画（(15.16)）。")
print("  HOD = TC ⊆ OD 的全体：传递 ZFC 内模型（定理 38）。")
print("  HOD ⊇ L；可一致 HOD ≠ L（力迫篇的预告）。")

print("END ====")
