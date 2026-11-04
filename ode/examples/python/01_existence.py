print("==== 01 existence")

# 第 01 章：存在唯一性的三组数值实验（Julia 通道的独立复算）。
# 输出纪律：纯 ASCII（python -I 忽略 PYTHONIOENCODING，控制台代码页不可靠）。
import math

# --- (a) Picard 迭代 y' = x + y、y(0)=1 ---
xs = [i * 0.001 for i in range(1001)]
y = [1.0] * len(xs)
truth1 = 2 * math.exp(1) - 2
errs = []
for _ in range(6):
    ynew = [1.0] * len(xs)
    for i, x in enumerate(xs):
        if i == 0:
            ynew[0] = 1.0
            continue
        # 复化梯形：∫₀ˣ (t + y(t)) dt，逐点累积
        s = sum(xs[j] + y[j] for j in range(1, i))
        ynew[i] = 1.0 + 0.001 * (0.5 * (xs[0] + y[0]) + s + 0.5 * (xs[i] + y[i]))
    y = ynew
    errs.append(abs(y[-1] - truth1))
print("Picard errors (round 1..6):", [f"{e:.3e}" for e in errs])
assert errs[5] < 5e-4, "round-6 error ~2.5e-4"
for n in range(1, 6):
    assert errs[n] < errs[n - 1], "errors should decrease (contraction)"

# --- (b) 爆破：y' = y^2、y(1)=1，解析解 1/(2-x) ---
assert 1 / (2 - 1.999) > 500, "solution diverges as x -> 2-"
yv, xv = 1.0, 1.0
h = 1e-4
while yv < 1e12:
    yv += h * yv * yv
    xv += h
assert xv < 2.05, "Euler should blow up numerically near x=2"
print(f"Euler from (1,1) crosses 1e12 at x = {xv:.4f} (true blow-up x=2)")

# --- (c) 非唯一 vs Lipschitz ---
f_nonl = lambda v: math.copysign(abs(v) ** (1 / 3), v)
yv2 = 1e-12
for _ in range(30000):
    yv2 += h * f_nonl(yv2)
assert yv2 > 1.0, "non-Lipschitz: perturbation 1e-12 grows to O(1)"
assert abs(yv2 - 2 ** 1.5) < 0.05, f"should track true solution 2.828, got {yv2}"
print(f"y'=y^(1/3): y0=1e-12 grows to y(3) = {yv2:.4f} (true 2^{1.5:.4f}) -- non-unique")
yv3 = 1e-12
for _ in range(30000):
    yv3 += h * yv3
assert yv3 < 1e-10, "Lipschitz case: perturbation stays exponentially small"
print(f"y'=y (Lipschitz): y0=1e-12 stays at {yv3:.3e} at x=3")

# --- (d) Grönwall 对照账：两条解轨道的分离 ---
delta = 1e-6
separation = delta * math.exp(3)
ya, yb = 1.0, 1.0 + delta
for _ in range(30000):
    ya += h * ya
    yb += h * yb
assert abs((yb - ya) - separation) / separation < 1e-3, "separation ~ delta*e^x"
print(f"orbit separation {yb - ya:.3e} ~ delta*e^3 = {separation:.3e} (Gronwall sharp)")

print("END ====")
