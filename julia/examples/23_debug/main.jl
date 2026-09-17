# 23 调试与工具：读 1.13 错误栈、@time/@allocated、Profiler、@show/@locals、生态表
# 运行：julia --startup-file=no main.jl

# ═══ 23.1 读懂 1.13 的错误：类型 + 消息 + Suggestion/Hint + 栈帧
# 拿"抛错点"的栈：current_exceptions() 返回 (异常, 回溯) 对——1.13 中 catch 里的
# 裸 stacktrace()/backtrace() 只反映"捕获点"，拿不到抛错链（老版本的 catch_stacktrace 已移除）
inner() = error("炸在深处")
outer() = inner()
frames = try
    outer()
    Base.StackFrame[]
catch
    stacktrace(Base.current_exceptions()[end][2])
end
@assert length(frames) >= 2
names = [string(f.func) for f in frames]
@assert "inner" in names && "outer" in names      # 栈帧按"调用点由内向外"排列
println("栈帧（内→外）：", join(names[1:min(4, end)], " → "))
# 1.13 的错误输出带 Suggestion/Hint 段（如 UndefVarError 的"检查拼写/局部遮蔽"），
# 还有新前端 flfrontend 的行内标注（Error @ file:line:col + └┘ 指示）——都值得整段读

# ═══ 23.2 showerror / sprint：把异常变成字符串（进日志、写测试）
e = try
    sqrt(-1.0)
catch err
    err
end
@assert e isa DomainError
@assert occursin("sqrt", sprint(showerror, e))    # DomainError 消息自带函数名

# ═══ 23.3 @show：一行打印"表达式 = 值"（比 println 手写名值对省事；输出到 stdout）
a, b = 3, 4
@show a + b                                      # 控制台可见：a + b = 7

# ═══ 23.4 Base.@locals：函数内一次性看全部局部变量（1.9+）
function where_am_i(x)
    y = x * 2
    locals = Base.@locals                        # Dict{Symbol, Any}
    (:y in keys(locals), y)
end
@assert where_am_i(5) == (true, 10)

# ═══ 23.5 计时与配额：三件套回顾（16 章细讲过性能，这里讲"诊断姿势"）
function probe_me(v)
    s = 0.0
    for x in v
        s += x
    end
    s
end
v1 = rand(1000)
probe_me(v1)                                     # 预热
t = @elapsed probe_me(v1)
bytes = @allocated probe_me(v1)                  # 参数在测量外构造——否则 rand 的分配会被算进去
@assert t > 0 && bytes == 0                      # 正确预热 + 参数外置后零分配
# 命令行诊断旗标（本脚本用不上，写代码卡性能时用）：
#   --track-allocation=user   按行统计分配字节数（写 .mem 文件）
#   --code-coverage=user      行覆盖统计（测试质量）
#   --heap-size-hint=2G       内存超限强制 GC（长跑任务防膨胀）

# ═══ 23.6 Profiler：内置采样剖析器（看火焰图数据的"原始形态"）
using Profile
function busy(n)
    s = 0.0
    for i in 1:n
        s += sin(i) * cos(i)
    end
    s
end
busy(10)                                         # 预热编译
Profile.clear()
@profile busy(500_000)
data = Profile.fetch()                           # 采样回栈（Vector{UInt}，帧地址指针）
@assert length(data) > 0
# REPL 里用 Profile.print() / ProfileView.jl（火焰图）/ PProf.jl（perf 视角）
Profile.clear()

# ═══ 23.7 工具生态速查（按需引入，均第三方：Pkg.add 后用）
# | 工具             | 用途                        | 类比          |
# |------------------|-----------------------------|---------------|
# | BenchmarkTools   | @btime 精确基准（防 GC 干扰）| google/benchmark |
# | JET.jl           | 静态类型/错误检查（IDE 内） | clang-tidy    |
# | Debugger.jl      | 逐行调试器（断点/单步）     | gdb           |
# | Infiltrator.jl   | 轻量"断点"宏 @infiltrate    | print 大法升级 |
# | Cthulhu.jl       | 逐层看类型推断 @descend     | —             |
# | Aqua.jl          | 包质量检查（测试里跑）      | lint全家桶    |
# | Documenter.jl    | 文档生成（doctest）         | doxygen       |
# | Revise.jl        | 改代码不重启会话            | 热重载        |

println("栈帧数 = ", length(frames), "；probe_me 零分配验证通过")
println("==== 23 结束 ====")
