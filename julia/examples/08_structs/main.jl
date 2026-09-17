# 08 结构体：struct/mutable、@kwdef、内外部构造器、参数化 struct、不可变语义
# 运行：julia --startup-file=no main.jl

# ═══ 08.1 不可变 struct：默认且首选（isbits 类型可内联、免堆分配）
struct Point
    x::Float64
    y::Float64
end
p = Point(1.0, 2.0)
@assert p.x == 1.0 && p.y == 2.0
@assert isbitstype(Point)                     # 纯数字字段 → 栈上值语义
# p.x = 9.0                                   # ERROR：不可变 struct 字段不能赋值
Base.:+(a::Point, b::Point) = Point(a.x + b.x, a.y + b.y)
@assert Point(1, 2) + Point(3, 4) == Point(4, 6)

# ═══ 08.2 mutable struct：需要"改"时才用
mutable struct Counter
    n::Int
end
c = Counter(0)
c.n += 1
@assert c.n == 1
@assert !isbitstype(Counter)
# 注意：mutable struct 的变量之间用 === 区分身份
@assert Counter(1) !== Counter(1)             # 两个不同对象
@assert Point(1.0, 2.0) === Point(1.0, 2.0)   # 不可变 isbits：按位相等

# ═══ 08.3 默认构造与字段自动转换：带类型注解的字段会 convert
struct NamedPoint
    name::String
    x::Float64
end
np = NamedPoint("原点", 1)                    # Int 自动转 Float64
@assert np.x isa Float64

# ═══ 08.4 @kwdef：关键字默认值构造（Base 宏，包作者人手一个）
Base.@kwdef struct ServerConfig
    host::String = "localhost"
    port::Int = 8080
    debug::Bool = false
end
@assert ServerConfig().port == 8080
@assert ServerConfig(port = 443, host = "ex.com").host == "ex.com"

# ═══ 08.5 外部构造器：给已有类型加便捷构造（不改原类型）
Point(p::Tuple) = Point(p[1], p[2])
origen() = Point(0, 0)
@assert Point((3.0, 4.0)) == Point(3.0, 4.0)
@assert origen() == Point(0.0, 0.0)

# ═══ 08.6 内部构造器：守不变量（invariant）——唯一能干"拒绝非法构造"的地方
struct Email
    addr::String
    function Email(addr::AbstractString)
        occursin('@', addr) || throw(ArgumentError("非法邮箱：$(addr)"))
        new(lowercase(addr))
    end
end
@assert Email("A@B.com").addr == "a@b.com"
function throws_argumenterror(f)
    try; f(); false
    catch e; e isa ArgumentError
    end
end
@assert throws_argumenterror(() -> Email("no-at-sign"))

# ═══ 08.7 参数化 struct：类型参数 T 让容器/算法泛化且不损失性能
struct Box{T}
    value::T
end
@assert Box(1) isa Box{Int} && Box(1.0) isa Box{Float64}
@assert Box{Int}(1) isa Box{Int}
# 注意：Box{Int} 与 Box{Float64} 互不为子类型；共同父类是 Box（或 Box{<:Real}）
@assert !(Box{Int} <: Box{Float64})
@assert Box{Int} <: Box && Box{Int} <: Box{<:Integer}
unwrap(b::Box{T}) where {T} = (b.value, T)    # 方法里也能拿到类型参数
@assert unwrap(Box("hi")) == ("hi", String)

# 参数化 + 内部构造器组合：约束类型参数
struct Meter{T <: Real}
    v::T
    Meter{T}(v) where {T <: Real} = v >= 0 ? new(v) : throw(ArgumentError("长度非负"))
end
Meter(v::T) where {T <: Real} = Meter{T}(v)   # 外部便捷构造转发到内部
@assert Meter(3).v == 3 && Meter(3) isa Meter{Int}
@assert throws_argumenterror(() -> Meter(-1))

# ═══ 08.8 单例类型：无字段 struct 每次构造都是同一个值
struct Unit end
@assert Unit() === Unit()
@assert isbitstype(Unit)

println("Point(1,2)+Point(3,4) = ", Point(1, 2) + Point(3, 4), "；ServerConfig() = ", ServerConfig())
println("==== 08 结束 ====")
