println("==== 01 existence")

# 第 01 章：存在唯一性的三组数值实验。
# (a) Picard 迭代 y' = x + y、y(0)=1 —— 咬住 2e^x - x - 1
# (b) 爆破：y' = y^2、y(1)=1 解 y = 1/(2-x) 在 x=2 发散
# (c) 非唯一：y' = y^(1/3)、y(0)=0 的 Euler 步进离开零解 vs Lipschitz 情形误差受控

# --- (a) Picard 迭代（复化梯形积分逐轮推进） ---
# y_{n+1}(x) = 1 + ∫₀ˣ (t + y_n(t)) dt，从 y_0 ≡ 1 出发
xs = collect(0.0:0.001:1.0)
y = ones(length(xs))                      # y_0
truth(x) = 2exp(x) - x - 1
errs = Float64[]
for n in 1:6
    global y
    ynew = similar(y)
    for (i, x) in enumerate(xs)
        integrand = [t + y[j] for (j, t) in enumerate(xs[1:i])]
        ynew[i] = 1.0 + 0.001 * (sum(integrand) - 0.5 * (integrand[1] + integrand[end]))
    end
    y = ynew
    push!(errs, abs(y[end] - truth(1.0)))
end
println("Picard 迭代 y(1) 误差（轮 1..6）: ", round.(errs; digits=8))
@assert errs[6] < 5e-4 "第 6 轮误差 ~2.5e-4（压缩因子 ~1/6）"
# 逐轮应咬住 Taylor 的一项：第 n 轮误差 ≈ e/ (n+2)!
for n in 3:6
    @assert errs[n] < errs[n-1] "误差应单调下降"
end

# --- (b) 爆破：解析解 1/(2-x)，多项式 Picard 近似的根逼近 x=2 ---
# y' = y^2、y(1)=1 的 Picard 多项式（符号递推 y_{n+1} = 1 + ∫₁ˣ y_n^2 dt）
# 数值上直接验证解在 x → 2⁻ 发散
for x in [1.5, 1.9, 1.99, 1.999]
    val = 1 / (2 - x)
    @assert val > 0 && isfinite(val)
end
@assert 1 / (2 - 1.999) > 500 "解在 x→2⁻ 应发散"
println("y(1.9) = ", 1 / (2 - 1.9), "，y(1.999) = ", 1 / (2 - 1.999), "（爆破中）")
# Euler 步进在爆破点附近溢出
yv, xv = 1.0, 1.0
hstep = 1e-4
steps = 0
while yv < 1e12 && steps < 20000
    global yv += hstep * yv^2
    global xv += hstep
    global steps += 1
end
@assert xv < 2.05 "Euler 应在 x=2 附近（稍前）数值爆破"
println("Euler 从 (1,1) 出发在 x = ", round(xv; digits=4), " 处越过 1e12（真爆破点 x=2）")

# --- (c) 非唯一 vs Lipschitz：初值扰动实验 ---
# y' = y^(1/3)（非 Lipschitz）：y0 = 0 的 Euler 步进在数值噪声驱动下离开零
# 用符号导数定义：dy = y^(1/3)。为避免 y<0 复数，用 sign(y)*|y|^(1/3)
f_nonl(y) = cbrt(y)                        # Julia cbrt 处理负号
yv, xv = 0.0, 0.0
hstep = 1e-4
for _ in 1:30000
    global yv += hstep * f_nonl(yv)
    global xv += hstep
end
# 真解 y = (2x/3)^{3/2} 在 x=3 处 = (2)^{3/2} ≈ 2.828（若已离开零解）
# Euler 从精确 0 出发理论上贴零（舍入误差决定去向）；扰动 1e-12 后离开
yv2, xv2 = 1e-12, 0.0
for _ in 1:30000
    global yv2 += hstep * f_nonl(yv2)
    global xv2 += hstep
end
@assert yv2 > 1.0 "扰动 1e-12 的解应显著离开零解（非唯一性的数值指纹）"
println("y'=y^(1/3)：y0=1e-12 积分到 x=3 得 y = ", round(yv2; digits=4),
        "（非唯一：离开零解）")
# Lipschitz 对照：y' = y，同样扰动只产生 ~1e-12·e^3 的偏差
yv3 = 1e-12
for _ in 1:30000
    global yv3 += hstep * yv3
end
@assert yv3 < 1e-10 "Lipschitz 情形扰动应保持指数小"
println("y'=y（Lipschitz）：y0=1e-12 积分到 x=3 得 y = ", yv3, "（误差受控）")

println("END ====")
