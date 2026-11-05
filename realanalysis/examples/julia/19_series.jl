# 第 19 章 级数：Julia 通道。
# 1 + 1/2 + 1/4 = 7/4 = (1 - 1/8)/(1/2)。
# (2/3)/(1 - 2/3) = 2。
# 调和前四项大于 2；把 1/3 换成 1/4 之后等于 2。
# 常数 1 并不小于 1/2。
# 运行：julia --startup-file=no 19_series.jl

println("==== 19 series ====")

partial = 1//1 + 1//2 + 1//4
closed = (1//1 - 1//8) / (1//2)
@assert partial == 7//4
@assert closed == partial
println("1 + 1/2 + 1/4 equals 7/4, and so does the closed form")

@assert (2//3) / (1//1 - 2//3) == 2//1
println("(2/3) / (1 - 2/3) equals 2")

group = 1//1 + 1//2 + 1//4 + 1//4
harmonic = 1//1 + 1//2 + 1//3 + 1//4
@assert group == 2//1
@assert harmonic > group
println("replacing 1/3 by 1/4 gives 2; the harmonic head is larger")

@assert abs(1//1) > 1//2
println("the constant term 1 is not below 1/2")

println("END ====")
