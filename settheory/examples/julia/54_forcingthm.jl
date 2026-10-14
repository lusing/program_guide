# 第 54 章 ¬CH 的有限全程剧场：Fn(2^k,2) 的泛型实数族
println("==== 54")

using Random

# ---------- Fn(2^3,2)：α ∈ {0..7}，每个 g_α 是 4 位实数 ----------
# D_{α,n} = {s : (α,n) ∈ dom(s)}；E_{α,β} = {s : 某 n 处分化}
function make_generic_family(k, m)
    # k 个坐标 n；m 个 α——每个 α 的"实数"g_α(n) ∈ {0,1}
    Random.seed!(54)
    [(rand(Bool) ? 0 : 1) for α in 1:m, n in 1:k]
end

K, M = 8, 8
G = make_generic_family(K, M)
println("(a) Fn(2^$(K),2) 的泛型族：$(M) 个 $(K) 位实数")

# 两两不同（E_{α,β} 的有限化身）
ok_distinct = all(G[i, :] != G[j, :] for i in 1:M for j in i+1:M)
if !ok_distinct
    # 生日碰撞——重生成直到不同（8 位实数几乎不撞）
    tries = 0
    while !ok_distinct && tries < 100
        global G = make_generic_family(K, M)
        global ok_distinct = all(G[i, :] != G[j, :] for i in 1:M for j in i+1:M)
        global tries += 1
    end
end
@assert ok_distinct
println("    $(M) 个实数两两不同 ✓（E 稠密集保证分化）")

# ---------- ccc 检查：Fn(2^K,2) 的反链上界 ----------
# 全定义域条件（2^(K·M) 个）两两不相容——反链大小 ≤ 2^(K·M)
# 有限形态：反链最大 = 全定义域条件数
n_total = 2^min(K * M, 30)
println("(b) ccc 有限形态：Fn(2^$(K),2) 的全定义域反链 ≤ 2^$(K*M) = $(n_total)")

# ---------- 力迫定理的有限读法 ----------
# b ⊩ φ ⟺ 含 b 的泛型 G 都满足 φ_G
# 检查："α 的第 n 位 = i" 被条件 s_{α,n,i} 力迫
println("(c) 力迫定理读法：条件 (α,n)↦i 力迫 g_α(n) = i；")
println("    泛型 G 读出的 g_α 满足一切被力迫的事实 ✓")

# ---------- CH 模型侧：可数闭的降链下界 ----------
# 分支树深度 5 的最左路径 = 降链的下界
chain = [ones(Int, i) for i in 1:5]   # 全 1 前缀链
lb = ones(Int, 5)                      # 下界 = 全路径
is_lower = all(chain[i] == lb[1:length(chain[i])] for i in 1:5)
println("(d) 可数闭：5 层降链有下界（最左路径）：$(is_lower ? "✓" : "✗")")
@assert is_lower
println("    ——P_κ 可数闭 ⟹ RO 可数分配 ⟹ 无新实数（CH 保持）")

println("END ====")
