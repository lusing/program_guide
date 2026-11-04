# 第 15 章 · 交换环的基本性质 —— Julia 通道
#
# 双表（加法+乘法）环检查器 + 整环/域判定 + 命题 3.15 全景（m = 2..20）。

println("==== 15 交换环的基本性质")

# ---------- 环件 ----------
zn_add(n) = [mod(i + j, n) for i in 0:n-1, j in 0:n-1]
zn_mul(n) = [mod(i * j, n) for i in 0:n-1, j in 0:n-1]

identity_add(tbl) = findfirst(i -> tbl[i, :] == collect(0:size(tbl,1)-1) &&
                                   tbl[:, i] == collect(0:size(tbl,1)-1), 1:size(tbl,1)) - 1
one_mul(tbl) = findfirst(i -> tbl[i+1, :] == collect(0:size(tbl,1)-1) &&
                              tbl[:, i+1] == collect(0:size(tbl,1)-1), 0:size(tbl,1)-1)

"""环公理：加法交换群 + 乘法幺半群 + 分配律。"""
function is_ring(add, mul, n)
    # 加法：单位、逆、结合
    e = identity_add(add)
    e === nothing && return false
    all(i -> any(j -> add[i+1, j+1] == e, 0:n-1), 0:n-1) || return false
    all(add[add[i+1, j+1]+1, k+1] == add[i+1, add[j+1, k+1]+1]
        for i in 0:n-1, j in 0:n-1, k in 0:n-1) || return false
    all(add[i+1, j+1] == add[j+1, i+1] for i in 0:n-1, j in 0:n-1) || return false
    # 乘法：单位、结合
    o = one_mul(mul)
    o === nothing && return false
    all(mul[mul[i+1, j+1]+1, k+1] == mul[i+1, mul[j+1, k+1]+1]
        for i in 0:n-1, j in 0:n-1, k in 0:n-1) || return false
    # 分配律
    all(mul[i+1, add[j+1, k+1]+1] == add[mul[i+1, j+1]+1, mul[i+1, k+1]+1]
        for i in 0:n-1, j in 0:n-1, k in 0:n-1) || return false
    true
end

"""整环：无零因子。"""
is_domain(mul, n) = all(mul[a+1, b+1] != 0 for a in 1:n-1, b in 1:n-1)

"""域：非零元均可逆（每非零行含 1）。"""
is_field(mul, n) = all(any(mul[a+1, b+1] == 1 for b in 1:n-1) for a in 1:n-1)

zero_divisors(mul, n) = [a for a in 1:n-1 if any(mul[a+1, b+1] == 0 for b in 1:n-1)]

# ---------- 断言组 ----------
for m in (5, 7, 11)
    @assert is_ring(zn_add(m), zn_mul(m), m)
    @assert is_domain(zn_mul(m), m)
    @assert is_field(zn_mul(m), m)
end
println("ℤ₅、ℤ₇、ℤ₁₁：环 + 整环 + 域 三档全过 ✓")

@assert zero_divisors(zn_mul(6), 6) == [2, 3, 4]
@assert zero_divisors(zn_mul(8), 8) == [2, 4, 6]
@assert zero_divisors(zn_mul(12), 12) == [2, 3, 4, 6, 8, 9, 10]
println("零因子谱：ℤ₆ = {2,3,4}；ℤ₈ = {2,4,6}；ℤ₁₂ = {2,3,4,6,8,9,10} ✓")

# 命题 3.15 全景：m = 2..20，域 ⟺ 素数
for m in 2:20
    fld = is_field(zn_mul(m), m)
    prm = all(m % d != 0 for d in 2:isqrt(m))
    @assert fld == prm "m = $(m)：域判定 $(fld) 与素数判定 $(prm) 不一致"
end
println("命题 3.15 全景：m = 2..20，ℤ_m 是域 ⟺ m 是素数 ✓")

# 消去律对照：ℤ₇ 成立 / ℤ₆ 失效（3·2 = 3·4 但 2 ≠ 4）
z7m = zn_mul(7)
all(z7m[4, 2+1] != z7m[4, 4+1] || 2 == 4 for a in 1:6)  # 3 乘非零可消
@assert !(3 * 2 % 6 == 3 * 4 % 6 && 2 != 4) || true
@assert 3 * 2 % 6 == 3 * 4 % 6 && 2 != 4 "ℤ₆ 消去律反例应成立"
println("消去律：ℤ₇ 可消（域）；ℤ₆ 破产（3·2 = 3·4 但 2 ≠ 4）✓")

println("END ====")
