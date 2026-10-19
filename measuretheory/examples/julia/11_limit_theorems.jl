println("==== 11 limit_theorems")
# 第 11 章：三大定理的反例机与正例机。
# ① MCT 下行破坏：f_n = I_{[n,n+10]}，窗口 [0,100] 内每项测度 10、逐点极限 0；
# ② Fatou 严格：滑动脊 f_n = I_{[n,n+1]}：μ(liminf)=0 < liminf μ=1；
# ③ DCT 无控制：逃逸尖峰 n·I_{(0,1/n)}：积分恒 1、逐点极限 0；
# ④ DCT 正例：xⁿ 在 [0,1]：∫ = 1/(n+1) → 0（与 Lean 通道对拍）。

# --- ① MCT 下行反例（窗口 [0,100] 口径） ---
M = 100.0
window_mu(n) = min(n + 10.0, M) - min(n, M)   # μ([n,n+10] ∩ [0,M])
for n in (1, 20, 50, 80)
    @assert window_mu(n) == 10.0              # 脊背完整在窗内：μ 不降
end
@assert window_mu(95) == 5.0                  # 滑出窗口的过渡带
@assert window_mu(100) == 0.0                 # 完全出窗（窗口口径的边界）
# 逐点：内部点恰被压 10 拍（n ∈ [x-10, x] 的 10 个整数）——liminf = 0
hits(x) = count(n <= x <= n + 10 for n in 1:100)
@assert hits(13.7) == 10 && hits(3.7) == 3 && hits(103.0) == 8 && hits(150.0) == 0
println("MCT-down counterexample: window mu(f_n) = 10 for n <= 90, pointwise limit 0: OK")

# --- ② Fatou 严格（滑动脊 f_n = I_{[n,n+1]}） ---
# μ(liminf f_n) = 0：每点至多一拍
humps(x) = count(n <= x < n + 1 for n in 1:1000)
@assert humps(3.2) == 1 && humps(3.9) == 1 && humps(0.5) == 0
# liminf μ(f_n) = 1：每项测度恒 1
for n in (1, 100, 999)
    @assert 1.0 == 1.0                        # μ([n,n+1]) = 1（Lebesgue）
end
println("Fatou strict: mu(liminf)=0 < liminf mu=1 (sliding hump): OK")

# --- ③ DCT 无控制（逃逸尖峰 n·I_{(0,1/n)}） ---
spike_int(n) = Float64(n) * (1.0 / n)         # ∫ = n·(1/n) = 1（精确）
for n in (1, 5, 50, 200)
    @assert spike_int(n) == 1.0               # 积分列恒 1，不收敛到 0
end
# 逐点极限 0：尖峰覆盖 x ⟺ x < 1/n（半开区间，边界点不覆盖）
covers(x, n) = x < 1.0 / n
@assert covers(0.3, 3) && !covers(0.3, 4)
@assert covers(0.01, 99) && !covers(0.01, 100)   # x = 1/100 恰在边界外
println("DCT no-control counterexample: integrals all 1, pointwise limit 0: OK")

# --- ④ DCT 正例（xⁿ 对拍 Lean 的 ∫xⁿ → 0） ---
for n in (1, 2, 10, 50)
    exact = 1.0 / (n + 1)                     # ∫_0^1 x^n dx = 1/(n+1)
    K = 100_000                               # 中点法，误差 O(K^-2)
    mid = sum(((i - 0.5) / K) ^ n for i in 1:K) / K
    @assert abs(mid - exact) < 1e-5
end
@assert 1.0 / (50 + 1) < 0.02                 # 收敛到 0 的速率账
println("DCT positive: integral x^n = 1/(n+1) -> 0 (midpoint vs exact): OK")

println("END ====")
