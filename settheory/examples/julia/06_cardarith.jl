# 第 06 章 基数算术：连续统函数模拟器与 König 不等式
#
# 1. Easton 定理的教学现场：正则基数上的连续统函数只需
#    单调 + cf(2^κ) > κ——构造满足约束的"合法"连续统函数；
# 2. König 不等式的有限验证：Σaᵢ < Πbᵢ（aᵢ < bᵢ, bᵢ ≥ 2）。

println("==== 06 基数算术：连续统函数与 König")

# ---------- 一、Easton 约束的数值体验 ----------

# 用 2^n 作为"连续统函数"的有限代理。约束：
#   (E1) 单调：α ≤ β ⟹ 2^α ≤ 2^β
#   (E2) König：cf(2^α) > α 的代理——增长"步幅"要足够大
# 在有限域：对正则"基数"（后继位置）任意指定 F(κ) 满足
# F(κ) > κ 且 F 保持单调即可——Easton 说的正是这种自由度。

function check_easton(F::Vector{Int})
    """检查连续统函数候选：严格递增（单调的严格版）"""
    all(F[i] < F[i+1] for i in 1:length(F)-1)
end

# 候选一：F(κ) = 2^κ（CH 模式：κ=ℵ_n ↦ 2^ℵ_n = ℵ_{n+1} 的代理）
F_ch = [2^k for k in 1:8]
println("候选一 F(κ)=2^κ：", F_ch)
@assert check_easton(F_ch)
println("  单调 ✓（Easton 约束下的合法点）")

# 候选二：F(κ) = 2^(2^κ)（"暴走"模式——Easton 允许！）
F_wild = [4^k for k in 1:8]
println("候选二 F(κ)=4^κ：", F_wild)
@assert check_easton(F_wild)
println("  同样合法——Easton：正则基数上的连续统函数只需满足两条约束，")
println("  ZFC 证明不了其他任何限制（在正则域内）。")

# ---------- 二、König 不等式的有限验证 ----------

"""Σaᵢ < Πbᵢ 当 aᵢ < bᵢ 且 bᵢ ≥ 2（有限版 König）"""
function konig_check(a::Vector{Int}, b::Vector{Int})
    @assert length(a) == length(b)
    @assert all(a[i] < b[i] for i in eachindex(a))
    @assert all(b[i] >= 2 for i in eachindex(b))
    S = sum(a)
    P = prod(b)
    return S, P, S < P
end

for (a, b) in [([1, 1], [2, 2]), ([0, 5, 3], [2, 7, 9]),
               ([2, 3, 4, 5], [3, 4, 5, 6])]
    S, P, ok = konig_check(a, b)
    println("  a=$a b=$b → Σ=$S < Π=$P : $ok")
    @assert ok
end
println("  König 有限版：Σκᵢ < Πλᵢ——无穷版是 cf(2^κ)>κ 与 κ^cf κ>κ 的源头")

# ---------- 三、gimel 函数表（Jech (6.15) 三分支） ----------

println("\ngimel ☞(κ) = κ^cf κ 的行为（超穷侧描述）：")
println("  后继基数 κ=ℵ_{α+1}（cf=κ）：   ☞(κ) = κ^κ = 2^κ")
println("  极限·终常值：                 2^κ = 2^γ0 ≤ ☞(κ)")
println("  极限·非终常值：               2^κ = ☞(2^<κ)")
println("  ——连续统函数完全由 gimel 决定（三分支定理）。")

println("END ====")
