# 第 14 章 序列与收敛：Julia 通道。
# 1/n 的 ε-N、平方越界、交错项到 1 的距离、常数序列的值域。
# 运行：julia --startup-file=no 14_sequences.jl

println("==== 14 sequences ====")

s(n) = 1 // n
ε = 1 // 10
@assert s(11) < ε
@assert s(10) == ε
println("1/11 < 1/10; N = 11 works for epsilon = 1/10")

@assert 20^2 > 100
println("20^2 = 400 escapes the bound 100")

function alt(n)
    sign = iseven(n) ? 1 : -1
    1 + sign // n
end

@assert abs(alt(11) - 1) == 1 // 11
@assert abs(alt(11) - 1) < ε
println("alternating distance to 1 equals 1/n")

vals = [1, 1, 1]
@assert length(unique(vals)) == 1
println("constant sequence has range {1}")

function ends(n)
    sign = iseven(n) ? 1 : -1
    sign + sign // n
end

@assert abs(ends(2) - ends(3)) > 2
println("consecutive terms of the two-endpoint sequence stay more than 2 apart")

println("END ====")
