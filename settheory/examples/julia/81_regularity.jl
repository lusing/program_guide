# 第 81 章：Cantor 区间的精确有理数有限层实验。
println("==== 81")

function children(interval)
    a, b = interval
    third = (b-a)//big(3)
    return ((a, a+third), (b-third, b))
end

function cantor_levels(n)
    levels = [[(big(0)//big(1), big(1)//big(1))]]
    for k in 1:n
        previous = levels[end]
        current = Tuple{Rational{BigInt},Rational{BigInt}}[]
        for interval in previous
            left, right = children(interval)
            @assert interval[1] <= left[1] < left[2] <= interval[2]
            @assert interval[1] <= right[1] < right[2] <= interval[2]
            @assert left[2] < right[1]
            push!(current, left, right)
        end
        @assert length(current) == 2^k
        @assert all(b-a == (big(1)//big(3))^k for (a,b) in current)
        @assert all(current[i][2] < current[i+1][1] for i in 1:length(current)-1)
        push!(levels, current)
    end
    return levels
end

levels = cantor_levels(8)
for k in 0:8
    total = sum(b-a for (a,b) in levels[k+1])
    @assert total == (big(2)//big(3))^k
end
@assert length(levels[end]) == 256
@assert levels[5][3] == (big(2)//big(27), big(7)//big(81))
println("Julia：第 8 层有 256 个两两分离的闭区间，每个长 3^-8")
println("第 k 层总长度恰为 (2/3)^k（0≤k≤8）；极限零测与完备性另由正文证明")
println("END ====")
