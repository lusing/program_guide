println("==== 09 convergence_modes")
# 第 09 章：收敛方式矩阵的数值版。
# 机器一（滑动脊）：fₙ = I_{[n,n+1]}，a.e. → 0 但依测度失败（窗口口径）。
# 机器二（打字机）：层-段指示函数，依测度 → 0 但逐点处处不收敛
#   （每点每层恰被扫中一次：前 2^15−1 项命中恰 15 次）。
# 机器三（逃逸尖峰 + Egorov）：fₙ = n·I_{(0,1/n)}，按证明构造挖集，
#   补集上从 n(1) 起 sup-误差精确为 0。

using Random

# --- 机器一：滑动脊 ---
M = 8.0                                        # 截断窗口 [0, 8]
sliding(x, n) = (n ≤ x ≤ n + 1) ? 1.0 : 0.0
Random.seed!(42)
xs = rand(200_000) .* M
for n in [1, 3, 6]
    emp = sum(sliding.(xs, n)) / length(xs)     # μ([|fₙ| ≥ 1/2]) 窗口采样
    @assert abs(emp - 1.0 / M) < 0.01           # ≈ 1/M，不随 n 消失
end
x0 = 3.7
@assert sum(sliding(x0, n) for n in 1:20) == 1.0  # 固定点至多一节为 1
println("sliding hump: in-measure deviation stays ~1/M (a.e. OK, in-measure FAIL): OK")

# --- 机器二：打字机 ---
"""n ↦ (层 k, 段 j)：层 k 有 2^(k-1) 段，段长 2^-(k-1)。n=1 → (1,1)。"""
function typewriter(n)
    k = 1
    while n > 2^k - 1
        k += 1
    end
    (k, n - 2^(k - 1) + 1)
end
tw(x, n) = begin
    k, j = typewriter(n)
    seg = (j - 1) / 2^(k - 1)
    seg ≤ x < j / 2^(k - 1) ? 1.0 : 0.0
end
xs01 = rand(200_000)
for n in [8, 32, 128, 512]
    k, _ = typewriter(n)
    dev_analytic = 2.0^-(k - 1)                 # 偏差集 = 当前段
    emp = sum(tw.(xs01, n)) / length(xs01)
    @assert abs(emp - dev_analytic) < 0.01      # 采样与解析吻合
end
println("typewriter: in-measure deviation = segment length 2^-(k-1) -> 0: OK")
# 逐点：0.3 与 0.7 每层恰一次命中（前 2^15−1 项 = 层 1..15，命中恰 15）
N_END = 2^15 - 1
hits03 = count(tw(0.3, n) == 1.0 for n in 1:N_END)
hits07 = count(tw(0.7, n) == 1.0 for n in 1:N_END)
println("typewriter: hits at x=0.3: ", hits03, ", at x=0.7: ", hits07, " (expect 15 each)")
@assert hits03 == 15 && hits07 == 15            # 每层一次 → 无穷层无穷次 → 不收敛

# --- 机器三：逃逸尖峰 + Egorov 数值版 ---
spike(x, n) = (0.0 < x < 1.0 / n) ? Float64(n) : 0.0
# a.e. 验证：x ≥ 1/4 的点，n ≥ 4 后恒为 0
pts = rand(10_000) .* 0.5 .+ 0.25               # 样本在 (0.25, 0.75)
@assert all(spike.(pts, 10_000) .== 0.0)
# Egorov 构造：ε = 0.05，n(k) = ceil(2^k/ε)，t = ⋃ₖ 尾集 = (0, 1/n(1)]
ε = 0.05
n_of_k(k) = ceil(Int, 2.0^k / ε)
t_right = 1.0 / n_of_k(1)                        # 嵌套并的右端
@assert t_right ≤ ε                              # μ(t) = 1/40 ≤ ε
# 补集 [1/n(1), 1] 上，i ≥ n(1) 时 fᵢ ≡ 0 —— sup-误差精确为 0
sup_err = maximum(abs(spike(x, i))
                 for x in t_right:1e-4:1.0, i in n_of_k(1):(n_of_k(1) + 200))
@assert sup_err == 0.0
println("spike+Egorov: mu(t) = ", t_right, " <= eps = ", ε,
        "; sup-error on complement exactly 0: OK")

println("END ====")
