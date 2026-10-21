# -*- coding: utf-8 -*-
println("==== 22 fourier_clt")
# 第 22 章 Julia：特征函数的频率形态。
# ① φ 的 MC 估计 vs 闭式（正态/均匀/Cauchy，实虚双部）；
# ② CLT 双版：标准化和的经验 φ vs e^{−t²/2}；③ Cauchy 稳定
#    与发散的 φ 对照；④ Box-Muller 生成器直方 vs φ。
using Random, Statistics

Random.seed!(22)

# ① 经验特征函数：E[e^{itX}] 的复平均
ecf(Z, t) = sum(exp(im * t * z) for z in Z) / length(Z)

# 正态
Z = randn(400_000)
for t in (0.5, 1.5)
    v = ecf(Z, t)
    @assert abs(v - exp(-t * t / 2)) < 0.005       # 实部收敛、虚部 ~0
end
println("normal ecf = e^{-t^2/2} (complex average): OK")

# 均匀 Unif(0,1)：φ = e^{it/2}sinc(t/2)
U = rand(400_000)
for t in (0.8, 2.0)
    v = ecf(U, t)
    h = t / 2
    closed = exp(im * h) * sin(h) / h
    @assert abs(v - closed) < 0.005
end
println("uniform ecf = e^{it/2}sinc(t/2): OK")

# Cauchy：φ = e^{−|t|}（虚部 0，实部慢收敛）
cauchy() = tan(pi * (rand() - 0.5))
C = [cauchy() for _ in 1:400_000]
for t in (0.5, 1.5)
    v = ecf(C, t)
    @assert abs(v - exp(-abs(t))) < 0.01
end
println("cauchy ecf = e^{-|t|} (heavy tail, slow MC): OK")

# ② CLT：指数族的标准化和（N=500）经验 φ vs e^{−t²/2}
N = 500
Zn = [(sum(randexp() for _ in 1:N) - N) / sqrt(N) for _ in 1:100_000]
for t in (0.5, 1.0)
    v = ecf(Zn, t)
    @assert abs(v - exp(-t * t / 2)) < 0.01
end
println("CLT ecf: standardized exp sums -> e^{-t^2/2}: OK")

# ③ Cauchy 稳定 vs 均值发散的 φ 对照：
#    (X+Y)/2 仍 Cauchy（ecf 同 e^{−|t|}）；样本均值 100 个的
#    ecf 尺度不变（无收敛）
Ch = [(cauchy() + cauchy()) / 2 for _ in 1:300_000]
for t in (0.5, 1.5)
    @assert abs(ecf(Ch, t) - exp(-abs(t))) < 0.01   # 同一分布
end
Cbar = [sum(cauchy() for _ in 1:100) / 100 for _ in 1:200_000]
# 平均 100 个的 ecf 仍 Cauchy（φ_{C̄}(t) = e^{−|t|}）：方差无穷的指纹
for t in (0.5, 1.5)
    @assert abs(ecf(Cbar, t) - exp(-abs(t))) < 0.015
end
println("cauchy averaging: mean of 100 still cauchy (no LLN): OK")

# ④ Box-Muller：两个均匀造正态（极坐标技巧的回马枪）
boxmuller() = begin
    u1, u2 = rand(), rand()
    sqrt(-2 * log(u1)) * cos(2 * pi * u2)
end
B = [boxmuller() for _ in 1:400_000]
@assert abs(mean(B)) < 0.005
@assert abs(var(B) - 1) < 0.005
for t in (0.5, 1.5)
    @assert abs(ecf(B, t) - exp(-t * t / 2)) < 0.005   # 特征函数核验
end
println("box-muller: two uniforms -> standard normal (ecf check): OK")

println("END ====")
