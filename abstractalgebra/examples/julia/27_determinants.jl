# 27 行列式：完全展开、公理化与可逆判别
#
# 对应原书 §4.4 前半（英文 3 版 pp. 385-389）。三台机器互相对拍：
#   1. det_perm    完全展开：Σ sgn(σ) ∏ a[σ(i),i]（置换定义——第 08 章 sgn 的重逢）
#   2. det_laplace 余子式展开：按第 1 行递推（Laplace 公式 (3)）
#   3. det_elim    高斯消元：行变换追迹 r 因子，上三角取对角乘积
# 再验证 det(AB) = det(A)det(B)、det(Aᵀ) = det(A)、A·adj(A) = det(A)·I
#（命题 4.86）、ℤ 上可逆 ⟺ det = ±1（推论 4.87）、特征多项式系数（命题 4.93）。

println("==== 27")

# ---------- 置换工具（自带实现，不引依赖） ----------

"""n 元置换的全体：从 [1] 出发，把 k = 2..n 依次插进每个槽位。"""
function permutations(n::Int)
    n == 0 && return Vector{Int}[[]]
    perms = Vector{Int}[[1]]
    for k in 2:n
        nxt = Vector{Vector{Int}}()
        for p in perms, j in 1:length(p)+1
            q = copy(p)
            insert!(q, j, k)
            push!(nxt, q)
        end
        perms = nxt
    end
    return perms
end

@assert length(permutations(3)) == 6 && length(permutations(4)) == 24

"""符号 = (−1)^{逆序数}：对换 σ 一次改变一次符号。"""
sgn_perm(p::Vector{Int})::Int =
    iseven(count(p[j] > p[i] for i in 1:length(p) for j in 1:i-1)) ? 1 : -1

@assert sgn_perm([1, 2, 3]) == 1 && sgn_perm([2, 1, 3]) == -1 && sgn_perm([3, 1, 2]) == 1

# ---------- 1. 完全展开 ----------

function det_perm(A::Matrix{Int})::Rational{Int}
    n = size(A, 1)
    s = 0 // 1
    for p in permutations(n)
        term = 1 // 1
        for col in 1:n
            term *= A[p[col], col]     # 每列恰取一行：第二个下标全不同
        end
        s += sgn_perm(p) * term
    end
    return s
end

# ---------- 2. Laplace 展开（按第 1 行，公式 (3) 的 i = 1） ----------

function minor(A::Matrix{Int}, i::Int, j::Int)::Matrix{Int}
    keep_r = [r for r in 1:size(A, 1) if r != i]
    keep_c = [c for c in 1:size(A, 2) if c != j]
    return A[keep_r, keep_c]
end

function det_laplace(A::Matrix{Int})::Rational{Int}
    n = size(A, 1)
    n == 1 && return A[1, 1] // 1
    s = 0 // 1
    for j in 1:n
        s += (-1)^(1 + j) * A[1, j] * det_laplace(minor(A, 1, j))
    end
    return s
end

# ---------- 3. 高斯消元（行变换三类；因子 r 累乘） ----------

function det_elim(A::Matrix{Int})::Rational{Int}
    n = size(A, 1)
    M = Rational{Int}.(copy(A))
    factor = 1 // 1                    # II 类乘 c，III 类乘 −1，I 类不变
    for col in 1:n
        piv = findfirst(k -> k >= col && M[k, col] != 0, 1:n)
        piv === nothing && return 0 // 1
        if piv != col                  # III 类：换行
            M[[col, piv], :] = M[[piv, col], :]
            factor *= -1
        end
        for r in col+1:n               # I 类：倍加，r 不变
            if M[r, col] != 0
                M[r, :] .-= (M[r, col] // M[col, col]) .* M[col, :]
            end
        end
    end
    return factor * prod(M[i, i] for i in 1:n)   # 上三角 ⟹ 对角乘积
end

# ---------- 三台机器同值互拍 ----------

for trial in 1:40
    n = 2 + (trial % 4)                # 2..5 阶
    A = rand(-6:6, n, n)
    @assert det_perm(A) == det_laplace(A) == det_elim(A)
end
println("完全展开 = Laplace = 高斯消元：40 张随机整数矩阵（2..5 阶）全同值 ✓")

A2 = [1 2; 3 4]                        # 书式锚点：1·4 − 2·3 = −2
@assert det_perm(A2) == -2 && det_laplace(A2) == -2 && det_elim(A2) == -2
println("锚点 det[[1,2;3,4]] = −2（三机器一致）✓")

# ---------- 乘法性与转置不变（式 (1)/(2)） ----------

for trial in 1:20
    n = 2 + (trial % 3)
    A = rand(-5:5, n, n)
    B = rand(-5:5, n, n)
    @assert det_perm(A * B) == det_perm(A) * det_perm(B)
    @assert det_perm(Matrix(transpose(A))) == det_perm(A)
end
println("det(AB) = det(A)det(B) 与 det(Aᵀ) = det(A)：20 组随机对 ✓")

# ---------- 伴随矩阵与命题 4.86 ----------

"""3×3 伴随（c_ji = (−1)^{i+j} det(A_ij)；下标反转是定义的一部分）。"""
function adj3(A::Matrix{Int})::Matrix{Int}
    adj = zeros(Int, 3, 3)
    for i in 1:3, j in 1:3
        adj[j, i] = (-1)^(i + j) * Int(det_laplace(minor(A, i, j)))
    end
    return adj
end

A3 = [2 1 0; 1 3 1; 0 1 2]
adjA = adj3(A3)
d3 = det_perm(A3)                       # = 8
RHS = d3 .* [1 0 0; 0 1 0; 0 0 1]
@assert A3 * adjA == RHS && adjA * A3 == RHS
println("命题 4.86：A·adj(A) = adj(A)·A = det(A)·I = 8·I ✓")

# ---------- ℤ 上可逆 ⟺ det = ±1（推论 4.87 的整数侧） ----------

U2 = [2 1; 1 1]                         # det = 1：逆 [[1,−1],[−1,2]] 仍是整数阵
@assert det_perm(U2) == 1 && U2 * [1 -1; -1 2] == [1 0; 0 1]
@assert det_perm([2 0; 0 1]) == 2       # det = 2：ℤ 上不可逆
println("推论 4.87（ℤ 侧）：det = ±1 ⟹ 整数逆（[[2,1;1,1]] ✓）；det = 2 ⟹ ℤ 上不可逆 ✓")

# ---------- 特征多项式的系数（命题 4.93 的数值面） ----------

"""升幂多项式（c[k] 是 x^{k-1} 的系数），仅供 3×3 特征多项式使用。"""
struct Poly
    c::Vector{Rational{Int}}
end
Base.:+(p::Poly, q::Poly) = Poly([get(p.c, i, 0 // 1) + get(q.c, i, 0 // 1) for i in 1:max(length(p.c), length(q.c))])
Base.:-(p::Poly, q::Poly) = Poly([get(p.c, i, 0 // 1) - get(q.c, i, 0 // 1) for i in 1:max(length(p.c), length(q.c))])
Base.:*(a::Rational{Int}, p::Poly) = Poly(a .* p.c)
function Base.:*(p::Poly, q::Poly)
    c = zeros(Rational{Int}, length(p.c) + length(q.c) - 1)
    for i in 1:length(p.c), j in 1:length(q.c)
        c[i+j-1] += p.c[i] * q.c[j]
    end
    return Poly(c)
end
const X = Poly([0 // 1, 1 // 1])
const Z = Poly([0 // 1])

"""n×n 多项式阵按第 1 行的 Laplace（n ≤ 3 足够本章使用）。"""
function detx(M::Matrix{Poly})::Poly
    n = size(M, 1)
    n == 1 && return M[1, 1]
    s = Z
    for j in 1:n
        keep_r = [r for r in 2:n]
        keep_c = [c for c in 1:n if c != j]
        s = s + ((-1)^(1 + j) // 1) * (M[1, j] * detx(M[keep_r, keep_c]))
    end
    return s
end

charpoly3(A::Matrix{Int}) = detx([(i == j ? X : Z) - Poly([Rational{Int}(A[i, j])]) for i in 1:3, j in 1:3])
tr3(A::Matrix{Int}) = A[1, 1] + A[2, 2] + A[3, 3]
e2_3(A::Matrix{Int}) = (A[1,1]*A[2,2]-A[1,2]*A[2,1]) + (A[1,1]*A[3,3]-A[1,3]*A[3,1]) + (A[2,2]*A[3,3]-A[2,3]*A[3,2])

for A in ([1 2 0; 0 1 3; 0 0 2], [0 1 0; -1 0 0; 0 0 5], A3)
    cp = charpoly3(A)                  # 升幂：[常数, x, x², x³] = [−det, e₂, −tr, 1]
    @assert cp.c[1] == -det_perm(A)
    @assert cp.c[2] == e2_3(A)
    @assert cp.c[3] == -tr3(A)
    @assert cp.c[4] == 1
end
println("命题 4.93 数值面：h_A = x³ − tr·x² + e₂·x − det（三矩阵逐系数 ✓）✓")

R3 = [0 1 0; -1 0 0; 0 0 5]             # det(xI − R) = (x²+1)(x−5) = x³ − 5x² + x − 5
@assert charpoly3(R3).c == [-5 // 1, 1 // 1, -5 // 1, 1 // 1]
println("无实特征值预告：det(xI − R) = x³ − 5x² + x − 5，x²+1 因子（无实根）在 29章开花 ✓")

println("END ====")
