# 第 83 章：截断超有理数 a + b·ε 的无穷小不等式核对。
println("==== 83")

struct TQ
    a::Rational{BigInt}
    b::Rational{BigInt}
end

tplus(x::TQ, y::TQ) = TQ(x.a + y.a, x.b + y.b)
tmul(x::TQ, y::TQ) = TQ(x.a * y.a, x.a * y.b + x.b * y.a)
tlt(x::TQ, y::TQ) = x.a < y.a || (x.a == y.a && x.b < y.b)
teq(x::TQ, y::TQ) = x.a == y.a && x.b == y.b

const ZERO = TQ(big(0)//big(1), big(0)//big(1))
const ONE = TQ(big(1)//big(1), big(0)//big(1))
const EPS = TQ(big(0)//big(1), big(1)//big(1))

# 无穷小：0 < ε < 1/n 对 n = 1..40。
for n in 1:40
    inv_n = TQ(big(1)//BigInt(n), big(0)//big(1))
    @assert tlt(ZERO, EPS) && tlt(EPS, inv_n)
end

# Archimede 失效：对一切 k ≤ 40，k·ε < 1。
for k in 1:40
    @assert tlt(tmul(TQ(BigInt(k)//big(1), big(0)//big(1)), EPS), ONE)
end

# 标准部分精确律：n·(1/n) = 1，(1+ε)² = 1 + 2ε。
for n in 1:40
    @assert teq(tmul(TQ(BigInt(n)//big(1), big(0)//big(1)),
                     TQ(big(1)//BigInt(n), big(0)//big(1))), ONE)
end
@assert teq(tmul(tplus(ONE, EPS), tplus(ONE, EPS)), TQ(big(1)//big(1), big(2)//big(1)))

println("Julia：ε 满足 0 < ε < 1/n（n≤40）与 k·ε < 1（k≤40）；")
println("标准部分精确 n·(1/n) = 1；(1+ε)² = 1 + 2ε（截断律 ε² = 0）")
println("END ====")
