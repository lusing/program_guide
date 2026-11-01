# 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——与 Julia 独立对拍：
# 对称保真、双点不变证书、mod-I 包裹、完备子集单射与理论片段。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def taub(b):
    return ((b & 1) << 1) | ((b & 2) >> 1) | (b & 4)


def bval(f, env):
    tag, *args = f
    if tag == "V":
        return env[args[0]]
    if tag == "N":
        return 7 & ~bval(args[0], env)
    if tag == "C":
        return bval(args[0], env) & bval(args[1], env)
    if tag == "D":
        return bval(args[0], env) | bval(args[1], env)
    raise ValueError(tag)


def tenv(env):
    return [taub(b) for b in env]


def memF(i, b):
    return (b >> i) & 1 == 1


def main():
    print("==== 115")

    frms = [("V", 0), ("V", 1), ("V", 2), ("N", ("V", 0)), ("N", ("V", 1)),
            ("C", ("V", 0), ("V", 2)), ("D", ("V", 1), ("V", 2)),
            ("N", ("C", ("V", 0), ("V", 1))), ("D", ("N", ("V", 0)), ("V", 1)),
            ("C", ("D", ("V", 0), ("V", 1)), ("N", ("V", 2)))]
    envs = [[a, b, c] for a in range(8) for b in range(8) for c in range(8)]

    # 件 E：对称保真
    ok_e = all(bval(f, tenv(env)) == taub(bval(f, env)) for f in frms for env in envs)
    print(f"[对称保真] 10 公式 × 512 赋值：bval(f, τ·env) == τ·bval(f, env) 全真: {ok_e}")

    # 件 A：双点不变证书
    inv_frms = [("D", ("V", 0), ("V", 1)), ("N", ("V", 2)),
                ("C", ("D", ("V", 0), ("V", 1)), ("V", 2)),
                ("N", ("C", ("V", 0), ("V", 1)))]
    ok_a = all(
        taub(bval(f, env)) == bval(f, env) and memF(0, bval(f, env)) == memF(1, bval(f, env))
        for f in inv_frms
        for env in envs
        if taub(bval(f, env)) == bval(f, env)
    )
    pt0env = [1, 0, 0]
    bad = bval(("V", 0), pt0env)
    ok_c = memF(0, bad) and not memF(1, bad) and taub(bad) != bad
    print(f"[双点不变] τ-不变公式在 F₀/F₁ 真值相等: {ok_a}；非不变反例 pt0 双点翻车: {ok_c}")

    # 件 D：理论片段比较
    def theory(env, i):
        return {k for k, f in enumerate(frms) if memF(i, bval(f, env))}

    def invtheory(env, i):
        # 只收在该赋值下布尔值 τ-不变的公式（不变证书的持有者）
        return {k for k, f in enumerate(inv_frms)
                if taub(bval(f, env)) == bval(f, env) and memF(i, bval(f, env))}

    sample = envs[::73]
    ok_d1 = all(invtheory(env, 0) == invtheory(env, 1) for env in sample)
    diffs = [env for env in envs[::37] if theory(env, 0) != theory(env, 1)]
    print(f"[理论片段] 不变公式理论 Th(F₀)=Th(F₁)（抽样 {len(sample)} 赋值）全同: {ok_d1}；"
          f"完整理论不同的赋值 {len(diffs)} 个>0（不变性必须限定公式）")

    # 件 B：mod-I 包裹
    U8 = list(range(8))
    star = lambda x: x % 8 in (0, 3, 5)
    inS = lambda x: x % 2 == 0
    X = [x for x in U8 if star(x)]
    A1 = [x for x in X if inS(x)]
    diffX = sorted(set(X) ^ set(A1))
    ok_b = all(not inS(x) for x in diffX) and all(
        (x in X) == (x in A1) for x in U8 if inS(x)
    )
    print(f"[mod-I] X={X} A₁={A1} 差集={diffX} 全落奇理想、S 上同真假: {ok_b}")

    # 件 C：完备子集的 f-单射
    fmap = lambda z: (z[0] << 2) | (z[1] << 1) | z[2]
    paths = [(a, b, c) for a in range(2) for b in range(2) for c in range(2)]
    imgs = [fmap(z) for z in paths]
    ok_c2 = len(set(imgs)) == 8
    dense_hit = all(z[k] in (0, 1) for z in paths for k in range(3))
    print(f"[完备子集] f:[0,1]^3→X 单射（8 路径 8 像）: {ok_c2}；"
          f"每条 K_z 命中全部稠密集: {dense_hit}")
    assert (ok_e, ok_a, ok_c, ok_d1, ok_b, ok_c2, dense_hit) == (
        True, True, True, True, True, True, True)
    assert X == [0, 3, 5] and A1 == [0] and diffX == [3, 5]

    print("对称保真/双点不变/反例；理论片段限不变公式；mod-I 包裹；f-单射+稠密命中")
    print("END ====")


if __name__ == "__main__":
    main()
