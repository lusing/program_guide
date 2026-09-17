# 11 · 集合

> 对应示例：`examples/11_collections/`

## 11.1 元组与命名元组

```julia
t = (1, "二", 3.0)                    # 异构定长；类型是 Tuple{Int, String, Float64}
t[1] == 1
a, b = (10, 20)                       # 解构
nt = (name = "Julia", year = 2012)    # 命名元组：字段名静态可知
nt.name == nt[:year] == nt[2] == ...
keys(nt)                              # (:name, :year)——Symbol 键
```

多返回值就是元组（05 章）；函数参数打包/解包也靠它（`f(t...)`）。

## 11.2 Dict：键值对

```julia
d = Dict("apple" => 3, "banana" => 5)   # => 构造 Pair
d["apple"]                      # 3
get(d, "cherry", 0)             # 0——带默认值（不存在不抛）
d["cherry"] = 7                 # 增/改
haskey(d, "banana")
pop!(d, "banana")               # 删除并返回值
delete!(d, "cherry")            # 删除（返回字典本身）
get!(d, "date", 99)             # 不存在则写入默认值
merge(d1, d2)                   # 合并，后者覆盖
for (k, v) in d                 # 直接解构遍历
```

键可以是任何支持 `hash`/`isequal` 的类型（String、Symbol、isbits struct……）。**迭代顺序不保证**——需要顺序就 `sort(collect(keys(d)))`。键不存在时裸 `d[k]` 抛 `KeyError`。

Symbol 键（`:a => 1`）：不可变interned字符串，比较是指针级——**做标识符用 Symbol、做数据用 String**。

## 11.3 Set：去重与集合运算

```julia
s = Set([3, 1, 2, 1, 3])        # 长度 3：自动去重
2 in s                          # 成员判定（\in）
push!(s, 10)
union(Set([1, 2]), Set(2:4))            # 并
intersect(Set(1:4), Set(3:8))           # 交
setdiff(Set(1:4), Set(3:8))             # 差
symdiff(Set(1:3), Set(2:4))             # 对称差
issetequal(Set([1, 2]), Set(2:-1:1))    # 只看元素不看顺序
```

递减 range 的写法是 `2:-1:1`（start:step:stop）——写成 `2:1:-1` 得到空范围（实测坑）。

## 11.4 sort 家族

```julia
sort(xs)            # 新数组（不动原表）
sort!(xs)           # 原地
sort(xs; rev = true)
sort(words)                                  # 默认字典序（大写在前：ASCII 码点）
sort(words; by = lowercase)                  # by= 变换键
sort(words; by = length, rev = true)         # 组合
sort(xs; lt = (a, b) -> a > b)               # lt= 自定义比较
sortperm([30, 10, 20])                       # [2, 3, 1]——排序后的下标序
partialsort(v, 1:3)                          # 只求最小 3 个
issorted(xs)                                 # 检查（注意 issorted 也要传 by=）
```

**`sort` 不接受 do 块**（无 `sort(f, v)` 方法，05 章实测）——自定义一律 `by=`/`lt=`。

## 11.5 迭代器：惰性是美德

```julia
collect(zip(1:3, 'a':'c'))          # [(1,'a'), (2,'b'), (3,'c')]
collect(enumerate("ab"))            # [(1,'a'), (2,'b')]
collect(Iterators.product(1:2, 1:2))    # 2×2 矩阵 [(1,1) (1,2); (2,1) (2,2)]——保持形状！
collect(Iterators.filter(isodd, 1:10))  # 惰性过滤
collect(Iterators.take(Iterators.cycle(1:2), 5))   # [1,2,1,2,1]
collect(Iterators.flatten([[1, 2], [3]]))
sum(Iterators.map(x -> x^2, 1:4))    # 惰性 map
collect(Iterators.drop(1:5, 2))      # [3, 4, 5]
pairs(nt)                            # 命名元组/数组/字典统一键值对视图（元素是 Pair）
```

注意 `cycle` 不是 Base 导出名（要 `Iterators.cycle`）；`Iterators.product` collect 出来是**矩阵**（保持笛卡尔形状，且列主序）。

## 11.6 comprehension 与 generator

```julia
sq = [x^2 for x in 1:5]                 # comprehension：落实成数组
evens = [x for x in 1:10 if iseven(x)]  # 带 if 过滤
grid = [i * j for i in 1:2, j in 1:3]   # 双变量 → 矩阵 [1 2 3; 2 4 6]
Dict(string(i) => i^2 for i in 1:2)     # 造字典
gen = sum(x^2 for x in 1:1000)          # generator：惰性、零中间数组
(x^2 for x in 1:3) isa Base.Generator   # Generator 类型（Base 命名空间）
```

comprehension vs generator：前者立刻分配容器、后者按需产出——**`sum(...)`/`count(...)` 里的过滤聚合永远用 generator**（16 章实测 8MB vs 0B）。

## 11.7 坑位清单

1. **Dict 迭代顺序不保证**：要确定性输出先 `sort(collect(keys(d)))`；跑两次顺序一致是实现细节不是承诺（11.2）。
2. **递减 range 写法**：`2:-1:1` 才是 [2,1]；`2:1:-1` 解析成 start=2 step=1 stop=-1 → 空集（11.3 实测）。
3. **`sort` 无 do 块**：自定义排序用 `by=`/`lt=` 关键字（05/11 章）。
4. **`cycle`/`rest` 等不在 Base 裸导出**：用 `Iterators.` 前缀（11.5 实测）。
5. **`Iterators.product` 的 collect 是矩阵**：形状是笛卡尔积、顺序列主序——别当平面向量用（11.5 实测）。
6. **空 zip 是 MethodError**：`collect(zip())` 报错（无限迭代器无法 collect）；空请用 `zip(1:0, ...)`。
