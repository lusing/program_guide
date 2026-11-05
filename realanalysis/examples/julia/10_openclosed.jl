# 第 10 章 闭集和开集：Julia 通道。
# 无限交收成 {0}，无限并不含右端点 2，闭包用 3-1/n 去碰 3，
# [1, 2) 相对 [0, 2) 不需要检查缺掉的 2。
# 运行：julia --startup-file=no 10_openclosed.jl

println("==== 10 open closed ====")

survives(x) = all(-1//n < x < 1//n for n in 1:40)
sample = [k//10 for k in -20:20]
alive = [x for x in sample if survives(x)]
@assert alive == [0//1]
@assert !survives(1//10)
println("nested open intervals keep only 0 from the tenths")

in_union(x) = any(0 <= x <= 2 - 1//n for n in 1:40)
@assert !in_union(2//1)
@assert in_union(0//1)
@assert in_union(3//2)
println("union of [0, 2-1/n] reaches 3/2 and stops short of 2")

seq = [3 - 1//n for n in 1:20]
@assert all(-3 < x < 3 for x in seq)
@assert abs(seq[end] - 3) < 1//10
println("3-1/n in (-3,3) approaches the closure endpoint 3")

inY(x) = 0 <= x < 2
inE(x) = 1 <= x < 2
@assert inY(3//2) && inE(3//2)
@assert !inY(2//1) && !inE(2//1)
@assert inY(1//2) && !inE(1//2)
println("[1, 2) sits in [0, 2); the point 2 is outside the subspace")

pts = [k//5 for k in -14:14]
@assert maximum(pts) < 3
println("a finite sample of (-3,3) stays strictly below the supremum 3")

println("END ====")
