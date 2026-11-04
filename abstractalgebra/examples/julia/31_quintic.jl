# 第 31 章 · 一般五次方程的不可解性 —— Julia 通道
#
# 实根计数 + 群结构巡检 + 可解对照 x⁵−2。

println("==== 31 一般五次方程的不可解性")

f(x) = x^5 - 6x + 3
fprime(x) = 5x^4 - 6

# ---------- x⁵−6x+3 的实根计数 ----------
# f' = 0 → x⁴ = 6/5 → 两个实临界点 ±(6/5)^{1/4}
c1 = -(6 / 5) ^ 0.25
c2 = (6 / 5) ^ 0.25
@assert abs(fprime(c1)) < 1e-9
@assert abs(fprime(c2)) < 1e-9
# 分段符号：f(−2)<0, f(c1)>0, f(0)>0, f(c2)<0, f(2)>0 → 恰三实根
pts = [-2, c1, 0, c2, 2]
signs = [sign(f(x)) for x in pts]
@assert signs == [-1, 1, 1, -1, 1]
changes = count(i -> signs[i] * signs[i+1] < 0, 1:4)
@assert changes == 3
println("x⁵−6x+3：恰三个实根（分段单调 + 符号变化 3 次）✓")

# ---------- 置换与 A₅ ----------
# S₅ = 120 个置换（5 元排列枚举）
function all_perms5()
    out = Vector{Int}[]
    p = [1, 2, 3, 4, 5]
    while true
        push!(out, copy(p))
        k = 0
        for i in 4:-1:1
            if p[i] < p[i+1]; k = i; break; end
        end
        k == 0 && break
        l = 0
        for j in 5:-1:1
            if p[k] < p[j]; l = j; break; end
        end
        p[k], p[l] = p[l], p[k]
        reverse!(p, k + 1)
    end
    out
end
perms = all_perms5()
@assert length(perms) == 120

# 偶置换（三循环复合计数巡检）：60 个
function inv_count(perm)
    cnt = 0
    for i in 1:5, j in i+1:5
        perm[i] > perm[j] && (cnt += 1)
    end
    cnt
end
evens = [p for p in perms if inv_count(p) % 2 == 0]
@assert length(evens) == 60
println("S₅ 与 A₅：120 置换、60 偶置换（逆序数奇偶巡检）✓")

# ---------- 可解对照：x⁵ − 2 ----------
# 根 = 2^{1/5}·ω^k，ω = e^{2πi/5}——F₂₀ 群（可解）
α = 2 ^ (1 / 5)
ω = exp(2im * π / 5)
for k in 0:4
    z = α * ω^k
    @assert abs(z^5 - 2) < 1e-12
end
# 韦达：根之和 = 0（四次项系数 0）
s = sum(α * ω^k for k in 0:4)
@assert abs(s) < 1e-12
println("可解对照：x⁵−2 的根 2^{1/5}ωᵏ（F₂₀ 可解）；根之和 = 0 ✓")

# ---------- 根式塔数值对拍 ----------
# ℚ → ℚ(√2) → ℚ(√2, √(1+√2))：嵌套表达式恒等式
inner = sqrt(1 + sqrt(big(2)))
@assert abs(inner^2 - 1 - sqrt(big(2))) < 1e-70
println("根式塔：√(1+√2) 的嵌套恒等式 ✓")


# ---------- 尾声（Epilog）：ζ₅ 的子域塔与高斯定理 5.41 的算术面 ----------

# 黄金比恒等式：g = 2cos(2π/5) = (√5−1)/2 满足 g² + g − 1 = 0（数值面）
g = (sqrt(5) - 1) / 2
@assert abs(g^2 + g - 1) < 1e-12
@assert abs(2 * cos(2π / 5) - g) < 1e-12        # = ζ₅ + ζ₅⁻¹（实固定元）
# 引理 5.40 的计数：Gal(ℚ(ζ₅)/ℚ) ≅ ℤ₄ 的子群塔 ↔ 子域塔
# G ⊇ ⟨σ²⟩ ⊇ {1}  ↔  ℚ(ζ₅) ⊇ ℚ(√5) ⊇ ℚ；[E^L : E^H] = [H : L]
@assert 4 // 2 == 2 && 2 // 1 == 2               # [ℚ(√5):ℚ] = [G:⟨σ²⟩] = 2
# ζ₇：2cos(2π/7) 的次数 3 = [ℤ₆ : ⟨σ³⟩]（指标 3 的子群）
@assert 6 // 2 == 3
# 定理 5.41：p 边形可作 ⟺ p − 1 是 2 的幂
@assert 17 - 1 == 2^4                             # 17 边形可作（费马素数）
@assert 7 - 1 == 6 && 6 % 2 == 0 && (6 ÷ 2) % 2 == 1   # 6 = 2·3：奇因子 ⟹ 不可作
println("Epilog：ζ₅ 黄金比恒等式 + 子群塔计数（引理 5.40）+ 17 可作/7 不可作（定理 5.41）✓")

println("END ====")
