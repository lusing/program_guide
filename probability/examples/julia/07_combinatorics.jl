# -*- coding: utf-8 -*-
println("==== 07 combinatorics")
# 第 07 章 Julia：恒等式的频率形态。
# ① 随机子集的平均大小 ≈ n/2（Σ k·C(n,k) = n·2^{n-1} 的
#    频率读法）；② 球进桶分布 vs 多项式系数比例；
# ③ DNA 序列随机采样（4^n 分母的规模感）。
using Random, Statistics

Random.seed!(7)

# binomial 手写（无 Combinatorics 依赖；须在使用前定义）
function binomial(n, k)
    k < 0 || k > n ? 0 : (k == 0 ? 1 : binomial(n, k - 1) * (n - k + 1) ÷ k)
end


# ① n = 20 的随机子集平均大小（100 万次采样）
function mean_subset_size(n, trials = 200_000)
    total = 0
    for _ in 1:trials
        sz = 0
        for _ in 1:n
            rand() < 0.5 && (sz += 1)
        end
        total += sz
    end
    total / trials
end
m = mean_subset_size(20)
@assert abs(m - 10) < 0.05                 # n/2（3σ 带）
println("random subset mean size (n=20): ", round(m, digits=3),
        " -> n/2 = 10 (sum k*C(n,k) = n*2^{n-1}): OK")

# ② 3 球进 2 桶：桶 1 球数的分布 vs C(3,j)/2^3
function bin_hist(bins, balls, trials = 200_000)
    counts = zeros(Int, balls + 1)
    for _ in 1:trials
        c = 0
        for _ in 1:balls
            rand() < 1 / bins && (c += 1)
        end
        counts[c + 1] += 1
    end
    counts ./ trials
end
h = bin_hist(2, 3)
for j in 0:3
    @assert abs(h[j + 1] - binomial(3, j) / 8) < 0.005
end
println("3 balls 2 bins: bin-1 counts match C(3,j)/8 (multinomial): OK")

# ③ DNA：长度 8 序列的首次重复试验（4^8 = 65536 的规模）
function dna_first_repeat(len, trials = 100_000)
    hit = 0
    for _ in 1:trials
        seen = Set{String}()
        dup = false
        for _ in 1:50
            s = join(rand("ACGT", len))
            if s in seen
                dup = true
                break
            end
            push!(seen, s)
        end
        dup && (hit += 1)
    end
    hit / trials
end
r = dna_first_repeat(8)
@assert abs(r - 0.0185) < 0.003              # 生日式理论：C(50,2)/4^8 = 0.0187
                                            # ⟹ P(重) ≈ 1.85%
println("DNA len-8 sequences: 50 draws repeat rate = ", round(r * 100, digits=2),
        "% (birthday-type theory 1.85%): OK")

println("END ====")
