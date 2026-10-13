# 第 18 章 布尔值模型 V^B：布尔值的计算
println("==== 18 V^B：布尔值计算")

# 三值布尔代数 {0, ½, 1}（教学版）
# 用 Double 0.0 / 0.5 / 1.0 表示

const B = [0.0, 0.5, 1.0]
bsup(u, v) = max(u, v)
binf(u, v) = min(u, v)
bneg(u) = 1.0 - u
bimp(u, v) = bsup(bneg(u), v)

println("  布尔值代数 {0, ½, 1}：")
println("    ½ ⇒ 0 = $(bimp(0.5, 0.0))（½ 的否定与 0 的 sup）")
println("    ½ ⇒ ½ = $(bimp(0.5, 0.5))")
println("    0 ⇒ ½ = $(bimp(0.0, 0.5))")

# ‖x ∈ y‖ = ⋁_{t ∈ dom(y)} (‖x=t‖ ⇒ y(t))
# 教学版：小 V^B 层上的演示
# y = {t₁↦½, t₂↦1}；‖x=t₁‖=1, ‖x=t₂‖=½
mem_val = max(bimp(1.0, 0.5), bimp(0.5, 1.0))
println("\n  ‖x ∈ y‖ = ⋁(‖x=t₁‖⇒½, ‖x=t₂‖⇒1) = $(mem_val)")

# ‖x ⊆ y‖ = ⋀_{t} (x(t) ⇒ ‖t ∈ y‖)
sub_val = min(bimp(0.5, 0.5), bimp(1.0, 1.0))
println("  ‖x ⊆ y‖ = ⋀(½⇒½, 1⇒1) = $(sub_val)")

# 力迫关系：p ⊩ φ ⟺ e(p) ≤ ‖φ‖
println("\n  力迫关系 (18.26)：p ⊩ φ ⟺ e(p) ≤ ‖φ‖")
println("  e(p)=½ ≤ ‖φ‖=$(mem_val)：", 0.5 <= mem_val)
println("  e(p)=1 ≤ ‖φ‖=$(mem_val)：", 1.0 <= mem_val)

# 泛型超滤的切割
println("\n  泛型超滤 G 把 B 分为真/假：‖φ‖ ∈ G' 决定 M[G] ⊨ φ")
println("  力迫定理 (18.30)：M[G] ⊨ φ ⟺ ‖φ‖ ∈ G'")
println("END ====")
