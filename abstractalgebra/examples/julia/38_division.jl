# 第 38 章 · 广义的除法算式 —— Julia 通道
#
# 单项式序（lex/grlex/grevlex）+ 多变量多项式（指数向量表示）+
# 多元除法算法（分割规则）。

println("==== 38 广义的除法算式")

# ---------- 多项式：Dict{指数向量, 系数}（稠密指数向量 n 个变元） ----------
# 项 (c, e)：单项式 x^e = x₁^{e₁}⋯xₙ^{eₙ}
import Base: +, -, *, ==

poly(coeffs_keys::Vector{Tuple{Int,Vector{Int}}}) = begin
    d = Dict{Vector{Int},Int}()
    for (c, e) in coeffs_keys
        c == 0 && continue
        d[e] = get(d, e, 0) + c
    end
    filter!(p -> p.second != 0, d)
    d
end

# ---------- 单项式序 ----------
"""字典序 lex：先比 x₁ 的指数。"""
lex(e1, e2) = begin
    for i in 1:length(e1)
        e1[i] != e2[i] && return e1[i] > e2[i]
    end
    false
end

"""全次序 grlex：先比总次数，再字典。"""
grlex(e1, e2) = begin
    s1, s2 = sum(e1), sum(e2)
    s1 != s2 && return s1 > s2
    lex(e1, e2)
end

"""逆字典序 grevlex：总次数优先，平局时比最后一个非零差变元（小者优先）。"""
grevlex(e1, e2) = begin
    s1, s2 = sum(e1), sum(e2)
    s1 != s2 && return s1 > s2
    for i in length(e1):-1:1
        d = e2[i] - e1[i]
        d != 0 && return d > 0
    end
    false
end

# 序的公理核对（小规模枚举）：全序 + 与乘法相容
function check_order_ok(ord, n, deg)
    mons = vec([collect(m) for m in Iterators.product([0:deg for _ in 1:n]...)])
    # 用序排序后核对传递与完全性（间接验证全序）
    sorted = sort(mons; lt=(a, b) -> ord(b, a))
    # 反对称 + 完全
    for a in mons, b in mons
        @assert !(ord(a, b) && ord(b, a))           # 反对称
        @assert ord(a, b) || ord(b, a) || a == b     # 完全
        # 乘法相容：a > b ⟹ a+c > b+c
        for c in mons
            @assert ord(a, b) ? ord(a .+ c, b .+ c) : true
        end
    end
    true
end

@assert check_order_ok(lex, 2, 2)
@assert check_order_ok(grlex, 2, 2)
@assert check_order_ok(grevlex, 2, 2)
println("单项式序：lex/grlex/grevlex 在 9 个单项式上全序 + 乘法相容 ✓")

# 三种序给出不同的首项排序（Cox 例：x₁ > x₂x₃² 按 lex；grlex 下 x₂x₃² 在前）
@assert lex([1, 0, 0], [0, 1, 2])                   # x₁ > x₂x₃²（lex）
@assert !grlex([1, 0, 0], [0, 1, 2])                # grlex：总次 1 < 3
@assert grlex([0, 1, 2], [1, 0, 0])
println("首项对比：lex 首项 x₁；grlex/grevlex 首项 x₂x₃²（同一次多项式）✓")

# ---------- 多元除法 ----------
"""多项式在序 ord 下的首项 (c, e)。"""
function leading_term(f, ord)
    es = collect(keys(f))
    best = es[1]
    for e in es[2:end]
        ord(e, best) && (best = e)
    end
    (f[best], best)
end

"""多项式加法。"""
padd(f, g) = begin
    h = copy(f)
    for (e, c) in g
        h[e] = get(h, e, 0) + c
        h[e] == 0 && delete!(h, e)
    end
    h
end

"""单项式乘多项式。"""
monom_mul(c, e, f) = Dict(e .+ e2 => c * c2 for (e2, c2) in f)

"""多变量除法：f 除以 (f₁,…,fₛ)（序 ord），返回 (余式, 商表)。"""
function divide(f, fs, ord)
    n = length(first(keys(f)))
    r = Dict{Vector{Int},Int}()
    quot = [Dict{Vector{Int},Rational{Int}}() for _ in fs]
    zero = Dict{Vector{Int},Int}()
    while f != zero
        divided = false
        for (j, g) in enumerate(fs)
            lg = leading_term(g, ord)
            lf = leading_term(f, ord)
            # lt(f) 能被 lt(g) 整除？
            if all(lf[2][i] >= lg[2][i] for i in 1:n)
                ec = lf[2] .- lg[2]
                cquot = lf[1] // lg[1]
                # f -= (cquot·x^ec)·g；q_j += ...
                f = padd(f, monom_mul(-cquot, ec, g))
                quot[j][ec] = get(quot[j], ec, 0) + cquot
                divided = true
                break
            end
        end
        divided || begin
            lf = leading_term(f, ord)
            r[lf[2]] = get(r, lf[2], 0) + lf[1]
            f = padd(f, Dict(lf[2] => -lf[1]))
        end
    end
    (r, quot)
end

"""多项式乘法。"""
function pmul(f, g)
    h = Dict{Vector{Int},Rational{Int}}()
    for (e1, c1) in f, (e2, c2) in g
        e = e1 .+ e2
        h[e] = get(h, e, 0) + c1 * c2
        h[e] == 0 && delete!(h, e)
    end
    h
end

# 原书例（定理 7.60 后）：f = x²y + xy² + y²，f₁ = xy − 1，f₂ = y² − 1
# lex 序除法得余式 x + y + 1；商的具体形状依赖平局时的选择，
# 断言「分解恒等式 f = Σ qᵢfᵢ + r」与「r 既约」而非具体商
f = poly([(1, [2, 1]), (1, [1, 2]), (1, [0, 2])])
f1 = poly([(1, [1, 1]), (-1, [0, 0])])
f2 = poly([(1, [0, 2]), (-1, [0, 0])])
r, q = divide(f, [f1, f2], lex)
@assert r == poly([(1, [1, 0]), (1, [0, 1]), (1, [0, 0])])   # x + y + 1
lhs = pmul(q[1], f1)
lhs = padd(lhs, pmul(q[2], f2))
lhs = padd(Dict([k => Rational(v) for (k, v) in lhs]), r)
@assert lhs == Dict([k => Rational(v) for (k, v) in f])      # f = Σqᵢfᵢ + r
println("多元除法：f mod [f₁,f₂] 余式 x+y+1，分解恒等式 f = Σqᵢfᵢ + r 成立（lex）✓")

# 除法结果依赖被除式顺序（原书 7.5.2 末的警示例，CLO 例）：
# f = xy² − x 除以 [xy+1, y²−1] 得 r = −x − y；交换顺序得 r = 0
g = poly([(1, [1, 2]), (-1, [1, 0])])
g1 = poly([(1, [1, 1]), (1, [0, 0])])
g2 = poly([(1, [0, 2]), (-1, [0, 0])])
r1, _ = divide(g, [g1, g2], lex)
r2, _ = divide(g, [g2, g1], lex)
@assert r1 == poly([(-1, [1, 0]), (-1, [0, 1])])             # −x − y
@assert r2 == Dict{Vector{Int},Int}()                        # 0
@assert r1 != r2
println("顺序依赖：同一 f 换被除式顺序得不同余式（−x−y vs 0）——"
        * "余式不是理想成员的判据，这是下一章 Grobner 基的动机 ✓")

println("END ====")
