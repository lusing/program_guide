# 第 74 章：基数：和、积与典型秩序（冯琦 §1.9）——Julia 通道
# 序数乘积空间的典型秩序（定义 1.97）与 Gödel 编码（定义 1.98）的
# 可执行化：gsq(μ) = "max < μ 的序对层数"（方块=前段，定理 1.92）、
# Γ(α,β) = 典型序下的名次；ℕ² ≅ ℕ 的配对双射全网格往返验证
# （ℵ₀·ℵ₀ = ℵ₀ 的构造性身影）；ℵ 序列符号演算器 + 基数算术 max 规则
# 引擎（推论 1.13）+ aleph 不动点链（定理 1.91(2) 的程序版）。
println("==== 74")

# ---------- ON：ε₀ 以内的序数 = [(指数, 系数), …] 指数递降 ----------
struct ON
    terms::Vector{Tuple{ON,Int}}
end

oz() = ON(Tuple{ON,Int}[])
nat(n::Int) = n <= 0 ? oz() : ON([(oz(), n)])
wexp(e::ON) = ON([(e, 1)])
omega() = wexp(nat(1))

Base.:(==)(a::ON, b::ON) = a.terms == b.terms
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

function omul(a::ON, b::ON)
    isempty(a.terms) && return oz()
    isempty(b.terms) && return oz()
    b == nat(1) && return ON(a.terms)
    a == nat(1) && return ON(b.terms)
    (ea, ca), (eb, cb) = a.terms[1], b.terms[1]
    if length(a.terms) == 1 && ea == oz() && length(b.terms) == 1 && eb == oz()
        return ON([(oz(), ca * cb)])
    end
    restb = tail(b)
    if length(a.terms) == 1 && ea == oz()
        return oadd(ON([(eb, cb)]), omul(a, restb))
    end
    if eb == oz()
        r = oz()
        for _ in 1:cb; r = oadd(r, a); end
        return r
    end
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

# ---------- 典型秩序（定义 1.97）与方块层数 gsq（定理 1.92） ----------
# 典型序：(α,β) < (γ,δ) ⟺ max<max ∨ (max 同 ∧ α<γ) ∨ (max 同 ∧ α=γ ∧ β<δ)
# gsq(μ) = 集合 {(ξ,η) | max{ξ,η} < μ} = μ×μ 在典型序下的序型
#   = "第 (0,μ) 名"——方块恰是前段（定理 1.92 的序型读法）。
# 闭式（由壳层求和 gsq(μ+1) = gsq(μ)+2μ+1 归纳得出）：
gsq(m::Int) = nat(m * m)                                  # 有限：m²
gsq_omega() = omega()                                     # gsq(ω) = ω ★坍缩点
gsq_omega_plus(n::Int) = oadd(omul(omega(), nat(2n + 1)), nat(n * n))  # ω·(2n+1)+n²

println("gsq：有限段 m²、gsq(ω) = ω（坍缩点 ★）、gsq(ω+n) = ω·(2n+1)+n²")
println("  gsq(ω+1) = ", show_on(gsq_omega_plus(1)), "、gsq(ω+5) = ", show_on(gsq_omega_plus(5)),
        " ——离开初始序数就涨（ℵ·ℵ=ℵ 只钉在初始序数上）")

# ---------- Gödel 编码 Γ（定义 1.98）：典型序下的名次 ----------
# μ = max{α,β} 时：Γ(α,β) = gsq(μ) + 壳内偏移
#   壳内次序：(0,μ), (1,μ), …, (μ−1,μ), (μ,0), (μ,1), …, (μ,μ)
function gpair(a::Int, b::Int)
    m = max(a, b)
    if a < m return m * m + a
    elseif b < m return m * m + m + b
    else return m * m + 2 * m end
end

# 逆映射：名次 → 序对（双射的另一半）
function gunpair(p::Int)
    m = isqrt(p)
    t = p - m * m
    if t < m return (t, m)
    elseif t < 2m return (m, t - m)
    else return (m, m) end
end

# 双射全网格往返：0..1999 的名次解码回原对；12×12 网格正向对拍
for p in 0:1999
    @assert gpair(gunpair(p)...) == p
end
seen = Set{Int}()
for a in 0:11, b in 0:11
    push!(seen, gpair(a, b))
end
@assert length(seen) == 144                    # 单射（网格内无碰撞）
# "方块=前段"（定理 1.92）逐格对拍：m×m 网格的 Γ 名次恰占满 0..m²−1
for m in 1:12
    @assert sort(vec([gpair(a, b) for a in 0:m-1, b in 0:m-1])) == collect(0:m*m-1)
end
println("Γ 配对：0..1999 往返恒等 ✓、12×12 网格单射 ✓、m×m 方块=前段 0..m²−1（m≤12）✓")
println("  样例：Γ(2,5) = $(gpair(2,5))、Γ(5,2) = $(gpair(5,2))、Γ(3,3) = $(gpair(3,3))")

# 序数版 Γ（有限截面）：gsq(μ) + 壳内偏移
#   α < μ=β 时偏移 α；α=μ > β 时偏移 μ+β；(μ,μ) 时偏移 2μ
function gpair_on(a::ON, b::ON)
    af = isempty(a.terms) || (length(a.terms) == 1 && a.terms[1][1] == oz())
    bf = isempty(b.terms) || (length(b.terms) == 1 && b.terms[1][1] == oz())
    (af && bf) || error("gpair_on: 演示范围为有限序数对")
    an = isempty(a.terms) ? 0 : a.terms[1][2]
    bn = isempty(b.terms) ? 0 : b.terms[1][2]
    nat(gpair(an, bn))
end

@assert gpair_on(nat(3), nat(7)) == nat(52)          # Γ(3,7) = 49+3
@assert gpair_on(nat(7), nat(3)) == nat(59)          # Γ(7,3) = 49+7+3
@assert gpair_on(nat(7), nat(7)) == nat(63)          # Γ(7,7) = 49+14
println("Γ 序数版（有限截面）：Γ(3,7)=52、Γ(7,3)=59、Γ(7,7)=63 ✓")

# ---------- ℵ 序列符号演算器（定义 1.93）与 max 规则（推论 1.13） ----------
# 符号基数：FCard(n) 有限；Aleph(α) 第 α 个无穷基数（α 为 ON）
abstract type SCard end
struct FCard <: SCard n::Int end
struct Aleph <: SCard α::ON end

Base.:(==)(a::FCard, b::FCard) = a.n == b.n
Base.:(==)(a::Aleph, b::Aleph) = a.α == b.α
Base.:(==)(::SCard, ::SCard) = false

show_sc(k::FCard) = string(k.n)
function show_sc(k::Aleph)
    k.α == omega() && return "ℵ_ω"
    isempty(k.α.terms) && return "ℵ_0"
    (length(k.α.terms) == 1 && k.α.terms[1][1] == oz()) && return "ℵ_$(k.α.terms[1][2])"
    "ℵ_(" * show_on(k.α) * ")"
end

is_inf(::FCard) = false
is_inf(::Aleph) = true

# 大小比较：有限 < 无穷；Aleph 按指标比
function sclt(a::SCard, b::SCard)
    is_inf(a) && !is_inf(b) && return false
    !is_inf(a) && is_inf(b) && return true
    !is_inf(a) && !is_inf(b) && return a.n < b.n
    olt((a::Aleph).α, (b::Aleph).α)
end

# 推论 1.13：κ+λ = κ·λ = max{κ,λ}（κ,λ 无穷）；有限退化到普通算术
function cadd(a::SCard, b::SCard)
    (!is_inf(a) && !is_inf(b)) && return FCard(a.n + b.n)
    sclt(a, b) ? b : a
end
function cmul(a::SCard, b::SCard)
    (!is_inf(a) && !is_inf(b)) && return FCard(a.n * b.n)
    sclt(a, b) ? b : a
end

t = [FCard(3), FCard(7), Aleph(oz()), Aleph(nat(1)), Aleph(nat(2)), Aleph(omega())]
println("max 规则引擎（推论 1.13）样例：")
println("  ℵ₂ + ℵ₀ = ", show_sc(cadd(Aleph(nat(2)), Aleph(oz()))))
println("  ℵ_ω · ℵ₃ = ", show_sc(cmul(Aleph(omega()), Aleph(nat(3)))))
println("  (ℵ₂ + ℵ₁) · ℵ₀ = ", show_sc(cmul(cadd(Aleph(nat(2)), Aleph(nat(1))), Aleph(oz()))))
println("  有限退化：3 + 7 = ", show_sc(cadd(FCard(3), FCard(7))), "、3 · 7 = ", show_sc(cmul(FCard(3), FCard(7))))
@assert cadd(Aleph(nat(2)), Aleph(oz())) == Aleph(nat(2))
@assert cmul(Aleph(omega()), Aleph(nat(3))) == Aleph(omega())
@assert cmul(cadd(Aleph(nat(2)), Aleph(nat(1))), Aleph(oz())) == Aleph(nat(2))

# ---------- aleph 不动点链（定理 1.91(2) 的程序版） ----------
# κ₀ = ℵ₀（= ℵ_ω 的种子），κ_{n+1} = ℵ_{κ_n}：符号层嵌套展示；
# 注意 κ₁ = ℵ_{ℵ₀} = ℵ_ω（ℵ₀ 作为序数就是 ω——初始序数的红利）
show_chain(k::Int) = k == 0 ? "ℵ₀" : "ℵ_{$(show_chain(k-1))}"
for n in 0:4
    note = n == 1 ? "  = ℵ_ω（第一个奇异基数，例 1.33）" : ""
    println("  κ_$n = ", show_chain(n), note)
end
println("  …sup_n κ_n = λ 满足 ℵ_λ = λ——任意大的 aleph 不动点（定理 1.91(2)）")

println("END ====")
