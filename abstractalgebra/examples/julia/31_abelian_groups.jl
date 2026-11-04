# 第 31 章 · 有限阿贝尔群 —— Julia 通道
#
# 结构定理机器面：初等因子分解枚举 + 阶档案（order profile）
# 是完全不变量（非同构判据）+ CRT 重合 + 循环判据。

println("==== 31 有限阿贝尔群")

# ---------- 阶档案：元素阶的多重集 ----------
"""ℤ/m 中 a 的阶 = m ÷ gcd(a, m)（a=0 时 gcd=m 得 1）。"""
elem_order(a, m) = m ÷ gcd(a, m)

"""ℤ/m₁ × ⋯ × ℤ/m_k 的全部元素阶（各分量阶的 lcm），升序。"""
function order_profile(ms)
    sort(vec([reduce(lcm, [elem_order(a, m) for (a, m) in zip(T, ms)])
              for T in Iterators.product([0:m-1 for m in ms]...)]))
end

# 8 阶三群的阶档案两两不同 ⟹ 非同构
p222 = order_profile([2, 2, 2])
@assert p222 == [1, 2, 2, 2, 2, 2, 2, 2]
p8 = order_profile([8])
@assert p8 == [1, 2, 4, 4, 8, 8, 8, 8]
p42 = order_profile([4, 2])
@assert p42 == [1, 2, 2, 2, 4, 4, 4, 4]
@assert p222 != p8 && p222 != p42 && p8 != p42
println("8 阶阿贝尔群：ℤ/8、ℤ/4×ℤ/2、ℤ/2×ℤ/2×ℤ/2 阶档案两两不同 ✓")

# ---------- 分类枚举：n = ∏p^e → 每个素数的分拆组合 ----------
"""n 的全部整数分拆（降序）。"""
function partitions(n)
    out = Vector{Int}[]
    gen(rem, maxpart, acc) = begin
        if rem == 0
            push!(out, sort(acc, rev=true)); return
        end
        for k in min(rem, maxpart):-1:1
            push!(acc, k); gen(rem - k, k, acc); pop!(acc)
        end
    end
    gen(n, n, Int[])
    out
end

"""n 的素分解（有序对表）。"""
function factorize(n)
    pf = Vector{Pair{Int,Int}}()
    m, p = n, 2
    while m > 1
        e = 0
        while m % p == 0
            m ÷= p; e += 1
        end
        e > 0 && push!(pf, Pair(p, e))
        p += 1
    end
    pf
end

"""n 阶阿贝尔群的全部初等因子形（定理 6.11 基定理的枚举面）。"""
function abelian_forms(n)
    acc = [Vector{Pair{Int,Int}}[]]           # 已确定素数的 (p, λ) 表
    for (pp, e) in factorize(n)
        tmp = Vector{Vector{Pair{Int,Int}}}()
        for part in partitions(e), prev in acc
            push!(tmp, vcat(prev, [Pair(pp, λ) for λ in part]))
        end
        acc = tmp
    end
    sort([sort([pp^λ for (pp, λ) in terms]) for terms in acc])
end

# 72 = 2³·3²：分拆数 p(3)·p(2) = 3·2 = 6 个群
forms72 = abelian_forms(72)
@assert length(forms72) == 6
@assert [8, 9] in forms72                     # ℤ/8×ℤ/9 ≅ ℤ/72（不变因子形）
@assert [2, 2, 2, 3, 3] in forms72
# 阶档案两两不同（推论 6.14 的数值面：U_p(n,G) 决定群）
profiles = [order_profile(f) for f in forms72]
for i in 1:6, j in i+1:6
    @assert profiles[i] != profiles[j]
end
println("72 阶阿贝尔群：恰 6 种（p(3)·p(2) = 6），阶档案两两不同 ✓")

# 计数公式：n 阶阿贝尔群个数 = ∏ p(ν_p(n))
for (n, cnt) in [(8, 3), (12, 2), (16, 5), (36, 4), (72, 6), (360, 6)]
    @assert length(abelian_forms(n)) == cnt
end
println("计数公式：8→3、12→2、16→5、36→4、72→6、360→6 ✓")

# ---------- CRT：gcd(m,n)=1 ⟹ ℤ/mn ≅ ℤ/m × ℤ/n ----------
for x in 0:5
    a, b = x % 2, x % 3
    sols = [y for y in 0:5 if y % 2 == a && y % 3 == b]
    @assert length(sols) == 1 && sols[1] == x
end
for x in 0:5, y in 0:5
    @assert ((x + y) % 2, (x + y) % 3) ==
            ((x % 2 + y % 2) % 2, (x % 3 + y % 3) % 3)
end
println("CRT：ℤ/6 ≅ ℤ/2 × ℤ/3（双射 + 保加法逐点核对）✓")

# ---------- 循环判据：两两互素 ⟺ 指数 = 阶 ----------
function is_cyclic_form(ms)
    all(gcd(ms[i], ms[j]) == 1
        for i in 1:length(ms) for j in i+1:length(ms))
end
for ms in ([6], [2, 3], [4, 9], [2, 2], [4, 6], [2, 3, 5], [4, 3])
    prof = order_profile(ms)
    @assert (maximum(prof) == prod(ms)) == is_cyclic_form(ms)
end
println("循环判据：直积循环 ⟺ 两两互素 ⟺ 指数 = 阶 ✓")

println("END ====")
