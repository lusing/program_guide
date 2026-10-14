# 第 51 章 sin/cos 网格剧场 + 量词 sup/inf 演示
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 51")

import math

# ---------- (a) ⟦sin < cos⟧ 的网格版 ----------
N = 2000
xs = [i * 4 * math.pi / N for i in range(N + 1)]
band = [x for x in xs if math.sin(x) < math.cos(x)]
# 连通分量
segs = []
start = None
for i in range(N):
    a, b = xs[i], xs[i + 1]
    ina = math.sin(a) < math.cos(a)
    inb = math.sin(b) < math.cos(b)
    if ina and not (segs and abs(segs[-1][1] - a) < 1e-12):
        segs.append([a, a])
    if ina:
        segs[-1][1] = b
print(f"(a) sin<cos 的分量数 = {len(segs)}（[0,4π] 内）")
for s in segs:
    print(f"    ({s[0]:.3f}, {s[1]:.3f})")
# 勘误后的理论带：(−3π/4+2kπ, π/4+2kπ)
import fractions
ok = (abs(segs[0][0] - 0) < 0.01 and abs(segs[0][1] - math.pi/4) < 0.01
      and abs(segs[1][0] - 5*math.pi/4) < 0.01 and abs(segs[1][1] - 9*math.pi/4) < 0.01)
assert ok
print("    与 (0,π/4)、(5π/4,9π/4) 吻合 ✓（Viale 符号乱码的数值勘误）")

# ---------- (b) 裁决剧场 ----------
x0 = math.pi / 4
for d in (0.05, 0.01, 1e-4):
    assert math.sin(x0 - d) < math.cos(x0 - d)
    assert math.sin(x0 + d) > math.cos(x0 + d)
print("(b) π/4 两侧各执一词（δ→0 亦然）——邻域滤子不裁决，超滤裁决 ✓")

# ---------- (c) 量词 = sup/inf ----------
# ⟦∃x φ(x)⟧ = ⋁_x ⟦φ(x)⟧；⟦∀x ψ(x)⟧ = ⋀_x ⟦ψ(x)⟧
phi = [1.0 if math.sin(x) > 0.5 else 0.0 for x in xs]
psi = [1.0 - abs(math.sin(x)**2 + math.cos(x)**2 - 1) for x in xs]
assert max(phi) == 1.0
assert min(psi) > 1 - 1e-9
print(f"(c) ⟦∃x φ⟧ = max = {max(phi):.0f}；⟦∀x ψ⟧ = min = {min(psi):.6f} → 1 ✓")
print("    量词在稠密域上被 sup/inf 逼近——RO(B) 补全的数值直觉")

print("END ====")
