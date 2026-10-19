println("==== 13 lp_spaces")
# 第 13 章：离散 Lp 的全家福（6 点原子测度，权 2^-k）。
# ① Minkowski 全族（p ∈ {1,2,3,10}，随机 1000 对）；
# ② Hölder/Schwarz 紧性（最紧对逼近 1）；
# ③ L² 完备性演示（截断 Cauchy 列差范数归零）；
# ④ 对偶表现 ‖T‖ = ‖g‖_q（有限维精确等式）。

using Random

const W = [2.0^-k for k in 1:6]
const N = length(W)
normp(f, p) = sum(W[k] * abs(f[k])^p for k in 1:N; init=0.0)^(1 / p)
inner(f, g) = sum(W[k] * f[k] * g[k] for k in 1:N; init=0.0)

# --- ① Minkowski 全族 ---
Random.seed!(13)
ok = true
for _ in 1:1000, p in (1, 2, 3, 10)
    f = randn(N); g = randn(N)
    global ok &= normp(f .+ g, p) ≤ normp(f, p) + normp(g, p) + 1e-12
end
@assert ok
println("Minkowski for p in {1,2,3,10}: 1000 random pairs each, all OK")

# --- ② Schwarz 紧性 ---
best = 0.0
for _ in 1:10000
    f = randn(N); g = randn(N)
    r = abs(inner(f, g)) / (normp(f, 2) * normp(g, 2))
    global best = max(best, r)
end
@assert 0.99 < best < 1.0 + 1e-9        # 逼近 1 但不超过
# 取等构造：g = 2f 时比值恰 1
f0 = [1.0, -2.0, 3.0, 0.5, -1.0, 2.0]
g0 = 2 .* f0
@assert abs(inner(f0, g0) / (normp(f0, 2) * normp(g0, 2)) - 1.0) < 1e-12
println("Schwarz tightness: random best ratio ~1, exact equality at g=2f: OK")

# --- ③ L² 完备性：截断列 f·I_{前n} → f ---
ff = [1.0, 1/2, 1/3, 1/4, 1/5, 1/6]
dists = [normp(ff .- [ff[k] * (k <= n ? 1.0 : 0.0) for k in 1:N], 2)
         for n in 0:N]
@assert all(diff(dists) .< 0)            # 差范数单调降
@assert dists[end] == 0.0
@assert dists[1] == normp(ff, 2)         # 起点 = 全范数
println("L2 completeness demo: truncation Cauchy tail norms decrease to 0: OK")

# --- ④ 对偶表现 ‖T‖ = ‖g‖_q（有限维精确账） ---
g = [1.0, 2.0, 3.0, 4.0, 5.0, 6.0]
q = 2.0
T(f) = inner(f, g)
gnorm = normp(g, q)
# 算子范数在有限维 = ‖g‖_q：取 f = g 的对偶方向逼近
fdual = [sign(g[k]) * abs(g[k])^(q - 1) for k in 1:N]  # p-对偶方向（p=q=2: f=g）
ratio = abs(T(fdual)) / normp(fdual, 2)
@assert abs(ratio - gnorm) < 1e-12       # 取到上确界
println("dual representation: ||T|| attained exactly at dual direction = ||g||_2: OK")

println("END ====")
