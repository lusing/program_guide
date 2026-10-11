import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(3838)
print("==== 38 topologies_bh (Python) ====")
# B(H) 拓扑层级：范数 ⊃ 强(SOT) ⊃ 弱算子(WOT)
# 单侧移位 S 的幂：SOT 发散（保范），WOT 收敛到 0
m, pad = 300, 60
x = np.zeros(m + pad)
x[: m - pad] = rng.standard_normal(m - pad) * np.exp(-np.arange(1, m - pad + 1) / 20)
y = rng.standard_normal(m + pad) * np.exp(-np.arange(1, m + pad + 1) / 20)

def shift(v, k):
    return np.concatenate([np.zeros(k), v[:-k]])

print("移位幂序列 Sᵏ（SOT vs WOT）：")
for k in [10, 30, 60]:
    Sk = shift(x, k)
    print(f"  k = {k} : ‖Sᵏx‖ = {np.linalg.norm(Sk):.6f}  |⟨Sᵏx,y⟩| = {abs(np.vdot(Sk, y)):.8f}")
assert abs(np.linalg.norm(shift(x, 30)) - np.linalg.norm(x)) < 1e-12
assert abs(np.vdot(shift(x, 60), y)) < abs(np.vdot(shift(x, 10), y)) / 2
print("‖Sᵏx‖ 不变（SOT 不收敛 0）而 ⟨Sᵏx,y⟩ → 0（WOT → 0）：✓")

# 秩一投影 Pₖ = eₖeₖ*：SOT → 0 但范数恒 1
N = 1000
xd = 1.0 / np.arange(1, N + 1)
xd = xd / np.linalg.norm(xd)
for k in [10, 100, 1000]:
    print(f"  ‖P_{k} x‖ = {abs(xd[k - 1]):.6f}，但 ‖P_{k}‖ = 1")
assert abs(xd[999]) < abs(xd[9]) < 0.5
print("SOT 收敛到 0 未必范数收敛：✓")
print("==== 38 topologies_bh END ====")
