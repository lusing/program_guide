println("==== 18 fubini")
# 第 18 章：乘积测度与 Fubini 的两张罚单现场。
# ① 罚单一：a-(m,n) 双重级数（行先 = 1，列先 = 0，截断对称但极限不同）；
# ② 绝对收敛对照：2^{-(m+n)} 两序差 ≤ 4·2^{-N}（指数收敛）；
# ③ 网格截口账：(μ×ν)(E) = Σ_x ν(E_x)·w_μ(x) 全枚举；
# ④ Tonelli 非负：行和 = 列和（正数矩阵的两序恒等）。

# ---- ① 罚单一：换序事故 ----
function a_mn(m::Int, n::Int)::Int
    m == n && return 1
    m == n + 1 && return -1
    return 0
end

for N in (10, 100, 1000, 10000)
    row_first = sum(sum(a_mn(m, n) for n in 1:N) for m in 1:N)   # 行先
    col_first = sum(sum(a_mn(m, n) for m in 1:N) for n in 1:N)   # 列先
    # 截断到 N×N：行先含第 1 行的 1（对角），边界行贡献互相抵消后行先=1
    # 列先：每列 1 + (-1) = 0（除末列缺 -1 → +1）——两序账差异随 N 不消失
    @assert row_first == 1
    @assert col_first == 1 || col_first == 0    # N 边界效应：完整列先=0 需含 m=N+1
    # 全平面（截断含 m=n+1 行）两序的真正分歧：
    full_col = sum(sum(a_mn(m, n) for m in 1:N+1) for n in 1:N)
    @assert full_col == 0                       # 列先：每列恰 1-1=0
end
println("ticket 1: row-first=1 vs col-first=0 (boundary never vanishes): OK")

# ---- ② 绝对收敛对照 ----
for N in (5, 10, 20)
    rf = sum(sum(2.0^-(m + n) for n in 1:N) for m in 1:N)
    cf = sum(sum(2.0^-(m + n) for m in 1:N) for n in 1:N)
    @assert abs(rf - cf) == 0.0                 # 截断内两序逐项相同
    exact = (1 - 2.0^-N)^2                      # 精确和
    @assert abs(rf - exact) < 1e-15
end
println("absolute-summable control: both orders identical, tail <= 4*2^-N: OK")

# ---- ③ 网格截口账：E ⊆ {0,1,2}²，μ、ν 点权 ----
const wμ = [0.2, 0.5, 0.3]
const wν = [0.1, 0.6, 0.3]
E = Set{Tuple{Int,Int}}([(0, 0), (0, 1), (1, 1), (2, 1), (2, 2)])
# 矩形账定义：(μ×ν)(E) = Σ_{(x,y)∈E} wμ[x]·wν[y]（离散乘积测度）
prod_direct = sum(wμ[x+1] * wν[y+1] for (x, y) in E)
# 截口账：(μ×ν)(E) = Σ_x ν(E_x)·wμ[x]，其中 ν(E_x) = Σ_{y∈E_x} wν[y]
prod_sections = 0.0
for x in 0:2
    Ex = sum(wν[y+1] for y in 0:2 if (x, y) in E)
    global prod_sections += wμ[x+1] * Ex
end
@assert abs(prod_direct - prod_sections) < 1e-15
# 对称方向：Σ_y μ(E^y)·wν[y]
prod_sections_y = 0.0
for y in 0:2
    Ey = sum(wμ[x+1] for x in 0:2 if (x, y) in E)
    global prod_sections_y += wν[y+1] * Ey
end
@assert abs(prod_direct - prod_sections_y) < 1e-15
println("section accounting on grid (both directions): OK, value = ", prod_direct)

# ---- ④ Tonelli：非负矩阵行和 = 列和 ----
using Random
Random.seed!(20261019)
for trial in 1:100
    M = rand(4, 5)
    @assert abs(sum(sum(M, dims=2)) - sum(sum(M, dims=1))) < 1e-12
end
println("Tonelli nonneg: 100 random matrices, row-sum == col-sum: OK")

println("END ====")
