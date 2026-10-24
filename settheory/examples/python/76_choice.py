# 第 76 章：选择公理与无穷和积不等式（冯琦 §2.1-2.2）——Python 通道
# 六个现场：定理 2.2 的选择函数⇄秩序往返（有限版超限递归）；问题 2.1
# "伪证"的裂缝现场（∈-极小元不唯一）；定理 2.4 佐恩引理证明的有限
# 重演（有限单射偏序的极大元=满射）；定理 2.10 柯尼希不等式第二步
# 的对角线构造（小集重演）；例 2.6(2) 的特征函数双射 2^n=|𝒫(n)|；
# 定理 2.13+豪斯多夫公式的基数指数符号求值器（ℵ 指数递推机器版）。
import sys, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")

print("==== 76")

# ---------- 现场一：定理 2.2——选择函数 ⇄ 秩序（有限版） ----------
# 方向一：选择函数 c 超限递归造秩序。F(α) = c(X − rng(F↾α))，直到取尽
def wellorder_from_choice(X, c):
    X = set(X)
    seq = []
    while X:
        a = c(frozenset(X))
        seq.append(a)
        X.discard(a)
    return seq

# 方向二：秩序 ≺ 给选择函数：c(A) = A 的 ≺-最小元（唯一！）
def choice_from_wellorder(order):
    rank = {x: i for i, x in enumerate(order)}
    return lambda A: min(A, key=lambda a: rank[a])

X = frozenset({"a", "b", "c", "d", "e"})
# 一个"任性"的选择函数：总取哈希最小的（模拟任意选择函数）
c0 = lambda A: sorted(A, key=hash)[0]
wo = wellorder_from_choice(X, c0)
assert sorted(wo) == sorted(X) and len(set(wo)) == 5
c1 = choice_from_wellorder(wo)
assert c1(frozenset(X)) == wo[0]
# 往返：由 wo 再造秩序 == wo 本身（递归的确定性）
assert wellorder_from_choice(X, c1) == wo
print(f"定理 2.2 往返：任意选择函数 c → 秩序 {wo} → 新选择函数 → 同一秩序 ✓")

# ---------- 现场二：问题 2.1 的裂缝——∈-极小元不唯一 ----------
# "伪证"：c(a) = a 的 ∈-极小元。裂缝：极小≠最小——a 可以有两个极小元，
# "取这一极小元"本身就是又一个选择问题。
a = frozenset({frozenset({0}), frozenset({1})})   # a = {{0},{1}}
minimals = [b for b in a if not (b & a)]
assert len(minimals) == 2
print(f"问题 2.1 现场：a = {{{{0}},{{1}}}} 的 ∈-极小元有 {len(minimals)} 个——")
print("  “取这一极小元”无典可依，秩序化的功劳正是把“极小”升级为唯一“最小” ✓")

# ---------- 现场三：佐恩 ⟹ 秩序原理的有限重演（定理 2.4 后半） ----------
# P = {f | f: α→X 单射, α 有限}，f ≤ g ⟺ f ⊆ g（延拓）。
# 链必有上界（并），极大元 F 必为满射（否则还能延拓一步）。
from itertools import permutations
Y = [0, 1, 2]
def injections(Y):
    out = [()]
    for k in range(1, len(Y) + 1):
        out += list(permutations(Y, k))
    return [tuple(f) for f in out]
P = injections(Y)
def extends(f, g):          # f ≤ g：g 是 f 的延拓
    return g[:len(f)] == f
def is_maximal(f, P):
    return not any(extends(f, g) and g != f for g in P)
maximals = [f for f in P if is_maximal(f, P)]
assert all(len(f) == len(Y) for f in maximals)     # 极大元皆满射
assert len(maximals) == 6                          # 3! 条双射
# 链取并=上界：一条有限链的并仍是单射
chain = [(), (0,), (0, 2), (0, 2, 1)]
assert all(extends(chain[i], chain[i + 1]) for i in range(3))
union = chain[-1]
assert all(extends(f, union) for f in chain)
print(f"佐恩有限重演：X={Y} 的 {len(P)} 个有限单射中极大元 {len(maximals)} 个，全是满射 ✓")
print("  （极大性 ⟹ 满射：X−rng(F) 非空则还能延拓一步——书载论证的有限影）")

# ---------- 现场四：柯尼希第二步的对角线（定理 2.10） ----------
# Σ κᵢ < Π λᵢ（κᵢ<λᵢ）的严格性：任意"候选覆盖" {Xᵢ}（|Xᵢ|≤κᵢ）都盖不满
# Π——对角构造 f(i) ∈ Bᵢ − {h(i) | h ∈ Xᵢ} 现场逃逸。
# 小集重演：I={0,1}，κ=(1,1)，λ=(2,2)：Σ=2 < Π=4
B = [[0, 1], [0, 1]]
from itertools import product as cart
PI = list(cart(*B))
X_cover = [[PI[0]], [PI[1]]]       # 候选覆盖：X₀={p0}, X₁={p1}（各 1 个=κᵢ）
A = [[h[i] for h in X_cover[i]] for i in range(2)]
f = tuple(next(b for b in B[i] if b not in A[i]) for i in range(2))
assert all(f not in X_cover[i] for i in range(2))
assert f in PI
# 所有 25 种候选覆盖（每格取 ≤1 个元素=κᵢ）全部逃逸成功
import itertools
escapes = 0
total = 0
for picks in itertools.product(*[[(j,) for j in range(4)] + [()] for _ in range(2)]):
    total += 1
    Xc = [[PI[j] for j in picks[i]] for i in range(2)]
    A = [[h[i] for h in Xc[i]] for i in range(2)]
    f = tuple(next(b for b in B[i] if b not in A[i]) for i in range(2))
    if all(f not in Xc[i] for i in range(2)):
        escapes += 1
assert escapes == total == 25
print(f"柯尼希对角线：Σ(1,1)=2 < Π(2,2)=4；25 种候选覆盖全被对角构造逃逸 ✓")

# ---------- 现场五：特征函数双射（例 2.6(2) 的有限身影） ----------
def char_bij(n):
    pairs = []
    for mask in range(2 ** n):
        f = tuple(1 if (mask >> k) & 1 else 0 for k in range(n))
        A = frozenset(k for k in range(n) if f[k])
        pairs.append((A, f))
    return pairs
pairs = char_bij(5)
assert len(pairs) == 32 == 2 ** 5
assert len({p[0] for p in pairs}) == 32 and len({p[1] for p in pairs}) == 32
print("2^n = |𝒫(n)|：n=5 时 32 = 32，特征函数双射逐点对拍 ✓（2^ℵ₀ = |𝒫(ω)| 的影子）")

# ---------- 现场六：基数指数符号求值器（定理 2.13 + 豪斯多夫公式） ----------
# 基数表示：("aleph", α)；("pow", λ) 连续统 2^λ；("mul", a, b) 乘积
# （乘积=max 坍缩只在 ZFC 可证一边 dominant 时应用——ℵ_i·2^{ℵ_j}
# 仅当 j+1 ≥ i（2^{ℵ_j} ≥ ℵ_{j+1} ≥ ℵ_i）才可坍缩成 2^{ℵ_j}）
def aleph(a): return ("aleph", a)
def cpow(lam): return ("pow", lam)

def show(k):
    if k[0] == "aleph":
        return f"ℵ_{k[1]}"
    if k[0] == "pow":
        return f"2^{{{show(k[1])}}}"
    return f"{show(k[1])}·{show(k[2])}"

def idx_le(k1, k2):
    """aleph 指标比较（整数与 ω 两档）。"""
    a, b = k1[1], k2[1]
    if a == "ω": return b == "ω"
    if b == "ω": return True
    return a <= b

def cmul(k1, k2):
    """乘积化简（推论 1.13 的 max 坍缩，只用 ZFC 可证的支配关系）。"""
    if k1[0] == "aleph" and k2[0] == "aleph":
        return k2 if idx_le(k1, k2) else k1
    if k1[0] == "aleph" and k2[0] == "pow" and isinstance(k1[1], int) \
       and isinstance(k2[1][1], int) and k2[1][1] + 1 >= k1[1]:
        return k2                            # ℵ_i·2^{ℵ_j} = 2^{ℵ_j}（j+1 ≥ i）
    if k2[0] == "aleph" and k1[0] == "pow" and isinstance(k2[1], int) \
       and isinstance(k1[1][1], int) and k1[1][1] + 1 >= k2[1]:
        return k1
    if k1[0] == "pow" and k2[0] == "pow":
        return k2 if idx_le(k1[1], k2[1]) else k1
    return ("mul", k1, k2)

def exp_eval(k, lam, depth=0):
    """定理 2.13 递归：κ^λ 的符号求值（每步打印依据）。"""
    steps = []
    def rec(k, lam, depth):
        ind = "  " * depth
        # (1) κ ≤ λ → 2^λ
        if idx_le(k, lam):
            steps.append(f"{ind}{show(k)}^{show(lam)} = 2^{{{show(lam)}}}（κ≤λ，定理 2.13(1)）")
            return cpow(lam)
        # 后继基数：豪斯多夫公式 κ=ℵ_{α+1}：κ^λ = κ·ℵ_α^λ
        if k[1] != "ω" and isinstance(k[1], int) and k[1] > 0:
            kp = aleph(k[1] - 1)
            steps.append(f"{ind}{show(k)}^{show(lam)} = {show(k)}·{show(kp)}^{show(lam)}"
                         f"（豪斯多夫公式，定理 2.12）")
            r = rec(kp, lam, depth + 1)
            return cmul(k, r)
        # 极限基数 + cf ≤ λ：引理 2.7（演示：ℵ_ω^λ = (sup_n ℵ_n^λ)^ω）
        steps.append(f"{ind}{show(k)}^{show(lam)} = (supₙ ℵ_n^{{{show(lam)}}})^ω"
                     f"（引理 2.7：cf(ℵ_ω)=ω）")
        return ("sup", k, lam)
    return rec(k, lam, 0), steps

r1, s1 = exp_eval(aleph(3), aleph(1))
print("指数递推样例一：")
for s in s1: print(s)
print(f"  ⇒ ℵ_3^ℵ₁ = {show(r1)}")

r2, s2 = exp_eval(aleph(2), aleph(3))
print("指数递推样例二：")
for s in s2: print(s)
print(f"  ⇒ ℵ_2^ℵ₃ = {show(r2)}")

r3, s3 = exp_eval(aleph("ω"), aleph(0))
print("指数递推样例三：")
for s in s3: print(s)

print("END ====")
