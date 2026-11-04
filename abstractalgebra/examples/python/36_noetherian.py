# 第 36 章 · 诺特环 —— Python 通道

import itertools
import random

import sympy as sp

x, y = sp.symbols("x y")

print("==== 36 诺特环")

# ---------- 单项式理想的升链稳定（Dickson / ACC） ----------
def monomial_closure(gens, bound=(6, 6)):
    """生成单项式集合的上闭包（受限窗口内）。"""
    S = set()
    frontier = [tuple(g) for g in gens]
    while frontier:
        e = frontier.pop()
        if e in S:
            continue
        S.add(e)
        for i in range(2):
            e2 = list(e)
            e2[i] += 1
            if e2[i] <= bound[i]:
                frontier.append(tuple(e2))
    return S


random.seed(20261104)
for _ in range(20):
    chain = [[(0, 0)]]
    prev = monomial_closure(chain[-1])
    for _ in range(25):
        chain.append(chain[-1] + [(random.randint(0, 6), random.randint(0, 6))])
        cur = monomial_closure(chain[-1])
        if cur == prev:
            # 链已稳定：继续加生成元也不再增长（在窗口内）
            for extra in range(5):
                chain.append(chain[-1] + [(random.randint(0, 6), random.randint(0, 6))])
                assert monomial_closure(chain[-1]) == prev
            break
        prev = cur
print("Dickson：20 条随机单项式升链全部稳定（k[x,y] 的 ACC 面）✓")


# ---------- 极小生成集 ----------
def minimal_gens(S):
    return [e for e in S
            if not any(f != e and f[0] <= e[0] and f[1] <= e[1] for f in S)]


S = monomial_closure([(2, 0), (0, 3), (1, 1)], bound=(8, 8))
mg = minimal_gens(S)
assert set(mg) == {(2, 0), (0, 3), (1, 1)}
assert monomial_closure(mg, bound=(8, 8)) == S
# 任何生成集 → 极小生成集 → 同一理想（有限生成）
for gens in ([(3, 0), (2, 1), (2, 0), (1, 2)],
             [(5, 5), (4, 6), (2, 3), (0, 7)]):
    Sc = monomial_closure(gens, bound=(9, 9))
    m = minimal_gens(Sc)
    assert monomial_closure(m, bound=(9, 9)) == Sc
    assert len(m) <= len(gens)
print("极小生成：生成集 → 极小元 → 同一理想（命题 7.26 的有限生成面）✓")

# ---------- ℤ 的理想链：整除链稳定 ----------
# (a₁) ⊆ (a₂) ⊆ … ⟺ …| a₂ | a₁（整除链）—— ℤ 中 ACC 的数值面：
# 递增理想链的生成元列是逐级整除的有限下降序列
def chain_stabilizes(start, max_len=60):
    a = start
    for _ in range(max_len):
        # 真包含一步：a 的真因子
        divs = [d for d in range(1, a) if a % d == 0 and d < a]
        if not divs:
            return True                            # 到 (1) = ℤ，链终止
        a = max(divs)                              # 最长的一步
    return False


for start in (60, 72, 96, 128, 360):
    assert chain_stabilizes(start)
print("ℤ 的理想链：整除链有限步到顶（(60)→…→ℤ）✓")

# ---------- 商环遗传（推论 7.28）----------
# ℤ/12 的理想 ↔ ℤ 中含 (12) 的理想（除数 1,2,3,4,6,12）——有限 ⟹ 诺特
for n in (4, 8, 12, 30):
    divs = [d for d in range(1, n + 1) if n % d == 0]
    # ℤ/n 的每个理想 (d)，包含链 (d) ⊆ (e) ⟺ e | d——有限格
    for d in divs:
        for e in divs:
            contain = set((d * k) % n for k in range(n // d)) >= \
                      set((e * k) % n for k in range(n // e))
            assert contain == (e % d == 0)          # (d) ⊇ (e) ⟺ d | e
print("ℤ/n：理想格 = 含 (n) 的理想（4/8/12/30 全核）——商环诺特 ✓")

# ---------- 希尔伯特基定理（定理 7.30）：Grobner 基有限 ----------
# sympy.groebner 终止 = 理想有限生成的机器证书
G1 = sp.groebner([x**3 - 2 * x * y, x**2 * y - y**2], x, y, order="lex")
assert all(isinstance(g, sp.Poly) for g in G1.polys)
assert len(G1.polys) <= 6
G2 = sp.groebner([x + y - 1, x - y], x, y, order="lex")
# 第二个多项式纯 y：消元成功（有限基的三角形）
assert any(not g.as_expr().free_symbols & {x} for g in G2.polys)
print("希尔伯特基：sympy groebner 终止并给出有限基（消元三角形）✓")

print("END ====")
