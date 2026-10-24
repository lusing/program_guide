# 第 77 章：滤子、非荟萃集理想与广义无界闭子集（冯琦 §2.3）——Julia 通道
# 三个实验：例 2.11 尾集族之交为空（κ-完全性长度限制之死）；定理 2.24
# 正规性在 κ=ω 处失败（对角线交变有限）；引理 2.13 的闭包构造 C_f
# （迭代 A_{n+1}=A_n∪{f(e):e⊆A_n} 到不动点，机器复演"可数子代数存在"）。
println("==== 77")

# ---------- 实验一：例 2.11——尾集族 C_k={i>k} 之交为空 ----------
# 每个 C_k 在 ω 上无界（任意 M 之上仍有 i>k），闭性在 ω 空虚真
# （ω 内没有非零极限序数）。但 ⋂_k C_k=∅：每个 i 都被 C_i 甩掉。
inC(k, i) = i > k                      # i ∈ C_k ⟺ i > k
N = 100_000
escapes = 0
for i in 0:N
    k = i                              # 逃逸指标：i ∉ C_i，因 ¬(i > i)
    @assert !inC(k, i)
    global escapes += 1
end
@assert escapes == N + 1
# 每个 C_k 在窗口内确无界：k+1..N 都落在 C_k 里
@assert all(k -> all(i -> inC(k, i), (k + 1):N), 0:(N ÷ 2))
# 全体之交为空：不存在 i 属于每个 C_k（取 k=i 即被甩）
@assert !any(i -> all(k -> inC(k, i), 0:i), 0:N)
println("实验一（例 2.11）：C_k={i>k} 各无界，但 ⋂C_k=∅——每个 i 被 C_i 甩掉（$escapes 个逃逸点）✓")

# ---------- 实验二：正规性之死——对角线交在 κ=ω 处变有限 ----------
# C_k = {(k+1) 的倍数}，每个在 ω 上无界闭。对角线交
# ΔC = {i : ∀k<i, i∈C_k} = {i : ∀j∈1..i, j | i}，数值上只有 {0,1,2}。
# 定理 2.24（κ 正规 ⟹ ΔC 是 club）在 κ=ω 失败：ω-完全性不够。
inClub(k, i) = (i % (k + 1) == 0)      # i ∈ C_k ⟺ (k+1) | i
inDelta(i) = all(k -> inClub(k, i), 0:(i - 1))   # i=0 时空交为真
deltaC = filter(inDelta, 0:1_000_000)
@assert deltaC == [0, 1, 2]
println("实验二（正规性之死）：ΔC = {i : ∀k<i (k+1)|i} 算到 10^6 只得 $(deltaC)——有限，非 club ✓")

# ---------- 实验三：引理 2.13 的闭包构造 C_f ----------
# X={0..9}，f(e)=(Σe) mod 7（[X]^{<ω}→X）。从种子出发迭代
# A_{n+1}=A_n ∪ {f(e) : e ⊆ A_n}，直到不动点（∀e⊆A: f(e)∈A）。
# 机器复演"C_f 无界/可数子代数存在"的构造步骤。
const X = 0:9
f_op(e) = sum(e; init=0) % 7
@assert all(v -> v ∈ X, [f_op([3]), f_op([5]), f_op([3, 5]), f_op(Int[])])  # 值域落在 X

function subsets(A)                    # A 的全体有限子集（A 已有限）
    A = collect(A)
    out = Vector{Int}[Int[]]
    for x in A
        append!(out, [push!(copy(s), x) for s in out])
    end
    out
end

function closure(seed)
    A = Set(seed)
    steps = 0
    while true
        newA = copy(A)
        for e in subsets(A)
            push!(newA, f_op(e))
        end
        newA == A && return (A, steps)   # A 已是不动点
        A = newA
        steps += 1
    end
end

A_fin, steps = closure([3, 5])
@assert A_fin == Set(0:6)              # 不动点 = 整个 Z_7
@assert steps == 2
# 验证不动点确实封闭：∀ 有限 e ⊆ A_fin, f(e) ∈ A_fin
@assert all(e -> f_op(e) ∈ A_fin, subsets(A_fin))
println("实验三（引理 2.13 闭包）：种子 {3,5} 经 $steps 步到不动点 $(sort(collect(A_fin)))，∀e⊆A: f(e)∈A ✓")

println("END ====")
