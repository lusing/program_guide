# 08 · 结构体

> 对应示例：`examples/08_structs/`

## 8.1 不可变 struct：默认且首选

```julia
struct Point
    x::Float64
    y::Float64
end
p = Point(1.0, 2.0)
p.x == 1.0                # 字段访问
# p.x = 9.0               # ERROR——不可变
Base.:+(a::Point, b::Point) = Point(a.x + b.x, a.y + b.y)
Point(1, 2) + Point(3, 4) == Point(4, 6)     # Int 实参自动 convert 成 Float64
```

不可变 + 全 isbits 字段 = **值语义 + 栈上/内联存储**：

```julia
isbitstype(Point)              # true——可内联进数组，比较按位
Point(1.0, 2.0) === Point(1.0, 2.0)   # true（逐位相等）
```

字段类型注解不只是文档——**构造时自动 `convert`**（`Point(1, 2)` 的 Int 被 convert 成 Float64），且让编译器能排布紧凑内存（16 章：无注解字段 = Any = 装箱）。

## 8.2 mutable struct：需要"改"才用

```julia
mutable struct Counter
    n::Int
end
c = Counter(0)
c.n += 1                 # 可变：字段可赋值
Counter(1) !== Counter(1)     # false！——可变对象按"身份"区分
Point(1.0, 2.0) === Point(1.0, 2.0)   # true——不可变按"内容"区分
```

`===`（egal）是身份判等：不可变 isbits 按位比，可变对象按"是不是同一个"。**默认写 struct，真有可变需求才加 mutable**——不可变让编译器自由复制、无锁共享。

## 8.3 @kwdef：关键字默认值构造

```julia
Base.@kwdef struct ServerConfig
    host::String = "localhost"
    port::Int = 8080
    debug::Bool = false
end
ServerConfig().port == 8080
ServerConfig(port = 443, host = "ex.com")
```

`Base.@kwdef` 是 Base 官方宏，包作者人手一个——配置类 struct 的标准姿势。

## 8.4 外部构造器：给已有类型加便捷构造

```julia
Point(p::Tuple) = Point(p[1], p[2])     # 元组构造
origen() = Point(0, 0)                   # 零参便捷
Point((3.0, 4.0)) == Point(3.0, 4.0)
```

新方法加在类型外（06 章的函数方法机制），不动原定义。

## 8.5 内部构造器：守不变量

```julia
struct Email
    addr::String
    function Email(addr::AbstractString)
        occursin('@', addr) || throw(ArgumentError("非法邮箱：$(addr)"))
        new(lowercase(addr))            # new 只在内部构造器里可用
    end
end
Email("A@B.com").addr      # "a@b.com"——顺手归一化
Email("no-at-sign")        # ArgumentError——非法状态进不来
```

**内部构造器一旦写了，默认构造器就没了**——`new(...)` 只在这里合法。它和外部构造器分工：内部守不变量（拒绝非法），外部做便捷（转换转发）。

## 8.6 参数化 struct

```julia
struct Box{T}
    value::T
end
Box(1) isa Box{Int} && Box(1.0) isa Box{Float64}
!(Box{Int} <: Box{Float64})            # 类型参数不变（07 章）
Box{Int} <: Box && Box{Int} <: Box{<:Integer}

unwrap(b::Box{T}) where {T} = (b.value, T)   # 方法里拿类型参数
unwrap(Box("hi"))     # ("hi", String)
```

参数化 + 内部构造器组合（约束类型参数）：

```julia
struct Meter{T <: Real}
    v::T
    Meter{T}(v) where {T <: Real} = v >= 0 ? new(v) : throw(ArgumentError("长度非负"))
end
Meter(v::T) where {T <: Real} = Meter{T}(v)   # 外部转发到内部
Meter(3) isa Meter{Int} && Meter(-1)          # ArgumentError
```

## 8.7 单例类型：无字段的极简

```julia
struct Unit end
Unit() === Unit()      # true——每次"构造"都是同一个值
isbitstype(Unit)
```

`Nothing`/`Missing` 就是这样的单例——你现在知道它们的实现原理了。

## 8.8 坑位清单

1. **内部构造器写掉默认构造**：定义了 `function Email(...)` 后 `Email(addr)` 只有你写的这一条路——便捷构造放外部（8.5）。
2. **可变 struct 的 `==` 是身份**：`Counter(1) == Counter(1)` 为 false（默认 == 落到 ===）；要值语义自己定义 `==`（24 章的 ODESolution 实测踩过）。
3. **无类型注解字段 = Any 字段**：`struct S; x; end` 的 x 是 `Any`——构造快但每次访问动态派发（16 章性能灾难清单）。
4. **@kwdef 写全限定 `Base.@kwdef`**：裸 `@kwdef` 在非 Main 模块里可能解析不到（老版本坑；1.13 已可裸用，但包代码里全限定更稳）。
5. **不可变 struct 含可变字段**：`struct T; v::Vector{Int}; end` 的 T 不可变，但 `t.v[1]=9` 合法——"不可变"锁的是字段绑定不是深层内容；此时 `===` 只比字段引用。
