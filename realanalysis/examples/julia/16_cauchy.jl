# 第 16 章 柯西序列与单调序列：Julia 通道。
# 尾部两项的距离、三点集与区间的跨度、递减的倒数、递增地靠近 1。
# 运行：julia --startup-file=no 16_cauchy.jl

println("==== 16 cauchy ====")

gap = abs(1 // 11 - 1 // 12)
@assert gap < 1 // 10
println("terms 11 and 12 of 1/n are less than 1/10 apart")

@assert abs(3 - 1) == 2
println("the farthest points of {1,2,3} are 2 apart")

@assert abs(3 - (-3)) == 6
println("the ends of [-3,3] are 6 apart")

trunc = abs(141 // 100 - 1414 // 1000)
@assert trunc < 1 // 100
println("two truncations of sqrt(2) differ by less than 1/100")

@assert 1 // 12 < 1 // 11
println("1/n decreases: 1/12 is smaller than 1/11")

left = 1 - 1 // 11
right = 1 - 1 // 12
@assert left < right
@assert abs(left - 1) == 1 // 11
println("1-1/11 is below 1-1/12, and it is 1/11 short of 1")

println("END ====")
