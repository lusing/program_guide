# 第 87 章 · 可构造宇宙 L 与一般连续统假设（冯琦第二卷 §2.1）——Julia 通道
# 与 Python 同一组检查：L_n = V_n 的引擎、位置配对对角线、
# <_L 典范秩序的出生层比较与末端延伸。
println("==== 87")

struct HS
    elems::Vector{HS}
end
rank(x::HS) = isempty(x.elems) ? 0 : 1 + maximum(rank(y) for y in x.elems)
function hs(xs::HS...)
    ys = collect(xs)
    sort!(ys, by = y -> (rank(y), string(y)))
    unique!(ys)
    HS(ys)
end
Base.show(io::IO, x::HS) = print(io, "{", join(string.(x.elems), ","), "}")
Base.:(==)(x::HS, y::HS) = x.elems == y.elems
Base.hash(x::HS, h::UInt) = hash(x.elems, h)

# ---------- 一、V 层次与 L_n = V_n 的引擎 ----------

function powerset_hf(prev::Vector{HS})
    out = Vector{HS}()
    for mask in 0:(1 << length(prev)) - 1
        sel = HS([prev[i] for i in eachindex(prev) if (mask >> (i - 1)) & 1 == 1])
        push!(out, sel)
    end
    out
end

function vlevels(n)
    levels = [Vector{HS}()]
    for _ in 1:n
        push!(levels, powerset_hf(levels[end]))
    end
    levels
end

levels = vlevels(4)
sizes = length.(levels)
@assert sizes == [0, 1, 2, 4, 16]
println("V 层次规模: ", sizes, " —— 有限层上 L_n = V_n（引理 2.1(3)）")

function def_closure(m::Vector{HS})
    # 从 ∅、全集与全部单点出发对补与二元并封闭：有限载体上到顶 = 全部子集
    # （所有集合一律经 hs 规范化：排序去重，保证 == 与 hash 的判等正确）
    fam = Set{HS}([hs(), hs(m...), [hs(p) for p in m]...])
    changed = true
    while changed
        changed = false
        for A in collect(fam)
            comp = hs([x for x in m if !(x in A.elems)]...)
            if !(comp in fam)
                push!(fam, comp)
                changed = true
            end
        end
        for A in collect(fam), B in collect(fam)
            U = hs(vcat(A.elems, [x for x in B.elems if !(x in A.elems)])...)
            if !(U in fam)
                push!(fam, U)
                changed = true
            end
        end
    end
    fam
end

fam3 = def_closure(levels[4])
@assert length(fam3) == 16
@assert length(powerset_hf(levels[4])) == 16
println("V_3 上的可定义闭包 = ", length(fam3), " = 2^4：引擎到顶")

# ---------- 二、公式可数 vs 子集更多：位置配对对角线 ----------

satb(f, x) = begin
    k = f[1]
    k == :tt && return true
    k == :ff && return false
    k == :eq && return x == f[2]
    k == :mem && return x * f[2] == 3
    k == :neg && return !satb(f[2], x)
    k == :or && return satb(f[2], x) || satb(f[3], x)
    error(f)
end

C4 = [0, 1, 2, 3]
atoms = vcat([(:tt,), (:ff,)], [(:eq, p) for p in C4], [(:mem, p) for p in C4])
Fs = vcat(atoms, [(:neg, f) for f in atoms], [(:or, f, g) for f in atoms for g in atoms])
@assert length(Fs) == 120
ext(f) = tuple([x for x in C4 if satb(f, x)]...)
println("深度 ≤ 1 的公式 ", length(Fs), " 个，给出 ",
        length(Set(ext.(Fs))), " 个不同子集（4 元载体全部 16 个）")

D = tuple([x for x in C4 if !satb(Fs[x + 1], x)]...)
for k in C4
    @assert (k in D) != (k in ext(Fs[k + 1]))
end
println("对角线集合 D = ", D, " 与全部 120 个扩张在配对位置互异")

# ---------- 三、<_L 典范秩序：出生层 + 最小定义码 ----------

born(x::HS) = findfirst(l -> x in l, levels) - 1

function literal_chains(m::Vector{HS})
    lits = vcat([(:eq, i) for i in eachindex(m)], [(:mem, i) for i in eachindex(m)],
                [(:neg, (:eq, i)) for i in eachindex(m)], [(:neg, (:mem, i)) for i in eachindex(m)])
    function sat_lit(l, x)
        l[1] == :eq && return x == m[l[2]]
        l[1] == :mem && return x in m[l[2]].elems
        return !sat_lit(l[2], x)
    end
    sat_chain(chain, x) = any(sat_lit(l, x) for l in chain)
    chains = Vector{Tuple}()
    for k in 1:length(m), combo in Iterators.product([1:length(lits) for _ in 1:k]...)
        push!(chains, tuple([lits[i] for i in combo]...))
    end
    chains, sat_chain
end

function code_of(x::HS, m::Vector{HS})
    isempty(m) && return ()
    target = Set(x.elems)
    chains, sat_chain = literal_chains(m)
    for chain in chains
        got = Set([a for a in m if sat_chain(chain, a)])
        got == target && return chain
    end
    error("no code")
end

function level_order(n)
    low = n > 1 ? level_order(n - 1) : Vector{HS}()
    old = [e for e in low if e in levels[n]]
    new = n == 1 ? collect(levels[1]) : [e for e in levels[n] if !(e in levels[n - 1])]
    m = n == 1 ? Vector{HS}() : sort(levels[n - 1], by = t -> (rank(t), string(t)))
    sort!(new, by = e -> string(code_of(e, m)))
    vcat(old, new)
end

ord3 = level_order(4)
ord4 = level_order(5)
@assert length(ord3) == 4 && length(ord4) == 16
@assert length(Set(ord4)) == 16

idx = Dict(e => i for (i, e) in enumerate(ord4))
# 三分性 + 传递性（严格全序的有限验证）
for a in ord4, b in ord4
    a == b && continue
    @assert (idx[a] < idx[b]) != (idx[b] < idx[a])
end
for a in ord4, b in ord4, c in ord4
    @assert !(idx[a] < idx[b] && idx[b] < idx[c]) || idx[a] < idx[c]
end
# 末端延伸（定义 2.14(b)）
rest = [e for e in ord4 if e in levels[4]]
@assert rest == ord3
println("<_L 在 L_4 上严格全序（三分 + 传递），且末端延伸 L_3 的秩序 ✓")

# ---------- 四、规模对账 ----------

println("L 层次规模对账: |L_n| = ", sizes, " ↔ |V_n|；",
        "ω 层之后公式只有可数多个，|L_{ω+1}| = ℵ₀ < 2^ℵ₀ = |V_{ω+1}|")
println("END ====")
