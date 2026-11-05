# 02_fourier.jl —— 第 02 章：Fourier 变换与复数矩阵（Julia 通道）
#
# 采用与书一致的对称约定：
#   û(k) = (1/√(2π)) ∫ u(x) e^{-ikx} dx,   u(x) = (1/√(2π)) ∫ û(k) e^{ikx} dk.
#   (1) 热核高斯变换对：u = e^{-x²} ⟺ û = e^{-k²/4}/√2，数值积分核对；
#   (2) 导数性质 F[u'] = ik·û(k)；
#   (3) Parseval：∫|u|² = ∫|û|²；
#   (4) 复矩阵：正规矩阵 ‖A‖₂ = ρ(A)，非正规（Jordan 块）严格大于——
#       Richardson 格式不稳定的矩阵机理预告；
#   (5) Hermite 矩阵的酉对角化（定理 3.2 的具体实例）。

println("==== 02 fourier")
using LinearAlgebra

# ---------- 数值积分底座 ----------
function simpson(f, a, b, n)
    h = (b - a) / n
    s = f(a) + f(b)
    for i in 1:n-1
        s += (i % 2 == 1 ? 4 : 2) * f(a + i * h)
    end
    s * h / 3
end

# ---------- (1) 高斯变换对 ----------
L, n = 8.0, 4000
u(x) = exp(-x^2)
uhat(k) = exp(-k^2 / 4) / sqrt(2.0)   # 闭式：(1/√2π)·√π e^{-k²/4}
for k in (0.0, 0.5, 1.0, 2.0)
    # 实部：∫u cos；虚部：−∫u sin（u 偶函数，虚部严格为 0）
    re = simpson(x -> u(x) * cos(k * x), -L, L, n) / sqrt(2π)
    @assert abs(re - uhat(k)) < 1.0e-8
    im_ = simpson(x -> -u(x) * sin(k * x), -L, L, n) / sqrt(2π)
    @assert abs(im_) < 1.0e-12
end
println("gauss pair: numeric FT of exp(-x^2) matches exp(-k^2/4)/sqrt(2) to 1e-8")

# 逆变换在 x0 处还原 u(x0)（k 积分的被积函数衰减慢，截断取 L2=10）
x0 = 0.7
inv = simpson(k -> uhat(k) * cos(k * x0), -10.0, 10.0, 5000) / sqrt(2π)
@assert abs(inv - u(x0)) < 1.0e-8
println("inverse FT at x0 = 0.7 recovers u(x0) to 1e-8")

# ---------- (2) 导数性质 F[u'] = ik û(k) ----------
dup(x) = -2x * exp(-x^2)
for k in (0.3, 1.0, 2.5)
    lhs_re = simpson(x -> dup(x) * cos(k * x), -L, L, n) / sqrt(2π)   # 奇函数积分为 0
    lhs_im = simpson(x -> -dup(x) * sin(k * x), -L, L, n) / sqrt(2π)
    rhs_re = -k * (simpson(x -> -u(x) * sin(k * x), -L, L, n) / sqrt(2π))  # ik·(a+ib) = -kb + ika
    rhs_im = k * (simpson(x -> u(x) * cos(k * x), -L, L, n) / sqrt(2π))
    @assert abs(lhs_re) < 1.0e-12
    @assert abs(lhs_re - rhs_re) < 1.0e-8
    @assert abs(lhs_im - rhs_im) < 1.0e-8
end
println("derivative rule: Re F[u'](k) = -k Im(uhat), Im F[u'](k) = k Re(uhat)")

# ---------- (3) Parseval ----------
lhs = simpson(x -> u(x)^2, -L, L, n)
rhs = simpson(k -> uhat(k)^2, -L, L, n)
@assert abs(lhs - rhs) < 1.0e-8
@assert abs(lhs - sqrt(π / 2)) < 1.0e-8   # ∫e^{-2x²}dx = √(π/2)
println("Parseval: int|u|^2 = int|uhat|^2 = sqrt(pi/2) = ", round(lhs, digits=6))

# ---------- (4) 正规矩阵 ‖A‖₂ = ρ(A)，非正规严格大于 ----------
A_jordan = [1.0 1.0; 0.0 1.0]                # 非正规
R_rot = [cos(0.7) -sin(0.7); sin(0.7) cos(0.7)]  # 酉（正规）
S_sym = [2.0 1.0; 1.0 2.0]                    # 实对称（Hermite，正规）

for (name, M) in (("rotation(unitary)", R_rot), ("symmetric(hermite)", S_sym))
    nrm = opnorm(M, 2)
    rho = maximum(abs, eigvals(M))
    @assert abs(nrm - rho) < 1.0e-12 "正规矩阵应满足 ‖A‖=ρ(A)（$name）"
    println(name, ": ||A||_2 = ", round(nrm, digits=6), " = rho(A)")
end
nj = opnorm(A_jordan, 2)
rhoj = maximum(abs, eigvals(A_jordan))
@assert nj > rhoj + 0.5 "Jordan 块应严格 ‖A‖>ρ(A)"
println("jordan(not normal): ||A||_2 = ", round(nj, digits=6), " > rho(A) = ", rhoj)

# Richardson 增长矩阵 G = [[-8rs, 1], [1, 0]]（r aλ, s = sin²(θ/2)）：
# 特征值 -4rs ± sqrt(16 r²s² + 1)，其中一支模恒 > 1
for r in (0.2, 0.5, 0.49), s in (0.1, 0.5, 1.0)
    G = [-8r * s 1.0; 1.0 0.0]
    mu = eigvals(G)
    @assert maximum(abs, mu) > 1.0 + 1.0e-12 "Richardson 增长矩阵恒有一支特征值超界"
end
println("Richardson growth matrix: max|eig| > 1 for every r,s (always unstable)")

# ---------- (5) Hermite 矩阵酉对角化（定理 3.2） ----------
U = 1 / sqrt(2) * [1.0 1.0; 1.0 -1.0]
@assert norm(U' * S_sym * U - Diagonal([3.0, 1.0])) < 1.0e-14
@assert norm(U' * U - I) < 1.0e-14
println("hermite S = [2 1; 1 2]: U^H S U = diag(3, 1), U unitary (Hadamard)")

println("END ====")
