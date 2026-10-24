# 第 72 章：秩序与序数算术（冯琦 §1.8.1-1.8.3）
# 康托尔范式演算器（ε₀ 以内）：加法（等指数合并系数）、乘法
# （水平字典序三情形，含"有限×无穷尾"的正确处理）、ω 幂；
# 定理 1.75/1.76 的运算律在网格上全量验证，不可交换三见证落账，
# 正规函数不动点（定理 1.74）以 ω·x 与 ω^x 两座塔现场点火；
# 自然列表（定义 1.71）以贪心取最小现场生成。
println("==== 72")

# ---------- 表示：ON = [(指数, 系数), …] 指数递降；0 = [] ----------
# 有限 n>0 = [(0, n)]（ω⁰·n）——无尾数设计，表示全域规范（定理 1.80：
# 每个序数唯一的指数-系数表；表示本身即范式，相等即范式相等）。
struct ON
    terms::Vector{Tuple{ON,Int}}
end

oz() = ON(Tuple{ON,Int}[])
nat(n::Int) = n <= 0 ? oz() : ON([(oz(), n)])
wexp(e::ON) = ON([(e, 1)])           # ω^e（定义 1.81：范式即 [(e,1)]）
omega() = wexp(nat(1))

Base.:(==)(a::ON, b::ON) = a.terms == b.terms
tail(a::ON) = ON(a.terms[2:end])

# ---------- 比较：首项指数比、系数比、递归余项 ----------
function olt(a::ON, b::ON)
    a == b && return false
    isempty(a.terms) && return !isempty(b.terms)
    isempty(b.terms) && return false
    (ea, ca), (eb, cb) = a.terms[1], b.terms[1]
    olt(ea, eb) && return true
    olt(eb, ea) && return false
    ca != cb && return ca < cb
    olt(tail(a), tail(b))
end
ole(a::ON, b::ON) = a == b || olt(a, b)

# ---------- 加法（命题 1.25 / 定理 1.75） ----------
# 保留 α 中指数 > β 首指数的前缀；等指数项合并系数
# （漏合并则 ω+ω = ω 假绿——measure 轮的老坑，这里正账）。
function oadd(a::ON, b::ON)
    isempty(b.terms) && return ON(a.terms)
    isempty(a.terms) && return ON(b.terms)
    eb, cb = b.terms[1]
    keep = Tuple{ON,Int}[]
    for (e, c) in a.terms
        olt(eb, e) ? push!(keep, (e, c)) : break
    end
    extra = 0
    if length(keep) < length(a.terms) && a.terms[length(keep)+1][1] == eb
        extra = a.terms[length(keep)+1][2]
    end
    ON(vcat(keep, [(eb, cb + extra)], b.terms[2:end]))
end

# ---------- 乘法（命题 1.26 / 定理 1.76）：水平字典序三情形 ----------
function omul(a::ON, b::ON)
    isempty(a.terms) && return oz()           # 0·β = 0
    isempty(b.terms) && return oz()           # α·0 = 0
    b == nat(1) && return ON(a.terms)         # α·1 = α
    a == nat(1) && return ON(b.terms)         # 1·β = β
    (ea, ca), (eb, cb) = a.terms[1], b.terms[1]
    # 情形一：双方有限——系数相乘（ω⁰·m · ω⁰·n = ω⁰·(mn)）
    if length(a.terms) == 1 && ea == oz() && length(b.terms) == 1 && eb == oz()
        return ON([(oz(), ca * cb)])
    end
    restb = tail(b)
    # 情形二：α 有限、β 无穷——首项 ω^eb 的系数吞掉 α，尾部递归
    #   （2·(ω+3) = ω + 2·3 = ω+6：有限系数只作用于有限尾巴）
    if length(a.terms) == 1 && ea == oz()
        return oadd(ON([(eb, cb)]), omul(a, restb))
    end
    # 情形三：β 有限 ≥ 2——α·m = α+…+α 逐次相加
    #   （(ω+1)·2 = ω·2+1：低次项存活，右分配律失效的根源）
    if eb == oz()
        r = oz()
        for _ in 1:cb; r = oadd(r, a); end
        return r
    end
    # 情形四：α 无穷、β 无穷——头项 ω^(ea+eb)·cb，余部 α·restβ
    head = ON([(oadd(ea, eb), cb)])
    isempty(restb.terms) && return head
    ON(vcat(head.terms, omul(a, restb).terms))
end

function show_on(a::ON)
    parts = String[]
    for (e, c) in a.terms
        es = e == oz() ? "0" : (e == nat(1) ? "" : "(" * show_on(e) * ")")
        push!(parts, c == 1 ? "ω$es" : "ω$es·$c")
    end
    isempty(parts) && return "0"
    join(parts, "+")
end

# ---------- 不可交换三见证（命题 1.25/1.26 的反差） ----------
@assert oadd(nat(1), omega()) == omega()                  # 1+ω = ω
@assert olt(omega(), oadd(omega(), nat(1)))               # ω < ω+1
@assert omul(nat(2), omega()) == omega()                  # 2·ω = ω
@assert olt(omega(), omul(omega(), nat(2)))               # ω < ω·2
@assert oadd(omega(), omega()) == omul(omega(), nat(2))   # ω+ω = ω·2
@assert omul(oadd(omega(), nat(1)), nat(2)) == oadd(omul(omega(), nat(2)), nat(1))
@assert omul(oadd(omega(), nat(1)), nat(2)) != oadd(omul(omega(), nat(2)), nat(2))
println("1+ω = ω < ω+1 ✓   2·ω = ω < ω·2 ✓   (ω+1)·2 = ω·2+1 ≠ ω·2+1·2 ✓")

# ---------- 运算律网格（定理 1.75/1.76 全量验证） ----------
G = [oz(), nat(1), nat(2), omega(), oadd(omega(), nat(1)),
     omul(omega(), nat(2)), wexp(nat(2)), wexp(omega()), oadd(wexp(omega()), nat(1))]

n_add = n_mul = n_dist = n_weak = n_tie = 0
for a in G, b in G, c in G
    global n_add, n_mul, n_dist, n_weak, n_tie
    oadd(oadd(a, b), c) == oadd(a, oadd(b, c)) || error("加法结合律失败")
    n_add += 1
    omul(omul(a, b), c) == omul(a, omul(b, c)) || error("乘法结合律失败")
    n_mul += 1
    omul(a, oadd(b, c)) == oadd(omul(a, b), omul(a, c)) || error("左分配律失败")
    n_dist += 1
    if olt(a, b)
        (ole(oadd(a, c), oadd(b, c))) || error("右弱保序失败")
        n_weak += 1
        oadd(a, c) == oadd(b, c) && (n_tie += 1)
    end
end
println("9³ 网格：加法结合 $(n_add)、乘法结合 $(n_mul)、左分配 $(n_dist) 全对 ✓")
println("右弱保序 $n_weak 例全对（其中平局 $n_tie 例——如 1+ω = 2+ω = ω）✓")

# 弱平局的具体见证：α < β 但 α+ω = β+ω
@assert olt(nat(1), nat(2)) && oadd(nat(1), omega()) == oadd(nat(2), omega())

# ---------- 幂（定义 1.81）：ω^(α+β) = ω^α·ω^β 网格 ----------
n_pow = 0
for a in G, b in G
    global n_pow
    wexp(oadd(a, b)) == omul(wexp(a), wexp(b)) || error("ω 幂的指数分配失败")
    n_pow += 1
end
println("ω^(α+β) = ω^α·ω^β：$n_pow 例全对 ✓")

# ---------- 定理 1.74：正规函数不动点，两座塔现场点火 ----------
# 塔 1：x ↦ ω·x。从 1 出发迭代：ω, ω², ω³, … sup = ω^ω = 第一个不动点
t = nat(1); tower1 = ON[t]
for _ in 1:5
    global t
    t = omul(omega(), t); push!(tower1, t)
end
@assert tower1[2] == omega() && tower1[3] == wexp(nat(2)) && tower1[6] == wexp(nat(5))
@assert all(olt(tower1[k], tower1[k+1]) for k in 1:5)
# 塔顶验证 ω·ω^ω = ω^ω（1+ω = ω 在指数层吞并——不动点实弹）
@assert omul(omega(), wexp(omega())) == wexp(omega())
println("ω·x 塔：1 ↦ ω ↦ ω² ↦ … ↦ ω⁵，ω·ω^ω = ω^ω（不动点 ✓）")

# 塔 2：x ↦ ω^x。1 ↦ ω ↦ ω^ω ↦ …，sup = ε₀（推论 1.11）
e = nat(1); tower2 = ON[e]
for _ in 1:4
    global e
    e = wexp(e); push!(tower2, e)
end
@assert all(olt(tower2[k], tower2[k+1]) for k in 1:4)
println("ω^x 塔：1 ↦ ω ↦ ω^ω ↦ ω^ω^ω ↦ …，sup = ε₀ = ω^ε₀（73 章的发射台）")

# ---------- 自然列表（定义 1.71）：贪心取最小的现场生成 ----------
# 有限序数集 A（以尺寸给出）——自然列表 = 反复取最小；
# 雪崩赋名次：x ↦ ot(x∩A) = x 之前 A 里的元素个数 = 位次。
function natural_list(A::Vector{Int})
    remaining, out = sort(unique(A)), Int[]
    while !isempty(remaining)
        push!(out, remaining[1])
        remaining = remaining[2:end]
    end
    out
end
rank_in(x::Int, L::Vector{Int}) = count(y -> y < x, L)

A = [5, 1, 3, 0, 3, 9, 2]
L = natural_list(A)
@assert L == [0, 1, 2, 3, 5, 9]                    # 贪心 = 升序（引理 1.14）
@assert all(rank_in(L[i], L) == i - 1 for i in eachindex(L))   # 名次 = 位次
@assert natural_list([7, 7, 7]) == [7]             # 去重：集合语义
println("自然列表 {5,1,3,0,9,2} = ", L, "，名次恒等于位次 ✓（雪崩映射）")

println("END ====")
