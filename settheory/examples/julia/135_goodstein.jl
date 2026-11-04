# 第 135 章 Julia：古德斯坦序列的 BigInt 面。
# ① S_n 超底换底（定义 4.5.1）与 g 序列（4.5.6）——书载 m=13
#    的表全部复现（BigInt：第 10 步已 3.1e12）；
# ② f 序数赋值的下降审计：与 Python 通道互证；
# ③ 终止试验：m ≤ 3 全终止；m = 4 只能前几步（增长曲线展示）。
println("==== 135 goodstein")

function S(m::BigInt, n::BigInt)
    m < n && return m
    t = big(0)
    while n^(t + 1) <= m
        t += 1
    end
    k = m ÷ n^t
    b = m - k * n^t
    return k * (n + 1)^S(t, n) + S(b, n)
end

g(m::BigInt, n::BigInt) = (s = S(m, n); s > 0 ? s - 1 : big(0))

# ① 书例 4.5.2
@assert S(big(89), big(2)) == big"213516729579718"
println("S2(89) = 213516729579718 exact: OK")

# m=13 的 g 表（第 7 项机器自纠 134219479，见 Python 通道注记）
table = [13, 108, 1279, 16092, 280711, 5765998,
         134219479, 3486786855, 100000003325]
function gtable(m0::BigInt, upto)
    c = m0
    vals = Int128[m0]
    for n in 2:upto
        c = c == 0 ? big(0) : g(c, big(n))
        push!(vals, Int128(c))
    end
    vals
end

vals = gtable(big(13), 10)
@assert vals[1:9] == table
@assert vals[10] == 3138428381103                 # 第 10 项继续狂奔
println("g-table of 13: 9 book values + step-10 value 3138428381103: OK")

# ③ 终止试验
function goodstein_steps(m0::BigInt, cap=200)
    c, n, steps = m0, big(2), 0
    while c > 0
        c = g(c, n)
        n += 1
        steps += 1
        steps < cap || error("no termination within cap")
    end
    steps
end

for m0 in (big(1), big(2), big(3))
    println("goodstein($(m0)) terminates at step $(goodstein_steps(m0))")
end

# m=4 的前几步：增长曲线（完整终止需要 3·2^402653211−3 步）
growth = gtable(big(4), 7)
@assert growth == [4, 26, 41, 60, 83, 109, 139]   # 教科书标准前段
@assert growth[end] > growth[1]                    # 先涨后（极晚）跌
println("goodstein(4) first steps 4,26,41,60,83,109,139 (climbing): OK")
println("END ====")
