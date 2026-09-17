# 13 · 异常

> 对应示例：`examples/13_errors/`

## 13.1 抛错的两种姿势

```julia
# error(msg)：抛 ErrorException——"不该发生"的断言式失败
must_positive(n) = (n > 0 || error("n 必须为正，得到 $(n)"); √n)

# throw(异常对象)：带类型语义的失败（调用方可按类型分支处理）
throw(ArgumentError("坏参数"))
```

`error` 是 `throw(ErrorException(...))` 的语法糖；要"可捕获分类"就定义异常类型（13.4）。

## 13.2 内建异常族：每个坑有名字

| 异常 | 触发场景（实测） |
|---|---|
| `DomainError` | `sqrt(-1)`、`√-1`——数学域外 |
| `InexactError` | `Int(3.99)`——非精确转换（03 章） |
| `BoundsError` | `[1,2][5]`——越界 |
| `MethodError` | `"a" + 1`——无方法匹配 |
| `ArgumentError` | `parse(Int, "x")`、自抛参数错 |
| `KeyError` | `Dict()[:k]`——键不存在 |
| `DivideError` | `1 ÷ 0`——整数除零（**浮点除零是 Inf！**） |
| `TypeError` | 布尔上下文用了非 Bool（04/07 章） |
| `StringIndexError` | 多字节字符串切在字节中间（12 章） |
| `TaskFailedException` | fetch 一个失败的任务（20 章包装层） |

## 13.3 try/catch/finally

```julia
function safe_div(a, b)
    try
        a ÷ b
    catch e
        e isa DivideError ? typemax(Int) : rethrow()   # 只消化目标类型，其余继续抛
    finally
        nothing                                        # 清理必经之路（关文件等）
    end
end
safe_div(1, 0)      # typemax(Int)
```

要点：`catch` 可不绑变量；`rethrow()` 在 catch 里重新抛出当前异常；`finally` 无论成败都执行（return 也会先经过它）。**异常当流程控制是性能与可读性双输**——正常路径用返回值/`nothing`。

## 13.4 自定义异常：模块化的类型层次

```julia
module Orders
    abstract type OrderError <: Exception end      # 异常也是类型树

    struct InsufficientStock <: OrderError
        sku::String; want::Int; have::Int
    end
    # 定制错误打印（栈跟踪前的那一行）
    Base.showerror(io::IO, e::InsufficientStock) =
        print(io, "库存不足：$(e.sku) 要 $(e.want) 有 $(e.have)")

    struct InvalidSku <: OrderError
        sku::String
    end
    Base.showerror(io::IO, e::InvalidSku) = print(io, "非法 SKU：$(e.sku)")

    function place_order!(stock, sku, qty)
        haskey(stock, sku) || throw(InvalidSku(sku))
        stock[sku] >= qty || throw(InsufficientStock(sku, qty, stock[sku]))
        stock[sku] -= qty
    end
end
```

捕获端按类型分派拿细节——异常设计也是多重派发（06 章）：

```julia
try
    Orders.place_order!(stock, "A1", 99)
catch e
    if e isa Orders.InsufficientStock
        (e.sku, e.want, e.have)        # 字段里带业务数据
    else
        rethrow()
    end
end
sprint(showerror, Orders.InsufficientStock("A1", 9, 1))   # "库存不足：A1 要 9 有 1"
```

## 13.5 栈跟踪：1.13 的正确姿势（实测 API 变更）

老教程的 `catch_stacktrace()` 在 1.13 **已不存在**；catch 里裸 `stacktrace()` / `stacktrace(backtrace())` 只反映**捕获点**，拿不到抛错链。正确做法：

```julia
frames = try
    risky()
    Base.StackFrame[]
catch
    stacktrace(Base.current_exceptions()[end][2])   # (异常, 回溯) 对 → 可读帧
end
names = [string(f.func) for f in frames]   # 按调用点由内向外
```

`current_exceptions()` 返回"当前正在处理的异常栈"，`[end][2]` 是最内层的回溯——它才有 `error → inner → outer → top-level` 这样的完整链条（23 章调试细讲）。

## 13.6 错误策略分层

| 场景 | 工具 |
|---|---|
| 开发期断言（可关） | `@assert cond "消息"` |
| 业务校验（不可关） | `throw(ArgumentError(...))` |
| "没找到/没值" | 返回 `nothing`（07 章），不是异常 |
| 数据缺失 | `missing` 三值逻辑（07 章） |
| 可恢复失败 | 自定义异常 + 类型化 catch |

```julia
find_first_negative(xs) = (for (i, x) in enumerate(xs); x < 0 && return i; end; nothing)
```

## 13.7 坑位清单

1. **`catch_stacktrace` 已移除**（1.13）：拿抛错点栈用 `stacktrace(current_exceptions()[end][2])`；裸 `stacktrace(backtrace())` 给的是捕获点链（13.5 实测）。
2. **整数除零 ≠ 浮点除零**：`1 ÷ 0` 抛 DivideError，`1 / 0` 得 Inf——混用两套除法时想清楚（13.2）。
3. **`->` 是函数 `=>` 是 Pair**：`throws_error(() => f())` 传进去的是 Pair 不是可调用物——运行时才炸（13.1 工具函数实测踩过）。
4. **`@assert` 不保证常开**：优化选项下可被剥离——生产校验用 throw，@assert 只留给自己看（13.6）。
5. **catch 里吞错不 rethrow 是大忌**：至少 `@warn` 或限定捕获类型——全吞的 catch 让 bug 石沉大海（13.3）。
