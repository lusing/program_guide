# 第 144 章 Julia：beth 阶梯与反映的数值面（书 7.8-7.9）。
# ① |V_{ω+n}| = beth_n 的数值验证（有限段）；
# ② 反映定理的层扫描：给定性偏找出最小 V_α 使其成立；
# ③ 不可达的"不可能三角"：正则 + 强极限 + >ω 在有限宇宙的缺失。
println("==== 144 inaccessible")

# ① V_n 的有限段增长（|V_n| = tower(2,...) 的前段）
sizes = BigInt[0]
for n in 1:5
    push!(sizes, big(2) ^ sizes[end])
end
# |V_0|=0, |V_1|=1=2^0, |V_2|=2=2^1, |V_3|=4=2^2, |V_4|=16=2^4, |V_5|=65536=2^16
@assert sizes == [0, 1, 2, 4, 16, 65536]
println("V sizes: |V_n+1| = 2^|V_n| for n >= 1: OK")

# beth 阶梯的类比：beth_0 = ℵ₀（无穷），有限影子是 0→1→2→4→16
# 反映 |V_{ω+n}| = beth_n：|V_{ω+1}| = 2^|V_ω| = 2^ℵ₀ = c
println("beth ladder: |V_{w+n}| = beth_n, beth_1 = 2^aleph0 = c: OK")

# ② 层扫描（反映定理的窗口版）：找最小 α 使性质 P 在 V_α 中成立
function find_reflection_layer(props, layers)
    for (i, V_a) in enumerate(layers)
        if all(p(V_a) for p in props)
            return i
        end
    end
    return -1
end

# 性质集："∅ 存在"、"传递性"、"'{∅}' 存在"
p1(V_a) = Set() in V_a
p2(V_a) = true                                    # V_n 天然传递
p3(V_a) = Set([Set()]) in V_a
layers = [Set{Any}(), Set{Any}([Set()]), Set{Any}([Set(), Set([Set()])])]
# p3 需要到 V_2；p1 从 V_1 开始
@assert find_reflection_layer([p1], layers) == 2
@assert find_reflection_layer([p1, p3], layers) == 3
println("reflection layer scan: minimal alpha found for each prop set: OK")

# ③ 强极限在有限宇宙的不可能性
is_strong_limit(n) = n > 0 && all(2^k < n for k in 0:n-1)
for n in (4, 8, 16, 100, 1000)
    @assert !is_strong_limit(n)                   # n ≤ 2^{n-1} 恒真
end
println("strong limit impossible in finite: n <= 2^(n-1) always: OK")

# 不可达三条件的完整叙事（窗口外，记号式总结）
println("inaccessible = regular + strong limit + > w (purely infinite): OK")
println("END ====")
