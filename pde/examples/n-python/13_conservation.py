# 13_conservation.py —— 第 13 章：守恒律（Python 通道，独立复算）

import math

print("==== 13 conservation")

flux = lambda u: 0.5 * u * u

def conservative_scheme(kind, uL, uR, lam, h, T):
    J = 512
    nst = round(T / (lam * h))
    u = [uL if (j - 1) * h < 0.5 else uR for j in range(1, J + 1)]
    for _ in range(nst):
        un = u[:]
        for j in range(J):
            jp = (j + 1) % J
            jm = (j - 1) % J
            if kind == "lf":
                un[j] = 0.5 * (u[jp] + u[jm]) - 0.5 * lam * (flux(u[jp]) - flux(u[jm]))
            elif kind == "lw":
                uhr = 0.5 * (u[j] + u[jp]) - 0.5 * lam * (flux(u[jp]) - flux(u[j]))
                uhl = 0.5 * (u[jm] + u[j]) - 0.5 * lam * (flux(u[j]) - flux(u[jm]))
                un[j] = u[j] - lam * (flux(uhr) - flux(uhl))
            else:
                if u[j] >= 0:
                    un[j] = u[j] - lam * u[j] * (u[j] - u[jm])
                else:
                    un[j] = u[j] - lam * u[j] * (u[jp] - u[j])
        u = un
    return u

def front_position(u, h):
    J = len(u)
    for j in range(J):
        jp = (j + 1) % J
        if u[j] >= 0.5 > u[jp]:
            frac = (u[j] - 0.5) / (u[j] - u[jp])
            return ((j + frac) * h) % 1.0
    return 0.0

uL, uR = 1.0, 0.0
s_exact = (flux(uL) - flux(uR)) / (uL - uR)
assert s_exact == 0.5
h = 1 / 512
lam, T = 0.4, 0.4

for kind in ("lf", "lw"):
    u = conservative_scheme(kind, uL, uR, lam, h, T)
    pos = front_position(u, h)
    err = abs(pos - (0.5 + s_exact * T))
    assert err < 5 * h, (kind, err)
    print(f"conservative {kind}: shock at {pos:.4f}, exact {0.5 + s_exact * T:.4f} (err {err:.5f})")

u_nc = conservative_scheme("noncons", uL, uR, lam, h, T)
pos_nc = front_position(u_nc, h)
err_nc = abs(pos_nc - (0.5 + s_exact * T))
assert err_nc > 10 * h, err_nc
print(f"non-conservative upwind: shock at {pos_nc:.4f} (err {err_nc:.4f}: WRONG SPEED)")

uL2, uR2 = -1.0, 1.0
T2 = 0.25
u = conservative_scheme("lf", uL2, uR2, lam, h, T2)
maxerr = 0.0
for j in range(len(u)):
    x = (j) * h
    xx = x - 0.5
    if abs(xx) > 0.35:
        continue
    ex = uL2 if xx < -T2 else (uR2 if xx > T2 else xx / T2)
    maxerr = max(maxerr, abs(u[j] - ex))
assert maxerr < 0.12, maxerr
print(f"rarefaction (uL=-1,uR=1): LF matches entropy solution u=x/t, max err = {maxerr:.4f}")

a_of = lambda u: u
def check_entropy(uL, uR):
    return a_of(uL) >= (flux(uR) - flux(uL)) / (uR - uL) >= a_of(uR)

assert check_entropy(1.0, 0.0)
assert not check_entropy(-1.0, 1.0)
print("entropy check: shock (1,0) satisfies a(uL) >= s >= a(uR); (-1,1) does not")

print("END ====")
