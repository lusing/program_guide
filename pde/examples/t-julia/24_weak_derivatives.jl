# Ch24 Sobolev 空间 I：弱导数与 Hölder 空间
#
# 对应书 §5.1-5.2：Hölder 空间 C^{k,γ}、弱导数定义（分部积分）、
# W^{k,p} 空间与基本性质。

using Printf

println("==== 24")

# ---- (a) 弱导数的原型：hat 函数 u = (1-|x|)₊ 的弱导数是阶跃 ----
# hat: u = 1-|x| 于 |x|<1；弱导数 v(x) = 1 (x<0), -1 (x>0)
# 分部核对：对任意试验 φ ∈ C_c^∞，∫u φ' = -∫v φ（数值用光滑 φ）
phi_test(x) = exp(-x^2 / 0.1)          # 紧支近似（宽度 0.3）
phi_test_der(x) = phi_test(x) * (-2x / 0.1)
u_hat(x) = max(0.0, 1 - abs(x))
v_step(x) = x < 0 ? 1.0 : -1.0
function integrate(f; L = 3.0, n = 20000)
    h = 2L / n
    s = 0.0
    for k in 0:n
        x = -L + k * h
        w = (k == 0 || k == n) ? 1.0 : (iseven(k) ? 2.0 : 4.0)
        s += w * f(x)
    end
    return s * h / 3
end
lhs = integrate(x -> u_hat(x) * phi_test_der(x))
rhs = -integrate(x -> v_step(x) * phi_test(x))
@printf("(a) weak derivative of hat: ∫uφ' = %.9f  -∫vφ = %.9f  |d| = %.1e\n", lhs, rhs, abs(lhs - rhs))
@assert abs(lhs - rhs) < 2e-3 "分部积分定义核对（φ 截断误差）"
# 对称 φ 使两侧都为 0（空测试）——用平移的非对称 φ 再核一遍
phi2(x) = exp(-(x - 0.2)^2 / 0.1)
phi2d(x) = phi2(x) * (-2(x - 0.2) / 0.1)
lhs1b = integrate(x -> u_hat(x) * phi2d(x))
rhs1b = -integrate(x -> v_step(x) * phi2(x))
@printf("    asymmetric φ: ∫uφ' = %.9f  -∫vφ = %.9f  |d| = %.1e\n", lhs1b, rhs1b, abs(lhs1b - rhs1b))
@assert abs(lhs1b - rhs1b) < 2e-3 "非对称试验函数（非空测试）"

# ---- (b) 弱导数与经典导数一致（光滑函数）----
g(x) = sin(2x) * exp(-x^2)
lhs2 = integrate(x -> g(x) * phi_test_der(x))
gd(x) = 2cos(2x) * exp(-x^2) - 2x * g(x)
rhs2 = -integrate(x -> gd(x) * phi_test(x))
@printf("(b) smooth case: ∫gφ' = %.9f  -∫g'φ = %.9f  |d| = %.1e\n", lhs2, rhs2, abs(lhs2 - rhs2))
@assert abs(lhs2 - rhs2) < 2e-3 "光滑时弱导数 = 经典导数"

# ---- (c) |x| 的弱导数是 sign（偶函数 ⟹ 奇弱导数）----
u2(x) = abs(x)
w2(x) = x < 0 ? -1.0 : 1.0
lhs3 = integrate(x -> u2(x) * phi_test_der(x))
rhs3 = -integrate(x -> w2(x) * phi_test(x))
@printf("(c) d/dx |x| = sign: ∫|x|φ' = %.9f  -∫sign·φ = %.9f\n", lhs3, rhs3)
@assert abs(lhs3 - rhs3) < 2e-3

# ---- (d) Hölder 半范数：[u]_{C^{0,γ}} = sup |u(x)-u(y)|/|x-y|^γ ----
# u = |x|^{1/2} 于 [0,1]：C^{0,1/2}，半范数 = 1（x=0,y→0 饱和）
u_h(x) = sqrt(x)
worst = 0.0
argworst = (0.0, 1.0)
for xi in 0.0:0.001:1.0, yi in 0.0:0.001:1.0
    xi == yi && continue
    r = abs(u_h(xi) - u_h(yi)) / abs(xi - yi)^0.5
    if r > worst
        global worst = r
        global argworst = (xi, yi)
    end
end
@printf("(d) Hoelder C^{0,1/2}: [|x|^{1/2}] = %.6f (theory sup = 1, at x->0 pairs)\n", worst)
@assert worst > 0.999 && worst <= 1.0 + 1e-12 "半范数恰为 1（|x|^a ⟹ [·]_{C^{0,a}}=1）"

println("END ====")
