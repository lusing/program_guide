# 第 73 章：快速增长数论函数层次（冯琦 §1.8.4）——Python 通道
# 与 73_fastgrowth.jl 同构：基本序列（定义 1.83）、F_α 层次（定义 1.84，
# F₁ 闭式与字面定义对拍）、古德斯坦剧场（遗传展开树 HB 不存基——换基
# = 换读法，影子 = 同一棵树读成序数，定理 1.82 的机理裸奔）。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 73")

# ---------- ON：ε₀ 以内的序数 = ((指数, 系数), …) 指数递降 ----------
OZ = ()
def nat(n): return () if n <= 0 else ((OZ, n),)
def wexp(e): return ((e, 1),)
OMEGA = wexp(nat(1))

def olt(a, b):
    if a == b: return False
    if not a: return bool(b)
    if not b: return False
    (ea, ca), (eb, cb) = a[0], b[0]
    if olt(ea, eb): return True
    if olt(eb, ea): return False
    if ca != cb: return ca < cb
    return olt(a[1:], b[1:])

def oadd(a, b):
    if not b: return a
    if not a: return b
    eb, cb = b[0]
    keep = []
    for (e, c) in a:
        if olt(eb, e): keep.append((e, c))
        else: break
    extra = 0
    if len(keep) < len(a) and a[len(keep)][0] == eb:
        extra = a[len(keep)][1]
    return tuple(keep) + ((eb, cb + extra),) + b[1:]

def show_on(a):
    parts = []
    for (e, c) in a:
        es = "0" if e == OZ else ("" if e == nat(1) else "(" + show_on(e) + ")")
        parts.append(f"ω{es}" if c == 1 else f"ω{es}·{c}")
    return "+".join(parts) if parts else "0"

# ---------- 后继/极限判定与前驱 ----------
def is_limit(a): return bool(a) and a[-1][0] != OZ
def opred(a):
    assert not is_limit(a) and a, "opred: 只接受后继序数"
    ts = list(a)
    e, c = ts[-1]
    assert e == OZ
    if c == 1: ts.pop()
    else: ts[-1] = (e, c - 1)
    return tuple(ts)

# ---------- 基本序列（定义 1.83：四条款 + ε₀ 特例） ----------
def fs(a, n):
    assert is_limit(a), "fs: 只对极限序数取基本序列"
    (bm, km) = a[-1]
    if len(a) > 1:
        # (d) m>1：头部保留，末项系数减一后接 (ω^βm)(n)
        head = a[:-1] + (((bm, km - 1),) if km > 1 else ())
        return oadd(head, fs(((bm, 1),), n))
    (beta, k) = a[0]
    if k > 1:
        # (c) m=1, k>1：α(n) = ω^β·(k−1) + (ω^β)(n)
        return oadd(((beta, k - 1),), fs(((beta, 1),), n))
    if is_limit(beta):
        # (b) m=1, k=1, β 极限：α(n) = ω^(β(n))
        return wexp(fs(beta, n))
    # (a) m=1, k=1, β=γ+1：α(n) = ω^γ·n（含 ω(n)=n 的 γ=0 特例）
    gamma = opred(beta)
    return OZ if n == 0 else ((gamma, n),)

def fs_eps0(n):                       # ε₀(0)=0，ε₀(n+1)=ω^(ε₀(n))
    return OZ if n == 0 else wexp(fs_eps0(n - 1))

samples = [OMEGA, wexp(nat(2)), wexp(OMEGA), wexp(wexp(OMEGA)),
           oadd(wexp(OMEGA), ((nat(3), 2),)),       # ω^ω + ω³·2
           oadd(wexp(wexp(OMEGA)), wexp(nat(2)))]   # ω^ω^ω + ω²
for a in samples:
    for n in range(6):
        assert olt(fs(a, n), fs(a, n + 1)), "基本序列不严格递增"
        assert olt(fs(a, n + 1), a), "基本序列越过上确界"
print(f"基本序列 {len(samples)} 条样本严格递增且不越界 ✓；ε₀ 链 {show_on(fs_eps0(3))} < {show_on(fs_eps0(4))} ↗ ε₀")
assert olt(oadd(((nat(2), 7),), nat(5)), fs(wexp(nat(3)), 8))   # ω²·7+5 < ω²·8

# ---------- 快速增长层次（定义 1.84） ----------
def F_literal(a, n):                  # 定义的字面实现（F₁ 逐次迭代，慢）
    if not a: return n + 1
    if not is_limit(a):
        x = n
        for _ in range(n): x = F_literal(opred(a), x)
        return x
    return F_literal(fs(a, n), n)

def F(a, n):                          # F₀/F₁ 闭式加速（小范围与字面对拍）
    if not a: return n + 1
    if a == nat(1): return 2 * n
    if not is_limit(a):
        x = n
        for _ in range(n): x = F(opred(a), x)
        return x
    return F(fs(a, n), n)

for k in range(3):
    for n in range(1, 9):
        assert F(nat(k), n) == F_literal(nat(k), n)
for n in range(1, 3):
    assert F(nat(3), n) == F_literal(nat(3), n)
    assert F(OMEGA, n) == F_literal(OMEGA, n)
print("F 与 F_literal 对拍：F₀..F₂（n≤8）、F₃/F_ω（n≤2）完全一致 ✓")

for n in range(1, 7):
    assert F(OZ, n) == n + 1
    assert F(nat(1), n) == 2 * n
    assert F(nat(2), n) == n * 2**n
assert F(nat(3), 1) == 2 and F(nat(3), 2) == 2048
assert F(OMEGA, 1) == 2 and F(OMEGA, 2) == 8
print("F₀(n)=n+1、F₁(n)=2n、F₂(n)=n·2ⁿ ✓；F₃(2)=2048；F_ω(1)=2、F_ω(2)=8 ✓")

f224 = F(nat(2), 24)
assert f224 == 402653184
import math
digits_est = int(402653184 * math.log10(2)) + 1
print(f"F_ω(3) = F₂({f224}) = {f224}·2^{f224}，约 {digits_est} 位——可定义而不可算")

assert all(F(OZ, n) < F(nat(1), n) for n in range(2, 51))
assert all(F(nat(1), n) < F(nat(2), n) for n in range(5, 51))
assert all(n**3 + n < F(nat(2), n) for n in range(7, 51))
print("<* 见证：F₀<*F₁（n≥2）、F₁<*F₂（n≥5）、n³+n <* F₂（n≥7）✓")

# ---------- 古德斯坦剧场（定义 1.86/1.87、定理 1.82） ----------
# HB = ((指数HB, 系数), …)——树里不存基 b；原子常数（<b）与系数（<b）
# 不参与换基，m = b 自然落成 b¹·1（换基即升——与书载 m≤b 原子条款同效）。
def hb_of(b, m):
    if m == 0: return ()
    if m < b: return (((), m),)
    e, p = 0, 1
    while p * b <= m: p, e = p * b, e + 1
    k, r = divmod(m, p)
    return ((hb_of(b, e), k),) + hb_of(b, r)

def hb_eval(h, b):
    return sum(b**hb_eval(e, b) * k for (e, k) in h)

def hb_to_on(h):
    return tuple((hb_to_on(e), k) for (e, k) in h)

# 例 1.29：T₂(37) = 2^{2²+1}+2²+1；原子 2（=b 自身）的影子是 ω
t37 = hb_of(2, 37)
assert hb_eval(t37, 2) == 37
assert hb_to_on(t37) == oadd(wexp(oadd(wexp(OMEGA), nat(1))),
                             oadd(wexp(OMEGA), nat(1)))
print(f"T₂(37) = 2^(2²+1)+2²+1 ✓（影子 {show_on(hb_to_on(t37))}）")

def gstep(b, m):
    if m == 0: return 0
    return hb_eval(hb_of(b, m), b + 1) - 1

# G(3) 全程：五步归零——数字原地踏步，影子一路下山
m, b = 3, 2
chain, shadows = [m], []
while m != 0:
    shadows.append(hb_to_on(hb_of(b, m)))
    m = gstep(b, m)
    b += 1
    chain.append(m)
shadows.append(OZ)
assert chain == [3, 3, 3, 2, 1, 0]
assert all(olt(shadows[k + 1], shadows[k]) for k in range(len(shadows) - 1))
print(f"G(3)：值链 {chain}（5 步归零）")
print(f"  影子链 {' > '.join(show_on(s) for s in shadows)} ——严格下降 ✓")

# G(4) 前八步：数字爆炸与影子下降同框（例 1.30 的微型重演）
m, b = 4, 2
vals, shs = [m], []
for _ in range(8):
    shs.append(hb_to_on(hb_of(b, m)))
    m = gstep(b, m)
    b += 1
    vals.append(m)
assert vals[1] == 26 and vals[2] == 41 and vals[3] == 60
assert all(olt(shs[k + 1], shs[k]) for k in range(len(shs) - 1))
assert hb_to_on(hb_of(2, 4)) == wexp(OMEGA)          # α₀ = ω^ω
print(f"G(4) 前八步值链 {vals} ——一路狂涨")
print(f"  影子：ω^ω > {show_on(shs[1])} > {show_on(shs[2])} > … 一路下降 ✓")

print("END ====")
