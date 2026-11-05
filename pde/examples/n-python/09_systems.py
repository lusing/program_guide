# 09_systems.py —— 第 09 章：一阶方程组与变系数双曲（Python 通道，独立复算）

import math

print("==== 09 systems")

g = lambda x: math.exp(-100 * (x - 0.5) ** 2)
gc = lambda x: math.exp(-25 * (x - 0.5) ** 2)

def exact_acoustics(x, t, gfun):
    gm = gfun(((x - t) % 1.0 + 1.0) % 1.0)
    gp = gfun(((x + t) % 1.0 + 1.0) % 1.0)
    return (0.5 * (gm + gp), 0.5 * (gm - gp))

def acoustics_scheme(kind, lam, h, T, gfun):
    J = round(1.0 / h)
    nst = round(T / (lam * h))
    p = [gfun((j - 1) * h) for j in range(J)]
    u = [0.0] * J
    for _ in range(nst):
        pn = p[:]
        un = u[:]
        for j in range(J):
            jm = J - 1 if j == 0 else j - 1
            jp = 0 if j == J - 1 else j + 1
            if kind == "upwind":
                wp, wm = p[j] + u[j], p[j] - u[j]
                wpm, wmm = p[jm] + u[jm], p[jp] - u[jp]
                wpn = wp - lam * (wp - wpm)
                wmn = wm + lam * (wmm - wm)
                pn[j] = 0.5 * (wpn + wmn)
                un[j] = 0.5 * (wpn - wmn)
            elif kind == "lf":
                pn[j] = 0.5 * (p[jp] + p[jm]) - 0.5 * lam * (u[jp] - u[jm])
                un[j] = 0.5 * (u[jp] + u[jm]) - 0.5 * lam * (p[jp] - p[jm])
            else:
                pn[j] = (p[j] - 0.5 * lam * (u[jp] - u[jm])
                         + 0.5 * lam**2 * (p[jp] - 2 * p[j] + p[jm]))
                un[j] = (u[j] - 0.5 * lam * (p[jp] - p[jm])
                         + 0.5 * lam**2 * (u[jp] - 2 * u[j] + u[jm]))
        p, u = pn, un
    return p, u

h, lam, T = 0.01, 0.8, 0.5
J = round(1.0 / h)
tf = round(T / (lam * h)) * lam * h
errs = {}
for kind in ("upwind", "lf", "lw"):
    p, u = acoustics_scheme(kind, lam, h, T, g)
    err = 0.0
    for j in range(J):
        pe, ue = exact_acoustics((j - 1) * h, tf, g)
        err = max(err, abs(p[j] - pe), abs(u[j] - ue))
    errs[kind] = err
    print(f"acoustics {kind:8s} max error = {err:.4g}")
assert errs["lf"] > errs["lw"]
assert errs["upwind"] < errs["lf"]

def acoustics_err(kind, h):
    lam2, T2 = 0.8, 0.5
    nst = round(T2 / (lam2 * h))
    tf2 = nst * lam2 * h
    p, u = acoustics_scheme(kind, lam2, h, T2, gc)
    J = round(1.0 / h)
    err = 0.0
    for j in range(J):
        pe, ue = exact_acoustics((j - 1) * h, tf2, gc)
        err = max(err, abs(p[j] - pe), abs(u[j] - ue))
    return err

r_up = acoustics_err("upwind", 2.0e-2) / acoustics_err("upwind", 1.0e-2)
r_lw = acoustics_err("lw", 2.0e-2) / acoustics_err("lw", 1.0e-2)
assert 1.5 < r_up < 2.5, r_up
assert 3.0 < r_lw < 4.7, r_lw
print(f"convergence: system upwind ratio = {r_up:.3f} (1st), system lw ratio = {r_lw:.3f} (2nd)")

# ---------- 变系数 ----------
avec = lambda x: 1 + 0.5 * math.sin(2 * math.pi * x)

def char_back(x_target, t_target, nstep):
    x = x_target
    dt = -t_target / nstep
    for _ in range(nstep):
        k1 = -avec(x)
        k2 = -avec(x + 0.5 * dt * k1)
        k3 = -avec(x + 0.5 * dt * k2)
        k4 = -avec(x + dt * k3)
        x += dt * (k1 + 2 * k2 + 2 * k3 + k4) / 6
        x %= 1.0
    return x

def varcoef_upwind(h, tau, T):
    J = round(1.0 / h)
    nst = round(T / tau)
    u = [g((j - 1) * h) for j in range(J)]
    for _ in range(nst):
        un = u[:]
        for j in range(J):
            xj = (j - 1) * h
            aj = avec(xj)
            lam_j = aj * tau / h
            if aj >= 0:
                jm = J - 1 if j == 0 else j - 1
                un[j] = u[j] - lam_j * (u[j] - u[jm])
            else:
                jp = 0 if j == J - 1 else j + 1
                un[j] = u[j] - lam_j * (u[jp] - u[j])
        u = un
        if max(abs(v) for v in u) > 1e6:
            return u
    return u

h = 0.002
amax = max(avec(j * h) for j in range(round(1 / h) + 1))
tau = 0.6 * h / amax
u = varcoef_upwind(h, tau, 0.5)
probes = [round(0.3 / h), round(0.7 / h), round(0.52 / h)]
maxerr = 0.0
for jj in probes:
    x0 = char_back(jj * h, 0.5, 2000)
    maxerr = max(maxerr, abs(u[jj] - g(x0)))
assert maxerr < 0.05, maxerr
print(f"variable-coefficient upwind vs characteristic (RK4): max error = {maxerr:.4g}")

tau = 1.3 * h / 1.5
u = varcoef_upwind(h, tau, 2.0)
assert max(abs(v) for v in u) > 10, "frozen-coeff violation should grow"
print(f"frozen-coeff violated (max a * lam = 1.3): max|u| = {max(abs(v) for v in u):.4g} (growth)")

print("END ====")
