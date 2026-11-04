# 第 34 章 · 装饰的对称 —— Julia 通道
#
# 等距的仿射表示 (A, c)（A ∈ 四个对角符号矩阵、c 半整数平移）：
# 带群关系式 + 点群同态 + 晶体学限制（整数矩阵阶枚举）。

println("==== 34 装饰的对称")

# ---------- 仿射等距的表示 ----------
# 等距 = (A, c)：z ↦ Az + c，A ∈ {I, α, β, R}（对角 ±1），c = (半整数, 0)
const I2 = [1 0; 0 1]
const ALPHA = [1 0; 0 -1]      # 水平反射（x-轴）
const BETA = [-1 0; 0 1]       # 竖直反射（y-轴）
const ROT2 = [-1 0; 0 -1]      # 半翻转 R

comp((A, c), (B, d)) = (A * B, A * d + c)          # 复合：先 B 后 A

const T = (I2, [1.0, 0.0])        # 单位平移 t
const TINV = (I2, [-1.0, 0.0])
const RHO = (ALPHA, [0.5, 0.0])   # 滑动反射 ρ
const RH = (ROT2, [0.0, 0.0])     # 半翻转 R
const AL = (ALPHA, [0.0, 0.0])    # α
const BE = (BETA, [0.0, 0.0])     # β
const ID2 = (I2, [0.0, 0.0])

iseq((A, c), (B, d)) = A == B && c ≈ d

# 关系式（定理 6.42 分类的基础代数）
@assert iseq(comp(RHO, RHO), T)                       # ρ² = t
@assert iseq(comp(RH, RH), ID2)                       # R² = 1
@assert iseq(comp(AL, AL), ID2)                       # α² = 1
@assert iseq(comp(BE, BE), ID2)                       # β² = 1
@assert iseq(comp(BE, AL), RH)                        # βα = R
@assert iseq(comp(AL, T), comp(T, AL))                # αt = tα
@assert iseq(comp(BE, T), comp(TINV, BE))             # βt = t⁻¹β
@assert iseq(comp(RH, T), comp(TINV, RH))             # Rt = t⁻¹R
println("关系式：ρ²=t、R²=α²=β²=1、βα=R、αt=tα、βt=t⁻¹β、Rt=t⁻¹R ✓")

# ---------- 带群元素（窗口枚举 |平移| ≤ 3） ----------
"""仿射等距的逆：(A, c)⁻¹ = (A⁻¹, −A⁻¹c)；对角 ±1 矩阵的逆 = 转置。"""
function inv_iso((A, c))
    Ainv = Matrix(A')
    (Ainv, Vector(-Ainv * c))
end

"""群 ⟨gens⟩ 在 |c₁| ≤ W 内的元素，正规形 (A, [k/2, 0])（含逆生成）。"""
function frieze_window(gens, W = 3)
    gensfull = vcat(gens, [inv_iso(g) for g in gens])
    S = Set{Tuple{Matrix{Int}, Vector{Float64}}}([])
    push!(S, (I2, [0.0, 0.0]))
    changed = true
    while changed
        changed = false
        for a in collect(S), g in gensfull
            p = comp(a, g)
            if abs(p[2][1]) <= W && p[2][2] == 0.0 &&
               p[1] in (I2, ALPHA, BETA, ROT2)
                if p ∉ S
                    push!(S, p)
                    changed = true
                end
            end
        end
    end
    S
end

F1 = frieze_window([T])            # F₁ = ⟨t⟩
F2 = frieze_window([T, RH])        # F₂ = ⟨t, R⟩（半翻转）
F4 = frieze_window([T, AL])        # F₄ = ⟨t, α⟩（水平反射）
F7 = frieze_window([T, RH, AL])    # F₇ = ⟨t, R, α⟩（= ⟨t, α, β⟩ 全体）
@assert length(F1) == 7
@assert length(F2) == 14
@assert length(F4) == 14
@assert length(F7) == 28
println("带群窗口：F₁=7、F₂=14、F₄=14、F₇=28（对 ⟨t⟩ 的指数 1/2/2/4）✓")

# ---------- 点群（推论 6.49） ----------
point_group(G) = Set([A for (A, _) in G])
@assert point_group(F1) == Set([I2])
@assert point_group(F2) == Set([I2, ROT2])
@assert point_group(F4) == Set([I2, ALPHA])
@assert point_group(F7) == Set([I2, ALPHA, BETA, ROT2])
V4 = point_group(F7)
@assert all(A * A == I2 for A in V4)                  # V₄ 全员自逆
@assert all(A * B == B * A for A in V4, B in V4)      # 交换
println("点群：{1}、{1,R}、{1,α}、{1,α,β,R}——V₄ 的四个子群；V₄ 自逆交换 ✓")

# ---------- F₅ = ⟨ρ⟩ ≅ ℤ（滑动反射带） ----------
# ρ² = t ⟹ ⟨ρ⟩ ⊇ ⟨t⟩ 且 ρ ∉ ⟨t⟩（ρ 的线性部分是 α）⟹ ⟨ρ⟩ = ⟨t⟩ ⊔ ρ⟨t⟩ 无限循环
@assert iseq(comp(RHO, RHO), T) && RHO[1] == ALPHA
println("F₅ = ⟨ρ⟩：ρ² = t 且线性部分 α ∉ ⟨t⟩ 的线性部分 ⟹ ⟨ρ⟩ ⊇ ⟨t⟩ 无限循环 ≅ ℤ ✓")

# ---------- 晶体学限制：整数矩阵的阶 ----------
function mat_order(A)
    A == I2 && return 1
    X = A * A
    k = 2
    while k <= 12 && X != I2
        X = A * X
        k += 1
    end
    X == I2 ? k : 0
end

orders = Set{Int}()
for a in -1:1, b in -1:1, c in -1:1, d in -1:1
    (a * d - b * c in (1, -1)) || continue
    k = mat_order([a b; c d])
    k > 0 && push!(orders, k)
end
@assert orders == Set([1, 2, 3, 4, 6])      # 无 5、无 ≥7
println("晶体学限制：{−1,0,1} 矩阵中可逆者的阶 ⊆ {1,2,3,4,6}（无 5、无 7+）✓")

# 迹论证：2cos(2π/n) 为整数恰在 n ∈ {1,2,3,4,6}
for (n, tr) in [(1, 2.0), (2, -2.0), (3, -1.0), (4, 0.0), (6, 1.0)]
    @assert abs(2cos(2π / n) - tr) < 1e-12
end
@assert abs(2cos(2π / 5) - round(2cos(2π / 5))) > 1e-3   # 阶 5 迹非整
println("迹论证：2cos(2π/n) ∈ ℤ 恰在 n ∈ {1,2,3,4,6}；n=5 给 (√5−1)/2 非整 ✓")

println("END ====")
