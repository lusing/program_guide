# 第 53 章 泛型读出剧场：同一名字、不同 G、不同集合
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 53")

# ---------- 钻石代数 ----------
D0, DU, DV, D1 = "d0", "du", "dv", "d1"

MEET = {
    (D0, _): D0 for _ in (D0, DU, DV, D1)
}
def meet(a, b):
    if a == D0 or b == D0: return D0
    if a == D1: return b
    if b == D1: return a
    return a if a == b else D0

def join(a, b):
    if a == D1 or b == D1: return D1
    if a == D0: return b
    if b == D0: return a
    return a if a == b else D1

def bnot(a):
    return {D0: D1, D1: D0, DU: DV, DV: DU}[a]

# ---------- 名字：[(子名标签, 真值)] 的有限表 ----------
# τ2 = {ξ_u ↦ du, ξ_v ↦ dv}：双标签名
tau2 = [(DU, "ξ_u"), (DV, "ξ_v")]
# check 名：ǔ = {(v̌, 1)}
check_1 = [(D1, "∅̌")]

# ---------- G-读出：τ_G = {ξ_G : τ(ξ) ∈ G} ----------
def readout(tau, G):
    return [name for (b, name) in tau if b in G]

G_u = {DU, D1}   # 主超滤 ↑du
G_v = {DV, D1}   # 主超滤 ↑dv

print("(a) 双标签名 τ = {ξ_u↦du, ξ_v↦dv}")
print(f"    τ_Gu 读出 = {readout(tau2, G_u)}（du 分量被激活）")
print(f"    τ_Gv 读出 = {readout(tau2, G_v)}（dv 分量被激活）")
assert readout(tau2, G_u) == ["ξ_u"]
assert readout(tau2, G_v) == ["ξ_v"]
print("    ——泛型多读性：M[G_u] ≠ M[G_v]，同一图纸两种实现 ✓")

# ---------- check 名复原 ----------
print("(b) check 名：ǔ = {(∅̌, 1)}")
for G in (G_u, G_v):
    assert readout(check_1, G) == ["∅̌"]
print("    ǔ_G = u 在两个超滤下都成立（check 名的 G-无关性）✓")

# ---------- ⟦τ ∈ σ⟧ 的数值 ----------
def in_val(tau, sigma, G):
    # ⋁_{ξ∈dom σ} σ(ξ) ∧ ⟦τ = ξ⟧（单层 toy：直接比较标签）
    acc = D0
    for (b, xi) in sigma:
        acc = join(acc, meet(b, D1 if (b, xi) in tau else b))
    return acc

t_du = [(DU, "a")]
t_dv = [(DV, "a")]
assert in_val(t_du, t_du, G_u) == DU
print("(c) ⟦tagged du ∈ tagged du⟧ = du（真值可以是中间值）✓")
assert meet(DU, DV) == D0
print("    ⟦du 分量 ∩ dv 分量⟧ = 0：泛型读出的互斥性 ✓")

print("END ====")
