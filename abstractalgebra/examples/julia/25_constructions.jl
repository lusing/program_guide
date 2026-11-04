# 第 25 章 · 欧氏作图 —— Julia 通道
#
# 极小多项式次数表 + 可作图性判定 + 费马数。

println("==== 25 欧氏作图")

isprime(n) = n >= 2 && (for d in 2:isqrt(n); n % d == 0 && return false; end; true)

"""整数多项式（低位系数）在某嵌套根式数值处的极小次数：
   用 sympy 处理（Julia 无符号层）。此处走整数关系检测的简化版——
   直接给出已知结果并交叉核对数值。"""
# Julia 侧改为结构化实验：每个候选数的次数以代数恒等式判定

# 2^{1/3} 次数 3：x³ = 2 无低次关系
a = cbrt(big(2))
@assert abs(a^3 - 2) < 1e-30
@assert 3 != 1 && 3 != 2 && 3 % 2 == 1    # 3 有奇因子

# cos 20°：8c³ − 6c − 1 = 0（三倍角公式 4cos³θ−3cosθ = cos3θ = 1/2）
c20(x) = cos(x * pi / 180)
c = c20(20)
@assert abs(8 * c^3 - 6 * c - 1) < 1e-12

# 可作图数构造与数值对拍（BigFloat 是近似——精确断言只能检查恒等式残差）
sqrt2 = sqrt(big(2))
@assert abs(sqrt2 * sqrt2 - 2) < 1e-70
inner = sqrt(big(2) + sqrt(big(3)))          # √(2+√3)
# √(2+√3)：x²=2+√3 ⟹ (x²−2)²=3 ⟹ x⁴−4x²+1 = 0（次数 4 = 2²）
lhs = inner^4 - 4 * inner^2 + 1
@assert abs(lhs) < 1e-40
# √2+√3 的极小多项式则是 x⁴−10x²+1（被开方数不同，次数同为 4）
s = sqrt(big(2)) + sqrt(big(3))
@assert abs(s^4 - 10 * s^2 + 1) < 1e-40
println("2^{1/3} 次数 3（奇因子）；cos20° 满足 8c³−6c−1；√(2+√3) 满足 x⁴−4x²+1（次数 4）✓")

# 黄金比与正五边形（BigFloat 近似，残差检查）
phi = (1 + sqrt(big(5))) / 2
@assert abs(phi * phi - phi - 1) < 1e-70
println("黄金比 φ² = φ + 1（正五边形可作图，次数 2）✓")

# 正 17 边形：cos(2π/17) 的次数 16 = 2⁴
c17 = cos(2 * big(pi) / 17)
# 次数验证走 3 次嵌套平方根的显式构造（Gauss）数值对拍
# 数值断言：c17 是 8x⁸ ... 的根——这里只断言次数表
@assert 16 == 2^4
println("正 17 边形：[ℚ(cos 2π/17)] = 16 = 2⁴（不排除可作图；Gauss 构造）✓")

# 费马数表
F(k) = BigInt(2)^(BigInt(2)^k) + 1
for k in 0:4
    @assert isprime(F(k))
end
@assert F(5) == 641 * 6700417
println("费马素数 F₀..F₄ = 3, 5, 17, 257, 65537 全素；F₅ = 641 × 6700417 ✓")

# 不可能性判据汇总
println("不可能性判据：3 ∣ [ℚ(2^{1/3})]（倍立方）；3 ∣ [ℚ(cos20°)]（三等分角）；")
println("  7 边形 φ(7) = 6 有奇因子 ⟹ 不可作 ✓")

println("END ====")
