# 14 元编程 ⭐：Expr、quote/:()、宏定义与卫生 esc、macroexpand、eval、世界年龄、@generated
# 运行：julia --startup-file=no main.jl

# ═══ 14.1 程序即数据：Expr 是普通值，能构造、检查、改写
ex = :(1 + 2 * 3)                 # :() 捕获单个表达式
@assert ex isa Expr && ex.head == :call && ex.args[1] == :+
@assert ex.args[2] == 1 && ex.args[3] == :(2 * 3)
println("ex = ", ex, "  args = ", ex.args)
# quote ... end 捕获多行代码块
q = quote
    a = 1
    a + 1
end
@assert q isa Expr && q.head == :block && length(q.args) == 4   # 两句 + 两个行号节点
# 符号与插值：:name 是 Symbol；$ 在 quote 里求值注入
sym = :hello
@assert sym isa Symbol && string(sym) == "hello"
xval = 40
built = :($xval + 2)              # 构造 Expr::(42 + 2)
@assert built.args[2] == 40

# ═══ 14.2 eval：把 Expr 变成执行（少用，但理解编译管线必备）
@assert eval(:(1 + 2)) == 3
@assert eval(:($xval * 2)) == 80
# 代码在"当前模块"的全局作用域求值——函数体内慎用（性能章：全局作用域 = 慢）

# ═══ 14.3 宏：接收 Expr、返回 Expr，编译前展开
macro twice(ex)
    :($ex + $ex)                 # $ex 把传入的表达式拼进结果
end
@assert @twice(21) == 42
@assert @twice(2 + 3) == 10      # 表达式先拼后算：(2+3)+(2+3)——不是 2+3+2+3 的求值序问题
macro unless(cond, body)         # 经典：unless = if not
    quote
        if !($(esc(cond)))       # cond/body 属于调用者——必须 esc，否则赋值被"卫生改名"丢掉
            $(esc(body))
        end
    end
end
ran = false
@unless 1 == 2 begin
    ran = true                   # 条件为假才执行
end
@assert ran

# ═══ 14.4 卫生（hygiene）：宏里的变量默认"隔离"，想外传用 esc
macro my_set(dest, value)        # 不 esc 的版本：dest 被当宏自己的局部——演示"错"
    :(local t = $value; t)       # t 是宏内部的（卫生），外界看不见
end
@assert @my_set(x, 5) == 5
macro setvar(dest, value)        # esc 版：dest 与 value 都解析回"调用处"的作用域
    quote
        $(esc(dest)) = $(esc(value))
        $(esc(dest))
    end
end
@assert (@setvar y 7) == 7       # 注意：宏的多参用空格分隔（@setvar y, 7 会把 (y,7) 当一个元组）
@assert y == 7
macro swap_vars(a, b)
    quote
        local tmp = $(esc(a))
        $(esc(a)) = $(esc(b))
        $(esc(b)) = tmp
    end
end
p, qv = 1, 2
@swap_vars p qv
@assert (p, qv) == (2, 1)

# ═══ 14.5 变参宏与展开检查
macro showex(exs...)
    quote
        println("宏收到 $(length($exs)) 个参数")
        $(foldl((acc, e) -> :($acc; $e), exs; init = :nothing))
    end
end
@assert (@showex 1 2 3) == 3
# macroexpand：看宏展开成什么（调试宏的第一工具；结果含卫生标记，用 eval 验证语义）
expanded = macroexpand(Main, :(@twice 5))
@assert eval(expanded) == 10 && occursin("+", string(expanded))

# ═══ 14.6 世界年龄（world age）：方法定义后，"正在运行的旧代码"看不见它
# 这一节整段都是「运行中定义新方法、再访问那个新 binding」，Julia 1.12+ 会因此
# 往 stderr 打一条 world-age 警告：
#   WARNING: Detected access to binding `Main.new_fn` in a world prior to its definition world.
# 警告本身就是这里要演示的现象，不是代码缺陷 —— 所以用 redirect_stderr(devnull)
# 把这两次调用圈起来，好让「stderr 为空（零告警）」这条判定对其它示例仍然严格。
# 真实项目里要改的是代码（用 invokelatest，或别在运行中定义方法），不是靠重定向遮掩。
function try_call_new()
    @eval new_fn() = 99          # 运行中定义新方法
    new_fn()                     # 直接调用——错误！当前函数编于"旧世界"，看不见 new_fn
end
function call_via_invokelatest()
    @eval new_fn2() = 99
    Base.invokelatest(new_fn2)   # invokelatest 跳到最新世界
end
world_ok = redirect_stderr(devnull) do
    call_via_invokelatest()
end
@assert world_ok == 99
world_error = redirect_stderr(devnull) do
    try
        try_call_new()
        false
    catch e
        e isa MethodError
    end
end
@assert world_error               # 旧世界调用新方法 → MethodError（世界年龄坑）

# ═══ 14.7 @generated：按类型在"编译期"生成方法体（进阶，够用即可）
@generated function myzero(::Type{T}) where {T}
    if T <: Number
        :(zero(T))               # 数值类型：零值
    else
        :("无零值")              # 其他类型：字符串
    end
end
@assert myzero(Int) == 0 && myzero(String) == "无零值"

println("@twice(21) = ", @twice(21), "；expanded = ", expanded)
println("==== 14 结束 ====")
