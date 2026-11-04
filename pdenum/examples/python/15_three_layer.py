# 15_three_layer.py —— 第 15 章：Richardson/DFF/跳点（Python 通道，独立复算）

import math

print("==== 15 three layer")

def richardson_run(r, nst):
    J = 64
    h = 1.0 / J
    u_prev = [math.sin(math.pi * j * h) for j in range(1, J)]
    u = u_prev[:]
    for _ in range(nst):
        u_new = u[:]
        for j in range(J - 1):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 2 else u[j + 1]
            u_new[j] = u_prev[j] + 2 * r * (ul - 2 * u[j] + ur)
        u_prev, u = u, u_new
        if max(abs(v) for v in u) > 1e6:
            return 1e6
    return max(abs(v) for v in u)

assert richardson_run(0.3, 60) > 1e3
print("Richardson at r=0.3: blows up (unconditionally unstable)")

def dff_run(r, h, T):
    J = round(1.0 / h)
    tau = r * h * h
    nst = round(T / tau)
    u_prev = [math.sin(math.pi * j * h) for j in range(1, J)]
    u = [u_prev[j] + r * ((0.0 if j == 0 else u_prev[j - 1]) - 2 * u_prev[j]
                          + (0.0 if j == J - 2 else u_prev[j + 1])) for j in range(J - 1)]
    for _ in range(2, nst + 1):
        u_new = u[:]
        for j in range(J - 1):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 2 else u[j + 1]
            u_new[j] = ((1 - 2 * r) * u_prev[j] + 2 * r * (ul + ur)) / (1 + 2 * r)
        u_prev, u = u, u_new
    return u, nst * tau

h15 = 0.01
u, tf = dff_run(5.0, h15, 0.4)
J = round(1.0 / h15)
err = max(abs(u[j] - math.exp(-math.pi**2 * tf) * math.sin(math.pi * (j + 1) * h15))
          for j in range(J - 1))
assert err < 0.01, err
print(f"DFF at r=5 (dead zone of FTCS/Richardson): stable, err = {err:.4g}")

def dff_fixed_beta(beta, h, T):
    J = round(1.0 / h)
    tau = beta * h
    nst = round(T / tau)
    r = tau / h**2
    u_prev = [math.sin(math.pi * j * h) for j in range(1, J)]
    u = [u_prev[j] + r * ((0.0 if j == 0 else u_prev[j - 1]) - 2 * u_prev[j]
                          + (0.0 if j == J - 2 else u_prev[j + 1])) for j in range(J - 1)]
    for _ in range(2, nst + 1):
        u_new = u[:]
        for j in range(J - 1):
            ul = 0.0 if j == 0 else u[j - 1]
            ur = 0.0 if j == J - 2 else u[j + 1]
            u_new[j] = ((1 - 2 * r) * u_prev[j] + 2 * r * (ul + ur)) / (1 + 2 * r)
        u_prev, u = u, u_new
    return u, nst * tau

errs = []
for h in (0.04, 0.02, 0.01):
    u, tf = dff_fixed_beta(0.5, h, 0.4)
    J = round(1.0 / h)
    e = max(abs(u[j] - math.exp(-math.pi**2 * tf) * math.sin(math.pi * (j + 1) * h))
            for j in range(J - 1))
    errs.append(e)
print(f"DFF with tau/h = 0.5 fixed: errors = {[round(e, 4) for e in errs]} (stuck)")
assert errs[2] > 0.05

def hopscotch_run(r, h, T):
    J = round(1.0 / h)
    tau = r * h * h
    nst = round(T / tau)
    u = [math.sin(math.pi * j * h) for j in range(1, J)]
    for n in range(nst):
        u_new = u[:]
        for j in range(J - 1):
            if (n + j + 1) % 2 == 0:
                ul = 0.0 if j == 0 else u[j - 1]
                ur = 0.0 if j == J - 2 else u[j + 1]
                u_new[j] = u[j] + r * (ul - 2 * u[j] + ur)
        for j in range(J - 1):
            if (n + j + 1) % 2 == 1:
                ul = 0.0 if j == 0 else u_new[j - 1]
                ur = 0.0 if j == J - 2 else u_new[j + 1]
                u_new[j] = (u[j] + r * (ul + ur)) / (1 + 2 * r)
        u = u_new
    return u, nst * tau

uh, tfh = hopscotch_run(5.0, 0.01, 0.4)
ud, tfd = dff_run(5.0, 0.01, 0.4)
maxdiff = max(abs(a - b) for a, b in zip(uh, ud))
assert maxdiff < 1.0, maxdiff
print(f"hopscotch vs DFF trajectory: max diff = {maxdiff} (equivalent schemes)")

print("END ====")
