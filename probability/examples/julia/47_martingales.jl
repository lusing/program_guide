# 第 47 章 Julia：离散鞅的机器账（固定种子）。
# ① 鞅性的经验验证：给定 S_n = s 的条件下 S_{n+1} 的经验均值 = s
#    （公平游走是鞅——命题化的条件期望用分组平均逼近）；
# ② 上穿不等式的 MC 对账：E[U_(a,b)] <= (E[(X_n-a)^+] + a^-)/（b-a) 型界；
# ③ Doob 极大 L^2 不等式：E[max S_k^2] <= 4 E[S_n^2] = 4n；
# ④ 赌博系统（鞅变换，命题 7.2.1）：可料下注的最终财富期望仍为 0。
println("==== 47 martingales")
using Random, Statistics

# ---------- ① 鞅性的条件均值验证 ----------
println("① 鞅性验证（n=50 处（偶数时刻只取偶状态），按 S_50 = s 分组，S_51 的组内均值，8000 轨道）：")
rng = MersenneTwister(4701)
S = zeros(Int, 8000)
for k in 1:50
    S .+= ifelse.(rand(rng, 8000) .< 0.5, 1, -1)
end
S51 = S .+ ifelse.(rand(rng, 8000) .< 0.5, 1, -1)
for s in [-4, -2, 0, 2, 4]
    idx = findall(==(s), S)
    m = mean(S51[idx])
    println("   s = ", s, "：组均值 = ", round(m, digits=4), "（应 = s）")
    @assert abs(m - s) < 0.08
end

# ---------- ② 上穿不等式 ----------
println("② 上穿不等式（a=-2, b=2, n=200，1000 轨道）：")
function upcrossings(path, a, b)
    cnt = 0
    below = true
    for v in path
        if below
            if v <= a
                below = false
            end
        else
            if v >= b
                cnt += 1
                below = true
            end
        end
    end
    return cnt
end
rng2 = MersenneTwister(4702)
us = Int[]
for _ in 1:1000
    s = 0
    path = Int[]
    for _ in 1:200
        s += rand(rng2) < 0.5 ? 1 : -1
        push!(path, s)
    end
    push!(us, upcrossings(path, -2, 2))
end
eu = mean(us)
bound = 200 / 4   # E[(X_n - a)^+]/(b-a) <= n/(b-a) 的简明版
println("   E[U] = ", round(eu, digits=2), " <= 上界 n/(b-a) = ", bound)
@assert eu <= bound

# ---------- ③ Doob 极大 L² 不等式 ----------
println("③ Doob 极大不等式（n=100，2000 轨道）：")
rng3 = MersenneTwister(4703)
m2 = Float64[]
for _ in 1:2000
    s = 0
    mx = 0
    for _ in 1:100
        s += rand(rng3) < 0.5 ? 1 : -1
        mx = max(mx, abs(s))
    end
    push!(m2, mx^2)
end
println("   E[max S_k^2] = ", round(mean(m2), digits=1), " <= 4·E[S_n^2] = 400")
@assert mean(m2) <= 400

# ---------- ④ 赌博系统（鞅变换） ----------
println("④ 赌博系统（只在 S_k <= -2 后下注 1，公平游走 n=100，6000 轨道）：")
rng4 = MersenneTwister(4704)
wealth = Float64[]
for _ in 1:6000
    s = 0
    y = 0
    for _ in 1:100
        eps = s <= -2 ? 1 : 0        # 可料：只依赖过去
        step = rand(rng4) < 0.5 ? 1 : -1
        y += eps * step
        s += step
    end
    push!(wealth, y)
end
println("   E[Y_n] = ", round(mean(wealth), digits=4), "（理论 0），std = ",
        round(std(wealth), digits=3), "（鞅变换仍是鞅——没有免费的午餐）")
@assert abs(mean(wealth)) < 3 * std(wealth) / sqrt(6000)
println("END ====")
