# 第 110 章：投影、饱和界与反射链——NS 峭壁/饱和/光影原理的有限影子。
println("==== 110")

# ── 一、位掩码宇宙（沿 109 章）与投影 π ──
const U = 0b111
proj(m) = m & 0b110                    # π：抹掉坐标 0（N ↦ N∩ω₁ 的影子）

@assert proj(0b111) == 0b110           # π(U) = {1,2}
@assert proj(0b011) == 0b010           # π({0,1}) = {1}
@assert proj(0b001) == 0b000           # π({0}) = ∅
@assert Set(proj(m) for m in 0:7) == Set([0, 2, 4, 6])   # 投影满到 P({1,2})

# ── 二、三理想饱和界表（反链规模 = 商原子数） ──
# mod-ideal 等价：m ≡ n ⟺ 双向差都在理想中；类代表取最小元。
rep_of(ideal, m) = minimum(n for n in 0:7
                           if !(n in ideal) && (n & ~m) in ideal && (m & ~n) in ideal)

function quotient_atoms(ideal)
    ipos = [m for m in 0:7 if !(m in ideal)]
    reps = unique(rep_of.(Ref(ideal), ipos))
    return [r for r in reps if !any(r2 != r && (r2 & ~r) in ideal for r2 in reps)]
end

# 商反链：两两不相容的正测族，按类代表去重后的规模。
function max_antichain(ideal)
    ipos = [m for m in 0:7 if !(m in ideal)]
    best = 0
    for mask in 0:(2^length(ipos) - 1)
        A = [ipos[i] for i in 1:length(ipos) if (mask >> (i - 1)) & 1 == 1]
        ok = all(A[i] & A[j] in ideal for i in 1:length(A) for j in i+1:length(A))
        if ok
            best = max(best, length(unique(rep_of.(Ref(ideal), A))))
        end
    end
    return best
end

table = [
    ("I₀ = {∅,{0}}", Set([0b000, 0b001])),
    ("I₁ = {∅}（平凡）", Set([0b000])),
    ("I₂ = {∅,{0},{1},{0,1}}", Set([0b000, 0b001, 0b010, 0b011])),
]
for (name, ideal) in table
    ma = max_antichain(ideal)
    atoms = length(quotient_atoms(ideal))
    println("  $(name)：反链至多 $(ma)，商原子 $(atoms)，饱和数 $(ma + 1)")
    @assert ma == atoms
end
# I₀ 的具体账：最大反链 {{1},{2}}，饱和数 3。
I0 = Set([0b000, 0b001])
@assert max_antichain(I0) == 2
@assert (0b010 & 0b100) in I0          # {1} 与 {2} 不相容（交 ∅）

# ── 三、核刻画与反链投影不交（全量核查） ──
@assert all((m in I0) == (proj(m) == 0) for m in 0:7)   # I₀ = π⁻¹(∅)
ipos0 = [m for m in 0:7 if !(m in I0)]
for C in ipos0, D in ipos0
    if (C & D) in I0                   # 模 I 不相容 ⟹ 投影不交
        @assert (proj(C) & proj(D)) == 0
    end
end
# 投影不交 + 两原子 ⟹ 反链 ≤ 2（数值版鸽笼）
@assert all(proj(C) != 0 for C in ipos0)

# ── 四、反射链（光影原理有限实例） ──
# 上向闭（有限 club 影子）+ 全投影（PS 影子）的族 S 必含
# 可比对 N ⊂ N' 且投影不同——「从 PS 族走出一阶」的有限替身。
sub(m, n) = (m & ~n) == 0                 # 位掩码包含：m ⊆ n
upward_closed(S) = all(N2 in S for N in S for N2 in ipos0 if sub(N, N2))
full_proj(S) = all(any(proj(N) == t for N in S) for t in [0b010, 0b100, 0b110])

count_ps = 0
for mask in 0:63
    S = Set(ipos0[i] for i in 1:6 if (mask >> (i - 1)) & 1 == 1)
    if upward_closed(S) && full_proj(S)
        global count_ps += 1
        found = any(N in S && N2 in S && N != N2 && sub(N, N2) && proj(N) != proj(N2)
                    for N in S, N2 in S)
        @assert found                 # 反射可比对存在
    end
end
@assert count_ps > 0
println("Julia：三理想饱和界表（反链=商原子）；核=π⁻¹(∅)；")
println("反链投影不交全查；上向闭 PS 族（$count_ps 个）全含反射可比对")
println("END ====")
