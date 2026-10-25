# 第 84 章 · KP 与可采纳集合（冯琦第二卷 §1.1）——Julia 通道
# 实验：Cantor 配对双向解码、有限累积层次的 KP⁻ 公理、HF 不含 ω、
# Δ₀ 公式在 V₃ 与 V₄ 之间逐环境逐公式绝对。
println("==== 84")

# ---------- 一、定义 1.22 的 Cantor 配对 ----------
# J(m,n)=T(m+n)+n，T(s)=s(s+1)/2。解码先由 8k+1 的整数平方根恢复对角线。
J(m, n) = (m + n) * (m + n + 1) ÷ 2 + n

function unpair(k)
    r = isqrt(8k + 1)
    s = (r - 1) ÷ 2
    n = k - s * (s + 1) ÷ 2
    (s - n, n)
end

codes = Set{Int}()
for m in 0:30, n in 0:30
    k = J(m, n)
    @assert unpair(k) == (m, n)
    @assert !(k in codes)
    push!(codes, k)
end
# 定义 1.22 的变元码 J(5,n+11) 与常元码 J(7,n+11) 永不混淆。
@assert all(J(5, n + 11) != J(7, m + 11) for n in 0:20, m in 0:20)
println("Cantor 配对：31×31 个坐标逐一解码回原对，变元码与常元码互异 ✓")

# ---------- 二、彻底有限集的规范化表示 ----------
# HS 的元素只构造、不修改；构造时按 (rank, repr) 排序，故相同外延有相同
# 内部表示、相等与哈希。这样才能把「集合的集合」直接交给 Julia 的 Set。
struct HS
    elems::Vector{HS}
end

rank(x::HS) = isempty(x.elems) ? 0 : 1 + maximum(rank(y) for y in x.elems)
function Base.show(io::IO, x::HS)
    print(io, "{", join((string(y) for y in x.elems), ","), "}")
end

function hs(xs::HS...)
    ys = collect(xs)
    sort!(ys, by = y -> (rank(y), string(y)))
    unique!(ys)
    HS(ys)
end
Base.iterate(x::HS, st...) = iterate(x.elems, st...)
Base.length(x::HS) = length(x.elems)
Base.isempty(x::HS) = isempty(x.elems)
Base.:(==)(x::HS, y::HS) = x.elems == y.elems
Base.hash(x::HS, h::UInt) = hash(x.elems, h)

emptyHS = hs()
pairset(x, y) = hs(x, y)
unionHS(x) = hs((y for z in x for y in z)...)

function powersetHS(v)
    a = collect(v)
    out = Set{HS}()
    for mask in 0:(1 << length(a)) - 1
        push!(out, hs((a[i] for i in eachindex(a) if (mask >> (i - 1)) & 1 == 1)...))
    end
    out
end

# V₀=∅，V_{n+1}=𝒫(V_n)（定义 1.21）。
function levels(n)
    vs = [Set{HS}()]
    for _ in 1:n
        push!(vs, powersetHS(vs[end]))
    end
    vs
end

V = levels(4)
@assert length.(V) == [0, 1, 2, 4, 16]
@assert all(rank(x) < n for n in 1:4 for x in V[n+1])
# 每层传递；对并集、任意子集（因而 Δ₀-分离）封闭。
for n in 1:4
    @assert all(y in V[n+1] for x in V[n+1] for y in x)
    @assert all(unionHS(x) in V[n+1] for x in V[n+1])
    @assert all(s in V[n+1] for x in V[n+1] for s in powersetHS(x))
end
# 固定 V₃ 内配对可能越层（两个秩 2 的元素配对秩 3）；放进 V₄ 后恢复。
# HF 是所有有限层的并，任给两个彻底有限集，取较大层再升一层即可配对。
@assert all(pairset(x, y) in V[5] for x in V[4] for y in V[4])
println("V₀..V₄：基数 0,1,2,4,16；传递/并集/子集封闭逐元素穷举 ✓")

# ---------- 三、ω 不属于 HF ----------
function von(n)
    x = emptyHS
    for _ in 1:n
        x = hs((collect(x)..., x)...)
    end
    x
end
@assert all(rank(von(n)) == n for n in 0:8)
omegaPrefix = hs((von(n) for n in 0:4)...)
@assert rank(omegaPrefix) == 5
# 无穷 ω 的秩是 ω，不可能落在任何有限层；这里验证其每个有限前段
# 都把秩再推高一层，而任意有限候选层最终必被越过。
@assert all(!(omegaPrefix in V[n+1]) for n in 0:4)
println("von Neumann 自然数秩=n；ω 的有限前段秩持续上升，故 ω∉V_ω=HF ✓")

# ---------- 四、Δ₀ 绝对性的有限穷举 ----------
# 公式用元组表示；(:ball,i,j,p) 即 ∀v_i∈v_j,p。
eval0(M, env, f) = begin
    tag = f[1]
    if tag == :mem
        env[f[2]] in env[f[3]]
    elseif tag == :eq
        env[f[2]] == env[f[3]]
    elseif tag == :neg
        !eval0(M, env, f[2])
    elseif tag == :and
        eval0(M, env, f[2]) && eval0(M, env, f[3])
    elseif tag == :ball
        i, j, p = f[2], f[3], f[4]
        all(x -> begin
            env′ = copy(env); env′[i] = x
            eval0(M, env′, p)
        end, (x for x in M if x in env[j]))
    else
        error("unknown formula")
    end
end

small = V[4]       # V₃：传递的小载体
large = V[5]       # V₄：包含它的外宇宙
atoms = [(:mem, 0, 1), (:eq, 0, 1), (:mem, 1, 0)]
forms = vcat(atoms,
    [(:neg, p) for p in atoms],
    [(:and, p, q) for p in atoms for q in atoms],
    [(:ball, 0, 1, (:mem, 0, 1)),
     (:ball, 0, 1, (:neg, (:mem, 0, 1))),
     (:ball, 0, 1, (:ball, 0, 0, (:eq, 0, 0)))])
checks = 0
for a in small, b in small, p in forms
    env = Dict(0 => a, 1 => b)
    @assert eval0(small, env, p) == eval0(large, env, p)
    global checks += 1
end
println("Δ₀ 绝对性：V₃/V₄ 间 $(length(forms)) 个公式×全部 $(length(small)^2) 个环境，共 $checks 次一致 ✓")
println("END ====")
