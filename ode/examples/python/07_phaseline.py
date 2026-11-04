print("==== 07 phaseline")

# 第 07 章：相线（Julia 的独立复算 + 相线构造器）。
import math

def rk4(f, y, h):
    k1 = f(y)
    k2 = f(y + h * k1 / 2)
    k3 = f(y + h * k2 / 2)
    k4 = f(y + h * k3)
    return y + h * (k1 + 2 * k2 + 2 * k3 + k4) / 6

def integrate_to(f, y0, T, n=24000):
    y, h = y0, T / n
    for _ in range(n):
        y = rk4(f, y, h)
    return y

# --- (a) 相线构造器：扫描求平衡点 + 区间符号 ---
def build_phaseline(f, lo, hi, n=4000):
    roots = []
    xs = [lo + (hi - lo) * i / n for i in range(n + 1)]
    for i in range(n):
        a, b = xs[i], xs[i + 1]
        fa, fb = f(a), f(b)
        if abs(fa) < 1e-14:
            roots.append(a)
        elif fa * fb < 0:
            # bisection
            for _ in range(60):
                m = (a + b) / 2
                if f(a) * f(m) <= 0:
                    b = m
                else:
                    a = m
            roots.append((a + b) / 2)
    return roots

f29 = lambda y: y * (y - 1)
roots = build_phaseline(f29, -0.5, 1.5, 400)
assert abs(roots[0]) < 1e-4 and abs(roots[1] - 1) < 1e-4, roots
print(f"phaseline constructor: equilibria of y(y-1) at {[round(r,6) for r in roots]}")

# 符号区间
assert f29(-0.5) > 0 and f29(0.5) < 0 and f29(1.5) > 0
print("signs: y<0 up, 0<y<1 down, y>1 up  =>  0 sink, 1 source")

# --- (b) 轨道核对 ---
assert abs(integrate_to(f29, 0.3, 12)) < 1e-4
assert abs(integrate_to(f29, -0.2, 12)) < 1e-4
assert integrate_to(f29, 1.3, 12) > 1e5
print("orbits: 0.3/-0.2 -> 0 (sink), 1.3 escapes (source)")

# --- (c) y' = -y^3 的幂式收敛 ~ 1/sqrt(2t) ---
f31 = lambda y: -y**3
ys = integrate_to(f31, 0.5, 200.0, n=400000)
assert abs(ys - 1 / math.sqrt(400)) < 0.02
print(f"y' = -y^3: y(200) = {ys:.4f} ~ 1/sqrt(2t) = {1/math.sqrt(400):.4f} (algebraic decay)")

# --- (d) y' = 2y^2 爆破时刻 t* = 1/(k y0) ---
yv, tv, hstep = 1.0, 0.0, 1e-5
while yv < 1e10 and tv < 1.0:
    yv += hstep * 2 * yv * yv
    tv += hstep
assert abs(tv - 0.5) < 0.01
print(f"y' = 2y^2, y(0)=1: numerical blow-up at t = {tv:.4f} (exact 0.5)")

print("END ====")
