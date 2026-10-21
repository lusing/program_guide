# 第 05 章 Julia：递归定理的执行面。
# ① 书 3.2.1 证明的机器化：近似序列——m-近似的并就是递归定义的函数；
# ② 递归式加法（书 3.2.6 原样）与内建 + 的对拍；
# ③ 双重递归的合法性：naive fib 不是递归定理的实例（步进函数需要
#    两个先前值），配对状态化后才是——两条曲线的调用次数就是证词。
println("==== 05 naturals")

# ② 递归式加法：m + 0 = m；m + (n+1) = (m+n) + 1
add_rec(m, n) = n == 0 ? m : add_rec(m, n - 1) + 1
for m in 0:15, n in 0:15
    @assert add_rec(m, n) == m + n
end
println("recursive add: add_rec(m,n) == m+n for m,n <= 15: OK")

# ① 近似序列（书 3.2.1 的证明构造）：对固定 m，n-近似是
# {(0,f(0)),...,(n-1,f(n-1))}；全体近似的并 = 加法函数的有限段。
function approximations(m, upto)
    aps = Vector{Vector{Int}}()
    t = Int[]                                  # 0-近似：空序列
    push!(aps, copy(t))
    for k in 0:upto-1
        push!(t, add_rec(m, k))                # t_{k+1} = g(t_k, k)
        push!(aps, copy(t))
    end
    aps
end
aps = approximations(7, 6)
union_ap = sort(unique(vcat(aps...)))          # ⋃F 的值域形态（函数并：无重复）
@assert union_ap == [add_rec(7, k) for k in 0:5]
@assert aps[4] == [7, 8, 9]                    # 3-近似 = 前三个值（aps[1] 是 0-近似）
@assert length.(aps) == 0:6                    # n-近似的长度是 n
println("approximation sequences: union of approximations = the function: OK")

# ③ 双重递归的合法性：naive fib vs 状态配对 fib
const calls = Ref(0)
function fib_naive(n)
    calls[] += 1
    n <= 1 ? n : fib_naive(n - 1) + fib_naive(n - 2)
end
# 状态化：F(n) = (fib n, fib n+1)——单步递归 g((a,b)) = (b, a+b)
fib_pair(n) = n == 0 ? (0, 1) : let (a, b) = fib_pair(n - 1); (b, a + b); end
for n in 0:20
    @assert fib_naive(n) == fib_pair(n)[1]
end
calls25 = (calls[] = 0; fib_naive(25); calls[])
@assert fib_pair(90)[1] == 2880067194370816120   # BigInt 级数值也精确
println("double recursion: naive fib 25 takes ", calls25,
        " calls; state-pair fib is single-recursive and linear: OK")

# ④ 带参数递归（书 3.2.3）的最小实例：乘法 = 以加法为步进的参数递归
mul_rec(m, n) = n == 0 ? 0 : add_rec(mul_rec(m, n - 1), m)
for m in 0:10, n in 0:10
    @assert mul_rec(m, n) == m * n
end
println("parametric recursion: mul_rec via add_rec step matches *: OK")
println("END ====")
