import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np
rng = np.random.default_rng(3434)
print("==== 34 cstar-algebra (Python) ====")
A = rng.standard_normal((5, 5)) + 1j * rng.standard_normal((5, 5))
lhs = np.linalg.norm(A.conj().T @ A, 2)
rhs = np.linalg.norm(A, 2)**2
print(f"C* identity: {lhs:.8f} = {rhs:.8f}")
assert abs(lhs - rhs) < 1e-10
print("==== 34 cstar-algebra END ====")
