println("==== 25 regular_measures")
# 第 25 章：三明治构造的显影（[0,1]² 网格 Lebesgue）。
# ① 三明治：内紧/外开的账差 ≤ 网格分辨率；
# ② 外正则：开 ε-邻域账单调降收敛；
# ③ 内正则：紧穷竭账单调升；
# ④ 分形表现：Cantor 集前 n 级的内外逼近账。

using Random
Random.seed!(5)

const N = 200                       # 200×200 网格
cell() = 1.0 / (N * N)

inA(x, y) = (0.3 ≤ x ≤ 0.7 && 0.3 ≤ y ≤ 0.7)          # 方块 A
inD(x, y) = (0.2 ≤ x ≤ 0.8 && 0.2 ≤ y ≤ 0.8) && !(0.4 < x < 0.6 && 0.4 < y < 0.6)  # 环 D

# ① 三明治：K = 闭内格点（δ-内缩），U = 开外格点（δ-膨胀）
function sandwich_account(infunc, delta)
    # 内：与补集距离 ≥ delta 的格点（近似紧内集）；外：集合的 delta-膨胀
    kin = 0; muU_cells = 0
    for i in 1:N, j in 1:N
        x = (i - 0.5) / N; y = (j - 0.5) / N
        inside = infunc(x, y)
        near_in = any(infunc(x + dx, y + dy) for dx in (-delta, 0, delta),
                                               dy in (-delta, 0, delta))
        near_out = any(!infunc(x + dx, y + dy) for dx in (-delta, 0, delta),
                                                dy in (-delta, 0, delta))
        inside && !near_out && (kin += 1)          # δ-内缩格点 → K
        near_in && (muU_cells += 1)                # δ-膨胀格点 → U
    end
    kin * cell(), muU_cells * cell()
end

for (f, name, muA) in ((inA, "square", 0.16), (inD, "ring", 0.32))
    muK, muU = sandwich_account(f, 1 / N)
    @assert muK ≤ muA + 1e-12                        # 内 ≤ 真
    @assert muU ≥ muA - 1e-12                        # 外 ≥ 真
    @assert muU - muK < 0.2                          # 三明治宽度受分辨率控制
    println("sandwich ", name, ": mu(K)=", round(muK, digits = 4),
            " ≤ mu(A)=", muA, " ≤ mu(U)=", round(muU, digits = 4))
end

# ② 外正则：开 ε-邻域账单调降
function outer_eps(infunc, eps)
    cnt = 0
    for i in 1:N, j in 1:N
        x = (i - 0.5) / N; y = (j - 0.5) / N
        hit = any(infunc(x + dx * eps, y + dy * eps) for dx in (-1, 0, 1), dy in (-1, 0, 1))
        hit && (cnt += 1)
    end
    cnt * cell()
end
vals = [outer_eps(inA, e) for e in (0.08, 0.04, 0.02, 0.01)]
@assert all(vals[i] ≥ vals[i+1] - 1e-12 for i in 1:3)   # 单调降
@assert vals[end] ≥ 0.16 && vals[end] < 0.16 + 0.06
println("outer regularity: eps-neighborhood account decreases to mu(A): OK")

# ③ 内正则：紧穷竭 A ∩ [-n,n]²（在 [0,1] 上即截断）
inner_n(n) = begin
    lim = min(1.0, n / 10)
    cnt = 0
    for i in 1:N, j in 1:N
        x = (i - 0.5) / N; y = (j - 0.5) / N
        x ≤ lim && y ≤ lim && inA(x, y) && (cnt += 1)
    end
    cnt * cell()
end
iv = [inner_n(n) for n in (2, 4, 8, 10)]
@assert all(iv[i] ≤ iv[i+1] + 1e-12 for i in 1:3)       # 单调升
@assert iv[end] == 0.16                                  # 穷竭到位（截断覆盖 A）
println("inner regularity: exhaustion account increases to mu(A): OK")

# ④ 分形表现：Cantor 前 n 级（每级 2^n 段、长 3^-n）
for n in (3, 5, 7)
    len = (2 / 3)^n                                     # Cantor 集前 n 级逼近的总长
    @assert len < 0.3                                   # 快速缩水（正则性在分形上：紧集账 → 0）
end
println("Cantor levels: (2/3)^n shrinking compact accounts: OK")

println("END ====")
