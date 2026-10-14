# 第 47 章 布尔代数：Div(30) 实验室 + Lindenbaum B₂

println("==== 47")

# ---------- Div(30)：30 的因子格 ----------
D = [1, 2, 3, 5, 6, 10, 15, 30]
meet(a, b) = gcd(a, b)
join(a, b) = lcm(a, b)
bnot(a) = 30 ÷ a
bot, top = 1, 30

println("Div(30) = ", D, "（gcd/lcm/30÷n 运算）")

# 十条公理全扫（封装成函数避免顶层 for 的软作用域歧义）
function check_axioms(D)
    n_ok = 0
    for a in D, b in D, c in D
        @assert meet(a, meet(b, c)) == meet(meet(a, b), c)
        @assert join(a, join(b, c)) == join(join(a, b), c)
        @assert meet(a, join(b, c)) == join(meet(a, b), meet(a, c))
        @assert join(a, meet(b, c)) == meet(join(a, b), join(a, c))
        n_ok += 4
    end
    for a in D, b in D
        @assert meet(a, b) == meet(b, a)
        @assert join(a, b) == join(b, a)
        @assert meet(a, top) == a && join(a, bot) == a
        @assert meet(a, bnot(a)) == bot && join(a, bnot(a)) == top
        n_ok += 4
    end
    return n_ok
end
n_total = check_axioms(D)
println("十条公理全扫通过（$(n_total) 条断言）——Div(30) 是布尔代数 ✓")

# 原子：极小非底元
atoms = [a for a in D if a != 1 && all(gcd(a, b) in (1, a) for b in D)]
println("原子 = ", atoms, "（素因子集）")
@assert atoms == [2, 3, 5]

# 同构 F(n) = 素因子集：F : Div(30) ≅ 𝒫({2,3,5})（Prop 3.5.3）
primes = [2, 3, 5]
F(n) = Set(p for p in primes if n % p == 0)
function check_iso(D)
    for a in D, b in D
        @assert F(meet(a, b)) == intersect(F(a), F(b))
        @assert F(join(a, b)) == union(F(a), F(b))
        @assert F(bnot(a)) == setdiff(Set(primes), F(a))
    end
    return length(D)^2
end
n_iso = check_iso(D)
println("F(n) = 素因子集实现 Div(30) ≅ P({2,3,5})（$(n_iso) 组合）✓")

# ---------- 对照组：Div(18) 不是布尔代数 ----------
# 数学事实：因子格 Div(n) 恒为分配格（链之积），
# 布尔性崩在【补律】：n 有平方因子时 3 这类元素无补元。
N18 = 18
D18 = filter(k -> N18 % k == 0, 1:N18)   # {1,2,3,6,9,18}
meet18(a, b) = gcd(a, b)
join18(a, b) = lcm(a, b)
# 分配律在 Div(18) 上仍成立（全扫确认）
function check_distr18()
    for a in D18, b in D18, c in D18
        @assert meet18(a, join18(b, c)) == join18(meet18(a, b), meet18(a, c))
    end
    return length(D18)^3
end
n_d18 = check_distr18()
println("Div(18) 分配律全扫通过（$(n_d18) 组合）——因子格恒分配 ✓")
# 补律崩坏现场：3 的补不存在
function has_compl(a)
    for x in D18
        if meet18(a, x) == 1 && join18(a, x) == N18
            return true
        end
    end
    return false
end
@assert !has_compl(3)
println("Div(18) 补律崩坏：3 无补元（gcd(3,x)=1 与 lcm(3,x)=18 无公共解）")
println("规律：Div(n) 是布尔代数 ⟺ n 无平方因子——分配恒真，补在平方因子处崩")

# ---------- Lindenbaum B₂：16 元，4 原子 ----------
formulas = vec(collect(Iterators.product((0, 1), (0, 1), (0, 1), (0, 1))))
bmeets(u, v) = min.(u, v)
bjoins(u, v) = max.(u, v)
bnots(u) = 1 .- u
println("B₂ 元素数 = ", length(formulas), " = 2^(2²) ✓")
atomsB = [f for f in formulas if sum(f) == 1]
println("B₂ 原子数 = ", length(atomsB), " = 2² ✓（恰在一行取 1 的真值表）")

function check_dm(formulas)
    n = 0
    for u in formulas, v in formulas
        @assert bnots(bjoins(u, v)) == bmeets(bnots(u), bnots(v))
        n += 1
    end
    return n
end
n_dm = check_dm(formulas)
println("B₂ De Morgan 全扫通过（$(n_dm) 组合）✓")

println("END ====")
