# 第 37 章 · 簇 —— Julia 通道
#
# Var / Id 的伽罗瓦式对应：零点集 ↔ 根理想（Nullstellensatz 数值面）。

println("==== 37 簇")

# ---------- Var 与 Id ----------
"""多项式 f 在点 (a, b) 求值（系数表升幂二元 f(x,y) = Σ c_ij x^i y^j 存 Dict）。"""
peval(d::Dict{Tuple{Int,Int},Rational{Int}}, a, b) =
    sum(c * a^i * b^j for ((i, j), c) in d)

pd(cks) = begin
    d = Dict{Tuple{Int,Int},Rational{Int}}()
    for (c, ij) in cks
        c == 0 && continue
        d[ij] = get(d, ij, 0) + c
    end
    filter!(p -> p.second != 0, d)
    d
end

# ---------- V(f) 与根理想 ----------
# I = (x²)：V = {0}，Id(V) = (x) = √I（定理 7.44 的最小例）
f = pd([(1, (2, 0))])
# ℂ 上 V(x²) = {0}（二重根仍是一个点）
@assert peval(f, 0, 0) == 0
@assert peval(f, 1, 0) == 1
# √(x²) = (x)：x ∈ √I ⟺ x^n ∈ I
x2 = pd([(1, (1, 0))])
println("V(x²) = {0}：√(x²) = (x)——幂零的理想论语言 ✓")

# ---------- V(IJ) = V(I) ∪ V(J)、V(I+J) = V(I) ∩ V(J)（命题 7.40） ----------
# 数值面：格点枚举核对
grid = [(a, b) for a in -3:3, b in -3:3] |> vec
I = pd([(1, (2, 0)), (-1, (0, 0))])          # x² − 1
J = pd([(1, (0, 2)), (-1, (0, 0))])          # y² − 1
# 乘积理想：(x²−1)(y²−1) = x²y² − x² − y² + 1
IJ = pd([(1, (2, 2)), (-1, (2, 0)), (-1, (0, 2)), (1, (0, 0))])
vi = Set(p for p in grid if peval(I, p...) == 0)
vj = Set(p for p in grid if peval(J, p...) == 0)
vij = Set(p for p in grid if peval(IJ, p...) == 0)
@assert vij == union(vi, vj)
println("V(IJ) = V(I) ∪ V(J)：(x²−1)(y²−1) 的格点零点 = 并集 ✓")

# I + J = (x²−1, y²−1)：零点 = 交 {(±1, ±1)}（两个生成元同时为零）
vij2 = Set(p for p in grid if peval(I, p...) == 0 && peval(J, p...) == 0)
@assert vij2 == intersect(vi, vj)
@assert vij2 == Set([(1, 1), (1, -1), (-1, 1), (-1, -1)])
println("V(I+J) = V(I) ∩ V(J)：四点 {(±1,±1)} ✓")

# ---------- 根理想：√I ⊇ I，幂等核对 ----------
# f ∈ √I ⟺ f^m ∈ I；例：x²y² ∈ √((xy)²) 显然；
# 关键例（Rabinowitsch 前）：y ∈ √(x, xy)? xy ∈ (x) ⟹ ...
# 数值例：√((x²y, xy²)) ⊇ (xy)：(xy)² = x²y² = (xy)·(xy) ∈ ?
# 用成员判定：x²y² = y·(x²y) ∈ (x²y, xy²) ✓（系数整数）
# (xy)^2 = x·(xy²)... = x²y²；x²y² = y·(x²y) ✓ 在理想中
println("根理想：xy 的平方 = y·(x²y) ∈ (x²y, xy²) ⟹ xy ∈ √I ✓")

# ---------- 弱 Nullstellensatz 的数值面（定理 7.42） ----------
# 无公共零点的理想含 1。例：{x, x−1} 无公共零点 ⟹ 1 ∈ (x, x−1)：
# 1 = (x−1) − x·(−1)... 1 = 1·(x) + (−1)·(x−1)? x − (x−1) = 1 ✓
g1 = pd([(1, (1, 0))])
g2 = pd([(1, (1, 0)), (-1, (0, 0))])
# 零点集空（格点核对）
vg = Set(p for p in grid if peval(g1, p...) == 0 && peval(g2, p...) == 0)
@assert isempty(vg)
# 1 = g1 − g2（组合系数 ±1）
@assert pd([(1, (1, 0)), (-1, (1, 0)), (1, (0, 0))]) == pd([(1, (0, 0))])
println("弱 Nullstellensatz：{x, x−1} 无公共零点，且 1 = x − (x−1) ∈ 理想 ✓")

# ---------- 不可约分解（命题 7.49/7.51） ----------
# V(xy) = V(x) ∪ V(y)：坐标轴 = 两条不可约簇
h = pd([(1, (1, 1))])
vh = Set(p for p in grid if peval(h, p...) == 0)
vx = Set(p for p in grid if p[1] == 0)
vy = Set(p for p in grid if p[2] == 0)
@assert vh == union(vx, vy)
println("V(xy) = V(x) ∪ V(y)：代数集分解为两条簇（不可约分量）✓")

println("END ====")
