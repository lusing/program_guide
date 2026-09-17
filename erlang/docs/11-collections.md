# 11 · 容器与配置结构

> 对应示例：`examples/11_collections/`（proplists / sets / queue / array）

## 11.1 proplists：配置的标准形状

```erlang
Opts = [{verbose, true}, debug, {retries, 3}, 42].
proplists:get_value(debug, Opts).    %% true —— 裸原子等价 {debug, true}
proplists:get_value(missing, Opts).  %% undefined（三参版可给默认值）
proplists:lookup(retries, Opts).     %% {retries,3}——拿整项而不是值
```

OTP 的选项、sys.config、gen_server 启动参数到处是它。**不合法项（如裸整数 42）被取值函数静默忽略**——`get_keys` 也不把它算作键；`lists:keysort(1, Opts)` 更是直接 badarg（裸原子不是元组）。

## 11.2 重复键：先给的赢（与 map 相反）

```erlang
proplists:get_value(level, [{level, warn}, {level, info}]).   %% warn
maps:from_list([{level, warn}, {level, info}]).                %% #{level => info}
```

这正是「命令行 > 配置文件 > 默认值」的覆盖语义——**高优先级的放前面，不要合并**。取全部值用 `get_all_values/2`。

## 11.3 布尔开关

`get_bool(debug, Opts)` 在"没写"和"写了 false"时都返回 false——**无法区分**；要区分用 `is_defined/2`。命令行开关（`--verbose`）的经典形态就是裸原子。

## 11.4 三套集合实现

| | sets | ordsets | gb_sets |
|---|---|---|---|
| 内部表示 | map | 有序列表 | 平衡树 |
| 成员判断 | O(1) | O(n) | O(log n) |
| to_list 顺序 | **随机**（必须 sort） | 天然有序 | 中序遍历有序 |
| 独有能力 | — | — | smallest/largest/larger/smaller、iterator |

集合代数（union/intersection/subtract/is_subset）三套语义一致。选型：频繁成员判断→sets；元素少要有序→ordsets；元素多要有序或区间查询→gb_sets。

## 11.5 queue：注意 in 与 snoc

```erlang
queue:in(4, Q).      %% 尾部加（常规入队）
queue:in_r(0, Q).    %% 头部加（cons 等价）
queue:snoc(Q, 4).    %% 等价于 in —— 但**参数顺序反了**（Q 在前）！
queue:out(Q).        %% {{value, X}, Q2} | {empty, Q}
```

内部是两个列表，均摊 O(1)。BFS/工作队列用它，别用 `list ++ [X]`。

## 11.6 array：稀疏数组

```erlang
array:get(9, array:from_list([a, b, c])).   %% undefined——越界不报错，返回默认值
S = array:set(1000, x, array:new()).
array:size(S).            %% 1001（随最大下标增长，含默认值条目）
array:sparse_to_orddict(S).   %% [{1000,x}]——只列真正设过的
```

`size` 含默认值条目、`sparse_size` 是"到最后一个非默认条目为止"、`sparse_to_orddict` 才是"真正存了几个"——三个语义完全不同。

## 11.7 带选项的 API 模板

```erlang
open(Opts) ->
    Mode = proplists:get_value(mode, Opts, read),      %% ① 合并默认值
    ...
    Unknown = [K || {K, _} <- Opts, not lists:member(K, Known)],
    ... {error, {unknown_options, ...}} ...            %% ② 不认识的键报错
```

不认识的选项**必须报错**而不是静默忽略——`{retry, 5}`（拼错的 retries）静默吞掉就是线上事故。

## 11.8 坑位清单

1. **proplists 的裸项静默忽略**：`[42]` 混进选项列表没人报错；`lists:keysort` 则直接崩——形状校验自己做。
2. **get_bool 区分不了"没写"与"false"**：要区分用 `is_defined/2`。
3. **sets 的 to_list 顺序随机**：与 map 同源（内部就是 map），输出前 sort。
4. **queue:snoc 参数顺序与 in 相反**：`in(Item, Q)` vs `snoc(Q, Item)`。
5. **array 越界返回默认值不报错**：写错下标不会崩，只会拿到 undefined——排查更难。
6. **proplists:property/1,2 是构造器不是判定器**：`property(a, true)` 缩成裸原子 `a`；它不做合法性检查（对源码核过）。

---
