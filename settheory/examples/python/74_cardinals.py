# 第 74 章：基数：和、积与典型秩序（冯琦 §1.9）——Python 通道
# 与 74_cardinals.jl 同构：典型秩序与 gsq 方块层数、Gödel 配对双射
# （ℕ² ≅ ℕ：ℵ₀·ℵ₀ = ℵ₀ 的构造性身影）、ℵ 序列符号演算与 max 规则
# 引擎（推论 1.13）、aleph 不动点链（定理 1.91(2) 的程序版）。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 74")

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

def omul(a, b):
    if not a or not b: return OZ
    if b == nat(1): return a
    if a == nat(1): return b
    (ea, ca), (eb, cb) = a[0], b[0]
    if len(a) == 1 and ea == OZ and len(b) == 1 and eb == OZ:
        return ((OZ, ca * cb),)
    restb = b[1:]
    if len(a) == 1 and ea == OZ:
        return oadd(((eb, cb),), omul(a, restb))
    if eb == OZ:
        r = OZ
        for _ in range(cb): r = oadd(r, a)
        return r
    head = ((oadd(ea, eb), cb),)
    if not restb: return head
    return head + omul(a, restb)

def show_on(a):
    parts = []
    for (e, c) in a:
        es = "0" if e == OZ else ("" if e == nat(1) else "(" + show_on(e) + ")")
        parts.append(f"ω{es}" if c == 1 else f"ω{es}·{c}")
    return "+".join(parts) if parts else "0"

# ---------- 方块层数 gsq（定理 1.92：方块=前段的序型读法） ----------
def gsq(m): return nat(m * m)                    # 有限：m²
def gsq_omega(): return OMEGA                    # gsq(ω) = ω ★坍缩点
def gsq_omega_plus(n): return oadd(omul(OMEGA, nat(2 * n + 1)), nat(n * n))

print("gsq：有限段 m²、gsq(ω) = ω（坍缩点 ★）、gsq(ω+n) = ω·(2n+1)+n²")
print(f"  gsq(ω+1) = {show_on(gsq_omega_plus(1))}、gsq(ω+5) = {show_on(gsq_omega_plus(5))}"
      " ——离开初始序数就涨（ℵ·ℵ=ℵ 只钉在初始序数上）")

# ---------- Gödel 编码 Γ（定义 1.98）：典型序下的名次 ----------
def gpair(a, b):
    m = max(a, b)
    if a < m: return m * m + a
    if b < m: return m * m + m + b
    return m * m + 2 * m

def gunpair(p):
    m = int(p**0.5)
    while (m + 1) ** 2 <= p: m += 1
    while m * m > p: m -= 1
    t = p - m * m
    if t < m: return (t, m)
    if t < 2 * m: return (m, t - m)
    return (m, m)

for p in range(2000):
    assert gpair(*gunpair(p)) == p
seen = {gpair(a, b) for a in range(12) for b in range(12)}
assert len(seen) == 144
for m in range(1, 13):
    assert sorted(gpair(a, b) for a in range(m) for b in range(m)) == list(range(m * m))
print("Γ 配对：0..1999 往返恒等 ✓、12×12 网格单射 ✓、m×m 方块=前段 0..m²−1（m≤12）✓")
print(f"  样例：Γ(2,5) = {gpair(2,5)}、Γ(5,2) = {gpair(5,2)}、Γ(3,3) = {gpair(3,3)}")

def gpair_on(a, b):
    af = not a or (len(a) == 1 and a[0][0] == OZ)
    bf = not b or (len(b) == 1 and b[0][0] == OZ)
    assert af and bf, "gpair_on: 演示范围为有限序数对"
    an = a[0][1] if a else 0
    bn = b[0][1] if b else 0
    return nat(gpair(an, bn))

assert gpair_on(nat(3), nat(7)) == nat(52)
assert gpair_on(nat(7), nat(3)) == nat(59)
assert gpair_on(nat(7), nat(7)) == nat(63)
print("Γ 序数版（有限截面）：Γ(3,7)=52、Γ(7,3)=59、Γ(7,7)=63 ✓")

# ---------- ℵ 序列符号演算器（定义 1.93）与 max 规则（推论 1.13） ----------
class FCard:
    def __init__(self, n): self.n = n
    def __eq__(self, o): return isinstance(o, FCard) and self.n == o.n
class Aleph:
    def __init__(self, alpha): self.alpha = alpha
    def __eq__(self, o): return isinstance(o, Aleph) and self.alpha == o.alpha

def show_sc(k):
    if isinstance(k, FCard): return str(k.n)
    if k.alpha == OMEGA: return "ℵ_ω"
    if not k.alpha: return "ℵ_0"
    if len(k.alpha) == 1 and k.alpha[0][0] == OZ: return f"ℵ_{k.alpha[0][1]}"
    return "ℵ_(" + show_on(k.alpha) + ")"

def sclt(a, b):
    if isinstance(a, Aleph) and isinstance(b, FCard): return False
    if isinstance(a, FCard) and isinstance(b, Aleph): return True
    if isinstance(a, FCard): return a.n < b.n
    return olt(a.alpha, b.alpha)

def cadd(a, b):
    if isinstance(a, FCard) and isinstance(b, FCard): return FCard(a.n + b.n)
    return b if sclt(a, b) else a
def cmul(a, b):
    if isinstance(a, FCard) and isinstance(b, FCard): return FCard(a.n * b.n)
    return b if sclt(a, b) else a

print("max 规则引擎（推论 1.13）样例：")
print("  ℵ₂ + ℵ₀ =", show_sc(cadd(Aleph(nat(2)), Aleph(OZ))))
print("  ℵ_ω · ℵ₃ =", show_sc(cmul(Aleph(OMEGA), Aleph(nat(3)))))
print("  (ℵ₂ + ℵ₁) · ℵ₀ =", show_sc(cmul(cadd(Aleph(nat(2)), Aleph(nat(1))), Aleph(OZ))))
print("  有限退化：3 + 7 =", show_sc(cadd(FCard(3), FCard(7))), "、3 · 7 =", show_sc(cmul(FCard(3), FCard(7))))
assert cadd(Aleph(nat(2)), Aleph(OZ)) == Aleph(nat(2))
assert cmul(Aleph(OMEGA), Aleph(nat(3))) == Aleph(OMEGA)
assert cmul(cadd(Aleph(nat(2)), Aleph(nat(1))), Aleph(OZ)) == Aleph(nat(2))

# ---------- aleph 不动点链（定理 1.91(2) 的程序版） ----------
def show_chain(k): return "ℵ₀" if k == 0 else "ℵ_{%s}" % show_chain(k - 1)
for n in range(5):
    note = "  = ℵ_ω（第一个奇异基数，例 1.33）" if n == 1 else ""
    print(f"  κ_{n} = {show_chain(n)}{note}")
print("  …sup_n κ_n = λ 满足 ℵ_λ = λ——任意大的 aleph 不动点（定理 1.91(2)）")

print("END ====")
