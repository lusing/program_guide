# 第 09 章 拓扑定义：Julia 通道。
# 距离三公理的数值核对、开球、[-3,3] 有界、端点是开区间的极限点。
# 运行：julia --startup-file=no 09_metric.jl

println("==== 09 metric ====")

d(p, q) = abs(p - q)

pts = [-3.0, -1.5, 0.0, 1.0, 3.0]
@assert all(d(p, p) == 0 for p in pts)
@assert all(d(p, q) == d(q, p) for p in pts, q in pts)
@assert all(d(p, q) <= d(p, r) + d(r, q) for p in pts, q in pts, r in pts)
println("distance axioms on a sample")

ball(p, r) = x -> d(p, x) < r
@assert ball(0.0, 3.0)(2.9)
@assert !ball(0.0, 3.0)(3.0)
@assert !ball(0.0, 3.0)(-3.0)
println("ball(0,3) contains 2.9, excludes the endpoints")

@assert all(d(p, 0.0) <= 3 for p in -3.0:0.5:3.0)
println("[-3,3] is bounded by 0 and M=3")

# 3 is a limit point of (-3,3): 3 - 1/n stays inside and approaches 3.
seq = [3 - 1 / n for n in 1:20]
@assert all(-3 < x < 3 for x in seq)
@assert abs(seq[end] - 3) < 0.1
println("3-1/n in (-3,3) approaches the missing endpoint")

# Q dense sample: between any two floats in the list, a rational midpoint.
function mid_rational(a, b)
    (a + b) / 2
end
@assert -3 < mid_rational(-3.0, 3.0) < 3
println("midpoint of an interval lies strictly inside")

println("END ====")
