import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(3535)
print("==== 35 positive_elements (Python) ====")
n = 5

# 正元：A = B*B ⟺ A 自伴且 σ(A) ⊆ [0, ∞)
B = rng.standard_normal((n, n)) + 1j * rng.standard_normal((n, n))
A = B.conj().T @ B
λA = np.linalg.eigvalsh(A)
print("B*B 的特征值：", np.round(λA, 4), " 全部 > 0")
assert (λA > 0).all()

# 平方根：S = V√ΛV*，S² = A 且 S 仍正
vals, vecs = np.linalg.eigh(A)
S = vecs @ np.diag(np.sqrt(vals)) @ vecs.conj().T
rel = np.linalg.norm(S @ S - A) / np.linalg.norm(A)
print(f"‖S² - A‖/‖A‖ = {rel:.12f}")
assert rel < 1e-12
λS = np.linalg.eigvalsh(S)
assert (λS > 0).all()
print("正元的正平方根存在（数值验证）：✓")

# 反例：含负特征值的自伴元不是 B*B
C = rng.standard_normal((n, n)); C = (C + C.T) / 2
λC = np.linalg.eigvalsh(C)
print(f"随机自伴阵最小特征值 {λC.min():.4f} < 0 ⟹ 非正")
assert λC.min() < 0

# 正元构成闭凸锥
B2 = rng.standard_normal((n, n)) + 1j * rng.standard_normal((n, n))
A2 = B2.conj().T @ B2
assert (np.linalg.eigvalsh(A + A2) > 0).all()
assert (np.linalg.eigvalsh(2.7 * A) > 0).all()
print("A,B 正 ⟹ A+B 正；t>0 ⟹ tA 正（闭凸锥）：✓")
print("==== 35 positive_elements END ====")
