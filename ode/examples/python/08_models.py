print("==== 08 models")

# 第 08 章：一阶模型合集（Julia 的独立复算 + solve_ivp 交叉）。
import math
from scipy.integrate import solve_ivp

# --- (a) 摩擦：总距离 v0·m/k（数值积分 v = v0 e^{-kt/m}） ---
m, k, v0 = 2.0, 3.0, 4.0
T, n = 30.0, 300000
vt = [v0 * math.exp(-k / m * (i * T / n)) for i in range(n + 1)]
total_x = (sum(vt) - 0.5 * (vt[0] + vt[-1])) * (T / n)   # trapezoid
assert abs(total_x - v0 * m / k) < 1e-8
print(f"friction: total distance {total_x:.6f} vs v0*m/k = {v0*m/k:.6f}")

# --- (b) 火箭：单级 5.838 < 11.2，两级 11.675 > 11.2 ---
ve = 3.0
assert abs(ve * math.log(7) - 5.838) < 1e-3
assert 2 * ve * math.log(7) > 11.2
print(f"rocket: single-stage {ve*math.log(7):.3f} km/s, two-stage {2*ve*math.log(7):.3f} km/s")

# --- (c) 冷却 + (d) 半衰期 ---
Tenv, T0, kc = 20.0, 90.0, 0.5
assert abs((T0 - Tenv) * math.exp(-kc * 3 / kc) / (T0 - Tenv) - math.exp(-3)) < 1e-15
lam = math.log(2) / 30
assert abs(math.exp(-lam * 30) - 0.5) < 1e-12
assert abs(math.exp(-lam * 60) - 0.25) < 1e-12
print("cooling: 3 tau -> e^-3 ; decay: 30d -> 1/2, 60d -> 1/4")

# --- (e) 复利三档 ---
S = 100000.0
yearly, monthly, cont = S * 1.06**15, S * (1.005) ** 180, S * math.exp(0.9)
assert abs(yearly - 239655.82) < 0.5
assert abs(cont - 245960.31) < 0.5
assert 6000 < cont - yearly < 6500
print(f"interest: yearly {yearly:.2f}, monthly {monthly:.2f}, continuous {cont:.2f}")

# --- (f) 盐水：solve_ivp 与解析解 V = 6(150-2t)^3/150^3 双核对 ---
Vsol = lambda t: 6 * (150 - 2 * t) ** 3 / 150**3
sol = solve_ivp(lambda t, V: -6 * V / (150 - 2 * t), [0, 60], [6.0],
                rtol=1e-12, atol=1e-14)
assert abs(sol.y[0, -1] - Vsol(60)) < 1e-8
print(f"brine: V(60) = {sol.y[0,-1]:.10f} vs analytic 0.048")

# --- (g) RL：i(τ) = 63.2% ---
E, R, L = 12.0, 4.0, 2.0
tau = L / R
i = lambda t: E / R * (1 - math.exp(-t / tau))
assert abs(i(tau) / (E / R) - (1 - 1 / math.e)) < 1e-12
print(f"RL: i(inf) = {E/R} A, tau = {tau} s, i(tau)/i(inf) = {i(tau)/(E/R):.6f}")

print("END ====")
