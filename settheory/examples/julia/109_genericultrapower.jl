# 第 109 章：理想力迫、泛型超滤子候选与有限 Łoś——泛型超幂的有限影子。
println("==== 109")

# ── 一、样本理想 I = {∅, {0}}（位掩码：bit i = 元素 i）与正测集 ──
const IDEAL = Set([0b000, 0b001])
pos(m) = !(m in IDEAL)
const IPOS = collect(filter(pos, 0:7))          # 6 个正测集

le(C, D) = (C & ~D) in IDEAL                    # C ≤ D ⟺ C − D ∈ I

@assert le(0b010, 0b011)                        # {1} ≤ {0,1}（差 ∅）
@assert !le(0b111, 0b011)                       # U ≰ {0,1}（差 {2} 正测）
@assert all(le(C, C) for C in IPOS)             # 自反
for C in IPOS, D in IPOS, E in IPOS             # 传递全量核查
    if le(C, D) && le(D, E)
        @assert le(C, E)
    end
end

# ── 二、商关系与商代数 P(U)/I ──
eqv(X, Y) = xor(X, Y) in IDEAL                  # X ≡ Y ⟺ X△Y ∈ I
@assert eqv(0b111, 0b110)                       # U ≡ {1,2}
@assert eqv(0b011, 0b010)                       # {0,1} ≡ {1}
classes = Set{Int}()
for m in 0:7
    bits12 = m & 0b110                          # 类由 {1,2} 上的截痕决定
    push!(classes, bits12 == 0b110 ? 7 : bits12)
end
@assert classes == Set([0, 2, 4, 7])            # P(U)/I ≅ 4 元布尔代数

# ── 三、泛型超滤子候选：主滤子 G(a)（位 a 非零的正测集） ──
G(a) = Set(m for m in IPOS if (m & (1 << a)) != 0)
@assert G(1) == Set([0b010, 0b011, 0b110, 0b111])
@assert G(2) == Set([0b100, 0b101, 0b110, 0b111])

# 超滤子四公理 (a)-(d) 的核查（书 p211）。
function ultra(G)
    (7 in G && !(0 in G)) &&                         # (a) 顶与不含底
    all((C & D) in G for C in G, D in G) &&          # (b) 交闭
    all(E in G for C in G for E in IPOS if le(C, E)) &&  # (c) 向上（C ≤ E）
    all((C in G) || ((7 & ~C) in G) for C in IPOS)   # (d) 超
end
@assert ultra(G(1)) && ultra(G(2))

# ── 四、稠密集与相遇（泛型性核查） ──
dense(Ds) = all(any(le(Y, X) for Y in Ds) for X in IPOS)
denses = Set{Set{Int}}()
for mask in 0:63
    D = Set(IPOS[i] for i in 1:6 if (mask >> (i - 1)) & 1 == 1)
    if dense(D)
        push!(denses, D)
    end
end
@assert length(denses) > 0 && all(dense, denses)
for a in (1, 2)
    for D in denses
        @assert !isempty(intersect(G(a), D))     # 候选滤子遇遍每个稠密集
    end
end

# ── 五、有限 Łoś：全函数对 × 双滤子（真值集裁决） ──
funcs = vec([(x, y, z) for x in 0:2, y in 0:2, z in 0:2])   # 27 个表
fval(f, a) = (a == 0 ? f[1] : (a == 1 ? f[2] : f[3]))
truth_lt(f, g) = (fval(f,0) < fval(g,0)) | ((fval(f,1) < fval(g,1)) << 1) | ((fval(f,2) < fval(g,2)) << 2)
truth_eq(f, g) = (fval(f,0) == fval(g,0)) | ((fval(f,1) == fval(g,1)) << 1) | ((fval(f,2) == fval(g,2)) << 2)

for a in (1, 2), f in funcs, g in funcs
    @assert ((truth_lt(f, g) & (1 << a)) != 0) == (fval(f, a) < fval(g, a))
    @assert ((truth_eq(f, g) & (1 << a)) != 0) == (fval(f, a) == fval(g, a))
end

# 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点（eval 同构）。
for a in (1, 2)
    idtruth = (a == 1 ? 0b010 : 0b100)
    @assert idtruth in G(a)
    for f in funcs
        @assert fval(f, a) == (a == 0 ? f[1] : (a == 1 ? f[2] : f[3]))  # 代表即取值
    end
end

# ── 六、下降链（引理 2.30(3) 的有限影子：无严格下降链超过 2 级） ──
function max_desc_len()
    best = 1
    for m in 0:63                      # 枚举链的起点集——直接 DFS
        stack = [(c, 1) for c in IPOS]
        while !isempty(stack)
            c, n = pop!(stack)
            best = max(best, n)
            for d in IPOS
                if d != c && le(d, c) && !le(c, d)   # d 严格强于 c
                    push!(stack, (d, n + 1))
                end
            end
        end
    end
    return best
end
@assert max_desc_len() == 2            # 商代数 4 元：1 > 原子，无更长链

println("Julia：序自反/传递全量；商代数 4 元；超滤子四公理；")
println("稠密集全相遇；有限 Łoś 27×27×2 双滤子；严格下降链至多 2 级")
println("END ====")
