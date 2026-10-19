println("==== 07 measurable_maps")
# 第 07 章：有限宇宙上 σ(f) 的机器枚举。
# Ω = {1..8}, f = [1,1,2,2,3,3,3,3]（三个纤维）。
# 实验一：σ(f) = 纤维并集族，|σ(f)| = 2^3 = 8。
# 实验二：因子定理——g 为 σ(f)-可测 ⟺ g 在纤维上常数（穷举 3^8 = 6561 个）。
# 实验三：可测 g 的 h 分解在纤维标记上唯一。

const Ω = collect(1:8)
const f = [1, 1, 2, 2, 3, 3, 3, 3]
const fibers = [filter(i -> f[i] == v, Ω) for v in sort(unique(f))]  # 3 个纤维

# --- 实验一：σ(f) 枚举 ---
sigma_f = Set{Vector{Int}}()
for mask in 0:(2^3 - 1)
    s = Int[]
    for (b, fb) in enumerate(fibers)
        (mask >> (b - 1)) & 1 == 1 && append!(s, fb)
    end
    push!(sigma_f, sort!(s))
end
println("fibers: ", fibers)
println("sigma(f) size = ", length(sigma_f), " (expect 2^3 = 8)")
@assert length(sigma_f) == 8
@assert sort!(collect(sigma_f)) == sort!([[], [1,2], [3,4], [5,6,7,8],
    [1,2,3,4], [1,2,5,6,7,8], [3,4,5,6,7,8], [1,2,3,4,5,6,7,8]])
# σ-代数封闭性自检：补与并
for A in sigma_f, B in sigma_f
    @assert sort!(setdiff(Ω, A)) in sigma_f          # 补封闭
    @assert sort!(union(A, B)) in sigma_f            # 并封闭
end
println("sigma(f) closed under complement/union: OK")

# --- 实验二：因子定理 穷举 3^8 ---
values = [0, 1, 2]
n_meas = 0
for code in 0:(3^8 - 1)
    g = [values[(code ÷ 3^(i - 1)) % 3 + 1] for i in 1:8]
    const_on_fibers = all(all(g[i] == g[first(fb)] for i in fb) for fb in fibers)
    # 可测性 ⟺ g⁻¹({v}) ∈ σ(f) ⟺ 每个水平集是纤维并
    levels_meas = all(
        sort!(filter(i -> g[i] == v, Ω)) in sigma_f for v in unique(g))
    @assert const_on_fibers == levels_meas   # 双方向逐例吻合
    const_on_fibers && (global n_meas += 1)
end
println("measurable g count = ", n_meas, " (expect 3^3 = 27)")
@assert n_meas == 27

# --- 实验三：h 分解唯一性 ---
g = [5, 5, 7, 7, 9, 9, 9, 9]   # 按纤维常数
h = Dict(v => g[first(filter(i -> f[i] == v, Ω))] for v in unique(f))
@assert all(g[i] == h[f[i]] for i in Ω)         # g = h ∘ f
println("g = h∘f decomposition unique on fiber labels: OK (h = ", h, ")")

println("END ====")
