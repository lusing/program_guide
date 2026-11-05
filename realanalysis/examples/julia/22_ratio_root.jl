# 第 22 章 比值判别法与根值判别法：Julia 通道。
# 2^3/3! / (2^2/2!) = 2/3；2^n 的比值恒为 2；
# (n/(2n+1))^n 被 (3/5)^n 控制；调和相邻项之比趋于 1。
# 运行：julia --startup-file=no 22_ratio_root.jl

println("==== 22 ratio root ====")

@assert (2//1)^3 / factorial(3) / ((2//1)^2 / factorial(2)) == 2//3
println("2^3/3! divided by 2^2/2! equals 2/3")

@assert (2//1)^(2+1) / (2//1)^2 == 2//1
println("the ratio of 2^n is always 2")

@assert (2//5)^2 <= (3//5)^2
println("(2/5)^2 is at most (3/5)^2")

for n in 0:8
    base = n//(2n+1)
    @assert base <= 3//5
    @assert base^n <= (3//5)^n
end
println("n/(2n+1) is at most 3/5 for n = 0..8, so the geometric bound holds")

@assert 2//1 / 3//1 == 2//3
println("harmonic ratio at n=1 is 2/3")

println("END ====")
