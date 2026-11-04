println("==== 21 bifurcation")

# 第 21 章：分岔——三范式 + Hopf + 滞后。

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

# --- (a) 鞍结：y' = μ - y² ---
# μ > 0：奇点 ±√μ，上稳（f' = -2√μ < 0）下不稳
for mu in [0.1, 0.5, 1.0]
    f(y) = mu - y^2
    # 上奇点稳定：数值从 y = √μ + 0.1 收敛
    yend = integrate((t, u) -> [f(u[1])], [sqrt(mu) + 0.1], 30.0; n = 300000)[1]
    @assert abs(yend - sqrt(mu)) < 1e-4 "上奇点稳定"
    # 下奇点不稳定：从 -√μ + 0.05 出发，位移增长（离开不稳定点）
    y2 = integrate((t, u) -> [f(u[1])], [-sqrt(mu) + 0.05], 3.0; n = 60000)[1]
    @assert y2 > -sqrt(mu) + 0.055 "下奇点不稳定（位移在增长）"
end
# μ < 0 无奇点：解单调下降（灭绝）
yn = integrate((t, u) -> [-0.2 .- u[1] .^ 2], [0.5], 9.0; n = 180000)[1]
@assert yn < -5 || isnan(yn) "μ<0 无奇点：解在 t*≈8.15 爆破到 -∞（y=-a·tan 型）"
println("鞍结：μ>0 两奇点（上稳下不稳），μ<0 无奇点（解单调逃逸）")

# --- (b) 跨临界：y' = μy - y²（奇点 0 与 μ 交换稳定性） ---
for (mu, stableAt) in [(-0.5, 0.0), (0.5, 0.5)]
    yend = integrate((t, u) -> [mu * u[1] - u[1]^2], [stableAt + 0.05], 25.0; n = 250000)[1]
    @assert abs(yend - stableAt) < 1e-4 "稳定奇点在 $(stableAt)"
    # 另一奇点不稳定
    other = (mu == -0.5) ? mu : 0.0
    y2 = integrate((t, u) -> [mu * u[1] - u[1]^2], [other + 0.05], 8.0; n = 160000)[1]
    @assert abs(y2 - other) > 0.15 "另一奇点不稳定（位移增长）"
end
println("跨临界：μ<0 时 y=0 稳 / y=μ 不稳；μ>0 时交换")

# --- (c) 叉式：y' = μy - y³ ---
for mu in [0.5, 1.0, 2.0]
    yend = integrate((t, u) -> [mu * u[1] - u[1]^3], [0.05], 20.0; n = 200000)[1]
    @assert abs(yend - sqrt(mu)) < 1e-3 "对称破缺支 ±√μ"
end
y0 = integrate((t, u) -> [-0.5 .* u[1] .- u[1] .^ 3], [0.05], 25.0; n = 250000)[1]
@assert abs(y0) < 1e-4 "μ<0 时 y=0 稳定"
println("叉式：μ>0 对称破缺 ±√μ（数值贴支），μ<0 唯一稳定 y=0")

# --- (d) Hopf：r' = r(μ - r²)，θ' = 1；μ>0 冒出 √μ 环 ---
for mu in [0.3, 1.0, 2.0]
    # 直角坐标积分
    f = (t, u) -> let r2 = u[1]^2 + u[2]^2
        [u[1] * (mu - r2) - u[2], u[1] + u[2] * (mu - r2)]
    end
    uend = integrate(f, [0.1, 0.1], 60.0; n = 600000)
    r_end = sqrt(uend[1]^2 + uend[2]^2)
    @assert abs(r_end - sqrt(mu)) < 5e-3 "Hopf 环半径 √μ（μ=$mu）"
end
# μ<0：原点稳定（r → 0）
f_neg = (t, u) -> let r2 = u[1]^2 + u[2]^2
    [u[1] * (-0.3 - r2) - u[2], u[1] + u[2] * (-0.3 - r2)]
end
un = integrate(f_neg, [0.3, 0.3], 30.0; n = 300000)
@assert sqrt(un[1]^2 + un[2]^2) < 1e-4 "μ<0 原点渐近稳定"
println("Hopf：μ>0 极限环半径 √μ（三档核对），μ<0 原点稳定")

# --- (e) 环半径标度律：拟合 log r ∝ 0.5 log μ ---
mus = [0.3, 0.5, 1.0, 2.0, 3.0]
rs = Float64[]
for mu in mus
    f = (t, u) -> let r2 = u[1]^2 + u[2]^2
        [u[1] * (mu - r2) - u[2], u[1] + u[2] * (mu - r2)]
    end
    uend = integrate(f, [0.1, 0.1], 60.0; n = 600000)
    push!(rs, sqrt(uend[1]^2 + uend[2]^2))
end
mymean(v) = sum(v) / length(v)
slope = sum((log.(mus) .- mymean(log.(mus))) .* (log.(rs) .- mymean(log.(rs)))) /
        sum((log.(mus) .- mymean(log.(mus))) .^ 2)
@assert abs(slope - 0.5) < 0.02 "标度律 r ∝ μ^{1/2}"
println("标度律：log r 对 log μ 斜率 = ", round(slope; digits=4), "（理论 0.5）")

println("END ====")
