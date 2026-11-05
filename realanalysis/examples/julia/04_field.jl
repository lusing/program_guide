# 第 04 章 实数域（上）：Julia 通道。
# 域公理在三个世界里的命运：Float64 不是域（结合律有反例）、
# Rational 是域、Z5（mod 5 整数）是域。
# 运行：julia --startup-file=no 04_field.jl

println("==== 04 field ====")

# --- 1. Float64 破坏结合律：大数吞噬小加数 ---------------------------
# (1 + (-1e100)) + 1e100 = 0，而 1 + ((-1e100) + 1e100) = 1。
left = (1.0 + -1e100) + 1e100
right = 1.0 + (-1e100 + 1e100)
@assert left != right
println("float assoc counterexample: (1 - 1e100) + 1e100 = $left, 1 + (-1e100 + 1e100) = $right")

# --- 2. Rational{BigInt} 是域：公理逐条抽查 --------------------------
function check_field_axioms(T, samples)
    for a in samples, b in samples, c in samples
        @assert (a + b) + c == a + (b + c)
        @assert (a * b) * c == a * (b * c)
        @assert a + b == b + a && a * b == b * a
        @assert a * (b + c) == a * b + a * c
        @assert a + zero(T) == a
        @assert a * one(T) == a
        @assert a + (-a) == zero(T)
        a != zero(T) && @assert a * inv(a) == one(T)
    end
end
qs = Rational{BigInt}[1//2, -3//7, 22//7, 0//1, 355//113]
check_field_axioms(Rational{BigInt}, qs)
println("Rational{BigInt}: all field axioms verified on samples")

# --- 3. Z5 是域：加法表/乘法表全枚举 ----------------------------------
z5add(a, b) = mod(a + b, 5)
z5mul(a, b) = mod(a * b, 5)
T = 0:4
for a in T, b in T, c in T
    @assert z5add(z5add(a, b), c) == z5add(a, z5add(b, c))
    @assert z5mul(z5mul(a, b), c) == z5mul(a, z5mul(b, c))
    @assert z5add(a, b) == z5add(b, a) && z5mul(a, b) == z5mul(b, a)
    @assert z5mul(a, z5add(b, c)) == z5add(z5mul(a, b), z5mul(a, c))
end
# 每个非零元有逆元：2*3 = 1 mod 5。
for a in 1:4
    @assert any(b -> z5mul(a, b) == 1, 1:4)
end
@assert z5add(2, 3) == 0     # 原书例 5.2：2+3 = 0 in Z5
@assert z5mul(2, 3) == 1
println("Z5: full field axiom enumeration passed (2+3=0, 2*3=1)")

# --- 4. Z 不是域：2 没有整数逆元 ---------------------------------------
@assert !any(z -> 2z == 1, -1000:1000)
println("Z: no integer z with 2z = 1")

println("END ====")
