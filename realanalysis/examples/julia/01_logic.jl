# 第 01 章 数学语言与证明技巧：Julia 通道。
# 把量词、德摩根律、归纳法与 ε-δ 定义放到有限论域上做可计算核验。
# 运行：julia --startup-file=no 01_logic.jl

println("==== 01 logic ====")

# --- 1. 布尔真值表：德摩根律与逆否命题 ----------------------------
# 有限论域 {true,false} 上穷举，等于把真值表逐行验算一遍。
@assert all(!(a || b) == (!a && !b) for a in (true, false), b in (true, false))
@assert all(!(a && b) == (!a || !b) for a in (true, false), b in (true, false))
# 逆否命题 A→B 与 ¬B→¬A 真值表相同；A→B 用 !a || b 表示。
@assert all((!a || b) == (!(!b) || !a) for a in (true, false), b in (true, false))
println("de Morgan and contrapositive: truth table verified")

# --- 2. 量词顺序：∀x ∃y 与 ∃y ∀x 完全不同 -------------------------
# 真命题：无界整数上每个 x 都有后继 y = x+1（对应 Lean 证明的见证）。
@assert all(x -> (x + 1) > x, -1000:999)
# 假命题：有限论域 -5:4 中不存在一个压过所有元素的 y（最大值没有后继）。
small = -5:4
@assert !any(y -> all(x -> y > x, small), small)
println("quantifier order: forall-exists true, exists-forall false")

# --- 3. 归纳公式的数值核验 ----------------------------------------
# 机器不会“归纳”，但可以对前 100 个 n 逐个核验公式，给归纳证明兜底。
sum_to(n) = n * (n + 1) ÷ 2
for n in 1:100
    @assert sum(1:n) == sum_to(n)
end
println("sum formula 1..n = n(n+1)/2 checked for n = 1..100")

# --- 4. ε-δ 直接证明的数值影子：lim_{x->2} (3x+1) = 7 --------------
# 证明说取 δ = ε/3；这里对一串 ε 与扰动 x 实测不等式。
for eps in (0.1, 0.01, 0.001, 1e-6)
    delta = eps / 3
    for t in (-0.9, -0.5, 0.0, 0.3, 0.89)   # |x-2|/δ 的比例
        x = 2 + t * delta
        if abs(x - 2) < delta
            @assert abs((3x + 1) - 7) < eps
        end
    end
end
println("epsilon-delta: delta = eps/3 works for every tested eps")

# 反面对照：若故意取 δ = ε（太大），可以找到违反不等式的 x。
found_violation = false
for eps in (0.1,), x in range(2 - eps, 2 + eps; length=1001)
    if abs(x - 2) < eps && abs((3x + 1) - 7) >= eps
        global found_violation = true
        break
    end
end
@assert found_violation
println("epsilon-delta: oversized delta = eps produces a violation (sharpness)")

# --- 5. “任意接近即相等”的数值读法 ---------------------------------
# x = y 当且仅当对所有 ε>0 有 |x-y| < ε。浮点世界只能核验有限个 ε，
# 这正是严格证明不能被数值实验替代的原因。
x, y = sqrt(2), sqrt(2)
@assert all(eps -> abs(x - y) < eps, (1.0, 1e-6, 1e-12, 1e-15))
println("arbitrarily-close principle checked on finite epsilon grid")

println("END ====")
