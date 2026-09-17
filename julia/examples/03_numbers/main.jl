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

# ═══ 03.7 数值稳定性：抵消、求和顺序、补偿求和、稳定求根
# 灾难性抵消：x→0 时 (1-cos x)/x² → 1/2，但 cos x ≈ 1 把有效位吃光
bad_cancellation(x) = (1 - cos(x)) / x^2
stable_cancellation(x) = 2 * sin(x / 2)^2 / x^2     # 等价恒等式：无相近数相减
@assert stable_cancellation(1e-8) ≈ 0.5             # 稳定式正确
@assert bad_cancellation(1e-8) == 0.0               # 朴素式直接得 0：cos(1e-8) 舍入成 1.0，差值全丢
println("(1-cos x)/x² @ x=1e-8：朴素 = ", bad_cancellation(1e-8), "，稳定 = ", stable_cancellation(1e-8))

# ulp（最后位单位）直觉：1e16 处相邻可表示数间隔 2——加 1 被吞、加 2 活下来
@assert (1e16 + 1) - 1e16 == 0.0                    # 1 不及半个 ulp：加了个寂寞
@assert (1e16 + 2) - 1e16 == 2.0                    # 2 恰好一个 ulp：精确保留

# Kahan 补偿求和：一堆小数加大数时把"丢失的低位"记回来
function kahan_sum(v)
    s = c = 0.0
    for x in v
        y = x - c
        t = s + y
        c = (t - s) - y
        s = t
    end
    s
end
vals = [1e16; ones(10_000)]                         # 一个大数 + 一万个小数
naive_sum(v) = (s = 0.0; for x in v; s += x; end; s)
exact = big(1e16) + big(10_000)                     # BigInt 当精确参考答案
target = Float64(exact)
@assert kahan_sum(vals) == target                   # Kahan 逐位恢复
@assert abs(naive_sum(vals) - target) > 9_000       # 顺序累加：小数几乎全丢
@assert abs(sum(vals) - target) < 1_000             # 内置 sum（pairwise/SIMD 归约）：好两个数量级
println("求和对比：naive 差 ", round(abs(naive_sum(vals) - target)),
        "，内置 sum 差 ", round(abs(sum(vals) - target)),
        "，Kahan 差 0（目标增量 10000）")
# 注意：内置 sum 的舍入取决于编译旗标——实测 --check-bounds=yes 下归约路径不同，
# 差值 626 vs 默认 38。要跨机器逐位复现：固定旗标，或用 Kahan/BigFloat 拿参考值再比较

# 一元二次的稳定求根：避免 b ± √Δ 的抵消；另一根走韦达定理
function stable_quad(a, b, c)
    Δ = b^2 - 4a * c
    Δ < 0 && error("复根")
    s = b >= 0 ? 1.0 : -1.0                         # 别用 sign(b)：sign(0) == 0，b=0 时 q=0 → c/q=Inf！
    q = -0.5 * (b + s * sqrt(Δ))                    # 同号相加，绝不抵消
    (q / a, c / q)                                  # 两根 = q/a 与 c/q（积 = c/a）
end
r1, r2 = stable_quad(1.0, -1e8, 1.0)                # 真根：1e8 与 1e-8
@assert abs(r1 - 1e8) < 1e-7 && abs(r2 - 1e-8) < 1e-12 && r1 * r2 ≈ 1.0
naive_small = (-(-1e8) - sqrt(1e16 - 4)) / 2        # 朴素小根：相近数相减
@assert abs(naive_small - 1e-8) > 1e-12             # 丢有效位
println("二次方程 x²-1e8x+1 的小根：稳定式 = ", r2, "，朴素式 = ", naive_small)

# ═══ 自检汇总
@assert 1 // 3 + 1 // 6 + 1 // 2 == 1
println("==== 03 结束 ====")
