# 第 101 章：位编码有限秩层、beth 尺寸链与有限强度矩阵。
println("==== 101")

# ── 一、有限累积层次（宇宙 {0..15}，四层）──
const U = collect(0:15)
elems(x) = [i for i in 0:3 if (x >> i) & 1 == 1]

function level(n::Int)
    n == 0 && return Int[]
    cur = level(n - 1)
    [x for x in U if issubset(Set(elems(x)), Set(cur))]
end

@assert level(0) == Int[]
@assert level(1) == [0]
@assert level(2) == [0, 1]
@assert level(3) == [0, 1, 2, 3]
@assert level(4) == U
# beth 尺寸链：|V_{n+1}| = 2^{|V_n|} 在有限层的精确复现。
@assert length.(level.(1:4)) == [1, 2, 4, 16]
# 层包含链 V_n ⊆ V_{n+1}。
for n in 0:3
    @assert issubset(Set(level(n)), Set(level(n + 1)))
end

# ── 二、见证条款：λ-强 / 超强 / 强 ──
# Wit = (crit, jκ, captured)：临界点、j(κ)、目标模型捕获的秩层号集合。
struct Wit
    crit::Int
    jk::Int
    captured::Set{Int}
end

# (κ,λ)-强条款：κ ≤ λ、λ < j(κ)、V_λ ⊆ M（第 λ 层被捕获）。
lam_strong(w, l) = w.crit <= l && l < w.jk && l in w.captured
# 超强条款：V_{j(κ)} ⊆ M。
superstrong(w) = w.jk in w.captured
# 强条款：对所有 λ ≥ κ 都 λ-强（有限 captured 上恒假）。
is_strong(w, maxλ) = all(lam_strong(w, l) for l in w.crit:maxλ)

# ── 三、有限强度矩阵：行 = 见证，列 = λ ──
witnesses = [
    Wit(2, 3, Set([2])),   # 恰好捕获第 2 层：可测类似物（κ=2、j(κ)=3）
    Wit(2, 5, Set([3])),   # 单 λ 见证：λ=3
    Wit(2, 5, Set([2, 3, 4])),  # λ=2,3,4 三点见证
    Wit(2, 6, Set([2, 3, 4, 5])),  # 四点见证，λ=5 处断
    Wit(2, 4, Set([4])),   # 超强见证：j(κ)=4 被捕获
]
println("有限强度矩阵（行 = 见证 (κ,jκ,cap)，列 = λ = 2..6）：")
print("            ")
for l in 2:6; print("λ=$l  "); end
println()
for w in witnesses
    print("($(w.crit),$(w.jk),$(sort(collect(w.captured))))  ")
    for l in 2:6
        print(lam_strong(w, l) ? " ✓   " : " ·   ")
    end
    println("  | 超强:$(superstrong(w) ? "✓" : "·")")
end

# 矩阵断言：每行只在有限列点亮——「对所有 λ 的见证」永不出场。
@assert all(any(!lam_strong(w, l) for l in 2:20) for w in witnesses)
# 有限捕获集上的强条款恒假（鸽笼：captured 有限而 λ 无穷）。
for w in witnesses
    L = w.crit + maximum(w.captured) + 1   # 超出捕获集的层号
    @assert !lam_strong(w, L)
    @assert !is_strong(w, L)
end
# 超强 ≠ 任意单 λ 强：超强见证 (2,4,[4]) 在 λ=4 处并非 λ-强？
# λ=4：crit=2≤4 ✓、4<4 ✗ —— j(κ) 本身不能作为自己的 λ（j(κ)>λ 要求）。
w_ss = witnesses[5]
@assert superstrong(w_ss)
@assert !lam_strong(w_ss, 4)
@assert lam_strong(w_ss, 3) == false   # 3 ∉ captured
# 可测类似物：(κ, κ+1)-强 = 捕获第 κ 层（定义 1.18 之后的观察）。
w_meas = witnesses[1]
@assert lam_strong(w_meas, 2)
@assert !lam_strong(w_meas, 3)

println("Julia：V 层尺寸 1,2,4,16 与包含链；强度矩阵每行有限点亮；")
println("有限捕获恒非强；超强条款与 λ-强条款互不蕴含（j(κ)>λ 边界）")
println("END ====")
