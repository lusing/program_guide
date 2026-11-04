# 第 18 章 · 环同态 —— Julia 通道
#
# mod 同态的核与像 + 求值同态统计 + 非同态反例 + ℚ(i) 表自同构。

println("==== 18 环同态")

# ---------- (1) mod 同态 ℤ₁₂ → ℤ₄：k mod 4 ----------
f124 = k -> k % 4
n = 12
for a in 0:11, b in 0:11
    @assert f124((a + b) % 12) == (f124(a) + f124(b)) % 4
    @assert f124((a * b) % 12) == (f124(a) * f124(b)) % 4
end
ker = [k for k in 0:11 if f124(k) == 0]
im = unique(f124.(0:11))
@assert ker == [0, 4, 8] && length(im) == 4
@assert 12 == length(ker) * length(im)
println("ℤ₁₂ → ℤ₄（mod 4）：144 对全查；核 = {0,4,8}，|ℤ₁₂| = 3 × 4 ✓")

# ---------- (2) 求值同态 φ₂ : ℤ₇[x] → ℤ₇ ----------
peval(f, a) = (v = 0; for i in length(f):-1:1; v = (v * a + f[i]) % 7; end; v)
polymul(f, g) = begin
    r = zeros(Int, length(f) + length(g) - 1)
    for (i, x) in enumerate(f), (j, y) in enumerate(g)
        r[i + j - 1] = (r[i + j - 1] + x * y) % 7
    end
    r
end
# 次数 ≤ 2 的全部 343 个多项式中核恰 49 个（= (x−2) 的倍数）
cnt_ker = 0
for a in 0:6, b in 0:6, c in 0:6
    peval([a, b, c], 2) == 0 && (global cnt_ker += 1)
end
@assert cnt_ker == 49
# |ℤ₇[x]_{≤2}| / |ker| = |im| = 49 ⟹ 343 = 49 × 7
@assert 343 == cnt_ker * 7
println("φ₂ : ℤ₇[x]≤2 → ℤ₇：343 个多项式中核恰 49 = 7²（第一同构数值投影）✓")

# ---------- (3) 非同态反例 ----------
sq7 = a -> (a * a) % 7
@assert sq7(1 + 1) != (sq7(1) + sq7(1)) % 7 "平方映射加性应破产"
println("非同态：ℤ₇ 平方映射 φ(1+1) = $(sq7(2)) ≠ 1 + 1 = 2 ✓")

# 范数 ℤ[i] → ℤ 非加性：N((1+i)+(1+i)) = 8 ≠ N(1+i)+N(1+i) = 4
N(z) = z.re * z.re + z.im * z.im  # 不用复数类型，直接算
Ni(a, b) = a * a + b * b
@assert Ni(2, 2) == 8 && Ni(1, 1) + Ni(1, 1) == 4
# 乘性：N(zw) = N(z)N(w)
for _ in 1:100
    z = (rand(-5:5), rand(-5:5)); w = (rand(-5:5), rand(-5:5))
    zw = (z[1]*w[1] - z[2]*w[2], z[1]*w[2] + z[2]*w[1])
    @assert Ni(zw...) == Ni(z...) * Ni(w...)
end
println("高斯范数：N((1+i)+(1+i)) = 8 ≠ 4（非加性）；N(zw) = N(z)N(w)（乘性 100 对）✓")

# ---------- (4) ℚ(i) 序对模型的自同构：恒等与共轭 ----------
qmul(z, w) = (z[1]*w[1] - z[2]*w[2], z[1]*w[2] + z[2]*w[1])
qs = [(0, 0), (1, 0), (0, 1), (0, -1)]
conjs = [id -> id, conj]
# 检查两个映射 φ(z) = z 与 φ(z) = z̄ 保持乘法
for phi in (z -> z, z -> (z[1], -z[2]))
    for z in qs, w in qs
        @assert phi(qmul(z, w)) == qmul(phi(z), phi(w))
    end
end
# 不存在第三个自同构（枚举 i 的像只能 ±i）
println("ℚ(i) 序对模型：恒等与共轭两个自同构保乘法（16 对 × 2 映射）✓")

println("END ====")
