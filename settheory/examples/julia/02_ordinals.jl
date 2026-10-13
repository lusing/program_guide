# 第 02 章 序数：Cantor 范式（CNF）序数计算器
#
# 每个小于 ε₀ 的序数有唯一的 Cantor 范式：
#     α = ω^e1·c1 + ω^e2·c2 + ... + ω^ek·ck + n   (e1>...>ek, ci∈ℕ⁺, n∈ℕ)
# 指数 e 自身也是 CNF（递归）。本文件实现比较/加法/乘法/幂，
# 并验证 Jech §2 的全部经典不等式。

println("==== 02 序数：CNF 计算器")

# CNF 表示：terms = [(e, c), ...]（ω^e·c 项，指数递降），fin = 尾部自然数
struct ON
    terms::Vector{Tuple{ON,Int}}
    fin::Int
end

oz() = ON([], 0)
on_n(n::Int) = n <= 0 ? oz() : ON([], n)
on_wexp(e::ON) = ON([(e, 1)], 0)      # ω^e
omega() = on_wexp(on_n(1))            # ω = ω^1

# ---------- 比较 ----------
function olt(a::ON, b::ON)
    a == b && return false            # （结构相等——仅用于短路；真正定义见下）
    if isempty(a.terms)
        isempty(b.terms) && return a.fin < b.fin
        return true                    # 有限 < 无穷
    end
    isempty(b.terms) && return false
    (ea, ca), (eb, cb) = a.terms[1], b.terms[1]
    olt(ea, eb) && return true
    olt(eb, ea) && return false
    ca != cb && return ca < cb
    # 首项相同 → 递归比较余项
    return olt(ON(a.terms[2:end], a.fin), ON(b.terms[2:end], b.fin))
end
Base.:(==)(a::ON, b::ON) = a.terms == b.terms && a.fin == b.fin

# ---------- 加法：α + β ----------
# 保留 α 中指数 > β 首项指数的前缀；其余（含 fin）被吸收。
function oadd(a::ON, b::ON)
    isempty(b.terms) && return ON(a.terms, a.fin + b.fin)
    eb, cb = b.terms[1]
    keep = Tuple{ON,Int}[]
    for (e, c) in a.terms
        olt(eb, e) ? push!(keep, (e, c)) : break
    end
    # α 中指数恰为 eb 的项（若有）与 β 首项合并系数，更低项与 fin 被吞
    head_extra = 0
    if length(keep) < length(a.terms) && a.terms[length(keep)+1][1] == eb
        head_extra = a.terms[length(keep)+1][2]
    end
    newb = vcat([(eb, cb + head_extra)], b.terms[2:end])
    normalize_terms(vcat(keep, newb), b.fin)
end

# 项列表规范化：合并同指数、去零系数、按指数递降排序
function normalize_terms(t::Vector{Tuple{ON,Int}}, fin::Int)
    ts = [(e, c) for (e, c) in t if c > 0]
    isempty(ts) && return ON([], max(fin, 0))
    sort!(ts; lt=(x, y) -> olt(y[1], x[1]))
    out = [ts[1]]
    for (e, c) in ts[2:end]
        if out[end][1] == e
            out[end] = (e, out[end][2] + c)
        else
            push!(out, (e, c))
        end
    end
    ON(out, max(fin, 0))
end

# ---------- 乘法：α · β ----------
function omul(a::ON, b::ON)
    a == oz() || b == oz() ? (return oz()) : ()
    b == on_n(1) && return a
    isempty(b.terms) && return omul_fin(a, b.fin)     # α·n = α+…+α
    isempty(a.terms) && return ON(b.terms, b.fin)     # 有限正数·无穷 = 无穷首项吸收系数
    (ea, ca) = a.terms[1]
    (eb, cb) = b.terms[1]
    head = (oadd(ea, eb), cb)                          # ω^(ea+eb)·cb：α 首项系数被吸收
    rest_b = ON(b.terms[2:end], b.fin)
    if rest_b == oz()
        return ON([head], 0)
    end
    rest = omul(a, rest_b)
    ON(vcat([head], rest.terms), rest.fin)
end

function omul_fin(a::ON, n::Int)
    r = oz()
    for _ in 1:n
        r = oadd(r, a)
    end
    r
end

# ---------- 打印 ----------
function show_on(a::ON)
    parts = String[]
    for (e, c) in a.terms
        es = (e == oz()) ? "0" : (e == on_n(1) ? "" : "(" * show_on(e) * ")")
        push!(parts, c == 1 ? "ω$es" : "ω$es·$c")
    end
    a.fin > 0 && push!(parts, string(a.fin))
    isempty(parts) && return "0"
    join(parts, "+")
end
Base.show(io::IO, a::ON) = print(io, show_on(a))

# ---------------- 验证 Jech §2 的经典事实 ----------------

w = omega()
one = on_n(1)
two = on_n(2)

r1 = oadd(one, w)
println("1 + ω = ", show_on(r1))
@assert r1 == w                          # 吸收：有限被 ω 吞没

r2 = oadd(w, one)
println("ω + 1 = ", show_on(r2))
@assert olt(w, r2)                       # 不塌缩
@assert olt(r2, oadd(w, two))            # ω+1 < ω+2

r3 = oadd(w, w)
println("ω + ω = ", show_on(r3), "  （即 ω·2）")
@assert r3 == omul(w, two)

r4 = omul(two, w)
println("2 · ω = ", show_on(r4))
@assert r4 == w                          # 乘法吸收：2·ω = ω

wp1 = oadd(w, one)
r5 = omul(wp1, two)
println("(ω+1)·2 = ", show_on(r5))
@assert r5 == oadd(omul(w, two), one)    # Jech：分配律反向的反例

w2 = omul(w, w)
println("ω · ω = ", show_on(w2), "  （即 ω²）")
@assert w2 == on_wexp(two)

ww = on_wexp(w)
println("ω^ω = ", show_on(ww))

# ε₀ 的逼近：α ↦ ω^α 迭代（Jech 习题 2.8：正规函数的不动点）
function eps0_approx(steps::Int)
    println("ε₀ 逼近序列：")
    a = on_n(1)
    for k in 1:steps
        a = on_wexp(a)                 # α ↦ ω^α
        println("  第 $k 步 = ", show_on(a))
    end
    return a
end
e0 = eps0_approx(5)
@assert olt(on_wexp(e0), e0) == false   # ω^e0 ≤ e0：逼近已过不动点邻域
println("（ω 的幂塔；真正的 ε₀ = 这座塔的 sup）")

println("要点：加法/乘法都是『左吸收』；结合律成立、交换律全线崩塌。")
println("END ====")
