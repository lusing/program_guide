import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
rng = np.random.default_rng(2525)
print("==== 25 krein-milman (Python) ====")
verts = np.array([[0.0, 0], [1, 0], [0.5, 1]])
t = rng.random(3); t /= t.sum()
pt = t @ verts
print(f"convex combo: {pt}")
assert all(t > 0) and abs(t.sum() - 1) < 1e-12
print("Krein-Milman: triangle = closure(conv(extreme points))")
print("==== 25 krein-milman END ====")
