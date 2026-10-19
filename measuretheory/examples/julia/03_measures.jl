println("==== 03 measures")

# 第 03 章：测度的可数可加性与连续性的数值验证。
# 取 μ({k}) = 2^{-k}（k=1,2,...）的原子测度，总质量 1。

# 截断到前 N 项的测度计算
mu_atom(k) = 2.0^(-k)
mu_finite(S) = sum(mu_atom(k) for k in S)

# --- 验证 1：总质量（可数可加性的直接读数）---
N = 60
total = sum(mu_atom(k) for k in 1:N)
@assert abs(total - 1.0) < 1e-12 "截断总质量应趋近 1"
println("μ(Ω) 截断到 $N 项 = $(total)，与 1 的差 < 1e-12")

# --- 验证 2：单调性 + 次可加性（随机子集实验）---
using Random
Random.seed!(7)
function subadd_experiment()
    ok_sub = true
    for _ in 1:1000
        A = Set(k for k in 1:30 if rand() < 0.3)
        B = Set(k for k in 1:30 if rand() < 0.3)
        ok_sub &= mu_finite(A) ≤ mu_finite(union(A, B)) + 1e-15
        ok_sub &= mu_finite(union(A, B)) ≤ mu_finite(A) + mu_finite(B) + 1e-15
    end
    ok_sub
end
@assert subadd_experiment() "单调性与次可加性在 1000 次随机实验中全部成立"
println("单调性 + 次可加性：1000 次随机实验全过")

# --- 验证 3：下方连续 Aₙ ↑ A ---
# Aₙ = {1..n}，A = ℕ：μ(Aₙ) → 1
seq = [sum(mu_atom(k) for k in 1:n) for n in 1:60]
@assert abs(seq[60] - 1.0) < 1e-12
println("下方连续：μ({1..n}) ↑ μ(Ω) = 1，第 60 项误差 $(abs(seq[60]-1.0))")

# --- 验证 4：上方连续 Aₙ ↓ ∅（首项有限）---
# Aₙ = {n, n+1, ...}：尾部质量 2^{-(n-1)} → 0
tails = [sum(mu_atom(k) for k in n:10n) for n in [1, 5, 10, 20, 40]]
# 截断到 10n 的解析真值（等比级数部分和）——断言用同口径对照
true_tail(n) = 2.0^(-(n - 1)) - 2.0^(-10 * n)
for (i, n) in enumerate([1, 5, 10, 20, 40])
    @assert abs(tails[i] - true_tail(n)) < 1e-12 "尾部质量应等于截断等比和"
end
println("上方连续：μ({n,n+1,...}) = 2^{-(n-1)} → 0：解析值与数值全部吻合")

# --- 验证 5：非 σ-有限的反面教材——计数测度的连续性不适用 ---
# 计数测度下 μ({n,n+1,...}) = ∞ 不趋于 μ(∅)=0：上方连续需要首项有限
println("对照：计数测度下尾部质量恒为 ∞（首项无限时上方连续失效——σ-有限条件的价值）")

# --- 验证 6：可数可加的结构性实验——偶数集/奇数集 ---
even = sum(mu_atom(k) for k in 2:2:60)
odd = sum(mu_atom(k) for k in 1:2:59)
@assert abs(even - 1/3) < 1e-12 "偶数原子质量和 = 1/3"
@assert abs(odd - 2/3) < 1e-12 "奇数原子质量和 = 2/3"
@assert abs(even + odd - 1.0) < 1e-12
println("不交分解：μ(偶) = $(round(even, digits=6))，μ(奇) = $(round(odd, digits=6))，和恰为 1")

println("END ====")
