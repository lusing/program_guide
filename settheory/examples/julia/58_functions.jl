# 第 58 章：函数的机器化（Makinson Ch3）
# 鸽笼原理实验剧场 + 生日悖论曲线 + 特征函数 + 像与闭包
println("==== 58")

using Random

# ---------- 一、鸽笼原理蒙特卡洛：400 村民 ----------
function village_experiment(trials=2000)
    same_day = 0
    month34 = 0
    for _ in 1:trials
        birthdays = rand(1:366, 400)
        months = mod.(birthdays .- 1, 12) .+ 1
        c1 = maximum(count(==(d), birthdays) for d in unique(birthdays))
        c2 = maximum(count(==(m), months) for m in 1:12)
        c1 >= 2 && (same_day += 1)
        c2 >= 34 && (month34 += 1)
    end
    println("  400 村民 $(trials) 次模拟：")
    println("    两人同生日：$(same_day)/$(trials)（原理保证 100%）")
    println("    一月内 ≥34 人：$(month34)/$(trials)（原理保证 100%）")
end
village_experiment()

# ---------- 二、生日悖论：碰撞概率曲线 ----------
collision_prob(n, space, trials=4000) =
    count(_ -> (b = rand(1:space, n); length(unique(b)) < n), 1:trials) / trials
println("  生日悖论（365 天）：")
for n in (10, 23, 30, 50, 60)
    p = collision_prob(n, 365)
    println("    n = $(n)：碰撞概率 ≈ $(round(p*100, digits=1))%")
end
println("    （23 人已过半——比鸽笼的确定阈 366 早得多）")

# ---------- 三、四函数的像与闭包（书本 3.2.2） ----------
A4 = Set([-1, 0, 1, 2])
fs = Dict(
    "mod"    => (n -> abs(n), 5),
    "square" => (n -> n^2,    5),
    "succ"   => (n -> n + 1,  5),
    "pred"   => (n -> n - 1,  5),
)
println("  A = {−1,0,1,2} 的像与闭包（闭包迭代 5 步）：")
for (name, (f, fuel)) in fs
    img = Set(f(x) for x in A4)
    cl = Set(A4)
    for _ in 1:fuel
        cl = union(cl, Set(f(x) for x in cl))
    end
    println("    $(name)：像 = $(sort(collect(img)))；闭包 ⊇ $(sort(collect(cl)))[前若干元素]")
end

# ---------- 四、特征函数 ↔ 位串 ----------
U6 = 1:3
chi(S, u) = u in S ? 1 : 0
for S in (Set([1]), Set([1,2]), Set([2,3]), Set([1,2,3]))
    println("  χ({$(sort(collect(S)))}) = ", [chi(S, u) for u in U6])
end
A, B = Set([1,2]), Set([2,3])
println("  χ(A∩B) = χ(A)·χ(B) 逐点：",
    [chi(A ∩ B, u) for u in U6] == [chi(A,u)*chi(B,u) for u in U6] ? "✓" : "✗")
println("  χ(A∪B) = max(χ(A),χ(B)) 逐点：",
    [chi(A ∪ B, u) for u in U6] == [max(chi(A,u),chi(B,u)) for u in U6] ? "✓" : "✗")

# ---------- 五、族 vs 集合族：保留/忘掉指标 ----------
fam = [(1, Set([7])), (2, Set([7])), (3, Set([8,9]))]   # A1 = A2 = {7}
coll = Set(values(Dict(fam)))
println("  族有 $(length(fam)) 个元素，集合族只有 $(length(coll)) 个（A1=A2 被合并）")

println("END ====")
