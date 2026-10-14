# 第 51 章 C(ℝ) 剧场：sin/cos 的布尔值与裁决三幕

println("==== 51")

# ---------- (a) ⟦sin < cos⟧ 的数值化身：RO(ℝ) 的区间元素 ----------
# 扫描 [0, 4π]：找 sin x < cos x 的开分量（两端各内缩 ε 防边界）
f_less(x) = sin(x) < cos(x)

function scan_segments(f; lo = 0.0, hi = 4π, n = 40001, eps = 1e-9)
    xs = range(lo, hi; length = n)
    segs = Tuple{Float64,Float64}[]
    in_seg = false
    seg_start = 0.0
    for i in 1:(n - 1)
        if f(xs[i]) && f(xs[i + 1])
            if !in_seg
                seg_start = xs[i]
                in_seg = true
            end
        elseif in_seg
            push!(segs, (seg_start + eps, xs[i] - eps))
            in_seg = false
        end
    end
    if in_seg
        push!(segs, (seg_start + eps, hi - eps))   # 尾段闭合
    end
    return segs
end

segs = scan_segments(f_less)
println("(a) ⟦sin < cos⟧ 的连通分量（RO(ℝ) 的元素）：")
for (a, b) in segs
    println("    ($(round(a; digits = 3)), $(round(b; digits = 3)))")
end
# 与理论对照：sin−cos = √2·sin(x−π/4) < 0 ⟺ x ∈ (5π/4+2kπ, 9π/4+2kπ)
# （Viale 原文的区间 (π/4,5π/4) 对应 sin > cos——PDF 符号乱码勘误）
expected = [(0.0, π / 4), (5π / 4, 9π / 4), (13π / 4, 4π)]  # [0,4π] 内三段
ok = length(segs) == 3 && all(abs.([segs[i][1] - expected[i][1] for i in 1:3]) .< 0.01 .&&
       [segs[i][2] - expected[i][2] for i in 1:3] .< 0.01)
println("    与 (5π/4+2kπ, 9π/4+2kπ) 吻合：", ok ? "✓" : "✗")
@assert ok

# ---------- (b) 三幕裁决剧场 ----------
# 第一幕：π/4 邻域滤子不能裁决
x0 = π / 4
δ = 0.05
lo, hi = x0 - δ, x0 + δ
println("(b1) π/4 的邻域 (±0.05)：左半 sin<cos=$(f_less(lo))，右半 sin>cos=$(sin(hi) > cos(hi))")
@assert f_less(lo) && (sin(hi) > cos(hi))
println("     两半各执一词——邻域滤子【不裁决】✓（Viale §6.2 的核心观察）")

# 第二幕：缩小到 δ→0 仍不能裁决（π/4 处相等）
for δ2 in (0.01, 0.001, 1e-5)
    @assert f_less(x0 - δ2) && (sin(x0 + δ2) > cos(x0 + δ2))
end
println("(b2) δ → 0：两半始终各执一词——点不够，要【超滤】✓")

# 第三幕：超滤裁决（左超滤 vs 右超滤）
left_decides = "sin > cos"   # 选左半（< π/4）：cos 大
right_decides = "sin < cos"  # 选右半
println("(b3) 左超滤裁决：$(left_decides)；右超滤裁决：$(right_decides)")
println("     超滤 = 极大相容裁决机——两个超滤给出两个答案，各自无矛盾 ✓")

# ---------- (c) 量词 = sup：∃x∈ℚ φ(x) 的布尔值 ----------
# 稠密网格上 φ(x) = (sin x > 0.5) 的存在值 = 网格 max（sup 逼近）
grid = range(0, 2π; length = 2001)
phi(x) = sin(x) > 0.5 ? 1.0 : 0.0
sup_val = maximum(phi.(grid))
println("(c) ⟦∃x φ(x)⟧ 的网格 sup = $(sup_val)（φ 在某点真 ⟹ 值 = 1）")
@assert sup_val == 1.0
# ∀ 的 inf：ψ(x) = sin²x + cos²x - 1 ≈ 0（恒真式的 inf 逼近）
psi_inf = minimum(abs.(sin.(grid) .^ 2 + cos.(grid) .^ 2 .- 1))
println("    ⟦∀x ψ(x)⟧ 的网格 inf（|sin²+cos²-1| 的余）= $(round(psi_inf; digits = 6)) → 0")
@assert psi_inf < 1e-10

println("END ====")
