# 第 09 章 · 群的定义与例子 —— Julia 通道
#
# 凯莱表 + 群公理自动检查器 + ℤ_n/U(m)/D_n 三族构造 + D₃ ≅ S₃ 表比对。

println("==== 09 群的定义与例子")

# ---------- 群公理检查器 ----------
"""凯莱表 tbl（元素编号 1..n）是否定义群：封闭、单位元、逆元、结合律。"""
function is_group(tbl::Matrix{Int})
    n = size(tbl, 1)
    all(x -> 1 <= x <= n, tbl) || return false
    e = findfirst(i -> tbl[i, :] == collect(1:n) && tbl[:, i] == collect(1:n), 1:n)
    isnothing(e) && return false
    all(i -> any(j -> tbl[i, j] == e, 1:n), 1:n) || return false   # 逆元
    all(tbl[tbl[i, j], k] == tbl[i, tbl[j, k]]
        for i in 1:n, j in 1:n, k in 1:n)                          # 结合律
end

identity_of(tbl) = findfirst(i -> tbl[i, :] == collect(1:size(tbl, 1)) &&
                                   tbl[:, i] == collect(1:size(tbl, 1)), 1:size(tbl, 1))

"""元素阶：沿幂轨道走回单位元。"""
function order_of(tbl, x)
    e = identity_of(tbl)
    k, cur = 1, x
    while cur != e
        cur = tbl[x, cur]
        k += 1
    end
    k
end

"""x 的 k 次幂（k 可为负）。"""
function itpow(tbl, x, k)
    e = identity_of(tbl)
    if k < 0; x = inv_of(tbl, x); k = -k; end
    r = e
    for _ in 1:k; r = tbl[x, r]; end
    r
end

function inv_of(tbl, x)
    e = identity_of(tbl)
    findfirst(j -> tbl[x, j] == e, 1:size(tbl, 1))
end

# ---------- 三族构造器 ----------
"""循环群 ℤ_n（加法）。"""
zn_add(n) = [mod(i + j, n) + 1 for i in 0:n-1, j in 0:n-1]

"""单位群 U(m)：与 m 互素的剩余类乘法表。"""
function un_mul(m)
    U = [k for k in 1:m if gcd(k, m) == 1]
    idx = Dict(v => i for (i, v) in enumerate(U))
    [idx[mod(U[i] * U[j], m)] for i in eachindex(U), j in eachindex(U)]
end

"""二面体群 D_n：元素 α^i b^j，关系 αⁿ = b² = 1, bab = α⁻¹（定理 2.63）。"""
function dihedral(n)
    tbl = zeros(Int, 2n, 2n)
    for i in 0:n-1, j in 0:1, k in 0:n-1, l in 0:1
        if j == 0
            r, s = mod(i + k, n), l
        else
            r, s = mod(i - k, n), 1 - l
        end
        id = s == 0 ? r + 1 : n + r + 1
        tbl[(j == 0 ? i + 1 : n + i + 1), (l == 0 ? k + 1 : n + k + 1)] = id
    end
    tbl
end

# ---------- 断言组 ----------
for tbl in (zn_add(5), zn_add(12), un_mul(8), un_mul(10), dihedral(3), dihedral(4))
    @assert is_group(tbl)
end
println("群公理检查器：ℤ₅、ℤ₁₂、U(8)、U(10)、D₃、D₄ 全过（含 O(n³) 结合律）✓")

# ---------- D₃ ≅ S₃：D₃ 表 = 标准置换实现的复合表 ----------
# D₃ 元素 [1, α, α², b, αb, α²b] 的置换像（α=(123)，b=(12)）：
img = [[1,2,3],      # 1
       [2,3,1],      # α = (123)
       [3,1,2],      # α² = (132)
       [2,1,3],      # b = (12)
       [3,2,1],      # αb
       [1,3,2]]      # α²b
d3 = dihedral(3)
for i in 1:6, j in 1:6
    prod = [img[i][img[j][k]] for k in 1:3]
    @assert img[d3[i, j]] == prod
end
@assert is_group(d3)
println("D₃ 的表 = S₃ 的置换复合表（同构的有限群版；定理 2.63 n = 3）✓")

# ---------- 元素阶 ----------
orders_u8 = sort([order_of(un_mul(8), i) for i in 1:4])
@assert orders_u8 == [1, 2, 2, 2] "U(8) 是 Klein 四元群"
@assert maximum(order_of(un_mul(10), i) for i in 1:4) == 4 "U(10) ≅ ℤ₄"
# 元素 i 编号对应剩余类 i−1；阶 = 12/gcd(k, 12)
@assert [order_of(zn_add(12), i) for i in 1:12] ==
        [1, 12, 6, 4, 3, 12, 2, 12, 3, 4, 6, 12]
println("元素阶：U(8) 全 2 阶（V）；U(10) 有 4 阶元（≅ ℤ₄）；ℤ₁₂ 阶表 = 12/gcd ✓")

# ---------- 定理 2.63 的关系在表上 ----------
for n in 3:6
    tbl = dihedral(n)
    e = identity_of(tbl)
    α, b = 2, n + 1                       # 旋转一次、反射
    @assert itpow(tbl, α, n) == e          # αⁿ = 1
    @assert tbl[b, b] == e                 # b² = 1
    @assert tbl[tbl[b, α], b] == itpow(tbl, α, n - 1)   # bab = α⁻¹
end
println("定理 2.63 关系 αⁿ = b² = 1，bab = α⁻¹ 在 D₃..D₆ 表上成立 ✓")

# ---------- 非阿贝尔现场 ----------
a, b = 2, 4
@assert itpow(d3, d3[a, b], 2) != d3[itpow(d3, a, 2), itpow(d3, b, 2)]
println("非阿贝尔现场：D₃ 中 (αb)² ≠ α²b²（命题 2.51 的反例侧）✓")

println("END ====")
