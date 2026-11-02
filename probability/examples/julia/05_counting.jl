# -*- coding: utf-8 -*-
println("==== 05 counting")
# 第 05 章 Julia：计数的频率视角（零依赖——环境无 Combinatorics）。
# ① 三抛硬币恰 2 正（陷阱一的现场）；② 10 人选 3 的枚举；
# ③ Pascal 行的数值（与 Python 精确表互补）。
using Random

Random.seed!(3)

# ① 三抛硬币恰 2 正：模拟 vs 3/8（错误直觉常猜 1/3）
function two_heads_rate(trials = 200_000)
    hit = 0
    for _ in 1:trials
        heads = 0
        for _ in 1:3
            rand() < 0.5 && (heads += 1)
        end
        heads == 2 && (hit += 1)
    end
    hit / trials
end
rate = two_heads_rate()
@assert abs(rate - 3 / 8) < 0.003
println("3 coins exactly 2 heads: sim = ", round(rate, digits=4),
        " vs 3/8 = 0.375: OK")

# ② 10 人选 3：手写组合枚举（三重循环去重序）
sel = Vector{Int}[]
for i in 1:8, j in (i + 1):9, k in (j + 1):10
    push!(sel, [i, j, k])
end
@assert length(sel) == 120
contains4 = count(s -> 4 in s, sel)
@assert contains4 == 36                        # C(9,2)：含指定人
println("C(10,3) = 120 enumerated; subsets containing person-4 = 36: OK")

# 排列计数：3 岗位（有序）= 720 = 6 × 120（3! 去重）
@assert 10 * 9 * 8 == 6 * 120
println("ordered assignments 720 = 3! * C(10,3)-count: OK")

# ③ Pascal 行（n = 10）：递推填充 vs 对称与求和性质
row = fill(0, 11)
row[1] = 1
for n in 1:10
    new = fill(0, 11)
    new[1] = 1
    for k in 2:(n + 1)
        new[k] = row[k - 1] + row[k]
    end
    global row = new
end
@assert row == [1, 10, 45, 120, 210, 252, 210, 120, 45, 10, 1]
@assert sum(row) == 2 ^ 10
println("Pascal row n=10: symmetric, sums to 2^10 = 1024: OK")

# ④ 多项系数：5 个有标签位置分成 (3,1,1) 三组，共有 20 种分法。
multinomial(n, groups) = factorial(n) ÷ prod(factorial.(groups))
@assert multinomial(5, (3, 1, 1)) == 20
@assert multinomial(11, (5, 3, 3)) == 9240
println("multinomial coefficients 5!/(3!1!1!)=20 and 11!/(5!3!3!)=9240: OK")

# 多项式定理：逐项枚举 a+b+c=5，与直接五次幂对拍。
let total = 0//1, vals = (1//2, 3//1, -1//1)
    for a in 0:5, b in 0:(5-a)
        c = 5 - a - b
        coef = multinomial(5, (a, b, c))//1
        total += coef * vals[1]^a * vals[2]^b * vals[3]^c
    end
    @assert total == (vals[1] + vals[2] + vals[3])^5
end
println("multinomial theorem (x+y+z)^5 matches direct power: OK")

# 3 个可辨球独立进 2 个桶，桶 1 恰有 j 球的分配数是 C(3,j)。
hist = zeros(Int, 4)
for b1 in 0:1, b2 in 0:1, b3 in 0:1
    hist[b1 + b2 + b3 + 1] += 1
end
@assert hist == [1, 3, 3, 1]
println("3 balls into 2 bins histogram [1,3,3,1] is a multinomial row: OK")

println("END ====")
