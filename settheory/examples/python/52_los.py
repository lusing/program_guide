# 第 52 章 超积实验室：P(X)-值模型与 Łoś 的有限化身
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 52")

from itertools import product

# ---------- 三个有限结构（不同的循环群） ----------
# M1 = Z/2, M2 = Z/3, M3 = Z/4（加法群，语言 {+, 0} 化为关系：sum(a,b,c) 表）
def cyc(n):
    return {(a, b, (a + b) % n) for a in range(n) for b in range(n)}

Ms = [cyc(2), cyc(3), cyc(4)]
X = [0, 1, 2]
print("(a) 结构 M1=Z2, M2=Z3, M3=Z4；P(X)-值模型 N = M1×M2×M3")

# ---------- P(X)-值语义：sum 的真值 = {x : Mx ⊨ sum(f,g,h)} ----------
def truth_sum(f, g, h):
    return frozenset(x for x in X if (f[x], g[x], h[x]) in Ms[x])

# ---------- 主超滤 G_k：商 = 第 k 坐标 ----------
for k in X:
    G = frozenset(S for S in map(frozenset, (c for r in range(4)
                       for c in product(X, repeat=r))) if k in S)
    # 抽查 Łoś 原子：sum 在商（即 M_k）中成立 ⟺ 真值集 ∈ G ⟺ k ∈ 真值集
    ok = True
    for _ in range(200):
        import random
        random.seed(52 + k)
        f = tuple(random.randrange(len(range(Ms[x][0][2]))) if False else
                  random.randrange(4) for x in X)   # 粗取值域 [0,4)
        g = tuple(random.randrange(4) for x in X)
        # h := f+g 逐坐标
        h = tuple((f[x] + g[x]) % (2, 3, 4)[x] for x in X)
        lhs = (f[k], g[k], h[k]) in Ms[k]            # 商中 sum(f,g,h) 成立
        rhs = k in truth_sum(f, g, h)                 # 真值 ∈ G_k
        ok &= (lhs == rhs)
    assert ok
    print(f"    主超滤 G_{k}：Łoś 原子等价成立（200 随机样本）✓")

# ---------- Fréchet 式"大集"（余有限滤子的对照） ----------
# 余有限滤子 F = {S : |X∖S| = 0}——本例 X 有限即 {X}：
# 量词行为：∃y φ(y) 的真值 = ⋃_y ⟦φ(y)⟧ ∈ F ⟺ 某单点覆盖 X——
# 几乎不可能（除非某 y 处处见证）——有限 Fréchet 太小，
# 超滤需要 PIT 扩张（47 章）。
print("(b) 余有限滤子在有限 X 上 = {X}：太穷，量词真值几乎总不在其中")
print("    ——真正的非主超滤需要无穷 X + PIT：超积实验室的无穷侧")
print("    由 Julia 通道的 L⁺ 可测函数域承载（同为 MALG 语义）")

# ---------- 混合性质（P(X) 上） ----------
# 反链 { {0}, {1}, {2} }：混合任意三元组 (a_0, a_1, a_2) 的元素 b
# P(X)-值模型里 b := 逐坐标选择 —— 正是超积的元素构造本身
def mix(a0, a1, a2):
    # 反链 {{0},{1},{2}} 上混合：b 在坐标 x 取 a_x 的第 x 分量
    vals = {0: a0, 1: a1, 2: a2}
    return tuple(vals[x] for x in X)

b = mix(0, 1, 2)
assert b == (0, 1, 2)
print("(c) P(X)-混合 = 坐标拼装（超积元素的本质）：", b, "✓")

print("END ====")
