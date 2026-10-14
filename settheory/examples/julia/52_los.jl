# 第 52 章 L⁺ 混合实验室 + 可测函数域（Prop 6.4.1/6.4.3 数值版）

println("==== 52")

using Random

# ---------- (a) MALG 反链（两两不交正测度 dyadic 集） ----------
function dyadic_partitions(n)
    # 第 n 层 dyadic 区间
    [(k / 2^n, (k + 1) / 2^n) for k in 0:(2^n - 1)]
end

L3 = dyadic_partitions(3)     # 8 个区间，两两不交
println("(a) MALG 反链：第 3 层 8 个 dyadic 区间（两两不交、各测 1/8）")
measure(I) = I[2] - I[1]
@assert all(measure(I) ≈ 1 / 8 for I in L3)
println("    ——ccc 保证任何反链可数；本例恰 8 元")

# ---------- (b) 混合拼装（Prop 6.4.1 的构造） ----------
# 在每个 X_d 上贴 f_d：取 8 个随机一次函数，拼装 g
Random.seed!(52)
fs = [x -> (i % 3) * x + (i % 2) for i in 1:8]
function mixed_g(x)
    # 找 x 落入哪个区间，用对应的 f
    for (i, (a, b)) in enumerate(L3)
        if a <= x < b
            return fs[i](x)
        end
    end
    return fs[8](1.0)
end

# 验证拼装在每段上等于对应的 f_d
ok_mix = all(begin
    mid = (a + b) / 2
    abs(mixed_g(mid) - fs[i](mid)) < 1e-12
end for (i, (a, b)) in enumerate(L3))
println("(b) 混合拼装 g|X_d = f_d（8 段中点抽查）：", ok_mix ? "✓" : "✗")
@assert ok_mix
println("    ——g 可测（有限拼装保持可测性）⟹ 混合性质落地")

# ---------- (c) 可测函数域（Prop 6.4.3） ----------
# f 的核 = {f = 0}；g = 1/f · χ_{f≠0} 是双侧逆（mod Null）
f(x) = x - 0.5                    # 零点 0.5（单点，零测）
ginv(x) = abs(x - 0.5) < 1e-15 ? 0.0 : 1 / (x - 0.5)

xs = range(0, 1; length = 1001)
# f·g = 1 mod Null（除零点外）
prod = [f(x) * ginv(x) for x in xs]
nonzero = [x for x in xs if abs(x - 0.5) > 1e-9]
ok_inv = all(abs(f(x) * ginv(x) - 1) < 1e-9 for x in nonzero)
println("(c) 可测函数域：f·g = 1 除零测集 {0.5} 外成立：", ok_inv ? "✓" : "✗")
@assert ok_inv
println("    ⟦x≠0 → y(x·y=1)⟧ = 1——L⁺ 满足域公理（Prop 6.4.3）✓")

println("END ====")
