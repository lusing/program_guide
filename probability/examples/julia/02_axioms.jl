# -*- coding: utf-8 -*-
println("==== 02 axioms")
# 第 02 章 Julia：公理定律的频率视角（骰子空间 Ω = 36 点）。
# ① 补律；② 容斥二项版；③ 单调性；④ Boole 上界——经验频率
#    对四条定律的逐条贴近（大数定律的预告，18 章正式证明）。
using Random, Statistics

Random.seed!(2)

# 骰子样本空间上的事件 = 36 个 (i,j) 的子集；模拟 N 次掷双骰
N = 200_000
samples = [(rand(1:6), rand(1:6)) for _ in 1:N]

freq(A) = count(A, samples) / N

A_first6(s) = s[1] == 6            # 首骰 6
B_second6(s) = s[2] == 6           # 次骰 6

# ① 补律：freq(A) + freq(A^c) ≈ 1
fa = freq(A_first6)
fna = freq(s -> !(s[1] == 6))
@assert abs(fa + fna - 1.0) < 0.001
println("complement law: freq(A) + freq(Ac) = ", round(fa + fna, digits=5), ": OK")

# ② 容斥：freq(A∪B) = freq(A) + freq(B) − freq(A∩B)
fA, fB = freq(A_first6), freq(B_second6)
fAiB = freq(s -> s[1] == 6 && s[2] == 6)
fAuB = freq(s -> s[1] == 6 || s[2] == 6)
@assert abs(fAuB - (fA + fB - fAiB)) < 0.001
println("inclusion-exclusion: freq(AuB) = ", round(fAuB, digits=4),
        " vs ", round(fA + fB - fAiB, digits=4), ": OK")

# ③ 单调性：A ⊂ B ⟹ freq(A) ≤ freq(B)（B = "至少一个 6"）
fB2 = fAuB
@assert fa <= fB2 + 0.001 && fB <= fB2 + 0.001
println("monotonicity: freq(first-6) = ", round(fa, digits=4),
        " <= freq(any-6) = ", round(fB2, digits=4), ": OK")

# ④ Boole 上界：freq(∪) ≤ Σ freq（三事件：首 6 / 次 6 / 和 ≥ 10）
C_sum10(s) = s[1] + s[2] >= 10
fC = freq(C_sum10)
f_union3 = freq(s -> A_first6(s) || B_second6(s) || C_sum10(s))
@assert f_union3 <= fa + fB + fC + 1e-9      # 上界无重叠信息也成立
gap = (fa + fB + fC) - f_union3
@assert gap > 0.05                           # 保守度可观（重叠被重复计）
println("Boole bound: freq(u3) = ", round(f_union3, digits=4),
        " <= sum = ", round(fa + fB + fC, digits=4),
        " (slack ", round(gap, digits=4), "): OK")

println("END ====")
