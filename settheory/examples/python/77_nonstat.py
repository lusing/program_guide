# 第 77 章：滤子、非荟萃集理想与广义无界闭子集（冯琦 §2.3）——Python 通道
# 四个场景：有限 club 滤子公理（顶点模型）；德摩根对偶 κ∖ΔC=∇(κ∖C) 随机对拍
# （与 Agda 构造性证明互核）；推论 2.3(2) 的有限影（全枚举 2^16）；有限佛多
# （演示"有限模型里佛多没有内容"，它的牙齿要等 ω₁）。
import sys, io, random, itertools
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 77")

# ---------- 场景一：有限 club 滤子公理（club = 含顶点 n−1 的子集族） ----------
# 有限序数 n 上，"无界"= 含最大值 n−1；闭性在有限模型无内容。故 club 族
# = {C ⊆ n : n−1 ∈ C}，它满足滤子三公理：∅∉、向上封闭、交封闭。
def scene1():
    checked = 0
    for n in range(1, 8):
        top = n - 1
        subsets = [frozenset(i for i in range(n) if (m >> i) & 1) for m in range(1 << n)]
        is_club = lambda C: top in C
        assert not is_club(frozenset())                    # ∅ 不是 club
        assert is_club(frozenset({top}))                   # {顶点} 是（最小）club
        for C in subsets:
            if not is_club(C):
                continue
            for D in subsets:
                if C <= D:
                    assert is_club(D); checked += 1        # 向上封闭
                if is_club(D):
                    assert is_club(C & D); checked += 1    # 交封闭
        for b in range(top):                               # 有界集 {0..b} 非 club
            assert not is_club(frozenset(range(b + 1)))
    return checked

c1 = scene1()
print(f"场景一（有限 club 滤子）：n≤7 顶点模型下 ∅∉滤子、向上封闭、交封闭共核对 {c1} 次 ✓")

# ---------- 场景二：德摩根对偶 κ∖ΔC = ∇(κ∖C)（随机对拍，互核 Agda） ----------
def diag_int(n, Cseq):    # ΔC = {ξ : ∀j<ξ, ξ∈C_j}
    return set(xi for xi in range(n) if all(xi in Cseq[j] for j in range(xi)))
def diag_un(n, Xseq):     # ∇X = {ξ : ∃j<ξ, ξ∈X_j}
    return set(xi for xi in range(n) if any(xi in Xseq[j] for j in range(xi)))

def scene2():
    n = 6
    univ = set(range(n))
    random.seed(20260724)
    for _ in range(20000):
        Cseq = [set(i for i in range(n) if random.random() < 0.5) for _ in range(n)]
        lhs = univ - diag_int(n, Cseq)                      # κ∖ΔC
        comp = [univ - C for C in Cseq]                     # κ∖C_j
        rhs = diag_un(n, comp)                              # ∇(κ∖C)
        assert lhs == rhs
    return 20000

c2 = scene2()
print(f"场景二（德摩根对偶）：n=6 上 {c2} 个随机谓词序列逐点验证 κ∖ΔC=∇(κ∖C) ✓")

# ---------- 场景三：推论 2.3(2) 的有限影（n=4 全枚举 2^16） ----------
# "每个 X_α 不含顶点 ⟹ 对角线并 ∇X 不含顶点"（顶点 n−1 只在 ∇X 里当
# ∃j<顶点 使顶点∈X_j，故全不含顶点即 ∇X 不含顶点）。
def scene3():
    n = 4
    top = n - 1
    all_subs = [set(i for i in range(n) if (m >> i) & 1) for m in range(1 << n)]
    total = 0; checked = 0
    for a, b, c, d in itertools.product(all_subs, repeat=4):
        total += 1
        Xseq = [a, b, c, d]
        if all(top not in X for X in Xseq):
            assert top not in diag_un(n, Xseq)
            checked += 1
    return total, checked

t3, k3 = scene3()
print(f"场景三（推论 2.3(2) 有限影）：n=4 全枚举 {t3}=2^16 个序列，其中 {k3} 个满足前提，∇X 均不含顶点 ✓")

# ---------- 场景四：有限佛多（无内容演示） ----------
# 有限模型里"荟萃"= 含顶点。压小函数 f:S→n（f(ξ)<ξ，ξ≥1）。佛多结论"某纤维
# 荟萃"平凡成立：顶点所在的纤维 f^{-1}(f(顶点)) 含顶点，故荟萃。
def scene4():
    n = 5
    top = n - 1
    count_S = 0; count_f = 0
    for m in range(1 << n):
        S = [i for i in range(n) if (m >> i) & 1]
        if top not in S:
            continue
        count_S += 1
        choices = [[0] if xi == 0 else list(range(xi)) for xi in S]   # 压小取值
        for vals in itertools.product(*choices):
            f = dict(zip(S, vals))
            count_f += 1
            fiber = set(xi for xi in S if f[xi] == f[top])           # 顶点所在纤维
            assert top in fiber                                       # 含顶点 ⟹ 荟萃
            assert top in S and len({f[xi] for xi in [top]}) == 1     # {顶点} 上 f 常值
    return count_S, count_f

s4, f4 = scene4()
print(f"场景四（有限佛多）：n=5 上 {s4} 个含顶点 S、共 {f4} 个压小函数，顶点纤维恒荟萃——")
print("  有限模型里佛多无内容（{顶点} 即见证），真正的牙齿要等 ω₁ 的不可数性 ✓")

print("END ====")
