# 第 11 章 紧集：Julia 通道。
# [-3,3] 的一个有限子覆盖；(0,1) 的嵌套开覆盖漏掉端点附近的点；
# (0, 1/n) 的无限交在样本上是空的，任意有限交却非空。
# 运行：julia --startup-file=no 11_compact.jl

println("==== 11 compact ====")

function in_subcover(x)
    (-4 < x < 0) || (-1 < x < 3) || (2 < x < 6)
end

grid = [k//2 for k in -6:6]
@assert all(in_subcover(x) for x in grid)
println("[-3,3] by halves sits in (-4,0) U (-1,3) U (2,6)")

function escapes(N)
    x = 1 // (2 * N)
    inner_left = 1 // N
    0 < x < 1 && !(inner_left < x)
end

@assert all(escapes(N) for N in 1:20)
println("1/(2N) is in (0,1) and left of (1/N, 1-1/N)")

function in_all_open(x)
    all(0 < x < 1//n for n in 1:40)
end

sample = [k//20 for k in 0:20]
@assert all(!in_all_open(x) for x in sample)
println("no sample point lies in every (0, 1/n)")

finite_inter(k) = 0 < (1//(2 * k)) < 1//k
@assert all(finite_inter(k) for k in 1:20)
println("each finite intersection (0, 1/k) still holds 1/(2k)")

println("END ====")
