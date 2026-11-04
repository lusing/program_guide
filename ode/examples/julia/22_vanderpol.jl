println("==== 22 vanderpol")

# 第 22 章：van der Pol 极限环——贴环、振幅律、周期律、能量账、环域。

function rk4vec(f, t, u, h)
    k1 = f(t, u)
    k2 = f(t + h / 2, u .+ h .* k1 ./ 2)
    k3 = f(t + h / 2, u .+ h .* k2 ./ 2)
    k4 = f(t + h, u .+ h .* k3)
    u .+ h .* (k1 .+ 2 .* k2 .+ 2 .* k3 .+ k4) ./ 6
end
integrate(f, u0, T; n = 24000) = begin
    h = T / n
    t, u = 0.0, copy(u0)
    for _ in 1:n
        u = rk4vec(f, t, u, h)
        t += h
    end
    u
end

vdp(mu) = (t, u) -> [u[2], mu * (1 - u[1]^2) * u[2] - u[1]]

# --- (a) 内外初值都贴环：μ = 1（相位不同，比较贴环后的包络 max|x|） ---
mu = 1.0
f = vdp(mu)
function envelope_xmax(f, u0)
    u = copy(u0)
    t = 0.0
    h = 0.005
    xmax = 0.0
    for _ in 1:24000          # t = 120，后半段统计
        u = rk4vec(f, t, u, h)
        t += h
        t > 60 && (xmax = max(xmax, abs(u[1])))
    end
    xmax
end
xin = envelope_xmax(f, [0.1, 0.0])
xout = envelope_xmax(f, [5.0, 5.0])
@assert abs(xin - xout) < 0.02 "内外轨道收敛到同一极限环（包络一致）"
@assert abs(xin - 2.0) < 0.15 "环的 x 包络 ≈ 2"
println("贴环：内外初值的包络 max|x| = ", round(xin; digits=4), " / ", round(xout; digits=4), "（同一环）")

# --- (b) 振幅律：μ 小时 max|x| ≈ 2 ---
for mu in [0.2, 1.0, 2.0]
    xmax = envelope_xmax(vdp(mu), [1.0, 0.0])
    @assert abs(xmax - 2.0) < 0.25 "振幅 ≈ 2（谐波平衡），μ=$(mu) 得 $xmax"
end
println("振幅律：μ ∈ {0.2, 1, 2} 的 max|x| ≈ 2（谐波平衡预言）")

# --- (c) 周期律：T(μ)/μ → 3 − 2ln2 ≈ 1.614（大 μ 张弛） ---
function vdp_period(mu)
    f = vdp(mu)
    u = [1.0, 0.0]
    t = 0.0
    h = 0.005
    peaks = Float64[]
    prevx, prevprevx = u[1], 0.0
    for _ in 1:400000        # t = 2000
        u = rk4vec(f, t, u, h)
        t += h
        if prevprevx < prevx > u[1] && prevx > 1.0 && t > 200
            push!(peaks, t)
            length(peaks) >= 4 && break
        end
        prevprevx = prevx
        prevx = u[1]
    end
    (peaks[end] - peaks[1]) / (length(peaks) - 1)
end
ratio_prev = 0.0
for mu in [10.0, 20.0]
    Tper = vdp_period(mu)
    ratio = Tper / mu
    # 渐近值 3−2ln2 = 1.614；μ=10 时修正项仍显著（文献值 T(10)≈19.08 ⟹ 1.908）
    @assert 1.5 < ratio < 2.0 "张弛周期量级, mu=$(mu)"
    if ratio_prev > 0
        @assert ratio < ratio_prev "T/μ 随 μ 增大下降（趋向 3−2ln2 = 1.614）"
    end
    global ratio_prev = ratio
    println("周期律：μ = $(mu)，T/μ = ", round(ratio; digits=4), "（趋向 3−2ln2 = ", round(3 - 2 * log(2); digits=4), "）")
end

# --- (d) 能量账：x ≈ 2cos t 的 ∮μ(1−x²)y²dt ≈ 0 ---
mu = 1.0
xc(t) = 2 * cos(t)
yc(t) = -2 * sin(t)
integrand(t) = mu * (1 - xc(t)^2) * yc(t)^2
# 周期 2π 数值梯形
n = 20000
h = 2pi / n
Iv = 0.0
for k in 0:n
    w = (k == 0 || k == n) ? 0.5 : 1.0
    global Iv += w * integrand(k * h) * h
end
@assert abs(Iv) < 0.05 "谐波平衡：一个周期净能量 ≈ 0（实际 $(Iv)）"
println("能量账：∮μ(1−x²)y²dt = ", round(Iv; digits=4), "（谐波平衡 x ≈ 2cos t 净能 ≈ 0）")

# --- (e) Poincaré–Bendixson 的 vdp 素材账 ---
# 恒等式：r·r' = x·x' + y·y' = μ(1−x²)y²（|x|<1 注能、|x|>1 耗能——
# 负阻尼机制的极坐标表述）。核对恒等式 + 轨道有界 ⟹ 紧集存在。
f = vdp(1.0)
for r in [0.5, 1.0, 1.8, 2.5]
    for k in 0:7
        th = k * pi / 4
        p = [r * cos(th), r * sin(th)]
        fv = f(0.0, p)
        lhs = p[1] * fv[1] + p[2] * fv[2]
        rhs = 1.0 * (1 - p[1]^2) * p[2]^2
        @assert abs(lhs - rhs) < 1e-12 "恒等式 r·r' = μ(1−x²)y²"
    end
end
println("恒等式：x·x' + y·y' = μ(1−x²)y²（32 点核对）——|x|<1 注能、|x|>1 耗能")
# 有界性：长轨道的 r 有上界（轨道被吸入紧集）
u = [0.1, 0.1]
t = 0.0
h = 0.01
rmax = 0.0
rmin_late = Inf
for _ in 1:30000
    global u = rk4vec(f, t, u, h)
    global t += h
    rnow = sqrt(u[1]^2 + u[2]^2)
    global rmax = max(rmax, rnow)
    t > 100 && (global rmin_late = min(rmin_late, rnow))
end
@assert rmax < 3.0 "轨道有界（μ=1 环的极径上界 ≈ 2.83）"
@assert rmin_late > 0.5 "轨道不缩回原点（原点排斥）"
println("Poincaré–Bendixson 素材：r_max = ", round(rmax; digits=4), "（有界）",
        "，晚期 r_min = ", round(rmin_late; digits=4), "（不回原点）",
        " ⟹ 紧集内无稳定平衡 ⟹ 极限环存在")

println("END ====")
