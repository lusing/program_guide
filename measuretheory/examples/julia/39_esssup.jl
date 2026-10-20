println("==== 39 esssup")
# 第 39 章：尖刺的无视与格运算。
# ① 零测尖刺 vs 正测尖刺的 ess sup 跳变；
# ② sup vs ess sup 谱系；③ 子可加与互补反例；④ 分块 ess sup。

# ① 尖刺测度参数化：格点权 w，尖刺点权 e
# ess sup：忽略权为零/趋零位置后的最大值（数值上以阈值 eps 代理）
esssup_grid(vals, w, eps) = maximum(vals[i] for i in eachindex(vals) if w[i] > eps)

vals = fill(1.0, 100)
vals[42] = 2.0                              # 尖刺
for eps in (0.0,)
    # 尖刺权 = 0（严格零测）：ess sup = 1（无视尖刺）
    w0 = fill(0.01, 100); w0[42] = 0.0
    @assert esssup_grid(vals, w0, 1e-9) == 1.0
    # 尖刺权 > 0：ess sup = 2（尖刺入账）
    w1 = fill(0.01, 100); w1[42] = 0.01
    @assert esssup_grid(vals, w1, 1e-9) == 2.0
end
@assert maximum(vals) == 2.0                # sup 恒见尖刺
println("spike ignored at zero weight, seen at positive weight; sup always 2: OK")

# ② 谱系：尖刺比例参数化（1/100 格）
for spike_measure in (0.0, 0.01, 0.1)
    n = 100
    k = round(Int, spike_measure * n)
    v = fill(1.0, n)
    for i in 1:k; v[i] = 2.0; end
    w = fill(1 / n, n)
    es = esssup_grid(v, w, 1e-9)
    if k == 0
        @assert es == 1.0
    else
        @assert es == 2.0                   # 正测尖刺即刻入账
    end
    @assert maximum(v) == (k > 0 ? 2.0 : 1.0)
end
println("spike-measure spectrum: ess sup jumps as soon as spike has mass: OK")

# ③ 子可加与互补反例
f = fill(0.0, 50); f[1:25] .= 1.0           # 1_A：前半 1
g = fill(0.0, 50); g[26:50] .= 1.0          # 1_Ac：后半 1
w = fill(1 / 50, 50)
@assert esssup_grid(f, w, 1e-9) == 1.0
@assert esssup_grid(g, w, 1e-9) == 1.0
@assert esssup_grid(f .+ g, w, 1e-9) == 1.0      # ess sup(f+g) = 1
@assert esssup_grid(f, w, 1e-9) + esssup_grid(g, w, 1e-9) == 2.0  # < 2：严格子可加
println("subadditivity strict for complementary indicators (1 < 2): OK")

# ④ 分块 ess sup（条件 ess sup 的有限版）
blocks = [[1:20;], [21:40;], [41:50;]]
vv = rand(50) .+ [i <= 20 ? 0.0 : i <= 40 ? 1.0 : 2.0 for i in 1:50]
blockmax = [maximum(vv[b]) for b in blocks]
@assert maximum(blockmax) == maximum(vv)
# 分块 ess sup 的再取 max = 全局（有限世界精确账）
@assert esssup_grid(vv, w, 1e-9) == maximum(vv)
println("blockwise ess sup: max of block maxima = global ess sup: OK")

println("END ====")
