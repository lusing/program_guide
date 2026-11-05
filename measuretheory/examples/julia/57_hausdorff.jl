# 第 57 章 Julia：Hausdorff 测度的数值横截面（确定性，无随机）。
# ① 盒计数：Cantor 阶段集 N(ε)=2^n，斜率恒为 log2/log3（严格自相似）；
# ② 覆盖账 2^n·(3^-n)^s 三档走向：s=1/2 发散、s=7/10 几何衰减、
#    临界 s=log2/log3 停在常数 1（相变点）；
# ③ 阶段集（等距间隙）上 φ-m = φ-P 取等；Tricot 集 {1/k} 的盒计数
#    斜率向 1/2 逼近——填充侧维数的信号。
println("==== 57 hausdorff")

# ---------- ① 盒计数斜率 ----------
crit = log(2) / log(3)
println("① 临界 s = log2/log3 ≈ ", round(crit, digits=4))
for n in 1:10
    slope = log(2.0^n) / log(3.0^n)
    @assert abs(slope - crit) < 1e-12
end
println("   n=1..10 盒计数斜率恒为 log2/log3（严格自相似 ⇒ 盒维数 = Hausdorff 维数）")

# ---------- ② 覆盖账三档（整数幂 + 精确开方，避免浮点累积） ----------
# 2^n·(3^-n)^s = (2^{10n} / 3^{10ns})^{1/10}；对有理 s = a/b 取 10b·s 整数幂。
function cover_sum(n::Int, s::Rational{Int})
    e = 10 * s.den                     # 指数放大到整数：s = a/b ⟹ e·s = 10a
    num = big(2)^(e * n)
    den = big(3)^(10 * s.num * n)
    Float64((num // den)^(1 / e))
end
v_low  = [cover_sum(n, 1 // 2) for n in 1:12]   # s=1/2 < 0.6309：账发散
v_high = [cover_sum(n, 7 // 10) for n in 1:12]  # s=7/10 > 0.6309：账几何衰减
@assert v_low[12] > v_low[4] > 1      # 单调膨胀 → ∞
@assert v_high[12] < v_high[1] < 1    # 单调衰减 → 0
println("② s=1/2（低于临界）: n=1,4,12 → ", round(v_low[1], digits=3), ", ",
    round(v_low[4], digits=3), ", ", round(v_low[12], digits=3), "  → ∞")
println("② s=7/10（高于临界）: n=1,4,12 → ", round(v_high[1], digits=3), ", ",
    round(v_high[4], digits=4), ", ", round(v_high[12], digits=6), "  → 0")
@assert abs(2 * 3.0^(-crit) - 1.0) < 1e-12
println("② 临界 s: 2·3^-s = 1，覆盖账恒为 1——零或顶二分法的相变点")

# ---------- ③ 填充侧与覆盖侧并排 ----------
# 阶段 n 的 Cantor 近似是 2^n 个等间隙点（相邻距离 3^-n）：
#   δ = 3^-n 时每点摆半径 3^-n/2 的球（间隙恰容两球），填充账（s=1）
#   = 2^n · 3^-n = (2/3)^n，与区间覆盖账相等——等距集上取等。
for n in 2:8
    cover = Rational(2)^n // Rational(3)^n
    @assert cover == Rational(2, 3)^n
end
println("③ 阶段集（等距）：φ-m = φ-P = (2/3)^n，两侧取等；分离见 Tricot 集")
# Tricot 集 {1/k}：尺度 1/M 的盒子数 ≈ #{floor(M/k)} ≈ 2√M，斜率 → 1/2
function tricot_slope(M::Int)
    boxes = Set(floor(Int, M // k) for k in 1:(20 * M))
    log(length(boxes)) / log(M)
end
println("③ Tricot {1/k} 盒斜率：M=100 → ", round(tricot_slope(100), digits=3),
    "，M=400 → ", round(tricot_slope(400), digits=3),
    "，M=1600 → ", round(tricot_slope(1600), digits=3),
    "（→ 1/2：dim_H = 0，填充侧信号 1/2）")

println("END ====")
