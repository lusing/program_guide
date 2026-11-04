# 第 129 章 Julia：康托-伯恩斯坦定理的构造性执行。
# 书 3.3.3 的证明是能行的：交替序列 A_n/B_n、集合 C = ⋃(A_n − B_n)、
# 分片双射 j（C 上用 h，其余恒等）。证明的对象是无穷集合（有限时
# "|A'|=|A| 且 A'⊆A"强制 A'=A，引理空洞），所以机器演示用 ℤ 的有限
# 窗口：A = ℤ，B = 2ℤ ∪ {1}，h(x) = 2x —— A' = 2ℤ ⊆ B ⊆ A 在 ℤ 中
# 严格成立；窗口只截断观察范围，不改变结构。
println("==== 129 equipollence")

const W = 64                                      # 观察窗口 [-64, 64]
h(x) = 2 * x
is_B(x) = iseven(x) || x == 1

# 交替序列（书证明的递归定义）：A_{n+1} = h[A_n]，B_{n+1} = h[B_n]，
# C = ⋃_n (A_n − B_n)。深度足够后 C 稳定（每层把偶部再减半）。
function csb_layers(depth)
    An = Set(-W:W)
    Bn = Set(x for x in -W:W if is_B(x))
    C = Set{Int}()
    for _ in 1:depth
        union!(C, setdiff(An, Bn))
        An = Set(filter(x -> -W <= x <= W, h.(collect(An))))
        Bn = Set(filter(x -> -W <= x <= W, h.(collect(Bn))))
    end
    C
end

C7 = csb_layers(7)
C8 = csb_layers(8)
@assert C7 == C8                                   # 交替序列稳定：C 不再增长
D = setdiff(Set(-W:W), C7)
@assert all(is_B, D)                               # D ⊆ B：分片恒等段落进 B
j(x) = x in C7 ? h(x) : x
@assert all(is_B, j.(collect(D)))                  # j[C] = 2C 全偶 ⟹ 落在 B
println("cantor-bernstein layers: C stable at depth 7, D subset of B: OK")

# 窗口内单射：h 在 C 上单、恒等在 D 上单、两段像不交
imgC = Set(h.(collect(C7)))
@assert isempty(intersect(imgC, D))
jwin = [j(x) for x in -W:W]
@assert length(unique(jwin)) == length(jwin)
println("piecewise j injective on window, images disjoint: OK")

# 满射的窗口审计：内窗 [-16,16] 的每个 B 元素都有原像
inner = [x for x in -16:16 if is_B(x)]
@assert all(inner) do b
    any(a -> -W <= a <= W && j(a) == b, -W:W)
end
println("j covers every B-element of the inner window: OK")

# 配对函数 f(k,n) = 2^k (2n+1) - 1（书 3.3.9）：双射的机器审计
pairkn(k, n) = 2^k * (2n + 1) - 1
seen = Set{Int}()
for k in 0:8, n in 0:40
    m = pairkn(k, n)
    @assert !(m in seen)                          # 单射（网格内无重复）
    push!(seen, m)
end
for m in 0:99                                     # 满射影子：分解 2^k·奇数 − 1
    q = m + 1
    k = 0
    while q % 2 == 0
        q ÷= 2
        k += 1
    end
    @assert pairkn(k, (q - 1) ÷ 2) == m
end
println("pairing 2^k(2n+1)-1: injective on grid, surjective on 0..99: OK")

# 可数并的交错序列（书 3.3.7）：c_{2k}=a_k, c_{2k+1}=b_k
c = Int[]
for k in 0:10
    push!(c, 2k, 2k + 1)
end
@assert c == collect(0:21)                        # 偶序列+奇序列交错 = 全体
println("countable union: interleave(evens, odds) enumerates 0..21: OK")
println("END ====")
