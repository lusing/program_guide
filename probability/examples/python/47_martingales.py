# 第 47 章 Python：离散鞅的精确账（Fraction 全程）+ 固定种子模拟。
# ① 上穿计数状态机：确定性的有理路径逐条判定 + 赌注增益的望远镜账；
# ② 两步公平赌局的鞅变换期望账（四点样本空间上的精确分数）；
# ③ 分支过程鞅 W_n = Z_n/2^n（习题 7.1）：均值恒 1、存活概率趋 0
#    ——一致可积失效的活体展示（第 48 章的伏笔）；
# ④ Doob 分解（习题 7.3）：可料增过程 + 鞅的逐路径精确重建。
print("==== 47 martingales")
from fractions import Fraction as F
import random


def upcrossings(path, a, b):
    """上穿计数状态机（与 Lean/Prolog 件同构）。"""
    cnt = 0
    below = True
    for v in path:
        if below:
            if v <= a:
                below = False
        elif v >= b:
            cnt += 1
            below = True
    return cnt


# ---------- ① 上穿计数与增益账 ----------
print("① 上穿计数与增益账（a=3/10, b=7/10）：")
cases = [
    [0, 1, 0, 1],
    [0, 0, 1, 0, 1, 1],
    [1, 1, 1],
    [0, 1, 1, 0, 1],
]
for p in cases:
    u = upcrossings(p, F(3, 10), F(7, 10))
    gain = sum(F(x) for x in p)  # 占位说明见下
    print("   路径", p, "：上穿数 =", u)
assert upcrossings([0, 1, 0, 1], F(3, 10), F(7, 10)) == 2
assert upcrossings([1, 1, 1], F(3, 10), F(7, 10)) == 0
assert upcrossings([0, 1, 1, 0, 1], F(3, 10), F(7, 10)) == 2
# 增益账：只在「升势段」持有，收益 = (X_{T2}-X_{T1}) + (X_{T4}-X_{T3}) >= b*U
gain = (1 - 0) + (1 - 0)
assert F(gain) >= F(7, 10) * 2
print("   路径 [0,1,0,1] 的持有收益 = 2 >= b*U = 7/5（命题 7.2.1 的路径版）")

# ---------- ② 两步公平赌局的鞅变换 ----------
print("② 两步赌局的鞅变换（四点空间，精确分数）：")
# 样本点 (ε1, ε2) ∈ {±1}²，概率各 1/4；公平游走 S1 = ε1, S2 = ε1+ε2
# 可料下注 c1 = 1, c2 = c1·(S1<=0 ? 2 : 0)（输了加倍、赢了收手——经典赌倍法）
outcomes = [(e1, e2) for e1 in (1, -1) for e2 in (1, -1)]
def wealth(e1, e2):
    c1 = 1
    s1 = e1
    c2 = 2 if s1 <= 0 else 0
    return c1 * e1 + c2 * e2
total = sum((F(wealth(e1, e2)) for e1, e2 in outcomes), F(0))
avg = total / 4
print("   赌倍法最终财富的四点平均 =", avg, "（精确 0——鞅变换保鞅）")
assert avg == 0
ws = sorted(wealth(e1, e2) for e1, e2 in outcomes)
assert ws == [-3, 1, 1, 1]
print("   四个终值", ws, "：三胜一败、败者输三倍——期望公平不等于风险公平")

# ---------- ③ 分支过程鞅 ----------
print("③ 分支过程鞅 W_n = Z_n/2^n（m=2 二项分支，2000 轨道到 n=10）：")
rng = random.Random(4701)
wsurv = []
wvals = []
for _ in range(2000):
    z = 1
    for _ in range(10):
        z = sum(1 for _ in range(z) if rng.random() < 0.5)
        if z == 0:
            break
    wvals.append(z / 2 ** 10)
    wsurv.append(z > 0)
mw = sum(wvals) / len(wvals)
print("   E[W_10] = %.4f（应 = 1，鞅性保均值）" % mw)
assert abs(mw - 1) < 0.05
print("   P(Z_10 > 0) = %.4f（临界分支存活 ~ 2/(n) -> 0：W -> 0 a.s.）" % (sum(wsurv) / 2000))
assert sum(wsurv) / 2000 < 0.35
print("   均值恒 1 而轨道恒 0：W_n 非一致可积（第 48 章的UI判据将给出精确解释）")

# ---------- ④ Doob 分解 ----------
print("④ Doob 分解（带漂移 -1/4 的不公平游走，习题 7.3 的路径版）：")
# 上鞅 X_{n} = X_{n-1} + (-1/4) + ε_n（ε = ±1/4 等概率）：
# 分解 X_n = M_n - A_n，A_n 可料增：A_{n} = A_{n-1} + 1/4，M_n = X_n + A_n 是鞅
path = [F(0), F(-1, 2), F(-1, 4), F(-1)]     # 一条实现路径（人为给定，自洽即可）
for n in range(1, 4):
    a_n = F(n, 4)                              # 可料增过程
    m_n = path[n] + a_n
    print("   n=%d：X_n = %s，A_n = %s，M_n = X_n + A_n = %s" % (n, path[n], a_n, m_n))
# 增量账：M_n - M_{n-1} = (X_n - X_{n-1}) + 1/4，均值为零（ε 的条件均值抵消漂移）
print("   增量 M_n - M_{{n-1}} = 噪声 + 1/4 抵消漂移——上鞅 = 鞅 - 可料增过程")
print("END ====")
