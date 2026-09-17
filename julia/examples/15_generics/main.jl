# 15 参数化：where 子句、Type{T} 捕获、Val 值分派、自定义 AbstractVector 白嫖生态
# 运行：julia --startup-file=no main.jl

# ═══ 15.1 where 子句：方法级的类型参数
firstel(v::AbstractVector{T}) where {T} = (v[1], T)   # 捕获元素类型
@assert firstel([1, 2]) == (1, Int)
@assert firstel([1.5]) == (1.5, Float64)
same_type(x::T, y::T) where {T} = true                # 两个实参必须是同一类型才命中
same_type(x, y) = false
@assert same_type(1, 2) && !same_type(1, 2.0)
# where 的约束像类型版的"前提条件"
pairsum(a::T, b::T) where {T <: Real} = a + b
@assert pairsum(1, 2) == 3
pairsum_rejected = try                          # String 不是 Real → MethodError（断言式验证）
    pairsum("a", "b")
    false
catch e
    e isa MethodError
end
@assert pairsum_rejected

# ═══ 15.2 Type{T}：把"类型本身"当值捕获（07 章的进阶用法）
whattype(::Type{Int}) = "整型"
whattype(::Type{Float64}) = "浮点"
whattype(::Type{T}) where {T} = "其他：$(T)"
@assert whattype(Int) == "整型" && whattype(String) == "其他：String"
# 经典应用：与 zero/one 配对的"按类型初始化"
function zero_like(::Type{T}) where {T <: Number}
    zero(T)                  # 每个 Number 类型都知道自己的零值
end
@assert zero_like(Float64) == 0.0 && zero_like(Int) == 0
# 另一经典：dispatch on Type 参数实现"构造器多态"
vec_of(T::Type, n::Int) = zeros(T, n)
@assert vec_of(Int, 2) == [0, 0]

# ═══ 15.3 Val{T}：把"值"变成"类型"进签名（值分派；小容量用，热路径慎用）
valmirror(::Val{1}) = "一"
valmirror(::Val{2}) = "二"
valmirror(::Val) = "其他"
@assert valmirror(Val(1)) == "一" && valmirror(Val(9)) == "其他"
function count_args(::Val{N}) where {N}
    N                        # 编译期把 N 当常数用（编译器常量传播）
end
@assert count_args(Val(4)) == 4

# ═══ 15.4 duck typing vs 类型约束：Julia 的实用主义
# 不写约束 = 对任何支持所用操作的类型成立（最泛型）
mydot(u, v) = sum(u .* v)                  # 任何能 .* 和 sum 的都行
@assert mydot([1, 2], [3, 4]) == 11
# 写约束 = 给调用方契约、给编译器假设（也是文档）
mydot2(u::AbstractVector{<:Real}, v::AbstractVector{<:Real}) = sum(u .* v)
@assert mydot2([1.0, 2.0], [3.0, 4.0]) == 11.0
# 协变参数位置用 <:，不变位置用 {T}
@assert [1, 2, 3] isa AbstractVector{<:Integer}
@assert [1, 2] isa AbstractVector{Int}     # 精确匹配也行

# ═══ 15.5 实现 AbstractVector 接口：两个方法换整个生态
struct SVec{T} <: AbstractVector{T}
    data::Vector{T}
end
Base.size(v::SVec) = (length(v.data),)
Base.getindex(v::SVec, i::Int) = v.data[i]
sv = SVec([3, 1, 2])
# 免费得到：map/filter/sum/sort/广播/线性代数……全部按我们的元素语义工作
@assert sum(sv) == 6 && minimum(sv) == 1
@assert map(x -> 10x, sv) isa Vector              # map 落到普通 Vector
@assert collect(sv) == [3, 1, 2]
@assert sort(sv) == [1, 2, 3]
@assert (sv .+ 1) == [4, 2, 3]                    # 广播也通了
@assert sv * 2 == [6, 2, 4]                        # 数乘（向量语义）
using LinearAlgebra
@assert dot(SVec([1.0, 0.0]), SVec([0.0, 1.0])) == 0.0
# 尺寸检查等"断言式文档"：Base.@invoke / promote 规则按需加

# ═══ 15.6 泛型函数的"跨类型一招鲜"：同一份代码，多种容器
function fillall(c, value)
    for i in eachindex(c)
        c[i] = value
    end
    c
end
@assert fillall([0, 0], 7) == [7, 7]
@assert fillall(zeros(2, 2), 5) == [5 5; 5 5]      # 矩阵也行——eachindex 通吃
@assert fillall(Matrix{Float64}(undef, 1, 1), 0.5) == reshape([0.5], 1, 1)

println("firstel([1,2]) = ", firstel([1, 2]), "；sort(sv) = ", sort(sv), "；valmirror(Val(1)) = ", valmirror(Val(1)))
println("==== 15 结束 ====")
