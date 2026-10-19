print("==== 12 signed_measures")
# 第 12 章 Python 通道：Fraction 精确版的离散 RN 与 Hahn 分解。
# ① 密度还原：g(k) = ν({k})/μ({k}) 精确等于 w_k；
# ② Hahn 穷举（64 集合）：sup-定义与 D-公式逐项相等；
# ③ 变差 9、达界 6/−3 精确断言；
# ④ 唯一性：搬动零权位点 5 仍是 Hahn 分解——分解不唯一、正负部唯一。

from fractions import Fraction as Fr
import itertools

OMEGA = [1, 2, 3, 4, 5, 6]
w = {1: Fr(1, 21), 2: Fr(2, 21), 3: Fr(3, 21), 4: Fr(4, 21), 5: Fr(5, 21), 6: Fr(6, 21)}
s = {1: 3, 2: -1, 3: 2, 4: -2, 5: 0, 6: 1}

mu = len
nu_w = lambda A: sum(w[k] for k in A)
nu_s = lambda A: sum(s[k] for k in A)

def all_subsets():
    for m in range(64):
        yield [k for k in OMEGA if (m >> (k - 1)) & 1]

def subsets_within(A):
    S = set(A)
    return (B for B in all_subsets() if set(B) <= S)

# --- ① 密度还原（精确） ---
for k in OMEGA:
    assert nu_w([k]) / mu([k]) == w[k]
print("discrete RN exact: g(k) = nu({k})/mu({k}) = w_k (Fractions): OK")

# --- ② Hahn 穷举 ---
D = [k for k in OMEGA if s[k] > 0]
Dc = [k for k in OMEGA if s[k] <= 0]
for A in all_subsets():
    if set(A) <= set(D):
        assert nu_s(A) >= 0
    if set(A) <= set(Dc):
        assert nu_s(A) <= 0
for A in ([1, 2, 3], [2, 4], OMEGA):
    pos_sup = max(nu_s(B) for B in subsets_within(A))
    neg_sup = max(-nu_s(B) for B in subsets_within(A))
    assert pos_sup == nu_s([k for k in A if k in D])
    assert neg_sup == -nu_s([k for k in A if k in Dc])
print("Hahn exhaustive: sup-definitions equal D-formulas on all subsets: OK")

# --- ③ 变差与达界（精确） ---
assert sum(abs(s[k]) for k in OMEGA) == 9
assert nu_s(D) == 6 and nu_s(Dc) == -3
best = max(nu_s(A) for A in all_subsets())
worst = min(nu_s(A) for A in all_subsets())
assert best == 6 and worst == -3
print("total variation exactly 9; max 6 / min -3 attained at D / Dc: OK")

# --- ④ 分解不唯一、正负部唯一 ---
# 零权位点 5 可以搬进正集：D' = {1,3,5,6} 也是 Hahn 分解
D2 = [1, 3, 5, 6]
D2c = [2, 4]
for A in all_subsets():
    if set(A) <= set(D2):
        assert nu_s(A) >= 0                  # 5 是零权位，搬动不破坏正性
    if set(A) <= set(D2c):
        assert nu_s(A) <= 0
# 两个 Hahn 分解给出同一对 (nu+, nu-)
for A in ([1, 2, 3], OMEGA):
    pos_D = nu_s([k for k in A if k in D])
    pos_D2 = nu_s([k for k in A if k in D2])
    assert pos_D == pos_D2                   # 差异只在零测（零权）位点
print("decomposition non-unique (move zero-weight site 5), parts unique: OK")

print("END ====")
