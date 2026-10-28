# 第 96 章：覆盖数的精确计算、不可覆盖点与定向并闭包。
println("==== 96")

function combos(v, k)
    k == 0 && return [eltype(v)[]]
    isempty(v) && return eltype(v)[]
    a = v[1]
    vcat([[a; c] for c in combos(v[2:end], k - 1)], combos(v[2:end], k))
end

ALLSETS = Vector{Set{Int}}()
for mask in 0:(1 << 6) - 1
    push!(ALLSETS, Set(i - 1 for i in 1:6 if (mask >> (i - 1)) & 1 == 1))
end

# (a) F_b = 大小 ≤ b 的子集族；对每个 X 计算 min 覆盖片数；
#     断言恰为 ceil(|X|/b)（slack 覆盖总可实现的最优账）。
function min_cover(X, family)
    isempty(X) && return 0
    members = [Y for Y in family if !isempty(Y)]
    X ⊆ union(members...) || return typemax(Int)
    for k in 1:length(members)
        for combo in combos(members, k)
            if X ⊆ union(combo...)
                return k
            end
        end
    end
    return typemax(Int)
end

for b in 1:3
    Fb = [Y for Y in ALLSETS if length(Y) <= b]
    for X in ALLSETS
        want = isempty(X) ? 0 : cld(length(X), b)
        @assert min_cover(X, Fb) == want
    end
end

# (b) 缺含 0 的成员族：任何含 0 的 X 完全不可覆盖
#     （逆命题 X = ω₁ ∪ {ιₙ} 的影子）。
Fno0 = [Y for Y in ALLSETS if !(0 in Y)]
@assert min_cover(Set([0, 1]), Fno0) == typemax(Int)
@assert min_cover(Set([0]), Fno0) == typemax(Int)
@assert min_cover(Set([1, 2]), Fno0) == 1

# (c) 定向并闭包：单点族经「并任意两成员」迭代封闭到全域幂集；
#     缺 0 的单点族闭包永远不含 0。
function directed_closure(seed)
    F = Set{Set{Int}}(seed)
    changed = true
    while changed
        changed = false
        current = collect(F)
        for Y in current, Z in current
            u = union(Y, Z)
            if !(u in F)
                push!(F, u)
                changed = true
            end
        end
    end
    return F
end

cl = directed_closure([Set{Int}(); [Set([i]) for i in 0:5]])
@assert length(cl) == 64
@assert Set([0, 3, 5]) in cl

cl0 = directed_closure([Set{Int}(); [Set([i]) for i in 1:5]])
@assert length(cl0) == 32
@assert all(!(0 in Y) for Y in cl0)

println("Julia：b=1..3 时最小覆盖数恰为 ⌈|X|/b⌉（全 64 个 X 核对）；")
println("缺含 0 的成员 ⇒ 0 完全不可覆盖；空集+单点定向闭包 = 全幂集（64）")
println("END ====")
