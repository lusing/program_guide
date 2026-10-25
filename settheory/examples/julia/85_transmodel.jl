# 第 85 章 · 传递模型（冯琦第二卷 §1.2）——Julia 通道
# 与 Python 同一组检查：不传递载体失去外延；后继公式的斯科伦闭包
# 把 {0,5} 补成整段 0..5；∃y (y = {x}) 的见证在 V_3 关闭。
println("==== 85")

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
Base.iterate(x::HS, st...) = iterate(x.elems, st...)
Base.isempty(x::HS) = isempty(x.elems)
Base.:(==)(x::HS, y::HS) = x.elems == y.elems
Base.hash(x::HS, h::UInt) = hash(x.elems, h)

function transitive(m)
    all(y in m for x in m for y in x)
end

function inside(m, a)
    Set(z for z in m if z in a)
end

function same_inside(m, a, b)
    inside(m, a) == inside(m, b)
end

function extensional(m)
    all(same_inside(m, a, b) == (a == b) for a in m for b in m)
end

zero = hs()
a = hs(zero)
b = hs(hs(a))
gap = Set([a, b])
@assert !transitive(gap) && !extensional(gap)
println("不传递的 {a,b}：外延失败，传递失败 ✓")

function powerset(v)
    prev = collect(v)
    out = Set{HS}()
    for mask in 0:(1 << length(prev)) - 1
        push!(out, hs((prev[i] for i in eachindex(prev) if (mask >> (i - 1)) & 1 == 1)...))
    end
    out
end

function vee(n)
    levels = [Set{HS}()]
    for _ in 1:n
        push!(levels, powerset(levels[end]))
    end
    levels
end

levels = vee(4)
v4 = levels[5]
@assert length(v4) == 16
@assert transitive(v4) && extensional(v4)
println("V_4 有 16 个元素，传递且外延 ✓")

function successor_witness(x, z, universe)
    for y in universe
        if x < y < z && all(!(x < w < y) for w in universe)
            return y
        end
    end
    return nothing
end

function reflects_successor(carrier, universe)
    for x in carrier, z in carrier
        y = successor_witness(x, z, universe)
        y === nothing && continue
        successor_witness(x, z, carrier) === nothing && return false
    end
    true
end

function skolem_hull(seed, universe)
    hull = Set(seed)
    changed = true
    while changed
        changed = false
        for x in collect(hull), z in collect(hull)
            y = successor_witness(x, z, universe)
            if y !== nothing && !(y in hull)
                push!(hull, y)
                changed = true
            end
        end
    end
    hull
end

universe = Set(0:5)
thin = Set([0, 2, 4, 5])
@assert !reflects_successor(thin, universe)
hull = skolem_hull(Set([0, 5]), universe)
@assert hull == universe
@assert reflects_successor(hull, universe)
println("SH({0,5}) = ", sort(collect(hull)), "，后继见证封闭 ✓")

v2 = levels[3]
witnesses = Set(hs(x) for x in v2)
@assert all(rank(y) <= 2 for y in witnesses)
@assert all(y in levels[4] for y in witnesses)
println("V_2 上的单元集见证秩 ≤ 2，全部落在 V_3 ✓")
println("END ====")
