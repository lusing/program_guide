# 第 38 章 · 簇 —— Python 通道
#
# Var/Id 对应 + 根理想 + Nullstellensatz（sympy groebner/solve 的符号面）。

import sympy as sp

x, y = sp.symbols("x y")

print("==== 38 簇")

# ---------- Var 的集合运算（命题 7.40） ----------
I = x**2 - 1
J = y**2 - 1
solI = sp.solve(I, x)
solJ = sp.solve(J, y)
assert solI == [-1, 1] and solJ == [-1, 1]
# V(IJ) = V(I) ∪ V(J)：乘积多项式零点 = 并
solIJ = sp.solve(sp.expand(I * J), (x, y), dict=True)
pts_IJ = {(s[x], s[y]) for s in
          [dict(zip((x, y), (a, b))) for a in solI for b in [-3, 0, 3]]}
# 直接枚举格点（数值面）
grid = [(a, b) for a in range(-3, 4) for b in range(-3, 4)]
vi = {p for p in grid if (I.subs({x: p[0], y: p[1]}) == 0)}
vj = {p for p in grid if (J.subs({x: p[0], y: p[1]}) == 0)}
vij = {p for p in grid if sp.expand(I * J).subs({x: p[0], y: p[1]}) == 0}
assert vij == vi | vj
# V(I+J) = V(I) ∩ V(J)
vij2 = {p for p in grid if I.subs({x: p[0], y: p[1]}) == 0
        and J.subs({x: p[0], y: p[1]}) == 0}
assert vij2 == vi & vj == {(1, 1), (1, -1), (-1, 1), (-1, -1)}
print("Var 运算：V(IJ) = V(I)∪V(J)、V(I+J) = V(I)∩V(J)（49 格点核对）✓")

# ---------- 根理想与 √I = Id(V(I))（定理 7.44） ----------
# I = (x²)：V = {0}，Id(V) = √I = (x)
G = sp.groebner([x**2], x, order="lex")
# sympy 无直接根理想函数：用 (x²) 的 Grobner 基与 (x) 比较——
# f ∈ √I ⟺ f^m ∈ I：x² ∈ (x²) 显然；数值面核对 x 的幂落入理想
assert sp.div(x**3, x**2, x, domain=sp.QQ)[1] == 0        # x³ ∈ (x²)
assert sp.div(x**4, x**2, x, domain=sp.QQ)[1] == 0
# (x(x−1)) 的根理想 = (x(x−1)) 本身（无重根 ⟹ 根理想）
f = x * (x - 1)
assert sp.div(f**2, f, x, domain=sp.QQ)[1] == 0
assert sp.roots(f, x) == {0: 1, 1: 1}                      # 单根
print("根理想：x³、x⁴ ∈ (x²)；无重根理想的幂仍落入自身 ✓")

# ---------- 弱 Nullstellensatz（定理 7.42）的符号面 ----------
# 无公共零点 ⟹ 1 ∈ I。{x, x−1}：sympy groebner 基含 1
G = sp.groebner([x, x - 1], x, order="lex")
assert 1 in [g.as_expr() for g in G.polys] or G.polys[0].as_expr() == 1
# {x, x−1} 的解集空
assert sp.solve([x, x - 1], [x], dict=True) == []
print("弱 Nullstellensatz：{x, x−1} 无解，groebner 基 = [1] ✓")

# ---------- 强 Nullstellensatz（定理 7.44）与拉比诺维奇技巧 ----------
# I = (y², xy)：V(I) = {y = 0}（整条 x-轴）；Id(V) = √I = (y)
# y ∉ I（余式非零）但 y² ∈ I ⟹ y ∈ √I \ I
Gm = sp.groebner([y**2, x * y], x, y, order="lex")
assert sp.expand(Gm.reduce(y)[1]) != 0
assert sp.expand(Gm.reduce(y**2)[1]) == 0
# 拉比诺维奇技巧（原书证明所用）：f ∈ √I ⟺ I + (1 − t·f) 无解
t = sp.Symbol("t")
Gr = sp.groebner([y**2, x * y, 1 - t * y], x, y, t, order="lex")
assert any(g.as_expr() == 1 for g in Gr.polys)             # 基含 1 ⟹ 无解 ⟹ y ∈ √I
# 对照：x ∉ √I（x 轴上 x 任意，x 不在根理想中）
Gr2 = sp.groebner([y**2, x * y, 1 - t * x], x, y, t, order="lex")
assert not any(g.as_expr() == 1 for g in Gr2.polys)        # 有解 ⟹ x ∉ √I
print("拉比诺维奇技巧：y ∈ √(y²,xy)（基含 1）；x ∉（基不含 1）✓")

# ---------- 不可约分解（命题 7.49/7.51） ----------
# V(xy) = V(x) ∪ V(y)（两条轴）；xy 可分解 ⟹ 簇可分解
vh = {p for p in grid if (x * y).subs({x: p[0], y: p[1]}) == 0}
vx = {p for p in grid if p[0] == 0}
vy = {p for p in grid if p[1] == 0}
assert vh == vx | vy
# 对应的理想面：Id(V) = √((xy)) = (xy)（xy 无重因子）；
# 素分解 (xy) ⊆ (x) ∩ (y)：x·y 同属两者
assert sp.div(x * y, x, domain=sp.QQ)[1] == 0
assert sp.div(x * y, y, domain=sp.QQ)[1] == 0
print("簇分解：V(xy) = 两条轴；(xy) ⊆ (x)∩(y)（素理想的交）✓")

# ---------- 极大理想（定理 7.45）的数值面 ----------
# ℂ[x] 的极大理想全部形如 (x − a)：a = 2 时
Gm = sp.groebner([x - 2], x, order="lex")
assert sp.solve(x - 2, x) == [2]
# (x−2) 极大 ⟺ 商 ℂ[x]/(x−2) ≅ ℂ：代入 x = 2 是同态
assert (x**2 + 1).subs(x, 2) == 5
print("极大理想：(x−a) 型——求值同态 x ↦ a（ℂ[x] 的完全刻画）✓")

print("END ====")
