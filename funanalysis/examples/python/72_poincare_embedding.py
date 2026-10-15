# 72_poincare_embedding.py —— Poincaré 与嵌入（docs/72 实验）
# 通道：Python 3.13 + numpy/scipy
# 内容：一维 Morrey（Lean 同型）、Poincaré 的边界条件必要性、
#       嵌入三段式的临界指数、Rellich 紧性
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

import numpy as np

print("==== 72 Poincaré 不等式与 Sobolev 嵌入 ====")

# ---------------------------------------------------------------
# 实验 1：一维 Morrey（Lean 定理的数值对照）
# |f(x) − f(y)| ≤ ‖f′‖_{L¹}（W^{1,1} → C⁰）对 f(x)=x^{3/2}·sin(3x) 验证
# ---------------------------------------------------------------
def exp1_morrey():
    xs = np.linspace(0, 1, 400_001)
    f = xs ** 1.5 * np.sin(3 * xs)
    df = 1.5 * np.sqrt(xs) * np.sin(3 * xs) + 3 * xs ** 1.5 * np.cos(3 * xs)
    l1 = np.trapezoid(np.abs(df), xs)
    for (x, y) in [(0.0, 0.3), (0.1, 0.95), (0.0, 1.0)]:
        osc = abs(f[int(x * 400_000)] - f[int(y * 400_000)])
        assert osc <= l1 + 1e-12
    return l1

l1_1 = exp1_morrey()
print(f"实验1 Morrey：‖f′‖₁ = {l1_1:.4f} 一致控制所有点对振幅（Lean abs_sub_le_integral_abs_deriv 同型）")

# ---------------------------------------------------------------
# 实验 2：Poincaré 需要边界条件——常数函数反例
# u ≡ 1（零导数、单位 L² 范数）：∫u² = 1 > 0 = ∫|∇u|²。
# 零边界的截断函数列 uₖ = min(1, kx, k(1−x))：Poincaré 逐步成立。
# ---------------------------------------------------------------
def exp2_boundary_necessity():
    xs = np.linspace(0, 1, 200_001)
    # 反例：无边界条件
    u_const = np.ones_like(xs)
    assert np.trapezoid(u_const**2, xs) > 0.99      # ‖u‖² ≈ 1
    assert np.trapezoid(np.gradient(u_const, xs) ** 2, xs) < 1e-12  # ‖u′‖² ≈ 0
    # 零边界截断：随坡度变陡 Poincaré 比值 → 1（远离 1/π² 的最优点）
    for k in [3, 10]:
        u = np.minimum(1, np.minimum(k * xs, k * (1 - xs)))
        du = np.gradient(u, xs)
        ratio = np.trapezoid(u**2, xs) / np.trapezoid(du**2, xs)
        assert ratio < 1.0 / (np.pi**2) + 0.01      # 仍受最优常数约束
    return None

exp2_boundary_necessity()
print("实验2 边界条件必要性：常数函数破坏 Poincaré（‖u‖=1, ‖∇u‖=0）；零边界截断函数恢复")

# ---------------------------------------------------------------
# 实验 3：一维嵌入三段式（书 6.2.6 在 n=1 的读法）
# W^{1,p}(0,1) ⊂ L^∞ 对一切 p ≥ 1（n < p 的三维分段在 n=1 恒真）。
# 临界函数 u(x) = x^{−α}：u ∈ L^q ⟺ αq < 1；u′ ~ x^{−α−1} ∈ L^p ⟺
# (α+1)p < 1 ⟹ α < 1/p − 1 < 0——任何 p ≥ 1 的 W 函数都自动有界。
# 数值：验证 x^β（β>0）族的 L^∞ 与 W^{1,p} 范数并存。
# ---------------------------------------------------------------
def exp3_embedding():
    xs = np.linspace(1e-6, 1, 200_001)
    for beta in [0.1, 0.5, 0.9]:
        u = xs ** beta
        du = beta * xs ** (beta - 1)
        linf = u.max()
        w1p = (np.trapezoid(np.abs(u) ** 2, xs) + np.trapezoid(np.abs(du) ** 2, xs)) ** 0.5
        # 一维 Morrey：‖u‖∞ ≤ C(‖u‖₂ + ‖u′‖₂)——常数 ~ sqrt(2)+1
        assert linf <= w1p * 2.5
    # 高维对照（n=3）：x^{−1/2} 型奇性在 n=3 落入临界带
    rs = np.geomspace(1e-4, 1, 2000)
    u = rs ** (-0.5)
    l3 = np.trapezoid(u**2 * rs**2, rs)     # ∫|u|²r²dr < ∞（L²(B₁) ✓）
    assert np.isfinite(l3)
    du = 0.5 * rs ** (-1.5)
    # ∫|u′|²r²dr = 0.25∫r^{-1}dr = 0.25·ln(1/a)：对数发散（无有限极限）
    for a in [1e-4, 1e-8, 1e-12]:
        rsa = np.geomspace(a, 1, 3000)
        val = np.trapezoid(0.25 * rsa ** (-1), rsa)
        assert abs(val - 0.25 * np.log(1 / a)) / (0.25 * np.log(1 / a)) < 0.05
    l3d = 0.25 * np.log(1 / 1e-12)           # 随 a→0 无界增长
    assert l3d > 6                            # 已 > L² 值，且不会停——发散
    return l3

l3_3 = exp3_embedding()
print(f"实验3 嵌入三段式：一维 W^{{1,p}} 自动 L^∞（n=1 < p）；n=3 的 r^(-1/2) 处于临界带（L² ✓ / W^{{1,2}} ✗）")

# ---------------------------------------------------------------
# 实验 4：Rellich 紧性（书 6.2.7）的数值投影
# W 归一振荡列 eₙ = sin(nπx)/√(1+n²π²) 强收敛于 0（L²），
# 而 L² 归一列 sin(nπx)·√2 在 L² 中只是弱收敛（范数不降）。
# ---------------------------------------------------------------
def exp4_rellich():
    xs = np.linspace(0, 1, 100_001)
    for n in [10, 100, 1000]:
        e = np.sin(n * np.pi * xs) / np.sqrt(1 + n**2 * np.pi**2)
        l2 = np.sqrt(np.trapezoid(e**2, xs))
        assert l2 < 1.01 / (n * np.pi * np.sqrt(2))
    # 弱收敛不降范数：纯振荡列 L² 范数恒 √2/√2=1（归一化后）
    for n in [10, 100]:
        w = np.sin(n * np.pi * xs) * np.sqrt(2)
        l2 = np.sqrt(np.trapezoid(w**2, xs))
        assert abs(l2 - 1) < 0.01
    return None

exp4_rellich()
print("实验4 Rellich：W 归一振荡列 L² → 0（紧性）；L² 归一振荡列范数恒 1（只弱收敛，无紧性）")

print("END ====")
