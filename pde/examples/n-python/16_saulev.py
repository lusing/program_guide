# 16_saulev.py —— 第 16 章：边界/Saul'ev/GE（Python 通道，独立复算）

import math

print("==== 16 saulev")

def neumann_bc_err(J, order):
    h = 1.0 / J
    r = 0.45
    tau = r * h * h
    nst = round(0.5 / tau)
    u = [math.cos(math.pi * j * h / 2) for j in range(J + 1)]
    for _ in range(nst):
        un = u[:]
        for j in range(1, J):
            un[j] = u[j] + r * (u[j - 1] - 2 * u[j] + u[j + 1])
        if order == 1:
            un[0] = un[1]
        else:
            un[0] = u[0] + r * (2 * u[1] - 2 * u[0])
        un[J] = 0.0
        u = un
    tf = nst * tau
    return max(abs(u[j] - math.exp(-math.pi**2 * tf / 4) * math.cos(math.pi * j * h / 2))
               for j in range(J + 1))

e40a = neumann_bc_err(40, 1)
e40b = neumann_bc_err(40, 2)
print(f"1st-order BC err(40) = {e40a:.5f}; 2nd-order BC err(40) = {e40b:.6f}")
assert e40b < e40a
print(f"boundary treatment matters globally: ratio = {e40b/e40a:.3f}")

def saulev(r, h, T):
    J = round(1.0 / h)
    tau = r * h * h
    nst = round(T / tau)
    u = [math.sin(math.pi * j * h) for j in range(J + 1)]
    for n in range(1, nst + 1):
        un = u[:]
        un[0] = 0.0
        un[J] = 0.0
        if n % 2 == 1:
            for j in range(1, J):
                un[j] = ((1 - r) * u[j] + r * u[j + 1] + r * un[j - 1]) / (1 + r)
        else:
            for j in range(J - 1, 0, -1):
                un[j] = ((1 - r) * u[j] + r * u[j - 1] + r * un[j + 1]) / (1 + r)
        u = un
    return u, nst * tau

us, tfs = saulev(5.0, 0.01, 0.4)
errs = max(abs(us[j] - math.exp(-math.pi**2 * tfs) * math.sin(math.pi * j * 0.01))
           for j in range(101))
assert errs < 0.03, errs
print(f"Saul'ev r=5: err = {errs:.5f} (unconditionally stable, no linear systems)")

def ge(r, h, T):
    J = round(1.0 / h)
    tau = r * h * h
    nst = round(T / tau)
    u = [math.sin(math.pi * j * h) for j in range(J + 1)]
    for _ in range(nst):
        un = u[:]
        un[0] = 0.0
        un[J] = 0.0
        j = 1
        while j + 2 <= J:
            a, b, cc, d = u[j - 1], u[j], u[j + 1], u[j + 2]
            un[j] = (r * (1 + r) * a + (1 - r * r) * b + r * (1 - r) * cc + r * r * d) / (1 + 2 * r)
            un[j + 1] = (r * r * a + r * (1 - r) * b + (1 - r * r) * cc + r * (1 + r) * d) / (1 + 2 * r)
            j += 2
        if j < J:
            un[j] = ((1 - r) * u[j] + r * u[j - 1] + r * u[j + 1]) / (1 + r)
        u = un
    return u, nst * tau

ug, tfg = ge(0.45, 0.01, 0.4)
errg = max(abs(ug[j] - math.exp(-math.pi**2 * tfg) * math.sin(math.pi * j * 0.01))
           for j in range(101))
assert errg < 0.02, errg
print(f"GE r=0.45: err = {errg:.5f} (grouped explicit)")

print("END ====")
