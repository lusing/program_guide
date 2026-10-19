println("==== 24 riesz")
# 第 24 章：泛函→测度的有限版翻译机。
# ① 权泛函 I(f) = Σw·f 与随机 500 个 f 的双向账；
# ② 唯一性：同账权相等；
# ③ 点评价 I(f)=f(1) ⟹ 权 = δ₁；
# ④ Riemann 透视：I = Riemann 积分透视出 Lebesgue（闭式对拍）；
# ⑤ Stieltjes 透视：Heaviside 的 R-S 账 = δ₀。

const W = [3.0, 5.0, 2.0, 1.0, 4.0]   # X = {1..5} 的权

# ① 双向账
If(f) = sum(W[i] * f[i] for i in 1:5)
ok1 = true
for _ in 1:500
    f = rand(5) .* 10 .- 5           # 值域 [-5,5]
    integral_account = sum(W[i] * f[i] for i in 1:5)   # "积分" = 同一账
    abs(If(f) - integral_account) < 1e-12 || (global ok1 = false)
end
@assert ok1
println("functional = weighted sum account on 500 random f: OK")

# ② 唯一性：同账（对一切基向量 e_i）⟹ 权相等
for i in 1:5
    e = zeros(5); e[i] = 1.0
    @assert If(e) == W[i]             # 点评价分离权
end
println("uniqueness: evaluating at basis vectors separates weights: OK")

# ③ 点评价泛函 → dirac
Wd = [0.0, 1.0, 0.0, 0.0, 0.0]
Ifd(f) = sum(Wd[i] * f[i] for i in 1:5)
f = randn(5)
@assert Ifd(f) == f[2]                # I = δ₂ 的评价
println("point evaluation functional = delta_2 weight: OK")

# ④ Riemann 透视：紧支撑连续函数的 Riemann 账 = Lebesgue 闭式
midpoint(f, a, b, n) = begin
    h = (b - a) / n
    s = 0.0
    for k in 0:n-1
        s += f(a + (k + 0.5) * h)
    end
    s * h
end
tests = [(x -> x^2, 1/3, "[0,1] x^2"),
         (x -> exp(x), exp(1) - 1, "[0,1] e^x"),
         (x -> sin(x), 1 - cos(1), "[0,1] sin")]
for (f, closed, name) in tests
    val = midpoint(f, 0.0, 1.0, 10000)
    @assert abs(val - closed) < 1e-6
    println("Riemann透视 Lebesgue ", name, ": |err| < 1e-6")
end

# ⑤ Stieltjes 透视：F = Heaviside（1_{x≥0}），Riemann-Stieltjes 和
#    Σ f(ξᵢ)·(F(xᵢ₊₁)−F(xᵢ))：只有跨 0 的区间贡献 f(ξ)·1 → 收敛到 f(0)
heaviside(x) = x >= 0 ? 1.0 : 0.0
rs_sum(f, a, b, n) = begin
    h = (b - a) / n
    s = 0.0
    for k in 0:n-1
        dF = heaviside(a + (k + 1) * h) - heaviside(a + k * h)
        dF != 0 && (s += f(a + (k + 0.5) * h) * dF)
    end
    s
end
for f in (x -> x^2 + 1, x -> exp(x), x -> 1 + sin(3x))
    v = rs_sum(f, -1.0, 1.0, 2000)
    @assert abs(v - f(0.0)) < 2e-3 * abs(f(0.0)) + 2e-3
end
println("Stieltjes透视 Heaviside R-S sum -> f(0): OK")

println("END ====")
