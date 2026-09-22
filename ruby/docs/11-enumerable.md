# 11 · Enumerable 与枚举：each 是根，Enumerator 与 lazy 是翅膀

> 对应示例：`examples/11_enumerable/`

Ruby 的数据处理能力几乎全部来自一个模块：Enumerable。它的契约只有一条——**你实现 `each`，它还你全套方法**。数组、哈希、Range、Set 的多数通用方法都出自这里，所以这章学的是「一份知识，四处受益」。

这章从这条契约出发，过变换族、折叠、查找，最后讲两个进阶武器：Enumerator（暂停的迭代器）与 lazy（敢碰无穷的惰性链）。

## 11.1 each 是根：include Enumerable 即获得全家

```ruby
class Playlist
  include Enumerable                # 只承诺一件事：我会 each
  def initialize(*songs)
    @songs = songs
  end

  def each(&blk)                    # 委托给内部数组的 each
    @songs.each(&blk)
  end
end

list = Playlist.new("晴天", "七里香", "稻香")
list.map { |s| s.length }           # => [2, 3, 2]（map 从未在 Playlist 里定义）
list.select { |s| s.include?("香") }  # => ["七里香", "稻香"]
list.include?("稻香") && list.first && list.count == 3   # 全部能用
```

```text

---- 11.1 each 是根：include Enumerable 即获得全家 ----
Playlist 只实现了 each，map/select/include?/count 全部免费获得
```

这是「协议优于继承」的 Ruby 典范：不继承任何数组类，只实现一个 `each` 委托，就拿到几十个方法。自己写的容器类养成习惯：`include Enumerable` + 实现 `each`，两行换全家。

## 11.2 变换族

```ruby
nums = [1, 2, 3, 4, 5, 6]
nums.map { |n| n * n }              # => [1, 4, 9, 16, 25, 36]
nums.filter_map { |n| n * 10 if n.even? }   # => [20, 40, 60]（nil 自动剔除）
nums.reject(&:even?)                # => [1, 3, 5]
%w[a b a c a b].tally               # => { "a" => 3, "b" => 2, "c" => 1 }（计数利器）
nums.group_by(&:odd?)               # => { true => [1,3,5], false => [2,4,6] }
nums.partition { |n| n > 3 }        # => [[4,5,6], [1,2,3]]
fruits.sort_by(&:length)            # => ["梨", "香蕉", "火龙果"]
nums.each_slice(2).to_a             # => [[1,2],[3,4],[5,6]]
```

```text

---- 11.2 变换族 ----
filter_map = map + compact + select；tally/group_by/partition 各管一种分堆
```

`filter_map` 是「变换中过滤掉 nil」的合体写法——块里 `if` 不命中返回 nil，结果自动剔除，比 `map.then(&:compact)` 少一趟遍历也更表意。`tally` 则把「数个数」这个高频动作收编成一词：词频统计、错误码分布一行完事。

分堆三兄弟的边界再钉一遍：`partition` 恒返回二元数组（真桶、假桶），`group_by` 返回哈希（键任意多），`tally` 返回「元素 → 出现次数」的哈希（键就是元素本身）。挑错的口诀：要「分两半」用 partition，要「按特征分桶」用 group_by，要「数个数」用 tally。

## 11.3 折叠：reduce / each_with_object

```ruby
(1..5).reduce(:+)                    # => 15（符号形式最简洁）
(1..5).reduce { |acc, n| acc * n }   # => 120（无初始值：首元素当种子）
(1..5).reduce(100) { |acc, n| acc + n }  # => 115（带初始值）
[].reduce(0, :+)                     # => 0（空集合 + 初始值才安全，否则抛错）

acc = []
(1..5).each_with_object(acc) { |n, box| box.unshift(n) }   # 元素在前，容器在后
acc                                  # => [5, 4, 3, 2, 1]
```

```text

---- 11.3 折叠：reduce / each_with_object ----
reduce 要「一个值」，each_with_object 要「一个容器」—— 块参数顺序也不同
```

两条分界线：**要一个值用 reduce，要一个容器（副作用积累）用 each_with_object**；**reduce 的块参数是 `(acc, element)`，each_with_object 是 `(element, container)`**——顺序恰好相反，混着写是经典 bug 源。空集合调无初始值的 `reduce` 直接抛错，怕空就总给初始值。

## 11.4 查找族

```ruby
scores = [58, 72, 90, 100]
scores.find { |s| s >= 90 }        # => 90（找到第一个就停）
scores.find_all { |s| s >= 72 }    # => [72, 90, 100]（找齐所有）
scores.any?(&:zero?)               # => false（至少一个？）
scores.all? { |s| s > 0 }          # => true
scores.none?(&:negative?)          # => true
[1, 2].one? { |n| n > 1 }          # => true
[1, 2, 3].one?(&:odd?)             # => false！one? 是「恰好」，不是「至少」
scores.find_index(90)              # => 2（按值找下标，也能按块找）
```

```text

---- 11.4 查找族 ----
find 找第一个、find_all 找全部、one? 是恰好一个（any? 才是至少一个）
```

`detect` 只是 `find` 的别名。最阴的一对是 `any?`/`one?`：中文语感里「有一个」含糊，Ruby 里**`any?` 是至少一个、`one?` 是恰好一个**，写错验证逻辑会静默放行不该放行的数据。查找族也吃 Enumerator：`scores.each_with_index.find { |_, i| i == 1 }` 是「按位置找」的合体套路。

## 11.5 Enumerator：方法不带块时返回 Enumerator

```ruby
[1, 2, 3, 4].each_slice(2)          # => #<Enumerator: ...>（暂停的迭代器）
[1, 2, 3, 4].each_slice(2).to_a     # => [[1, 2], [3, 4]]
%w[a b c].each_with_index.to_a      # => [["a", 0], ["b", 1], ["c", 2]]
[10, 20, 30].each.with_index(1).to_a  # => [[10, 1], [20, 2], [30, 3]]（序号从 1 起）
[1, 2, 3].map                        # => #<Enumerator: ...>（无参 map：先记账后结算）
[1, 2, 3].map.with_index { |v, i| v * i }  # => [0, 2, 6]
```

```text

---- 11.5 Enumerator：方法不带块时返回 Enumerator ----
each_slice/with_index/map 不带块 → Enumerator，可以再挂一层继续变换
```

「不带块调用 = 拿到暂停的迭代器」是 Ruby 迭代的通用语法糖：先记账（each_slice(2)），后结算（.to_a 或再挂方法）。`each.with_index(1)` 这种链式让「迭代 + 计数从 1 开始」不用手写计数器。Enumerator 还能继续链 lazy——下一节的入场券。

注意区分 `each_with_index`（方法，直接返回带索引的 Enumerator）与 `each.with_index`（先拿 each 的 Enumerator 再挂 with_index）：后者能传起始序号（`(1)`），前者永远从 0 起。要「从 1 数」时只能走链式那条路。

注意区分 `each_with_index`（方法，直接返回带索引的 Enumerator）与 `each.with_index`（先拿 each 的 Enumerator 再挂 with_index）：后者能传起始序号（`(1)`），前者永远从 0 起。要「从 1 数」时只能走链式那条路。

## 11.6 无限流与 lazy

```ruby
# 坑：直接对 (1..Float::INFINITY) 调 map 会死循环（eager 立即求值）
lazy_squares = (1..Float::INFINITY).lazy.map { |n| n * n }.select(&:even?)
lazy_squares.first(3)    # => [4, 16, 36]（1,4,9,16... 中偶数的平方）
(1..Float::INFINITY).lazy.select { |n| n.to_s.include?("7") }.first(3)
# => [7, 17, 27]（select 一直往后找直到凑够 3 个，绝不会算完无穷）
```

```text

---- 11.6 无限流与 lazy ----
(1..Float::INFINITY).lazy.map { ... }.first(3) 只算了刚好够用的几个元素
```

`lazy` 让每个元素「要用时才算」，`first(n)` 取够即停。

性能上的好处不止无穷流：长列表的多级变换链（map → select → map）用 lazy 能把中间数组压成逐元素推进，省内存也省一趟遍历。反例必须刻在脑子里：**无 lazy 的无限流调 `reduce`/`sum`/`to_a` 会死循环**——eager 模式要把无穷个元素全算完才返回，进程直接挂死（只能 Ctrl+C 或等 OOM）。lazy 链上还能继续挂 Enumerator 方法（`.lazy.each_slice(3).first(1)`）。

## 11.7 zip / flatten / flat_map

```ruby
[1, 2, 3].zip(%w[a b])              # => [[1, "a"], [2, "b"], [3, nil]]（短的一方补 nil）
[[1, [2, 3]], [4]].flatten          # => [1, 2, 3, 4]（无限展平）
[[1, [2, 3]], [4]].flatten(1)       # => [1, [2, 3], 4]（只展一层）
[1, 2, 3].flat_map { |n| [n, -n] }  # => [1, -1, 2, -2, 3, -3]（map + flatten(1) 合体）
[[1, 2], [3, 4]].map { |a, b| a + b }  # => [3, 7]（块参数对子数组自动解构）
```

```text

---- 11.7 zip / flatten / flat_map ----
zip 拉链、flatten 展平、flat_map 是「一对多变换」的正解
```

块参数自动解构（`|a, b|` 直接接 `[1, 2]`）让配对数据的处理代码非常干净。「一对多变换」（每个元素产出 0..n 个结果）用 `flat_map`，别 `map` 完再 `flatten`——后者遇到**元素本身就是数组**的数据会把不该展平的也展掉（`flatten` 无限展平 vs `flat_map` 只展一层，语义差在这）。

## 11.8 多键排序：数组字典序

```ruby
[2, 1] <=> [2, 2]    # => -1（Array#<=> 逐位比较 = 字典序）
[[1, 9], [1, 2], [0, 5]].sort   # => [[0, 5], [1, 2], [1, 9]]

people = [["tom", 92], ["jerry", 85], ["anna", 92], ["bob", 78]]
people.sort_by { |name, score| [-score, name] }
# => [["anna", 92], ["tom", 92], ["jerry", 85], ["bob", 78]]
#    分数降序（取负），同分按名字升序
```

```text

---- 11.8 多键排序：数组字典序 ----
sort_by { |x| [键1, 键2] } 用数组字典序实现多键排序，降序键取负即可
```

多键排序的标准答案：**`sort_by { |x| [键1, 键2] }`，数组 `<=>` 天然是字典序**。降序键取负（数值）或反转比较器（非数值，`sort { |a, b| b <=> a }`）。这与 9.4 的稳定性补丁（把位置并进键）是同一套思想：键是数组，一切可组合。

## 11.9 坑位清单

1. **无 lazy 的无限流 reduce/sum/to_a 会死循环**：eager 模式要算完无穷个才返回，无限流必须 `.lazy`（11.6）。
2. **`one?` 是恰好一个、`any?` 是至少一个**：中文语感陷阱，验证逻辑写反会静默放行（11.4）。
3. **reduce 与 each_with_object 块参数顺序相反**：`(acc, el)` vs `(el, box)`，混写直接逻辑错乱（11.3）。
4. **空集合 + 无初始值的 reduce 抛错**：`[].reduce(:+)` 炸，`[].reduce(0, :+)` 才安全（11.3）。
5. **`filter_map` 自动剔除 nil**：块里的条件分支返回 nil 不是 bug 是设计，别再手动 compact（11.2）。
6. **不带块调用返回 Enumerator**：`each_slice(2)` 本身不迭代，「忘了 to_a/块」拿到的是迭代器不是结果（11.5）。
7. **`zip` 短的一方补 nil**：长度不齐的数组 zip 出 nil 项，下游 `to_h` 前要想想（11.7）。
8. **`flatten` 无限展平**：元素本身是数组的数据会被展到不见，需要一层展平用 `flatten(1)` 或 `flat_map`（11.7）。
9. **`sort_by` 多键靠数组字典序**：忘写数组直接单键排，同分数据顺序乱掉（11.8）。
10. **等值元素顺序无语言保证**：跨实现/跨版本别赌 sort 稳定，要稳定把位置并进键（9.4、11.8）。
11. ** Enumerator 链上每层都是暂停点**：`map.lazy.first(2)` 只算 2 个，但去掉 lazy 就是全量算——性能敏感链路盯紧 lazy 位置（11.5、11.6）。

---

**上一章**：[10 · 哈希与集合](10-hashes.md) | **下一章**：[12 · 符号与正则](12-symbols-regex.md)
