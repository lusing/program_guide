# 第 32 章 · 西罗定理 —— Julia 通道
#
# 子群枚举（对生成元闭包）验证西罗计数 + 30/40/56 非单性算术 +
# UT(3,F₂) 的阶档案陷阱（同档案不同构）。

println("==== 32 西罗定理")

# ---------- 置换基础设施（列表形 [σ(1),…,σ(n)]） ----------
compose(σ, τ) = [σ[τ[i]] for i in 1:length(τ)]
inverse(σ) = begin
    n = length(σ)
    r = zeros(Int, n)
    for i in 1:n; r[σ[i]] = i; end
    r
end
mulset(S) = Set([compose(a, b) for a in S for b in S])

"""闭包：乘法封闭的极小集（含单位元，集合比较到不动点）。"""
function closure(seed)
    S = Set(vcat(seed, [collect(1:length(seed[1]))]))
    while true
        S2 = union(S, mulset(S))
        S2 == S && return S
        S = S2
    end
end

permgroup(gens) = closure(gens)

"""群的全部子群：单元素与二元生成元的闭包（小群中每个真子群 ≤2 生成）。"""
function subgroups(G)
    E = collect(G)
    subs = Set{Set{Vector{Int}}}()
    for a in E
        push!(subs, closure([a]))
        for b in E
            push!(subs, closure([a, b]))
        end
    end
    subs
end

"""西罗 p-子群的个数（|G| = p^e·m，数阶 p^e 的子群）。"""
function sylow_count(G, gorder, p)
    e = 0
    m = gorder
    while m % p == 0
        m ÷= p; e += 1
    end
    target = p^e
    count(S -> length(S) == target, subgroups(G))
end

# ---------- S₃：n₂ = 3、n₃ = 1 ----------
S3 = permgroup([[2, 1, 3], [2, 3, 1]])          # ⟨(12), (123)⟩
@assert length(S3) == 6
n2 = sylow_count(S3, 6, 2)
n3 = sylow_count(S3, 6, 3)
@assert n2 == 3 && n2 % 2 == 1 && 6 ÷ 2 % n2 == 0   # n₂ ≡ 1 (mod 2)，n₂ | 3
@assert n3 == 1
println("S₃：n₂ = 3 ≡ 1 (mod 2) 且 | 3；n₃ = 1（正规）✓")

# ---------- A₄：n₂ = 1、n₃ = 4 ----------
A4 = permgroup([[2, 1, 4, 3], [2, 3, 1, 4]])    # ⟨(12)(34), (123)⟩
@assert length(A4) == 12
@assert sylow_count(A4, 12, 2) == 1              # V₄ 正规
@assert sylow_count(A4, 12, 3) == 4              # 4 ≡ 1 (mod 3)，4 | 4
println("A₄：n₂ = 1（V₄ 正规）；n₃ = 4 ≡ 1 (mod 3) 且 | 4 ✓")

# ---------- D₄（正方形对称群，8 元）：n₂ = 1 ----------
D4 = permgroup([[2, 3, 4, 1], [2, 1, 4, 3]])    # ⟨r=(1234), s=(13)... 用 (1234),(12)(34)⟩
# 检查群阶
@assert length(D4) == 8
@assert sylow_count(D4, 8, 2) == 1               # 整群即西罗 2-子群
println("D₄：2-群自身即唯一西罗 2-子群 ✓")

# ---------- S₄：n₂ = 3、n₃ = 4 ----------
S4 = permgroup([[2, 1, 3, 4], [2, 3, 4, 1]])
@assert length(S4) == 24
c2 = sylow_count(S4, 24, 2)
c3 = sylow_count(S4, 24, 3)
@assert c2 == 3 && c2 % 2 == 1 && (24 ÷ 8) % c2 == 0
@assert c3 == 4 && c3 % 3 == 1 && (24 ÷ 3) % c3 == 0
println("S₄：n₂ = 3 ≡ 1 (mod 2) 且 | 3；n₃ = 4 ≡ 1 (mod 3) 且 | 4 ✓")

# ---------- 30/40/56：非单性的候选枚举与元素计数 ----------
"""n 的因数中 ≡ 1 (mod p) 者。"""
sylow_candidates(m, p) = [d for d in 1:m if m % d == 0 && d % p == 1]
# 30 = 2·3·5：r₅ | 6 且 ≡ 1 (mod 5) → {1, 6}
@assert sylow_candidates(6, 5) == [1, 6]
# 40 = 2³·5：r₅ | 8 且 ≡ 1 (mod 5) → {1} ⟹ 西罗 5-子群正规
@assert sylow_candidates(8, 5) == [1]
# 56 = 2³·7：r₇ | 8 且 ≡ 1 (mod 7) → {1, 8}
@assert sylow_candidates(8, 7) == [1, 8]
# 56 的元素计数：r₇ = 8 时 8 个 7 阶子群两两交 {e}，非单位元 8·6 = 48 个；
# 加上单位元与一个西罗 2-子群的 7 个非单位元恰 56 —— 再多任何元素即超限
@assert 8 * 6 + 1 + (8 - 1) == 56
@assert 8 * 6 + 1 + (8 - 1) + 1 > 56            # 第二个西罗 2-子群必爆
println("非单性算术：30/40/56 三案的候选枚举 + 56 案元素计数封顶 ✓")

# ---------- UT(3, F₂)：与 D₄ 同阶档案 ----------
# 3×3 单位上三角阵（mod 2）：(I+N)² = I + N²（N³ = 0）
ut3(a, b, c) = [1 a c; 0 1 b; 0 0 1]
ut_mul2(X, Y) = (X * Y) .% 2
UT2 = [ut3(a, b, c) for a in 0:1, b in 0:1, c in 0:1] |> vec
@assert length(UT2) == 8
@assert Set([ut_mul2(X, Y) for X in UT2 for Y in UT2]) == Set(UT2)   # 封闭
@assert ut_mul2(ut3(1,0,0), ut3(0,1,0)) != ut_mul2(ut3(0,1,0), ut3(1,0,0))  # 非交换
# 阶谱：X² = I + N²，只有 ab = 1 的两个元素是 4 阶
mat_order(X, mul, id) = begin
    n, Y = 1, X
    while Y != id
        Y = mul(Y, X); n += 1
    end
    n
end
prof_ut2 = sort([mat_order(X, ut_mul2, ut3(0,0,0)) for X in UT2])
@assert prof_ut2 == [1, 2, 2, 2, 2, 2, 4, 4]
# 与 D₄（置换实现）的阶档案一致——习题 2.123 的 UT(3,F₂) ≅ D₄ 数值面
perm_order(g) = mat_order(g, compose, collect(1:length(g)))
prof_d4 = sort([perm_order(g) for g in D4])
@assert prof_d4 == [1, 2, 2, 2, 2, 2, 4, 4]
println("UT(3,F₂)：8 元封闭非交换、阶谱 {1,2⁵,4²} 与 D₄ 一致（≅ D₄）✓")

# ---------- UT(3, F₃)：同阶档案、不同构（命题 6.29 的数值面） ----------
# p 奇素数时 (I+N)^p = I（二项系数被 p 整除、N³ = 0）⟹ 全部元素 ≤ p 阶
ut_mul3(X, Y) = (X * Y) .% 3
UT3 = [ut3(a, b, c) for a in 0:2, b in 0:2, c in 0:2] |> vec
@assert length(UT3) == 27
@assert Set([ut_mul3(X, Y) for X in UT3 for Y in UT3]) == Set(UT3)
@assert all(mat_order(X, ut_mul3, ut3(0,0,0)) ∈ (1, 3) for X in UT3)
@assert ut_mul3(ut3(1,0,0), ut3(0,1,0)) != ut_mul3(ut3(0,1,0), ut3(1,0,0))
# 阶档案与 (ℤ/3)³ 完全相同：1 + 26 个 3 阶——但 UT 非阿贝尔
@assert sort([mat_order(X, ut_mul3, ut3(0,0,0)) for X in UT3]) ==
        vcat([1], repeat([3], 26))
println("UT(3,F₃)：阶档案 = (ℤ/3)³（1 + 26×3 阶）但非阿贝尔——"
        * "阶档案不是一般群的完全不变量 ✓")

# |GL(2,F₂)| = (4−1)(4−2) = 6、|GL(3,F₂)| = 7·6·4 = 168（定理 6.30）
@assert (2^2 - 1) * (2^2 - 2) == 6
@assert (2^3 - 1) * (2^3 - 2) * (2^3 - 2^2) == 168
println("|GL(2,F₂)| = 6、|GL(3,F₂)| = 168（定理 6.30 公式；UT(3,F₂) 是其西罗 2-子群）✓")

println("END ====")
