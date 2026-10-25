# 第 92 章 · 布尔值模型（冯琦第二卷 §3.5）——Julia 通道
# 与 Python 同一组检查：Ba1-Ba6 穷举、布尔值算法与定理 3.23、
# V^B 两层度量账（引理 3.75(1)）、柱超滤子 Los 换算与广义分配律。
println("==== 92")

# ---------- 一、幂集代数 B = 2^2（定义 3.38） ----------

const TOP = (true, true)
const BOT = (false, false)
bjoin(a, b) = (a[1] || b[1], a[2] || b[2])
bmeet(a, b) = (a[1] && b[1], a[2] && b[2])
bcompl(a) = (!a[1], !a[2])
bimp(a, b) = bjoin(bcompl(a), b)

B4 = [(x, y) for x in (false, true) for y in (false, true)]

for a in B4
    @assert bmeet(a, bcompl(a)) == BOT && bjoin(a, bcompl(a)) == TOP  # Ba5
    for b in B4
        @assert bjoin(a, b) == bjoin(b, a) && bmeet(a, b) == bmeet(b, a)
        @assert bjoin(a, BOT) == a && bmeet(a, TOP) == a
        for c in B4
            @assert bmeet(a, bjoin(b, c)) == bjoin(bmeet(a, b), bmeet(a, c))
            @assert bmeet(bmeet(a, b), c) == bmeet(a, bmeet(b, c))
            @assert bjoin(a, bmeet(a, b)) == a
        end
    end
end
println("幂集代数 2^2：Ba1-Ba6 全部穷举验证 OK")

# ---------- 二、布尔值算法与基本布尔值不等式 ----------

# 公式：Symbol 或 (op, f, g)
function bval(f, v)
    f isa Symbol && return (f === :p ? v : bcompl(v))
    f[1] === :~ && return bcompl(bval(f[2], v))
    op, g, h = f
    op === :&  && return bmeet(bval(g, v), bval(h, v))
    op === :|  && return bjoin(bval(g, v), bval(h, v))
    op === :imp && return bimp(bval(g, v), bval(h, v))
    op === :iff && return bmeet(bimp(bval(g, v), bval(h, v)),
                                bimp(bval(h, v), bval(g, v)))
    error("bad op")
end

FORMULAS = [:p, :q, (:~, :p), (:&, :p, :q), (:|, :p, :q), (:imp, :p, :q),
            (:iff, :p, :q), (:imp, :p, :p), (:imp, (:&, :p, (:~, :p)), :q)]
for f in FORMULAS, v in B4
    x = bval(f, v)
    @assert bmeet(x, bcompl(x)) == BOT              # 3.23(1)
    for u in B4
        u == BOT && continue
        @assert bjoin(bmeet(u, x), x) == x           # u∧φ ≤ φ
        @assert bjoin(bmeet(u, x), u) == u           # u∧φ ≤ u
        @assert bjoin(bmeet(u, x), bmeet(u, bcompl(x))) == u  # 分配律
    end
end
@assert bval((:imp, :p, :p), BOT) == TOP
@assert bval((:imp, (:&, :p, (:~, :p)), :q), B4[1]) == TOP
println("布尔值算法：矛盾值为 0、同一律与爆炸律值为 1 OK")

# ---------- 三、V^B 两层度量账（引理 3.75(1) 影子） ----------

mem1(x, s) = s(x)
eq1(t, s) = bmeet(bimp(t(0), s(0)), bimp(s(0), t(0)))  # 单坐标补集点相等
gen_diag(u) = (k -> k == 0 ? u : BOT)

u0 = (true, false)
@assert mem1(0, gen_diag(u0)) == u0              # [[u in G]] = u
@assert eq1(gen_diag(u0), gen_diag(u0)) == TOP   # [[t = t]] = 1
println("V^B 两层账：[[u in G]] = u（引理 3.75(1)）、[[t=t]]=1 OK")

# ---------- 四、柱超滤子与广义分配律 ----------

U0(a) = a[1] === true
for a in B4
    @assert U0(bcompl(a)) == !U0(a)
    for b in B4
        @assert U0(bmeet(a, b)) == (U0(a) && U0(b))
        U0(a) && @assert U0(bimp(a, b)) == U0(b)
    end
end
println("柱超滤子 U0：交/补/蕴含的 Los 换算（引理 3.72 原子）OK")

# 广义分配律（定义 3.68）：2x2 矩阵穷举
#   ∧_i Σ_j a_ij = Σ_{f∈2^2} ∧_i a_{i,f(i)}
COORD = [(x, y) for x in (false, true) for y in (false, true)]
for b00 in COORD, b01 in COORD, b10 in COORD, b11 in COORD
    lhs = bmeet(bjoin(b00, b01), bjoin(b10, b11))
    rhs = bjoin(bjoin(bmeet(b00, b10), bmeet(b00, b11)),
                bjoin(bmeet(b01, b10), bmeet(b01, b11)))
    @assert lhs == rhs
end
println("广义分配律（定义 3.68）：2x2 全部 256 个矩阵穷举 OK")

println("END ====")
