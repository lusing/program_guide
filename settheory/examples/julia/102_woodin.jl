# 第 102 章：f-闭包点枚举、见证依赖函数与伪见证失败原因分类。
println("==== 102")

const DELTA = 4  # 有限论域 {0,1,2,3}：κ 的候选范围 [1,4)

closed(f, κ) = all(f[i+1] < κ for i in 0:κ-1)

# ── 一、全函数枚举：每个 f:4→4 的闭包点集合 ──
allfs = [collect(t) for t in Iterators.product(fill(0:3, DELTA)...)]
@assert length(allfs) == 256

witnesses(f) = [κ for κ in 1:DELTA-1 if closed(f, κ)]

# 手写期望（对拍孤本）：闭包点集合的非空函数恰有几类。
w11 = [1,1,1,1]   # κ=2,3
@assert witnesses(w11) == [2, 3]
w22 = [2,2,2,2]   # κ=3
@assert witnesses(w22) == [3]
w13 = [1,3,1,1]   # κ∈{2,4}\[1,4) → 只有 4 之外；实际 [1,4) 内空
@assert witnesses(w13) == Int[]
cofinal = [1,2,3,3]  # 共尾型：无闭包点
@assert witnesses(cofinal) == Int[]

# 统计对拍：256 个函数中恰有 N 个在 [1,4) 内有闭包点。
n_with = count(f -> !isempty(witnesses(f)), allfs)
# 孤本账（容斥；初版以为「闭包点集上闭」——错账：[2,2,2,2]
# 的见证集恰是 {3} 而无 2，闭包于 κ 不蕴含闭包于更大的 κ'，
# 因为新坐标 i∈[κ,κ') 的值 f(i) 可以 =κ'。正确账）：
#   |A3| = 3³·4 = 108；|A2∖A3| = 2²·4² - 2²·3·4 = 16；
#   |A1∖(A2∪A3)| = 64 - 32 - 36 + 24 = 20；合计 144。
@assert n_with == 108 + 16 + 20
@assert n_with == 144

# ── 二、见证必须随函数变化（单一 κ 不够）──
# 对每个 κ∈[1,4) 找一个在该 κ 处闭包失败的函数：
adversary(κ) = [κ; κ; κ; κ]  # f(0)=κ ≥ κ → 闭包败
for κ in 1:DELTA-1
    @assert !closed(adversary(κ), κ)
end
# 于是「∀f∃κ」的 κ 必须依赖 f：常值 κ 函数把每个固定 κ 都打死。

# ── 三、f-谢拉赫型条款与失败原因分类 ──
struct FWit
    κ::Int
    jfκ::Int
    cap::Vector{Int}
end

fShelah(f, w) = closed(f, w.κ) && w.κ < w.jfκ && w.jfκ in w.cap

# 失败原因：返回 (closure_fail_at, capture_fail)。
function reasons(f, w)
    c = findfirst(i -> f[i+1] >= w.κ, 0:w.κ-1)
    return (c === nothing ? nothing : c - 1,
            !(w.jfκ in w.cap))
end

w = FWit(2, 3, [3])
@assert fShelah([1,1,1,1], w)
@assert reasons([1,1,1,1], w) == (nothing, false)
r = reasons([2,2,2,2], w)          # κ=2 处 f(0)=2 ≥ 2：闭包败于 i=0
@assert r == (0, false)
r2 = reasons([1,1,1,1], FWit(2, 4, [3]))  # 层 4 未捕获：捕获败
@assert r2 == (nothing, true)

println("Julia：256 函数全枚举，有闭包点者 $n_with 个；每个固定 κ 都有敌人；")
println("失败原因二分类（闭包位 / 捕获位）——见证必须随 f 变化")
println("END ====")
