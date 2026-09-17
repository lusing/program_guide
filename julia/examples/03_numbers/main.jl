# 03 数值类型：整型/浮点/BigInt/有理数/复数、溢出、整除家族、promote 与 convert
# 运行：julia --startup-file=no main.jl
# 注意：Julia 的注释是 #——`//` 是有理数除法运算符，不是注释！

# ═══ 03.1 整型族：固定位宽，溢出静默环绕
println("Int64 范围：[", typemin(Int64), ", ", typemax(Int64), "]")
@assert typemax(Int64) + 1 == typemin(Int64)     # 环绕，不抛错！
@assert UInt8(255) + UInt8(1) == UInt8(0)        # 无符号同样环绕
println("typemax(Int64)+1 = ", typemax(Int64) + 1, "（环绕到最小值）")

# 任意精度：BigInt（big"..." 字面量）
@assert big"2" ^ 100 == BigInt(2)^100
println("2^100 = ", big"2" ^ 100)

# ═══ 03.2 浮点族：Float64 默认、Float16/32、特殊值
@assert 0.1 + 0.2 != 0.3                          # IEEE 754 经典
@assert isapprox(0.1 + 0.2, 0.3)
@assert isnan(0.0 / 0.0) && isnan(NaN)
@assert typemax(Float64) == Inf                   # 注意：Float 的 typemax 就是 Inf 本身
@assert Inf > floatmax(Float64)                   # 最大有限浮点用 floatmax
@assert eps(Float64) ≈ 2.220446049250313e-16
println("0.1 + 0.2 == 0.3 ？ ", 0.1 + 0.2 == 0.3, "；isapprox ？ ", isapprox(0.1 + 0.2, 0.3))

# ═══ 03.3 整除家族：/ ÷ div fld cld rem mod
@assert 7 / 2 == 3.5                              # / 永远返回浮点
@assert 7 ÷ 2 == 3                                # ÷（输入 \div）向零截断
@assert 7 ÷ -2 == -3                              # 截断：向零取整
@assert fld(7, 2) == 3 && fld(-7, 2) == -4        # floor：向下取整
@assert cld(7, 2) == 4                            # ceil：向上取整
@assert rem(7, 2) == 1 && rem(-7, 2) == -1        # rem：与被除数同号（截断式）
@assert mod(-7, 2) == 1                           # mod：与除数同号
println("7÷2=$(7 ÷ 2)  fld(-7,2)=$(fld(-7, 2))  rem(-7,2)=$(rem(-7, 2))  mod(-7,2)=$(mod(-7, 2))")

# ═══ 03.4 有理数与复数：// 与 im 是字面量的一部分
@assert 1 // 3 + 1 // 6 == 1 // 2                 # 精确分数运算
@assert numerator(3 // 9) == 1 && denominator(3 // 9) == 3   # 自动约分（函数名是全称，无 num/den）
@assert (2 // 3) * 3 == 2                         # 与整数混算自动提升
@assert (1 + 2im) * (1 - 2im) == 5 + 0im          # 复数乘法
@assert abs(3 + 4im) == 5
@assert real(1 + 2im) == 1 && imag(1 + 2im) == 2
println("(1+2im)*(1-2im) = ", (1 + 2im) * (1 - 2im))

# ═══ 03.5 promote 与 convert：类型提升是可查询的规则
@assert promote(1, 2.0) == (1.0, 2.0)             # 统一到"公共更宽"类型
@assert promote(1, 2.0, 3 // 4) == (1.0, 2.0, 0.75)
@assert promote(Int32(1), Int64(2)) == (Int64(1), Int64(2))
@assert convert(Float64, 3) == 3.0                # convert：显式转换，可能丢精度
# Int(3.99) 直接抛 InexactError——Int() 只接受"精确可表示"的值，不截断！
@assert trunc(Int, 3.99) == 3                     # trunc：向零截断
@assert floor(Int, 3.99) == 3 && ceil(Int, 3.99) == 4
@assert round(Int, 3.5) == 4 && round(Int, 2.5) == 2   # round：四舍六入五取偶
println("promote(1, 2.0) = ", promote(1, 2.0), "；trunc(Int, 3.99) = ", trunc(Int, 3.99))

# ═══ 03.6 常用数值函数
@assert gcd(12, 18) == 6 && lcm(4, 6) == 12
@assert isqrt(10) == 3                            # 整数平方根
@assert abs(-5) == 5 && sign(-5) == -1
@assert clamp(15, 0, 10) == 10
@assert min(3, 1, 2) == 1 && max(3, 1, 2) == 3
@assert parse(Int, "42") == 42 && parse(Float64, "0.5") == 0.5
@assert string(255, base = 16) == "ff"
println("gcd(12,18)=$(gcd(12, 18))  isqrt(10)=$(isqrt(10))  clamp(15,0,10)=$(clamp(15, 0, 10))")

# ═══ 自检汇总
@assert 1 // 3 + 1 // 6 + 1 // 2 == 1
println("==== 03 结束 ====")
