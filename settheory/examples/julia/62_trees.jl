# 第 62 章：树的机器化（Makinson Ch7）
# BST 构造/搜索/插入 + 表达式树求值 + 波兰记法 + 生成树
println("==== 62")

# ---------- 一、BST：九词构造（书本例） ----------
abstract type BT end
struct Leaf <: BT end
struct Node <: BT; l::BT; v::String; r::BT; end

insert(::Leaf, w) = Node(Leaf(), w, Leaf())
function insert(t::Node, w)
    c = cmp(w, t.v)
    if c < 0 Node(insert(t.l, w), t.v, t.r)
    elseif c > 0 Node(t.l, t.v, insert(t.r, w))
    else t end
end

search(::Leaf, _) = false
function search(t::Node, w)
    c = cmp(w, t.v)
    c == 0 && return true
    c < 0 ? search(t.l, w) : search(t.r, w)
end

height(::Leaf) = 0
height(t::Node) = 1 + max(height(t.l), height(t.r))
nodes(::Leaf) = 0
nodes(t::Node) = 1 + nodes(t.l) + nodes(t.r)

words1 = ["this","is","how","to","construct","a","binary","search","tree"]
words2 = sort(words1)   # 有序表 → 右斜链
t1 = foldl(insert, words1; init=Leaf())
t2 = foldl(insert, words2; init=Leaf())
println("  九词 BST（书本序）：高 $(height(t1))，节点 $(nodes(t1))")
println("  九词 BST（字典序）：高 $(height(t2))（右斜链——最坏情形）")
println("  search(this) = $(search(t1,"this"))，search(zero) = $(search(t1,"zero"))")

# ---------- 二、表达式树求值（x=4, y=7） ----------
expr_tree = Node(Node(Node(Leaf(),"5",Leaf()), "+",
                      Node(Node(Leaf(),"2",Leaf()),"*",Node(Leaf(),"x",Leaf()))),
                 "-",
                 Node(Node(Node(Leaf(),"y",Leaf()),"-",Node(Leaf(),"3",Leaf())),"+",
                      Node(Node(Leaf(),"2",Leaf()),"+",Node(Leaf(),"x",Leaf()))))
ev(n::String, env) = haskey(env, n) ? env[n] : parse(Int, n)
ev(t::Leaf, env) = 0
function ev(t::Node, env)
    isdigit(first(t.v)) || haskey(env, t.v) ? ev(t.v, env) :
    t.v == "+" ? ev(t.l, env) + ev(t.r, env) :
    t.v == "-" ? ev(t.l, env) - ev(t.r, env) :
    t.v == "*" ? ev(t.l, env) * ev(t.r, env) : 0
end
# 修：直接递归版
ev2(::Leaf, _) = 0
ev2(t::Node, env) =
    t.v == "+" ? ev2(t.l, env) + ev2(t.r, env) :
    t.v == "-" ? ev2(t.l, env) - ev2(t.r, env) :
    t.v == "*" ? ev2(t.l, env) * ev2(t.r, env) :
    haskey(env, t.v) ? env[t.v] : parse(Int, t.v)

env = Dict("x"=>4, "y"=>7)
println("  (5+(2·x))−((y−3)+(2+x)) 于 x=4,y=7 = ", ev2(expr_tree, env))

# ---------- 三、波兰/逆波兰记法（栈求值） ----------
function rpn(tokens, env=Dict())
    stk = Int[]
    for t in tokens
        if t in ("+", "-", "*")
            b = pop!(stk); a = pop!(stk)
            push!(stk, t == "+" ? a+b : t == "-" ? a-b : a*b)
        else
            push!(stk, haskey(env, t) ? env[t] : parse(Int, t))
        end
    end
    stk[1]
end
println("  逆波兰 [5,2,x,*,+,y,3,-,2,x,+,+,-] = ",
    rpn(["5","2","x","*","+","y","3","-","2","x","+","+","-"], env))

# ---------- 四、生成树：删圈到无简单圈 ----------
edges_g = Set([(1,2),(2,3),(3,4),(4,5),(5,1),(1,3)])
function spanning(edges, n)
    s = Set{Tuple{Int,Int}}()
    parent = collect(1:n)
    find!(p, i) = p[i] == i ? i : (p[i] = find!(p, p[i]))
    for (u, v) in sort(collect(edges))
        ru, rv = find!(parent, u), find!(parent, v)
        if ru != rv
            push!(s, (u, v))
            parent[ru] = rv
        end
    end
    s
end
st = spanning(edges_g, 5)
println("  6 边图的最小生成树（Kruskal）：", sort(collect(st)), "（$(length(st)) = n−1 条边）")

println("END ====")
