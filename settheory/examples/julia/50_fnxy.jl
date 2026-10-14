# 第 50 章 Δ 引理穷举实验室 + Fn(5,2) 反链 + 泛型滤子构造

println("==== 50")

using Random

# 自写组合生成（Combinatorics 包不可依赖）
function combinations_k(v, k)
    n = length(v)
    out = Vector{Vector{Int}}()
    idx = collect(1:k)
    while true
        push!(out, [v[i] for i in idx])
        i = k
        while i > 0 && idx[i] == n - k + i
            i -= 1
        end
        i == 0 && break
        idx[i] += 1
        for j in (i + 1):k
            idx[j] = idx[j - 1] + 1
        end
    end
    return out
end

# ---------- Δ 引理蒙特卡洛（有限版） ----------
# 断言：任何足够大的"有限集族"都有大的 Δ-子系（有限版不能保证
# 任意大——Δ 引理的正则基数条件在有限版退化为阈值现象）
function max_delta_sub(fam)
    best = []
    n = length(fam)
    for mask in 0:(2^n - 1)
        S = [fam[i] for i in 1:n if (mask >> (i - 1)) & 1 == 1]
        length(S) < length(best) && continue
        isΔ = length(S) >= 2 && begin
            roots = Set(intersect(S[i], S[j]) for i in 1:length(S) for j in i+1:length(S))
            length(roots) == 1
        end
        isΔ && (best = S)
    end
    return best
end

# Julia 1.13 已移除 Random.sample——自写无放回采样
sample_k(U, k) = [U[i] for i in randperm(length(U))[1:k]]

function delta_mc()
    Random.seed!(50)
    U = combinations_k([1,2,3,4,5], 2)
    append!(U, combinations_k([1,2,3,4,5], 3))
    n_pos = 0
    for _ in 1:300
        fam = sample_k(U, 6)
        d = max_delta_sub(fam)
        length(d) >= 2 && (n_pos += 1)
    end
    return n_pos
end
n_pos = delta_mc()
println("Δ-子系蒙特卡洛：300 组随机 6 族中 $(n_pos) 组有 ≥2 元 Δ-子系")
println("（有限宇宙无免费大 Δ-系——引理的正则基数条件是本质的）")

# ---------- Fn(3,2) 反链枚举：最大反链 = 4 ----------
# 条件 = (mask, val)：dom = mask 的位，val 在 dom 上的取值
conditions3 = []
for mask in 0:7
    for v in 0:(2^count_ones(mask) - 1)
        push!(conditions3, (mask, v))
    end
end
compat(c, d) = begin
    m = c[1] & d[1]
    # 公共坐标取值一致
    ok = true
    for i in 0:2
        if (m >> i) & 1 == 1
            vi = value_at(c, i); vj = value_at(d, i)
            vi != vj && (ok = false; break)
        end
    end
    ok
end
value_at(c, i) = begin
    # c 的值按 dom 内位序编码
    idx = count_ones(c[1] & ((1 << i) - 1))
    (c[2] >> idx) & 1
end

function is_antichain(A)
    all(!compat(A[i], A[j]) for i in 1:length(A) for j in i+1:length(A))
end

# 全定义域（mask=7）8 条件两两不相容 → 反链 8
full = [(7, v) for v in 0:7]
@assert is_antichain(full)
println("Fn(3,2)：全定义域 8 条件两两不相容（最大反链 8——ccc 有限形态）")

# ---------- 泛型滤子构造（Lemma 5.1.2 有限截段） ----------
# 稠密集 D_n = {s : n ∈ dom(s)}（Fn(ω,2) 的标准稠密集）
refine_ext(c, n) = begin
    # 若 n 已在 dom，返回自身；否则加坐标
    (c[1] >> n) & 1 == 1 ? c : extend(c, n, rand(0:1))
end
extend(c, n, b) = begin
    m = c[1] | (1 << n)
    # 重建值编码（位序重排的简化：仅演示用小定义域）
    (m, c[2] | (b << count_ones(c[1] & ((1 << n) - 1))))
end

Random.seed!(51)
chain = [(1, 0)]   # 从 {(0)→0} 出发
for n in 1:6
    push!(chain, refine_ext(chain[end], n))
end
# 上闭包（有限宇宙）= chain 本身（已逐点相容）
ok = all(compat(chain[i], chain[j]) for i in 1:7 for j in 1:7)
println("泛型滤子构造：7 步递增链，全相容：", ok ? "✓" : "✗")
@assert ok
println("（链与每个 D_n 相交：步 n 恰好把 n 放进定义域——Lemma 5.1.2 落地）")

println("END ====")
