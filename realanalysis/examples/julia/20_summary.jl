# 第 20 章 总结：Julia 通道。
# 5 后面有 6；|3+(-1)| 不超过 3+1；两半加回 1。
# 并集的补集等于补集的交集。公比 1/2 的和是 2。
# 运行：julia --startup-file=no 20_summary.jl

println("==== 20 review ====")

@assert 6 > 5
println("6 is past 5")

@assert abs(3 + -1) <= abs(3) + abs(-1)
println("|3 + (-1)| does not exceed |3| + |-1|")

@assert 1//2 + 1//2 == 1//1
println("two halves add back to 1")

U = Set([1, 2, 3])
A = Set([1])
B = Set([2])
@assert setdiff(U, union(A, B)) == intersect(setdiff(U, A), setdiff(U, B))
println("the complement of a union is the intersection of the complements")

@assert 1//1 / (1//1 - 1//2) == 2//1
println("1 / (1 - 1/2) equals 2")

println("END ====")
