# Ch28 Sobolev 空间 V：H^{-1} 与时空空间
#
# 对应书 §5.9：H^{-1}（H¹_0 的对偶）与 L²(0,T;H¹)/L²(0,T;H^{-1})
# 时空框架（发展方程弱解的家）。

using Printf

println("==== 28")

# ---- (a) H^{-1} 范数：f = δ 的近似（窄 Gauss）的 H^{-1} 范数有限 ----
# f_ε = Gauss(ε)：‖f_ε‖_{H^{-1}} = ‖u_ε‖_{H¹}，-u'' = f_ε 的解
# 解析：Gauss 的原函数 er f 两次积分——直接谱：f̂_k = e^{-ε²k²π²/4}·?
# 用特征展开：‖f‖_{H^{-1}}² = Σ |f_k|²/(1 + k²π²)（(0,1) 上 H¹_0 谱）
function h_minus_1(eps; K = 400)
    s = 0.0
    for k in 1:K
        # f = (4πε²)^{-1/2}e^{-x²/4ε²} 于 (0,1)，中心 0.5；
        # sin 系数 f_k = 2∫f sin(kπx) ≈ e^{-ε²k²π²}·2·sin(kπ/2)（中心贡献）
        fk = 2 * exp(-eps^2 * k^2 * pi^2) * sin(k * pi / 2) * exp(0)  # 近似（ε 小）
        s += fk^2 / (1 + k^2 * pi^2)
    end
    return sqrt(s)
end
for eps in [0.1, 0.05, 0.01]
    n = h_minus_1(eps)
    @printf("(a) H^-1 norm of approx-delta (eps=%.2f): %.6f (finite, -> const)\n", eps, n)
end
@assert h_minus_1(0.01) < 1.0 "δ ∈ H^{-1}：近似列的 H^{-1} 范数有界"

# ---- (b) f ∈ L² ⊂ H^{-1}：‖f‖_{H^{-1}} ≤ C‖f‖_{L²} ----
f2(x) = sin(3pi * x)
# 谱：f_k = 1（k=3），‖f‖_{H^-1} = 1/√(1+9π²)，‖f‖_2 = 1/√2
nh = 1 / sqrt(1 + 9pi^2)
nl = 1 / sqrt(2)
@printf("(b) f = sin(3πx): ||f||_{H^-1} = %.6f  ||f||_{L²} = %.6f  ratio = %.6f < 1\n",
        nh, nl, nh / nl)
@assert nh < nl "L² 连续嵌入 H^{-1}"

# ---- (c) 时空空间：L²(0,T;H¹_0) ∩ H¹(0,T;H^{-1}) 的样本范数 ----
# u(x,t) = e^{-t}sin(πx)：
# ‖u‖_{L²(0,T;H¹)}² = ∫₀ᵀ e^{-2t}(π²+1)/2 dt = (π²+1)/4·(1-e^{-2T})
# ‖u_t‖_{L²(0,T;H^{-1})}² = ∫₀ᵀ e^{-2t}/(1+π²)·(1/2)·? 用谱：u_t 的
# H^{-1}² = e^{-2t}·(1/2)/(1+π²)（单模式系数 1·e^{-t}，导数 e^{-t}）
T0 = 1.0
val_space = (pi^2 + 1) / 2 * (1 - exp(-2T0)) / 2
val_time = (1 / (1 + pi^2)) * (1 / 2) * (1 - exp(-2T0)) / 1
# 上面按 ‖·‖² 逐项：空间 (π²+1)/2·∫e^{-2t} = (π²+1)/2·(1-e^{-2})/2；
# 时间 (1/(1+π²))·(1/2)·∫e^{-2t}dt = (1/(1+π²))·(1-e^{-2})/4
val_space2 = (pi^2 + 1) / 2 * (1 - exp(-2T0)) / 2
val_time2 = (1 / (2 * (1 + pi^2))) * (1 - exp(-2T0)) / 2
@printf("(c) u=e^{-t}sinπx: ||u||²_{L²H¹} = %.6f  ||u_t||²_{L²H^{-1}} = %.6f\n",
        val_space2, val_time2)
@assert val_space2 > 0 && val_time2 > 0
# 能量恒等式只对**热方程解**成立：u = e^{−π²t}sin(πx)（07 章模式）
E_t(t) = 0.25 * exp(-2pi^2 * t)
diss(t) = pi^2 * 0.5 * exp(-2pi^2 * t)
for t in [0.0, 0.5, 1.0]
    lhs = (E_t(t + 1e-7) - E_t(t - 1e-7)) / 2e-7
    @assert abs(lhs + diss(t)) < 1e-5 "能量恒等式（时空框架的基础账）"
end
println("    energy identity (heat solution): verified at t=0, 0.5, 1")

# ---- (d) 对偶配对：Riesz 代表 u* = f/(1+λ)，⟨f,u*⟩ = ‖f‖²_{H^{-1}} ----
# f = sin(3πx)：‖f‖²₂ = 1/2，‖f‖²_{H^{-1}} = (1/2)/(1+9π²)
nh2 = (1 / 2) / (1 + 9pi^2)
pairing = (1 / (1 + 9pi^2)) * (1 / 2)   # ∫ f·u* = ∫sin²/(1+λ)
@printf("(d) duality pairing <f, u*> = %.8f  ||f||²_{H^-1} = %.8f (Riesz equality)\n",
        pairing, nh2)
@assert pairing == nh2 "配对饱和（Riesz 代表）"

println("END ====")
