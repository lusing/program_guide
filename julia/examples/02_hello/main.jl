# 02 第一个程序：println/print/show、插值、ARGS 与 @main 入口
# 运行：julia --startup-file=no main.jl Julia 1.13
# 测试：julia --startup-file=no runtests.jl

# ═══ 02.1 println / print / show：三种输出的差别
println("Hello, Julia ", VERSION)          # println：追加换行
print("print 不换行")
print("，可以接着写\n")                    # print：原样输出
show(stdout, "show 给出可解析的形式")       # show：带引号（代码表示）
println()
println("字符串拼接用 * ：", "a" * "b", "；重复用 ^ ：", "ab" ^ 3)

# ═══ 02.2 字符串插值：$ 与 $()
x = 42
println("插值：x = $(x)，表达式 $((x + 8))，圆周率 π = $(π)")

# ═══ 02.3 定义并调用一个函数（完整讲法见 05 章）
greet(name::AbstractString) = "你好，$(name)！"
println(greet("Julia"))

# ═══ 02.4 ARGS 与 @main 入口（Julia 1.11+）
# 正确形式：function @main(args)。脚本主体先执行，随后 julia 自动调用 main(ARGS)。
# 注意：`Base.@main function main(args)` 是错误写法——宏会展开成"注册 + 立即调用"。
function @main(args)
    if isempty(args)
        println("（无参数运行：@main 也接受空参数，走默认演示路径）")
    else
        println("入口收到 ARGS = $args（共 $(length(args)) 个）")
    end
    # ═══ 自检（@assert 失败立即中断）
    @assert greet("x") == "你好，x！"   # $name 后紧跟全角标点会解析错误，须写 $(name)
    @assert "a" * "b" == "ab"
    @assert x == 42
    println("==== 02 结束 ====")
end
