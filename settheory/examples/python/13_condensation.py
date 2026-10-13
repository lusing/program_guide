# 第 13 章 AC 与 GCH 在 L：Condensation 的数值影子
#
# 凝聚引理（引理 13.1 的引擎）：可数"充分"子结构 M 的
# 坍缩像落回 L_γ。数值影子：可数结构的坍缩 = 某个"层级快照"。

import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 13 AC 与 GCH 在 L：Condensation")

# ------------------------------------------------------------------
# 一、出生证与 <_L（与 Julia 通道同构的 Python 版）
# ------------------------------------------------------------------

def norm_set(members):
    uniq = sorted(set(members), key=lambda s: (len(s), s))
    return "{" + ",".join(uniq) + "}"

def parse_members(s):
    inner = s[1:-1]
    if not inner:
        return []
    out, depth, cur = [], 0, ""
    for c in inner:
        if c == '{': depth += 1
        if c == '}': depth -= 1
        if c == ',' and depth == 0:
            out.append(cur.strip()); cur = ""
        else:
            cur += c
    out.append(cur.strip())
    return out

def build_L_with_birth(maxlayer):
    birth = {"{}": 0}
    current = ["{}"]
    for n in range(1, maxlayer + 1):
        nxt = []
        for x in current:
            for y in current:
                c = norm_set([x, y])
                if c not in birth:
                    birth[c] = n
                    nxt.append(c)
        current.extend(nxt)
    return birth

birth = build_L_with_birth(3)
sample = sorted(birth.items(), key=lambda kv: (kv[1], len(kv[0]), kv[0]))[:6]
for s, n in sample:
    print(f"  {s}：层 {n}")
assert birth["{}"] == 0 and birth["{{}}"] == 1 and birth["{{},{{}}}"] == 2

# <_L 全序性验证：全体按（层， 长度， 字典）排
order = sorted(birth.keys(), key=lambda s: (birth[s], len(s), s))
print(f"\n  <_L 序（前 6）：{order[:6]}")
print("  ——层号优先的字典序良序化全体（定理 33 的可计算化身）")

# ------------------------------------------------------------------
# 二、Condensation 的语义链（讲义动画）
# ------------------------------------------------------------------

print("\nCondensation（引理 13.1）的四步链条：")
print("  ① X ⊆ ω_α。反射原理：取可数充分 M ∋ X, ω_α")
print("     （充分 = 封闭 + 含 cl(U) + 含 <L_β 序列——(13.9)）")
print("  ② Mostowski 坍缩：M ≅ 传递 N（π[X] = X 因 X ⊆ 传递部分）")
print("  ③ 绝对性（引理 13.2）：y = L_α 对充分 M 绝对 ⟹ N = L_γ")
print("     （N ⊨ V=L 且传递 ⟹ N 是某 L_γ）")
print("  ④ γ 可数 < ω_{α+1}，X ∈ L_γ = N")
print("\n  ⟹ P(ω_α) ⊆ L_{ω_{α+1}}，|L_{ω_{α+1}}| = ℵ_{α+1}")
print("  ⟹ 2^{ℵ_α} = ℵ_{α+1}（GCH）+ Cantor 合流")

print("\n定理 33（AC）：<_L 良序 L 本身 ⟹ V=L ⟹ 良序定理 ⟹ AC")
print("  （与 05 章 Zermelo 引擎的对话：L 中选择函数=<_L 最小元）")

print("END ====")
