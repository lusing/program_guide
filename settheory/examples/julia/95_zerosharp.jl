# 第 95 章：R(3,3)=6 穷举、五边形反例、平移不变性与蓝图一致性。
println("==== 95")

pairs_of(v) = [(v[i], v[j]) for i in 1:length(v) for j in i+1:length(v)]
triples_of(v) = [(v[i], v[j], v[k])
                 for i in 1:length(v) for j in i+1:length(v) for k in j+1:length(v)]

pairs6 = pairs_of(1:6)
idx = Dict(p => k for (k, p) in enumerate(pairs6))
triples6 = triples_of(1:6)

function colors(mask, t)
    i, j, k = t
    ((mask >> (idx[(i, j)] - 1)) & 1, (mask >> (idx[(i, k)] - 1)) & 1,
     (mask >> (idx[(j, k)] - 1)) & 1)
end

function mono_count(mask)
    c = 0
    for t in triples6
        a, b, d = colors(mask, t)
        c += (a == b == d)
    end
    return c
end

counts = [mono_count(mask) for mask in 0:(1 << 15)-1]
@assert all(counts .> 0)
@assert minimum(counts) == 2
first_min = findfirst(==(2), counts) - 1
@assert mono_count(first_min) == 2

c5(i, j) = ((j - i == 1) || (j - i == 4)) ? 1 : 0
c5mask = sum(c5(i, j) << (idx[(i, j)] - 1) for (i, j) in pairs6 if j <= 5)
for t in triples_of(1:5)
    a, b, d = colors(c5mask, t)
    @assert !(a == b == d)
end

parity(i, j) = (i + j) % 2
I7 = [1, 3, 5, 7]
J8 = [2, 4, 6, 8]
@assert all(parity(i, j) == 0 for (i, j) in pairs_of(I7))
@assert all(parity(i, j) == 0 for (i, j) in pairs_of(J8))
@assert all(parity(i + 2, j + 2) == parity(i, j) for (i, j) in pairs_of(I7))
@assert any(parity(i, j) == 1 for (i, j) in pairs_of([1, 2, 3]))

println("Julia：2^15 种六点对染色全部含齐一三元组；最少恰 2 个（经典事实）")
println("五点 C5 染色无齐一三元组 ⇒ 6 不能降为 5；平移 +2 保持偶点蓝图")
println("END ====")
