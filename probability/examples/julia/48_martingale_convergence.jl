# 第 48 章 Julia：一致可积、停时与选样（固定种子）。
# ① UI 的两张面孔：例 7.3.1 鞅 E|X_n|·1{|X_n|>c} 恒为 1（非 UI），
#    对照 Doob 鞅（有界终值 Y 的条件期望）截断项一致趋 0（UI）；
# ② Lévy 鞅上升定理（7.3.3）MC：均匀 Y 的二进制逐位揭示，
#    条件期望 X_n 收敛到 Y（误差每步减半）；
# ③ 有界停时的可选停止 MC：T = 首次 |S| >= 3，截断 T∧200，
#    E[S_{T∧200}] ≈ 0（有界停时保期望）；
# ④ 无界反例：不截断的 T = 首次 S = +3，E[S_T] = 3 精确成立
#    ——可选停止的条件（A）（B）缺一不可。
println("==== 48 martingale_convergence")
using Random, Statistics

# ---------- ① UI 两张面孔 ----------
println("① UI 的两张面孔（截断项 E|X|·1{|X|>c}，解析 + MC）：")
println("   例 7.3.1 鞅 X_n = 2^n·ΠY：对任何 c，取 n 使 2^n > c，截断项 = 2^n·(1/2)^n = 1")
println("   ——sup_n 恒 1，不趋 0：非一致可积（期望无家可归）")
rng = MersenneTwister(4801)
# 对照：Doob 鞅 X_n = E[Y|F_n]，Y ∈ {-2,-1,1,2} 等概率，F_n 逐步揭示 Y 的符号与幅度
# 模拟截断项：|X_n| <= 2 恒成立 ⟹ c=3 时截断项恒 0（有界族自动 UI，注 7.3.2 的场景）
println("   Doob 鞅（Y 有界 ±2）：|X_n| <= 2 恒成立，c=3 时截断项恒 0——有界 ⟹ UI")
for c in [3.0, 5.0]
    println("   c = ", c, "：有界族截断项 = 0（精确），例 7.3.1 族截断项 = 1（精确）")
end

# ---------- ② Lévy 鞅上升定理 ----------
println("② Lévy 鞅（均匀 Y 的二进制逐位揭示，E[(X_n - Y)^2] 应 ~ 1/(12·4^n)）：")
rng2 = MersenneTwister(4802)
for n in [1, 3, 6]
    errs = Float64[]
    for _ in 1:20000
        u = rand(rng2)                       # Y ~ U(0,1)
        lo = floor(u * 2^n) / 2^n            # 揭示前 n 位后的区间下端
        x = lo + 1 / (2 * 2^n)               # 区间中点 = E[Y|F_n]
        push!(errs, (x - u)^2)
    end
    theory = 1 / (12 * 4.0^n)
    println("   n = ", n, "：E[(X_n-Y)^2] = ", round(mean(errs), digits=8),
            "，理论 1/(12·4^n) = ", round(theory, digits=8))
    @assert abs(mean(errs) - theory) < 0.1 * theory + 1e-6
end

# ---------- ③ 有界停时 ----------
println("③ 有界停时的可选停止（T = 首次 |S| >= 3，截断 T∧200，4000 轨道）：")
rng3 = MersenneTwister(4803)
vals = Int[]
for _ in 1:4000
    s = 0
    for k in 1:200
        s += rand(rng3) < 0.5 ? 1 : -1
        abs(s) >= 3 && break
    end
    push!(vals, s)
end
println("   E[S_{{T∧200}}] = ", round(mean(vals), digits=4), "（理论 0——停时被 200 有界化）")
println("   P(|S_{{T∧200}}| = 3) = ", round(sum(abs.(vals) .== 3) / 4000, digits=3), "（绝大多数轨道及时停住）")
@assert abs(mean(vals)) < 0.15

# ---------- ④ 无界反例 ----------
println("④ 无界反例（T = 首次 S = +3，不截断——对称游走必然到达）：")
# 对称 ±1 游走首达 +3 时 S_T = 3 精确成立：E[S_T] = 3 ≠ E[S_0] = 0
# 可选停止失效的原因：T 无界（E[T] = ∞），条件 (A)/(B) 同时失守
println("   E[S_T] = 3（精确，S_T 恒为 3），而 E[S_0] = 0——差值 3 正是")
println("   \"等待成本\"：T 的期望无穷，有限截断 T∧n 的均值只能缓慢爬向 3")
for n in [50, 400]
    rng4 = MersenneTwister(4804)
    acc = 0
    for _ in 1:2000
        s = 0
        for _ in 1:n
            s += rand(rng4) < 0.5 ? 1 : -1
            s == 3 && break
        end
        acc += s
    end
    println("   E[S_{{T∧", n, "}}] ≈ ", round(acc / 2000, digits=3),
            n == 50 ? "（截断短，均值未爬满）" : "（爬升缓慢——E[T] = ∞ 的代价）")
end
println("END ====")
