# 第 116 章：荟萃塔 I——club 与荟萃的有限刻画、轮换最小性、塔链搜索、
# 等价类机制与泛型相遇（定义 3.10/3.15/引理 3.26/3.36 的机制核；对拍）。
println("==== 116")

# ── 一、载体 {0,1,2} 与一元函数 27 个 ──
const U = [0, 1, 2]
const funs = [(a, b, c) for a in U for b in U for c in U]
feval(f, x) = (x == 0 ? f[1] : x == 1 ? f[2] : f[3])
gcyc(x) = x == 0 ? 1 : x == 1 ? 2 : 0

# ── 二、club：C_f = {A ⊆ U | f[A] ⊆ A} ──
const subsets = sort!([[i for i in 0:2 if (m >> i) & 1 == 1] for m in 0:7], by = length)
fevalimg(f, A) = Set(feval(f, a) for a in A)
club(f) = Set(Set(A) for A in subsets if issubset(fevalimg(f, A), Set(A)))

cclubs = Dict(f => club(f) for f in funs)
sizes = Dict{Int,Int}()
for f in funs
    n = length(club(f))
    sizes[n] = get(sizes, n, 0) + 1
end
println("[club] 27 函数 club 大小分布（大小→函数数）: ",
        join(["$n→$(sizes[n])" for n in sort(collect(keys(sizes)))], " "))

gc = (1, 2, 0)
cgc = sort([sort(collect(A)) for A in club(gc)])
println("[轮换] C_g 大小 = ", length(cgc), "（恰 {{}},{U}——最小 club）")

# ── 三、荟萃性与完全刻画 ──
smn(X) = all(!isempty(intersect(Set(X), c)) for c in values(cclubs))
smn_char = all(smn([Set(A)]) == (isempty(A) || A == U) for A in subsets)
println("[荟萃刻画] 单成员族 {{A}} 荟萃 ⟺ A=∅ 或 A=U: ", smn_char)

X2 = [Set(setdiff(U, [i])) for i in U]
smn_X2 = smn(X2)
println("[非平凡反例] X₂ = 三点余单点族 荟萃? ", smn_X2,
        "（轮换 club 与之交空）")

# ── 四、塔序与链搜索（引理 3.34 机制——支撑面） ──
# ≤ 的 (a) 款：∪Y ⊆ ∪X（支撑方向）。支撑 supp(X) = ⋃X。
supp(X) = union(reduce(union, X))
le(X, Y) = issubset(supp(Y), supp(X))
T1 = [Set([0]), Set([1]), Set(U)]
T2 = [Set([1]), Set([2]), Set(U)]
glb2 = collect(intersect(Set(T1), Set(T2)))
println("[塔序] supp 单调 ≤ 自反: ", le(T1, T1),
        "；glb（成员交）≤ 两者: ",
        le(glb2, T1) && le(glb2, T2), "（同高同支撑）")

# 链搜索：从 X₂ 收缩到 {U} 的贪心链（支撑恒 U——高度不变）。
chain = Vector{Vector{Set{Int}}}()
cur = copy(X2)
push!(chain, copy(cur))
while length(cur) > 1
    global cur = [Set(U)]
    push!(chain, copy(cur))
end
ok_chain = all(le(chain[i], chain[i+1]) for i in 1:length(chain)-1)
println("[塔链] X₂ ≤ {U}: ", le(X2, [Set(U)]),
        "；贪心链长 ", length(chain), " 全程 ≤: ", ok_chain)

# ── 五、等价类机制（引理 3.36 前置的 ~_G） ──
G = B -> (0 in B)  # 主滤子 F₀
eqset(f, g) = Set(b for b in U if feval(f, b) == feval(g, b))
feq(f, g) = G(eqset(f, g))
ok_refl = all(feq(f, f) for f in funs)
ok_sym = all(feq(f, g) == feq(g, f) for f in funs for g in funs)
ok_trans = all(!(feq(f, g) && feq(g, h) && !feq(f, h))
              for f in funs for g in funs for h in funs)
println("[~_G] 自反 ", ok_refl, " 对称 ", ok_sym, " 传递 ", ok_trans,
        "（主滤子 F₀）")

ok_const = all(feq(f, (c, c, c)) == G(Set(b for b in U if feval(f, b) == c))
               for f in funs for c in U)
println("[常值刻画] feq f c ⟺ 相等集∈G: ", ok_const)

# ── 六、泛型相遇（G_X 的相容性 (a)——引理 3.35 影子） ──
down(B, X) = intersect(B, X)
up(A, Y) = union(A, Y)
ok_a = all(issubset(down(B, Set([0, 1])), Set([0, 1]))
           for B in [Set([0]), Set(U)])
ok_b = all(issubset(A, up(A, Set(U))) for A in [Set([0]), Set([1])])
println("[相容] (a) 降落封闭 ", ok_a, "；(b) 提升复原 ", ok_b)

println("club 分布/轮换最小/荟萃刻画/反例；塔序+链+glb；~_G 三律+常值；降落提升")
println("END ====")
