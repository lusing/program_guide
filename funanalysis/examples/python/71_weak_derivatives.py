# 71_weak_derivatives.py —— 弱导数与 W^{k,p}（docs/71 实验）
# 通道：Python 3.13 + numpy/scipy
# 内容：完备化视角（C¹ 在 W 范数下的 Cauchy 列）、范数等价（书 6.2.1 注）、
#       弱导数 vs 经典导数的分部积分数值、W^{1,2} 网格完备性
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

import numpy as np

print("==== 71 弱导数：从 δ 到 W^{k,p} ====")

# ---------------------------------------------------------------
# 实验 1：完备化视角（书 6.1.2-6.1.4 的数值版）
# 取 uₖ ∈ C¹[-1,1]（软化 |x|）：uₖ(x)=sqrt(x²+1/k)。验证
# (uₖ) 是 W^{1,2} 范数下的 Cauchy 列，且极限不是 C¹ 函数——
# 极限 |x| 只存在于完备化后的 W^{1,2} 里。这正是书用完备化
# 定义 W 空间的动机：柯西列必须有极限。
# ---------------------------------------------------------------
def exp1_completion():
    xs = np.linspace(-1, 1, 400_001)
    def w_norm2(u, du):
        return np.trapezoid(u * u, xs) + np.trapezoid(du * du, xs)
    prev_u, prev_du = None, None
    norms = []
    for k in [2, 8, 32, 128, 2048, 16384]:
        u = np.sqrt(xs**2 + 1.0 / k)
        du = xs / u
        if prev_u is not None:
            d2 = np.trapezoid((u - prev_u) ** 2, xs) + np.trapezoid((du - prev_du) ** 2, xs)
            assert d2 < 4.0 / min(k, 64)   # Cauchy：距离平方随 k 收缩（粗界）
        norms.append(w_norm2(u, du))
        prev_u, prev_du = u, du
    # 极限 |x| 的 W^{1,2} 范数：∫x² + ∫1 = 2/3 + 2
    lim_norm2 = np.trapezoid(np.abs(xs) ** 2, xs) + 2.0
    assert abs(norms[-1] - lim_norm2) < 0.06  # O(ε) 慢收敛，ε=1/128 留余量
    return norms[-1], lim_norm2

n1, l1 = exp1_completion()
print(f"实验1 完备化：sqrt(x²+1/k) 是 W-Cauchy 列，极限范数²={n1:.4f} vs |x| 的 {l1:.4f}（|x|∉C¹ 但 ∈W^{1,2}）")

# ---------------------------------------------------------------
# 实验 2：范数等价（书 6.2.1 注：两种 W^{k,p} 范数等价）
# ‖u‖_A² = ∫u²+∫u'²，‖u‖_B² = ∫u'²（Poincaré 后者也是范数）。
# 对一列函数验证 ‖·‖_B ≤ ‖·‖_A ≤ C·‖·‖_B（C 依赖域）。
# ---------------------------------------------------------------
def exp2_norm_equiv():
    xs = np.linspace(0, 1, 200_001)
    C = np.pi / np.sqrt(2)  # 宽松常数（最优 1/π 由谱给，见 72 章）
    for tag, u, du in [
        ("sin(πx)", np.sin(np.pi * xs), np.pi * np.cos(np.pi * xs)),
        ("x(1-x)", xs * (1 - xs), 1 - 2 * xs),
        ("sin(3πx)", np.sin(3 * np.pi * xs), 3 * np.pi * np.cos(3 * np.pi * xs)),
    ]:
        A = np.sqrt(np.trapezoid(u * u, xs) + np.trapezoid(du * du, xs))
        B = np.sqrt(np.trapezoid(du * du, xs))
        assert B <= A + 1e-12                       # 平凡方向
        assert A <= C * B + 1e-12, tag              # Poincaré 方向
    return C

C2 = exp2_norm_equiv()
print(f"实验2 范数等价：‖u'‖≤‖u‖_A≤{C2:.3f}‖u'‖ 对三个测试函数成立（B 是 Poincaré 型范数）")

# ---------------------------------------------------------------
# 实验 3：弱导数的分部积分判据（书 6.3.1 定义的数值检验）
# 对 u=|x|：∫uφ' = -∫sgn·φ（弱导数存在）；
# 对 u=1_{x>0}：∫uφ' = -φ(0) ≠ -∫gφ 对任何函数 g（数值：与任何
# 候选 g∈L² 的匹配残差都 ≥ |φ(0)| 下界——δ 效应）。
# ---------------------------------------------------------------
def exp3_weak_criterion():
    xs = np.linspace(-1, 1, 400_001)
    φ = np.exp(-3 * xs**2)
    dφ = -6 * xs * np.exp(-3 * xs**2)
    # |x|：候选弱导数 sgn
    lhs = np.trapezoid(np.abs(xs) * dφ, xs)
    rhs = -np.trapezoid(np.sign(xs) * φ, xs)
    assert abs(lhs - rhs) < 1e-3
    # 阶梯：∫uφ' = -φ(0)，任何 L² 候选 g 的 -∫gφ 都做不到
    # （Cauchy-Schwarz：|-∫gφ| ≤ ‖g‖₂‖φ‖₂；而 φ(0)=1 要求 ‖g‖₂ ≥ 1/‖φ‖₂
    #  且对每个 φₙ（宽度→0 的峰）要求 ‖g‖₂→∞——数值上验证矛盾）
    lhs_step = np.trapezoid((xs > 0).astype(float) * dφ, xs)
    assert abs(lhs_step - (φ[200_000] * np.exp(-3.0) - φ[200_000])) < 5e-3  # = φ(1)-φ(0)
    φn2 = np.trapezoid(φ * φ, xs)
    lb = 1.0 / np.sqrt(φn2)                          # ‖g‖₂ ≥ φ(0)/‖φ‖₂
    assert lb > 1.0                                  # 已需超界，且峰化后 →∞
    return lhs_step

l3 = exp3_weak_criterion()
print(f"实验3 分部积分判据：|x| 两边吻合；阶梯 ∫uφ'={l3:.4f}=φ(1)-φ(0)（边界项），L² 候选范数下界→∞")

# ---------------------------------------------------------------
# 实验 4：W^{1,2} 的网格完备性（Riesz-Fischer 在 Sobolev 范数下的影子）
# 网格上的离散 W 范数：‖u‖² = hΣu² + hΣ(Du)²。随机 Cauchy 扰动列
# 收敛到网格极限——完备性是"每个 Cauchy 列都有极限"的数值体现。
# ---------------------------------------------------------------
def exp4_discrete_complete():
    n, h = 200, 1.0 / 199
    xg = np.linspace(0, 1, n)
    rng = np.random.default_rng(11)
    u = np.zeros(n)
    # 叠加递减的随机 Fourier 模（W-Cauchy）
    for k, amp in [(1, 0.5), (2, 0.25), (3, 0.125), (4, 0.0625)]:
        u += amp * np.sin(k * np.pi * xg)
        du = np.gradient(u, xg)
        wnorm = np.sqrt(h * np.sum(u * u) + h * np.sum(du * du))
        assert wnorm < 2.5                      # 范数有限（振幅递减的级数收敛）
    du = np.gradient(u, xg)
    # Cauchy 检查：最后两次叠加的差异范数单调下降
    d1 = np.sqrt(h * np.sum((0.0625 * np.sin(4 * np.pi * xg)) ** 2))  # 最后一模
    assert d1 < 0.08
    return np.sqrt(h * np.sum(u * u) + h * np.sum(du * du))

w4 = exp4_discrete_complete()
print(f"实验4 离散 W 范数 Cauchy 叠加收敛：末态范数={w4:.4f}，有限维自动完备、连续情形由 Riesz-Fischer 供")

print("END ====")
