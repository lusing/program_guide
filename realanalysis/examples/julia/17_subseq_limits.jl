# 第 17 章 子序列极限：Julia 通道。
# n^2 越过 10，-5n 降到 -10 以下，(-1)^n 仍贴着 ±1，
# 偶数项 [(-1)^n+1]*n 变成 4, 8, 12。
# 运行：julia --startup-file=no 17_subseq_limits.jl

println("==== 17 limsup ====")

@assert 4^2 > 10
println("4^2 is already past 10")

@assert -5 * 4 < -10
println("-5*4 is below -10")

@assert (-1)^2 == 1 && (-1)^3 == -1
@assert abs((-1)^4) < 10
println("(-1)^n stays at 1 or -1, so it is not past 10")

spike(n) = ((-1)^n + 1) * n
@assert spike(1) == 0 && spike(3) == 0 && spike(5) == 0
@assert spike(2) == 4 && spike(4) == 8 && spike(6) == 12
@assert spike(6) > 10
println("odd terms of the spike are 0; even terms 4, 8, 12 climb past 10")

println("END ====")
