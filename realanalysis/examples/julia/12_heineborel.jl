# 第 12 章 海涅–博雷尔定理：Julia 通道。
# 闭区间套里的公共点、对分后的长度、有界样本落进格子、1/n 靠近 0。
# 运行：julia --startup-file=no 12_heineborel.jl

println("==== 12 heine borel ====")

function in_nested(x, n)
    0 <= x <= 1 + 1 // (n + 1)
end

@assert all(in_nested(0, n) for n in 0:19)
@assert all(in_nested(1, n) for n in 0:19)
println("0 and 1 lie in every [0, 1+1/(n+1)]")

function bisect_len(n)
    4 // (2 ^ n)
end

@assert bisect_len(6) < 1 // 10
println("after 6 bisections, length 4/64 < 1/10")

function in_cell(x)
    -3 <= x <= 3
end

sample = [-3, -1, 0, 2, 3]
@assert all(in_cell(x) for x in sample)
@assert !in_cell(4)
println("bounded sample sits in [-3,3]; 4 does not")

seq = [1 // n for n in 1:20]
@assert all(0 < x <= 1 for x in seq)
@assert seq[end] < 1 // 10
println("1/n stays in (0,1] and the 20th term is < 1/10")

println("END ====")
