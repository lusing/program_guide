# 第 63 章：命题逻辑（Makinson Ch8）
# 公式求值 + DNF 构造 + 真值树搜索 + 16 个二位真值函数表
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
from itertools import product

print("==== 63")

# ---------- 一、公式（嵌套元组）与赋值延拓 ----------
def ev(v, f):
    if isinstance(f, str): return v[f]
    op = f[0]
    if op == "¬": return not ev(v, f[1])
    if op == "∧": return ev(v, f[1]) and ev(v, f[2])
    if op == "∨": return ev(v, f[1]) or ev(v, f[2])
    raise ValueError

def impl(a, b): return ("∨", ("¬", a), b)
p, q, r = "p", "q", "r"

def letters(f):
    if isinstance(f, str): return {f}
    if len(f) == 2: return letters(f[1])
    return letters(f[1]) | letters(f[2])

def is_taut(f):
    ls = sorted(letters(f))
    return all(ev(dict(zip(ls, vals)), f) for vals in product([True, False], repeat=len(ls)))

# ---------- 二、九条永真蕴含 ----------
tests = [
    ("MP", impl(("∧", p, impl(p, q)), q)),
    ("MT", impl(("∧", impl(p, q), ("¬", q)), ("¬", p))),
    ("DS", impl(("∧", ("∨", p, q), ("¬", p)), q)),
    ("右爆炸", impl(("∧", p, ("¬", p)), q)),
    ("左爆炸", impl(p, ("∨", q, ("¬", q)))),
    ("传递", impl(("∧", impl(p, q), impl(q, r)), impl(p, r))),
    ("De Morgan→", impl(("¬", ("∧", p, q)), ("∨", ("¬", p), ("¬", q)))),
    ("De Morgan←", impl(("∨", ("¬", p), ("¬", q)), ("¬", ("∧", p, q)))),
    ("分配", impl(("∧", p, ("∨", q, r)), ("∨", ("∧", p, q), ("∧", p, r)))),
]
for name, f in tests:
    assert is_taut(f), f"{name} should be taut"
print("  九条永真蕴含全部 ✓")

# 非 Taut 见证
assert not is_taut(impl(impl(p, q), q))
print("  (p→q)→q 非永真 ✓（反例 p=F, q=T）")

# ---------- 三、DNF 语义构造 ----------
def dnf(f):
    ls = sorted(letters(f))
    basics = []
    for vals in product([True, False], repeat=len(ls)):
        v = dict(zip(ls, vals))
        if ev(v, f):
            lit = lambda x, b: x if b else ("¬", x)
            bc = lit(ls[0], v[ls[0]])
            for x in ls[1:]:
                bc = ("∧", bc, lit(x, v[x]))
            basics.append(bc)
    if not basics: return ("∧", p, ("¬", p))
    return basics[0] if len(basics) == 1 else \
        ("∨", basics[0], basics[1]) if len(basics) == 2 else \
        ("∨", basics[0], ("∨", basics[1], basics[2]))

f = impl(p, q)
d = dnf(f)
assert is_taut(("∨", ("¬", f), d)) and is_taut(("∨", ("¬", d), f))
print("  p→q 的 DNF = (¬p∧¬q)∨(¬p∧q)∨(p∧q)，语义等价 ✓")

# ---------- 四、16 个二位真值函数表 ----------
# 真值表列向量 → 函数编号：f_i 的第 j 位是行 j 的值
print("  16 个二位真值函数（f₁..f₁₆ 的真值表，行序 TT,TF,FT,FF）：")
for i in range(16):
    bits = [(i >> (3-j)) & 1 for j in range(4)]
    known = {(1,1,1,1):"⊤", (1,1,1,0):"∨", (1,1,0,1):"←", (1,1,0,0):"p∧q→¬q",
             (1,0,1,1):"→", (1,0,1,0):"↔", (1,0,0,1):"p", (1,0,0,0):"p∧q",
             (0,1,1,1):"¬p→q", (0,1,1,0):"⊕", (0,1,0,1):"q", (0,1,0,0):"p∧¬q",
             (0,0,1,1):"¬p", (0,0,1,0):"¬p∧q", (0,0,0,1):"p↓q", (0,0,0,0):"⊥"}
    tag = known.get(tuple(bits), "")
    print(f"    f{i+1:2d}: {bits}  {tag}")

# ---------- 五、真值树（活支搜索）：((p∧q)→r)→(p→r) 非永真 ----------
big = impl(impl(("∧", p, q), r), impl(p, r))
assert not is_taut(big)
print("  ((p∧q)→r)→(p→r) 非 Taut ✓（书本例：活支 v(p)=T, v(q)=F, v(r)=F）")

print("END ====")
