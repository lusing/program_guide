# 06 · 多重派发 ⭐

> 对应示例：`examples/06_dispatch/`
>
> Julia 的核心机制：**方法选择看全部实参类型**。本章是全书枢纽，值得反复读。

## 6.1 函数与方法：一对多

"函数"是名字，"方法"是它对某组参数类型的实现。调用时 Julia 收集**所有实参类型**，在方法表里选**最具体**的匹配：

```julia
collide(a, b) = "未知 × 未知"                        # 最泛兜底
collide(a::Integer, b::Integer) = "数 × 数"
collide(a::AbstractString, b::AbstractString) = "串 × 串"
collide(a::Integer, b::AbstractString) = "数 × 串"

collide(1, 2)          # "数 × 数"
collide("x", "y")      # "串 × 串"
collide(1, "x")        # "数 × 串"
collide("x", 1)        # "未知 × 未知"——没有更具体的 → 兜底
collide(true, false)   # "数 × 数"——注意 Bool <: Integer！（07 章）
```

对比 OOP：`a.collide(b)` 只看 a 的类（单分派），b 只能 if-else 类型判断；Julia 的 `collide(a, b)` 天生二维——**组合爆炸的问题交给方法表**。

## 6.2 没有方法时：MethodError（不是隐式转换）

```julia
shape_area(s) = error("不认识的形状")    # 兜底也可以选择抛错
overlap(Rect(1, 1), Circle(1))           # MethodError——无方法也无兜底
```

Julia 不做隐式类型转换来找方法（`collide(1.5, 2)` 落到 `(Any, Any)` 兜底而不是转成 Integer）。 MethodError 的错误信息会列出所有候选方法——**读方法表是排错基本功**。

## 6.3 方法表内省：methods / which / @which

```julia
meets(x, y) = x + y                     # 泛型方法
meets(x::Integer, y::Integer) = x + y + 100
meets(1, 2)         # 103——选了更具体的
meets(1.5, 2.5)     # 4.0

which(meets, (Int, Int))     # meets(x::Integer, y::Integer) @ Main main.jl:32
length(methods(shape_area))  # 3——数一数方法表
```

`which(f, (T1, T2))` 回答"这个调用会选谁"；`.sig` 是**声明**的形参类型（`Tuple{typeof(meets), Integer, Integer}`，不是调用时的 Int）；REPL 里 `@which f(args)` 更顺手。

## 6.4 歧义（ambiguity）：两个方法各覆盖一半

```julia
amb(x::Integer, y::AbstractFloat) = "Int × Float 家族"
amb(x::Number,   y::Float64)     = "Number × Float64"
amb(1, 2.0)      # ❌ MethodError: ambiguous——两个候选谁也不比谁具体

amb(x::Integer, y::Float64) = "Int × Float64（桥方法）"   # ✅ 消除歧义
amb(Int32(1), 2.0)   # 桥方法
amb(1, Float16(2))   # "Int × Float 家族"
amb(1 // 2, 2.0)     # "Number × Float64"
```

规则：**定义第三个更具体的"桥方法"**。Julia 拒绝静默猜测歧义——这是特性不是缺陷。

## 6.5 签名约束是双向契约

```julia
toint8(x) = Int8(x)                    # 非精确浮点 → InexactError
toint8(x::Integer) = Int8(x % Int8)    # 整数走环绕版（% T = 环绕转换）
toint8(300)      # Int8(44)——300 - 256 环绕
toint8(300.0)    # InexactError——浮点版无环绕
```

同一个函数名，签名不同 = 语义契约不同。给方法写窄签名既是对调用方的文档，也是给编译器的性能承诺（16 章）。

## 6.6 扩展 Base：给别人的类型加方法

类型和方法是**两个独立维度**——方法不必属于类型（对比 C++ 成员函数）。给自定义类型扩展 `Base.+`、`Base.show` 是日常：

```julia
struct Circle; r::Float64; end
Base.:+(a::Circle, b::Circle) = Circle(a.r + b.r)       # 扩展 + 
Base.show(io::IO, c::Circle) = print(io, "⚪(r=", c.r, ")")   # 定制打印
Circle(1.0) + Circle(2.0)        # ⚪(r=3.0)
sprint(show, Circle(2.5))        # "⚪(r=2.5)"——sprint 把 show 输出收进字符串
```

这就是 `*`（字符串）、`+`（数组 vcat 之外的语义）……整个生态的运作方式：**类型来自一处，方法来自四面八方**。纪律：只给"自己拥有其中一端"的组合加方法（类型是你的或函数是你的），给 `Base.:+(::Foo, ::Bar)` 两个都是别人的 = 型别海盗。

## 6.7 与 OOP 的心智迁移表

| OOP 概念 | Julia 对应 |
|---|---|
| 类 = 数据 + 方法 | struct 只有数据；方法挂在泛型函数上 |
| 虚函数/重载 | 方法表按全部实参选择 |
| 接口 interface | 抽象类型 + 约定方法集（15 章 AbstractVector） |
| 运算符重载 | 给 Base 操作符加方法（普通函数而已） |
| visitor/双重派发 | 天生多重派发，不需要模式 |

## 6.8 坑位清单

1. **Bool <: Integer**：`collide(true, false)` 命中 `::Integer` 方法——布尔参与派发时别忘它在类型树里是整数（6.1、07 章）。
2. **歧义要桥方法**：两个具体度"打平"的签名对某调用集同时最优 → MethodError: ambiguous——补一个交集签名（6.4）。
3. **`.sig` 是声明类型**：`which(...).sig` 给 `Integer` 不是调用时的 `Int`——内省时别混淆"声明"与"实参"（6.3）。
4. **show 的 io 参数别丢**：`Base.show(io::IO, c::Circle)` 必须往 io 打印，`print(io, ...)`；忘了 io 会递归触发 show 死循环。
5. **不隐式转换找方法**：`1.5` 不会转成 `Integer` 去命中方法——泛型兜底 `(a, b)` 才是 Float 的去处（6.1）。
