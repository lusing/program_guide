# 第 06 章 复数与欧几里得空间：Julia 通道。
# 复数按定义写成实数有序对 (a, b)，乘法 (a,b)(c,d) = (ac-bd, ad+bc)；
# 全程用 Rational{BigInt}，没有浮点舍入。再与 Julia 内置 Complex 对照。
# 欧氏空间部分：内积、范数平方、Cauchy–Schwarz 与 Lagrange 恒等式。
# 运行：julia --startup-file=no 06_complex.jl

println("==== 06 complex ====")

# --- 1. 复数 = 有序对 ---------------------------------------------------
struct C
    re::Rational{BigInt}
    im::Rational{BigInt}
end
C(a::Integer, b::Integer) = C(big(a) // 1, big(b) // 1)

cadd(z::C, w::C) = C(z.re + w.re, z.im + w.im)
cmul(z::C, w::C) = C(z.re * w.re - z.im * w.im, z.re * w.im + z.im * w.re)
cconj(z::C) = C(z.re, -z.im)
cnorm2(z::C) = z.re^2 + z.im^2
function cinv(z::C)
    d = cnorm2(z)
    @assert d != 0
    C(z.re / d, -z.im / d)
end
ceq(z::C, w::C) = z.re == w.re && z.im == w.im

i = C(0, 1)
@assert ceq(cmul(i, i), C(-1, 0))
println("i * i = -1")

z, w = C(1, 2), C(3, 4)
@assert ceq(cmul(z, w), C(-5, 10))          # (1+2i)(3+4i) = -5 + 10i
println("(1+2i)(3+4i) = -5 + 10i")

@assert ceq(cmul(z, cconj(z)), C(cnorm2(z), 0 // 1))   # z * conj z = |z|^2
println("z * conj(z) = |z|^2 = 5")

@assert ceq(cmul(z, cinv(z)), C(1, 0))       # 1/z 确实是逆元
println("z * (1/z) = 1, 1/(1+2i) = $(cinv(z).re) + $(cinv(z).im)i")

@assert cnorm2(C(3, 4)) == 25                # |3+4i| = 5
println("|3+4i|^2 = 25, |3+4i| = 5")

# 与内置 Complex{Int} 对照：同一乘法公式。
@assert (1 + 2im) * (3 + 4im) == -5 + 10im
@assert abs(3 + 4im) == 5.0
println("builtin Complex agrees")

# --- 2. 欧几里得空间 R^n --------------------------------------------------
dot(x, y) = sum(x .* y)
n2(x) = dot(x, x)

x, y = [1, 2], [3, 4]
@assert dot(x, y) == 11 && n2(x) == 5 && n2(y) == 25
@assert dot(x, y)^2 <= n2(x) * n2(y)                  # 121 <= 125
@assert n2(x) * n2(y) - dot(x, y)^2 == (1 * 4 - 2 * 3)^2   # Lagrange：差 4
println("C-S in R^2: 121 <= 125, gap 4 = (1*4 - 2*3)^2")

# 一般 n 维 Lagrange 恒等式：差 = sum_{i<j} (x_i y_j - x_j y_i)^2。
function lagrange_gap(x, y)
    s = big(0)
    for i in eachindex(x), j in eachindex(y)
        if i < j
            s += (x[i] * y[j] - x[j] * y[i])^2
        end
    end
    s
end
u = big.([3, -1, 4, 1, -5])
v = big.([2, 7, -1, 8, 2])
@assert n2(u) * n2(v) - dot(u, v)^2 == lagrange_gap(u, v)
@assert dot(u, v)^2 <= n2(u) * n2(v)
println("C-S in R^5: $(dot(u, v)^2) <= $(n2(u) * n2(v)), gap = sum of squares")

# 三角不等式：|u+v|^2 <= (|u|+|v|)^2 等价于 <u,v> <= |u||v|，由 C-S 推出。
@assert sqrt(n2(u + v)) <= sqrt(n2(u)) + sqrt(n2(v))
println("triangle inequality holds in R^5")

println("END ====")
