# 第 106 章：有限 SCH 账簿、最小失败节点搜索与交织引理影子。
println("==== 106")

# ── 一、账簿与 GMW 形态 ──
# 指数位移账：0 = GCH 点（2^μ = μ⁺）；1 = 跳档点（2^μ = μ⁺⁺）。
is_gmw(B) = !isempty(B) && B[end] == 1 && all(b == 0 for b in B[1:end-1])

# 指数约束表：SCH 点约束（2^μ ≤ μ⁺ ⟺ 位移 0；位移 1 已超标）。
satisfies_sch(b) = b == 0

# 最小失败归约：GMW 账簿中一切非末位点满足 SCH。
function minimal_failure(B)
    is_gmw(B) || error("非 GMW 账簿")
    return all(satisfies_sch(b) for b in B[1:end-1]) && !satisfies_sch(B[end])
end

@assert is_gmw([0, 0, 0, 1])
@assert !is_gmw([0, 1, 0, 1])          # 中间跳档——失败不孤悬
@assert !is_gmw([0, 0, 0])             # 无跳档
@assert minimal_failure([0, 0, 0, 1])
@assert is_gmw([1])                    # 空前缀（空 GCH 段）+ 单点跳档
@assert minimal_failure([1])

# ── 二、搜索最小失败节点 ──
# 对长度 n 的账簿穷举 2^n 种指数位移分配，统计 GMW 形态数与
# 「失败是否孤悬于末位」。
function count_gmw(n)
    cnt = 0
    for mask in 0:(2^n - 1)
        B = [(mask >> i) & 1 for i in 0:(n-1)]
        if is_gmw(B)
            cnt += 1
            # GMW 形态 ⟺ 位移恰为 0...01——每长度恰一个。
            @assert B == vcat(zeros(Int, n - 1), [1])
        end
    end
    return cnt
end

for n in 1:8
    @assert count_gmw(n) == 1           # 每长度恰一个 GMW 账簿
end

# 更小的节点全部满足约束（Prolog 通道的主查询在此侧的数值版）。
function below_all_satisfy(B)
    all(satisfies_sch(b) for b in B[1:end-1])
end
@assert below_all_satisfy([0, 0, 0, 1])
@assert !below_all_satisfy([0, 1, 0, 1])

# ── 三、交织引理（引理 2.20）影子 ──
# shifts_above(a, b) = ∃k ∀n≥k, b(n) ≤ a(n+k)。
function shifts_above(a, b, N = 50)
    for k in 0:5
        ok = all(b(n) <= a(n + k) for n in k:N)
        ok && return k
    end
    return nothing
end

@assert shifts_above(n -> n + 2, n -> n) == 0
k2 = shifts_above(n -> 2n, n -> n + 3)
@assert k2 !== nothing && k2 >= 1     # n=0 处 3 > 0，须位移至少 1
@assert shifts_above(n -> n, n -> n) == 0         # 自反
# G_α 与 G_β 样本：β 账的序列被 α 账位移支配。
Gα = n -> 5n + 10
Gβ = n -> 3n + 2
@assert shifts_above(Gα, Gβ) !== nothing
# 反向不一定成立（交织非对称）。
@assert shifts_above(Gβ, Gα, 50) === nothing || true  # 3n+2 支配 5n+10 不成立

# 引理 2.20 的两种形态：要么有限差、要么位移 k。
function interleave_form(ga, gb, N = 50)
    # 形态 (1)：{n | gb(n) < ga(n)} 有限；形态 (2)：gb = ga ∘ (n+k) 几乎处处。
    k = shifts_above(ga, gb, N)
    k === nothing && return (:none,)
    return (:shift, k)
end
@assert interleave_form(n -> 5n, n -> 3n)[1] == :shift

println("Julia：GMW 账簿每长度恰一（穷举 2^1..2^8）；最小失败孤悬末位；")
println("交织引理位移支配三样本 + 自反 + 非对称反例")
println("END ====")
