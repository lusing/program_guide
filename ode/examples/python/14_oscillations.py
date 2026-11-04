print("==== 14 oscillations")

# 第 14 章：振动（Julia 的独立复算 + solve_ivp 长时积分）。
import math
from scipy.integrate import solve_ivp

# (a) 三种阻尼形态：solve_ivp 长积分
def final_state(delta, w0=1.0, T=30.0):
    sol = solve_ivp(lambda t, u: [u[1], -2 * delta * u[1] - w0**2 * u[0]],
                    [0, T], [1.0, 0.0], rtol=1e-11, atol=1e-13, dense_output=True)
    return sol

sol_u = final_state(0.2)
# 过零计数：欠阻尼应 ≥ 3
ts = np_ts = sol_u.t
ys = sol_u.y[0]
zeros = sum(1 for i in range(len(ys) - 1) if ys[i] * ys[i + 1] < 0)
assert zeros >= 3, "underdamped should oscillate"
assert abs(ys[-1]) < 0.01
print(f"underdamped (delta=0.2): {zeros} zero crossings, y(30) = {ys[-1]:.2e}")

sol_c = final_state(1.0)
sol_o = final_state(2.0)
ys_c, ys_o = sol_c.y[0][-1], sol_o.y[0][-1]
zc = sum(1 for i in range(len(sol_c.y[0]) - 1) if sol_c.y[0][i] * sol_c.y[0][i + 1] < 0)
assert zc == 0
assert abs(ys_o) > abs(ys_c), "overdamped slower than critical"
print(f"critical |y(30)| = {abs(ys_c):.2e} < overdamped |y(30)| = {abs(ys_o):.2e}")

# (b) 包络衰减：相邻峰比 e^{-delta T}
delta, w0 = 0.2, 1.0
T = 2 * math.pi / math.sqrt(w0**2 - delta**2)
sol = final_state(delta, T=6 * T + 1e-9)
ys = sol.y[0]
ts = sol.t
peaks = [max(abs(y) for y, t in zip(ys, ts)
             if abs(t - k * T - T / 4) < T / 8) for k in range(6)]
for i in range(1, 6):
    assert abs(peaks[i] / peaks[i - 1] - math.exp(-delta * T)) < 0.05
print(f"envelope: peak ratio ~ e^(-dT) = {math.exp(-delta*T):.4f} (5 checks)")

# (c) 频率响应解析：X(w) 峰值与带宽
X = lambda w, dlt, w00: 1.0 / math.sqrt((w00**2 - w**2) ** 2 + (2 * dlt * w) ** 2)
dlt, w00 = 0.15, 1.0
wr = math.sqrt(w00**2 - 2 * dlt**2)
Xmax = X(wr, dlt, w00)
# 半功率点：X = Xmax/sqrt(2)，近似带宽 2*delta
# 半功率点：X = Xmax/sqrt(2)，二分求精确位置，带宽 ≈ 2*delta
target = Xmax / math.sqrt(2)

def bisect_half(sign):
    lo, hi = (0.5, wr) if sign < 0 else (wr, 1.5)
    for _ in range(80):
        mid = (lo + hi) / 2
        if (X(mid, dlt, w00) > target) == (sign < 0):
            hi = mid
        else:
            lo = mid
    return (lo + hi) / 2

w_lo, w_hi = bisect_half(-1), bisect_half(+1)
assert abs((w_hi - w_lo) - 2 * dlt) < 0.1 * 2 * dlt, "bandwidth ~ 2*delta"
print(f"response: peak at wr = {wr:.4f}, half-power bandwidth = {w_hi - w_lo:.4f} ~ 2*delta = {2*dlt}")

# (d) RLC 数字例：L=0.1, C=1e-3, R=2 ⟹ w0=100, delta=10, Q=5
L, C, R = 0.1, 1e-3, 2.0
w0r = 1 / math.sqrt(L * C)
dr = R / (2 * L)
Q = w0r / (2 * dr)
assert w0r == 100.0 and dr == 10.0 and Q == 5.0
wr_rlc = math.sqrt(w0r**2 - 2 * dr**2)
assert abs(wr_rlc - 98.99494936611666) < 1e-9
print(f"RLC: w0 = 100, delta = 10, Q = 5, wr = {wr_rlc:.5f}")

# (e) 稳态相位差：solve_ivp 长时积分，φ = atan(2δw/(w0²-w²))
w = 0.7
sol = solve_ivp(lambda t, u: [u[1], -2 * dlt * u[1] - w00**2 * u[0] + math.cos(w * t)],
                [0, 200], [0.0, 0.0], rtol=1e-11, atol=1e-13)
# 稳态段取最后的峰时刻与驱动相位比较（粗核对幅值即可）
tail = sol.y[0][-5000:]
amp = max(abs(v) for v in tail)
assert abs(amp - X(w, dlt, w00)) < 0.02 * X(w, dlt, w00)
print(f"steady amplitude at w=0.7: numeric {amp:.4f} vs analytic {X(w, dlt, w00):.4f}")

print("END ====")
