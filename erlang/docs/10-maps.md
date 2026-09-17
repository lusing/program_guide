# 10 · 映射与记录

> 对应示例：`examples/10_maps/`（map 与 record 在同一个示例里对照）

## 10.1 构造与访问

```erlang
M = #{name => "alice", age => 30}.
maps:get(name, M).              %% "alice"
maps:get(city, M, "unknown").   %% 默认值
maps:find(age, M).              %% {ok,30} | error
#{age := A} = M.                %% 模式取字段（:= 要求键存在）
```

`maps:from_list([{a,1},{a,2}])` 重复键**后者胜**。

## 10.2 更新：`=>` 与 `:=` 是两套语义

```erlang
M#{b => 2}.    %% 新增或覆盖（upsert）
M#{zz := 1}.   %% 只更新已存在的键——没有就抛 {badkey, zz}
maps:take(b, M).   %% {2, #{a => 1}}——返回 {值, 剩余} 或 error
```

计数/累加的标准写法：`maps:update_with(K, fun(V) -> V+1 end, Init, M)`——有则用函数更新、无则用初值（词频统计一行搞定）。所有"更新"都返回新 map，原值不可变。

## 10.3 遍历与转换

```erlang
maps:map(fun(_K, V) -> V * 10 end, M).       %% 变换值
maps:filter(fun(_K, V) -> V > 1 end, M).     %% 过滤
maps:merge(A, B).                            %% 冲突右侧优先
maps:merge_with(fun(_K, L, R) -> L + R end, A, B).   %% 冲突交给函数
maps:with([a, c], M). / maps:without([a], M).
```

## 10.4 顺序不保证（map 的头号纪律）

**map 迭代顺序每次进程启动都随机**（原子哈希随机种子）——`maps:keys` 两次运行可能不同。要稳定输出必须 `lists:sort(maps:to_list(M))`；判等也用排序后的列表。整数键看起来有序是实现细节，**不要依赖**。

## 10.5 record：编译期的"结构体"

```erlang
-record(person, {name = "" :: string(),      %% 默认值 + 类型标注（给 dialyzer）
                 age = 0  :: non_neg_integer(),
                 tags = [] :: [atom()]}).

P#person.name.                 %% 访问：编译期展开成 element/3，O(1)
P#person{age = A + 1}.         %% 更新：返回新 record
label(#person{name = ""}) -> anonymous;      %% 模式解构
label(#person{age = A}) when A < 18 -> minor.
```

- record 定义**只在编译期存在**，运行期就是元组 `{person, Name, Age, Tags}`；
- 字段名不可动态访问；`is_record(X, person)` 可在 guard 里判定；
- 定义要放进 `.hrl` 才能跨模块共享（每处 `-include`）。

## 10.6 record vs map 取舍

| | record | map |
|---|---|---|
| 字段检查 | **编译期** | 运行期 |
| 访问成本 | element/2，最快 | 哈希查找 |
| 动态键 | ✘ | ✔（`maps:keys`、运行期拼键名） |
| 序列化 | 要先转 map | 直接 `maps:to_list` |

经验法则：**内部结构用 record，跨模块/跨进程边界与可变结构用 map**。示例给出 `to_map/1` / `from_map/1` 互转。

## 10.7 坑位清单

1. **map 迭代顺序随机**：打印/落盘前必须 `lists:sort(maps:to_list(M))`，否则双通道验证必挂。
2. **`:=` 更新不存在的键抛 badkey**：upsert 语义用 `=>`；想"有则函数更新无则初值"用 `maps:update_with/4`。
3. **`maps:take` 返回 {值, 剩余}**：值在前——容易记反成 {剩余, 值}。
4. **record 当动态字典用**：字段名运行期拿不到，动态键场景换 map。
5. **子句顺序**：`label` 里"匿名"判定排在年龄判定后面就永远轮不到——age=0 先命中 minor（示例实测）。
6. **两个模块的 record 定义不同步**：同一 record 各处定义不一致时元组照旧匹配——共享定义放 .hrl。

---
