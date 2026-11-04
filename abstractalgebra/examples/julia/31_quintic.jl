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

println("END ====")
