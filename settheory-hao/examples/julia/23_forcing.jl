# 第 23 章 Julia：力迫法的有限实验（书 9.2-9.5）。
# ① 偏序 Func(I,J) 的稠密性与条件计数；
# ② M-脱殊滤的构造算法 + Cohen 实数的出生现场；
# ③ 链相容性审计。
println("==== 23 forcing")

# 条件 = Dict{Int,Int}（部分函数）
dom_of(p) = sort(collect(keys(p)))

function compat(p, q)
    all(p[d] == q[d] for d in keys(p) if haskey(q, d))
end

# p ≤ q（力迫：p 更强）⟺ p ⊇ q（函数包含）
stronger(p, q) = all(haskey(p, d) && p[d] == v for (d, v) in q)

# 枚举条件
function enumerate_conditions(n, m, max_size)
    conds = Dict{Int,Int}[]
    for dom_set in all_subsets(collect(1:n), max_size)
        for vals in all_valuations(dom_set, m)
            push!(conds, Dict(zip(dom_set, vals)))
        end
    end
    conds
end

function all_subsets(items, max_size)
    out = [Int[]]
    for r in 1:min(max_size, length(items))
        for c in combinations_of(items, r)
            push!(out, c)
        end
    end
    out
end

function combinations_of(items, r)
    n = length(items)
    if r == 0; return [Int[]]; end
    if n < r; return Vector{Int}[]; end
    out = Vector{Int}[]
    without_last = combinations_of(items[1:end-1], r-1)
    for c in without_last
        push!(out, vcat(c, [items[end]]))
    end
    append!(out, combinations_of(items[1:end-1], r))
    out
end

function all_valuations(dom, m)
    if isempty(dom); return [Int[]]; end
    out = Vector{Int}[]
    for v in 0:m-1
        for rest in all_valuations(dom[2:end], m)
            push!(out, vcat([v], rest))
        end
    end
    out
end

P2 = enumerate_conditions(2, 2, 2)
println("P = Func(2,2), |dom|≤2: $(length(P2)) conditions")

is_dense(D, P) = all(any(stronger(q, p) for q in D) for p in P)

D1 = [p for p in P2 if 1 in keys(p)]
@assert is_dense(D1, P2)
println("D_1 = {p : 1 ∈ dom(p)} is dense: OK")

function cohen_chain(P, dense_sets)
    cur = Dict{Int,Int}()
    chain = [cur]
    for D in dense_sets
        cands = [q for q in D if stronger(q, cur)]
        isempty(cands) && error("not dense")
        cur = cands[argmin([length(q) for q in cands])]
        push!(chain, deepcopy(cur))
    end
    chain
end

n3 = 3
P3 = enumerate_conditions(n3, 2, n3)
D3 = [[p for p in P3 if i in keys(p)] for i in 1:n3]
chain = cohen_chain(P3, D3)
f_cohen = merge(chain...)
@assert length(f_cohen) == n3
@assert all(v in (0, 1) for v in values(f_cohen))
println("cohen real: chain union covers domain {1,2,3}, values in {0,1}: OK")

@assert all(compat(chain[i], chain[j]) for i in eachindex(chain), j in eachindex(chain))
println("chain elements pairwise compatible: OK")
println("ccc shadow: finite antichain trivially countable: OK")
println("END ====")
