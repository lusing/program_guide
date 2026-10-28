# 第 80 章：有理数精确区间套与 √2 下截断（while 实现）。
println("==== 80")

function bisect_sqrt2(n)
    lo, hi = big(1)//big(1), big(2)//big(1)
    intervals = [(lo, hi)]
    step = 0
    while step < n
        mid = (lo + hi)//big(2)
        if mid*mid < big(2)//big(1)
            lo = mid
        else
            hi = mid
        end
        step += 1
        @assert lo*lo < big(2)//big(1) <= hi*hi
        @assert hi-lo == (big(1)//big(2))^step
        push!(intervals, (lo, hi))
    end
    return intervals
end

intervals = bisect_sqrt2(40)
@assert intervals[4] == (11//8, 12//8)
@assert all(intervals[i+1][1] >= intervals[i][1] &&
            intervals[i+1][2] <= intervals[i][2] for i in 1:40)
lo, hi = intervals[end]
@assert hi-lo == (big(1)//big(2))^40
sqrt2cut(q) = q < 0//1 || q*q < 2//1
@assert sqrt2cut(7//5) && !sqrt2cut(3//2)
@assert sqrt2cut(-3//2)
println("Julia 有理数 while 二分：三步区间 [11/8,12/8]，40 步宽度 2^-40")
println("√2 下截断核对：7/5 在内，3/2 在外，负数按向下封闭自动在内 ✓")
println("数值近似不证明完备性；正文用尾部上/下确界证明柯西收敛")
println("END ====")
