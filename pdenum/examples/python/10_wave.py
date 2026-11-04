# 10_wave.py —— 第 10 章：波动方程差分格式（Python 通道，独立复算）

import math

print("==== 10 wave")

def wave_solve(h, lam, T, start_order):
    J = round(1.0 / h)
    tau = lam * h
    nst = round(T / tau)
    u0 = [math.sin(2 * math.pi * (j - 1) * h) for j in range(J)]
    u1 = [0.0] * J
    for j in range(J):
        jm = J - 1 if j == 0 else j - 1
        jp = 0 if j == J - 1 else j + 1
        if start_order == 1:
            u1[j] = u0[j]
        else:
            u1[j] = u0[j] + 0.5 * lam**2 * (u0[jp] - 2 * u0[j] + u0[jm])
    up, uc = u0[:], u1[:]
    for _ in range(2, nst + 1):
        un = uc[:]
        for j in range(J):
            jm = J - 1 if j == 0 else j - 1
            jp = 0 if j == J - 1 else j + 1
            un[j] = 2 * uc[j] - up[j] + lam**2 * (uc[jp] - 2 * uc[j] + uc[jm])
        up = uc[:]
        uc = un
        if max(abs(v) for v in uc) > 1e8:
            return uc, nst
    return uc, nst

def wave_err(h, start_order):
    lam, T = 0.8, 0.5
    u, nst = wave_solve(h, lam, T, start_order)
    tf = nst * lam * h
    J = round(1.0 / h)
    uex = [math.sin(2 * math.pi * (j - 1) * h) * math.cos(2 * math.pi * tf) for j in range(J)]
    return max(abs(a - b) for a, b in zip(u, uex))

e1, e2 = wave_err(2.0e-2, 2), wave_err(1.0e-2, 2)
r2 = e1 / e2
assert 3.5 < r2 < 4.5, r2
print(f"wave explicit (2nd-order start): h->h/2 error ratio = {r2:.3f}")

e1a, e2a = wave_err(2.0e-2, 1), wave_err(1.0e-2, 1)
r1 = e1a / e2a
assert 1.7 < r1 < 2.4, r1
assert e2 < e2a
print(f"wave 1st-order start (4.12): ratio = {r1:.3f} (1st order)")
print(f"wave 2nd-order start (4.14): err(0.01) = {e2:.2e} vs 1st-order {e2a:.2e}")

def wave_growth(lam, nst, degen):
    J = 256
    if degen:
        u0 = [1.0 if j % 2 == 0 else -1.0 for j in range(J)]
        u1 = u0[:]
    else:
        u0 = [math.sin(2 * math.pi * j / J) for j in range(J)]
        u1 = [u0[j] + 0.5 * lam**2 * (u0[(j + 1) % J] - 2 * u0[j] + u0[(j - 1) % J]) for j in range(J)]
    up, uc = u0[:], u1[:]
    for _ in range(2, nst + 1):
        un = uc[:]
        for j in range(J):
            un[j] = 2 * uc[j] - up[j] + lam**2 * (uc[(j + 1) % J] - 2 * uc[j] + uc[(j - 1) % J])
        up = uc[:]
        uc = un
        if max(abs(v) for v in uc) > 1e8:
            return 1e8
    return max(abs(v) for v in uc)

assert wave_growth(0.99, 400, False) < 1.01
print(f"wave lambda=0.99: max|u| = {wave_growth(0.99, 400, False):.4f} (stable)")
g100 = wave_growth(1.0, 200, True)
assert g100 > 100, g100
assert g100 < 800, g100
print(f"wave lambda=1.0, degenerate (-1)^j mode: max|u| = {g100} after 200 steps (linear ~ 2n)")
assert wave_growth(1.01, 400, False) > 1e3
print(f"wave lambda=1.01: blows up (max|u| = {wave_growth(1.01, 400, False):.3g})")

u, _ = wave_solve(0.01, 0.5, 0.5, 2)
assert max(abs(v) for v in u) < 1.01
print(f"wave lambda=0.5: amplitude bounded (max|u| = {max(abs(v) for v in u):.4f})")

print("END ====")
