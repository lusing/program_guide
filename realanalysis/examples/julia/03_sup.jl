# 第 03 章 上确界：Julia 通道。
# 原书定理 4.1 的 q-迭代：从 p=1 出发，q=(2p+2)/(p+2) 单调逼近 √2，
# 每步都验证 p < q 且 q² < 2（精确有理数），并观察与 √2 的误差收缩。
# 运行：julia --startup-file=no 03_sup.jl

println("==== 03 sup ====")

# --- 1. q-迭代：有理数世界里“没有最大元”的动态演示 -------------------
# 两条恒等式与原书的代数推导逐项对应：
#   q - p = (2 - p^2)/(p+2)，q^2 - 2 = 2(p^2 - 2)/(p+2)^2。
qstep(p) = (2p + 2) // (p + 2)

function check_identities(p)
    q = qstep(p)
    @assert q - p == (2 - p^2) // (p + 2)
    @assert q^2 - 2 == 2 * (p^2 - 2) // (p + 2)^2
    return q
end

function qiteration(p0, kmax; below::Bool)
    p = p0
    traj = [p]
    for _ in 1:kmax
        q = check_identities(p)
        if below
            @assert q > p && q^2 < 2
        else
            @assert 0 < q < p && q^2 > 2
        end
        push!(traj, q)
        p = q
    end
    return traj
end

traj = qiteration(1 // 1, 8; below=true)
println("q-iteration from below (exact rationals), last two:")
println("  p_7 = $(traj[8])")
println("  p_8 = $(traj[9])")
println("  p_8^2 = $(traj[9]^2) < 2, gap 2-p^2 = $(Float64(2 - traj[9]^2))")

above = qiteration(2 // 1, 8; below=false)
println("q-iteration from above, gap p_8^2-2 = $(Float64(above[end]^2 - 2))")

# 迭代的极限点 sqrt(2) 不是有理数——有理数列永远到不了自己的上确界，
# 这就是“Q 有洞”的计算学表述。
@assert all(t -> t^2 < 2, traj)

# --- 2. 有限集合的上确界 = 最大值 ------------------------------------
# 截断前 8 步的点列是有限集：它的上确界就是最大值（在集合内）。
@assert maximum(traj) == traj[end]          # 单调递增
# 上界性的逐点核验：最大值不小于任何成员。
@assert all(t -> t <= maximum(traj), traj)

# --- 3. 序列值域 {1 - 1/(n+1)} 的截断上确界实验 ----------------------
# 数学事实：sup = 1，但 1 不属于值域——上确界可以不属于集合。
f(n) = 1 - 1 // (n + 1)
for N in (10, 1000, 100000)
    best = maximum(f(n) for n in 0:N)
    @assert best == f(N)                    # 递增序列：截断 sup 在末端
    @assert best < 1                        # 永远够不到 1
    @assert 1 - best == 1 // (N + 1)
end
# Archimedean 核验：给定 eps，存在 n 使 1 - 1/(n+1) > 1 - eps。
for eps in (1 // 10, 1 // 10^6)
    n = ceil(Int, 1 / Float64(eps)) + 1
    @assert f(n) > 1 - eps
end
println("truncated sup of {1-1/(n+1)} stays < 1 but converges to 1")

# --- 4. 例 4.8：{1/(n+1)} 的上确界 1 被取到，下确界 0 取不到 ---------
g(n) = 1 // (n + 1)
for N in (10, 1000, 100000)
    @assert maximum(g(n) for n in 0:N) == g(0) == 1 // 1
    @assert minimum(g(n) for n in 0:N) == g(N) > 0
end
# 中点：γ < 3 时 (γ+3)/2 仍小于 3。
γ = 5 // 2
@assert γ < (γ + 3) // 2 < 3
println("sup of {1/(n+1)} attained; inf not attained; midpoint stays below 3")

println("END ====")
