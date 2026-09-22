# 10 · 哈希与集合：键的学问、默认值陷阱与 Set

> 对应示例：`examples/10_hashes/`

哈希的所有疑难都在「键」上：符号键还是字符串键、缺键给什么、什么算「同一个键」。这章围绕三条实测结论展开：**默认值对象会被共享**、**eql? 一票决定键相等**、**JSON 往返会换键**。末尾用 Set 收掉「数学集合」的需求。

## 10.1 字面量：符号键简写与 => 火箭

```ruby
{ a: 1, b: 2 } == { :a => 1, :b => 2 }   # 两种写法产出完全相同的哈希
{ "键" => "值", 1 => :int }              # 非符号键只能用 =>
{ a: { b: { c: 3 } } }[:a][:b][:c]       # 嵌套取值一路 []
Hash[[[:a, 1], [:b, 2]]]                 # 二维结构转哈希
{**{ a: 1 }, b: 2}                       # ** 展开：哈希也能拼

h = { a: 1 }
h[:b] = 2
h[:缺失]   # => nil（静默，是福是祸看 10.4）
```

```text

---- 10.1 字面量：符号键简写与 => 火箭 ----
{ a: 1 } 是 { :a => 1 } 的糖；h[:缺失] 返回 nil —— 拼错键不会立刻报错
```

`h[:缺失]` 返回 nil 意味着**拼错键不报错**——错误推迟到下游某处 `NoMethodError` 才爆。数据「必须存在」的读取，用 10.4 的 fetch。

## 10.2 符号键 vs 字符串键

```ruby
:a != "a"                          # 符号与字符串是两种对象，永远不相等
{ a: 1 } != { "a" => 1 }           # 键类型不同 → 两个哈希不相等
json = JSON.generate({ name: "小明", age: 9 })
parsed = JSON.parse(json)          # => { "name" => "小明", "age" => 9 } 全是字符串键
parsed["name"]                     # => "小明"；parsed[:name] => nil
JSON.parse(json, symbolize_names: true)  # => { name: "小明", ... } 换回符号键
```

```text

---- 10.2 符号键 vs 字符串键 ----
JSON.generate → parse 往返一圈，键从符号变字符串；用 symbolize_names: true 保持符号键
```

JSON 没有符号类型，所以 `generate → parse` 往返一圈键必然「换装」。代码里两套键混用（一半 `h[:name]` 一半 `h["name"]`）是真实项目最常见的 nil 来源之一：**在边界处统一**——要么 parse 时就 `symbolize_names: true`，要么全链路字符串键（`transform_keys` 见 10.7）。

## 10.3 默认值陷阱：读缺键时给的到底是什么

```ruby
counter = Hash.new(0)
counter[:a] += 1                   # 读到默认 0，+1 后写回 —— 安全

trap = Hash.new([])                # 陷阱！
trap[:a] << 1                      # << 改的是那个共享默认对象，键里还是空的！
trap[:a]                           # => [1]（读起来「有」—— 其实键没存进去）
trap.key?(:a)                      # => false（证据）
trap[:b].equal?(trap[:a])          # => true（所有缺键读到同一个对象）

fixed = Hash.new { |hash, key| hash[key] = [] }   # 正解：默认块，写入后再返回
fixed[:a] << 1
fixed.key?(:a)                     # => true，每键独立
```

```text

---- 10.3 默认值陷阱：读缺键时给的到底是什么 ----
计数用 Hash.new(0)；可变默认值必须用默认块 Hash.new { |h,k| h[k] = [] }，否则改的是共享对象
```

这条坑的机制与 9.7 的 `Array.new(3, [])` 同源：**默认值形态只求值一次**，`Hash.new([])` 里那个 `[]` 是全哈希共享的单个对象。`trap[:a] << 1` 修改的是共享对象却没写回键表，于是出现「读着有、`key?` 说没有」的灵异现场。安全线：**默认值是不可变对象（0、""）用 `Hash.new(0)`；可变对象一律默认块 `Hash.new { |h,k| h[k] = [] }`**。

## 10.4 fetch 与 dig：把「没有」变响亮或变明确

```ruby
stock = { apple: 3, banana: 0 }
stock.fetch(:apple)                          # => 3
stock.fetch(:cherry)                         # => KeyError！
stock.fetch(:cherry, 0)                      # => 0   兜底值形式
stock.fetch(:cherry) { |key| "#{key}：查无此货" }  # 块形式：能拿到键
stock.fetch(:banana, "缺货")                 # => 0（值为 0 也如实返回，与 [] 同）

profile = { user: { name: "小明", address: { city: "杭州" } } }
profile.dig(:user, :address, :city)          # => "杭州"
profile.dig(:user, :phone, :city)            # => nil（断链宽容）
profile.dig(:user, :name, :city)             # => TypeError！（中途是字符串不是哈希）
```

```text

---- 10.4 fetch 与 dig：把「没有」变响亮或变明确 ----
fetch：缺键抛 KeyError 或用兜底/块；dig：深层下钻随时可能断，断了给 nil
```

两个实测细节：

1. **fetch 对 nil/false 值诚实**：`{ a: nil }[:a]` 与缺键无法区分，`fetch(:a)` 返回 nil 就是「值真的是 nil」——想区分「缺键」与「值为空」，只有 fetch 做得到。
2. **dig 只对「断链」宽容，不对「类型错」宽容**（实测 4.0.7）：中途撞上非哈希值（这里是字符串 `"小明"`）直接抛 `TypeError`。嵌套结构形状不稳时，dig 外面还是得套一层保护或先 `is_a?(Hash)` 检查。

## 10.5 合并与筛选：merge 的块语义

```ruby
base = { a: 1, b: 2 }; extra = { b: 20, c: 3 }
base.merge(extra)                              # => { a: 1, b: 20, c: 3 }（右侧覆盖）
base.merge(extra) { |key, old, new| old + new }  # => { a: 1, b: 22, c: 3 }
base.merge!(extra)                             # merge! / update 是原地版
h5.filter_map { |k, v| k if v.odd? }           # => [:a, :c]（filter + map 合体）
h5.select { |_k, v| v.even? }                  # => { b: 2 }
```

```text

---- 10.5 合并与筛选：merge 的块语义 ----
merge(冲突块) 让「合并策略」可编程：块收 |key, old, new|，返回值即落盘值
```

merge 的块让「合并策略」成为代码：求和、保旧、取新、记日志，一个块说完。默认（无块）是**右侧覆盖左侧**——配置合并场景里「谁覆盖谁」想清楚再写。`merge` 不动原哈希，`merge!`/`update` 原地改。

## 10.6 键相等性奇观：eql? 决定一切

Hash 判「同一个键」的规则：**hash 值相等 且 eql? 为真**，缺一不可。

```ruby
1 == 1.0            # => true（== 只看数值）
1.eql?(1.0)         # => false！eql? 连类型一起比（实测 4.0.7）
1.hash.eql?(1.0.hash)  # => false（hash 值也不同）

by_num = { 1 => "整数一" }
by_num[1.0]         # => nil —— 用 1.0 找 1 的键：找不到
by_num[1.0] = "浮点一"
by_num.size         # => 2，{1=>"整数一", 1.0=>"浮点一"} 两个键并存
```

```text

---- 10.6 键相等性奇观：eql? 决定一切 ----
1 == 1.0 但 1 与 1.0 是两个键（eql? 为假）；字符串键入表即冻结复制，改原串不影响
```

（旧版行为里 `1.eql?(1.0)` 有过为真的说法，实测 4.0.7 为 **false**——以实测为准。）另一面：字符串键入哈希时被**冻结复制**，之后改原串不影响哈希里的键：

```ruby
key = +"temp"
by_str = { key => :v }
key << "-changed"     # 哈希里锁的是入表那一刻的副本
by_str["temp"]        # => :v；by_str[key] => nil
```

自定义类想当哈希键用，必须同时实现 `hash` 与 `eql?`（`==` 不够）。

## 10.7 保插入序与 transform_values / transform_keys

```ruby
ordered = {}
%w[梨 苹果 香蕉].each { |f| ordered[f] = f.length }
ordered.keys          # => ["梨", "苹果", "香蕉"]（按插入序遍历）
ordered["枣"] = 1      # 新键追加在尾部
ordered.transform_values { |v| v * 10 }   # 值批量变换：保序、原哈希不动
{ a: 1 }.transform_keys(&:to_s)           # => { "a" => 1 } 符号键 → 字符串键的常用桥
{ a: 1, b: nil, c: 3 }.compact            # => { a: 1, c: 3 }
```

```text

---- 10.7 保插入序与 transform_values / transform_keys ----
哈希按插入序遍历；transform_keys 是「符号键 ↔ 字符串键」清一色的标准工具
```

Ruby 3.0+ 哈希保插入序是语言保证（实测行为一致）——遍历顺序可依赖，但**相等性比较不问顺序**（两个哈希 `==` 只比内容）。`transform_keys` 是 10.2 键类型混乱的解药：边界处一键统一。

## 10.8 Set：无重不问序，交并差一步到位

```ruby
require "set"          # 习惯上显式 require，表意清晰
s1 = Set[1, 2, 3]; s2 = Set.new([2, 3, 4])
s1 & s2   # 交集；s1 | s2 并集；s1 - s2 差集；s1 ^ s2 对称差（只在一方出现）
s1 << 99 << 99    # 重复加无事发生，成员天然去重
Set[1, 1, 2] == Set[2, 1]         # 元素相同即相等（顺序无关）
Set[1].subset?(s1)                # 判包含
[1, 1, 2, 3, 3].to_set            # 数组去重惯用法（等价 uniq，大数组更快）
```

```text

---- 10.8 Set：无重不问序，交并差一步到位 ----
Set[1,2,3] & | - ^ 一套带走；成员去重天成，subset?/superset? 判包含
```

Set 的成员判断 O(1)，数组的 `include?` O(n)——「反复查成员」的场景直接换 Set。注意 Set 是 Enumerable，`map` 返回的还是**数组**；要顺序时转回数组排（`s1.sort.last`）。

## 10.9 坑位清单

1. **`Hash.new([])` 共享同一个默认对象**：`h[:a] << 1` 改的是共享对象且不写回，`key?` 为 false——可变默认值必须用默认块（10.3）。
2. **默认值形态只求值一次**：与 `Array.new(3, [])` 同源，不可变值（0）才可用 `Hash.new(0)`（10.3）。
3. **`dig` 中途遇非哈希抛 TypeError**：它只对断链宽容，形状不稳的结构先检查类型（10.4）。
4. **`h[:缺失]` 静默给 nil**：拼错键不报错，「必须有」的读取用 fetch（10.1、10.4）。
5. **`{ a: nil }[:a]` 与缺键无法区分**：只有 fetch 能区分「值为 nil」与「没有键」（10.4）。
6. **1 与 1.0 不是同一个键**：`1 == 1.0` 但 `1.eql?(1.0)` 为 false（实测 4.0.7），哈希里两个键并存（10.6）。
7. **自定义类当键必须实现 `hash` + `eql?`**：只写 `==` 判等不生效（10.6）。
8. **字符串键入表即冻结复制**：入哈希后再改原串，哈希里的键不变（10.6）。
9. **符号键与字符串键永不相等**：JSON 往返必换键，边界处 `symbolize_names: true` 或 `transform_keys` 统一（10.2、10.7）。
10. **merge 默认右侧覆盖左侧**：合并策略要自定义时用块 `|key, old, new|`（10.5）。
11. **`require "set"` 别忘**：Set 不是核心类自动加载的常量，漏 require 直接 NameError（10.8）。
12. **Set#map 返回数组不是 Set**：要继续集合运算得重新 `to_set`（10.8）。

---

**上一章**：[09 · 数组](09-arrays.md) | **下一章**：[11 · Enumerable 与枚举](11-enumerable.md)
