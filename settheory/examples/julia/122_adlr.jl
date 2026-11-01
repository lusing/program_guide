# 第 122 章：AD^{L(R)} 的有限影子。
# 四件机器：有限决定性全枚举、尾等价代表（AC 反例的有限截断）、
# 完美集密度界（AD 正则性后果）、L(R) 定义参数编码。
# 边界：所有件都是有限对象，不证明 AD，也不构造 AC 的非确定博弈。

bit(table, k) = ((table >> k) & 1) == 1

# ---------- 件 1：长度 4 有限博弈的全表决定性 ----------
# 位置 0,2 张三行动；位置 1,3 李四行动；终局索引 x0+2x1+4x2+8x3。
# 张三策略 0..31：bit0=开局；bit(1+a0+2b0)=位置 2 回应。
imask4(s) = begin
    a0 = s & 1
    m = 0
    for b0 in (0, 1), b1 in (0, 1)
        a2 = (s >> (1 + a0 + 2 * b0)) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2 + 8 * b1)
    end
    m
end

# 李四策略 0..1023：bit a0=位置 1 回应；bit(2+a0+2b0+4a2)=位置 3 回应。
iimask4(t) = begin
    m = 0
    for a0 in (0, 1), a2 in (0, 1)
        b0 = (t >> a0) & 1
        b1 = (t >> (2 + a0 + 2 * b0 + 4 * a2)) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2 + 8 * b1)
    end
    m
end

play4(s, t) = begin
    a0 = s & 1
    b0 = (t >> a0) & 1
    a2 = (s >> (1 + a0 + 2 * b0)) & 1
    b1 = (t >> (2 + a0 + 2 * b0 + 4 * a2)) & 1
    a0 + 2 * b0 + 4 * a2 + 8 * b1
end

mm4(table) =
    any(a0 -> all(b0 -> any(a2 -> all(b1 ->
        bit(table, a0 + 2*b0 + 4*a2 + 8*b1), (0, 1)), (0, 1)), (0, 1)), (0, 1))

emasks = [imask4(s) for s in 0:31]
fmasks = [iimask4(t) for t in 0:1023]
# 张三 5 bit 编码含 2 个不关心位（位置 2 只按自己的开局索引），实际 8 个不同策略；
# 李四位置 3 的 8 槽中 4 槽永不与自己的位置 1 回应共存，实际 64 个不同策略。
@assert length(unique(emasks)) == 8 && length(unique(fmasks)) == 64
# 排他性：任意张三/李四策略对产生唯一对弈点，同时落入双方“必胜终局集”。
for s in 0:31
    @assert count_ones(emasks[s+1]) == 4
    for t in 0:1023
        p = play4(s, t)
        @assert bit(emasks[s+1], p) && bit(fmasks[t+1], p)
    end
end
@assert all(==(4), map(count_ones, fmasks))

win_i = 0
win_ii = 0
for table in 0:65535
    iwins = any(m -> (table & m) == m, emasks)
    iiwins = any(f -> (table & f) == 0, fmasks)
    @assert iwins == mm4(table)          # 逆向归纳值与策略枚举一致
    @assert iwins !== iiwins             # 恰一方胜
    global win_i += iwins
    global win_ii += iiwins
end
@assert win_i + win_ii == 65536
@assert win_i == 22687 && win_ii == 42849

# 长度 3 的小表：256 张，207 张张三胜、49 张李四胜。
imask3(s) = begin
    a0 = s & 1
    m = 0
    for b0 in 0:1
        a2 = (s >> (1 + b0)) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2)
    end
    m
end
iimask3(t) = begin
    m = 0
    for a0 in 0:1, a2 in 0:1
        b0 = (t >> a0) & 1
        m |= 1 << (a0 + 2 * b0 + 4 * a2)
    end
    m
end
w3i = count(table -> any(m -> (table & m) == m, [imask3(s) for s in 0:7]), 0:255)
w3ii = count(table -> any(f -> (table & f) == 0, [iimask3(t) for t in 0:3]), 0:255)
@assert (w3i, w3ii) == (207, 49)

# ---------- 件 2：尾等价代表与 AC 反例的有限截断 ----------
tailrep(n, m, x) = x & (((1 << m) - 1) << (n - m))
firstdiff(n, m, x) = begin
    for j in 0:(n-m-1)
        bit(x, j) && return j
    end
    n
end
tailpay(n, m, x) = iseven(firstdiff(n, m, x))

gamevalue(n, pay) = begin
    function rec(k, idx)
        k == n && return pay(idx)
        iseven(k) ? any(z -> rec(k + 1, idx | (z << k)), (0, 1)) :
                    all(z -> rec(k + 1, idx | (z << k)), (0, 1))
    end
    rec(0, 0)
end

tail_sizes = Dict()
for n in 1:6, m in 1:n
    for x in 0:(1<<n)-1
        r = tailrep(n, m, x)
        @assert tailrep(n, m, r) == r                    # 代表幂等
        @assert (r >> (n - m)) == (x >> (n - m))         # 代表留在同类
    end
    sz = count(x -> tailpay(n, m, x), 0:(1<<n)-1)
    tail_sizes[(n, m)] = sz
    v = gamevalue(n, x -> tailpay(n, m, x))
    @assert v isa Bool                                   # 有限博弈必有确定值
end
@assert tail_sizes[(4, 2)] == 12

# ---------- 件 3：完美集密度界（AD 完美集性质的有限影子） ----------
hasperfect(A, n, d) =
    any(s -> all(t -> bit(A, (s << d) | t), 0:(1<<d)-1), 0:(1<<(n-d))-1)

for A in 0:65535, d in 1:4
    if !hasperfect(A, 4, d)
        @assert count_ones(A) <= 16 - (1 << (4 - d))
    end
end
# 紧性：每个长度 4-d 柱恰缺一个叶点，计数恰达界且无深度 d 完美树。
for d in 1:4
    missing = reduce(|, [1 << (s << d) for s in 0:(1<<(4-d))-1]; init=0)
    Astar = 65535 ⊻ missing
    @assert !hasperfect(Astar, 4, d)
    @assert count_ones(Astar) == 16 - (1 << (4 - d))
end
# 更大 n 值只验证紧例构造。
for n in 6:10, d in (1, 2, n)
    missing = reduce(|, [big(1) << (s << d) for s in 0:(1<<(n-d))-1]; init=big(0))
    Astar = (big(1) << (1 << n)) - 1 - missing
    @assert !hasperfect(Astar, n, d)
    @assert count_ones(Astar) == (1 << n) - (1 << (n - d))
end

# ---------- 件 4：L(R) 定义参数编码（序数参数吸收进实数参数） ----------
enc(p, a) = (p << 4) | a            # p < 8 序数参数，a < 16 实数参数
dec(c) = (c >> 4, c & 15)
seen = Set()
for p in 0:7, a in 0:15
    c = enc(p, a)
    @assert c in 0:127
    @assert dec(c) == (p, a)         # 往返
    push!(seen, c)
end
@assert length(seen) == 128          # 编码单射

println("==== 122")
println("finite determinacy length4: 65536/65536 tables, I=$win_i II=$win_ii")
println("length3: 256 tables, I=$w3i II=$w3ii; 8x64 strategy pairs exclusive")
println("tail-representative games n=1..6 all determined; |A_(4,2)|=12")
println("perfect-tree bound: 65536 sets x 4 depths, tight on every depth")
println("parameter codes: 128/128 round-trip")
println("END ====")
