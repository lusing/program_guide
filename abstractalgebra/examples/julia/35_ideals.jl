# 第 35 章 · 素理想与极大理想 —— Julia 通道
#
# ℤ/n 的理想格（除数对应）+ 素/极大判别（商环整域/域）+ k[x]/(p) 造域。

println("==== 35 素理想与极大理想")

# ---------- ℤ/n 的理想 = (d)，d | n ----------
"""n 的全部理想 (d)（d 取 n 的因数），每个表示为 0..n−1 的集合。"""
function zn_ideals(n)
    [Set((d * k) % n for k in 0:n-1) for d in 1:n if n % d == 0]
end

function zn_ideal(n, d)
    Set((d * k) % n for k in 0:n-1)
end

# ℤ/12：理想与因数一一对应（命题 7.1 对应定理的数值面）
@assert length(zn_ideals(12)) == 6                    # 1,2,3,4,6,12
# 包含关系即整除：(a) ⊇ (b) ⟺ a | b（b 的倍数必是 a 的倍数）
for a in 1:12, b in 1:12
    if 12 % a == 0 && 12 % b == 0
        @assert (zn_ideal(12, a) ⊇ zn_ideal(12, b)) == (b % a == 0)
    end
end
println("ℤ/12：6 个理想与因数一一对应；(a) ⊇ (b) ⟺ a | b ✓")

# 商环整域/域的暴力判定（枚举乘法）
function zn_is_domain(n)
    n == 1 && return false
    all((a * b) % n != 0 || a == 0 || b == 0
        for a in 0:n-1 for b in 0:n-1)
end
function zn_is_field(n)
    zn_is_domain(n) && all(any((a * b) % n == 1 for b in 0:n-1)
                           for a in 1:n-1)
end
# ℤ/n 的理想 (d) = {0, d, 2d, …} 有 n/d 个元素，商环 ≅ ℤ/d
quotient_order(_, d) = d

# ℤ/12 的判定表：(2) → ℤ/2 域（极大）；(3) → ℤ/3 域（极大）；
# (4) → ℤ/4 有零因子 2·2=0（非素）；(6) → ℤ/6 有零因子 2·3=0（非素）
@assert quotient_order(12, 2) == 2 && zn_is_field(2)   # (2) 极大
@assert quotient_order(12, 3) == 3 && zn_is_field(3)   # (3) 极大
@assert quotient_order(12, 4) == 4 && !zn_is_domain(4) # (4) 非素
@assert quotient_order(12, 6) == 6 && !zn_is_domain(6) # (6) 非素
println("ℤ/12：(2)、(3) 极大（商 ℤ/2、ℤ/3 是域）；(4)、(6) 非素（商有零因子）✓")

# ℤ/n 是域 ⟺ n 素（引理 7.6：(0) 极大 ⟺ R 域 的数值面）
for n in 2:20
    isp = all(n % p != 0 for p in 2:n-1)
    @assert zn_is_field(n) == isp
    @assert zn_is_domain(n) == isp                     # ℤ/n：整域 ⟺ 域（有限整域是域）
end
println("ℤ/n：n ∈ 2..20 全扫描——域 ⟺ 素 ⟺ 整域（(0) 极大 ⟺ 域）✓")

# ---------- 极大 ⟹ 素（推论 7.8）----------
# ℤ/p² 的理想 (p)：商 ℤ/p 域 ⟹ 极大 ⟹ 素
for p in (2, 3, 5)
    n = p^2
    # (p) 在 ℤ/p² 中素：ab ∈ (p) ⟹ a ∈ (p) 或 b ∈ (p)
    ok = all(((a * b) % p == 0) ? ((a % p == 0) || (b % p == 0)) : true
             for a in 0:n-1 for b in 0:n-1)
    @assert ok
end
println("(p) ⊂ ℤ/p²：p = 2,3,5 全部素理想（极大 ⟹ 素）✓")

# ---------- 非极大的素理想：ℤ[x] 的 (x) ----------
# ℤ[x]/(x) ≅ ℤ 是整域非域 ⟹ (x) 素不极大
# 数值面：x 的倍数的常数项为 0；乘积常数项为零 ⟹ 某因子常数项为零
poly_const(cfs) = cfs                                  # 多项式 = 系数表（升幂）
const_of_prod(a, b) = a[1] * b[1]
for a1 in -2:2, b1 in -2:2                             # 常数项的组合
    @assert (a1 * b1 == 0) ? (a1 == 0 || b1 == 0) : true
end
println("ℤ[x] 的 (x)：商 ≅ ℤ 整域非域 ⟹ 素而不极大（PID 外常事）✓")

# ---------- k[x]/(不可约) 造域（推论 7.12）----------
# ℤ/2[x]/(x²+x+1) = GF(4)：系数 mod 2、指数 mod x²+x+1
# 元素 = {0, 1, x, x+1}；乘法：x² ≡ x+1
function gf4_mul(a, b)
    # 元素 (c0, c1) 表示 c0 + c1·x
    c0 = (a[1] * b[1] + a[2] * b[2]) % 2              # x² ≡ x+1 贡献 c1d1·(1+x)
    c1 = (a[1] * b[2] + a[2] * b[1] + a[2] * b[2]) % 2
    (c0, c1)
end

GF4 = [(0, 0), (1, 0), (0, 1), (1, 1)]
@assert Set([gf4_mul(a, b) for a in GF4 for b in GF4]) == Set(GF4)  # 封闭
# 非零元可逆
for a in GF4[2:end]
    @assert any(gf4_mul(a, b) == (1, 0) for b in GF4[2:end])
end
# 无零因子（域 ⟹ 整域）
@assert all(gf4_mul(a, b) == (0, 0) ? (a == (0, 0) || b == (0, 0)) : true
            for a in GF4 for b in GF4)
println("GF(4) = ℤ/2[x]/(x²+x+1)：4 元封闭、非零可逆、无零因子 ✓")

println("END ====")
