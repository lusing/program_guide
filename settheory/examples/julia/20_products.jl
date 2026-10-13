# 第 20 章 链条件与积力迫：积的泛型滤波器
println("==== 20 积力迫")

# Product Lemma（引理 20.1）的数值骨架
# P₁ 和 P₂ 各自的小偏序；P₁×P₂ 上的条件 (p₁,p₂)

# 两套简单条件（单点 0/1）
p_set1 = [(i, b) for i in 0:1, b in [false, true]]
p_set2 = [(j, b) for j in 0:1, b in [false, true]]

# 积条件 = (p₁, p₂) 对
prod = collect(Iterators.product(p_set1, p_set2))
println("  |P₁| = ", length(p_set1), "，|P₂| = ", length(p_set2))
println("  |P₁×P₂| = ", length(prod), " = |P₁|·|P₂|")

# 相容性在积中是分量的
compatible_prod((p1,q1), (p2,q2)) = compatible_single(p1,p2) && compatible_single(q1,q2)
compatible_single((i1,b1),(i2,b2)) = !(i1==i2 && b1!=b2)

c1 = ((0, false), (1, true))
c2 = ((0, false), (0, true))
c3 = ((0, true), (0, true))
println("\n  条件 $(c1) 与 $(c2) 相容 = ", compatible_prod(c1,c2))
println("  条件 $(c1) 与 $(c3) 相容 = ", compatible_prod(c1,c3))

println("\n  Product Lemma（引理 20.1）：")
println("  G 在 P₁×P₂ 泛型 ⟺ G = G₁×G₂，G₁ 泛型于 P₁，G₂ 泛型于 M[G₁]")
println("  且 M[G] = M[G₁][G₂] = M[G₂][G₁]（对称性）")

println("\n  Levy 崩塌（引理 20.4）：不可达 λ 变 κ⁺")
println("  Easton 定理（定理 46）：正则 κ 处 2^κ 可自由规定")
println("END ====")
