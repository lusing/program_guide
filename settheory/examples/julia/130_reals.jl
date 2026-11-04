# 第 130 章 Julia：魔法公式的迭代与往复法（back-and-forth）。
# ① 书 3.5.2 的公式 q = p − (p²−2)/(p+2) 作为迭代：从下方单调爬向 √2；
# ② 往复法（书 3.4.15-3.4.17）：在 (ℚ, <) 与（二进有理数, <）之间
#    逐步构造保序双射——每一步都是"局部同构"的扩张（扩张引理的执行）。
println("==== 130 reals")

# ① 魔法公式迭代：p_{k+1} = p_k − (p_k²−2)/(p_k+2)，p₀ = 1
magic(p) = p - (p * p - 2) / (p + 2)
p = big(1) // 1
seq = [p]
for _ in 1:40
    global p = magic(p)
    push!(seq, p)
end
@assert all(seq[i] < seq[i+1] for i in 1:40)          # A 内单调上升
@assert all(q * q < 2 for q in seq)                   # 永不越界（精确判定）
errs = [abs(float(q * q - 2)) for q in seq]
@assert all(errs[i+1] < 0.23 * errs[i] for i in 1:30) # 线性收敛，速率 sup|g'| = 2/(2+√2)² ≈ 0.1716（首步 2/9）
@assert abs(float(seq[end] * seq[end]) - 2) < 1e-8
println("magic iteration: monotone from below, squares -> 2, rate < 0.2: OK")

# ② 往复法：ℚ ↔ 二进有理数 D = {k/2^m}（两边都是无端点稠密可数线序）
qs = Rational{BigInt}[]                               # ℚ 的 zigzag 枚举
for d in 2:40, k in 0:d
    if gcd(k, d) == 1
        push!(qs, k // big(d), -k // big(d))
    end
end
unique_q = unique(qs)
ds = Rational{BigInt}[]                               # 二进有理数枚举
for m in 0:8, k in -50:50
    push!(ds, k // big(2)^m)
end
unique_d = unique(ds)

SENT_LO, SENT_HI = -(big(10)^8) // 1, big(10)^8 // 1   # 注意 (−10)^8 是正数！

mutable struct LocalIso
    dom::Vector{Rational{BigInt}}                     # ℚ 侧
    ran::Vector{Rational{BigInt}}                     # D 侧
end

function is_partial_iso(h)                            # 局部同构（书 3.4.16）
    n = length(h.dom)
    length(unique(h.dom)) == n && length(unique(h.ran)) == n || return false
    for i in 1:n, j in 1:n
        (h.dom[i] < h.dom[j]) != (h.ran[i] < h.ran[j]) && return false
        h.dom[i] == h.dom[j] && h.ran[i] != h.ran[j] && return false
    end
    true
end

function bounds(vec, x)                               # x 在 vec 中的左右邻居
    lo, hi = SENT_LO, SENT_HI
    for v in vec
        v < x && v > lo && (lo = v)
        v > x && v < hi && (hi = v)
    end
    (lo, hi)
end

# 扩张引理（书 3.4.17）：稠密 + 无端点保证空隙里总找得到未用的伙伴
function extend!(h, p, side)
    if side == :q2d                                   # 把 p（ℚ 侧）加进 dom
        lo, hi = bounds(h.dom, p)
        ylo = lo == SENT_LO ? SENT_LO : h.ran[findfirst(==(lo), h.dom)]
        yhi = hi == SENT_HI ? SENT_HI : h.ran[findfirst(==(hi), h.dom)]
        c = findfirst(c -> ylo < c < yhi && !(c in h.ran), unique_d)
        c === nothing && return false
        push!(h.dom, p); push!(h.ran, unique_d[c])
    else                                              # 把 p（D 侧）加进 ran
        lo, hi = bounds(h.ran, p)
        xlo = lo == SENT_LO ? SENT_LO : h.dom[findfirst(==(lo), h.ran)]
        xhi = hi == SENT_HI ? SENT_HI : h.dom[findfirst(==(hi), h.ran)]
        c = findfirst(c -> xlo < c < xhi && !(c in h.dom), unique_q)
        c === nothing && return false
        push!(h.dom, unique_q[c]); push!(h.ran, p)
    end
    true
end

h = LocalIso(Rational{BigInt}[0 // 1], Rational{BigInt}[0 // 1])   # h₀ = {(0,0)}
for k in 1:120
    if isodd(k)                                       # 奇数步拉 ℚ 侧，偶数步拉 D 侧
        pk = unique_q[k]
        pk in h.dom || extend!(h, pk, :q2d) || break
    else
        qk = unique_d[k]
        qk in h.ran || extend!(h, qk, :d2q) || break
    end
    @assert is_partial_iso(h)
end
@assert length(h.dom) >= 45
println("back-and-forth: 45+ steps, partial isomorphism preserved: OK")
println("END ====")
