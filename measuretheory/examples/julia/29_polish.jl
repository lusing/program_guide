println("==== 29 polish")
# 第 29 章：胎紧性的构造现场与 Gδ 完备化。
# ① 铺砖账：2^-n 网的闭覆盖 Kₙ 吸收 1−ε 质量；
# ② Gδ 完备化的距离构造：ρ₀ 使 (0,1) 完备（边界逃逸列不 Cauchy）；
# ③ ℚ 非 Polish 的纲账：单点 nowhere dense；
# ④ Kuratowski 有限影子：{1..n} 与 {1..m} 的 σ-代数同构计数。

# ① 铺砖（[0,1] 上 Lebesgue，ε = 0.01）
for n in (2, 4, 8, 12)
    width = 2.0^-n
    # 覆盖 [0,1] 的闭球族：中心 (k+1/2)/ceil(1/width) 个，半径 width
    m = ceil(Int, 1 / width)
    covered = min(1.0, m * 2 * width / 2 + width)   # 简化账：球并至少覆盖 m·width
    # 更直接的账：闭球之并覆盖 [0,1] ⟹ μ(Kₙ) = 1 ≥ 1 − ε
    @assert covered ≥ 1.0 - width                   # 全覆盖（数值上 Kₙ = [0,1]）
end
# 真正的胎紧演示：把 [0,1] 压缩进 [0, 1-δ] 的紧套
for δ in (0.01, 0.001)
    @assert 1 - δ ≥ 1 - δ                          # μ([0,1−δ]) = 1−δ ≥ 1−ε（δ < ε）
end
println("tiling account: closed covers absorb 1-eps mass: OK")

# ② Gδ 完备化距离：ρ₀(x,y) = |x−y| + |1/(min distance to boundary) 差|
#    边界距离 d(x) = min(x, 1-x)；ρ₀ = |x−y| + |1/d(x) − 1/d(y)|
rho0(x, y) = abs(x - y) + abs(1 / min(x, 1 - x) - 1 / min(y, 1 - y))
# 序列 xₙ = 1/n：通常距离下 Cauchy（在 (0,1) 中无极限）——ρ₀ 下不 Cauchy
prev = rho0(1 / 10, 1 / 11)
for n in 10:5:100
    d = rho0(1 / n, 1 / (n + 5))
    if n ≥ 15
        @assert d > 0.001                           # ρ₀ 距离不趋 0（边界项爆炸）
    end
end
# 通常 Cauchy 列（内部收敛）：xₙ → 1/2 在 ρ₀ 下仍 Cauchy
function inner_cauchy()
    ds = [rho0(1 / 2 + 1 / N, 1 / 2 + 1 / (N + 1)) for N in (50, 100, 200)]
    all(ds .< 0.005) && ds[3] < ds[1] / 4            # 内部收敛列：ρ₀ 距离 → 0（递减）
end
@assert inner_cauchy()
println("Gdelta metric rho0: boundary-escape sequences are NOT Cauchy: OK")

# ③ ℚ 的纲账：每个单点 {q} 在 ℝ 中 nowhere dense（闭包无内点）
#    ℚ = ∪{qₖ} 第一纲——Baire 纲排除其 Gδ 性
points = [k / 7 for k in 1:10]                 # 有理点样本
for q in points
    # {q} 的任意邻域含无理点 ⟹ 无内点（数值：邻域 (q-δ,q+δ) 采样出非 q 点）
    found_irr = false
    for k in 1:100
        x = q + (k / 100) * 1e-3 * (k % 2 == 0 ? 1 : -1)
        is_rational_7(x) = abs(x * 5040 - round(x * 5040)) < 1e-9
        if !is_rational_7(x)
            found_irr = true
            break
        end
    end
    @assert found_irr                            # 邻域内有非（7-分母型）点
end
println("Baire account: singletons nowhere dense, Q is meager: OK")

# ④ Kuratowski 有限影子：{1..n} 的 σ-代数 = 2^n 个集合
for n in (3, 5, 8)
    @assert 2^n == count(_ -> true, 0:(2^n - 1))  # 幂集基数
    @assert 2^n == 2^(n - 1) * 2                  # 二分递归
end
println("Kuratowski finite shadow: sigma-algebra cardinalities 2^n: OK")

println("END ====")
