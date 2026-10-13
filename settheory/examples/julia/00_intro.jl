# 第 00 章 导引：Cantor 对角线的数值现场
#
# "实数不可数"不是一个存在性断言，而是一台"逃逸机器"：
# 给你任何一份实数名单，机器输出一个不在名单上的实数。
# 本程序把这台机器开动起来，并度量它逃逸得多彻底。

println("==== 00 导引：对角线机器")

# ------------------------------------------------------------------
# 对角线构造（二进制版本）
# 名单 x_1, x_2, ... 中每个 x_n 给出二进制数字序列；
# 逃逸者 y 的第 n 位取 x_n 第 n 位的"翻转"。
# ------------------------------------------------------------------

"""把 [0,1) 内的数转为 52 位二进制展开（Double 的尾数位）"""
function binary_digits(x::Float64, n::Int)
    ds = zeros(Int, n)
    y = x
    for k in 1:n
        y *= 2
        ds[k] = ifelse(y >= 1, 1, 0)
        y -= ds[k]
    end
    return ds
end

"""从二进制数字序列重建实数"""
function from_digits(ds::Vector{Int})
    x = 0.0
    for k in length(ds):-1:1
        x = (x + ds[k]) / 2
    end
    return x
end

"""对角线机器：给定名单（0 与 1 之间的函数），返回逃逸者"""
function diagonal_escape(list::Vector{Float64}, n::Int)
    flips = [1 - binary_digits(list[k], n)[k] for k in 1:n]
    return from_digits(flips)
end

# 一份"精心挑选"的名单：等距网格 + 无理数点缀
n = 52
list = [k / (n + 1) for k in 1:n]
y = diagonal_escape(list, n)

min_gap = minimum(abs(y - x) for x in list)
println("名单长度 = ", n, "，逃逸者 y = ", round(y, digits = 6))
println("y 与名单的最小距离 = ", min_gap, "  (>0 表示逃逸成功)")

@assert min_gap > 0

# ------------------------------------------------------------------
# 观点：机器可以跑，但"名单"永远只能是可数前缀。
# Cantor 定理说的是没有任何名单穷尽 [0,1]——
# 数值演示永远只能展示有限名单的失败。
# ------------------------------------------------------------------

println("要点：对角线机器对任何有限名单都能逃逸；")
println("     Cantor 的贡献是把这升级为对『任何可数名单』的逃逸。")

println("END ====")
