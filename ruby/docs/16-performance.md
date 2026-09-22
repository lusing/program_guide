# 16 · GC 与性能

> 对应示例：`examples/16_performance/`

性能优化的原料是分配与查找：分配越多 GC 越忙，查找越慢响应越差。本章用可复现的实验对比几组经典选择（`+` vs `<<`、Array vs Hash、Struct vs OpenStruct），并立下一条贯穿全书的生产纪律——**确定性优先**。

先说这条纪律，因为它解释了本章所有输出的长相：示例 16 的文件头注释写明了约定——**stdout 必须完全确定性，所有耗时/计数只做内部断言，stdout 只打印结论**。这不是洁癖，而是验证纪律：

1. **耗时数字每次跑都不同**。`Benchmark.realtime` 的返回值受机器负载、CPU 频率、JIT 预热影响，同一台机器两次运行能差出几倍。把数字打印进输出，build 产物就不可复现，diff 会永远「脏」。
2. **本教程用「输出与结束标记逐字节比对」做验证**。任何含耗时/随机数/机器路径的内容都会让比对失败，或者逼得验证脚本加豁免规则——豁免一多，验证就名存实亡。
3. **断言比数字更有信息量**。`ok plus_diff > shovel_diff * 10` 打印成 `= true`，比打印两个毫秒数更能说明「这不是巧合，是量级差距」。源码里还刻意把 n 取大（10 万次拼接、20 万元素查找、百万次属性访问）并留足断言余量（10 倍、3 倍、1.2 倍），保证结论在慢机器上依然稳定成立。

所以本章每段实测输出里你看不到一个毫秒数——那是故意的，不是漏打。想看真实数字，自己在终端跑 `Benchmark.realtime`，别把数字写进任何需要复现的地方。

这条纪律在后两章还有两处回响：17.2 不打印 `Time.now`（时间每次都不同），18 章把 minitest 的耗时行截进 StringIO、只留 `N runs, M assertions` 摘要行——「确定性输出」是全书统一约定，本章是它的出生地。

## 16.1 对象分配与 GC

Ruby 的 GC 由 VM 自动驱动，`GC.start` 只是建议：

```ruby
GC.start                                   # 请求一次完整 GC（MBARI/分代实现下只是提示）
allocated = GC.stat(:total_allocated_objects)
before = GC.stat(:total_allocated_objects)
tmp = 100.times.map { "临时对象#{_1}" }
after = GC.stat(:total_allocated_objects)
ok after > before, "分配对象后计数应增加"
```

实测输出：

```text
GC.count 是 Integer 且 >= 1 = true，GC.stat(:total_allocated_objects) 是 Integer 且分配后变大 = true
结论：GC 由 VM 自动驱动，GC.start 只是建议；GC.stat 只做观测，别把计数写进业务逻辑
```

`GC.count` 是「GC 已发生次数」，`GC.stat(:total_allocated_objects)` 是累计分配对象数——两者都只增不减（统计意义上的）。示例只打印结论、不打印原值，因为原值每次跑都不同（这正是 16.0 说的纪律，第一处就体现在这）。实战用途：`GC.stat` 的差值是测量「某段代码分配了多少对象」的标准探针，16.2 就用它做实验——前后两次读数相减，中间代码的分配总数一目了然，而且这个数字是**确定性的**（不像耗时受负载影响），可以放心写进断言。别把计数写进业务逻辑——GC 是实现细节，不同版本数值含义可能变化。

## 16.2 字符串构造：+ 每次新建 vs << 原地扩容

循环拼接字符串，`+` 和 `<<` 的分配数差出一个数量级：

```ruby
n = 100_000                                # n 足够大，差异必然稳定
s1 = +""                                   # + 前缀拿未冻结副本（frozen_string_literal 下字面量不可原地改）
n.times { s1 = s1 + base }                 # String#+ 每轮产生全新字符串
s2 = +""
n.times { s2 << base }                     # String#<< 原地追加，几乎零分配
ok plus_diff > shovel_diff * 10
```

实测输出：

```text
+ 循环 vs << 循环（各 100000 次）：分配数对比 + 侧是 << 侧的 10 倍以上 = true（只打印结论，不打印原值）
结论：热路径拼接字符串一律用 <<（或 shovel 风格的 append），+ 在循环里是分配放大器
```

原理：`String#+` 是纯函数——每轮都新建一个「旧串 + base」的新字符串对象，n 轮就是 n 个中间对象，全靠 GC 擦屁股；`String#<<` 是原地扩容，缓冲区按需增长，分配数是个位数。10 倍是保守断言，实测余量巨大。

两个细节：`+""` 这个前缀写法是为了从 `frozen_string_literal: true` 的字面量拿一份**未冻结副本**（16.5 详述），否则 `<<` 直接抛 `FrozenError`；多段拼接更惯用的写法是把片段收进数组后一次 `parts.join`——能一次 join 就别循环 `<<`。

## 16.3 复杂度：include? O(n) vs Hash O(1)

查找是最常见的复杂度陷阱，实验用 20 万元素对比线性扫描和哈希查找：

```ruby
size = 200_000
arr = (0...size).map(&:to_s)
hash = arr.each_with_object({}) { |k, acc| acc[k] = true }
keys = %w[0 99999 199999]                  # 混合头/中/尾命中，避免「最坏情况恰好没命中」的偶然
t_array = Benchmark.realtime { 2000.times { keys.each { |k| arr.include?(k) } } }
t_hash  = Benchmark.realtime { 2000.times { keys.each { |k| hash.key?(k) } } }
ok t_array > t_hash * 3
```

实测输出：

```text
20 万元素命中查找：数组 include? 耗时 > Hash#key? 3 倍以上 = true（内部计时，只打印结论）
结论：反复 membership 检查就建 Hash/Set（O(1)）；数组线性扫描是 O(n)，n 大了就是数量级差距
```

`Array#include?` 从头线性比对，平均要看一半元素；`Hash#key?` 算一次哈希直达桶位，n 再大也是常数。示例选键很讲究——`%w[0 99999 199999]` 混合头/中/尾三个位置，避免「碰巧查第一个元素所以数组也很快」的偶然。工程规则：**循环里的 membership 检查（`include?`、`any?`），数据规模上千就该换成 Set/Hash**。热路径上这一条改动，往往胜过所有微优化。反过来也要说清楚边界：数据只有几十条时，建 Hash 的固定开销不一定回本——优化前先确认「这个集合真的会被反复查找」，别把一次性扫描也升格成 Set（17 章的 Set 专节会再回到这个主题）。

## 16.4 memoization：@cache ||=

把昂贵计算的结果缓存进实例变量，第二次调用直接取：

```ruby
def answer
  @answer ||= begin                      # 第一次算完存进 @answer，之后直接取
    @calls += 1
    (1..100).sum
  end
end
```

实测输出：

```text
连取三次 answer = 5050，真实计算次数 = 1（只算一次）
坑：@cache ||= 对 false 结果会反复重算（false 是假值）；结果可能为 false 时改用 defined?(@cache) 判断
```

`||=` 的语义是「假值就重新赋值」——`false` 和 `nil` 都是假值，所以**计算结果恰好为 false 时，缓存永远失效，每次都重算**。结果可能为 false 时改用：

```ruby
# 示意（示例源码注释给出的修法）
def answer
  return @answer if defined?(@answer)
  @answer = 昂贵计算
end
```

memoization 的第二层代价：缓存的是**实例状态**，对象的其余部分变了缓存不会失效——`@answer` 缓存了基于 `@x` 的计算，改 `@x` 后拿到的是旧值。缓存什么、随什么失效，写 memoization 时要想清楚。

## 16.5 frozen string 的收益

`# frozen_string_literal: true` 魔法注释下，字符串字面量一律冻结：

```ruby
f1 = "hello"                               # frozen_string_literal: true 下字面量即冻结
f2 = "hello"                               # 相同字面量被去重：同一个对象
ok f1.frozen? && f2.frozen?
ok f1.object_id == f2.object_id, "相同冻结字面量应去重为同一对象"
u = f1.upcase                              # 冻结串上的「修改」都返回新串，原串不动
begin; f1.upcase!; rescue FrozenError; raised = true; end
```

实测输出：

```text
相同冻结字面量 object_id 相同（去重）= true；upcase 返回新串且原串不变 = true
结论：frozen_string_literal 省内存（去重）且杜绝意外突变；要改就 +"" 或 .dup
```

两份收益：**去重**（相同字面量共享同一个对象，一万个 `if x == "error"` 只有一个 `"error"` 对象）和**不可变**（不存在「谁悄悄改了共享字面量」这类事故）。对应的坑：冻结串上所有 `!` 方法（`upcase!`、`<<`）抛 `FrozenError`；要一份可变副本，用 `+""`（返回未冻结的新串）或 `.dup`。这是 16.2 里 `s1 = +""` 的由来。改不了字符串就逼你写出「每次返回新串」的纯函数式代码，意外突变的 bug 类别被整个消灭。

## 16.6 结构选择：Struct vs OpenStruct

字段固定的记录用 `Struct`，别用 `OpenStruct`：

```ruby
Point = Struct.new(:x, :y)                 # 定义时就生成实体方法，访问是直接调用
p1 = Point.new(1, 2)
op1 = OpenStruct.new(x: 1, y: 2)
m = 1_000_000                              # n 足够大；实测倍数 1.6~2.4，断言放宽到 1.2 留足余量
t_struct = Benchmark.realtime { m.times { p1.x } }
t_ostruct = Benchmark.realtime { m.times { op1.x } }
ok t_ostruct > t_struct * 1.2
```

实测输出：

```text
百万次属性访问：OpenStruct 耗时 > Struct 1.2 倍以上 = true（内部计时，只打印结论）
结论：字段固定的记录用 Struct（快、省）；OpenStruct 灵活（任意键）但每走一次 method_missing，热路径别用
```

原因在方法查找：`Struct` 在定义时生成了实体方法 `x`/`y`，访问是普通方法调用；`OpenStruct` 没有任何实体方法，**每次读写都走 method_missing**——完整经历「方法查找失败 → method_missing → 哈希读写」，15.2 讲过的机制在这里变成性能税。实测倍数 1.6~2.4，断言放宽到 1.2 留余量。选择规则：字段编译期已知 → Struct（快、省内存）；键真的任意且访问稀疏 → OpenStruct 或干脆 Hash。

## 16.7 Benchmark 标准库

`benchmark` 是标准库，测耗时的最小 API：

```ruby
require "benchmark"   # 只验证 API 存在性，不打印任何耗时原值
v = Benchmark.realtime { 1 + 1 }           # 返回块执行耗时（秒，Float）
ok v.is_a?(Float) && v >= 0
```

实测输出：

```text
Benchmark.realtime { } 返回 Float = true，Benchmark.bm/measure 均可用（结论打印，数值不打印）
结论：Benchmark 用于开发期测量；本教程 stdout 只打印结论，因为耗时数字每次跑都不同
```

`Benchmark.realtime` 返回块执行秒数（Float）；`Benchmark.bm`/`measure` 可产出对比报表，但它们的输出天生含耗时数字——**只在交互终端用，不进需要复现的产物**。测什么也要讲究：单次微操作（纳秒级）直接测噪声大于信号，要像 16.3/16.6 那样循环千万次取总量；同时警惕 GC 干扰，精确测量前 `GC.start` 并用 `GC.stat` 差值把分配数也看一眼（16.1 的探针手法）。

本章的实验设计可以总结成一条可复用的配方：**大 n 拉开量级 → 内部计时/计数 → 保守倍数断言 → 只打印结论**。性能优化的证据链应该像测试一样可自动判定，而不是靠肉眼比较两个每次都不同的毫秒数。

## 16.8 坑位清单

1. **stdout 打印耗时数字毁掉可复现性**：耗时/随机数/机器路径一律不进确定性输出——内部断言只打印结论（16.0、16.7）。
2. **循环里用 `+` 拼字符串是分配放大器**：每轮新建对象，分配数是 `<<` 的 10 倍以上——热路径一律 `<<` 或 `join`（16.2）。
3. **`frozen_string_literal` 下对字面量 `<<` 抛 `FrozenError`**：可变副本用 `+""` 或 `.dup`（16.5、16.2）。
4. **`Array#include?` 在循环里是 O(n)**：n 上千就该换 Hash/Set 的 O(1) 查找——20 万元素实测数量级差距（16.3）。
5. **`@cache ||=` 对 false 结果反复重算**：`false` 是假值，缓存永远失效——可能为 false 时改用 `defined?(@cache)` 判断（16.4）。
6. **memoization 缓存不随依赖失效**：`@answer` 基于 `@x` 算出后，改 `@x` 拿到的还是旧值——想清楚缓存随什么失效（16.4）。
7. **`GC.start` 只是建议**：VM 自动驱动 GC，别指望它做确定性的内存管理，更别把 GC.stat 计数写进业务逻辑（16.1）。
8. **OpenStruct 每次访问走 method_missing**：百万次访问实测比 Struct 慢 1.2 倍以上（真实 1.6~2.4）——热路径字段固定就用 Struct（16.6）。
9. **微基准噪声大于信号**：单次操作直接测毫无意义——循环百万次取总量，测前 `GC.start` 排干扰（16.7）。
10. **去重收益依赖冻结**：相同字面量只有写魔法注释才去重成同一对象，省内存的前提是 `frozen_string_literal: true`（16.5）。
11. **性能结论要用「量级断言」验证而不是肉眼比数字**：`ok t_array > t_hash * 3` 这种留足余量的断言在慢机器上也稳定成立（16.3、16.6）。
12. **只测命中路径会骗自己**：查第一个元素的数组也很快——测试键要混合头/中/尾甚至未命中（16.3）。

---

[上一章](15-metaprogramming.md) | [下一章](17-stdlib.md)
