# 10 广播 ⭐：. 运算符、融合、.+=、@. 宏、自定义广播、标量/矩阵乘陷阱
# 运行：julia --startup-file=no main.jl

# ═══ 10.1 . 是广播：函数/运算符逐元素施用
v = [1.0, 4.0, 9.0]
@assert sqrt.(v) == [1.0, 2.0, 3.0]
@assert v .+ 1 == [2.0, 5.0, 10.0]
@assert v .^ 2 == [1.0, 16.0, 81.0]
@assert 2 .^ (1:3) == [2, 4, 8]              # 两侧都可广播
@assert abs.(-1:2) == [1, 0, 1, 2]           # 任何函数都能 f.(x)

# 广播自动扩展低维：标量、1×n 与 m×1 → 矩阵（outer 广播）
@assert [10, 20] .+ [1, 2]' == [11 12; 21 22]   # (2,1) + (1,2) → (2,2)
@assert fill(1, (2, 3)) .* [1, 2] == [1 1 1; 2 2 2]   # (2,3) .* (2,)：向量按"第一维"扩展（与 NumPy 的尾部对齐相反！）
# fill(1,(2,3)) .* [1,2,3] 会 DimensionMismatch：3 对不上第一维 2——列主序语言的广播对齐规则

# ═══ 10.2 * vs .* ——头号新手混淆点
A = [1.0 2.0; 3.0 4.0]
@assert A * A == [7.0 10.0; 15.0 22.0]       # 矩阵乘
@assert A .* A == [1.0 4.0; 9.0 16.0]        # 对应元素乘
# 字符串也能广播拼接：string. 家族
@assert string.("a", 1:2) == ["a1", "a2"]

# ═══ 10.3 融合（fusion）：一条广播表达式只遍历一次、不建中间数组
x = Float64.(1:1_000_000)
fused = x .+ 1 .* 2                       # 一次遍历、只分配一个结果数组（非 (x.+1).*2 的两个）
@assert fused[1] == 3.0 && fused[end] == 1_000_002.0
alloc_warm = @allocated(x .+ 1)           # 预热后测量：结果数组 ≈ length(x) × 8 字节
alloc_fused = @allocated(x .+ 1 .* 2)     # 融合后仍是"一个"结果数组的量级
println("分配对比：单广播 $(alloc_warm) B vs 融合 $(alloc_fused) B（应同量级，而非翻倍）")
# .= 是就地广播写入：零新分配
y = similar(x)
y .= x .* 2 .+ 1
@assert y[1] == 3.0 && y[end] == 2_000_001.0
# .+= 语法糖：x .+= 1 等价 x .= x .+ 1（就地）
z = [1, 2]
z .+= 10
@assert z == [11, 12]

# ═══ 10.4 @. 宏：整条表达式点"全上"（注意：连 == 也会被加点！）
w = [1.0, 4.0]
@assert (@. sqrt(w) + 1) == [2.0, 3.0]       # 等价 sqrt.(w) .+ 1；比较留在括号外
@assert (@. w^2 + 1) == [2.0, 17.0]          # 不加括号的话 == 变 .==，结果是 BitVector 而非 Bool
# @. 里想保留"整体调用"的函数用 $(f)：$(exp)(w) 不加点（了解即可）

# ═══ 10.5 广播到自定义类型：标量类型必须声明自己是"标量"（Ref 包装）
struct Celsius                     # 摄氏温度（isbits，字段就一个数）
    c::Float64
end
Base.:+(a::Celsius, b::Celsius) = Celsius(a.c + b.c)
# 不声明的话 broadcastable 会把 Celsius 当可迭代物 collect → MethodError: length(::Celsius)
Base.broadcastable(x::Celsius) = Ref(x)     # Ref：按"零维标量"广播（官方推荐姿势）
ts = [Celsius(1), Celsius(2)]
@assert (ts .+ Celsius(10)) isa Vector{Celsius}
@assert (ts .+ Celsius(10))[2].c == 12.0

# ═══ 10.6 广播 vs map：什么时候用哪个
@assert map(x -> x^2, 1:3) == [1, 4, 9]           # map 惰性收集、只支持单容器（多容器按位 zip）
@assert map((a, b) -> a + b, [1, 2], [10, 20]) == [11, 22]
@assert broadcast(x -> x^2, 1:3) == [1, 4, 9]     # broadcast 支持维度扩展；两者常等价
@assert [1, 2] .+ [10 20] == [11 21; 12 22]       # map 做不了维度扩展
# 生成器（11 章）不分配中间数组：sum(x^2 for x in 1:3)

# ═══ 10.7 广播陷阱
# 1) 标量函数调用忘了点：floor(v) 是整表取整函数？——floor.([1.5,2.5]) 才对
@assert floor.([1.7, 2.3]) == [1.0, 2.0]
# 2) 逻辑组合要用 .& / .|（向量化），不能 && / ||（标量短路——数组上直接报 TypeError）
mask = (v .> 2) .& (v .< 10)
@assert v[mask] == [4.0, 9.0]

println("sqrt.(v) = ", sqrt.(v), "；A .* A = ", A .* A)
println("==== 10 结束 ====")
