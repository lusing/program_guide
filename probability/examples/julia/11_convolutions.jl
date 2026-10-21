# -*- coding: utf-8 -*-
println("==== 11 convolutions")
# 第 11 章 Julia：卷积与变量替换的频率形态。
# ① 两骰卷积 vs 模拟；② 四骰 grouping 卷积 vs 1296 格模拟；
# ③ 连续均匀 [−1/2,1/2] 自卷积的三角形密度 vs 模拟；
# ④ Y = X²（X 均匀 [0,2]）模拟直方图 vs 1/(4√y)；
# ⑤ 指数商 X/Y：λ = 1 与 λ = 5 的经验分布重合（λ 无关）
#    + 样本均值不稳定的现场观察。
using Random, Statistics

Random.seed!(11)

# ① 两骰：卷积公式（三角形）vs 模拟
tri2(z) = 2 <= z <= 7 ? (z - 1) / 36 : (7 < z <= 12 ? (13 - z) / 36 : 0.0)
sums2 = [rand(1:6) + rand(1:6) for _ in 1:500_000]
for z in 2:12
    emp = count(==(z), sums2) / length(sums2)
    @assert abs(emp - tri2(z)) < 0.005
end
println("two-dice convolution triangle vs simulation: OK")

# ② 四骰 grouping：f2 = 两骰密度（三角形，f2[i] ↔ 值 i+1），f4 = f2 * f2
f2 = [tri2(z) for z in 2:12]
f4 = [sum(f2[i] * f2[j - i - 2] for i in 1:11 if 2 <= j - i - 1 <= 12)
      for j in 4:24]      # j = z；值 i+1 与 z−(i+1)（索引再减一）配对
@assert abs(sum(f4) - 1) < 1e-12
@assert abs(f4[6 - 3] - 10 / 1296) < 1e-12   # f4(6) = 5/648
sums4 = [sum(rand(1:6, 4)) for _ in 1:500_000]
for z in 4:24
    emp = count(==(z), sums4) / length(sums4)
    @assert abs(emp - f4[z - 3]) < 0.003
end
println("four-dice grouping convolution f2*f2 vs simulation: OK")

# ③ 连续：两个 U[−1/2,1/2] 之和的三角形密度 (f*f)(z) = 1 − |z|
U = rand(1_000_000) .- 0.5 .+ (rand(1_000_000) .- 0.5)
for (lo, hi) in [(0.0, 0.25), (0.25, 0.5), (0.5, 0.75)]
    emp = count(x -> lo <= x <= hi, U) / length(U)
    theo = begin  # ∫ (1−|z|) dz over [lo,hi]（右半边）
        quad(z) = z - z^2 / 2
        quad(hi) - quad(lo)
    end
    @assert abs(emp - theo) < 0.004
end
@assert maximum(abs.(U)) <= 1.0 + 1e-12   # 支撑集 [−1,1]
println("continuous U+U triangle density vs simulation: OK")

# ④ Y = X²（X ~ U[0,2]）：密度 1/(4√y) 的分桶对拍
Y = (2 .* rand(400_000)) .^ 2
for (lo, hi) in [(0.01, 0.04), (0.25, 0.64), (1.0, 4.0)]
    emp = count(x -> lo <= x <= hi, Y) / length(Y)
    theo = sqrt(hi) / 2 - sqrt(lo) / 2     # ∫ 1/(4√y) dy = √y/2
    @assert abs(emp - theo) < 0.005
end
println("Y = X^2 change-of-variables density 1/(4*sqrt(y)): OK")

# ⑤ 指数商 Z = X/Y：密度 1/(1+z)² 与 λ 无关；样本均值不稳定
myexp(λ) = -λ * log(rand())
Z1 = [myexp(1.0) / myexp(1.0) for _ in 1:200_000]
Z5 = [myexp(5.0) / myexp(5.0) for _ in 1:200_000]
for thr in [0.5, 1.0, 3.0]
    e1 = count(<=(thr), Z1) / length(Z1)
    e5 = count(<=(thr), Z5) / length(Z5)
    theo = thr / (1 + thr)                 # P(Z ≤ t) = t/(1+t)
    @assert abs(e1 - theo) < 0.005 && abs(e5 - theo) < 0.005
end
m1a = mean(Z1[1:100_000]); m1b = mean(Z1[100_001:end])
spread = abs(m1a - m1b)
println("exponential ratio: CDF lambda-independent (0.5/1/3), ",
        "split-mean spread = ", round(spread, digits=2),
        " (mean is infinite — no LLN): OK")

println("END ====")
