# 第 72 章：秩序与序数算术（冯琦 §1.8.1-1.8.3）
# 康托尔范式演算器（ε₀ 以内）· Python 面：带余除法（引理 1.20）
# 的存在性与唯一性对拍、指数层的序数差 odiff（y ≤ x 时 y+γ = x 的
# 唯一 γ）、ε₀ 塔与两座不动点塔、康托尔范式的自然数投影（定理 1.78）。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 72")

# ---------- 表示：范式表 [(指数, 系数), …] 指数递降；0 = [] ----------
# 有限 n>0 = [(0, n)]（ω⁰·n）——表示即范式（定理 1.80）。

def oz():
    return []

def nat(n):
    return [] if n <= 0 else [([], n)]

def wexp(e):
    return [(e, 1)]                      # ω^e

OMEGA = wexp(nat(1))

def eq(a, b):
    return a == b

def olt(a, b):
    if a == b:
        return False
    if not a:
        return bool(b)                   # 有限 < 无穷
    if not b:
        return False
    (ea, ca), (eb, cb) = a[0], b[0]
    if ea != eb:
        return olt(ea, eb)
    if ca != cb:
        return ca < cb
    return olt(a[1:], b[1:])

def oadd(a, b):
    if not b:
        return list(a)
    if not a:
        return list(b)
    eb, cb = b[0]
    keep = []
    for e, c in a:
        if olt(eb, e):                   # 指数 > β 首指数：保留
            keep.append((e, c))
        else:
            break
    extra = 0
    if len(keep) < len(a) and a[len(keep)][0] == eb:
        extra = a[len(keep)][1]          # 等指数项合并系数（ω+ω = ω·2）
    return keep + [(eb, cb + extra)] + b[1:]

def omul(a, b):
    if not a or not b:
        return []
    if b == nat(1):
        return list(a)
    if a == nat(1):
        return list(b)
    (ea, ca), (eb, cb) = a[0], b[0]
    # 情形一：双方有限——系数相乘
    if len(a) == 1 and not ea and len(b) == 1 and not eb:
        return [([], ca * cb)]
    restb = b[1:]
    # 情形二：α 有限、β 无穷——首项吞掉 α 的系数，尾部递归
    if len(a) == 1 and not ea:
        return oadd([(eb, cb)], omul(a, restb))
    # 情形三：β 有限 ≥ 2——α·m = α+…+α（(ω+1)·2 = ω·2+1 的来源）
    if not eb:
        r = []
        for _ in range(cb):
            r = oadd(r, a)
        return r
    # 情形四：双方无穷——头项 ω^(ea+eb)·cb，余部 α·restβ
    head = [(oadd(ea, eb), cb)]
    if not restb:
        return head
    return head + omul(a, restb)

def show(a):
    parts = []
    for e, c in a:
        es = "0" if not e else ("" if e == nat(1) else "(" + show(e) + ")")
        parts.append(("ω" + es) if c == 1 else f"ω{es}·{c}")
    return "+".join(parts) if parts else "0"

# ---------- 不可交换三见证 ----------
assert oadd(nat(1), OMEGA) == OMEGA            # 1+ω = ω
assert olt(OMEGA, oadd(OMEGA, nat(1)))         # ω < ω+1
assert omul(nat(2), OMEGA) == OMEGA            # 2·ω = ω
assert olt(OMEGA, omul(OMEGA, nat(2)))         # ω < ω·2
assert oadd(nat(1), OMEGA) == oadd(nat(2), OMEGA)   # 弱保序的平局见证
print("1+ω = ω = 2+ω < ω+1 ✓   2·ω = ω < ω·2 ✓")

# ---------- 运算律网格 ----------
G = [oz(), nat(1), nat(2), OMEGA, oadd(OMEGA, nat(1)),
     omul(OMEGA, nat(2)), wexp(nat(2)), wexp(OMEGA), oadd(wexp(OMEGA), nat(1))]

cnt = {"add": 0, "mul": 0, "dist": 0}
for a in G:
    for b in G:
        for c in G:
            assert oadd(oadd(a, b), c) == oadd(a, oadd(b, c))     # 定理 1.75
            assert omul(omul(a, b), c) == omul(a, omul(b, c))     # 定理 1.76
            assert omul(a, oadd(b, c)) == oadd(omul(a, b), omul(a, c))
            cnt["add"] += 1; cnt["mul"] += 1; cnt["dist"] += 1
print(f"9³ 网格：加法结合/乘法结合/左分配各 {cnt['add']} 例全对 ✓")

# 右分配律的反例（引理 1.26 之后）：(ω+1)·2 ≠ ω·2 + 1·2
lhs = omul(oadd(OMEGA, nat(1)), nat(2))
rhs = oadd(omul(OMEGA, nat(2)), omul(nat(1), nat(2)))
assert lhs == oadd(omul(OMEGA, nat(2)), nat(1)) and lhs != rhs
print(f"(ω+1)·2 = {show(lhs)} ≠ ω·2+1·2 = ω·2+2 ✓（右分配律失效）")

# ---------- 序数差：odiff(x, y) = 唯一 γ 使 y + γ = x（y ≤ x） ----------
def odiff(x, y):
    if not y:
        return list(x)                   # 0 + γ = x
    (ex, cx), (ey, cy) = x[0], y[0]
    if olt(ey, ex):                      # y 整体被吞：γ = x
        return list(x)
    if cx == cy:                         # 首项相同：剥层递归
        return odiff(x[1:], y[1:])
    return [(ex, cx - cy)] + x[1:]       # 同指数差系数：y 的尾被吞

# 自检：odiff 的 y + γ = x 双向验证
for x in G:
    for y in G:
        if eq(y, x) or olt(y, x):
            g = odiff(x, y)
            assert oadd(y, g) == x, f"odiff 失败 {show(y)}+?={show(x)}"
assert odiff(nat(3), nat(1)) == nat(2)
assert oadd(nat(2), odiff(nat(5), nat(2))) == nat(5)   # 补差律（定理 1.75）
print("odiff（补差律 γ）：45 对全对 ✓")

# ---------- 带余除法（引理 1.20）：δ = α·β + ρ ∧ ρ < α，唯一性对拍 ----------
P = list(G)
for a in G:                              # 候选池封闭化：掺入全部乘积
    for b in G:
        p = omul(a, b)
        if p not in P:
            P.append(p)
pairs_ok = 0
for d in G:
    for alpha in G[1:]:                  # α ≠ 0
        sols = [(be, r) for be in P for r in G
                if eq(oadd(omul(alpha, be), r), d) and olt(r, alpha)]
        assert len(sols) == 1, \
            f"除法唯一性失败 δ={show(d)} α={show(alpha)}: {len(sols)} 解"
        pairs_ok += 1
print(f"带余除法：{pairs_ok} 对 (δ,α) 的解存在且唯一 ✓（候选池 {len(P)} 元）")

# ---------- 幂与两座不动点塔（定理 1.74 现场点火） ----------
for a in G:
    for b in G:
        assert wexp(oadd(a, b)) == omul(wexp(a), wexp(b))   # ω^(α+β) = ω^α·ω^β
print("ω^(α+β) = ω^α·ω^β：81 例全对 ✓")

t, tower1 = nat(1), [nat(1)]
for _ in range(5):
    t = omul(OMEGA, t); tower1.append(t)
assert tower1[1] == OMEGA and tower1[2] == wexp(nat(2))
assert omul(OMEGA, wexp(OMEGA)) == wexp(OMEGA)     # ω·ω^ω = ω^ω：不动点实弹
e, tower2 = nat(1), [nat(1)]
for _ in range(4):
    e = wexp(e); tower2.append(e)
assert all(olt(tower2[k], tower2[k + 1]) for k in range(4))
print("ω·x 塔 1→ω→ω²→…，ω·ω^ω = ω^ω ✓；ω^x 塔 1→ω→ω^ω→…（sup = ε₀）✓")

# ---------- 康托尔范式的自然数投影（定理 1.78：基 b 展开） ----------
def digits(n, b):
    out = []
    while n:
        out.append(n % b); n //= b
    return out

for n in range(1, 60):
    for b in (2, 3, 10):
        ds = digits(n, b)
        assert sum(d * b**i for i, d in enumerate(ds)) == n
assert digits(5, 2) == [1, 0, 1]         # 5 = 1+4 = 101₂
print("基 b 展开 59×3 全对 ✓（ω^0 系数层的十进制影子）")

print("END ====")
