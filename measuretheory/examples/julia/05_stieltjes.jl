println("==== 05 stieltjes")

# 第 05 章：Lebesgue-Stieltjes 测度的数值实验。
# 三种分布函数：纯跳（原子）、绝对连续（恒等）、Cantor（奇异），
# 统一用 μ(a,b] = F(b) - F(a) 计算。

using Random
Random.seed!(5)

# --- F1：纯跳分布（整数点 1..4 各质量 1/4）---
F_atom(x) = count(k -> k <= x, 1:4) / 4

@assert F_atom(0.5) == 0.0
@assert F_atom(1.0) == 0.25   # 右连续：x=1 处质量已计入
@assert F_atom(4.0) == 1.0
println("原子分布 F：F(0.5)=$(F_atom(0.5))，F(1)=$(F_atom(1.0))，F(4)=$(F_atom(4.0))（右连续）")

# LS 测度：μ_F(a,b] = F(b) - F(a)
muF(F, a, b) = F(b) - F(a)

# 原子测度检验：区间 (0.5, 3.5] 含原子 {1,2,3}，质量 3/4
@assert abs(muF(F_atom, 0.5, 3.5) - 0.75) < 1e-15
# 单点质量：μ{k} = F(k) - F(k-)
mu_point(F, k, eps = 1e-9) = F(k) - F(k - eps)
for k in 1:4
    @assert abs(mu_point(F_atom, k) - 0.25) < 1e-6 "原子 {k} 质量应为 1/4"
end
println("原子测度：μ(0.5,3.5] = 0.75；单点质量均为 1/4")

# --- F2：绝对连续（恒等）→ Lebesgue ---
F_id(x) = clamp(x, 0.0, 1.0)
@assert abs(muF(F_id, 0.2, 0.7) - 0.5) < 1e-15
@assert abs(muF(F_id, 0.2, 0.5) + muF(F_id, 0.5, 0.8) - muF(F_id, 0.2, 0.8)) < 1e-15
println("恒等 F：μ(0.2,0.7] = 0.5；区间可加性 OK（Lebesgue 测度）")

# --- F3：Cantor 分布（奇异，无原子，支撑零测）---
function cantor_F(x, depth = 40)
    x <= 0 && return 0.0
    x >= 1 && return 1.0
    acc = 0.0
    y = x
    for i in 1:depth
        y *= 3
        d = floor(Int, y)
        if d == 1
            return acc + 2.0^(-i)   # 中段常值：左端值 + 半位
        end
        d == 2 && (acc += 2.0^(-i))
        y -= d
    end
    acc
end

xs = range(0, 1, length = 1001)
Fv = [cantor_F(x) for x in xs]
@assert Fv[1] == 0.0 && abs(Fv[end] - 1.0) < 1e-12 "Cantor F 端点：F(0)=0，F(1)=1"
mono_ok = all(Fv[i] <= Fv[i+1] + 1e-9 for i in 1:1000)
@assert mono_ok "Cantor 函数单调"
println("Cantor F：单调 OK；F(0)=$(Fv[1])，F(1)=$(Fv[end])")

# Cantor 测度的自相似：μ([0,1/3]) = 1/2（前 1/3 承载一半质量）
m13 = cantor_F(1 / 3) - cantor_F(0.0)
@assert abs(m13 - 0.5) < 1e-9 "μ([0,1/3]) 应为 1/2"
m_middle = cantor_F(2 / 3) - cantor_F(1 / 3)
@assert m_middle < 1e-9 "中段 (1/3,2/3) 质量应为 0（挖空）"
println("Cantor 测度：μ[0,1/3] = $(m13)（自相似半质量），中段质量 $(m_middle)（零）")

# 无原子性
for p in [0.0, 1 / 3, 1 / 9, 0.5, 1.0]
    @assert mu_point(cantor_F, p, 1e-12) < 1e-6 "Cantor 测度无原子（eps=1e-12：陡坡有限斜率不再虚增）"
end
println("Cantor 测度无原子：5 个测试点单点质量均 < 1e-6（奇异连续）")

# --- 从 Cantor 分布抽样（二进均匀 → Cantor 逆），检验经验分布 ---
function cantor_sample(n)
    us = rand(n)
    out = Vector{Float64}(undef, n)
    for (idx, ui) in enumerate(us)
        x = 0.0
        u = ui
        for i in 1:30
            u *= 2
            x += (u >= 1.0 ? 2 : 0) / 3^i
            u = u >= 1.0 ? u - 1 : u
        end
        out[idx] = x
    end
    out
end
smp = cantor_sample(20000)
in_third_1 = count(<(1 / 3), smp) / length(smp)
@assert abs(in_third_1 - 0.5) < 0.02 "Cantor 样本落入前 1/3 的频率应约 1/2"
in_middle = count(x -> 1 / 3 < x < 2 / 3, smp) / length(smp)
@assert in_middle < 0.001 "样本几乎不落入中段"
println("Cantor 抽样 2 万点：前 1/3 频率 $(round(in_third_1, digits=4))（理论 0.5），中段频率 $(in_middle)")

println("END ====")
