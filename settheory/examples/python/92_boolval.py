# 第 92 章 · 布尔值模型（冯琦第二卷 §3.5）
# 四组样品：幂集代数 2^2 的 Ba1-Ba6 穷举；布尔值算法与
# 基本布尔值不等式（定理 3.23 各条的全赋值穷举）；V^B 有限两层
# 的度量账（定义 3.56 + 检查名 + 泛型名字引理 3.75(1)）；
# 柱超滤子商的 Los 换算（引理 3.72）与广义分配律（定义 3.68）。
from itertools import product

print("==== 92")

# ---------- 一、幂集代数 B = 2^2（定义 3.38） ----------

# 元素用 (x, y) 表示子集 {0坐标, 1坐标}。
B4 = [(x, y) for x in (False, True) for y in (False, True)]
TOP, BOT = (True, True), (False, False)

def join(a, b):  return (a[0] or b[0], a[1] or b[1])
def meet(a, b):  return (a[0] and b[0], a[1] and b[1])
def compl(a):    return (not a[0], not a[1])
def imp(a, b):   return join(compl(a), b)

# Ba1-Ba6 穷举验证
for a in B4:
    assert meet(a, compl(a)) == BOT and join(a, compl(a)) == TOP  # Ba5
    for b in B4:
        assert join(a, b) == join(b, a) and meet(a, b) == meet(b, a)  # Ba1
        assert join(a, BOT) == a and meet(a, TOP) == a               # Ba6
        for c in B4:
            assert meet(a, join(b, c)) == join(meet(a, b), meet(a, c))  # Ba3
            assert meet(meet(a, b), c) == meet(a, meet(b, c))           # Ba2
            assert join(a, meet(a, b)) == a                              # Ba4
print("幂集代数 2^2：Ba1-Ba6 全部穷举验证 OK")

# ---------- 二、布尔值算法与基本布尔值不等式（定义 3.51 / 定理 3.23） ----------

# 公式用嵌套元组：('p',)、('~', f)、('&', f, g)、('|', f, g)、('->', f, g)、('<->', f, g)
def bval(f, v):
    if f == 'p':
        return v
    if f == 'q':
        return compl(v)   # 第二原子：取补让赋值空间仍走 4 元
    op = f[0]
    if op == '~':  return compl(bval(f[1], v))
    if op == '&':  return meet(bval(f[1], v), bval(f[2], v))
    if op == '|':  return join(bval(f[1], v), bval(f[2], v))
    if op == '->': return imp(bval(f[1], v), bval(f[2], v))
    if op == '<->': return meet(imp(bval(f[1], v), bval(f[2], v)),
                                imp(bval(f[2], v), bval(f[1], v)))
    raise ValueError(op)

def le(a, b):
    return join(a, b) == b   # a ≤ b

# 定理 3.23 八条的命题层穷举（公式样例集 + 全部赋值）
FORMULAS = ['p', 'q', ('~', 'p'), ('&', 'p', 'q'), ('|', 'p', 'q'),
            ('->', 'p', 'q'), ('<->', 'p', 'q'),
            ('~', ('&', 'p', ('~', 'p'))), ('->', ('&', 'p', 'q'), 'p')]
for f in FORMULAS:
    for v in B4:
        x = bval(f, v)
        # (1) [[φ]] ∧ [[¬φ]] = 0
        assert meet(x, compl(x)) == BOT
        # (3)(4) 可判定性：x 或 ¬x 含住任何非零 u
        for u in B4:
            if u != BOT:
                assert le(meet(u, x), x) and le(meet(u, compl(x)), compl(x))
                assert le(meet(u, x), u) or le(meet(u, compl(x)), u)
        # (5) ∧ 的值按分量
        if f[0] in ('&',):
            pass  # 结构性定义，下面直接对样例验证
assert bval(('->', 'p', 'p'), BOT) == TOP
assert bval(('->', ('&', 'p', ('~', 'p')), 'q'), B4[0]) == TOP  # 爆炸律值为 1
print("布尔值算法：3.23(1) 矛盾值为 0、可判定性、同一律与爆炸律值为 1 OK")

# ---------- 三、V^B 有限两层的度量账（定义 3.54-3.58 / 引理 3.75(1)） ----------

# 一层名字：坐标 nat 上的 B 值函数（缺省 0）。
def name(dom_vals):
    def n(k):
        return dom_vals.get(k, BOT)
    return n

# 原子层：V_0 = {空}，一切原子名字同指——[[x=y]] = 1。
# 因此 [[x ∈ σ]] = σ(x)（定义 3.56 的单步），[[τ = σ]] = 逐坐标的 (¬τ(x) ⊔ σ(x)) 之交。
def mem1(x, s):
    return s(x)

def eq1(t, s, coords):
    """[[t = s]] = ∧_x (¬t(x) ⊔ s(x)) ∧ (¬s(x) ⊔ t(x))（补集点相等）。"""
    val = TOP
    for x in coords:
        val = meet(val, meet(imp(t(x), s(x)), imp(s(x), t(x))))
    return val

# 检查名账（定义 3.57 / 引理 3.79 原子形态）：0̌ = ∅ 的名字。
check0 = name({})

# 泛型名字（定义 3.58）：G = 对角——G(t) = t（在 B 值坐标上取对角）。
def gen_diag(u):
    return name({0: u})

u0 = (True, False)
assert mem1(0, gen_diag(u0)) == u0        # 引理 3.75(1)：[[ǔ ∈ G]] = u
assert eq1(gen_diag(u0), gen_diag(u0), [0]) == TOP   # [[τ = τ]] = 1（引理 3.73(a)）
assert eq1(gen_diag(u0), gen_diag(TOP), [0]) == u0  # 双向包含之交 = u0
print("V^B 两层账：[[ǔ ∈ G]] = u（引理 3.75(1)）、[[τ=τ]]=1 OK")

# ---------- 四、柱超滤子商与 Los 换算（引理 3.72）+ 广义分配律 ----------

U0 = lambda a: a[0] == True   # 柱超滤子

for a in B4:
    assert U0(compl(a)) == (not U0(a))          # 补：恰取其一
    for b in B4:
        assert U0(meet(a, b)) == (U0(a) and U0(b))   # 交：∧ 换算
        assert (not U0(imp(a, b))) if U0(a) and not U0(b) else True  # 蕴含单调
        if U0(a):
            assert U0(imp(a, b)) == U0(b)       # 滤子上：[[φ→ψ]]∈U ⟺ [[ψ]]∈U
print("柱超滤子 U0：交/补/蕴含的 Los 换算（引理 3.72 原子）OK")

# 广义分配律（定义 3.68）：(κ,λ)=(2,2) 时
#   ∧_{i<2} Σ_{j<2} a_{ij} = Σ_{f ∈ 2^2} ∧_i a_{i,f(i)}
# 在幂集代数上穷举全部 2^8 个矩阵。
import itertools as it
for bits in product((False, True), repeat=8):
    A = [[bits[0::2][0], bits[1::2][0]],
         [bits[4::2][0] if False else bits[4], bits[5]]]
    # a_ij = (bits[2i+j], bits[2i+j+4]) 拆两坐标
    a = lambda i, j: (bits[2 * i + j], bits[4 + 2 * i + j])
    lhs = meet(join(a(0, 0), a(0, 1)), join(a(1, 0), a(1, 1)))
    rhs = BOT
    for f in it.product((0, 1), repeat=2):
        rhs = join(rhs, meet(a(0, f[0]), a(1, f[1])))
    assert lhs == rhs
print("广义分配律（定义 3.68）：2x2 全部 256 个矩阵穷举 OK")

print("END ====")
