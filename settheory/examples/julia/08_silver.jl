# 第 08 章 奇异基数：beth 表、Silver 传染与范数演示
#
# 1. beth 阶梯的数值侧影（ℶ₀=ℵ₀、ℶ_{α+1}=2^ℶ_α）；
# 2. Silver 定理（定理 23）的"传染"直觉：GCH 在 {ℵ_n} 上成立
#    ⟹ 在 ℵ_ω 处成立（不可数共尾才有效——对照 §8 的反例注释）；
# 3. 范数 ‖φ‖（引理 8.6-8.7 的良基关系）的有限计算。

println("==== 08 奇异基数：beth 与 Silver")

# ---------- 一、beth 阶梯（用位长近似"大小"） ----------

"""beth 的有限侧影：用 2↑↑k 层级（幂塔）表示增长形态"""
beth_like(k::Int) = k == 0 ? "ℵ₀" : (k == 1 ? "2^ℵ₀ = 𝔠" : "2^ℶ_$(k-1)")

for k in 0:5
    println("  ℶ_$k = ", beth_like(k))
end
println("  （ℶ_ω = sup——强极限的首个不动点候选；GCH ⟺ ℶ_α = ℵ_α）")

# ---------- 二、Silver 传染的表格式直觉 ----------

println("\nSilver（定理 23a）：cf κ > ω 时 GCH 从下方传染到 κ")
println("  设 κ = ℵ_ω₁（cf = ω₁），下方 2^ℵ_α = ℵ_{α+1} 对 α < ω₁：")
println("  表格模式（α | 2^ℵ_α | 是否 ℵ_{α+1}）：")
for a in ["0", "1", "2", "…", "ω", "ω+1", "…", "ω₁-1", "ω₁(=κ)"]
    if a == "ω₁(=κ)"
        println("    $a |  2^κ = ℵ_{ω₁+1}（Silver 的结论——不是自由格）")
    elseif a in ("…",)
        println("    ⋮")
    else
        println("    $a |  ℵ_$(a == "0" ? "1" : a == "1" ? "2" : "…") | ✓")
    end
end
println("  反例注释（§8）：cf κ = ω 时可一致地 2^ℵ_n = ℵ_{n+1} 而")
println("  2^ℵ_ω = ℵ_{ω+2}——Magidor（大基数下）——共尾不可数是必需的。")

# ---------- 三、范数 ‖φ‖：eventual dominance 的有限计算 ----------

"""φ < ψ ⟺ {α : φ(α) ≤ ψ(α)} thin（有限版：密度 < 1/2）
   范数 = 降链长度（well-founded 的有限代理）"""
function norm(phi::Vector{Int})
    # 贪心降链：φ → ψ（ψ 在多数点 < φ）
    len = 0
    cur = copy(phi)
    while any(x -> x > 0, cur)
        cur = [max(c - 1, 0) for c in cur]   # 统一降 1（dominance 的简单版本）
        len += 1
    end
    return len
end

phi1 = [3, 1, 4, 1, 5]
phi2 = [9, 9, 9, 9, 9]
println("\n范数（降链长度）：‖[3,1,4,1,5]‖ = ", norm(phi1))
println("               ‖[9,9,9,9,9]‖ = ", norm(phi2))
@assert norm(phi1) == 5 && norm(phi2) == 9
println("  ‖φ‖ 是序数值的函数（引理 8.7）：|F| ≤ ℵ_{ω₁}+‖φ‖ 的右端")
println("  把'几乎不交族的大小'用范数分层——Silver 链条的最深一环。")

println("END ====")
