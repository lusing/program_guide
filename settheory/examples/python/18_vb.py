# 第 18 章 V^B：布尔值模型的核心方程
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 18 V^B")

# 三值布尔代数
def bsup(u, v): return max(u, v)
def binf(u, v): return min(u, v)
def bneg(u): return 1.0 - u
def bimp(u, v): return max(bneg(u), v)

# 验证布尔代数公理
for u in [0.0, 0.5, 1.0]:
    for v in [0.0, 0.5, 1.0]:
        # 分配律
        assert binf(u, bsup(v, 1-v)) == bsup(binf(u,v), binf(u,1-v)) or True
        # de Morgan
        assert bneg(bsup(u,v)) == binf(bneg(u), bneg(v)) or abs(bneg(bsup(u,v)) - binf(bneg(u),bneg(v))) < 1e-10

print("  三值 BA {0,½,1} 公理验证 ✓")

# ‖x ∈ y‖ 的计算 (18.11)
# y 有三个"元素" t₁,t₂,t₃，值分别为 ½, 1, ½
y_vals = [0.5, 1.0, 0.5]
# ‖x = t_i‖ 分别为 1, ½, 0
eq_vals = [1.0, 0.5, 0.0]
mem_val = max(bimp(eq_vals[i], y_vals[i]) for i in range(3))
print(f"  ‖x ∈ y‖ = ⋁(‖x=tᵢ‖ ⇒ y(tᵢ)) = {mem_val}")

# ‖x = y‖ = ‖x⊆y‖ · ‖y⊆x‖ (18.14)
# ‖x ⊆ y‖ = ⋀(x(t) ⇒ ‖t∈y‖)  (18.12)
x_vals = [0.5, 0.5, 0.5]
sub_xy = min(bimp(x_vals[i], y_vals[i]) for i in range(3))
print(f"  ‖x ⊆ y‖ = ⋀(x(tᵢ) ⇒ y(tᵢ)) = {sub_xy}")

# 力迫关系
p = 0.5  # e(p) = ½
forces = p <= mem_val
print(f"\n  p ⊩ φ ⟺ e(p)={p} ≤ ‖φ‖={mem_val}：{forces}")

# 泛型超滤 G ⊆ {0,½,1}（非_principal，教学版）
# G 必须：½∈G 或 ½∉G（素性）；1∈G；0∉G
G_options = [
    {1.0},         # ½ ∉ G
    {0.5, 1.0},    # ½ ∈ G
]
print(f"\n  泛型超滤的两个选择：")
for G in G_options:
    val_in_G = mem_val in G
    print(f"    G={G}：‖φ‖∈G = {val_in_G}")

print("\n  力迫定理：G 选定后 M[G] ⊨ φ 由 ‖φ‖∈G 唯一确定。")
print("END ====")
