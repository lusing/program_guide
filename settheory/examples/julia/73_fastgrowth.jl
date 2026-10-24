# 第 73 章：快速增长数论函数层次（冯琦 §1.8.4）
# ε₀ 以内的康托尔范式演算器（沿用 72 章 ON 表示）+ 基本序列（定义 1.83
# 四条款全实现）+ 快速增长层次 F_α（定义 1.84：F_ω(3) 已冲出 BigInt 的
# 现场演示）+ 古德斯坦剧场（定义 1.86/1.87：遗传展开 HB 与影子序数是
# 同一棵树的两种读法——换基不改树，−1 砍树，定理 1.82 的机理裸奔）。
println("==== 73")

# ---------- ON：ε₀ 以内的序数 = [(指数, 系数), …] 指数递降 ----------
struct ON
    terms::Vector{Tuple{ON,Int}}
end

oz() = ON(Tuple{ON,Int}[])
nat(n::Int) = n <= 0 ? oz() : ON([(oz(), n)])
wexp(e::ON) = ON([(e, 1)])
omega() = wexp(nat(1))

Base.:(==)(a::ON, b::ON) = a.terms == b.terms
Base.hash(a::ON, h::UInt) = hash(a.terms, h)
tail(a::ON) = ON(a.terms[2:end])

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

function show_on(a::ON)
    parts = String[]
    for (e, c) in a.terms
        es = e == oz() ? "0" : (e == nat(1) ? "" : "(" * show_on(e) * ")")
        push!(parts, c == 1 ? "ω$es" : "ω$es·$c")
    end
    isempty(parts) && return "0"
    join(parts, "+")
end

# ---------- 后继/极限判定与前驱 ----------
is_limit(a::ON) = !isempty(a.terms) && a.terms[end][1] != oz()   # 末项指数非零
function opred(a::ON)                       # a 后继序数 → 前驱
    ts = copy(a.terms)
    (e, c) = ts[end]
    @assert e == oz() "opred: 只接受后继序数"
    if c == 1 pop!(ts) else ts[end] = (e, c - 1) end
    ON(ts)
end

# ---------- 基本序列（定义 1.83：四条款 + ε₀ 特例） ----------
# α 极限且 α < ε₀（CNF 段）：α(n) 严格递增、sup = α（引理 1.22）
function fs(a::ON, n::Int)
    @assert is_limit(a) "fs: 只对极限序数取基本序列"
    m = length(a.terms)
    (βm, km) = a.terms[end]
    if m > 1
        # (d) m>1：头部保留，末项系数减一后接 (ω^βm)(n)
        head = km > 1 ? oadd(ON(a.terms[1:end-1]), ON([(βm, km - 1)])) :
                        ON(a.terms[1:end-1])
        return oadd(head, fs(ON([(βm, 1)]), n))
    end
    (β, k) = a.terms[1]
    if k > 1
        # (c) m=1, k>1：α(n) = ω^β·(k−1) + (ω^β)(n)
        return oadd(ON([(β, k - 1)]), fs(ON([(β, 1)]), n))
    end
    if is_limit(β)
        # (b) m=1, k=1, β 极限：α(n) = ω^(β(n))
        return wexp(fs(β, n))
    end
    # (a) m=1, k=1, β=γ+1：α(n) = ω^γ·n（含 ω(n) = n 的 γ=0 特例）
    γ = opred(β)
    return n == 0 ? oz() : ON([(γ, n)])
end

# ε₀ 自身的基本序列（定义 1.83(3)）：ε₀(0) = 0，ε₀(n+1) = ω^(ε₀(n))
fs_eps0(n::Int) = n == 0 ? oz() : wexp(fs_eps0(n - 1))

# ---------- 基本序列验收（引理 1.22 的样本段） ----------
samples = [omega(), wexp(nat(2)), wexp(omega()), wexp(wexp(omega())),
           oadd(wexp(omega()), ON([(nat(3), 2)])),   # ω^ω + ω³·2
           oadd(wexp(wexp(omega())), wexp(nat(2)))]  # ω^ω^ω + ω²
for a in samples
    for n in 0:5
        olt(fs(a, n), fs(a, n + 1)) || error("基本序列不严格递增")
        olt(fs(a, n + 1), a) || error("基本序列越过上确界")
    end
end
println("基本序列：ω²(n)=ω·n、ω^ω(n)=ω^n、(ω^ω+ω³·2)(n)=ω^ω+ω³+ω²·n 等 $(length(samples)) 条样本")
println("  严格递增且不越界全验 ✓；ε₀ 链：", show_on(fs_eps0(3)), " < ", show_on(fs_eps0(4)), " ↗ ε₀")
# 收敛性抽查：ω³ 之下的 β = ω²·7+5 被 ω²(n) 在第 8 项赶上
@assert olt(oadd(ON([(nat(2), 7)]), nat(5)), fs(wexp(nat(3)), 8))

# ---------- 快速增长层次（定义 1.84） ----------
# F₀/F₁ 走闭式（F₀(n)=n+1、F₁(n)=2n——定义的字面迭代 F₁(x)=F₀ˣ(x) 是
# O(x) 步，F₂(50) 的中间值已达 10¹⁶，字面迭代物理不可行）；闭式与字面
# 定义在小范围逐点对拍，保证闭式没有偷换定义。
function F_literal(a::ON, n::BigInt)            # 定义 1.84 的字面实现
    isempty(a.terms) && return n + 1                  # F₀(n) = n+1
    if !is_limit(a)                                   # F_{β+1}(n) = F_βⁿ(n)
        β = opred(a)
        x = n
        for _ in 1:n; x = F_literal(β, x); end
        return x
    end
    F_literal(fs(a, Int(n)), n)                       # F_λ(n) = F_{λ(n)}(n)
end

function F(a::ON, n::BigInt)
    isempty(a.terms) && return n + 1
    a == nat(1) && return 2n                          # F₁ 闭式
    if !is_limit(a)
        β = opred(a)
        x = n
        for _ in 1:n; x = F(β, x); end
        return x
    end
    F(fs(a, Int(n)), n)
end

# 对拍：F₀..F₂ 在 n=1..8、F₃ 与 F_ω 在 n=1..2（F₃(3) 本身已物理不可行，
# 见下文 F_ω(3) 的计数）逐点一致
for k in 0:2, n in BigInt(1):8
    @assert F(nat(k), n) == F_literal(nat(k), n)
end
for n in BigInt(1):2
    @assert F(nat(3), n) == F_literal(nat(3), n)
    @assert F(omega(), n) == F_literal(omega(), n)
end
println("F 与 F_literal 对拍：F₀..F₂（n≤8）、F₃/F_ω（n≤2）完全一致 ✓")

# 值表：F₀(n)=n+1、F₁(n)=2n、F₂(n)=n·2ⁿ——三个解析式先验后验
for n in BigInt(1):6
    @assert F(oz(), n) == n + 1
    @assert F(nat(1), n) == 2n
    @assert F(nat(2), n) == n * big(2)^n
end
@assert F(nat(3), BigInt(1)) == 2                     # F₃(1) = F₂(1) = 2
@assert F(nat(3), BigInt(2)) == 2048                  # F₃(2) = F₂(F₂(2)) = F₂(8)
@assert F(omega(), BigInt(1)) == 2                    # F_ω(1) = F₁(1)
@assert F(omega(), BigInt(2)) == 8                    # F_ω(2) = F₂(2)
println("F₀(n)=n+1、F₁(n)=2n、F₂(n)=n·2ⁿ（n=1..6 全对）✓")
println("F₃(1)=2、F₃(2)=2048；F_ω(1)=2、F_ω(2)=8 ✓")

# F_ω(3) = F₃(3) = F₂(F₂(F₂(3)))：F₂(3)=24、F₂(24)=402653184，
# 最外层 F₂(402653184) = 402653184·2^402653184——约 1.2 亿位十进制数，
# BigInt 也装不下：层次在第三层就把"可计算"顶到物理边界
f224 = F(nat(2), BigInt(24))
@assert f224 == 402653184
digits_est = floor(Int, 402653184 * log10(2.0)) + 1
println("F_ω(3) = F₂($(f224)) = $(f224)·2^$(f224)，约 $digits_est 位——可定义而不可算（定理 1.81(1) 的张力）")

# <* 见证（定义 1.85 / 定理 1.81(2) 的有限截面）：
# F₀ 从 n=2 起被 F₁ 全灭；F₁ 从 n=5 起被 F₂ 全灭
@assert all(F(oz(), n) < F(nat(1), n) for n in BigInt(2):50)
@assert all(F(nat(1), n) < F(nat(2), n) for n in BigInt(5):50)
# 初等递归样本 n ↦ n³+n 从 n=7 起被 F₂ 全灭（定理 1.81(3) 的身影）
@assert all(n^3 + n < F(nat(2), n) for n in BigInt(7):50)
println("<* 见证：F₀<\\*F₁（n≥2）、F₁<\\*F₂（n≥5）、n³+n <\\* F₂（n≥7）✓")

# ---------- 古德斯坦剧场（定义 1.86/1.87、定理 1.82） ----------
# HB = 遗传展开树：[(指数HB, 系数)] —— 与 ON 同构但系数可达 b−1。
# 关键设计：树里不存基 b——换基 = 换读法，影子序数 = 同一棵树读成 ON。
struct HB
    terms::Vector{Tuple{HB,BigInt}}
end

function hb_of(b::BigInt, m::BigInt)::HB
    m == 0 && return HB(Tuple{HB,BigInt}[])
    m < b && return HB([(HB(Tuple{HB,BigInt}[]), m)])   # 原子常数（<b，不参与换基）
    e, p = 0, one(BigInt)                 # 贪心取最大幂 b^e ≤ m（m = b 自然落成 b¹·1）
    while p * b <= m; p *= b; e += 1; end
    k, r = divrem(m, p)                   # 0 < k < b：系数永不换基（定义 1.86 的 0<kᵢ<b）
    HB(vcat([(hb_of(b, BigInt(e)), k)], hb_of(b, r).terms))
end

function hb_eval(h::HB, b::BigInt)::BigInt     # 把树读成自然数（基 b）
    s = zero(BigInt)
    for (e, k) in h.terms
        s += b^hb_eval(e, b) * k
    end
    s
end

hb_to_on(h::HB) = ON([(hb_to_on(e), Int(k)) for (e, k) in h.terms])  # 读成序数

# 例 1.29：T₂(37) = 2^{2²+1}+2²+1；原子 2（= b 自身）的影子是 ω，
# 故影子 = ω^{ω^ω+1}+ω^ω+1（不是 ω^{ω²+1}——指数 2 是 b 不是常数）
t37 = hb_of(big(2), big(37))
@assert hb_eval(t37, big(2)) == 37
@assert hb_to_on(t37) == oadd(wexp(oadd(wexp(omega()), nat(1))),
                              oadd(wexp(omega()), nat(1)))
println("T₂(37) = 2^(2²+1)+2²+1 ✓（影子 ", show_on(hb_to_on(t37)), "）")

# 古德斯坦一步：树不变，读法 b ↦ b+1，再 −1，重新展开
function gstep(b::BigInt, m::BigInt)
    m == 0 && return (zero(BigInt), HB(Tuple{HB,BigInt}[]))
    t = hb_of(b, m)
    m2 = hb_eval(t, b + 1) - 1
    (m2, hb_of(b + 1, m2))
end

# G(3) 全程（例：五步归零）——数字原地踏步，影子一路下山
m, b = big(3), big(2)
chain, shadows = [m], ON[]
while m != 0
    push!(shadows, hb_to_on(hb_of(b, m)))
    global m, b
    m, t = gstep(b, m)
    b += 1
    push!(chain, m)
end
push!(shadows, oz())
@assert chain == [3, 3, 3, 2, 1, 0]
@assert all(olt(shadows[k+1], shadows[k]) for k in 1:length(shadows)-1)
println("G(3)：值链 ", chain, "（G(3)=5 步归零）")
println("  影子链 ", join(show_on.(shadows), " > "), " ——严格下降 ✓（定理 1.82 的刹车）")

# G(4) 前八步：数字爆炸与影子下降同框（例 1.30 的微型重演）
m, b = big(4), big(2)
vals, shs = [m], ON[]
for _ in 1:8
    push!(shs, hb_to_on(hb_of(b, m)))
    global m, b
    m, _ = gstep(b, m)
    b += 1
    push!(vals, m)
end
@assert vals[2] == 26 && vals[3] == 41 && vals[4] == 60      # 书载前段
@assert all(olt(shs[k+1], shs[k]) for k in 1:length(shs)-1)
@assert hb_to_on(hb_of(big(2), big(4))) == wexp(omega())     # α₀ = ω^ω
println("G(4) 前八步值链 ", vals, " ——一路狂涨")
println("  影子：ω^ω > ", show_on(shs[2]), " > ", show_on(shs[3]), " > … 一路下降 ✓")

println("END ====")
