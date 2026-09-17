# 06 多重派发 ⭐：方法选择、按全部实参分派、歧义与消除、方法表内省
# 运行：julia --startup-file=no main.jl

# ═══ 06.1 同名函数，多个方法：按实参类型选择
collide(a, b) = "未知 × 未知"
collide(a::Integer, b::Integer) = "数 × 数"
collide(a::AbstractString, b::AbstractString) = "串 × 串"
collide(a::Integer, b::AbstractString) = "数 × 串"
@assert collide(1, 2) == "数 × 数"
@assert collide("x", "y") == "串 × 串"
@assert collide(1, "x") == "数 × 串"
@assert collide("x", 1) == "未知 × 未知"          # 没有更具体的方法 → 落到兜底方法

println("collide(1,2) = ", collide(1, 2), "；collide(\"x\",1) = ", collide("x", 1))

# ═══ 06.2 派发看"全部"实参——不是只看第一个（与 OOP 单分派的本质区别）
shape_area(s) = error("不认识的形状")              # 兜底：抛错也是方法
struct Circle; r::Float64; end
struct Rect; w::Float64; h::Float64; end
shape_area(c::Circle) = π * c.r^2
shape_area(r::Rect) = r.w * r.h
overlap(a::Circle, b::Circle) = "两圆：圆心距判交"
overlap(a::Rect, b::Rect) = "两矩形：投影判交"
overlap(a::Circle, b::Rect) = "圆 × 矩形：半径到矩形距离"
@assert shape_area(Circle(1.0)) ≈ π
@assert shape_area(Rect(2.0, 3.0)) == 6.0
@assert overlap(Circle(1), Rect(1, 1)) == "圆 × 矩形：半径到矩形距离"
println("methods(shape_area) 共有 ", length(methods(shape_area)), " 个方法（含兜底）")

# ═══ 06.3 方法表内省：methods / which / @which
meets(x, y) = x + y                              # 泛型方法：对任意支持 + 的类型成立
meets(x::Integer, y::Integer) = x + y + 100      # 更具体的 Int 版本
@assert meets(1.5, 2.5) == 4.0
@assert meets(1, 2) == 103                       # 选了更具体的方法
w = which(meets, (Int, Int))                     # 查询：这个调用会选哪个方法
@assert w.sig == Tuple{typeof(meets), Integer, Integer}   # .sig 是"声明"的形参类型
println("which(meets, (Int,Int)) → ", w)

# ═══ 06.4 歧义（ambiguity）：两个方法各覆盖一半，谁也不更具体
# f(x::Integer, y::AbstractFloat) 与 f(x::Number, y::Float64) 对 (Int, Float64) 歧义——
# 定义第三个更具体的方法即可消除：
amb(x::Integer, y::AbstractFloat) = "Int × Float 家族"
amb(x::Number, y::Float64) = "Number × Float64"
amb(x::Integer, y::Float64) = "Int × Float64（消除歧义的桥方法）"
@assert amb(1, 2.0) == "Int × Float64（消除歧义的桥方法）"
@assert amb(1, Float16(2)) == "Int × Float 家族"
@assert amb(1 // 2, 2.0) == "Number × Float64"

# ═══ 06.5 抽象收窄：方法签名决定编译器能假设什么
function throws_inexact(f)::Bool                 # 小工具：f() 是否抛 InexactError
    try
        f()
        return false
    catch e
        return e isa InexactError
    end
end
toint8(x) = Int8(x)                              # 对超范围值抛 InexactError
toint8(x::Integer) = Int8(x % Int8)              # 整数走环绕版
@assert toint8(300) == Int8(44)                  # 300 环绕（300 - 256）
@assert throws_inexact(() -> toint8(300.0))      # 浮点版无环绕——精确保留

# ═══ 06.6 派发的实用主义：操作符也是多方法
# 自定义类型的 +：给 Circle 定义加法（半径相加）——扩展 Base 函数是合法且常见操作
Base.:+(a::Circle, b::Circle) = Circle(a.r + b.r)
@assert (Circle(1.0) + Circle(2.0)).r == 3.0

# show 定制打印：派发到 Base.show
Base.show(io::IO, c::Circle) = print(io, "⚪(r=", c.r, ")")
@assert sprint(show, Circle(2.5)) == "⚪(r=2.5)"  # sprint 把 show 输出收进字符串

println("collide 家族 + Circle 扩展 + 全部通过")
println("==== 06 结束 ====")
