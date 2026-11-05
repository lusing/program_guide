# 第 21 章 收官：Julia 通道。
# 三个 1/3 加回 1；6 超过 5；两半加回 1；公比 1/2 的闭式是 2。
# 运行：julia --startup-file=no 21_wrapup.jl

println("==== 21 roadmap ====")

@assert 1//3 + 1//3 + 1//3 == 1//1
println("three thirds make 1")

@assert 6 > 5
println("6 is past 5")

@assert 1//2 + 1//2 == 1//1
println("two halves make 1")

@assert 1//1 / (1//1 - 1//2) == 2//1
println("geometric closed form is 2")

println("END ====")
