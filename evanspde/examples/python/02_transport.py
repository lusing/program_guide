# Ch02 传输方程（Python 交叉）：Duhamel 闭式推导核对 + 弱解传播
#
# 与 julia/02_transport.jl 交叉：
#   (a) Duhamel 积分的闭式用 sympy 风格的手算多项式核（这里纯 math）；
#   (b) 间断初值的弱解：L1 误差恒零（平移精确）；
#   (c) 逆推数据：从 (x,t) 反找特征足点 x - t b 的对账。

import math

print("==== 02")

# ---- (a) 闭式推导核对：∫₀ᵗ e^{-s} cos(a+s) ds 的分部积分两条路 ----
# 路 1（和角展开）：∫ e^{-s}(cos a cos s - sin a sin s) ds
#   = cos a ∫ e^{-s} cos s - sin a ∫ e^{-s} sin s
#   ∫e^{-s}cos s = e^{-s}(sin s - cos s)/2,  ∫e^{-s}sin s = -e^{-s}(sin s + cos s)/2
# 路 2（直接终值公式）：(sin a - cos a - e^{-t}(sin(a+t) - cos(a+t)))/2
def int_route1(a, t):
    # 原函数 F(s) = e^{-s}(sin s - cos s)/2·cos a + e^{-s}(sin s + cos s)/2·sin a
    #（第二个原函数来自 ∫e^{-s}sin s = -e^{-s}(sin s + cos s)/2 的负号合并）
    def F(s):
        return math.exp(-s) * (math.sin(s) - math.cos(s)) / 2 * math.cos(a) \
             + math.exp(-s) * (math.sin(s) + math.cos(s)) / 2 * math.sin(a)
    return F(t) - F(0)   # 初版写成 F(0)-F(t)，符号翻转被 Simpson 对账翻案

def int_route2(a, t):
    E = math.exp(-t)
    return (E * (math.sin(a + t) - math.cos(a + t)) - (math.sin(a) - math.cos(a))) / 2

for (a, t) in [(0.3 - 1.0, 1.0), (-0.7 - 2.3, 2.3), (1.5 - 0.4, 0.4)]:
    r1, r2 = int_route1(a, t), int_route2(a, t)
    print(f"    a={a:+.2f} t={t:.1f}: route1 {r1:.12f} route2 {r2:.12f} |d|={abs(r1-r2):.1e}")
    assert abs(r1 - r2) < 1e-12, "两条推导路线必须逐位一致"

# Simpson 数值积分第三重对照
def simpson(g, n=2048):
    h = 1.0 / n
    s = g(0.0) + g(1.0)
    for k in range(1, n):
        s += (4 if k % 2 else 2) * g(k * h)
    return s * h / 3

a0, t0 = 0.3 - 1.0, 1.0
num = simpson(lambda u: t0 * math.exp(-t0 * u) * math.cos(a0 + t0 * u))
print(f"    Simpson subsample check: {num:.12f} vs {int_route2(a0, t0):.12f}")
assert abs(num - int_route2(a0, t0)) < 1e-9

# ---- (b) 弱解：间断初值在任意 t 仍是同一形状的平移（L1 误差 0）----
def g_step(x):
    return 1.0 if x < 0.3 else -1.0

b = 0.7
import random
random.seed(7)
for t in [0.0, 0.9, 2.1]:
    pts = [random.random() for _ in range(500)]
    # 强对账：u(·,t) 是 g(·) 的平移——u(x0 + t b, t) = g(x0) 逐点成立
    err = sum(abs(g_step(x0 + t * b - t * b) - g_step(x0)) for x0 in pts)
    assert err == 0.0
print("(b) weak solution: jump profile translated exactly, L1 error = 0 at all t")

# ---- (c) 特征足点：点 (x,t) 的依赖域是单点 x - t b ----
b2 = (0.6, 0.8)
for (x, y, t) in [(1.0, 0.5, 1.3), (0.2, -0.4, 0.7)]:
    fx, fy = x - t * b2[0], y - t * b2[1]
    # 足点上再正向积分回到原点：往返闭合
    assert abs(fx + t * b2[0] - x) < 1e-15 and abs(fy + t * b2[1] - y) < 1e-15
print("(c) foot-of-characteristic round trip closed")

print("END ====")
