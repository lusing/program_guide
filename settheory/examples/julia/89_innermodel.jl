# 第 89 章 · 内模型 HOD、L[A] 与 L(ℝ)（冯琦第二卷 §2.2）——Julia 通道
# 与 Python 同一组检查：OD(V_3) 见证、引理 2.27(3) 等价、谓词免参定义力、L[U] 计算账。
println("==== 89")

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
Base.:(==)(x::HS, y::HS) = x.elems == y.elems
Base.hash(x::HS, h::UInt) = hash(x.elems, h)

function powerset_hf(prev::Vector{HS})
    out = Vector{HS}()
    for mask in 0:(1 << length(prev)) - 1
        push!(out, hs([prev[i] for i in eachindex(prev) if (mask >> (i - 1)) & 1 == 1]...))
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
V2, V3, V4 = levels[3], levels[4], levels[5]
NAT = [hs()]
for _ in 1:3
    prev = NAT[end]
    push!(NAT, hs(vcat(prev.elems, [prev])...))   # 后继 n ∪ {n}
end

# ---------- 一、OD(V_3) = V_3（例 2.2(1)）：序数参数见证 ----------

bex(x, cond) = any(cond, x.elems)
ball(x, cond) = all(cond, x.elems)

wit = Dict(
    NAT[1] => (x -> x == NAT[1]),                                   # x = 0（免参）
    NAT[2] => (x -> x == NAT[2]),                                   # x = 1（免参）
    NAT[3] => (x -> x == NAT[3]),                                   # x = 2（免参）
    hs(NAT[2]) => (x -> ball(x, y -> y == NAT[2]) && bex(x, y -> y == NAT[2])),  # x = {1}
)
@assert Set(keys(wit)) == Set(V3)
for (a, phi) in wit
    ext = Set(x for x in V3 if phi(x))
    @assert ext == Set([a])
end
println("V_3 的四个元素全部由带序数参数的 Delta_0 公式唯一见证：OD(V_3) = V_3 OK")

# ---------- 二、引理 2.27(3) 等价式的数值验证 ----------

function tcplus(x::HS)
    seen = Set{HS}()
    todo = [x]
    while !isempty(todo)
        y = pop!(todo)
        y in seen && continue
        push!(seen, y)
        append!(todo, y.elems)
    end
    seen
end

inV3(y) = y in V3
hered_tc(x) = all(inV3, tcplus(x))
hered_split(x) = inV3(x) && all(hered_tc, x.elems)

for x in V4
    @assert hered_tc(x) == hered_split(x)
end
println("V_4 全体：Hered_TC(x) = (P x 且成员全 Hered)——引理 2.27(3) 等价成立 OK")

# ---------- 三、谓词原子对免参定义力的提升 ----------

sat_free(f, x, U) = begin
    k = f[1]
    k == :tt && return true
    k == :ff && return false
    k == :inA && return x in U
    k == :neg && return !sat_free(f[2], x, U)
    k == :or && return sat_free(f[2], x, U) || sat_free(f[3], x, U)
    error(f)
end

function free_family(U, with_pred)
    atoms = vcat([(:tt,), (:ff,)], with_pred ? [(:inA,)] : Vector{Tuple}[])
    fs = vcat(atoms, [(:neg, a) for a in atoms])
    fs = vcat(fs, [(:or, a, b) for a in atoms for b in atoms])
    Set(tuple([x for x in V2 if sat_free(f, x, U)]...) for f in fs)
end

U = Set([NAT[1]])                    # 谓词解释：U 含 0 不含 1
no_pred = free_family(U, false)
with_pred = free_family(U, true)
@assert length(no_pred) == 2 && length(with_pred) == 4
println("V_2 上免参可定义子集：无谓词 2 个 -> 带谓词 4 个——U 截断进入免参定义 OK")

# ---------- 四、L_n[U] = V_n 与 U 属于 L[U]（引理 2.24 的计算账） ----------

function def_closure(m::Vector{HS}, U)
    fam = Set{HS}([hs(), hs(m...), [hs(p) for p in m]...])
    U0 = hs(collect(U)...)
    U0 != hs() && U0 != hs(m...) && push!(fam, U0)
    changed = true
    while changed
        changed = false
        for A in collect(fam)
            comp = hs([x for x in m if !(x in A.elems)]...)
            comp in fam || (push!(fam, comp); changed = true)
        end
        for A in collect(fam), B in collect(fam)
            W = hs(vcat(A.elems, [x for x in B.elems if !(x in A.elems)])...)
            W in fam || (push!(fam, W); changed = true)
        end
    end
    fam
end

LU = def_closure(V2, U)
@assert LU == Set(powerset_hf(V2)) && length(LU) == 4
U0 = hs(collect(U)...)
@assert U0 in V3
println("L[U] 有限层与 V 重合；U 截断由谓词原子免参给出，U 属于 L_3[U] OK")

println("END ====")
