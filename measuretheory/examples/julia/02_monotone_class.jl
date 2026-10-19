println("==== 02 monotone-class")

# 第 02 章：三类闭包的有限模型——单调闭包 / λ-闭包 / σ-闭包。
# 有限宇宙上"单调列极限"退化为恒等（有限单调列的极限是其某项），
# 这个退化本身就是教材：单调类定理需要从【代数】出发才有力，
# 而 Dynkin 的 π-λ 路线改用 λ 类（带不交并封闭），在 π-系上立刻生效。

using Random
Random.seed!(42)

const FULL = UInt8(0b1111)

inter(s, t) = s & t
un_(s, t) = s | t
comp(s) = ~s & FULL

# --- 闭包算子 1：σ-闭包（补 + 并）---
function sigma_closure(C)
    S = Set(C)
    changed = true
    while changed
        changed = false
        for u in collect(S)
            c = comp(u)
            if !(c in S); push!(S, c); changed = true; end
        end
        for u in collect(S), v in collect(S)
            w = un_(u, v)
            if !(w in S); push!(S, w); changed = true; end
        end
    end
    S
end

# --- 闭包算子 2：单调类闭包（可比对取并/交——有限单调列的影子）---
function monotone_closure(C)
    S = Set(C)
    changed = true
    while changed
        changed = false
        for u in collect(S), v in collect(S)
            if (u & v) == u || (u & v) == v   # u ⊆ v 或 v ⊆ u
                for w in (un_(u, v), inter(u, v))
                    if !(w in S); push!(S, w); changed = true; end
                end
            end
        end
    end
    S
end

# --- 闭包算子 3：λ-闭包（含 Ω、真差、不交并）---
function lambda_closure(C)
    S = Set(C)
    push!(S, FULL)
    changed = true
    while changed
        changed = false
        for u in collect(S), v in collect(S)
            if (u & v) == v                    # v ⊆ u：真差
                d = u ⊻ v
                if !(d in S); push!(S, d); changed = true; end
            end
            if (u & v) == UInt8(0)             # 不交并
                w = un_(u, v)
                if !(w in S); push!(S, w); changed = true; end
            end
        end
    end
    S
end

# ============ 实验一：单点族 + ∅ 是 π-系：λ-闭包 = σ-闭包 =16 ============
gen1 = UInt8[0b0001, 0b0010, 0b0100, 0b1000, 0b0000]
Sσ1 = sigma_closure(gen1)
Sλ1 = lambda_closure(gen1)
Sm1 = monotone_closure(gen1)
println("π-系 {∅,单点×4}：σ = $(length(Sσ1))，λ = $(length(Sλ1))，单调 = $(length(Sm1))")
@assert Sσ1 == Sλ1 == Set(0:FULL) "π-系上 λ-闭包应等于 σ-闭包（π-λ 定理读出方向）"
@assert length(Sm1) == 5 "单调闭包原地不动（有限宇宙上单调列退化——λ 类比单调类强）"

# ============ 实验二：非 π-系：λ-闭包严格小于 σ-闭包 ============
# C = {{1,2}, {2,3}}：交 {2} ∉ C
gen2 = UInt8[0b0011, 0b0110]
Sσ2 = sigma_closure(gen2)
Sλ2 = lambda_closure(gen2)
println("非 π-系 {{1,2},{2,3}}：σ = $(length(Sσ2))，λ = $(length(Sλ2))")
@assert (Sλ2 ⊆ Sσ2) && (Sλ2 != Sσ2) "非 π-系的 λ-闭包严格小于 σ-闭包——π 条件不可去"

# ============ 实验三：从代数出发——单调闭包 = σ-闭包（定理有限影子）============
# Ω = {1,2,3,4} 上由划分 {1,2}|{3,4} 生成的代数：
gen3 = UInt8[0b0000, 0b0011, 0b1100, 0b1111]
@assert length(gen3) == 4
Sσ3 = sigma_closure(gen3)
Sm3 = monotone_closure(gen3)
println("代数 {∅,{1,2},{3,4},Ω}：σ = $(length(Sσ3))，单调 = $(length(Sm3))")
@assert Sσ3 == Sm3 == Set(gen3) "代数本身就是 σ-代数（有限宇宙），单调闭包原地守恒——定理的影子平凡成立"

# ============ 实验四：π-系 + λ 的威力——随机 π-系对照 ============
# 取嵌套链（自动是 π-系）：{1} ⊂ {1,2} ⊂ {1,2,3}
gen4 = UInt8[0b0001, 0b0011, 0b0111]
Sσ4 = sigma_closure(gen4)
Sλ4 = lambda_closure(gen4)
println("嵌套链（π-系）：σ = $(length(Sσ4))，λ = $(length(Sλ4))")
@assert Sσ4 == Sλ4 "嵌套 π-系上 λ = σ（链是 π-系）"

println("END ====")
