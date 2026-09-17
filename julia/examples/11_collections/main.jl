# 11 集合：Dict/Set/元组、get!/delete!/merge、sort 家族、迭代器、comprehension/generator
# 运行：julia --startup-file=no main.jl

# ═══ 11.1 元组与命名元组：定长、不可变、可异构
t = (1, "二", 3.0)
@assert t[1] == 1 && t isa Tuple{Int, String, Float64}   # 元组类型逐元素记录
@assert length(t) == 3
a, b = (10, 20)                       # 解构
@assert a + b == 30
nt = (name = "Julia", year = 2012)
@assert nt.name == "Julia" && nt[1] == "Julia" && nt[:year] == 2012
function minmax_avg(xs)               # 多返回值就是元组（05 章）
    extrema(xs)..., sum(xs) / length(xs)
end
@assert minmax_avg([1, 2, 3]) == (1, 3, 2.0)

# ═══ 11.2 Dict：键值对；任何不可变 isbits/字符串都能当键
d = Dict("apple" => 3, "banana" => 5)
@assert d["apple"] == 3
@assert haskey(d, "banana") && !haskey(d, "cherry")
@assert get(d, "cherry", 0) == 0      # 带默认值的读取（键不存在不报错）
d["cherry"] = 7                       # 增/改
@assert length(d) == 3
@assert pop!(d, "banana") == 5        # 删除并返回值
@assert delete!(d, "cherry") === d    # delete! 无值返回（链式写法的来源）
@assert get!(d, "apple", 99) == 3     # get!：不存在则写入默认值
@assert get!(d, "date", 99) == 99 && d["date"] == 99
merged = merge(d, Dict("date" => 1))  # merge：后者覆盖前者
@assert merged["date"] == 1
d2 = Dict(:a => 1, :b => 2)           # Symbol 键（不可变字符串，最快的键）
@assert d2[:a] == 1
# 迭代顺序不保证！需要有序用 OrderedDict（DataStructures.jl）或排序后遍历
ks = sort(collect(keys(d)))
@assert ks == ["apple", "date"]
for (k, v) in Dict(:x => 1)           # 直接解构键值
    @assert (k, v) == (:x, 1)
end

# ═══ 11.3 Set：去重与集合运算
s = Set([3, 1, 2, 1, 3])
@assert length(s) == 3
@assert 2 in s && !(9 in s)           # in（\in）成员判定
push!(s, 10)
@assert union(Set([1, 2]), Set(2:4)) == Set([1, 2, 3, 4])
@assert intersect(Set(1:4), Set(3:8)) == Set([3, 4])
@assert setdiff(Set(1:4), Set(3:8)) == Set([1, 2])
@assert issetequal(Set([1, 2]), Set(2:-1:1))  # 不看顺序只看元素（注意递减 range 是 2:-1:1）

# ═══ 11.4 sort 家族：sort 返回新表、sort! 原地；by/lt/rev
xs = [5, 2, 8, 1]
@assert sort(xs) == [1, 2, 5, 8] && xs == [5, 2, 8, 1]     # sort 不动原表
sort!(xs)
@assert xs == [1, 2, 5, 8]
@assert sort(xs; rev = true) == [8, 5, 2, 1]
words = ["fig", "Apple", "banana"]
@assert sort(words) == ["Apple", "banana", "fig"]           # 默认字典序（大写在前）
@assert sort(words; by = lowercase) == ["Apple", "banana", "fig"]
@assert sort(words; by = length, rev = true) == ["banana", "Apple", "fig"]
@assert sortperm([30, 10, 20]) == [2, 3, 1]                 # 排序后的"下标序"
@assert partialsort([5, 1, 9, 3, 7], 1:3) == [1, 3, 5]      # 只排前 k 个
@assert issorted(sort(xs))

# ═══ 11.5 迭代器协议与 Iterators 工具箱
itr = zip(1:3, 'a':'c')               # zip：并行迭代
@assert collect(itr) == [(1, 'a'), (2, 'b'), (3, 'c')]
@assert collect(enumerate("ab")) == [(1, 'a'), (2, 'b')]
@assert collect(Iterators.product(1:2, 1:2)) == [(1,1) (1,2); (2,1) (2,2)]     # 结果是 2×2 矩阵（保持形状）
@assert collect(Iterators.filter(isodd, 1:10)) == [1, 3, 5, 7, 9]   # 惰性 filter
@assert collect(Iterators.take(Iterators.cycle(1:2), 5)) == [1, 2, 1, 2, 1]   # cycle/take（cycle 不是 Base 导出名）
@assert collect(Iterators.flatten([[1, 2], [3]])) == [1, 2, 3]
@assert sum(Iterators.map(x -> x^2, 1:4)) == 30             # 惰性 map
pairs_kv = collect(pairs(nt))          # pairs：命名元组/数组/字典的键值对视图
@assert pairs_kv[1] == (:name => "Julia")   # 元素是 Pair（=> 构造），不是元组；== 优先级高于 =>，须加括号

# ═══ 11.6 comprehension 与 generator：一行造容器；generator 零分配
sq = [x^2 for x in 1:5]
@assert sq == [1, 4, 9, 16, 25]
evens = [x for x in 1:10 if iseven(x)]           # 带 if 过滤
@assert evens == [2, 4, 6, 8, 10]
grid = [i * j for i in 1:2, j in 1:3]            # 双变量 → 矩阵
@assert grid == [1 2 3; 2 4 6]
dict_comp = Dict(string(i) => i^2 for i in 1:2)  # 造字典
@assert dict_comp["2"] == 4
gen_total = sum(x^2 for x in 1:1000)             # generator：不建中间数组
@assert gen_total == 333_833_500
@assert (x^2 for x in 1:3) isa Base.Generator    # generator 是惰性对象（Base.Generator），collect 才落实

println("d = ", d, "；grid = ", grid, "；sum(gen) = ", gen_total)
println("==== 11 结束 ====")
