# 23 · 调试与工具

> 对应示例：`examples/23_debug/`

## 23.1 读懂 1.13 的错误输出

新前端（flfrontend）的错误长这样（02 章插值坑的真实输出）：

```text
ERROR: LoadError: ParseError:
# Error @ examples/02_hello/main.jl:15:19
x = 42
println("插值：x = $x，表达式 ...")
#                    └┘ ── interpolated variable ends with invalid character; use `$(...)` instead
```

四段式：**错误类型 → 定位（file:line:col）→ 源码行 + `└┘` 标注 → 修复建议**。运行期错误还有 `Suggestion:`/`Hint:` 段（UndefVarError 会提示"检查局部遮蔽"并指向存在的同名全局）。**整段读，不要只看第一行**。

## 23.2 栈跟踪：current_exceptions 的正确姿势（1.13 实测变更）

```julia
inner() = error("炸在深处")
outer() = inner()
frames = try
    outer()
    Base.StackFrame[]
catch
    stacktrace(Base.current_exceptions()[end][2])   # ★ (异常, 回溯) 对
end
names = [string(f.func) for f in frames]
# 实测：["error", "inner", "outer", "top-level scope", "eval", ...] ——由内向外
```

| 写法 | 结果（1.13 实测） |
|---|---|
| `stacktrace(current_exceptions()[end][2])` | ✅ 完整抛错链（error → inner → outer） |
| `stacktrace(backtrace())`（catch 里） | ❌ 只有捕获点链（top-level → include → _start） |
| `catch_stacktrace()`（老 API） | ❌ 1.13 已移除 |

帧信息：`f.func`（函数名）、`f.file:f.line`（定位）。未捕获异常 Julia 自己会打印整套——catch 后想拿到它就用上表第一种。

## 23.3 showerror / @show / @locals：三件即时工具

```julia
sprint(showerror, e)         # 异常格式化成字符串（进日志/断言消息）
Base.showerror(io::IO, e::MyErr) = print(io, "...")   # 给自己的异常定制（13 章）

@show a + b                  # 打印 "a + b = 7"——比手写 println 名值对省事

function where_am_i(x)
    y = x * 2
    Base.@locals             # Dict{Symbol,Any}：一次看全局部变量（1.9+）
end
```

## 23.4 计时/配额：诊断三件套

```julia
t = @elapsed f(x)            # 秒（浮点）
bytes = @allocated f(x)      # 分配字节数
@time f(x)                   # 人读版：时间 + 分配数 + 字节
```

纪律（16 章详述，调试视角重申）：**预热后测、参数在测量外构造**——`@allocated f(rand(100))` 会把 rand 的分配算进结果（实测）。

命令行旗标（配 build.ps1 或手动）：

| 旗标 | 用途 |
|---|---|
| `--track-allocation=user` | 逐行统计分配（生成 .mem 文件，`jl +行号=字节`） |
| `--code-coverage=user` | 行覆盖（.cov 文件；测试质量、找死代码） |
| `--heap-size-hint=2G` | 内存超限强制 GC（长跑防膨胀） |
| `--check-bounds=yes` | 强制边界检查（本教程验证层在用） |
| `--depwarn=error` | 弃用警告转错误（拿栈定位老用法） |

## 23.5 Profiler：内置采样剖析

```julia
using Profile
busy(10)                       # 预热
Profile.clear()
@profile busy(500_000)
data = Profile.fetch()         # 采样回栈（非空即工作）
length(data) > 0               # true
```

REPL 里 `Profile.print()` 看树状聚合；配 ProfileView.jl（火焰图）、PProf.jl（perf 视角）、StatProfilerHTML.jl。采样默认 1ms 间隔——函数太小测不准，包一层循环再 profile。

## 23.6 生态工具表（均第三方：`Pkg.add` 后用）

| 工具 | 用途 | 类比 |
|---|---|---|
| BenchmarkTools | `@btime`：多次采样防 GC/编译干扰的精确基准 | google/benchmark |
| JET.jl | 静态分析：类型错误、未定义名——提交前跑 | clang-tidy |
| Debugger.jl | 逐行调试（断点/单步/栈） | gdb |
| Infiltrator.jl | `@infiltrate` 轻量断点（REPL 里探现场） | print 大法升级版 |
| Cthulhu.jl | `@descend`：逐层看类型推断卡在哪 | — |
| Aqua.jl | 包质量检查（歧义、stale deps……测试里跑） | lint 全家桶 |
| Documenter.jl | 文档生成 + doctest | doxygen |
| Revise.jl | 改源码不重启会话（开发标配） | 热重载 |

日常组合：**Revise（改代码）+ Infiltrator（看现场）+ BenchmarkTools（量性能）+ JET（防低级错）**。

## 23.7 排错流程卡

1. 读错误**全文**（类型/定位/标注/Suggestion）；
2. 栈跟踪找"自己的文件"里最内一帧；
3. 最小复现（REPL 一行）；
4. 还不通：`@show`/`@locals` 打现场，或 Infiltrator 断点；
5. 性能问题：预热 + @allocated → `--track-allocation` 定位行 → Profile 看热点 → JET 查类型不稳。

## 23.8 坑位清单

1. **catch 里裸 `stacktrace(backtrace())` 拿不到抛错链**（1.13 变更）：用 `stacktrace(current_exceptions()[end][2])`——老资料普遍写错（23.2 实测表）。
2. **`@allocated f(rand(...))` 把参数构造也算进去**：参数在测量外造好（23.4 实测）。
3. **Profiler 采样测不准小函数**：先包大循环；并记得 `Profile.clear()` 防旧数据混入（23.5）。
4. **`@show` 打到 stdout**：无法用 sprint 直接捕获（它不走 io 参数）——要捕获用 redirect_stdout 或改 println（23.3 实测）。
5. **`@locals` 只在函数体内有意义**：顶层拿到的是全局（Main）绑定集。
