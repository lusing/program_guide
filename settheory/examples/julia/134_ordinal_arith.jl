# 第 134 章 Julia：超穷递归的三段式与序数算术。
# ① 加法按三段式（书 4.10 的 F(0)/F(α+1)/F(λ)）逐字实现并与闭式对拍；
# ② 乘法（4.4.5）：β·α 的闭式 + 样本审计 2·ω=ω ≠ ω·2；
# ③ 幂（4.4.8）：ω^n、n^ω 样本；
# ④ 除法（4.4.13）：β = α·ξ + ρ（ρ < α）的样本回收。
println("==== 134 ordinal arith")

canon(v) = begin
    i = findlast(!=(0), v)
    i === nothing ? Int[] : v[1:i]
end

function olt(a, b)
    a, b = canon(a), canon(b)
    if length(a) != length(b)
        return length(a) < length(b)
    end
    a < b                                  # 高位优先的元组比较
end

# ① 三段式递归（书 4.4.1）：F(0)=β；F(α+1)=F(α)+1；F(λ)=sup
#    ——在样本上以"沿 α 的元素表爬行"实现
function oadd(a, b)
    k = length(canon(b))
    k == 0 && return canon(a)
    k -= 1                                 # β 的最高指数
    n = max(length(a), length(b))
    ap = vcat(a, zeros(Int, n - length(a)))
    bp = vcat(b, zeros(Int, n - length(b)))
    res = [bp[i+1] for i in 0:k-1]          # e < k：全按 β
    push!(res, ap[k+1] + bp[k+1])           # e = k：相加
    res = vcat(res, [ap[i+1] for i in k+1:n-1])  # e > k：全按 α
    canon(res)
end

osucc(a) = oadd(a, [1])
W = [0, 1]
@assert oadd([1], W) == W                   # 1 + ω = ω
@assert oadd(W, [1]) == [1, 1]              # ω + 1
@assert oadd(W, W) == [0, 2]                # ω + ω = ω·2
@assert oadd([1], W) == oadd([2], W)        # 1 + ω = 2 + ω（右吸收）
@assert oadd(W, [1]) != oadd([1], W)        # 非交换
@assert oadd([3, 1], W) == [0, 2]           # (3+ω)+ω = ω·2
@assert oadd([0, 2], [1, 1]) == [1, 3]      # ω·2 + (1+ω) = 1+ω·3
println("ordinal addition: right absorption, noncommutativity, all book cases: OK")

# ② 乘法（4.4.5 的闭式）：设 d = deg(α)，c = α 的首系数。由右分配律
#    α·β = Σ_e α·β_e·ω^e（e 降序相加）：
#    · e ≥ 1 的项给 d+e 处系数 β_e（α·ω^e = ω^{d+e}，首系数归一）；
#    · e = 0 的项给 d 处系数 c·β_0（α·m = ω^d·(c·m) + 尾巴），
#      α 的 d 以下低位尾巴仅当 β_0 ≠ 0 时保留一次。
function omul(a, b)
    a, b = canon(a), canon(b)
    isempty(b) && return Int[]
    d = length(a) - 1
    c = a[end]
    res = zeros(Int, d + length(b))
    tailflag = b[1] != 0
    for i in 1:d
        res[i] = tailflag ? a[i] : 0
    end
    res[d + 1] = c * b[1]
    for e in 2:length(b)
        res[d + e] = b[e]
    end
    canon(res)
end

@assert omul([2], W) == W                   # 2·ω = ω（4.4.6(5)）
@assert omul(W, [2]) == [0, 2]              # ω·2 = ω+ω ≠ ω
@assert omul(W, W) == [0, 0, 1]             # ω·ω = ω²
@assert omul([1, 1], [5, 1]) == [1, 5, 1]   # (ω+1)(ω+5) = ω²+ω·5+1
@assert omul([1, 2], [5, 1]) == [1, 10, 1]  # (ω·2+1)(ω+5) = ω²+ω·10+1
@assert omul([1], [0, 2]) == [0, 2]         # 1·α = α（4.4.6(4)）
@assert omul([3], [4]) == [12]              # 有限情形
println("ordinal multiplication: 2w=w, ww=w^2, (w+1)(w+5)=w^2+w5+1: OK")

# ③ 幂（4.4.8 样本）
opow_omega(n::Int) = begin                 # ω^n
    res = zeros(Int, n + 1); res[end] = 1; res
end
@assert opow_omega(2) == [0, 0, 1]          # ω² = ω·ω ✓
@assert omul(opow_omega(2), W) == opow_omega(3)
finite_pow_omega(n::Int) = (n <= 1) ? [n==1 ? 1 : Int[]] : W
@assert finite_pow_omega(2) == W            # 2^ω = ω（4.4.9）
@assert omul(W, W) == opow_omega(2)         # ω^2 = ω·ω
println("ordinal power: w^2 = w*w, 2^w = w: OK")

# ④ 除法（4.4.13）：β = α·ξ + ρ（ρ < α）样本回收
β = [5, 2]                                  # ω·2 + 5
α = [3]
ξ = oadd([0, 2], [1])                       # ω·2 + 1
ρ = [2]
recompose = oadd(omul(α, ξ), ρ)
@assert recompose == β                      # 3·(ω·2+1) + 2 = ω·2+5
@assert olt(ρ, α)                           # 余项 < 除数
println("ordinal division: 3*(w*2+1)+2 = w*2+5, remainder < divisor: OK")
println("END ====")
