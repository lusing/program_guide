# 第 11 章 · 群同态 —— Julia 通道
#
# det/sgn/模映射三例 + |G| = |ker|·|im| + 共轭自同构 + 同态枚举。

println("==== 11 群同态")

# ---------- sgn : S₄ → {±1}（定理 2.39 即同态性） ----------
function all_perms(n::Int)
    out = Vector{Int}[]; p = collect(1:n)
    while true
        push!(out, copy(p))
        k = 0
        for i in n-1:-1:1
            if p[i] < p[i+1]; k = i; break; end
        end
        k == 0 && break
        l = 0
        for j in n:-1:1
            if p[k] < p[j]; l = j; break; end
        end
        p[k], p[l] = p[l], p[k]
        reverse!(p, k + 1)
    end
    out
end
compose(α, β) = [α[β[i]] for i in eachindex(β)]
signum(α) = (count(i < j && α[i] > α[j] for i in eachindex(α), j in eachindex(α)) % 2 == 0) ? 1 : -1

S4 = all_perms(4)
for α in S4, β in S4
    @assert signum(compose(α, β)) == signum(α) * signum(β)
end
kerA4 = count(α -> signum(α) == 1, S4)
@assert kerA4 == 12 "核 = A₄（12 元），|S₄| = 12 × 2 = |ker|·|im|"
println("sgn : S₄ → {±1}：576 对同态性；|ker| = 12，|G| = |ker|·|im| ✓")

# ---------- det : GL(2, ℤ₅) → (ℤ₅)*, 随机抽样 ----------
function gl2_zp(p)
    mats = Vector{Matrix{Int}}()
    for a in 0:p-1, b in 0:p-1, c in 0:p-1, d in 0:p-1
        if mod(a * d - b * c, p) != 0
            push!(mats, [a b; c d])
        end
    end
    mats
end
GL = gl2_zp(5)
@assert length(GL) == (25 - 1) * (25 - 5) == 480
det5(M) = mod(M[1,1] * M[2,2] - M[1,2] * M[2,1], 5)
mul5(A, B) = mod.(A * B, 5)
# 随机 200 对同态性（确定性伪随机：固定步长抽样）
for k in 1:200
    A = GL[mod1(97 * k, length(GL))]; B = GL[mod1(89 * k + 3, length(GL))]
    @assert det5(mul5(A, B)) == mod(det5(A) * det5(B), 5)
end
kerSL = count(M -> det5(M) == 1, GL)
@assert kerSL == 480 ÷ 4 "|SL(2,ℤ₅)| = 120"
println("det : GL(2,ℤ₅) → ℤ₅*：480 元群，200 对抽样同态性；核 = SL₂ 恰 120 = 480/4 ✓")

# ---------- f : ℤ₆ → ℤ₃，k ↦ k mod 3 ----------
f63(k) = mod(k, 3)
for a in 0:5, b in 0:5
    @assert f63(mod(a + b, 6)) == mod(f63(a) + f63(b), 3)
end
ker_size = count(k -> f63(k) == 0, 0:5)
im_size = length(unique(f63.(0:5)))
@assert ker_size == 2 && im_size == 3 && 6 == ker_size * im_size
println("f : ℤ₆ → ℤ₃（k ↦ k mod 3）：核 {[0],[3]}（2 元），像 = ℤ₃，6 = 2×3 ✓")

# ---------- 非同态反例：f(x) = 2x mod 4? 取 ℤ₄ → ℤ₄ 的平方映射类比 ----------
bad(x) = mod(2x, 4)   # 群同态？检验加法保持
is_hom_bad = all(a -> all(b -> bad(mod(a + b, 4)) == mod(bad(a) + bad(b), 4), 0:3), 0:3)
@assert is_hom_bad   # 2x 其实是同态（倍乘映射总是同态）
# 真反例：ℤ₄ → ℤ₄ 的"平方"（乘法意义）在加法群上不是同态
sq(x) = mod(x * x, 4)
is_hom_sq = all(a -> all(b -> sq(mod(a + b, 4)) == mod(sq(a) + sq(b), 4), 0:3), 0:3)
@assert !is_hom_sq "平方映射不是加法同态（a=b=1：sq(2) = 0 ≠ sq(1)+sq(1) = 2）"
println("反例：ℤ₄ 的平方映射不保持加法（1+1 处失败）✓；倍乘 2x 是同态 ✓")

# ---------- 命题 2.92：共轭是自同构（D₄ 上全量） ----------
function dihedral(n)
    tbl = zeros(Int, 2n, 2n)
    for i in 0:n-1, j in 0:1, k in 0:n-1, l in 0:1
        r, s = j == 0 ? (mod(i + k, n), l) : (mod(i - k, n), 1 - l)
        tbl[(j == 0 ? i + 1 : n + i + 1), (l == 0 ? k + 1 : n + k + 1)] =
            s == 0 ? r + 1 : n + r + 1
    end
    tbl
end
d4 = dihedral(4)
for g in 1:8
    # 表置换 φ_g : x ↦ 表中 g 行 g⁻¹ 列交点 = gxg⁻¹
    ginv = findfirst(y -> d4[g, y] == 1, 1:8)
    φ = [d4[g, d4[ginv, x]] for x in 1:8]
    @assert sort(φ) == collect(1:8)                       # 双射
    for x in 1:8, y in 1:8                                # 保持运算
        @assert φ[d4[x, y]] == d4[φ[x], φ[y]]
    end
end
println("命题 2.92：D₄ 的 8 个共轭映射全部是表自同构 ✓")

# ---------- 同态枚举：S₃ → ℤ₂ 恰 2 个 ----------
# S₃ = ⟨α=(123), b=(12) | α³=b²=1, (αb)²=1⟩；候选映射在生成元上取值后全检
function count_homs_s3_to_z2()
    s3_img = [[1,2,3],[2,3,1],[3,1,2],[2,1,3],[3,2,1],[1,3,2]]
    s3_tbl = [findfirst(p -> p == [s3_img[a][s3_img[b][j]] for j in 1:3], s3_img)
              for a in 1:6, b in 1:6]
    cnt = 0
    for fa in 0:1, fb in 0:1          # α ↦ fa，b ↦ fb（ℤ₂ 加法）
        val(i) = begin
            ii = i <= 3 ? i - 1 : i - 4      # 正规形 α^i b^j
            jj = i <= 3 ? 0 : 1
            mod(ii * fa + jj * fb, 2)
        end
        if all(val(s3_tbl[x, y]) == mod(val(x) + val(y), 2) for x in 1:6, y in 1:6)
            cnt += 1
        end
    end
    cnt
end
@assert count_homs_s3_to_z2() == 2 "S₃ → ℤ₂ 同态恰 2 个（平凡 + sgn）"
println("同态枚举：S₃ → ℤ₂ 恰 2 个（平凡与 sgn）✓")

println("END ====")
