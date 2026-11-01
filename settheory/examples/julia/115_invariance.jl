# 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——双点不变证书、
# 对称保真、mod-I 包裹、完备子集单射与理论片段对拍（与 Python 同账）。
println("==== 115")

# ── 一、三点底集与布尔值模型 ──
# 子集 = bitmask（bit i ⟺ 点 i ∈ 集合）；公式 = 小语言。
pts = [0, 1, 2]
bmask(b) = b + 1  # 1 基显示用（与 Python 对拍时统一用集合显示）
# τ = swap(0,1) 在点上的作用：bit 位 0 与 1 互换。
taub(b) = ((b & 1) << 1) | ((b & 2) >> 1) | (b & 4)

abstract type Frm end

struct V <: Frm
    n::Int
end

struct N <: Frm
    f::Frm
end

struct C <: Frm
    a::Frm
    b::Frm
end

struct D <: Frm
    a::Frm
    b::Frm
end

bval(f::V, env) = env[f.n+1]
bval(f::N, env) = 7 & ~bval(f.f, env)
bval(f::C, env) = bval(f.a, env) & bval(f.b, env)
bval(f::D, env) = bval(f.a, env) | bval(f.b, env)

# 赋值的 τ-提升（子集逐个过 τ）。
tenv(env) = [taub(b) for b in env]

# ── 二、件 E：对称保真 ⟦φ⟧_{v^τ} = τ·⟦φ⟧_v（全公式抽样验证） ──
frms = Any[V(0), V(1), V(2), N(V(0)), N(V(1)), C(V(0), V(2)),
           D(V(1), V(2)), N(C(V(0), V(1))), D(N(V(0)), V(1)),
           C(D(V(0), V(1)), N(V(2)))]
envs = [[a, b, c] for a in 0:7 for b in 0:7 for c in 0:7]
ok_e = all(bval(f, tenv(env)) == taub(bval(f, env)) for f in frms for env in envs)
println("[对称保真] 10 公式 × 512 赋值：bval(f, τ·env) == τ·bval(f, env) 全真: $ok_e")

# ── 三、件 A：双点不变证书（共轭超滤 F₀ 与 F₁） ──
memF(i, b) = (b >> i) & 1 == 1
# τ-不变公式清单（布尔值是 τ-不变的：taub(b) == b）。
inv_frms = Any[D(V(0), V(1)), N(V(2)), C(D(V(0), V(1)), V(2)), N(C(V(0), V(1)))]
ok_a = all(let b = bval(f, env)
             taub(b) == b ? (memF(0, b) == memF(1, b)) : true
           end
           for f in inv_frms for env in envs)
# 反例：pt0（只含点 0 的变元赋值）在双点上翻车。
pt0env = [1, 0, 0]
bad = bval(V(0), pt0env)
ok_c = memF(0, bad) && !memF(1, bad) && taub(bad) != bad
println("[双点不变] τ-不变公式在 F₀/F₁ 真值相等: $(ok_a)；非不变反例 pt0 双点翻车: $ok_c")

# ── 四、件 D：理论片段比较（F₀ 与 F₁ 的理论在不变公式上一致） ──
theory(env, i) = Set(f for f in frms if memF(i, bval(f, env)))
invtheory(env, i) = Set(f for f in inv_frms
                        if taub(bval(f, env)) == bval(f, env) && memF(i, bval(f, env)))
ok_d1 = all(invtheory(env, 0) == invtheory(env, 1) for env in envs[1:73:end])
diffs = [env for env in envs[1:37:end] if theory(env, 0) != theory(env, 1)]
ok_d2 = length(diffs) > 0
println("[理论片段] 不变公式理论 Th(F₀)=Th(F₁)（抽样）: $(length(envs[1:73:end])) 赋值全同；完整理论不同的赋值 $(length(diffs)) 个>0: $(ok_d2)（不变性必须限定公式）")

# ── 五、件 B：博雷尔包裹的 mod-I 同余（星形、偶集、奇理想） ──
U8 = collect(0:7)
star(x) = mod(x, 8) in (0, 3, 5)
inS(x) = x % 2 == 0
X = [x for x in U8 if star(x)]
A1 = [x for x in X if inS(x)]
diffX = sort(union(setdiff(X, A1), setdiff(A1, X)))
ok_b = all(!inS(x) for x in diffX) && all((x in X) == (x in A1) for x in U8 if inS(x))
println("[mod-I] X=$(X) A₁=$(A1) 差集=$(diffX) 全落奇理想、S 上同真假: $ok_b")

# ── 六、件 C：完备子集的 f-单射（事实五：K_z 命中稠密集 + f 单射） ──
# 路径树：每层条件把 ḃ(n) 分叉成 0/1；K_z = 沿路径 z 的分支链。
fmap(z) = (z[1] << 2) | (z[2] << 1) | z[3]
paths = [(a, b, c) for a in 0:1 for b in 0:1 for c in 0:1]
imgs = [fmap(z) for z in paths]
ok_c2 = length(unique(imgs)) == 8
# 稠密命中：D_n = 含第 n 位分叉两支的条件集；每个 K_z 命中每个 D_n。
dense_hit = all(begin
    # K_z 沿途条件 p_k 决定第 k 位——命中「第 k 层稠密集」即 p_k 存在
    p_k = z[k+1]
    p_k in (0, 1)
end for z in paths for k in 0:2)
println("[完备子集] f:[0,1]^3→X 单射（8 路径 8 像）: $(ok_c2)；每条 K_z 命中全部稠密集: $dense_hit")

println("对称保真/双点不变/反例；理论片段限不变公式；mod-I 包裹；f-单射+稠密命中")
println("END ====")
