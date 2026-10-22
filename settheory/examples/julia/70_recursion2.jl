# 第 70 章：第二递归定义定理与彻底有限集合（冯琦 §1.5-1.6）
# V_ω 的 Set 化身：Vₙ 塔、TC 迭代（定理 1.42）、阿克曼编码
# f(N) = f(N−2^i) ∪ {f(i)}（定理 1.48）与逆（推论 1.9）。
println("==== 70")

const EMPTY = Set{Any}()

# ---------- 一、Vₙ 塔（定义 1.53）与规模爆炸 ----------
function powerset_f(s)
    elems = collect(s)
    n = length(elems)
    [Set(elems[i] for i in 1:n if (m >> (i - 1)) & 1 == 1)
     for m in 0:(2^n - 1)]
end
V = [EMPTY]
sizes = [1]
for _ in 1:4
    global V = powerset_f(V)          # Vₖ₊₁ = 𝒫(Vₖ)
    push!(sizes, length(V))
end
println("Vₙ 塔规模 |V₀..V₄| = ", sizes,
        "   |V₅| = 2^65536（共 ", ndigits(big(2)^big(65536)), " 位十进制）")

# ---------- 二、传递闭包 TC（定理 1.42：Xₙ₊₁ = Xₙ ∪ ⋃Xₙ 迭代） ----------
function tc(x)
    Y = Set{Any}()                  # 从 x 的元素起步（不含 x 本身）
    Xn = Set{Any}(x)
    while !isempty(Xn)
        union!(Y, Xn)
        Xn = setdiff(Set{Any}(e for a in Xn for e in a), Y)
    end
    Y
end
vn(n) = foldl((acc, _) -> union(acc, Set([acc])), 1:n; init = EMPTY)
@assert vn(4) == Set([EMPTY, vn(1), vn(2), vn(3)])
@assert Set(tc(vn(5))) == Set(vn(5))                   # TC(n) = n：自然数传递
@assert Set(tc(Set([vn(1)]))) == Set([EMPTY, vn(1)])
println("TC(5) = 5 ✓   TC({1}) = {0,1} ✓（迭代到不动点）")

# ---------- 三、阿克曼编码（定理 1.48）----------
# 书定义 f(0)=∅；f(n+1) = f(r(n)) ∪ {f(lg2(n))}，以 N = n+1 改写成
# f(N) = f(N − 2^i) ∪ {f(i)}，i = ⌊log2 N⌋。
lg2(n) = n <= 0 ? 0 : floor(Int, log2(n))
const ACK = Dict{Int,Any}(0 => EMPTY)
function ack(N)
    N == 0 && return EMPTY
    get!(ACK, N) do
        i = lg2(N)
        r = N - 2^i
        union(ack(r), Set([ack(i)]))
    end
end
for n in 1:255; ack(n); end
@assert length(Set(ack(n) for n in 0:255)) == 256      # 单射的有限见证
println("f(0..8) 元素个数 = ", [length(ack(n)) for n in 0:8], "  f(3) = {f(1),f(0)} ✓")

# 逆（推论 1.9）：inv(a) = Σ 2^{inv(e)}
const INV = Dict{Any,Int}(EMPTY => 0)
function inv(a)
    get!(INV, a) do
        s = 0
        for e in a
            s += 2^inv(e)
        end
        s
    end
end
@assert all(inv(ack(n)) == n for n in 0:255)
println("阿克曼编码 0..255 往返恒等（f 与 Σ2^inv 互逆）✓")

# ---------- 四、V_ω 封闭律（定理 1.46(5)/推论 1.8）----------
depth(a) = isempty(a) ? 0 : 1 + maximum(depth(e) for e in a)
A = [ack(n) for n in 0:63]
@assert all(depth(union(A[i], Set([A[j]]))) < 100
            for i in 1:16 for j in 1:16)
println("V_ω 对 a ∪ {b} 封闭（推论 1.8）✓")

println("END ====")
