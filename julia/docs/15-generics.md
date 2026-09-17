# 15 · 参数化与接口

> 对应示例：`examples/15_generics/`

## 15.1 where 子句：方法级类型参数

```julia
firstel(v::AbstractVector{T}) where {T} = (v[1], T)   # 捕获元素类型
firstel([1, 2])          # (1, Int)
firstel([1.5])           # (1.5, Float64)

same_type(x::T, y::T) where {T} = true      # 两实参同一类型才命中
same_type(x, y) = false
same_type(1, 2)           # true
same_type(1, 2.0)         # false

pairsum(a::T, b::T) where {T <: Real} = a + b    # 带约束
pairsum("a", "b")         # MethodError——String 不是 Real
```

where 让"类型即值"参与方法签名：约束是编译器与调用方的双重契约。

## 15.2 `Type{T}`：捕获类型本身

```julia
whattype(::Type{Int}) = "整型"              # 只有传 Int 这个"值"才命中
whattype(::Type{T}) where {T} = "其他：$(T)"
whattype(Int)             # "整型"
whattype(String)          # "其他：String"

vec_of(T::Type, n::Int) = zeros(T, n)       # 类型当第一参数的"构造器风格"
zero_like(::Type{T}) where {T <: Number} = zero(T)
```

`Type{Int}` 只匹配"Int 本身"（不是 Int 的实例）——07 章类型是一等值的落地。

## 15.3 `Val{N}`：把值编码进类型（值派发）

```julia
valmirror(::Val{1}) = "一"
valmirror(::Val{2}) = "二"
valmirror(::Val) = "其他"
valmirror(Val(1))         # "一"——按"编译期常量"分派
count_args(::Val{N}) where {N} = N
count_args(Val(4))        # 4
```

`Val(4)` 把数字 4 变成类型参数——编译器可为每个 N 生成专属代码。小规模分派利器，滥用会编译时间爆炸（Val 坑：**从运行期值构造 `Val(x)` 再派发没有收益**——只有在编译期常量流入时才快）。

## 15.4 鸭子类型 vs 类型约束

```julia
mydot(u, v) = sum(u .* v)                 # 零约束：任何支持 .* 与 sum 的类型
mydot([1, 2], [3, 4]) == 11               # 测试即文档

mydot2(u::AbstractVector{<:Real}, v::AbstractVector{<:Real}) = sum(u .* v)
```

Julia 的实用主义：**不写约束 = 最大泛化**（你的类型只要"有这些操作"就能用）；写约束 = 契约 + 编译器假设。库的公开 API 通常两者都提供（宽松入口 + 具体方法）。

## 15.5 实现 AbstractVector：两个方法换整个生态 ⭐

自定义容器只需实现 `size` 与 `getindex`，**整个 Base/LinearAlgebra 生态免费附赠**：

```julia
struct SVec{T} <: AbstractVector{T}
    data::Vector{T}
end
Base.size(v::SVec) = (length(v.data),)
Base.getindex(v::SVec, i::Int) = v.data[i]

sv = SVec([3, 1, 2])
sum(sv) == 6 && minimum(sv) == 1          # 归约免费
collect(sv) == [3, 1, 2]
sort(sv) == [1, 2, 3]                     # 排序免费
(sv .+ 1) == [4, 2, 3]                    # 广播免费（10 章）
sv * 2 == [6, 2, 4]                       # 数乘免费
dot(SVec([1.0, 0.0]), SVec([0.0, 1.0])) == 0.0   # 线性代数免费
sv == [3, 1, 2]                           # 与普通 Vector 比较：免费
map(+, SVec([1, 2]), SVec([10, 20]))      # 多容器 map：免费
```

这就是"接口靠约定"的 Julia 式答案：**没有 interface 关键字**，子类型化 `AbstractVector{T}` + 实现约定方法 = 接口完成。同理可实现 `AbstractDict`、`AbstractArray{T,N}`、迭代协议（`iterate`）——标准库的每类容器都有这样的"最小方法集"文档。

## 15.6 泛型算法：一份代码吃遍容器

```julia
function fillall(c, value)          # 对任何"可下标赋值"的容器成立
    for i in eachindex(c)
        c[i] = value
    end
    c
end
fillall([0, 0], 7)                    # Vector
fillall(zeros(2, 2), 5)               # Matrix——eachindex 通吃任意维
```

## 15.7 坑位清单

1. **`::Type{T}` 只匹配类型值**：`whattype(1)` 落不到 `::Type{Int}` 方法（1 不是 Int 类型本身）——传的是 1 时签名写 `::Int`（15.2）。
2. **`Val` 从运行期值构造无收益**：`valmirror(Val(runtime_n))` 每个新 n 都要编译新特化——值派发只配编译期常量（15.3）。
3. **实现 AbstractVector 别忘 `setindex!`**：只要读就 size+getindex；要写（fillall 这类）还得加 `Base.setindex!(v, x, i)`（15.5/15.6）。
4. **`AbstractVector{<:Real}` 也要 Vector 适配**：约束签名排除了复数/字符串向量——写约束前想清楚要不要放进来（15.4）。
5. **协变匹配用 `{<:T}`**：`[1,2,3] isa AbstractVector{<:Integer}` 为 true、`isa AbstractVector{Integer}` 为 false（07 章不变性在方法签名里的化身）。
