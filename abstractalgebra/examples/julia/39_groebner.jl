# 第 39 章 · 格罗布纳基 —— Julia 通道
#
# S-多项式 + Buchberger 判据（定理 7.67）+ 算法 + 三个应用
#（理想成员判定、理想相等、方程组求解）。

println("==== 39 格罗布纳基")

# ---------- 多项式机器（与第 38 章同构） ----------
function poly(cks)
    d = Dict{Vector{Int},Rational{Int}}()
    for (c, e) in cks
        c == 0 && continue
        d[e] = get(d, e, 0) + c
    end
    filter!(p -> p.second != 0, d)
    d
end

lex(e1, e2) = begin
    for i in 1:length(e1)
        e1[i] != e2[i] && return e1[i] > e2[i]
    end
    false
end
grlex(e1, e2) = begin
    s1, s2 = sum(e1), sum(e2)
    s1 != s2 && return s1 > s2
    lex(e1, e2)
end

function leading_term(f, ord)
    es = collect(keys(f))
    best = es[1]
    for e in es[2:end]
        ord(e, best) && (best = e)
    end
    (f[best], best)
end

padd(f, g) = begin
    h = copy(f)
    for (e, c) in g
        h[e] = get(h, e, 0) + c
        h[e] == 0 && delete!(h, e)
    end
    h
end

monom_mul(c, e, f) = Dict(e .+ e2 => c * c2 for (e2, c2) in f)

pmul(f, g) = begin
    h = Dict{Vector{Int},Rational{Int}}()
    for (e1, c1) in f, (e2, c2) in g
        e = e1 .+ e2
        h[e] = get(h, e, 0) + c1 * c2
        h[e] == 0 && delete!(h, e)
    end
    h
end

"""多变量除法（定理 7.60），返回余式。"""
function rem(f, fs, ord)
    n = length(first(keys(f)))
    zero = Dict{Vector{Int},Rational{Int}}()
    r = Dict{Vector{Int},Rational{Int}}()
    while f != zero
        divided = false
        for g in fs
            lg = leading_term(g, ord)
            lf = leading_term(f, ord)
            if all(lf[2][i] >= lg[2][i] for i in 1:n)
                ec = lf[2] .- lg[2]
                f = padd(f, monom_mul(-(lf[1] // lg[1]), ec, g))
                divided = true
                break
            end
        end
        if !divided
            lf = leading_term(f, ord)
            r[lf[2]] = get(r, lf[2], 0) + lf[1]
            f = padd(f, Dict(lf[2] => -lf[1]))
        end
    end
    r
end

# ---------- S-多项式与 Buchberger ----------
"""S(f, g) = (L/lc(f))·f − (L/lc(g))·g，L 是首单项式的 lcm。"""
function spoly(f, g, ord)
    lf, lg = leading_term(f, ord), leading_term(g, ord)
    L = [max(lf[2][i], lg[2][i]) for i in 1:length(lf[2])]
    padd(monom_mul(1 // lf[1], L .- lf[2], f),
         monom_mul(-(1 // lg[1]), L .- lg[2], g))
end

"""Buchberger 判据核对：所有 S(gᵢ,gⱼ) mod G 余式为零。"""
function is_groebner(G, ord)
    for i in 1:length(G), j in i+1:length(G)
        s = spoly(G[i], G[j], ord)
        s == Dict{Vector{Int},Rational{Int}}() && continue
        rem(s, G, ord) != Dict{Vector{Int},Rational{Int}}() && return false
    end
    true
end

"""Buchberger 算法：往基里补非零 S-余式直到判据通过。"""
function buchberger(G, ord)
    zero = Dict{Vector{Int},Rational{Int}}()
    G = deepcopy(G)
    changed = true
    while changed
        changed = false
        for i in 1:length(G), j in i+1:length(G)
            s = spoly(G[i], G[j], ord)
            s == zero && continue
            r = rem(s, G, ord)
            if r != zero
                push!(G, r)
                changed = true
            end
        end
    end
    G
end

# 原书例：{x² + 1, xy − 1} 不是 Grobner 基（S 的余式非零）
h1 = poly([(1, [2, 0]), (1, [0, 0])])            # x² + 1
h2 = poly([(1, [1, 1]), (-1, [0, 0])])           # xy − 1
G0 = [h1, h2]
@assert !is_groebner(G0, lex)
s01 = spoly(h1, h2, lex)
@assert s01 == poly([(1, [1, 0]), (1, [0, 1])])  # S = y·(x²+1) − x·(xy−1) = x + y
r01 = rem(s01, G0, lex)
@assert r01 == poly([(1, [1, 0]), (1, [0, 1])])  # 余式 = S 本身（不能再约）
println("S-多项式：S(x²+1, xy−1) = x + y，mod 原基余式非零 ⟹ 非 Grobner 基 ✓")

# Buchberger 算法补出 Grobner 基 {x²+1, xy−1, x+y, y²−1}
GB = buchberger(G0, lex)
@assert is_groebner(GB, lex)
@assert length(GB) == 4
@assert poly([(1, [1, 0]), (1, [0, 1])]) in GB             # x + y 补入基中
println("Buchberger：{x²+1, xy−1} → {x²+1, xy−1, x+y, y²−1}（$(length(GB)) 元基）判据全过 ✓")

# ---------- 应用一：理想成员判定（推论 7.63） ----------
# f ∈ I = (g₁,…,gₘ) ⟺ f mod GB = 0
# 例：xy² − x ∈ (xy+1, y²−1)？第 38 章的顺序依赖案：换序后余式 0
t = poly([(1, [1, 2]), (-1, [1, 0])])            # xy² − x
e1 = poly([(1, [1, 1]), (1, [0, 0])])            # xy + 1
e2 = poly([(1, [0, 2]), (-1, [0, 0])])           # y² − 1
GBe = buchberger([e1, e2], lex)
@assert is_groebner(GBe, lex)
@assert rem(t, GBe, lex) == Dict{Vector{Int},Rational{Int}}()   # 确在理想中
u = poly([(1, [1, 0])])                          # x 不在理想中
@assert rem(u, GBe, lex) != Dict{Vector{Int},Rational{Int}}()
println("理想成员：xy²−x ∈ (xy+1, y²−1) 经 Grobner 基判定为真；x ∉ ✓")

# ---------- 应用二：理想相等 ----------
# ℚ 上 (x+y, x−y) = (x, y)：x = ½(x+y) + ½(x−y)、y = ½(x+y) − ½(x−y)
I1 = [poly([(1, [1, 0]), (1, [0, 1])]), poly([(1, [1, 0]), (-1, [0, 1])])]
I2 = [poly([(1, [1, 0])]), poly([(1, [0, 1])])]
GB1 = buchberger(I1, lex)
GB2 = buchberger(I2, lex)
# 两理想相等 ⟺ 互相整除（每个生成元 mod 对方基余式为零）
for g in I1
    @assert rem(g, GB2, lex) == Dict{Vector{Int},Rational{Int}}()
end
for g in I2
    @assert rem(g, GB1, lex) == Dict{Vector{Int},Rational{Int}}()
end
println("理想相等：(x+y, x−y) = (x, y) 双向成员判定（½ 系数出场）✓")

# ---------- 应用三：方程组求解（消元定理的数值面） ----------
# {x² + y² = 1, x − y = 0}：lex 序 Grobner 基给出三角形
p1 = poly([(1, [2, 0]), (1, [0, 2]), (-1, [0, 0])])   # x² + y² − 1
p2 = poly([(1, [1, 0]), (-1, [0, 1])])                # x − y
GBs = buchberger([p1, p2], lex)
# 基中必有只含 y 的多项式（消元）：2y² − 1
only_y = [g for g in GBs if all(e[1] == 0 for e in keys(g))]
@assert length(only_y) >= 1
@assert any(q -> q == poly([(2, [0, 2]), (-1, [0, 0])]), only_y)
println("消元：{x²+y²−1, x−y} 的 lex 基含 2y²−1（纯 y 多项式）——"
        * "解 y = ±1/√2、x = y ✓")

println("END ====")
