# 第 15 章 极限与子序列：Julia 通道。
# 和、数乘、积、倒数的误差，以及 (-1)^n 的偶、奇子序列。
# 运行：julia --startup-file=no 15_subsequences.jl

println("==== 15 subsequences ====")

a = 1 // 11
@assert (a + 1) - 1 == a
println("adding 1 moves the term by exactly 1/11 from the limit 1")

@assert abs(3 * a) < 3 // 10
println("three times 1/11 stays under 3/10")

p = (1 + 1 // 10) * (2 + 1 // 10)
@assert abs(p - 2) < 1 // 2
println("product at n=10 is within 1/2 of 2")

inv = 1 / (1 + 1 // 10)
@assert abs(inv - 1) == 1 // 11
println("reciprocal of 1+1/10 is 10/11, distance 1/11")

alt(n) = iseven(n) ? 1 : -1
@assert alt(2) == 1 && alt(4) == 1 && alt(6) == 1
@assert alt(1) == -1 && alt(3) == -1 && alt(5) == -1
@assert 2 < 4 < 6
println("even subsequence is constantly 1; odd subsequence is constantly -1")

@assert (3 - 3) == 0
println("the second coordinate of (1/n, 3) is already at 3")

println("END ====")
