# 第 114 章：Solovay 内模型与 HOD(Ω)——与 Julia 独立对拍：群作用、
# 轨道稳定子、定义交换、配对整合、DC 链与 HOD 燃料账。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def rot(x):
    return (x + 2) % 8


U = list(range(8))


def main():
    print("==== 114")

    # ── 二、三个群作用的轨道-稳定子账本 ──
    # 群 A：加法循环群 C8，k 作用 x ↦ (x + 2k) mod 8。
    actA = lambda k, x: (x + 2 * k) % 8
    orbA = lambda x: sorted({actA(k, x) for k in U})
    stabA = lambda x: [k for k in U if actA(k, x) == x]
    okA = all(len(orbA(x)) * len(stabA(x)) == 8 for x in U)
    print(f"[群A C8: x↦x+2k] 轨道=4 点（奇偶类）、稳定子=2 元、拉格朗日 4*2=8 全员: {okA}")

    # 群 B：偶移位子群 H={0,2,4,6}，k 作用 x ↦ (x + k) mod 8。
    H = list(range(0, 7, 2))
    actB = lambda k, x: (x + k) % 8
    orbB = lambda x: sorted({actB(k, x) for k in H})
    stabB = lambda x: [k for k in H if actB(k, x) == x]
    okB = all(len(orbB(x)) * len(stabB(x)) == 4 for x in U)
    print(f"[群B 偶子群] 轨道=奇偶两类（4 点）、稳定子平凡、拉格朗日 4*1=4 全员: {okB}")

    # 群 C：翻转对 {id, x↦7-x}——不变性的反例。
    flip = lambda x: 7 - x
    flip_preserves = all(x % 2 == flip(x) % 2 for x in U)
    print(f"[群C 翻转对] 偶集在翻转下不变: {flip_preserves}"
          "（反例：0↔7、2↔5 奇偶互换——不变破缺的见证）")

    # 轨道代表（可定义代表：每条轨道取最小元）。
    repsA = sorted({min(orbA(x)) for x in U})
    print(f"[代表] 群A 轨道代表（各轨道最小元）: {repsA}——「可定义代表」的有限影子")

    # ── 三、参数化谓词与群作用交换（OD 的影子——件 A） ──
    def odef(k, x):
        return (x - k) % 8 in (0, 3, 5)

    exch_ok = all(
        odef((k + j) % 8, (x + j) % 8) == odef(k, x) for k in U for x in U for j in U
    )
    print(f"[定义交换] odef((k+j)%8, (x+j)%8) == odef(k,x) 对 8^3=512 组全真: {exch_ok}")

    invar_ok = all((x % 2 == 0) == (rot(x) % 2 == 0) for x in U)
    print(f"[不变对象] 偶集对 rot 不变: {invar_ok}")

    closed_ok = all(rot(y) in orbB(x) for x in U for y in orbB(x))
    print(f"[轨道封闭] 生成元再移一位仍在轨道内: {closed_ok}")

    # ── 四、窗口配对整合（引理 3.22(1) 机制） ──
    def gpair(m, k):
        return m + 8 * k

    vals = [gpair(m, k) for m in U for k in U]
    inj_ok = len(set(vals)) == 64
    decode_ok = all(
        gpair(m, k) % 8 == m and gpair(m, k) // 8 == k for m in U for k in U
    )
    print(f"[配对整合] gpair m+8k 在 0..7 窗口 64 值两两不同: {inj_ok}；解码往返: {decode_ok}")

    # ── 五、DC 链（引理 3.22(2) 机制核） ──
    def dchain(next_fn, a, d):
        out = []
        cur = a
        for _ in range(d):
            out.append(cur)
            cur = next_fn(cur)
        return out

    ch = dchain(rot, 0, 8)
    adj_ok = all(ch[i + 1] == rot(ch[i]) for i in range(7))
    print(f"[DC 链] next=rot 的 8 步链: {ch}（0→2→4→6→0 循环）；相邻对满足 R: {adj_ok}")

    # ── 六、HOD 燃料递归（闭包遗传——件 C） ──
    def parts(x):
        return [] if x == 0 else [x // 2]

    def inHOD(d, p, x):
        if d == 0:
            return True
        return odef(p, x) and all(inHOD(d - 1, p, y) for y in parts(x))

    def countHOD(d, p):
        return sum(1 for x in range(16) if inHOD(d, p, x))

    counts = [countHOD(d, 0) for d in (1, 2, 3, 4)]
    print(f"[HOD 燃料] p=0 的星形 {{0,3,5}} 下 0..15 各层成员数: "
          f"d=1→{counts[0]} d=2→{counts[1]} d=3→{counts[2]} d=4→{counts[3]}")
    herit_ok = all(
        (not inHOD(d + 1, 0, x)) or all(inHOD(d, 0, y) for y in parts(x))
        for d in range(1, 5)
        for x in range(16)
    )
    print(f"[闭包遗传] HOD(d+1) 成员的组件全落 HOD(d): {herit_ok}")
    assert counts == [6, 2, 1, 1]

    print("群作用三账+代表；定义交换/不变/封闭；配对整合；DC 链；HOD 燃料账")
    print("END ====")


if __name__ == "__main__":
    main()
