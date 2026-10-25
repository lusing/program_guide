# 第 84 章 · KP 与舒适集合（冯琦第二卷 §1.1）。
# 在有限累积层次 V_n 与彻底有限宇宙 HF=V_ω 上检验 KP⁻ 的存在公理：
# Δ₀-分解与精确并在传递的 V_n 里就成立；两个最高秩元素的精确对会
# 溢出 V_n，升到 HF 后秩仍有限，配对恢复。ω 的有限前段秩持续上升，
# 故 ω 不属于 HF：HF 是 KP⁻ 的模型，不是 KP 的模型。
import itertools


def vee(n):
    """levels[k] = V_k（秩 < k 的全体纯粹集合，frozenset 嵌套表示）。"""
    levels = [set()]                      # V_0 = ∅
    for _ in range(n):
        prev = sorted(levels[-1], key=repr)
        nxt = set(frozenset(c)
                  for r in range(len(prev) + 1)
                  for c in itertools.combinations(prev, r))
        levels.append(nxt)
    return levels


def rank(x):
    """von Neumann 秩：rank(x) = sup{rank(y)+1 : y ∈ x}。"""
    return 0 if not x else 1 + max(rank(y) for y in x)


def main():
    N = 4
    levels = vee(N)
    Vn = levels[N]                        # V_N 的全部元素（秩 < N）
    print("==== 84")

    trans = all(rank(y) < rank(x) < N for x in Vn for y in x)
    print("V_%d 传递：" % N, trans)
    assert trans

    def union_of(x):
        return frozenset(set().union(*[set(y) for y in x])) if x else frozenset()
    union_ok = all(rank(union_of(x)) < N for x in Vn)
    print("V_%d 满足并集公理：" % N, union_ok)
    assert union_ok

    # Δ0-分解：φ(x) ≡ ∃y∈x (y ∈ b) 是 Δ0 的；{x ∈ a : φ(x)} ⊆ a 故秩不超 a。
    def delta0_sep_holds(a, b):
        return rank(frozenset(x for x in a if any(y in b for y in x))) < N
    sep_ok = all(delta0_sep_holds(a, b) for a in Vn for b in Vn)
    print("V_%d 满足 Δ0-分解：" % N, sep_ok)
    assert sep_ok

    # 配对在 V_N 内失败：两个秩 N-1 的元素，其对的秩为 N（不在 V_N 中）。
    top = sorted([x for x in Vn if rank(x) == N - 1], key=repr)
    a, b = top[0], top[1]
    pair_fail = rank(frozenset((a, b))) >= N
    print("V_%d 配对反例存在（秩溢出）：" % N, pair_fail)
    assert pair_fail

    # 升到 HF：秩有限即属于 HF，故配对在 HF 内恢复成立。
    pair_ok = all(rank(frozenset((x, y))) < 100 for x in Vn for y in Vn)
    print("HF 内配对（秩仍有限）：", pair_ok)
    assert pair_ok

    # ω 的有限前段 {0,1,...,N} 的秩是 N+1，随 N 上升，任何 V_n 都装不下整个 ω。
    def von(k):
        s = frozenset()
        for _ in range(k):
            s = frozenset(set(s) | {s})
        return s
    om = [von(k) for k in range(N + 1)]
    omega_in = all(rank(w) == k for k, w in enumerate(om)) and rank(frozenset(om)) == N + 1
    print("ω 的前段秩为 %d，高于 V_%d：" % (N + 1, N), omega_in)
    assert omega_in

    print("END ====")


main()
