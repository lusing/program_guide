# 13 异常：throw/error、内建异常族、try/catch/finally、自定义异常、栈跟踪
# 运行：julia --startup-file=no main.jl

# ═══ 13.1 抛错的两种姿势：error（带消息）与 throw（带异常对象）
# error(...) 抛ErrorException——适合"不该发生"的断言式失败
function must_positive(n)
    n > 0 || error("n 必须为正，得到 $(n)")
    √n
end
@assert must_positive(9) == 3.0
function throws_error(f)     # 小工具：f() 抛的异常类型
    try
        f()
        nothing
    catch e
        typeof(e)
    end
end
@assert throws_error(() -> must_positive(-1)) === ErrorException

# ═══ 13.2 内建异常族：每类错误有专属类型（catch 里按类型分派）
@assert throws_error(() -> √-1) === DomainError            # √ 负数（默认实数模式）
@assert throws_error(() -> Int(3.99)) === InexactError     # 03 章：非精确转换
@assert throws_error(() -> [1, 2][5]) === BoundsError      # 越界
@assert throws_error(() -> "a" + 1) === MethodError        # 无方法匹配
@assert throws_error(() -> parse(Int, "x")) === ArgumentError
@assert throws_error(() -> Dict()[:k]) === KeyError
@assert throws_error(() -> 1 ÷ 0) === DivideError         # 整数除零抛错（浮点除零是 Inf！）
@assert throws_error(() -> 1) === nothing                 # 不抛——注意箭头是 -> 而非 =>（后者构造 Pair）

# ═══ 13.3 try/catch/finally：catch 可以不带变量；finally 总执行
function safe_div(a, b)
    try
        a ÷ b
    catch e
        e isa DivideError ? typemax(Int) : rethrow()       # 只消化目标异常，其余继续抛
    finally
        nothing                                            # 清理动作放这里（文件关闭等）
    end
end
@assert safe_div(6, 2) == 3 && safe_div(1, 0) == typemax(Int)

# ═══ 13.4 自定义异常：抽象类型 <: Exception + 具体类型
module Orders
    # 异常也是类型——放模块里导出，调用方按类型捕获
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
@assert throws_error(() -> Orders.place_order!(stock, "A1", 99)) === Orders.InsufficientStock
@assert occursin("库存不足", sprint(showerror, Orders.InsufficientStock("A1", 9, 1)))
@assert sprint(showerror, Orders.InvalidSku("XX")) == "非法 SKU：XX"

# ═══ 13.5 捕获时取细节：catch e 的字段、catch_stacktrace
function what_happened()
    try
        Orders.place_order!(Dict("A1" => 0), "A1", 2)
    catch e
        if e isa Orders.InsufficientStock
            (e.sku, e.want, e.have)
        else
            rethrow()
        end
    end
end
@assert what_happened() == ("A1", 2, 0)
# 栈跟踪：1.13 拿"抛错点"的栈用 current_exceptions()（返回 (异常, 回溯) 对）；
# catch 里裸 stacktrace()/backtrace() 只反映捕获点，拿不到抛错链（catch_stacktrace 已移除）
caught_frames = try
    Orders.place_order!(Dict("A1" => 0), "A1", 2)
    Base.StackFrame[]
catch
    stacktrace(Base.current_exceptions()[end][2])
end
caught_names = [string(f.func) for f in caught_frames]
@assert any(n -> occursin("place_order!", n), caught_names)   # 抛错函数在栈里

# ═══ 13.6 @assert 与错误策略
# @assert：开发期断言（可被优化关掉，别当业务校验）；业务校验用 throw error(...)
# 返回 nothing/missing 表示"没有值"（07 章）；异常只用于"异常路径"，别当流程控制
@assert 1 + 1 == 2
function find_first_negative(xs)
    for (i, x) in enumerate(xs)
        x < 0 && return i             # 正常结果：返回值
    end
    nothing                            # "没找到"：nothing 而不是异常
end
@assert find_first_negative([1, -2, 3]) == 2
@assert find_first_negative([1, 2]) === nothing

println("safe_div(1,0) = ", safe_div(1, 0), "；what_happened = ", what_happened())
println("==== 13 结束 ====")
