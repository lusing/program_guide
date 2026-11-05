# 第 13 章 完备集与连通集：Julia 通道。
# 康托尔集前两步留下和删掉的点，小区间的长度，以及带缺口的并集。
# 运行：julia --startup-file=no 13_perfect.jl

println("==== 13 perfect ====")

function in_e1(x)
    (0 <= x <= 1 // 3) || (2 // 3 <= x <= 1)
end

function in_e2(x)
    pieces = [(0, 1 // 9), (2 // 9, 3 // 9), (6 // 9, 7 // 9), (8 // 9, 1)]
    any(a <= x <= b for (a, b) in pieces)
end

@assert in_e1(0) && in_e1(1 // 4) && in_e1(1)
@assert !in_e1(1 // 2)
@assert in_e2(1 // 4)
@assert !in_e2(1 // 2)
println("0, 1/4, 1 stay in E1; 1/2 is removed; 1/4 still in E2")

@assert (1 // 2) > (1 // 9)
@assert 2^2 == 4
println("E2 has 4 pieces of length 1/9, shorter than 1/2")

function in_gap(x)
    (-3 <= x < 0) || (0 < x <= 3)
end

@assert in_gap(-1) && in_gap(1) && !in_gap(0)
println("-1 and 1 are in [-3,0) U (0,3]; 0 is not")

println("END ====")
