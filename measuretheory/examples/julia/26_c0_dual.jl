println("==== 26 c0_dual")
# 第 26 章：符号泛函的 Jordan 拼装与保范账。
# ① 符号权的 Jordan 分解（逐点正负部）与 |ν| 账；
# ② 保范：‖Λ‖ = Σ|νᵢ|，达范向量 sign(ν)；
# ③ 密度情形：g = x − 1/2 的 ∫f g dλ 与闭式对拍；‖Λ‖ = ∫|g| = 1/4；
# ④ δ₀ − δ₁ 的对偶词典条目。

const V = [2.0, -3.0, 0.0, 1.5, -0.5]    # 符号权（X = {1..5}）

# ① Jordan 分解
Vpos = max.(V, 0.0)
Vneg = max.(-V, 0.0)
@assert Vpos - Vneg == V                    # Λ = Λ⁺ − Λ⁻
totvar = sum(abs.(V))
@assert sum(Vpos) + sum(Vneg) == totvar     # |ν| = ν⁺ + ν⁻
println("Jordan: nu+ - nu- = nu, |nu| = nu+ + nu- = ", totvar)

# ② 保范与达范
fstar = sign.(V)                            # 有限维达范向量
@assert abs(sum(V .* fstar)) == totvar      # |Λ(f*)| = ‖Λ‖
@assert maximum(abs.(fstar)) == 1.0         # f* 在单位球内
println("norm identity: |Lambda(f*)| = ||Lambda|| = ", totvar)

# ③ 密度情形：[0,1] 上 g(x) = x - 1/2
g(x) = x - 0.5
Lf(f, n) = begin                            # Λ(f) = ∫ f g dλ（中点积分）
    h = 1.0 / n; s = 0.0
    for k in 0:n-1
        s += f((k + 0.5) * h) * g((k + 0.5) * h)
    end
    s * h
end
# 测试：f(x) = x → ∫x(x−1/2) = 1/3 − 1/4 = 1/12
@assert abs(Lf(x -> x, 40000) - 1 / 12) < 1e-6
# 测试：f = 1 → ∫(x−1/2) = 0
@assert abs(Lf(x -> 1.0, 40000)) < 1e-6
# ‖Λ‖ = ∫|g| = 1/4（精确；单独积分 |g| 而非 f·g）
ng(n) = begin h = 1.0/n; s = 0.0
    for k in 0:n-1; s += abs(g((k+0.5)*h)); end
    s * h end
@assert abs(ng(40000) - 0.25) < 1e-6
println("density case: closed forms 1/12, 0, and norm = 1/4: OK")

# ④ 原子词典：δ₀ − δ₁
d01(f) = f(0.0) - f(1.0)
@assert d01(x -> x^2) == -1.0
@assert d01(x -> exp(x)) == -exp(1.0) + 1.0
totvar_d01 = 2.0                            # |δ₀ − δ₁| = δ₀ + δ₁
@assert abs(d01(x -> 1 - 2x)) == 2.0 == totvar_d01   # 连续达范：f(0)=1, f(1)=-1
println("atom dictionary: delta_0 - delta_1 entries: OK")

println("END ====")
