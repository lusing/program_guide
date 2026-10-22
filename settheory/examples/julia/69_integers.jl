# 第 69 章：有限与无限、整数与有理数（冯琦 §1.3.5 + §1.4）
# 典型序螺旋 + 三大配对函数（含逆）+ 欧几里得剧场 + 扩展贝祖 +
# 书版 ℚ（既约代表元）+ 往返渐进同构。
println("==== 69")

# ---------- 一、典型序（定义 1.33）与螺旋次序 ----------
gtyp(a, b) = a < b ? b * b + a : a * a + a + b   # 内点 < 上边界 < 右边界

function spiral(n)
    out = Tuple{Int,Int}[]
    k = 0
    while length(out) < n
        for a in 0:k-1; push!(out, (a, k)); end   # 上边界：从左到右
        for b in 0:k;   push!(out, (k, b)); end   # 右边界：自下而上
        k += 1
    end
    out[1:n]
end

sp = spiral(12)
println("典型序前 12 点: ", sp)
println("gtyp 逐一吻合: ", [gtyp(a, b) for (a, b) in sp] == collect(0:11))

# ---------- 二、三大配对函数与逆（命题 1.10） ----------
cantor(m, n) = (m + n) * (m + n + 1) ÷ 2 + m     # (1) 层和式 h
function cantor_inv(c)
    w = floor(Int, (isqrt(8 * c + 1) - 1) / 2)
    while (w + 1) * (w + 2) ÷ 2 <= c; w += 1; end
    while w * (w + 1) ÷ 2 > c; w -= 1; end
    t = w * (w + 1) ÷ 2
    (c - t, w - (c - t))
end
jpair(m, n) = 2^m * (2n + 1) - 1                 # (2) 奇偶析因式 J
function jpair_inv(j)
    v, c = 0, j + 1
    while c % 2 == 0; c ÷= 2; v += 1; end         # 2-adic 赋值（唯一分解的算法化身）
    (v, (c - 1) ÷ 2)
end
ok_c = all(cantor_inv(cantor(m, n)) == (m, n) for m in 0:25 for n in 0:25)
ok_j = all(jpair_inv(jpair(m, n)) == (m, n) for m in 0:14 for n in 0:14)
println("cantor / jpair 配对往返恒等（网格全检）: ", ok_c, "  ", ok_j)

# ---------- 三、欧几里得剧场 + 扩展贝祖 ----------
isprime(n) = n >= 2 && all(d -> n % d != 0, 2:isqrt(n))
function euclid(k)
    ps = [2]
    for _ in 1:k
        c = prod(ps) + 1                        # 前素数之积 + 1
        p = 2
        while !(c % p == 0 && isprime(p)); p += 1; end
        push!(ps, p)                            # c 的最小素因子 = 新素数
    end
    ps
end
println("欧几里得剧场（积+1 反复出新素数）: ", euclid(6))
function extgcd(a, b)                           # 辗转相除带回贝祖系数
    b == 0 && return (a, 1, 0)
    (g, u, v) = extgcd(b, a % b)
    (g, v, u - (a ÷ b) * v)
end
ok_bezout = all(2:50) do m
    all(2:50) do n
        (g, u, v) = extgcd(m, n)
        g == gcd(m, n) && u * m + v * n == g
    end
end
println("扩展贝祖（2..50 网格）: ", ok_bezout)

# ---------- 四、书版 ℚ（既约代表元 [(m,n)]，定义 1.46） ----------
gcd2(a, b) = b == 0 ? a : gcd2(b, a % b)
qreduce(m, n) = (g = gcd2(m, n); (m ÷ g, n ÷ g))
ok_q = all(1:15) do m
    all(2:15) do n
        (a, b) = qreduce(m, n)
        gcd2(a, b) == 1 && a // b == m // n
    end
end
println("既约化算子 [(m,n)] 与 Julia Rational 对拍: ", ok_q)
ok_dense = all(a < b && (a // 1 < (a + b) // 2 < b // 1)
               for a in -3:3 for b in -3:3 if a < b)
println("ℚ 中点稠密性（命题 1.17）: ", ok_dense)

# ---------- 五、往返渐进（定理 1.38）：ℚ ≅ 二进有理数 ----------
function backforth(nsteps)
    As = [i // j for j in 1:8 for i in -12:12]
    Bs = [k // 2^e for e in 0:6 for k in -40:40]
    NEG, POS = (-10^9) // 1, (10^9) // 1
    h = Dict{Rational{Int},Rational{Int}}()      # 部分同构 A → B
    taken = Set{Rational{Int}}()
    function insertA(a)                          # "往"：吃 A 侧元素
        haskey(h, a) && return true
        lo = maximum((h[x] for x in keys(h) if x < a); init = NEG)  # 邻居的"像"
        hi = minimum((h[x] for x in keys(h) if x > a); init = POS)
        opts = [b for b in Bs if !(b in taken) && lo < b < hi]
        isempty(opts) && return false
        h[a] = first(opts); push!(taken, h[a]); true
    end
    function insertB(b)                          # "返"：吃 B 侧元素
        b in taken && return true
        lo = maximum((x for x in keys(h) if h[x] < b); init = NEG)
        hi = minimum((x for x in keys(h) if h[x] > b); init = POS)
        opts = [a for a in As if !haskey(h, a) && lo < a < hi]
        isempty(opts) && return false
        h[first(opts)] = b; push!(taken, b); true
    end
    for step in 1:nsteps
        if isodd(step)
            insertA(As[mod1(step, length(As))])
        else
            insertB(Bs[mod1(step, length(Bs))])
        end
    end
    ks = collect(keys(h))
    mono = all(t -> t, ((ks[i] < ks[j]) == (h[ks[i]] < h[ks[j]]))
               for i in eachindex(ks) for j in eachindex(ks))
    (length(ks), mono)
end
(n, mono) = backforth(60)
println("往返渐进 60 步：部分同构覆盖 ", n, " 点，双向单调 = ", mono)

println("END ====")
