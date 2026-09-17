# 22 错误与调试：内建异常族、自定义异常、try/catch、栈跟踪、@show/@locals、Profiler、生态
# 运行：julia --startup-file=no main.jl

# ═══ 22.1 抛错的两种姿势：error（带消息）与 throw（带异常对象）
must_positive(n) = (n > 0 || error("n 必须为正，得到 $(n)"); √n)   # error：断言式失败（ErrorException）
@assert must_positive(9) == 3.0
function throws_type(f)                     # 小工具：f() 抛的异常类型（本章反复用）
    try
        f()
        nothing
    catch e
        typeof(e)
    end
end
@assert throws_type(() -> must_positive(-1)) === ErrorException

# ═══ 22.2 内建异常族：每类错误有专属类型（catch 里按类型分派）
@assert throws_type(() -> √(-1)) === DomainError           # 数学域外
@assert throws_type(() -> Int(3.99)) === InexactError      # 非精确转换（03 章）
@assert throws_type(() -> [1, 2][5]) === BoundsError       # 越界
@assert throws_type(() -> "a" + 1) === MethodError         # 无方法匹配
@assert throws_type(() -> parse(Int, "x")) === ArgumentError
@assert throws_type(() -> Dict()[:k]) === KeyError
@assert throws_type(() -> 1 ÷ 0) === DivideError           # 整数除零（浮点除零是 Inf！）
@assert throws_type(() -> 1) === nothing                   # 不抛——箭头是 -> 而非 =>（后者构造 Pair）
@assert throws_type(() -> "aé中"[3]) === StringIndexError  # 多字节切在字节中间（12 章）

# ═══ 22.3 try/catch/finally：只消化目标类型，其余 rethrow
function safe_div(a, b)
    try
        a ÷ b
    catch e
        e isa DivideError ? typemax(Int) : rethrow()
    finally
        nothing                                            # 清理必经之路（关文件等）
    end
end
@assert safe_div(6, 2) == 3 && safe_div(1, 0) == typemax(Int)

# ═══ 22.4 自定义异常：模块化的类型层次（异常也是类型树，06 章派发规则适用）
module Orders
    abstract type OrderError <: Exception end
    struct InsufficientStock <: OrderError
        sku::String
        want::Int
        have::Int
    end
    Base.showerror(io::IO, e::InsufficientStock) = print(io, "库存不足：$(e.sku) 要 $(e.want) 有 $(e.have)")
    struct InvalidSku <: OrderError
        sku::String
    end
    Base.showerror(io::IO, e::InvalidSku) = print(io, "非法 SKU：$(e.sku)")

    function place_order!(stock::Dict{String,Int}, sku::String, qty::Int)
        haskey(stock, sku) || throw(InvalidSku(sku))
        stock[sku] >= qty || throw(InsufficientStock(sku, qty, stock[sku]))
        stock[sku] -= qty
        qty
    end
end
stock = Dict("A1" => 5)
@assert Orders.place_order!(stock, "A1", 3) == 3
@assert throws_type(() -> Orders.place_order!(stock, "A1", 99)) === Orders.InsufficientStock
@assert occursin("库存不足", sprint(showerror, Orders.InsufficientStock("A1", 9, 1)))
# 捕获端按类型拿业务数据：
what = try
    Orders.place_order!(Dict("A1" => 0), "A1", 2)
catch e
    e isa Orders.InsufficientStock ? (e.sku, e.want, e.have) : rethrow()
end
@assert what == ("A1", 2, 0)

# ═══ 22.5 读 1.13 的错误与栈跟踪：current_exceptions 的正确姿势（实测 API 变更）
# 未捕获异常 Julia 自己打印"类型 → 定位 → 源码 + └┘ 标注 → Suggestion/Hint"四段式——整段读。
# catch 里拿"抛错点"的栈：老资料写 catch_stacktrace()（1.13 已删）或 stacktrace(backtrace())
# （只给捕获点链）——都不对，正确的是：
inner() = error("炸在深处")
outer() = inner()
frames = try
    outer()
    Base.StackFrame[]
catch
    stacktrace(Base.current_exceptions()[end][2])   # (异常, 回溯) 对 → 完整抛错链
end
names = [string(f.func) for f in frames]
@assert "inner" in names && "outer" in names        # 栈帧按调用点由内向外
println("栈帧（内→外）：", join(names[1:min(4, end)], " → "))

# ═══ 22.6 三件即时工具：showerror / @show / @locals
e = try; sqrt(-1.0); catch err; err; end
@assert e isa DomainError && occursin("sqrt", sprint(showerror, e))   # 异常 → 字符串（进日志/断言）
a, b = 3, 4
@show a + b                                          # 打印 "a + b = 7"（输出到 stdout）
function where_am_i(x)
    y = x * 2
    locals = Base.@locals                            # Dict{Symbol,Any}：一次看全局部（1.9+）
    (:y in keys(locals), y)
end
@assert where_am_i(5) == (true, 10)

# ═══ 22.7 计时与配额：诊断三件套（16 章细讲性能，这里讲"诊断姿势"）
function probe_me(v)
    s = 0.0
    for x in v
        s += x
    end
    s
end
v1 = rand(1000)
probe_me(v1)                                         # 预热
@assert (@elapsed probe_me(v1)) >= 0
@assert (@allocated probe_me(v1)) == 0               # 参数在测量外构造（否则 rand 的分配被算进去）
# 命令行旗标：--track-allocation=user（逐行分配）、--code-coverage=user（行覆盖）、
# --heap-size-hint=2G（内存上限提示 GC）、--check-bounds=yes（强制边界检查）、--depwarn=error（弃用转错误）

# ═══ 22.8 Profiler：内置采样剖析器
using Profile
busy(n) = (s = 0.0; for i in 1:n; s += sin(i) * cos(i); end; s)
busy(10)                                             # 预热编译
Profile.clear()
@profile busy(500_000)
data = Profile.fetch()                               # 采样回栈（Vector{UInt}）
@assert length(data) > 0
Profile.clear()                                      # REPL 里 Profile.print() 看树状聚合；火焰图用 ProfileView.jl

# ═══ 22.9 工具生态速查（均第三方：Pkg.add 后用）
# | 工具             | 用途                        | 类比          |
# |------------------|-----------------------------|---------------|
# | BenchmarkTools   | @btime 精确基准（防 GC 干扰）| google/benchmark |
# | JET.jl           | 静态类型/错误检查           | clang-tidy    |
# | Debugger.jl      | 逐行调试器（断点/单步）     | gdb           |
# | Infiltrator.jl   | 轻量"断点"宏 @infiltrate    | print 大法升级 |
# | Cthulhu.jl       | 逐层看类型推断 @descend     | —             |
# | Aqua.jl          | 包质量检查                  | lint 全家桶   |
# | Documenter.jl    | 文档生成（doctest）         | doxygen       |
# | Revise.jl        | 改代码不重启会话            | 热重载        |

# ═══ 22.10 错误策略分层
# 开发期断言（可关）@assert；业务校验 throw(ArgumentError)；"没找到"返回 nothing（07 章）；
# 数据缺失 missing；可恢复失败 → 自定义异常 + 类型化 catch。@assert 别当业务校验（可被优化剥离）。
function find_first_negative(xs)
    for (i, x) in enumerate(xs)
        x < 0 && return i
    end
    nothing
end
@assert find_first_negative([1, -2, 3]) == 2
@assert find_first_negative([1, 2]) === nothing

println("safe_div(1,0) = ", safe_div(1, 0), "；what_happened = ", what)
println("==== 22 结束 ====")
