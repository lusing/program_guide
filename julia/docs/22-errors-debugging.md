# 22 · 错误与调试

> 对应示例：`examples/22_errdebug/`
>
> 出错时的完整工具链：**抛什么（异常族）→ 怎么接（try/catch）→ 在哪炸的（栈跟踪）→ 为什么慢/错（计时/剖析）**。

## 22.1 抛错的两种姿势

```julia
# error(msg)：抛 ErrorException——"不该发生"的断言式失败
must_positive(n) = (n > 0 || error("n 必须为正，得到 $(n)"); √n)
# throw(异常对象)：带类型语义的失败（调用方可按类型分支处理，22.4）
throw(ArgumentError("坏参数"))
```

## 22.2 内建异常族：每个坑有名字

| 异常 | 触发场景（实测） |
|---|---|
| `DomainError` | `sqrt(-1)`——数学域外 |
| `InexactError` | `Int(3.99)`——非精确转换（03 章） |
| `BoundsError` | `[1,2][5]`——越界 |
| `MethodError` | `"a" + 1`——无方法匹配 |
| `ArgumentError` | `parse(Int, "x")`、自抛参数错 |
| `KeyError` | `Dict()[:k]`——键不存在 |
| `DivideError` | `1 ÷ 0`——整数除零（**浮点除零是 Inf！**） |
| `TypeError` | 布尔上下文用了非 Bool（04/07 章） |
| `StringIndexError` | 多字节字符串切在字节中间（12 章） |
| `PosDefException` | Cholesky 遇到非正定（13 章） |
| `TaskFailedException` | fetch 一个失败的任务（20 章包装层） |

## 22.3 try/catch/finally：只消化目标类型

```julia
function safe_div(a, b)
    try
        a ÷ b
    catch e
        e isa DivideError ? typemax(Int) : rethrow()   # 其余继续抛
    finally
        nothing                                        # 清理必经之路（return 也会先经过）
    end
end
```

`catch` 可不绑变量；**全吞的 catch 让 bug 石沉大海**——限定类型 + rethrow 是底线。

## 22.4 自定义异常：模块化的类型层次

```julia
module Orders
    abstract type OrderError <: Exception end      # 异常也是类型树（06 章派发规则适用）
    struct InsufficientStock <: OrderError
        sku::String; want::Int; have::Int          # 业务数据随身带
    end
    Base.showerror(io::IO, e::InsufficientStock) = print(io, "库存不足：$(e.sku) 要 $(e.want) 有 $(e.have)")
    ...
    haskey(stock, sku) || throw(InvalidSku(sku))
end
# 捕获端按类型拿字段：
catch e
    e isa Orders.InsufficientStock ? (e.sku, e.want, e.have) : rethrow()
end
sprint(showerror, Orders.InsufficientStock("A1", 9, 1))   # "库存不足：A1 要 9 有 1"
```

`showerror` 定制打印（栈跟踪前那行）；异常设计 = 多重派发设计。

## 22.5 读 1.13 的错误与栈跟踪（实测 API 变更）

未捕获异常的输出是四段式：**错误类型 → 定位（file:line:col）→ 源码 + `└┘` 标注 → Suggestion/Hint**（02 章插值坑的原文示例）——整段读，别只看第一行。

catch 里拿**抛错点**的栈——老资料普遍写错：

```julia
inner() = error("炸在深处")
outer() = inner()
frames = try
    outer()
    Base.StackFrame[]
catch
    stacktrace(Base.current_exceptions()[end][2])   # ★ (异常, 回溯) 对 → 完整抛错链
end
# 实测：["error", "inner", "outer", "top-level scope", ...] 由内向外
```

| 写法 | 结果（1.13 实测） |
|---|---|
| `stacktrace(current_exceptions()[end][2])` | ✅ 完整抛错链 |
| `stacktrace(backtrace())`（catch 里） | ❌ 只有捕获点链 |
| `catch_stacktrace()`（老 API） | ❌ 1.13 已移除 |

帧信息：`f.func`、`f.file:f.line`。

## 22.6 三件即时工具

```julia
sprint(showerror, e)         # 异常 → 字符串（进日志/断言消息）
@show a + b                  # 打印 "a + b = 7"（输出到 stdout，不能 sprint 捕获——实测）
Base.@locals                 # 函数内一次看全局部变量（Dict{Symbol,Any}，1.9+）
```

## 22.7 计时与配额：诊断三件套

```julia
t = @elapsed f(v1)           # 秒（16 章：预热后测）
bytes = @allocated f(v1)     # 分配字节——参数在测量外构造（否则构造的分配被算进去，实测）
```

命令行旗标：`--track-allocation=user`（逐行分配，.mem 文件）、`--code-coverage=user`（行覆盖，18 章）、`--heap-size-hint=2G`（内存上限提示 GC）、`--check-bounds=yes`（强制边界检查，本教程验证层在用）、`--depwarn=error`（弃用转错误拿栈定位）。

## 22.8 Profiler：内置采样剖析

```julia
using Profile
busy(10)                     # 预热编译
Profile.clear()
@profile busy(500_000)
Profile.fetch()              # 采样回栈（非空即工作）
Profile.clear()              # 防旧数据混入
```

REPL 里 `Profile.print()` 看树状聚合；火焰图用 ProfileView.jl、PProf.jl。采样默认 1ms——小函数包大循环再剖。

## 22.9 工具生态（均第三方：Pkg.add 后用）

| 工具 | 用途 | 类比 |
|---|---|---|
| BenchmarkTools | `@btime` 精确基准（防 GC/编译干扰） | google/benchmark |
| JET.jl | 静态类型/错误检查 | clang-tidy |
| Debugger.jl | 逐行调试（断点/单步/栈） | gdb |
| Infiltrator.jl | `@infiltrate` 轻量断点 | print 大法升级 |
| Cthulhu.jl | `@descend` 看类型推断 | — |
| Aqua.jl | 包质量检查 | lint 全家桶 |
| Documenter.jl | 文档生成 + doctest | doxygen |
| Revise.jl | 改源码不重启会话 | 热重载 |

日常组合：**Revise（改代码）+ Infiltrator（看现场）+ BenchmarkTools（量性能）+ JET（防低级错）**。

## 22.10 错误策略分层

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

排错流程卡：读错误**全文** → 栈里找"自己文件"最内帧 → REPL 最小复现 → `@show`/`@locals`/Infiltrator 看现场 → 性能问题走 22.7/22.8 → 类型问题 JET/`@code_warntype`（16 章）。

## 22.11 坑位清单

1. **`catch_stacktrace` 已删；`stacktrace(backtrace())` 只给捕获点**——抛错点栈用 `stacktrace(current_exceptions()[end][2])`（22.5 实测表）。
2. **整数除零 ≠ 浮点除零**：`1 ÷ 0` 抛 DivideError，`1 / 0` 得 Inf（22.2）。
3. **`->` 是函数 `=>` 是 Pair**：`() => f()` 传的是 Pair——运行时才炸（22.1 工具函数实测踩过）。
4. **`@show` 打到 stdout**：无法 sprint 捕获——要捕获用 redirect_stdout 或改 println（22.6 实测）。
5. **`@assert` 不保证常开**：优化下可被剥离——生产校验用 throw（22.10）。
6. **`@allocated f(rand(...))` 把参数构造也算进去**：参数在测量外造好（22.7 实测）。
