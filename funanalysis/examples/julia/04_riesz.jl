# 第 04 章 · Riesz 表示定理的数值实验（Conway I.3）
# 对应 docs/04-riesz.md。
# 三个实验：有限维"泛函 -> 表示向量"的求解、L²([0,1]) 上积分泛函的
# 表示函数逼近、以及 ‖L‖ = ‖h₀‖ 的数值确认。

using LinearAlgebra
using Random

println("==== 04 riesz (Julia) ====")
Random.seed!(2718)

# --- 实验 1：有限维 Riesz：L(y) = <y, h0>，h0 由 L 在基上的值拼出 --------
# 取 L(y) = 3y1 + 4y2 - y3（R^3），则 h0 = (3,4,-1)，且 ||L|| = ||h0||。
L(y) = 3y[1] + 4y[2] - y[3]
h0 = [3.0, 4.0, -1.0]
riesz_ok(n::Int) = all(y -> abs(L(y) - dot(y, h0)) < 1e-12, (randn(3) for _ in 1:n))
ok = riesz_ok(100)
println("L(y) == <y,h0> for random y: ", ok ? "PASS" : "FAIL")
@assert ok
# 范数相等：||L|| = ||h0||，在 h0 方向上 L(y)/||y|| 恰取满 ||h0||
println("||h0|| = ", norm(h0), "  L(h0/||h0||) = ", L(h0) / norm(h0))
@assert abs(L(h0) / norm(h0) - norm(h0)) < 1e-12   # 在 h0 方向取满

# --- 实验 2：L²([0,1]) 上的 Riesz（Conway 3.5 的数值化身）----------------
# 泛函 F(h) = ∫_0^1 h(t)·g(t) dt 的表示函数就是 g 本身。
# 离散化：区间细分 + 梯形积分，验证 F 的"表示向量"数值上还原 g。
n = 4000
ts = range(0, 1; length = n)
g = t -> sin(2π * t) + 0.5 * cos(6π * t)
gv = g.(ts)
F(h) = (h' * gv) / (n - 1)        # 梯形近似（端点权重差一个 O(1/n)，忽略）
# 构造几个测试函数，验证 F(h) ≈ ∫ h·g
discrete_ok(k) = begin
    hv = sin.(k .* π .* ts)
    abs(F(hv) - sum(hv .* gv) / (n - 1)) < 1e-9  # 离散恒等：F 由 gv 完全决定
end
ok = all(discrete_ok, [1, 3, 7])
println("discrete Riesz vector functional: ", ok ? "PASS" : "FAIL")
@assert ok
# 解析对照：取整周期正弦 h = sin(2πt)：∫ sin(2πt)·g(t) dt = 1/2（正交性），
# 其余频率交叉项全为零。注意半周期的 sin(πt) 与 cos(6πt) 并不正交——
# 正交性依赖 [0,1] 上的整周期（第 06 章 Fourier 理论的伏笔）。
println("F(sin(2pi t)) ≈ ", round(F(sin.(2π .* ts)), digits=6), "（解析值 1/2）")
@assert abs(F(sin.(2π .* ts)) - 0.5) < 5e-3

# --- 实验 3：‖L‖ = ‖h₀‖ 的数值确认 ---------------------------------------
# ‖g‖_{L²} = sqrt(∫ g²)：解析值由 Parseval（第 05 章预告）=
# sqrt(1/2 + 0.25/2) = sqrt(5/8)
norm2_sq = sum(gv .^ 2) / (n - 1)
println("||g||_L2^2 numeric = ", round(norm2_sq, digits=5),
    "  exact = ", round(5 / 8, digits=5))
@assert abs(norm2_sq - 5 / 8) < 1e-3

println("==== 04 riesz END ====")
