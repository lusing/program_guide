# 09 · 集合：Keyword / Map / Struct / MapSet

> 对应示例：`examples/09_collections/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

很多语言用一个 `HashMap` 打天下，Elixir 却把「键值」拆成四种结构。
它们不是语法糖变体，而是**底层数据结构完全不同、复杂度特性不同、适用场景不同**的四样东西：

| 结构 | 底层 | 键 | 重复键 | 顺序 | 典型用途 |
|---|---|---|---|---|---|
| Keyword | 键值元组**列表** | 仅原子 | 允许 | 有序 | 函数选项 |
| Map | flatmap / hashmap | 任意类型 | 不允许 | 无序 | 通用键值数据 |
| Struct | 带标记的 Map | 原子，编译期固定 | 不允许 | 字段定义序 | 有名字的实体类型 |
| MapSet | Map 的键集合 | 任意类型 | — | 无序 | 去重、集合运算 |

先记住一句话：**选项用 Keyword，数据用 Map，实体用 Struct，去重用 MapSet。**

## 9.1 Keyword：选项列表的真身

`[a: 1, b: 2]` 不是什么特殊对象，它就是 `[{:a, 1}, {:b, 2}]` 的语法糖——
一个原子键二元组列表。这个出身决定了它的全部特性：

```text
inspect 真身: [a: 1, b: 2]
重复键 opts=[a: 1, b: 2, a: 3]
  Keyword.get(:a)   => 1（取第一个）
  get_values(:a)    => [1, 3]
  [b:2,a:1]==[a:1,b:2] => false（顺序敏感）
  set_option 去重并置顶 => [a: 9, b: 2]
  greet 用法        => "HOLA, ADA"
```

- **允许重复键**：`Keyword.get/2` 取第一个，`Keyword.get_values/2` 取全部。
  重复键在语法上合法，个别库（如 Ecto 的 `select`）刻意利用它；
- **顺序敏感**：列表逐元素比较，`[b: 2, a: 1] != [a: 1, b: 2]`；
- **线性查找 O(n)**：`get` 要从头扫列表。所以 Keyword 只用于「几个、十几个选项」
  这种短列表，绝不装大量业务数据；
- **库函数的标准签名是 `name + opts`**：

```elixir
def greet(name, opts \\ []) do
  prefix = Keyword.get(opts, :prefix, "Hello")
  ...
end
```

本章的 `option/3` 就是这层封装；`set_option/3` 对应写入用的 `Keyword.put/3`
（替换第一个同名键、删掉其余同名键、再挪到列表头部）。

## 9.2 Map：通用键值结构

Map 的键可以是任意 Elixir 术语，同一结构里还能混放不同类型的键：

```elixir
%{:a => 1, "a" => 2, {1, 2} => 3}   # 合法：三个不同的键
%{a: 1} == %{:a => 1}               # true：a: 是原子键的语法糖
```

两个必须钉死的事实：

**1）相等与键顺序无关，但展示顺序不保证。**

```text
  字面量 %{z:1,a:2,m:3} 的 inspect 顺序不保证（+S1:1 下实测不同），本工程一律排序打印
  sorted_pairs 排序输出 => [a: 2, m: 3, z: 1]
  键序无关的相等        => true
```

Map 在键数不超过 32 时内部是按存储排布的 flatmap，超过后切换成 hashmap；
**同一份代码在 `+S 1:1`（单调度器）下 inspect 出的键序都可能不同**
（本章 `run-all.sh` 开发过程中实测翻车）。因此：

- 比较两个 map 直接用 `==`，顺序无关，这是安全的；
- **要打印/序列化给人看，先 `Enum.sort`**，本教程所有 map 输出走 `sorted_pairs/1`。

**2）大 map 的存取依然高效。**

```text
  40 键大 map map_size => 40，取 key=33 => 1089
  merge_counters 冲突求和 => [a: 1, b: 12, c: 3]（排序后输出）
```

`map_size/1` 是 O(1)，按键取值在大 map 上是 O(log n)。
合并用 `Map.merge/2`（后者覆盖冲突键）或 `Map.merge/3`（冲突键交给用户函数）。

## 9.3 Struct：带类型的 Map

Struct 是「字段在编译期固定、还带一个 `__struct__` 标记键」的 map：

```elixir
defmodule Ex09Collections.User do
  @enforce_keys [:id]
  defstruct id: nil, name: "anonymous", tags: [], admin: false
end
```

```text
  user_from_map => %Ex09Collections.User{id: 7, name: "Ada", tags: [], admin: false}
  promote 更新 => %Ex09Collections.User{id: 7, name: "Ada", tags: [], admin: true}
  add_tag 去重 => %Ex09Collections.User{id: 7, name: "Ada", tags: ["beam"], admin: false}
  shape 分派: point/user/plain_map => point / user / plain_map
  点语法 1.20 => Ada；去掉 __struct__ 退回普通 map
  struct! 未知键抛 KeyError；@enforce_keys 漏键抛 ArgumentError；未知字段展开即报错
```

Struct 带来的是普通 map 给不了的三样东西：

1. **名义类型**。`%User{}` 模式只匹配 User，字段一模一样的普通 map 不匹配——
   所以 `shape/1` 能按结构体名分派。函数参数写成 `%User{} = user`，
   传错类型会在入口得到 FunctionClauseError，而不是把数据悄悄改坏；

2. **编译期字段检查**。`%{user | admin: true}` 更新语法里写错字段名，
   编译期就过不去；多给未知键（`%User{bogus: 1}`）在展开时即报错；

3. **构造契约**。`@enforce_keys [:id]` 让漏键的构造抛 ArgumentError；
   `struct!/2` 对未知键抛 KeyError，而宽松的 `struct/2` 会静默忽略未知键。
   处理外部输入时通常要严格的那个。

另外两点结构事实：`Map.from_struct/1` 剥掉 `__struct__` 返回普通 map；
反过来 `Map.delete(struct, :__struct__)` 也能把一个 struct 变成普通 map。

## 9.4 MapSet：去重与集合代数

MapSet 是建立在 Map 之上的集合（值存的是键，所以 map 值全是 nil）：

```text
  uniq_sorted([3,1,3,2,1]) => [1, 2, 3]
  venn([1,2,3],[2,3,4])    => %{union: [1, 2, 3, 4], inter: [2, 3], only_left: [1]}
  member? 2 / 9            => true / false
```

- 「去重」最省事的写法是 `list |> MapSet.new() |> MapSet.to_list()`，别自己写 reduce；
- 集合代数：`union/2`、`intersection/2`、`difference/2`、`subset?/2`；
- **复杂度纪律**：`MapSet.member?/2` 是 O(log n)，而 `Enum.member?/2` 是 O(n)。
  「在一个大列表里反复查是否存在」先转 MapSet 再查，是常见的性能修复；
- MapSet 是不透明结构，展示同样要排序（本章的 `venn/2` 三个结果都排了序）。

## 9.5 Access：data[key] 的规则

`data[key]` 不是 map 专属语法，它走的是 **Access 行为**：

```text
  map[:missing] => nil；nil[:b] => nil（一路 nil 下去）
  %User{}[:id] => :raises_undefined_function_error（struct 不实现 Access）
  Map.get 三参可给默认值 => nil（值是 nil 与缺失不同：Access 分不清）
```

规则逐条：

- map 和 keyword 都实现了 Access：键缺失返回 **nil**，不抛异常；
- **`nil` 也实现了 Access**：`nil[:b]` 返回 nil。所以 `data[:a][:b][:c]`
  可以一路链式下钻，任何一层缺失都安静地变成 nil——这就是「nil 安全」；
- **Struct 不实现 Access**：`%User{}[:id]` 抛 UndefinedFunctionError
  （1.20 的报错信息会提示用 `user.field` 点语法或 `Access.key!/1`）；
- MapSet 也不实现 Access（没有 `fetch/2`）；
- nil 安全的代价：**区分不了「键缺失」和「值就是 nil」**。
  需要区分时用 `Map.fetch/2`（返回 `{:ok, v}` / `:error`）或 `Map.get/3` 给默认值。

## 9.6 get_in / put_in 家族：路径式深取深改

深层嵌套的数据，用路径（键的列表）来取和改：

```text
  dig 字符串键 + Access.at => "Ada"
  dig 缺失一路 nil          => nil
  bump_in 沿路径 +1         => %{stats: %{count: 2}}
  pluck Access.all 批量取   => [1, 2]
  tuple_nth Access.elem     => :b
  pop_in 取出并删除         => {1, %{b: 2}}
```

```elixir
get_in(data, [:db, :port])                 # keyword / map 用裸原子键
get_in(json, ["users", Access.at(0), "name"])  # JSON 用字符串键 + 列表下标
update_in(data, [:stats, :count], &(&1 + 1))
put_in(data, [:db, :port], 6543)
pop_in(data, [:debug])
get_and_update_in(data, [:a], fn v -> {v, v + 1} end)
```

要点：

- 路径里**列表位置不能用裸下标**（`0` 不是键），必须写 `Access.at(0)`；
- 可组合的路径片段还有 `Access.all/0`（遍历列表每个元素）、
  `Access.elem/1`（元组位置）、`Access.key/3`（动态键 + 默认值）；
- 这些函数都有两种形式：**函数形式**（路径是运行时数据）和
  **宏形式**（编译期已知路径）：`put_in(data.a.b, 9)`、`update_in(data.count, &... )`。
  宏形式中间层缺失会报错，不自动建层。

## 9.7 选型决策

```text
  函数的可选参数      -> Keyword（opts :: keyword()）
  外部数据/通用键值   -> Map（键类型混合、需要哈希查找）
  有明确字段的实体     -> Struct（模式分派、编译期字段检查）
  只需去重/集合运算    -> MapSet
  深层嵌套的 JSON     -> get_in + Access.at/all（nil 安全）
  编译期已知的深路径   -> put_in(data.a.b, v) 宏形式
```

三条补充经验：

- 配置数据（`config/*.exs`）传统上用嵌套 Keyword，因为它保序、支持重复键、
  还能在编译期求值；运行时从外部进来的数据一律是 Map；
- 不要把 Keyword 当 map 用——`Keyword` 没有 O(1) 存取，
  也别对大量数据用 keyword 字面量；
- Struct 之间没有「继承」。要共享字段与逻辑，用组合或第 10 章的协议；
  想给 struct 补上 Access 风格的动态取值，用 `get_in(struct, [Access.key!(:field)])`。

## 9.8 坑位清单

1. **Keyword 是线性列表**：查找 O(n)、允许重复键、顺序敏感。
   只用于短选项列表；`get` 重复键取第一个，要全部用 `get_values`。

2. **Map 的 inspect 顺序不能依赖**：开发中实测 `+S 1:1` 下同一字面量
   打印顺序都不同。比较用 `==`（顺序无关），输出先排序。

3. **32 键是内部存储分界**：小 map 是 flatmap、大 map 是 hashmap。
   行为一致但迭代顺序可能不同——又一条「别依赖顺序」的理由。

4. **Struct 不实现 Access**：`%User{}[:id]` 抛 UndefinedFunctionError；
   点语法（`user.id`）或 `Access.key!/1` 才是正路。

5. **nil 安全分不清 nil 与缺失**：`data[:k]` 两种情况都给 nil。
   要区分用 `Map.fetch/2`（`:error`）或 `Map.get/3`。

6. **`@enforce_keys` 只管构造**：它不防止之后用 `%{u | id: nil}` 改成 nil，
   更不是类型校验。强不变量要在构造函数里自己守。

7. **`struct!/2` 与 `struct/2` 脾气不同**：前者对未知键抛 KeyError，
   后者静默忽略。处理不可信输入时别用宽松的那个。

8. **get_in 路径里列表下标必须 `Access.at`**：写成 `get_in(x, ["users", 0, "name"])`
   会把 `0` 当成键去查，查不到返回 nil，错误还很安静。

9. **大列表反复判存在别用 `Enum.member?`**：O(n) 扫描，先转 MapSet
   再 `MapSet.member?`（O(log n)）。同理「去重」用 MapSet，别手写 reduce。

---

下一章：[10 · 协议与行为](10-protocols.md)
