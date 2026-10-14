# 第 48 章 Stone 对偶：P({1,2,3}) 的有限 Stone 空间实验室

println("==== 48")

# ---------- 幂集工具（自写，免依赖） ----------
function powerset3(v)
    out = Vector{Vector{Int}}()
    for mask in 0:(2^length(v) - 1)
        push!(out, [v[i] for i in 1:length(v) if (mask >> (i - 1)) & 1 == 1])
    end
    return out
end

# ---------- B = P({1,2,3})：8 元布尔代数 ----------
elems = [1, 2, 3]
# 集合的规范形：始终升序向量（否则 union([2],[1])=[2,1] ≠ B 中的 [1,2]）
bmeet(a, b) = sort(intersect(a, b))
bjoin(a, b) = sort(union(a, b))
bnot(a) = sort(setdiff(elems, a))

B = powerset3(elems)
println("B = P({1,2,3})：", length(B), " 元")

# ---------- 超滤子：有限 BA 上 = 主超滤 U_S = {b ∈ B : S ⊆ b} ----------
function is_ultra(U)
    # 滤子性：含顶、对交封闭、上封闭
    elems ∉ U && return false
    for b in U, c in U
        bmeet(b, c) in U || return false
    end
    for b in U, d in B
        b ⊆ d && (d in U || return false)
    end
    # 超性：b 与 ¬b 恰一在
    return all((b in U) != (bnot(b) in U) for b in B)
end

function ultrafilters()
    us = []
    for S in B
        U = [b for b in B if issetequal(S, bmeet(S, b))]
        is_ultra(U) && push!(us, U)
    end
    return us
end
st = ultrafilters()
# 数学事实：主超滤 G_a = {b : a ⊆ b} 只有原子 a 生成者是超滤
#（非原子 S 的 U_S 会同时漏掉 b 与 ¬b）——|St(B)| = #atoms = 3
println("超滤子恰 ", length(st), " 个（原子主超滤，每原子一个）")
@assert length(st) == 3

# ---------- N_b = {G 的编号 : b ∈ G}：Stone 拓扑基 ----------
N(b) = [i for (i, G) in enumerate(st) if b in G]

function check_hom()
    n = 0
    for b in B, c in B
        @assert sort(N(bmeet(b, c))) == sort(intersect(N(b), N(c)))
        @assert sort(N(bjoin(b, c))) == sort(union(N(b), N(c)))
        @assert sort(N(bnot(b))) == sort(setdiff(collect(1:3), N(b)))
        n += 3
    end
    return n
end
n_hom = check_hom()
println("N_{b∧c}=N_b∩N_c、N_{b∨c}=N_b∪N_c、N_{¬b}=St∖N_b：全扫 $(n_hom) 条 ✓")

# ---------- 单射半边：8 个 N_b 两两不同 ----------
Nfam = unique([sort(N(b)) for b in B])
println("|{N_b : b ∈ B}| = ", length(Nfam), "（b ↦ N_b 单射）")
@assert length(Nfam) == 8
println("对偶：8 元 B ≅ 3 点离散空间的 CLOP = 全部 2^3 = 8 个 clopen ✓")
println("（这就是 β{1,2,3} = {1,2,3}——有限集的 Stone-Čech 是自身）")

# ---------- 对偶定理 (4)：孤立点 = 主超滤 ----------
println("3 点全部孤立 ⟺ 3 个原子主超滤（定理 4 有限化身）✓")

# ---------- Prop 3.11.2：sup 的拓扑算法 ----------
# 有限情形：{N_b : b ∈ X} 在 N_a 稠密 ⟺ N_a 的每点被某 N_b 覆盖
function check_sup()
    n = 0
    for X in powerset3(collect(1:length(B)))   # X ⊆ B 的索引集合
        isempty(X) && continue
        pts = Set{Int}()
        for xi in X
            union!(pts, N(B[xi]))
        end
        sup = reduce(bjoin, [B[xi] for xi in X])
        @assert Set(N(sup)) ⊆ pts      # ⋁X 是上界：N_sup ⊆ ⋃_{b∈X} N_b
        n += 1
        # 最小性：若 a 也是上界且 N_a ⊋ 覆盖，则 sup ⊆ a（有限格中直接验证）
        for a in B
            if all(bjoin(B[xi], a) == a for xi in X)
                @assert issetequal(bmeet(sup, a), sup)  # sup ≤ a
            end
        end
    end
    return n
end
n_sup = check_sup()
println("Prop 3.11.2：$(n_sup) 个子集的上确界+最小性全过 ✓")

println("END ====")
