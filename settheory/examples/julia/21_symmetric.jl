# 第 21 章 对称子模型：置换论证的数值骨架
println("==== 21 对称子模型")

# ---------- 例 I：A 无可数子集 ----------

println("例 I（引理 21.2）：")
println("  A = 无穷原子集；𝔊 = Sym(A)；𝔽 由 fix(E) 生成（E 有限）")
println("  反设 f : ω → A 单射且 f ∈ 𝔐（有有限支撑 E）")
println("  取 a ∈ A-E 且 a = f(n)；取 b ∈ A-E-{a}")
println("  π 交换 a,b 且固定 E：πf = f 但 π(f(n)) = b ≠ a——矛盾")

# ---------- 例 II：可数对族无选择函数 ----------

println("\n例 II（引理 21.3）：")
pairs = [(2k, 2k+1) for k in 0:4]
println("  Pₙ 对族：", pairs[1:min(3,end)], "…")
println("  反设 f 选择 f(Pₙ) ∈ Pₙ 且 f 有有限支撑 E")
println("  取 n 使 aₙ,bₙ ∉ E；π 在 Pₙ 内交换 aₙ↔bₙ 且固定 E")
println("  πf = f 但 π(f(Pₙ)) = bₙ ≠ aₙ——矛盾")

# ---------- 对称模型（ZF 版本） ----------

println("\n对称模型（§21 后半）：")
println("  𝔊 ⊆ Aut(B) 作用于 V^B 的名字")
println("  HS = 遗传对称名；𝔑 = (HS)^G ⊆ M[G]")
println("  𝔑 ⊨ ZF 但可以 ⊨ ¬AC")
println("  HOD(A) 是对称模型的特例（定理 45 的推广）")

println("END ====")
