import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
"""第 22 章 · 分布。"""
import numpy as np
print("==== 22 distributions (Python) ====")
n = 200; xs = np.linspace(0, 1, n); h = 1/(n-1)
phi = lambda x: np.exp(-100*(x-0.5)**2)
phiv = phi(xs)
dphi = phi(0.5)
print(f"<δ,φ> = φ(1/2) = {dphi:.6f}")
for sig in [0.1, 0.05, 0.02]:
    g = lambda x: np.exp(-(x-0.5)**2/(2*sig**2)) / (sig*np.sqrt(2*np.pi))
    approx = np.sum(g(xs) * phiv) * h
    print(f"  σ={sig}: ∫g·φ ≈ {approx:.4f}")
print("(narrow Gaussians approach δ)")
print("==== 22 distributions END ====")
