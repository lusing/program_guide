# 第 63 章：命题逻辑（Makinson Ch8）
# 公式求值 + 五关系 + DNF 构造 + 真值树搜索
println("==== 63")

# ---------- 一、公式的 Julia 表达（嵌套元组） ----------
const Var = Symbol
const Neg = Tuple{Symbol, Any}        # (:¬, a)
const Con = Tuple{Symbol, Any, Any}   # (:∧, a, b)
const Dis = Tuple{Symbol, Any, Any}   # (:∨, a, b)

ev(v::Dict{Symbol,Bool}, p::Symbol) = v[p]
ev(v, f::Tuple{Symbol,Any}) = f[1] == :¬ ? !ev(v, f[2]) : error("bad")
ev(v, f::Tuple{Symbol,Any,Any}) =
    f[1] == :∧ ? ev(v, f[2]) && ev(v, f[3]) :
    f[1] == :∨ ? ev(v, f[2]) || ev(v, f[3]) : error("bad")

impl(a, b) = (:∨, (:¬, a), b)

# ---------- 二、五关系的判定 ----------
letters(f::Symbol) = Set([f])
letters(f::Tuple{Symbol,Any}) = letters(f[2])
letters(f::Tuple{Symbol,Any,Any}) = union(letters(f[2]), letters(f[3]))

isTaut(f) = begin
    ls = collect(letters(f))
    n = length(ls)
    all(0:(2^n-1)) do mask
        v = Dict(ls[i] => (mask >> (i-1)) & 1 == 1 for i in 1:n)
        ev(v, f)
    end
end

p, q, r = :p, :q, :r

println("  九条永真蕴含（语义验证）：")
tests = [
    ("MP", impl((:∧, p, impl(p,q)), q)),
    ("MT", impl((:∧, impl(p,q), (:¬, q)), (:¬, p))),
    ("DS", impl((:∧, (:∨, p, q), (:¬, p)), q)),
    ("右爆炸", impl((:∧, p, (:¬, p)), q)),
    ("左爆炸", impl(p, (:∨, q, (:¬, q)))),
    ("传递", impl((:∧, impl(p,q), impl(q,r)), impl(p,r))),
    ("De Morgan→", impl((:¬, (:∧, p, q)), (:∨, (:¬,p), (:¬,q)))),
    ("De Morgan←", impl((:∨, (:¬,p), (:¬,q)), (:¬, (:∧, p, q)))),
    ("分配", impl((:∧, p, (:∨, q, r)), (:∨, (:∧,p,q), (:∧,p,r)))),
]
for (name, f) in tests
    println("    $(name)：", isTaut(f) ? "✓" : "✗")
end

# 非 Taut 见证
println("  (p→q)→q 非永真：", isTaut(impl(impl(p,q), q)) ? "✓（错误！）" : "✗（正确，反例 p=F,q=T）")

# ---------- 三、DNF 语义构造 ----------
function dnf(f)
    ls = collect(letters(f))
    n = length(ls)
    basics = []
    for mask in 0:(2^n-1)
        v = Dict(ls[i] => (mask >> (i-1)) & 1 == 1 for i in 1:n)
        if ev(v, f)
            bc = v[ls[1]] ? ls[1] : (:¬, ls[1])
            for i in 2:n
                bc = (:∧, bc, v[ls[i]] ? ls[i] : (:¬, ls[i]))
            end
            push!(basics, bc)
        end
    end
    isempty(basics) && return (:∧, p, (:¬, p))
    foldr((a,b)->(:∨,a,b), basics)
end

f_test = impl(p, q)
f_dnf = dnf(f_test)
println("  p→q 的 DNF 语义等价：",
    isTaut((:∨, (:¬, f_test), f_dnf)) && isTaut((:∨, (:¬, f_dnf), f_test)) ? "✓" : "✗")

# ---------- 四、真值树（简版：活支搜索） ----------
# 对否定正常式做 tableaux：这里给"(p∧q)→r ⊨ p→r"的搜索
# 全式 ((p∧q)→r)→(p→r) 的 Taut 检测
big = impl(impl((:∧,p,q), r), impl(p, r))
println("  ((p∧q)→r)→(p→r) 是 Taut：", isTaut(big) ? "是 ✓" : "否（反例 p=T,q=F,r=F）")

println("END ====")
