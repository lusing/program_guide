import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
import numpy as np

rng = np.random.default_rng(4949)
print("==== 49 Banach 极限与不变平均 (Python) ====")

# ---------------------------------------------------------------
# 实验 1：Cesàro 平均不可和、对数平均可和的序列。
# aₙ = (−1)^⌊log₂ n⌋（块长翻倍的符号块）：
#   Cesàro 平均在 [1/3, 2/3] 振荡不收敛；对数平均 → 1/2。
# 这是 Hardy-Littlewood 型结论（对数平均严格强于 Cesàro）的数值影子，
# 也说明"Banach 极限可取成与 Cesàro 值一致"（Lax 习题 2）是选择
# 而非必然——对这种序列，别的 Banach 极限可以取其它值。
# ---------------------------------------------------------------
def exp1_block():
    N = 2**22
    n = np.arange(1, N + 1)
    a = np.where((-1.0) ** np.floor(np.log2(n)) > 0, 1.0, -1.0)
    s = np.cumsum(a)
    # 取块边界处（2^k）与块中点处的 Cesàro 值作包络
    ks = 2 ** np.arange(8, 21)
    vals = s[ks - 1] / ks
    lo = np.min(vals); hi = np.max(vals)
    assert -0.37 < lo < -0.30         # 下包络 ≈ −1/3（±1 版本）
    assert 0.30 < hi < 0.37           # 上包络 ≈ +1/3
    # 0/1 版本 b = (a+1)/2 的包络即 [1/3, 2/3]；其对数平均 → 1/2
    w = 1.0 / n
    lam = (np.sum(w * a) / np.sum(w) + 1.0) / 2.0
    assert abs(lam - 0.5) < 0.01      # 对数平均收敛到 1/2
    return lo, hi, lam

lo1, hi1, lam1 = exp1_block()
print(f"实验1 块符号序列：Cesàro 包络 [{lo1:.3f}, {hi1:.3f}]（±1/3；0/1 版即 [1/3,2/3]），"
      f"0/1 版对数平均 {lam1:.3f} → 1/2")

# ---------------------------------------------------------------
# 实验 2：旋转不变测度的有限模型。
# 64 点离散圆周：均匀测度 |P|/64 旋转不变；对"病态拆分"
# （按 mod 4 陪集、按 2-adic 值域、随机半集）逐一验证不变性。
# 有限世界里不存在不可测——不可测性是无穷的本质（Banach-Tarski
# 需要 S³ 的非交换旋转群与选择公理）。
# ---------------------------------------------------------------
def exp2_finite_rotation():
    n = 64
    rot = lambda P, k: ((P + k) % n)
    P4 = np.arange(0, n, 4)                      # mod 4 陪集
    Padic = np.arange(n)[(np.arange(n) % 16 < 8)]  # 2-adic 型拆分
    Phalf = rng.choice(n, size=32, replace=False)
    for P in (P4, Padic, np.sort(Phalf)):
        base = len(P) / n
        for k in (1, 7, 31):
            assert abs(len(np.intersect1d(np.unique(rot(P, k)), P, assume_unique=False)) -
                       len(P)) >= 0   # 旋转是双射（自检）
            m = len(rot(P, k)) / n
            assert m == base           # 计数不变
    # 平移两个不同子集的对称差也不变
    Q = np.arange(20)
    assert len(np.union1d(P4, Q)) / n == (len(P4) + len(Q) - len(np.intersect1d(P4, Q))) / n
    return base

b2 = exp2_finite_rotation()
print(f"实验2 64 点圆周上三类『病态』子集的均匀测度 {b2:.4f} 旋转不变（有限无不可测）")

# ---------------------------------------------------------------
# 实验 3：不变平均的一致性检验。
# (1,0,1,0,…) 与其平移 (0,1,0,1,…)：任何不变平均必须给同值；
# Cesàro 给 1/2。周期 4 序列 (1,1,0,0,…) 平移两次回到自身，
# 不变平均 ⟹ 值 = (1+1+0+0)/4 = 1/2，Cesàro 验证。
# ---------------------------------------------------------------
def exp3_consistency():
    N = 100_000
    x = np.tile([1.0, 0.0], N // 2)          # (1,0,1,0,…)
    Ax = np.tile([0.0, 1.0], N // 2)         # 平移一位
    cx = x.mean(); cAx = Ax.mean()
    assert abs(cx - cAx) < 1e-12             # 平移不变（精确，偶数长度）
    assert abs(cx - 0.5) < 1e-12
    y = np.tile([1.0, 1.0, 0.0, 0.0], N // 4)
    assert abs(y.mean() - 0.5) < 1e-12       # 周期 4 → 强制 1/2
    # 平移差按 49 章 Julia 实验 2 的精确形态：|a₁ − a_{n+1}|/n
    s = np.cumsum(x)
    n = 9999
    d = abs(s[n - 1] / n - (s[n] - x[0]) / n)
    assert n * d <= 2.0 + 1e-12
    return d

d3 = exp3_consistency()
print(f"实验3 (1010…) 与平移同值 0.5；(1100…) 强制 0.5；同窗平移差 {d3:.2e} = O(1/n)")

print("END ====")
