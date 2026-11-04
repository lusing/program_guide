# 第 28 章 · 特征值 —— Julia 通道
#
# 2×2 谱计算 + Fibonacci 幂流水线 + 凯莱–哈密顿 + GF(2) 迁移。

println("==== 28 特征值")

"""2×2 特征多项式 (1, −tr, det)。"""
charpoly2(A) = (1, -(A[1,1] + A[2,2]), A[1,1]*A[2,2] - A[1,2]*A[2,1])

isqrtbi(n) = isqrt(big(n))
"""整数二次 a·x²+b·x+c 的有理根（判别式完全平方）。"""
function rat_roots2(a, b, c)
    D = b * b - 4 * a * c
    D < 0 && return nothing
    s = isqrtbi(D)
    s * s == D || return :irrational
    den = 2 * a
    g = gcd(gcd(-b + s, -b - s), den) |> BigInt
    (BigInt(-b + s) ÷ den, BigInt(-b - s) ÷ den)  # 整除时即有理根
end

# ---------- 谱计算：[[2,1],[1,2]] ----------
A = [2 1; 1 2]
c = charpoly2(A)
@assert c == (1, -4, 3)
roots = rat_roots2(1, -4, 3)
@assert roots == (3, 1)
# 特征向量 (1,−1)/（1,1）
v1 = [1, -1]; v2 = [1, 1]
@assert A * v1 == 1 * v1
@assert A * v2 == 3 * v2
# A^k = P D^k P⁻¹ 的闭式对拍（手写，零依赖）
# 精确整数版：A^k 的闭式 = (3^k + 1)/2 · I + (3^k − 1)/2 · (A − I)
function matpow(A, k)
    R = map(BigInt, A)
    for _ in 2:k; R = R * A; end
    R
end
for k in 1:10
    # 谱分解闭式：A^k = ((3−3ᵏ)/2)·I + ((3ᵏ−1)/2)·A
    Ak = (3 - BigInt(3)^k) ÷ 2 .* [1 0; 0 1] + (BigInt(3)^k - 1) ÷ 2 .* A
    direct = matpow(A, k)
    @assert Ak == direct "k=$k"
end
println("[[2,1],[1,2]]：谱 {1,3}、Aᵏ 闭式（(3ᵏ±1)/2）与直接矩阵幂对拍（k ≤ 10）✓")

# ---------- Fibonacci 幂流水线 ----------
function fib(n)
    a, b = BigInt(0), BigInt(1)
    for _ in 1:n
        a, b = b, a + b
    end
    a
end
F = BigInt[1 1; 1 0]
for k in 1:30
    Fk = matpow(F, k)
    @assert Fk[1, 2] == fib(k)           # F^k 的 (0,1) 分量 = F_k
    @assert Fk[1, 1] == fib(k + 1)       # (0,0) 分量 = F_{k+1}
end
println("Fibonacci：F 矩阵幂的分量 = Fibonacci 数（k ≤ 30 精确对拍）✓")

# ---------- 凯莱–哈密顿（3×3：x³ − tr·x² + s₂·x − det） ----------
using Random
Random.seed!(20261104)
trm(M) = sum(M[i, i] for i in 1:size(M, 1))
for _ in 1:20
    M = rand(-9:9, 3, 3)
    M = map(BigInt, M)
    tr3 = trm(M)
    det3 = map(BigInt, [1 0 0; 0 1 0; 0 0 1])
    # det 按行列式展开（BigInt 精确）
    d3 = M[1,1]*(M[2,2]*M[3,3] - M[2,3]*M[3,2]) - M[1,2]*(M[2,1]*M[3,3] - M[2,3]*M[3,1]) + M[1,3]*(M[2,1]*M[3,2] - M[2,2]*M[3,1])
    s2 = (M[2,2]*M[3,3] - M[2,3]*M[3,2]) + (M[1,1]*M[3,3] - M[1,3]*M[3,1]) + (M[1,1]*M[2,2] - M[1,2]*M[2,1])
    M2 = M * M; M3 = M2 * M
    lhs = M3 - tr3 * M2 + s2 * M - d3 .* M2 .* 0 - d3 .* [BigInt(1) 0 0; 0 1 0; 0 0 1] .+ d3 .* M2 .* 0
    # 干净版：M³ − tr·M² + s₂·M − det·I
    lhs = M3 - tr3 * M2 + s2 * M - d3 .* [BigInt(1) 0 0; 0 1 0; 0 0 1]
    @assert all(iszero, lhs)
end
println("凯莱–哈密顿：随机 3×3 整数矩阵 p_A(A) = 0（20 组精确）✓")

# ---------- GF(2) 迁移 ----------
B = [0 1; 1 1]          # 特征多项式 x² − x − 1（整数系数）
cB = charpoly2(B)
@assert cB == (1, -1, -1)                    # 整数世界
cB2 = (mod(cB[1], 2), mod(cB[2], 2), mod(cB[3], 2))
@assert cB2 == (1, 1, 1)                     # mod 2 后 x² + x + 1
# GF(2) 中 x²+x+1 无根
@assert !(0^2 + 0 + 1 == 0) && !(1^2 + 1 + 1 == 0)
# 但 trace = 1、det = 1 落回 GF(2)
@assert mod(B[1,1] + B[2,2], 2) == 1
@assert mod(B[1,1]*B[2,2] - B[1,2]*B[2,1], 2) == 1
# B³ = I（阶 3——GF(4) 循环群）
B2 = map(x -> mod(x, 2), B * B)
B3 = map(x -> mod(x, 2), B2 * B)
@assert B3 == [1 0; 0 1]
println("GF(2) 迁移：[[0,1],[1,1]] 特征多项式 x²+x+1 在 GF(2) 无根（谱住 GF(4)）；
  trace = det = 1 落回 GF(2)；B³ = I ✓")

println("END ====")
