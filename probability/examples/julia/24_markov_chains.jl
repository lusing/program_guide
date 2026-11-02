# -*- coding: utf-8 -*-
println("==== 24 markov_chains")
# 第 24 章 Julia：Markov 链的精确有理数账与遍历定理的蒙特卡洛审计。
using LinearAlgebra, Random, Statistics

const Q = Rational{BigInt}
q(a, b) = Q(a, b)

# 平稳分布：解 (Pᵀ − I) π = 0 且 Σπ=1（把最后一个方程换成归一化）
function stationary(P)
    n = size(P, 1)
    A = Matrix(transpose(P)) - Matrix{Q}(I, n, n)
    A[n, :] .= 1
    b = zeros(Q, n); b[n] = 1
    return A \ b
end

# ① 两状态链
P2 = Q[q(4, 5) q(1, 5); q(3, 10) q(7, 10)]
pi2 = stationary(P2)
@assert pi2 == Q[q(3, 5), q(2, 5)]
@assert transpose(pi2) * P2 == transpose(pi2)
λ2 = 1 - q(1, 5) - q(3, 10)
@assert λ2 == q(1, 2)
Π = [transpose(pi2); transpose(pi2)]
for n in (1, 2, 5, 10)
    @assert P2^n == Π + λ2^n * (Matrix{Q}(I, 2, 2) - Π)
end
@assert P2^7 == P2^3 * P2^4                            # Chapman–Kolmogorov
println("two-state chain: pi=(3/5,2/5), P^n = Pi + (1/2)^n (I-Pi): OK")

# ② 生灭链可逆；三圈链平稳但不可逆
P3 = Q[q(1, 2) q(1, 2) 0; q(1, 4) q(1, 2) q(1, 4); 0 q(1, 2) q(1, 2)]
pi3 = stationary(P3)
@assert pi3 == Q[q(1, 4), q(1, 2), q(1, 4)]
@assert all(pi3[i] * P3[i, j] == pi3[j] * P3[j, i] for i in 1:3, j in 1:3)
cyc = Q[0 q(3, 4) q(1, 4); q(1, 4) 0 q(3, 4); q(3, 4) q(1, 4) 0]
pic = stationary(cyc)
@assert pic == fill(q(1, 3), 3)
@assert any(pic[i] * cyc[i, j] != pic[j] * cyc[j, i] for i in 1:3, j in 1:3)
println("birth-death: detailed balance; 3-cycle: stationary but irreversible: OK")

# ③ 状态分类：可达闭包、通信类、周期
function reach(P)
    n = size(P, 1)
    R = [P[i, j] > 0 || i == j for i in 1:n, j in 1:n]
    for k in 1:n, i in 1:n, j in 1:n
        R[i, j] = R[i, j] || (R[i, k] && R[k, j])
    end
    return R
end
function classes(P)
    R = reach(P); n = size(P, 1); seen = Set{Int}(); out = Vector{Vector{Int}}()
    for i in 1:n
        i in seen && continue
        cl = [j for j in 1:n if R[i, j] && R[j, i]]
        union!(seen, cl); push!(out, cl)
    end
    return out, R
end
function period(P, i; horizon = 40)
    g = 0; M = Matrix{Q}(I, size(P, 1), size(P, 1))
    for n in 1:horizon
        M = M * P
        M[i, i] > 0 && (g = gcd(g, n))
    end
    return g
end
Pc = Q[q(1, 2) q(1, 4) 0 q(1, 4); 0 0 1 0; 0 1 0 0; 0 0 0 1]
cls, R = classes(Pc)
@assert cls == [[1], [2, 3], [4]]
closed = [c for c in cls if all(!R[i, j] || j in c for i in c, j in 1:4)]
@assert closed == [[2, 3], [4]]
@assert period(Pc, 2) == 2 && period(Pc, 4) == 1 && period(P2, 1) == 1
println("classes {1} transient, {2,3} closed period 2, {4} absorbing: OK")

# ④ 赌徒破产：线性方程组 (I − Q_trans) x = b
function ruin(p::Q, N)
    qq = 1 - p
    m = N - 1                                      # 过渡态 1..N-1
    A = zeros(Q, m, m); bh = zeros(Q, m); bt = ones(Q, m)
    for i in 1:m
        A[i, i] = 1
        i + 1 <= m ? (A[i, i + 1] = -p) : (bh[i] += p)     # 上一格；到 N 吸收贡献 1
        i - 1 >= 1 ? (A[i, i - 1] = -qq) : nothing
    end
    return vcat(Q(0), A \ bh, Q(1)), vcat(Q(0), A \ bt, Q(0))
end
h, t = ruin(q(1, 2), 5)
@assert h == [q(i, 5) for i in 0:5]
@assert t == [Q(i * (5 - i)) for i in 0:5]
h, t = ruin(q(2, 3), 5)
ρ = q(1, 2)
@assert all(h[i + 1] == (1 - ρ^i) / (1 - ρ^5) for i in 0:5)
println("gambler's ruin: fair h_i=i/N, t_i=i(N-i); biased closed form: OK")

# ⑤ 5 连正面
S = 6
P5 = zeros(Q, S, S)
for s in 1:5
    P5[s, s + 1] = q(1, 2); P5[s, 1] = q(1, 2)
end
P5[6, 6] = 1
Qt = P5[1:5, 1:5]
Et = (Matrix{Q}(I, 5, 5) - Qt) \ ones(Q, 5)        # 期望首达时间
@assert Et[1] == 62 && Et == [Q(2^6 - 2^s) for s in 1:5]
b = fill(Q(1), 5)                                   # 旧补事件递推 b_0..b_4 = 1
for n in 5:100
    push!(b, sum(b[n - k + 1] / Q(2)^k for k in 1:5))
end
@assert (P5^100)[1, 6] == 1 - b[101]
println("5-run chain: E[T]=62, P(T<=100) = 1 - b_100: OK")

# ⑥ Leslie 矩阵：特征多项式与 Fibonacci 幂
A = [0 2 1 0 0; 1 0 0 0 0; 0 1 0 0 0; 0 0 1 0 0; 0 0 0 1 0]
φ = (1 + sqrt(5)) / 2
@assert abs(φ^2 - φ - 1) < 1e-14
@assert maximum(abs.(eigvals(A))) ≈ φ
Fm = BigInt[1 1; 1 0]
fib = BigInt[0, 1]
for _ in 1:40 push!(fib, fib[end] + fib[end - 1]) end
@assert all((Fm^n)[1, 2] == fib[n + 1] for n in (5, 10, 30))
println("Leslie dominant eigenvalue = phi; Fibonacci matrix powers: OK")

# ⑦ 遍历均值与 iid 的差别：精确渐近方差 18/25 vs iid 6/25；再用模拟审计
g0 = pi2[1] * pi2[2]
σ2 = g0 * (1 + λ2) / (1 - λ2)
@assert σ2 == q(18, 25) && σ2 == 3 * g0
Random.seed!(2411)
function path_mean(n)
    s = 1; cnt = 0
    for _ in 1:n
        cnt += (s == 1)
        r = rand()
        s = s == 1 ? (r < 0.8 ? 1 : 2) : (r < 0.3 ? 1 : 2)
    end
    return cnt / n
end
n = 2000; reps = 2000
means = [path_mean(n) for _ in 1:reps]
emp = n * var(means)
@assert abs(mean(means) - 0.6) < 0.01
@assert abs(emp - 0.72) < 0.12                        # 远离 iid 的 0.24
println("ergodic mean variance n*Var ≈ ", round(emp; digits = 3), " (theory 0.72, iid 0.24): OK")
println("END ====")
