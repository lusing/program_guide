# 07 · 类型系统 ⭐

> 对应示例：`examples/07_typesystem/`

## 7.1 类型树：一棵向下生长的 DAG

所有类型都是 `Any` 的后代；`<:` 读作"是……的子类型"：

```julia
Int <: Integer <: Real <: Number <: Any        # 全 true
Float64 <: AbstractFloat <: Real
String <: AbstractString
Bool <: Integer                                 # ！
```

向上爬用 `supertype`，一条链收齐：

```julia
chain(Int32)    # [Any, Number, Real, Integer, Signed, Int32]
chain(String)   # [Any, AbstractString, String]
```

两条铁律：

- **抽象类型不能实例化**（`Integer(5)` 不行），只当"路由节点"给方法签名用；
- **具体类型是叶子**：`Int` 不能再有子类型（想"继承 Int"请组合 + 派发，不是继承）。

## 7.2 声明自己的抽象层

```julia
abstract type Shape end
abstract type Polygon <: Shape end      # 抽象类型可以嵌套声明

struct Triangle <: Polygon
    a::Float64; b::Float64; c::Float64
end
Triangle <: Shape       # true——具体类型挂在抽象层下
isconcretetype(Triangle) && isabstracttype(Shape)
```

## 7.3 Union：类型层面的"或"

```julia
const IntOrFloat = Union{Int, Float64}
1 isa IntOrFloat && 1.5 isa IntOrFloat      # true
Union{} <: Int <: Any                       # Union{}（底部类型）是万物之子
typejoin(Int, Float64) === Real             # 最小公共祖先
promote_type(Int8, Float64) === Float64     # 算术提升用（≠ typejoin）
typeintersect(Integer, Real) === Integer    # 最大公共后代
```

Union 不是摆设：**小 Union（≤3 个成员）编译器能生成高效的分支代码**（16 章的性能含义）；`Union{Nothing, T}` 是"可空"的标准姿势。

**坍缩规则**：单成员 `Union{Int}` 就是 `Int` 本身——`typeof(Union{Int}) === DataType`（实测坑）。

## 7.4 三种"空"：nothing / missing / Union{}

| 值 | 类型 | 语义 | 惯用场 |
|---|---|---|---|
| `nothing` | `Nothing`（单例） | "没有返回值"/"没找到" | 函数副作用返回、`find...` 失败 |
| `missing` | `Missing`（单例） | 统计意义的缺失（三值逻辑） | 数据表 NULL |
| `Union{}` | 底部类型 | 没有任何值 | 类型运算的零元 |

`missing` 是**传染的**——这是本章最重要的实测行为：

```julia
missing == 1          # missing（不是 false！）
missing == missing    # 还是 missing！
0.1 + missing         # missing——运算也传染
# 判等/判缺用：
ismissing(x)          # true/false
isequal(missing, missing)     # true
sort([2, missing, 1])         # [1, 2, missing]——排序时 missing 恒最大
coalesce(missing, 42)         # 42——missing 兜底
something(nothing, 7)         # 7——nothing 兜底
skipmissing([1, missing, 2]) |> collect   # [1, 2]
```

把 `==` 用在可能含 missing 的数据上是逻辑炸弹——`if x == missing` 永远不成立（条件要求 Bool，missing 抛 TypeError）。

## 7.5 类型是一等值

```julia
typeof(Int) === DataType        # 类型本身的类型
types = Dict(Int => "整数", Float64 => "浮点")   # 类型当字典键
[1, 2] isa AbstractVector{<:Integer}            # 协变匹配：参数位置用 <:
```

类型可以传参、比较、存容器——`Type{T}` 捕获、`Val` 值派发都建立在这一点上（15 章）。参数化类型还有一条**不变性**（invariance）：

```julia
Vector{Int} <: Vector{Integer}      # false！！
Vector{Int} <: Vector               # true（抹掉参数）
Vector{Int} <: AbstractVector{<:Integer}   # true（<: 语法在参数位表达协变）
```

原因：`Vector{Integer}` 能装任何整数（元素是装箱的），`Vector{Int}` 是紧凑的 Int 数组——内存布局不同，不能互换。**想要"任何元素类型的向量"写 `AbstractVector{<:Integer}` 或 `Vector{<:Integer}`**（09/15 章反复用）。

## 7.6 primitive type：自己造叶子

```julia
primitive type Packed24 24 end     # 24 位原语（无字段、按位存储）
sizeof(Packed24)     # 3（字节）
isbitstype(Packed24) # true
```

几乎不用，但能看清"具体类型"的本质：固定大小、无堆引用（isbits）。`isbitstype(T)` 为真的类型走值语义、可内联进数组（08 章 struct 的性能含义）。

## 7.7 常用内省函数速查

| 函数 | 问的问题 |
|---|---|
| `typeof(x)` | x 的具体类型 |
| `x isa T` | x 是 T（或后代）吗 |
| `T <: U` | T 是 U 的子类型吗 |
| `supertype(T)` | 父类型 |
| `eltype(v)` | 容器元素类型 |
| `isconcretetype / isabstracttype` | 叶子 / 节点 |
| `isbitstype(T)` | 值语义可内联吗（性能！） |

## 7.8 坑位清单

1. **missing 传染 `==`**：`missing == missing` 也是 missing——判等用 `isequal`、判缺用 `ismissing`；含 missing 的数组断言用 `isequal`（7.4，实测两次踩中）。
2. **参数化类型不变**：`Vector{Int} <: Vector{Integer}` 是 false——协变要写 `Vector{<:Integer}`（7.5）。
3. **单成员 Union 坍缩**：`Union{Int}` === `Int`；`typeof` 单成员 Union 拿到的是 DataType 不是 Union（7.3）。
4. **Bool 是 Integer**：`true isa Integer` 为 true——写 `::Integer` 方法时布尔会溜进来（6 章坑位重现）。
5. **具体类型不能继承**：想特化 `Int` 的行为请写新类型 + 方法，别试图 `struct MyInt <: Int`（语法错误）。
