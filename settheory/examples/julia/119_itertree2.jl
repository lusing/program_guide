# 第 119 章：有限目标选择策略；不是无限迭代树的可迭代性证明。
c_strategy(k) = k == 0 ? 0 : k - 1
bad_strategy(_) = 6
legal_target(k, p) = 0 <= p <= k && p == c_strategy(k)

# 函数与六步策略表统一分派；策略表使用 Julia 的 1 基索引。
choice(strategy, k) = strategy isa Function ? strategy(k) : strategy[k + 1]

function run_with(strategy, fuel)
    parents = Int[]
    k = 0
    while true
        k >= 6 && return (:done, Tuple(parents))
        fuel == 0 && return (:out_of_fuel, Tuple(parents))
        p = choice(strategy, k)
        legal_target(k, p) || return (:illegal, Tuple(parents))
        push!(parents, p)
        k += 1
        fuel -= 1
    end
end

const C_PARENTS = (0, 0, 1, 2, 3, 4)
@assert run_with(c_strategy, 6) == (:done, C_PARENTS)
@assert run_with(c_strategy, 5)[1] == :out_of_fuel
@assert run_with(bad_strategy, 6)[1] == :illegal

# 穷举 7^6 个策略表；吻合表恰允许唯一的完整六步策略。
function count_complete_strategies()
    total = 0
    done_count = 0
    for table in Iterators.product(ntuple(_ -> 0:6, 6)...)
        status, parents = run_with(table, 6)
        total += 1
        if status == :done
            done_count += 1
            @assert parents == C_PARENTS
        end
    end
    return total, done_count
end

total, done_count = count_complete_strategies()
@assert total == 7^6
@assert done_count == 1

# 有限二选一证书：存在良枝不等于已有跨所有树的系统选枝策略。
good = Dict(:even => false, :odd => true)
exists_good = any(values(good))
selected = Symbol[]
for branch in (:even, :odd)
    good[branch] && push!(selected, branch)
end
@assert exists_good
@assert selected == [:odd]

println("==== 119")
println("六步策略完成；短燃料与非法目标均被拒绝")
println("穷举策略表=", total, "；完整策略数=", done_count)
println("有限存在见证与选枝函数均选 Odd；不声称一般可迭代性")
println("END ====")
