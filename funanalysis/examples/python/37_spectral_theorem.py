import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
rng = np.random.default_rng(3737)
print("==== 37 spectral-theorem (Python) ====")
A = rng.standard_normal((8, 8)); H = (A + A.T) / 2
vals, vecs = np.linalg.eigh(H)
print(f"eigenvalues all real: {np.abs(vals.imag).max() == 0}")
H2 = vecs @ np.diag(vals) @ vecs.T
print(f"reconstruction err: {np.linalg.norm(H - H2):.2e}")
assert np.linalg.norm(H - H2) < 1e-12
print("==== 37 spectral-theorem END ====")
