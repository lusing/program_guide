# 第 59 章：归纳与递归的机器化（Makinson Ch4）
# 朴素 vs 记忆化 Fibonacci 的调用计数 + Ackermann 表 + 求值方向实验
println("==== 59")

# ---------- 一、朴素递归 + 加法计数器 ----------
const CALLS = Ref(0)
fib_naive(n) = begin
    n <= 1 && return n
    CALLS[] += 1
    fib_naive(n-1) + fib_naive(n-2)
end

# ---------- 二、记忆化（自底向上） ----------
fib_memo(n) = begin
    a, b = 0, 1
    for _ in 1:n
        a, b = b, a + b
    end
    a
end

println("  Fibonacci 求值剧场：")
for n in (10, 20, 25, 30)
    CALLS[] = 0
    v1 = fib_naive(n)
    c = CALLS[]
    v2 = fib_memo(n)
    @assert v1 == v2
    println("    F($(n)) = $(v1)：朴素递归做 $(c) 次加法 vs 记忆化 $(n-1) 次")
end
# T(n) = F(n+1) - 1 的验证
for n in (10, 20, 25)
    CALLS[] = 0; fib_naive(n)
    @assert CALLS[] == fib_memo(n+1) - 1
end
println("    加法次数 T(n) = F(n+1) − 1 的恒等式验证 ✓")

# ---------- 三、6! 的两个求值方向（书本 4.4） ----------
println("  6! 自底向上：")
acc = 1
for k in 1:6
    global acc *= k
    println("    $(k)! = $(acc)")
end
println("  6! 自顶向下（展开）：")
expr = "6!"
for k in 6:-1:2
    global expr = replace(expr, string(k, "!") => string("(", k-1, "!×", k, ")"))
    println("    ", expr)
end
println("    展开到底后逐步算回 = 720 ✓")

# ---------- 四、Ackermann 函数小值表 ----------
ack(m, n) = m == 0 ? n + 1 : (n == 0 ? ack(m-1, 1) : ack(m-1, ack(m, n-1)))
println("  Ackermann 小值表：")
println("    A(0,n) = n+1：", [ack(0, n) for n in 0:5])
println("    A(1,n) = n+2：", [ack(1, n) for n in 0:5])
println("    A(2,n) = 2n+3：", [ack(2, n) for n in 0:5])
println("    A(3,n) = 2^(n+3)−3：", [ack(3, n) for n in 0:4])
println("    A(3,3) = $(ack(3,3))，A(3,4) = $(ack(3,4))（指数增长）")

# ---------- 五、闭包的自底向上生成（57 章 R[X] 的函数版） ----------
cl = Set([2])
for _ in 1:5
    global cl = union(cl, Set(2x for x in cl))
end
println("  {2} 在 n↦2n 下的闭包前几步：", sort(collect(cl)))
cl2 = Set([2, 5])
for _ in 1:3
    global cl2 = union(cl2, Set(2x for x in cl2))
end
println("  {2,5} 在 n↦2n 下的闭包（书本答案双链）：", sort(collect(cl2)))

println("END ====")
