println("==== 16 bochner_integral")
using LinearAlgebra: norm
# 第 16 章：ℝ² 值 Bochner 积分的数值复刻。
# ① 分量积分：(x, x²) 在 [0,1] 的积分 = (1/2, 1/3)（中点法）；
# ② 简单函数逼近（加倍控制版阶梯）；
# ③ Bochner-DCT：Xₙ = (xⁿ, 0)，‖Xₙ‖ ≤ (1,1) 可积，积分 → (0,0)；
# ④ 范数判据与三角不等式：‖∫f‖ ≤ ∫‖f‖。

# --- ① 分量积分 ---
K = 200_000
function bochner_mid(f, K)
    s = (0.0, 0.0)
    for i in 1:K
        x = (i - 0.5) / K
        s = s .+ f(x)
    end
    s ./ K
end
f1(x) = (x, x^2)
I1 = bochner_mid(f1, K)
@assert abs(I1[1] - 1/2) < 1e-5 && abs(I1[2] - 1/3) < 1e-5
println("component integrals: (x,x^2) -> (1/2,1/3) via midpoint: OK")

# --- ② 简单函数逼近（8 段阶梯，加倍控制） ---
function step_approx(x, n)
    h = 1 / n
    k = min(floor(Int, x / h), n - 1)
    # 取段中点值（保证 ‖Xₙ‖ ≤ 2‖f‖ 型控制的示意版）
    xm = (k + 0.5) * h
    f1(xm)
end
for n in (8, 64)
    I2 = bochner_mid(x -> step_approx(x, n), K)
    @assert abs(I2[1] - 1/2) < 2 / n + 1e-4
    @assert abs(I2[2] - 1/3) < 2 / n + 1e-4
end
println("simple-function approximation: step integrals converge at grid rate: OK")

# --- ③ Bochner-DCT ---
for n in (2, 10, 50)
    In = bochner_mid(x -> (x^n, 0.0), 50_000)
    @assert abs(In[1] - 1/(n+1)) < 1e-4      # 分量 = 1/(n+1) → 0
    @assert abs(In[2]) < 1e-12
end
println("Bochner-DCT: integrals (1/(n+1), 0) -> (0,0): OK")

# --- ④ 范数判据与三角不等式：‖∫f‖ ≤ ∫‖f‖ ---
mid_scalar(f, K) = sum(f((i - 0.5) / K) for i in 1:K) / K
If = bochner_mid(f1, K)
norm_int = mid_scalar(x -> norm(f1(x)), K)   # ∫√(x²+x⁴) dx
@assert norm(If) <= norm_int + 1e-9          # 三角不等式的积分版
@assert abs(norm(If) - sqrt(13) / 6) < 1e-5  # ‖(1/2,1/3)‖ = √13/6
println("norm criterion: ||int f|| = sqrt(13)/6 <= int ||f|| = ",
        round(norm_int; digits=6), ": OK")

println("END ====")
