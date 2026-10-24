# 第 76 章：选择公理与无穷和积不等式（冯琦 §2.1-2.2）——Julia 通道
# 与 76_choice.py 同构：选择函数⇄秩序往返（定理 2.2 有限版）、
# 问题 2.1 裂缝现场、佐恩有限重演（定理 2.4）、柯尼希对角线
# （定理 2.10 第二步）、特征函数双射、基数指数符号求值器
# （定理 2.13 + 豪斯多夫公式，乘积坍缩只用 ZFC 可证的支配关系）。
println("==== 76")

# ---------- 现场一：定理 2.2——选择函数 ⇄ 秩序（有限版） ----------
function wellorder_from_choice(X, c)
    X = Set(X)
    seq = Any[]
    while !isempty(X)
        a = c(Set{Any}(collect(X)))
        push!(seq, a)
        delete!(X, a)
    end
    seq
end

function choice_from_wellorder(order)
    rank = Dict(x => i for (i, x) in enumerate(order))
    A -> sort(collect(A), by = x -> rank[x])[1]
end

X = Set{Any}(["a", "b", "c", "d", "e"])
c0 = A -> sort(collect(A), by = hash)[1]      # "任性"选择函数
wo = wellorder_from_choice(X, c0)
@assert Set{Any}(wo) == X && length(wo) == 5
c1 = choice_from_wellorder(wo)
@assert c1(X) == wo[1]
@assert wellorder_from_choice(X, c1) == wo
println("定理 2.2 往返：任意选择函数 c → 秩序 $(wo) → 新选择函数 → 同一秩序 ✓")

# ---------- 现场二：问题 2.1 的裂缝——∈-极小元不唯一 ----------
a = Set{Any}([Set{Any}([0]), Set{Any}([1])])
minimals = [b for b in a if isempty(intersect(b, a))]
@assert length(minimals) == 2
println("问题 2.1 现场：a = {{0},{1}} 的 ∈-极小元有 2 个——")
println("  “取这一极小元”无典可依；秩序化把“极小”升级为唯一“最小” ✓")

# ---------- 现场三：佐恩 ⟹ 秩序原理的有限重演（定理 2.4 后半） ----------
Y = [0, 1, 2]
function perms(Y, k)                 # 手卷 k-排列（免 Combinatorics 依赖）
    k == 0 && return [Int[]]
    out = Vector{Int}[]
    for (i, y) in enumerate(Y)
        for p in perms(Y[setdiff(1:end, i)], k - 1)
            push!(out, vcat([y], p))
        end
    end
    out
end
function injections(Y)
    out = Vector{Int}[Int[]]
    for k in 1:length(Y)
        append!(out, perms(Y, k))
    end
    out
end
extends(f, g) = length(g) >= length(f) && g[1:length(f)] == f
is_maximal(f, P) = !any(g -> extends(f, g) && g != f, P)
P = injections(Y)
maximals = [f for f in P if is_maximal(f, P)]
@assert all(f -> length(f) == length(Y), maximals)
@assert length(maximals) == 6
chain = [Int[], [0], [0, 2], [0, 2, 1]]
@assert all(i -> extends(chain[i], chain[i + 1]), 1:3)
@assert all(f -> extends(f, chain[end]), chain)
println("佐恩有限重演：16 个有限单射中极大元 6 个，全是满射 ✓")

# ---------- 现场四：柯尼希第二步的对角线（定理 2.10） ----------
function koenig_demo()
    B = [[0, 1], [0, 1]]
    PI = collect(Iterators.product(B...))[:]
    escapes = total = 0
    for picks in Iterators.product([(), (1,), (2,), (3,), (4,)],
                                   [(), (1,), (2,), (3,), (4,)])
        isempty(picks[1]) && isempty(picks[2]) && continue
        total += 1
        Xc = [[PI[j] for j in picks[i]] for i in 1:2]
        A = [[h[i] for h in Xc[i]] for i in 1:2]
        f = Tuple(first(b for b in B[i] if !(b in A[i])) for i in 1:2)
        all(i -> !(f in Xc[i]), 1:2) && (escapes += 1)
    end
    (escapes, total)
end
escapes, total = koenig_demo()
@assert escapes == total
println("柯尼希对角线：Σ(1,1)=2 < Π(2,2)=4；$total 种候选覆盖全被逃逸 ✓")

# ---------- 现场五：特征函数双射（例 2.6(2) 的有限身影） ----------
pairs = [(Set{Int}(k for k in 0:4 if (mask >> k) & 1 == 1),
          Tuple((mask >> k) & 1 for k in 0:4)) for mask in 0:31]
@assert length(pairs) == 32
@assert length(Set(first.(pairs))) == 32 && length(Set(last.(pairs))) == 32
println("2^n = |𝒫(n)|：n=5 时 32 = 32，特征函数双射逐点对拍 ✓")

# ---------- 现场六：基数指数符号求值器（定理 2.13 + 豪斯多夫公式） ----------
struct AK    # aleph 基数
    a::Any   # 非负整数或 :ω
end
struct PK    # 2^λ
    lam::Any
end
struct MK    # 乘积（未坍缩）
    a::Any
    b::Any
end

show_k(k::AK) = "ℵ_$(k.a)"
show_k(k::PK) = "2^{$(show_k(k.lam))}"
show_k(k::MK) = "$(show_k(k.a))·$(show_k(k.b))"

idx_le(a::Int, b::Int) = a <= b
idx_le(::Int, ::Symbol) = true
idx_le(::Symbol, b) = b == :ω
idx_le(k1::AK, k2::AK) = idx_le(k1.a, k2.a)

function cmul(k1, k2)
    k1 isa AK && k2 isa AK && return idx_le(k1, k2) ? k2 : k1
    if k1 isa AK && k2 isa PK && k1.a isa Int && k2.lam.a isa Int && k2.lam.a + 1 >= k1.a
        return k2                      # ℵ_i·2^{ℵ_j} = 2^{ℵ_j}（j+1 ≥ i，ZFC 可证）
    end
    if k2 isa AK && k1 isa PK && k2.a isa Int && k1.lam.a isa Int && k1.lam.a + 1 >= k2.a
        return k1
    end
    MK(k1, k2)
end

function exp_eval(k, lam)
    steps = String[]
    function rec(k, lam, depth)
        ind = "  " ^ depth
        if idx_le(k, lam)
            push!(steps, "$(ind)$(show_k(k))^$(show_k(lam)) = 2^{$(show_k(lam))}（κ≤λ，定理 2.13(1)）")
            return PK(lam)
        end
        if k.a isa Int && k.a > 0
            kp = AK(k.a - 1)
            push!(steps, "$(ind)$(show_k(k))^$(show_k(lam)) = $(show_k(k))·$(show_k(kp))^$(show_k(lam))（豪斯多夫公式，定理 2.12）")
            return cmul(k, rec(kp, lam, depth + 1))
        end
        push!(steps, "$(ind)$(show_k(k))^$(show_k(lam)) = (supₙ ℵ_n^{$(show_k(lam))})^ω（引理 2.7：cf(ℵ_ω)=ω）")
        MK(AK(:sup), k)
    end
    (rec(k, lam, 0), steps)
end

r1, s1 = exp_eval(AK(3), AK(1))
println("指数递推样例一：")
foreach(println, s1)
println("  ⇒ ℵ_3^ℵ₁ = $(show_k(r1))")

r2, s2 = exp_eval(AK(2), AK(3))
println("指数递推样例二：")
foreach(println, s2)
println("  ⇒ ℵ_2^ℵ₃ = $(show_k(r2))")

r3, s3 = exp_eval(AK(:ω), AK(0))
println("指数递推样例三：")
foreach(println, s3)

println("END ====")
