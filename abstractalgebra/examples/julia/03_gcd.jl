# 第 03 章 · 最大公因子 —— 计算通道
#
# 扩展欧几里得（回代贝祖系数）+ 拉梅定理实测 + 平衡三进制天平称量。

println("==== 03 最大公因子")

# ---------- 扩展欧几里得 ----------
"""返回 (d, s, t) 使 d = s·a + t·b（贝祖系数跟着除法算式同步演化）。"""
function extgcd(a::T, b::T) where T <: Integer
    old_r, r = a, b
    old_s, s = T(1), T(0)
    old_t, t = T(0), T(1)
    while r != 0
        q = div(old_r, r)
        old_r, r = r, old_r - q * r
        old_s, s = s, old_s - q * s
        old_t, t = t, old_t - q * t
    end
    return old_r, old_s, old_t
end

# 例 1.42：gcd(326, 78) = 2 = 46·78 − 11·326
d, s, t = extgcd(326, 78)
@assert (d, s, t) == (2, -11, 46) "extgcd(326,78) = ($d, $s, $t)"
println("gcd(326, 78) = $d = $s·326 + $t·78（与正文手算一致）")
@assert 78 // 326 == 39 // 163 "既约分数"

# 全量复核：1 ≤ a ≤ b ≤ 500
cnt = 0
for a in 1:500, b in a:500
    dd, ss, tt = extgcd(a, b)
    @assert dd == gcd(a, b) && ss * a + tt * b == dd
    global cnt += 1
end
println("extgcd 全量复核 $cnt 对：d = gcd(a,b) 且 s·a + t·b = d ✓")

# ---------- 欧几里得算法步数 + 拉梅定理 ----------
"""欧几里得算法的除法步数。"""
function euclid_steps(a::Integer, b::Integer)
    steps = 0
    while b != 0
        a, b = b, a % b
        steps += 1
    end
    steps
end

function fibit(n::Integer)
    a, b = big(0), big(1)
    for _ in 1:n
        a, b = b, a + b
    end
    a
end

println("相邻斐波那契对是欧几里得算法的最坏输入（拉梅定理）：")
for n in 5:3:30
    a, b = fibit(n + 1), fibit(n)
    steps = euclid_steps(a, b)
    lameround = 5 * ndigits(a)
    @assert steps ≤ lameround
    println("  (F_$(n+1), F_$n)：$steps 步 ≤ 5×$(ndigits(a)) = $lameround")
end

# ---------- 进制表示（例 1.45）与天平称量（例 1.46/1.50） ----------
function base_digits(n::Integer, b::Integer)
    ds = Integer[]
    while n > 0
        push!(ds, n % b)
        n ÷= b
    end
    reverse(ds)
end
@assert base_digits(12345, 7) == [5, 0, 6, 6, 4] "12345 = (50664)₇"

"""天平称量：重量 1,3,9,27 能否（唯一地）称出 n？返回 (e1,e3,e9,e27)。"""
function weigh(n::Integer)
    for e1 in -1:1, e3 in -1:1, e9 in -1:1, e27 in -1:1
        e1 + 3*e3 + 9*e9 + 27*e27 == n && return (e1, e3, e9, e27)
    end
    return nothing
end

for n in 1:40
    w = weigh(n)
    @assert !isnothing(w) "n = $n 称不出来"
    # 唯一性：枚举全部系数组合计数
    sols = count(e1 + 3*e3 + 9*e9 + 27*e27 == n
                 for e1 in -1:1, e3 in -1:1, e9 in -1:1, e27 in -1:1)
    @assert sols == 1 "n = $n 有 $sols 种称法"
end
println("天平 1,3,9,27：1..40 每个重量恰一种称法 ✓（19 = 27−9+1：",
        join(string.(collect(weigh(19))), ", "), "）")

println("END ====")
