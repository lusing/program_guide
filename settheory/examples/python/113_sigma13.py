# 第 113 章：Σ¹₃ 与广泛贝尔——与 Julia 独立对拍：BK 序、双树互补、
# 外延稳定性与枚举反例（四证明通道见 Lean/Coq/Agda/Isabelle）。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


# ── 一、布劳威尔-克林序（引理 3.20 机制核） ──
# bk_lt(s, t) ⟺ t ⊏ s（真前段）∨ 首异位 s(k) < t(k)。延伸者更小。
def bk_lt(s, t):
    if len(t) < len(s) and s[: len(t)] == t:
        return True
    for k in range(min(len(s), len(t))):
        if s[k] != t[k]:
            return s[k] < t[k]
    return False


def all_nodes(dmax):
    out = [()]
    for k in range(1, dmax + 1):
        out.extend(product((0, 1), repeat=k))
    return out


def space(d):
    return list(product((0, 1), repeat=d))


def main():
    print("==== 113")

    # 二元窗口 2^≤3：全 15 节点——BK 是线性序（书断言），逐对验证。
    nodes3 = all_nodes(3)
    assert len(nodes3) == 15
    pairs = [(a, b) for a in nodes3 for b in nodes3 if a != b]
    total = sum(bk_lt(a, b) != bk_lt(b, a) for a, b in pairs)
    anti = sum(not bk_lt(a, a) for a in nodes3)
    transok = all(
        not (bk_lt(a, b) and bk_lt(b, c)) or bk_lt(a, c)
        for a in nodes3
        for b in nodes3
        for c in nodes3
    )
    nilmax = all(bk_lt(s, ()) for s in nodes3 if s)
    print(f"[BK] 2^≤3 线性序: 节点 15, 完全对 {len(pairs)} 中恰好一向 {total}, "
          f"无自环 {anti}/15, 传递 {transok}, ε 最大元 {nilmax}")
    assert total == len(pairs) and anti == 15 and transok and nilmax

    # 全二叉树 depth d 的最长 BK 递降链（按线性序排序后 DP）。
    def longest_chain(d):
        ns = all_nodes(d)
        order = sorted(ns, key=lambda x: 0)  # 占位，下面用 cmp 排
        import functools

        order = sorted(ns, key=functools.cmp_to_key(
            lambda x, y: -1 if bk_lt(x, y) else (1 if bk_lt(y, x) else 0)))
        best = {n: 1 for n in ns}
        for s in order:
            for t in ns:
                if bk_lt(t, s):
                    best[s] = max(best[s], best[t] + 1)
        return max(best.values())

    chains = [longest_chain(d) for d in range(4)]
    print(f"[BK] 全二叉树最长递降链: d=0→{chains[0]} d=1→{chains[1]} "
          f"d=2→{chains[2]} d=3→{chains[3]}（= 2^(d+1)-1，线性序容纳全部节点）")
    assert chains == [2 ** (d + 1) - 1 for d in range(4)]

    # 长度 4 的全部 16 条序列：前缀链逐对递降（树枝即递降链）。
    branch_ok = sum(
        all(bk_lt(x[: k + 1], x[:k]) for k in range(4)) for x in space(4)
    )
    print(f"[BK] 16 条长度 4 序列前缀链递降: {branch_ok}/16")
    assert branch_ok == 16

    # ── 二、双树互补（定理 3.19 机制核） ──
    # caught(T, x)：x 的每一段前缀都在树 T 中（π[T] 的有限替身）。
    def caught(T, x):
        return all(x[:k] in T for k in range(len(x) + 1))

    # 稳定对：首位分裂 T = {ε}∪0⌢2^<ω，T* = {ε}∪1⌢2^<ω（对一切深度成立）。
    def pT(s):
        return not s or s[0] == 0

    def pS(s):
        return not s or s[0] == 1

    for d in range(1, 7):
        assert all(pT(x) or pS(x) for x in space(d))
        assert not any(pT(x) and pS(x) for x in space(d))
    print("[双树-稳定对] 深度 1..6 全覆盖 ✓ 不相交 ✓（对深度无量化限制=「广泛」的影子）")

    # 投影不变（外延稳定性）：细化的实数被接住 ⟹ 截断（旧实数）仍被接住。
    nref = 0
    for d in range(1, 6):
        for y in space(d + 1):
            x = y[:d]
            if pT(y):
                assert pT(x)
            if pS(y):
                assert pS(x)
            nref += 1
    print(f"[双树-稳定对] 投影不变: {nref}/{nref} 条细化路径的截断保持接住 ✓")

    # 截断对（覆盖当前宇宙 ≠ 广泛贝尔）：T = {ε,0}，T* = {ε,1}。
    tt = {(), (0,)}
    ts = {(), (1,)}
    cov1 = all(x in tt or x in ts for x in space(1))
    cov2 = all(x in tt or x in ts for x in space(2))
    fails = [x for x in space(2) if x not in tt and x not in ts]
    print(f"[双树-截断对] 覆盖深度 1: {cov1}；覆盖深度 2: {cov2} — 失败见证 {fails}")
    assert cov1 and not cov2 and len(fails) == 4

    # ── 三、枚举反例（与 Julia 独立对拍） ──
    # 2^≤2 上含根前缀闭节点集共 25 个；根交仅 {ε} 的有序对中
    # 覆盖@1 但不覆盖@2 者即「不稳定对」（当前宇宙成立 ≠ 扩张后成立）。
    def prefix_closed(sub):
        S = set(sub)
        return all(s[:k] in S for s in sub for k in range(len(s)))

    inner = [(0,), (1,), (0, 0), (0, 1), (1, 0), (1, 1)]
    closed = set()
    for mask in range(64):
        sel = {inner[i] for i in range(6) if (mask >> i) & 1}
        sel.add(())
        if prefix_closed(sel):
            closed.add(frozenset(sel))
    assert len(closed) == 25
    print(f"[枚举] 2^≤2 前缀闭节点集(含根): {len(closed)} 个")

    root_only = [(A, B) for A in closed for B in closed
                 if set(A) & set(B) == {()}]
    cov1pairs = [(A, B) for A, B in root_only
                 if all(x in A or x in B for x in space(1))]
    cov2pairs = [(A, B) for A, B in cov1pairs
                 if all(caught(A, x) or caught(B, x) for x in space(2))]
    unstable = [p for p in cov1pairs if p not in cov2pairs]
    print(f"[枚举] 根交={{ε}} 有序对 {len(root_only)}；覆盖@1 {len(cov1pairs)}；"
          f"其中覆盖@2 {len(cov2pairs)}；不稳定 {len(unstable)}")
    assert (len(root_only), len(cov1pairs), len(cov2pairs),
            len(unstable)) == (81, 64, 4, 60)

    A1, B1 = min(unstable, key=lambda AB: len(AB[0]) + len(AB[1]))
    print(f"[枚举] 最小不稳定对: T={sorted(A1, key=len)} / T*={sorted(B1, key=len)}"
          "（覆盖@1、扩张后失守——见证 (0,0)）")

    print("BK 序线性/最长链/树枝递降；稳定对全覆盖+投影不变；截断对反例；枚举 25/不稳定账")
    print("END ====")


if __name__ == "__main__":
    main()
