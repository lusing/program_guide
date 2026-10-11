# 第 06 章 · 同构分类、圆周 Fourier 变换与直和的数值实验（Conway I.5-6）
# 对应 docs/06-fourier-sums.md。
# 四个实验：单侧移位的等距性（5.3）、DFT 作为 L² 同构（5.11 的离散化身）、
# Parseval 能量守恒（5.10 离散版）、两个空间的 ℓ² 直和（6.1-6.2）。

using LinearAlgebra
using FFTW
using Random

println("==== 06 fourier-sums (Julia) ====")
Random.seed!(606)

# --- 实验 1：单侧移位 S 是等距但不满（Conway 5.3 + II.2.10 预告）----------
# S(α₁,α₂,...) = (0,α₁,α₂,...)：保范数；S* 是后移（左移）
α = randn(50)
Sα = [0.0; α]
println("shift isometry: ‖Sα‖ = ", round(norm(Sα), digits=10),
    " = ‖α‖ = ", round(norm(α), digits=10))
@assert abs(norm(Sα) - norm(α)) < 1e-12
# S*S = I 但 SS* ≠ I（第 08 章的代数预演）
SstarSα = Sα[2:end]          # S*(Sα) = α
SSstarα = [0.0; α[1:end-1]]  # S(S*α) = (0, α₁, ..., α₄₈) ≠ α
@assert norm(SstarSα - α) < 1e-12
@assert norm(SSstarα - α) > 0.1

# --- 实验 2：DFT 是 L² 的等距同构（Conway 5.11 的离散化身）------------------
# 圆周上的 Fourier 变换在离散格点上就是 DFT：‖DFT x‖ = √n·‖x‖（约定依赖）
n = 128
x = randn(n) + im * randn(n)
Fx = fft(x)
ratio = norm(Fx) / (sqrt(n) * norm(x))
println("DFT isometry ratio = ", round(ratio, digits=10))
@assert abs(ratio - 1.0) < 1e-10
# 满射：逆变换恢复
@assert norm(ifft(Fx) - x) < 1e-10

# --- 实验 3：Parseval 能量守恒（Conway 5.10 离散版）-------------------------
# ‖f‖² = (1/n)·Σ|f̂(k)|² —— Fourier 系数携带全部能量
energy_time = norm(x)^2
energy_freq = norm(Fx)^2 / n
println("energy: time = ", round(energy_time, digits=6),
    "  freq = ", round(energy_freq, digits=6))
@assert abs(energy_time - energy_freq) < 1e-8

# --- 实验 4：Hilbert 直和（Conway 6.1-6.2）----------------------------------
# (x,y) ⊕ (x',y') 的范数 = √(‖x‖²+‖y‖²)：勾股形式
w1, w2 = randn(6), randn(6)
normsum = norm([w1; w2])
expect = sqrt(norm(w1)^2 + norm(w2)^2)
println("direct-sum norm = ", round(normsum, digits=10),
    "  √(‖w1‖²+‖w2‖²) = ", round(expect, digits=10))
@assert abs(normsum - expect) < 1e-12

println("==== 06 fourier-sums END ====")
