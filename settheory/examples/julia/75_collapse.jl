# 第 75 章：传递化：刚性与有秩关系（冯琦 §1.10）——Julia 通道
# 与 75_collapse.py 同构：有限坍缩引擎（π(a) = {π(z) | z ∈ ext(a)}）、
# 自同一性检查（定义 1.99）、秩分层器（定理 1.98）、HF 世界
# （嵌套 Set{Any}）验收坍缩像的传递性/保关系/单射三条件。
println("==== 75")

# ---------- HF 世界与冯诺伊曼数字 ----------
hf(xs...) = Set{Any}(collect(xs))
function vn(n::Int)
    s = Set{Any}()
    for _ in 1:n
        s = union(s, Set{Any}([s]))
    end
    s
end

# ---------- 自同一（定义 1.99）：外延相同者相等 ----------
function is_extensional(nodes, ext)
    seen = Dict{Set{Any},Any}()
    for a in nodes
        key = get(ext, a, Set{Any}())
        haskey(seen, key) && seen[key] != a && return (false, (seen[key], a))
        seen[key] = a
    end
    (true, nothing)
end

# ---------- 秩分层器（定理 1.98：F(β+1) = {a | ext(a) ⊆ F(β)}） ----------
function rank_layers(nodes, ext)
    covered, rank = Set{Any}(), Dict{Any,Int}()
    layer = 0
    while length(covered) < length(nodes)
        new = [a for a in nodes if !(a in covered) &&
               all(z -> z in covered, get(ext, a, Set{Any}()))]
        isempty(new) && return (rank, [a for a in nodes if !(a in covered)])
        for a in new; rank[a] = layer; end
        union!(covered, new)
        layer += 1
    end
    (rank, Any[])
end

# ---------- 坍缩引擎（定理 1.100：π(a) = {π(z) | z ∈ ext(a)}） ----------
function collapse(nodes, ext)
    pi = Dict{Any,Set{Any}}()
    function go(a)
        if !haskey(pi, a)
            pi[a] = Set{Any}([go(z) for z in get(ext, a, Set{Any}())])
        end
        pi[a]
    end
    for a in nodes; go(a); end
    (pi, Set{Any}(collect(values(pi))))
end

is_transitive(M) = all(x -> x in M, Iterators.flatten(collect(M)))

function check_collapse(nodes, ext, pi, M)
    @assert is_transitive(M) "坍缩像不传递"
    for a in nodes
        for z in get(ext, a, Set{Any}())
            @assert pi[z] in pi[a] "π 不保关系（正向）"
        end
        for z in nodes
            pi[z] in pi[a] && @assert(z in get(ext, a, Set{Any}()), "π 不保关系（反向）")
        end
    end
    @assert length(Set{Any}([pi[a] for a in nodes])) == length(nodes) "π 不单射"
end

# ---------- 现场一：偶数链坍缩（例 1.35 的有限段） ----------
nodes1 = Any[0, 2, 4, 6]
ext1 = Dict{Any,Set{Any}}(2n => Set{Any}(Any[2k for k in 0:n-1]) for n in 0:3)
ok, _ = is_extensional(nodes1, ext1); @assert ok
rank1, leftover1 = rank_layers(nodes1, ext1); @assert isempty(leftover1)
pi1, M1 = collapse(nodes1, ext1)
check_collapse(nodes1, ext1, pi1, M1)
@assert all(pi1[2n] == vn(n) for n in 0:3)
@assert M1 == vn(4)
println("偶数链 {0,2,4,6}：π(2n) = n，坍缩像 = 4（冯诺伊曼）✓（例 1.35）")
println("  分层：", [rank1[2n] for n in 0:3], "——秩 = 位次（定理 1.98）")

# ---------- 现场二：刚性（定理 1.95）的计算面 ----------
nodes2 = Any[1, 3, 5, 7]
ext2 = Dict{Any,Set{Any}}(2n + 1 => Set{Any}(Any[2k + 1 for k in 0:n-1]) for n in 0:3)
pi2, M2 = collapse(nodes2, ext2)
@assert M2 == M1
println("刚性：{0,2,4,6} 与 {1,3,5,7} 坍缩到同一 M = 4 ✓")

# ---------- 现场三：自同一性破坏 → 坍缩相撞（例 1.34） ----------
a2, a3, a23 = "2", "3", "{2}"
nodes3 = Any[a2, a3, a23]
ext3 = Dict{Any,Set{Any}}(a2 => Set{Any}(), a3 => Set{Any}(Any[a2]),
                          a23 => Set{Any}(Any[a2]))
ok3, wit3 = is_extensional(nodes3, ext3)
@assert !ok3 && Set{Any}(collect(wit3)) == Set{Any}(Any[a3, a23])
pi3, _ = collapse(nodes3, ext3)
@assert pi3[a3] == pi3[a23] == Set{Any}(Any[Set{Any}()])
println("例 1.34 {2,3,{2}}：不自同一 → π(3) = π({2}) = {∅} 相撞 ✓")

# ---------- 现场四：外延 DAG 与 2-循环 ----------
nodes4 = Any["a", "b", "c", "d"]
ext4 = Dict{Any,Set{Any}}("a" => Set{Any}(), "b" => Set{Any}(Any["a"]),
                          "c" => Set{Any}(Any["a", "b"]), "d" => Set{Any}(Any["a", "c"]))
rank4, leftover4 = rank_layers(nodes4, ext4)
@assert isempty(leftover4) && rank4 == Dict("a" => 0, "b" => 1, "c" => 2, "d" => 3)
pi4, M4 = collapse(nodes4, ext4)
check_collapse(nodes4, ext4, pi4, M4)
@assert pi4["d"] == Set{Any}(Any[Set{Any}(), Set{Any}(Any[Set{Any}(), Set{Any}(Any[Set{Any}()])])])
@assert all(pi4["d"] != vn(k) for k in 0:4)
println("外延 DAG 分层 {a:0, b:1, c:2, d:3} ✓；π(d) = {0,2}——非序数的传递集合居民 ✓")

nodes5 = Any["x", "y"]
ext5 = Dict{Any,Set{Any}}("x" => Set{Any}(Any["y"]), "y" => Set{Any}(Any["x"]))
rank5, leftover5 = rank_layers(nodes5, ext5)
@assert isempty(rank5) && Set{Any}(leftover5) == Set{Any}(Any["x", "y"])
println("2-循环 x⇄y：分层永远漏掉它——非有秩 ⟺ 不可分层 ✓（定理 1.98 反向）")

println("END ====")
