# 29_fem2d.py —— 第 29 章：二维三角形线性元（Python 通道，独立复算）

import math
import numpy as np

print("==== 29 fem2d")

f29 = lambda x, y: 2 * math.pi**2 * math.sin(math.pi * x) * math.sin(math.pi * y)
uex29 = lambda x, y: math.sin(math.pi * x) * math.sin(math.pi * y)

def mesh_square(N):
    nodes = [(i / N, j / N) for j in range(N + 1) for i in range(N + 1)]
    nid = lambda i, j: j * (N + 1) + i
    elems = []
    for j in range(N):
        for i in range(N):
            n1 = nid(i, j); n2 = nid(i + 1, j)
            n3 = nid(i + 1, j + 1); n4 = nid(i, j + 1)
            elems.append((n1, n2, n3))
            elems.append((n1, n3, n4))
    return nodes, elems

def fem2d_solve(N):
    nodes, elems = mesh_square(N)
    nn = len(nodes)
    K = np.zeros((nn, nn))
    F = np.zeros(nn)
    for (n1, n2, n3) in elems:
        x1, y1 = nodes[n1]; x2, y2 = nodes[n2]; x3, y3 = nodes[n3]
        b = (y2 - y3, y3 - y1, y1 - y2)
        c = (x3 - x2, x1 - x3, x2 - x1)
        A2 = x1 * (y2 - y3) + x2 * (y3 - y1) + x3 * (y1 - y2)
        area = A2 / 2
        ke = np.zeros((3, 3))
        for a in range(3):
            for bb in range(3):
                ke[a, bb] = (b[a] * b[bb] + c[a] * c[bb]) / (4 * area)
        ns = (n1, n2, n3)
        xm = (x1 + x2 + x3) / 3
        ym = (y1 + y2 + y3) / 3
        for a in range(3):
            F[ns[a]] += area / 3 * f29(xm, ym)
            for bb in range(3):
                K[ns[a], ns[bb]] += ke[a, bb]
    def is_boundary(i):
        x, y = nodes[i]
        return abs(x) < 1e-12 or abs(x - 1) < 1e-12 or abs(y) < 1e-12 or abs(y - 1) < 1e-12
    free = [i for i in range(nn) if not is_boundary(i)]
    c = np.linalg.solve(K[np.ix_(free, free)], F[free])
    u = np.zeros(nn)
    u[free] = c
    return u, nodes

def fem2d_err(N):
    u, nodes = fem2d_solve(N)
    return max(abs(u[i] - uex29(nodes[i][0], nodes[i][1])) for i in range(len(nodes)))

e1, e2 = fem2d_err(8), fem2d_err(16)
r29 = e1 / e2
print(f"P1 triangle FEM: err(8) = {e1:.4f}, err(16) = {e2:.4f}")
print(f"  h->h/2 ratio = {r29:.3f} (2nd order at nodes)")
assert r29 > 3.0

ke = np.zeros((3, 3))
b = (-1.0, 1.0, 0.0); c = (-1.0, 0.0, 1.0)
for a in range(3):
    for bb in range(3):
        ke[a, bb] = (b[a] * b[bb] + c[a] * c[bb]) / 2
print(f"unit right triangle stiffness row1 = {np.round(ke[0], 4)}")

print("END ====")
