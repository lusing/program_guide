# 07 类型系统 ⭐：类型树、抽象/具体、Union、Nothing/missing、类型是一等值
# 运行：julia --startup-file=no main.jl

# ═══ 07.1 类型树：supertype 链一路向上到 Any
@assert Int <: Integer <: Real <: Number <: Any
@assert Float64 <: AbstractFloat <: Real
@assert String <: AbstractString
@assert Bool <: Integer                     # Bool 是 Integer 的子类型（true 即 1）
@assert supertype(Int) === Signed
@assert supertype(Signed) === Integer
chain(t) = t === Any ? [Any] : [chain(supertype(t))..., t]   # 收集整条继承链
@assert chain(Int32) == [Any, Number, Real, Integer, Signed, Int32]
@assert chain(String) == [Any, AbstractString, String]
println("Int32 的继承链 = ", chain(Int32))

# ═══ 07.2 兄弟不互斥于父类：具体类型是"叶子"，不能有子类
@assert isconcretetype(Int) && isconcretetype(String)
@assert isabstracttype(Integer) && isabstracttype(Real)
@assert !(Int32 <: Int64) && !(Int64 <: Int32)   # 具体类型之间只有 <
# 抽象类型只能声明（无字段、不能实例化）：
abstract type Shape end
abstract type Polygon <: Shape end
@assert Polygon <: Shape && Shape <: Any
struct Triangle <: Polygon
    a::Float64; b::Float64; c::Float64
end
@assert Triangle <: Polygon && Triangle <: Shape && isconcretetype(Triangle)

# ═══ 07.3 Union：类型层面的"或"；Union{} 是万物之底
const IntOrFloat = Union{Int, Float64}
@assert 1 isa IntOrFloat && 1.5 isa IntOrFloat && !(Bool isa IntOrFloat)
@assert Union{} <: Int <: Any               # Union{}（底部类型）是任何类型的子类型
@assert typejoin(Int, Float64) === Real     # 最小公共祖先
@assert promote_type(Int8, Float64) === Float64   # 提升用（算术用 promote_type 而非 typejoin）
@assert typeintersect(Integer, Real) === Integer

# ═══ 07.4 三种"空"：nothing/missing/Union{}
@assert nothing isa Nothing                 # 单例：函数"没有返回值"
@assert missing isa Missing                 # 单例：统计意义上的缺失值（三值逻辑！）
@assert (missing == 1) === missing          # 传染：与任何值的 == 都是 missing，包括 missing == missing！
@assert (missing == missing) === missing    # 想判等用 isequal / ismissing
@assert ismissing(missing)
@assert (missing == 1) === missing          # 传染性：比较结果是 missing 不是 false
@assert isequal(NaN, NaN)                   # isequal 区分 NaN（== 则 false）
@assert !isequal(missing, nothing)          # isequal 视 missing 相等；isequal 与 == 的差异

# ═══ 07.5 类型是一等值：可以传递、比较、当字典键
function nameof_type(::Type{T}) where {T}   # Type{T} 捕获类型本身（15 章细讲）
    string(T)
end
@assert nameof_type(Int) == "Int64"          # Int 在 64 位系统即 Int64
types = Dict(Int => "整数", Float64 => "浮点", String => "字符串")
@assert types[Int64] == "整数"
@assert typeof(Int) === DataType && typeof(Union{Int,Float64}) === Union

# ═══ 07.6 primitive type：自定义位级类型（几乎不用，但能看清"具体类型"的本质）
primitive type Packed24 24 end              # 24 位原语类型（无字段、按位存储）
@assert sizeof(Packed24) == 3               # 24 bit = 3 byte
@assert isbitstype(Packed24)

# ═══ 07.7 isa 与 typeof：运行时查类型；eltype 查容器元素类型
@assert typeof(3.14) === Float64
@assert typeof("abc") === String
@assert typeof('中') === Char
@assert typeof([1, 2]) === Vector{Int}      # Vector{Int} 是 Array{Int,1} 的别名
@assert typeof([1 2; 3 4]) === Matrix{Int}  # Matrix{Int} = Array{Int,2}
@assert eltype([1.0, 2.0]) === Float64
@assert [1, 2] isa AbstractVector{<:Integer}   # 协变匹配：<: 在参数位置

println("类型即值：typeof(Int) = ", typeof(Int), "；Vector{Int} 的父链 = ", chain(Vector{Int}))
println("==== 07 结束 ====")
