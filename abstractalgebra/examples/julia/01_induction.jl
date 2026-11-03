# 第 01 章 · 数学归纳法与良序 —— 计算通道
#
# 最小反例搜索器（良序原则的可执行版）+ 归纳断言的数值复核。
# 全程精确整数算术（isqrt 判平方数，无浮点容差）。

println("==== 01 数学归纳法与良序")

# ---------- 工具 ----------
"""命题 1.3 直译：试除到 √n 判素。"""
function isprime(n::Integer)
    n < 2 && return false
    p = big(2)
    while p * p <= n
        n % p == 0 && return false
        p += (p == 2 ? 1 : 2)
    end
    return true
end

"""最小反例搜索：从 1 起找第一个满足 bad 的 n（良序原则的可执行版）。"""
function first_counterexample(bad, N)
    for n in 1:N
        bad(n) && return n
    end
    return nothing
end

# ---------- 1.1 归纳推理不算证明 ----------
euler_hit = first_counterexample(n -> !isprime(n^2 - n + 41), 100)
@assert euler_hit == 41 "欧拉多项式第一个合数值出现在 n = 41，得 $euler_hit"
println("欧拉多项式 n²−n+41：n = 1..40 全素，第一个反例 n = ", euler_hit,
        "（f(41) = ", 41^2 - 41 + 41, " = 41²）")

sierpinski_hit = first_counterexample(n -> isqrt(991 * n^2 + 1)^2 == 991 * n^2 + 1, 10^6)
@assert isnothing(sierpinski_hit) "前 10⁶ 个 n 内应无反例"
println("谢尔宾斯基 991n²+1：前 10⁶ 个 n 内无反例（真反例 ~1.2×10²⁸）")

# 平面分割空间：公式 (n³+5n+6)/6 与 2ⁿ 在 n ≤ 3 撞车，n = 4 分道扬镳
regions(n) = div(n^3 + 5n + 6, 6)
for n in 0:4
    r, p = regions(n), 2^n
    tag = r == p ? "（与 2ⁿ 撞车）" : "（≠ 2ⁿ = $p）"
    println("  n = $n 平面：最多 $(r) 区域$tag")
end
@assert regions(0) == 1 && regions(1) == 2 && regions(2) == 4 &&
        regions(3) == 8 && regions(4) == 15

# ---------- 1.3 命题 1.8：2ⁿ > n² 恰从 n = 5 开始 ----------
for n in 1:10
    holds = 2^n > n^2
    if n == 2 || n == 4
        @assert !holds "n = $n 应是等号（2ⁿ = n²）"
    elseif n == 3
        @assert !holds "n = 3 应反向（8 < 9）"
    elseif n >= 5
        @assert holds "n = $n 应有 2ⁿ > n²"
    end
end
println("2ⁿ > n²：n = 2, 4 相等；n = 3 反向；n ≥ 5 成立 ✓")

# ---------- 1.3 高斯求和：递归 vs 公式 ----------
sum_to(n) = n == 0 ? 0 : sum_to(n - 1) + n   # 与 Lean 的 sumTo 同构
for n in 0:200
    @assert 2 * sum_to(n) == n * (n + 1)
end
println("高斯求和：递归定义与公式 n(n+1)/2 在 n ≤ 200 逐点一致 ✓")

# ---------- 1.6 斐波那契：卡西尼恒等式（命题 1.15 的邻伴） ----------
"""迭代版斐波那契（BigInt 无溢出）。"""
function fibit(n::Integer)
    a, b = big(0), big(1)
    for _ in 1:n
        a, b = b, a + b
    end
    a
end
# 与二项递归定义的一致性抽查（n ≤ 25：朴素递归在此范围可接受）
fib(n) = n == 0 ? big(0) : n == 1 ? big(1) : fib(n - 1) + fib(n - 2)
for n in 0:25
    @assert fib(n) == fibit(n)
end
for n in 1:500
    lhs = BigInt(fibit(n - 1)) * fibit(n + 1) - fibit(n)^2
    @assert lhs == (n % 2 == 0 ? 1 : -1) "卡西尼在 n = $n 失效"
end
println("卡西尼恒等式 F_{n−1}F_{n+1} − F_n² = (−1)ⁿ：n ≤ 500 全部成立 ✓")

println("END ====")
