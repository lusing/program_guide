# 第 78 章：奇异基数假设——银杰与嘎尔文-海纳（冯琦 §2.4）——Python 通道
# 四个场景：引理 2.16 的压小函数与佛多纤维（有限模拟）；引理 2.19 的超滤子
# 线性序（尾集替身，可比较/传递/初始段计数）；两点底空间的范数表（验证引理
# 2.20(1)(3)）；引理 2.22 的指标记账（ω₁+‖φ‖<ζ）。
import sys, io, itertools
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 78")

# ---------- 场景一：引理 2.16——压小函数与佛多纤维 ----------
# μ=8，g(α)=2α+3。取 f(α)=α（满足 f(α)<g(α)）。压小 f*(α)=min{β<α : f(α)<g(β)}
# 把每个 α 映到更小的 β；f* 的纤维划分演示佛多"某纤维大"。
def scene1():
    mu = 8
    g = lambda a: 2 * a + 3
    f = lambda a: a
    assert all(f(a) < g(a) for a in range(mu))
    fstar = {}
    for a in range(1, mu):                       # α=0 无 β<0
        cands = [b for b in range(a) if f(a) < g(b)]
        assert cands, f"α={a} 无压小见证"
        fstar[a] = min(cands)
    fibers = {}
    for a, v in fstar.items():
        fibers.setdefault(v, []).append(a)
    return mu, fstar, fibers

mu1, fstar, fibers = scene1()
biggest = max(fibers.values(), key=len)
print(f"场景一（引理 2.16 压小）：μ={mu1}, g(α)=2α+3, f(α)=α；f*={dict(sorted(fstar.items()))}")
print(f"  纤维划分 {({k: v for k, v in sorted(fibers.items())})}；最大纤维 {biggest}（佛多'某纤维大'的有限影）✓")

# ---------- 场景二：引理 2.19——超滤子线性序（尾集替身） ----------
# μ=5，"大集"取尾集 {α≥t}（有限世界的超滤子替身）。f ≤_U g ⟺ {α:f(α)≤g(α)} 大。
def scene2():
    mu = 5
    def is_large(S):                             # S 含某个尾集 {t..mu-1}
        return any(set(range(t, mu)) <= S for t in range(mu))
    F = {"f": lambda a: a, "g": lambda a: 2 * a, "h": lambda a: a + 10}
    names = list(F)
    def le(x, y):
        return is_large({a for a in range(mu) if F[x](a) <= F[y](a)})
    for x in names:
        assert le(x, x)                          # 自反
    for x, y in itertools.product(names, repeat=2):
        assert le(x, y) or le(y, x)              # 可比较（线性）
    for x, y, z in itertools.product(names, repeat=3):
        if le(x, y) and le(y, z):
            assert le(x, z)                      # 传递
    downsets = []                                # 初始段（下闭集）计数
    for r in range(len(names) + 1):
        for D in itertools.combinations(names, r):
            Ds = set(D)
            if all((not (le(x, y) and y in Ds)) or (x in Ds)
                   for x in names for y in names):
                downsets.append(Ds)
    order = sorted(names, key=lambda x: sum(1 for y in names if le(y, x) and not le(x, y)))
    return order, len(downsets)

order2, ndown = scene2()
print(f"场景二（引理 2.19 线性序）：μ=5 尾集替身下 F 线性排序为 {' < '.join(order2)}，下闭集 {ndown} 个 ✓")

# ---------- 场景三：两点底空间的范数表（验证引理 2.20(1)(3)） ----------
# 底空间 {0,1}，滤子 I = {含点 1 的集合}（点 1 处的principal超滤子）。
# 穷举 f:{0,1}→{0,1,2}，按定义 2.30 递推 ‖f‖=sup{‖g‖+1 : g<_I f}。
def scene3():
    base = [0, 1]
    vals = [0, 1, 2]
    funcs = [(a, b) for a in vals for b in vals]  # (f(0), f(1))
    def large(S):
        return 1 in S
    def less_I(g, f):                             # g<_I f ⟺ {α:g(α)<f(α)} 含点 1
        return large({a for a in base if g[a] < f[a]})
    norm = {}
    def gh(f):
        if f in norm:
            return norm[f]
        below = [g for g in funcs if less_I(g, f)]
        norm[f] = 0 if not below else max(gh(g) + 1 for g in below)
        return norm[f]
    for f in funcs:
        gh(f)
    table = dict(norm)
    # ‖f‖ 只依赖 f(1)：坐标 0 非荟萃（引理 2.20(3)），限制到 {1} 范数不降（(1)）
    assert all(table[f] == f[1] for f in funcs)
    for f, g in itertools.product(funcs, repeat=2):
        if f[1] == g[1]:
            assert table[f] == table[g]           # 只差坐标 0 ⟹ 同范数
    return table

table3 = scene3()
rows = ", ".join(f"‖{f}‖={table3[f]}" for f in sorted(table3))
print(f"场景三（两点范数表）：{rows}")
print("  ‖f‖ 只依赖荟萃坐标 f(1)：引理 2.20(3)（非荟萃坐标 0 无关）与 (1)（限制不降）成立 ✓")

# ---------- 场景四：引理 2.22——指标记账 ω₁+‖φ‖<ζ ----------
# ‖φ‖≤2^{ℵ₁}，ζ=(2^{ℵ₁})⁺。序数吸收律 ω₁+2^{ℵ₁}=2^{ℵ₁}（因 2^{ℵ₁}≥ℵ₂>ω₁·ω），
# 故 ω₁+‖φ‖≤2^{ℵ₁}<ζ。以指标记账：2^{ℵ₁}=ℵ_c ⟹ ζ=ℵ_{c+1}，ω₁+‖φ‖ 指标 ≤ c<c+1。
def scene4():
    rows = []
    for c in (2, 3, 4):                           # 2^{ℵ₁}=ℵ_c 的几种可能
        zeta_idx = c + 1
        for phi_idx in range(0, c + 1):           # ‖φ‖ ≤ 2^{ℵ₁}，指标 ≤ c
            sum_idx = max(1, phi_idx)             # ω₁+‖φ‖ 指标上界（ω₁ 指标=1，吸收）
            assert sum_idx < zeta_idx             # ω₁+‖φ‖ < ζ
        rows.append((c, zeta_idx))
    return rows

rows4 = scene4()
cs = [c for c, _ in rows4]
print(f"场景四（引理 2.22 记账）：对 2^ℵ₁=ℵ_c（c∈{cs}），ζ=ℵ_(c+1)，ω₁+‖φ‖ 指标恒 < ζ 指标 ✓")

print("END ====")
