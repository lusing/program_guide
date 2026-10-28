# 第 93 章：高阶无穷导引——有限 DAG 的独立拓扑排序。
# woodinWitness 指「超紧与武丁见证的联合假设」。
println("==== 93")

nodes = [:zfc, :measurable, :supercompact, :woodinWitness]
edges = [(:zfc, :measurable), (:measurable, :supercompact),
         (:supercompact, :woodinWitness)]

function topo_sort(nodes, edges)
    indegree = Dict(n => 0 for n in nodes)
    outgoing = Dict(n => Symbol[] for n in nodes)
    for (a, b) in edges
        indegree[b] += 1
        push!(outgoing[a], b)
    end
    ready = [n for n in nodes if indegree[n] == 0]
    order = Symbol[]
    while !isempty(ready)
        a = popfirst!(ready)
        push!(order, a)
        for b in outgoing[a]
            indegree[b] -= 1
            indegree[b] == 0 && push!(ready, b)
        end
    end
    @assert length(order) == length(nodes) "存在有向环"
    return order
end

order = topo_sort(nodes, edges)
@assert order == nodes
@assert all(findfirst(==(a), order) < findfirst(==(b), order) for (a, b) in edges)
println("Kahn 拓扑排序：", join(order, " → "))
println("路径 ZFC → 可测 → 超紧 → 超紧与武丁见证联合假设；有限图无环 ✓")
println("END ====")
