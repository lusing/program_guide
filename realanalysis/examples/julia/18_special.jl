# 第 18 章 特殊序列：Julia 通道。
# 1/121 < 1/10，并且 1/121 < 1/11。
# (1/2)^10 = 1/1024 < 1/100。
# (3/2)^2 = 9/4 > 2 = 1 + 2*(1/2)。
# 运行：julia --startup-file=no 18_special.jl

println("==== 18 squeeze ====")

@assert 1 // 121 < 1 // 10
println("1/121 is below 1/10")

@assert 0 < 1 // 121 && 1 // 121 < 1 // 11
println("1/121 sits strictly between 0 and 1/11")

@assert (1 // 2)^10 == 1 // 1024
@assert (1 // 2)^10 < 1 // 100
println("(1/2)^10 is 1/1024, below 1/100")

@assert (3 // 2)^2 == 9 // 4
@assert 1 + 2 * (1 // 2) < (3 // 2)^2
println("(3/2)^2 is 9/4, above 1 + 2*(1/2)")

println("END ====")
