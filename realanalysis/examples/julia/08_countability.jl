# 第 08 章 可数性：Julia 通道。
# 交错枚举 ℤ、对角线逃逸、约分有理数的对角线列举。
# 运行：julia --startup-file=no 08_countability.jl

println("==== 08 countability ====")

zig(n) = iseven(n) ? n ÷ 2 : -((n + 1) ÷ 2)
unzig(z) = z >= 0 ? 2 * z : -2 * z - 1

@assert [zig(n) for n in 0:5] == [0, -1, 1, -2, 2, -3]
@assert all(zig(unzig(z)) == z for z in -20:20)
@assert all(unzig(zig(n)) == n for n in 0:40)
println("zigzag bijection on sample: 0,-1,1,-2,2,-3,...")

function diagonal(rows)
    n = length(rows)
    [rows[i][i] == 0 ? 1 : 0 for i in 1:n]
end

rows = [
    [0, 1, 0, 1],
    [1, 1, 0, 0],
    [0, 0, 0, 1],
    [1, 0, 1, 1],
]
s = diagonal(rows)
@assert all(s[i] != rows[i][i] for i in 1:4)
println("diagonal escape differs on the diagonal")

function rationals(limit)
    out = Rational{Int}[]
    s = 1
    while length(out) < limit
        for b in 1:s
            a = s - b
            if gcd(a, b) == 1
                push!(out, a // b)
                a != 0 && push!(out, -a // b)
            end
        end
        s += 1
    end
    out[1:limit]
end

qs = rationals(12)
@assert length(unique(qs)) == length(qs)
@assert 0 // 1 in qs && 1 // 1 in qs && -1 // 1 in qs && 1 // 2 in qs
println("first reduced rationals are unique, include 0, ±1, 1/2")

println("END ====")
