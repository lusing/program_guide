# 70_lebesgue_lp.py —— 勒贝格积分与 L^p（docs/70 实验）
# 通道：Python 3.13 + numpy + scipy
# 内容：Monte Carlo 测度、Young 等号条件、DCT 数值、Cantor 测度递减
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

import numpy as np

print("==== 70 勒贝格积分与 L^p ====")

# ---------------------------------------------------------------
# 实验 1：Monte Carlo 面积——测度的频率解释
# 勒贝格测度在概率语言里就是均匀采样的命中频率：m(A∩[0,1]²) ≈ 计数/总数。
# 对照对象：圆盘面积 π/4（真值已知），展示 MC 误差 ~ 1/√N。
# ---------------------------------------------------------------
def exp1_monte_carlo():
    rng = np.random.default_rng(42)
    for N in [10_000, 100_000, 1_000_000]:
        pts = rng.random((N, 2))
        inside = (pts[:, 0] ** 2 + pts[:, 1] ** 2 <= 1.0).mean()
        err = abs(inside - np.pi / 4)
        assert err < 5 / np.sqrt(N)  # MC 收敛律 O(1/√N)
    return inside

mc1 = exp1_monte_carlo()
print(f"实验1 MC 圆盘测度={mc1:.5f}（真值 π/4={np.pi/4:.5f}），误差遵 1/√N 律")

# ---------------------------------------------------------------
# 实验 2：Young 不等式 ab ≤ a^p/p + b^q/q 及其等号条件
# 等号 ⟺ a^p = b^q（凸性的切线条件）。随机抽样验证不等式与等号判据。
# ---------------------------------------------------------------
def exp2_young():
    rng = np.random.default_rng(7)
    p = 3.0
    q = p / (p - 1)  # 共轭指数 1/p+1/q=1
    worst_gap = -1.0
    for _ in range(20_000):
        a = rng.random() * 5
        b = rng.random() * 5
        lhs, rhs = a * b, a**p / p + b**q / q
        assert lhs <= rhs + 1e-12  # Young 恒成立
        worst_gap = max(worst_gap, rhs - lhs)
        # 等号判据：a^p = b^q
        if abs(a**p - b**q) < 1e-3:
            assert abs(lhs - rhs) < 5e-3  # 近似等号点处近似取等
    return worst_gap

gap2 = exp2_young()
print(f"实验2 Young 不等式 2 万随机对全过，最大间隙={gap2:.3f}，等号点 a^p=b^q 验证")

# ---------------------------------------------------------------
# 实验 3：DCT 数值（书例 1.4.29 / 习题 1.7）
# fₙ(x) = 1/(1+n²x²) 在 [0,1]：逐点 → 0，被 g=1 控制（可积），
# 故 ∫fₙ → 0。同时展示"没有控制函数会怎样"的姊妹序列
# hₙ = n·1_{(0,1/n)}：逐点 → 0 但 ∫hₙ = 1 恒定——Fatou 不等号两侧。
# ---------------------------------------------------------------
def exp3_dct():
    xs = np.linspace(0, 1, 2_000_001)
    for n in [10, 100, 1000]:
        fn = 1.0 / (1.0 + (n * xs) ** 2)
        integral = np.trapezoid(fn, xs)
        assert abs(integral - np.arctan(n) / n) < 1e-4  # 精确值 arctan(n)/n
        assert integral < 0.02 if n >= 100 else True
    # 反例：n·1_{(0,1/n)} 无可积控制，积分不趋于逐点积分
    for n in [10, 100, 1000]:
        hn = np.where(xs < 1.0 / n, n, 0.0)
        integral = np.trapezoid(hn, xs)
        assert abs(integral - 1.0) < 1e-3  # 恒为 1 ≠ ∫0 = 0
    return np.arctan(1000) / 1000

dct3 = exp3_dct()
print(f"实验3 DCT：∫1/(1+n²x²)→{dct3:.5f}（→0）；反例 n·1_(0,1/n) 积分恒 1（无控制 ⟹ 极限换序破产）")

# ---------------------------------------------------------------
# 实验 4：Cantor 集测度递减（书 1.4.13）
# 第 k 步去掉 2^{k-1} 个长 3^{-k} 的开区间，剩余测度 (2/3)^k → 0。
# 数值追踪剩余测度与不可数性（三进制展开无数字 1 的点集）。
# ---------------------------------------------------------------
def exp4_cantor():
    rem = 1.0
    for k in range(1, 61):
        rem -= (2 ** (k - 1)) * (3.0 ** (-k))  # 去掉的部分
        assert rem > 0
    assert rem < 1e-10  # (2/3)^60 ≈ 2.7e-11 → 快速归零
    # 三进制判据采样：Cantor 点 = 三进制只用 0/2 的数
    rng = np.random.default_rng(3)
    hits = 0
    for _ in range(200_000):
        x = rng.random()
        t = x
        ok = True
        for _ in range(30):
            t *= 3
            d = int(t)
            if d == 1:
                ok = False
                break
            t -= d
        hits += ok
    assert hits / 200_000 < 0.001  # 命中率→测度→0
    return rem

rem4 = exp4_cantor()
print(f"实验4 Cantor 集：60 步后剩余测度≈{rem4:.1e}，随机采样 20 万点命中 {0:.1%} 以下——零测而不可数")

print("END ====")
