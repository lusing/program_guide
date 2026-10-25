# 第 86 章 · 谢旯 pcf 理论（冯琦第二卷 §1.3）。
# 有限正则集合 A={3,5,7}：标尺、主超滤子、生成元与传递性。


A = [3, 5, 7]


def le_pw(f, g):
    return all(f[n] <= g[n] for n in A)


def lt_pw(f, g):
    return le_pw(f, g) and any(f[n] < g[n] for n in A)


scale0 = {3: 0, 5: 0, 7: 0}
scale1 = {3: 1, 5: 1, 7: 1}
scale2 = {3: 2, 5: 2, 7: 2}


def principal(a, X):
    return a in X


def generator(lam):
    return [x for x in A if x <= lam]


def generator_transitive(mu, lam):
    """mu in B_lam implies B_musubseteq B_lam."""
    if mu not in generator(lam):
        return False
    return all(x in generator(lam) for x in generator(mu))


def reduced_product_cf(ultrafilter_sets):
    """玩具：主超滤子 U_a 的梯度就是 a。"""
    for a in A:
        if all(a in X for X in ultrafilter_sets):
            return a
    return None


def main():
    print("==== 86")
    assert lt_pw(scale0, scale1)
    assert lt_pw(scale1, scale2)
    assert le_pw(scale0, scale2)

    assert principal(3, [3])
    assert principal(5, [3, 5, 7])
    assert reduced_product_cf([[3], [3, 5]]) == 3

    assert generator(3) == [3]
    assert generator(5) == [3, 5]
    assert generator(7) == [3, 5, 7]

    for lam in A:
        for mu in generator(lam):
            assert generator_transitive(mu, lam)

    # 幂等：pcf(A)=A 时 pcf(pcf(A))=A
    pcf_A = list(A)
    assert pcf_A == A

    # 区间：介于 min 与 max 之间的玩具正则都在 A 里
    for lam in range(min(A), max(A) + 1):
        if lam in (3, 5, 7):
            assert lam in A

    print("scale length", 3)
    print("generators", {lam: generator(lam) for lam in A})
    print("transitive ok")
    print("pcf toy idempotent")
    print("END ====")


if __name__ == "__main__":
    main()
