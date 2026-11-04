# 第 16 章 · 域与分式域 —— Julia 通道
#
# 序对分式的完整机器化 + ℤ[√2] 模型 + 良定义性爆破实验（ℤ/6ℤ）。

println("==== 16 域与分式域")

# ---------- 序对分式构造（ℤ 上） ----------
struct Frac
    num::Int
    den::Int
end

frac(a::Int, b::Int) = begin
    b == 0 && error("分母为零")
    g = gcd(a, b); s = b < 0 ? -1 : 1
    Frac(s * a ÷ g, abs(b ÷ g))
end

Base.:+(f::Frac, g::Frac) = frac(f.num * g.den + g.num * f.den, f.den * g.den)
Base.:*(f::Frac, g::Frac) = frac(f.num * g.num, f.den * g.den)
Base.:-(f::Frac, g::Frac) = frac(f.num * g.den - g.num * f.den, f.den * g.den)
Base.:/(f::Frac, g::Frac) = frac(f.num * g.den, f.den * g.num)
Base.:(==)(f::Frac, g::Frac) = f.num * g.den == g.num * f.den

# 断言组（ℤ 上）
f1 = frac(1, 2); f2 = frac(1, 3); f3 = frac(2, 6)
@assert f1 + f2 == frac(5, 6)
@assert f1 * f2 == frac(1, 6)
@assert f3 == frac(1, 3)            # (2,6) ~ (1,3)：等价类代表元无关
@assert (f1 - f2) / f3 == frac(1, 2)   # (1/6) / (1/3) = 1/2
println("ℤ 分式构造：1/2 + 1/3 = 5/6；1/2·1/3 = 1/6；(2,6) = (1,3) ✓")

# ---------- ℤ[√2] 模型：序对 (a,b) = a + b√2 ----------
struct Q2
    a::Rational{Int}
    b::Rational{Int}
end
Base.:+(x::Q2, y::Q2) = Q2(x.a + y.a, x.b + y.b)
Base.:*(x::Q2, y::Q2) = Q2(x.a * y.a + 2 * x.b * y.b, x.a * y.b + x.b * y.a)
norm2(x::Q2) = x.a * x.a - 2 * x.b * x.b      # 范数（乘性探针）

s = Q2(0, 1)                                  # √2
@assert s * s == Q2(2, 0)                     # (√2)² = 2
@assert norm2(s * s) == norm2(s) * norm2(s)   # N(zw) = N(z)N(w)
one = Q2(1, 0)
# (1+√2) 的逆 = (√2−1)：范数 ±1 的元素可逆
inv_1p = Q2(-1, 1)
@assert Q2(1, 1) * inv_1p == one
println("ℤ[√2] 序对模型：(√2)² = 2；N(zw) = N(z)N(w)；(1+√2)⁻¹ = √2−1 ✓")

# ---------- 良定义性爆破实验：ℤ/6ℤ 上伪造分式 ----------
# 关系 (a,b) ~ (c,d) ⟺ ad ≡ bc (mod 6)：传递性应破产
function mod6_equiv(a, b, c, d)
    mod(a * d - b * c, 6) == 0
end
witness = nothing
for a1 in 0:5, b1 in 1:5, a2 in 0:5, b2 in 1:5, a3 in 0:5, b3 in 1:5
    if mod6_equiv(a1, b1, a2, b2) && mod6_equiv(a2, b2, a3, b3) &&
       !mod6_equiv(a1, b1, a3, b3)
        global witness = (a1, b1, a2, b2, a3, b3)
        break
    end
end
@assert witness !== nothing "ℤ/6ℤ 上伪造等价关系应传递性破产"
println("良定义性爆破：ℤ/6ℤ 上 (a,b)~(c,d) ⟺ ad≡bc 的传递性反例 = ",
        join(witness, ","), " ✓")

# 分式构造良性 ⟺ m 素（命题 3.15 再确认）
function modp_equiv_ok(p)
    for a1 in 0:p-1, b1 in 1:p-1, a2 in 0:p-1, b2 in 1:p-1, a3 in 0:p-1, b3 in 1:p-1
        if mod(a1*b2 - b1*a2, p) == 0 && mod(a2*b3 - b2*a3, p) == 0 &&
           mod(a1*b3 - b1*a3, p) != 0
            return false
        end
    end
    true
end
for m in (5, 7, 11)
    @assert modp_equiv_ok(m)
end
for m in (4, 6, 8, 9)
    @assert !modp_equiv_ok(m)
end
println("分式构造良性谱：素数模全过、合成数模全爆 ✓")

println("END ====")
