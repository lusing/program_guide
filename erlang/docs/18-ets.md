# 18 · ETS 与 DETS

> 对应示例：`examples/18_ets/`

## 18.1 进程间唯一的共享数据结构

```erlang
T = ets:new(my_table, [set, public]).
ets:insert(T, {a, 1}).            %% 返回 true；批量 insert 一个列表更快
ets:lookup(T, a).                 %% [{a,1}]——查不到返回 []，不报错
ets:info(T, size).                %% 条数——注意 ets:size/1 不存在！
true = ets:delete(T).             %% 删整张表
```

"进程不共享内存"的唯一例外：读常数级、并发读几乎无锁；没有事务语义（单条原子、多条不原子）；**表属于创建进程，进程一死表就没了**。

## 18.2 四种表类型

| 类型 | 同键 | 遍历顺序 |
|---|---|---|
| `set` | 覆盖（最后写入者胜） | **未定义**（打印前 sort） |
| `ordered_set` | 覆盖 | 键序（范围扫描用它） |
| `bag` | 多条，完全相同的对象去重 | 未定义 |
| `duplicate_bag` | 多条，重复也保留 | 未定义 |

## 18.3 match vs match_object vs select

```erlang
ets:match(T, {'$1', 2}).           %% [[b]]——返回**变量绑定**列表
ets:match_object(T, {'_', 2}).     %% [{b,2}]——返回**对象本身**
ets:select(T, [{{'$1','$2'}, [{'>','$2',1}], [{{'$1','$2'}}]}]).
%% match spec：{模式, 守卫列表, body}
```

body 是**表达式列表**：`['$2']` 拿值、`['$_']` 拿整个对象、`[{{'$1','$2'}}]` 造元组（**多套一层**）。两个实测坑：`[{'$2'}]` 单元素元组被当 action → badarg；`[]` 空 body 也 badarg。guard 里 `'>'` 是**字面量原子**，不能写表达式。

## 18.4 update_counter：原子自增

```erlang
ets:update_counter(T, hits, 1).               %% 返回自增后的值，单条原子——限流器首选
ets:update_counter(T, hits, {2, 10, 100, 0}). %% {Pos,Incr,Threshold,SetValue}：越门槛重置
```

无锁计数器，不存在丢更新；多进程限流/去重（`insert_new`）的标准件。

## 18.5 所有权与 heir

```erlang
ets:new(tab, [named_table, public, {heir, self(), Data}]).
%% owner 死 → heir 收到 {'ETS-TRANSFER', Tid, FromPid, Data}，表活下来
```

不带 heir：owner 一死表立刻消失（实测）。worker 重启要保表的标准手段就是 heir——supervisor 做重启时让 gen_server 把表转交给新实例。

## 18.6 选项的两种形状

裸原子开关（`set/protected/named_table/compressed`…）与 `{键, 值}` 对（`{keypos,N}`、`{read_concurrency,B}`、`{write_concurrency,B|auto}`、`{heir,Pid[,Data]}`）。**混写是运行期 badarg**（编译期查不出）——最常见错法 `{compressed, true}`。

> 实测：`write_concurrency` / `decentralized_counters` 在单调度器（+S 1:1）下会被运行时**静默降级成 false**——这两个值打进输出就不可重复，只能写成"= (调度器数 > 1)"这种布尔断言。

## 18.7 选型

单进程缓存用 map；多进程共享读用 ETS（protected）；范围扫描 ordered_set；计数/限流 update_counter；要事务用 Mnesia（[28 章](28-dets-mnesia.md)）。

## 18.8 坑位清单

1. **ets:size/1 不存在**：写 `ets:info(T, size)`——编译器不拦，运行期 undef。
2. **owner 死表没**：表挂在创建进程名下——长命表放 gen_server/监督树进程里，或用 heir。
3. **match 与 match_object 返回形状不同**：`[[绑定]]` vs `[对象]`——想要对象必须 match_object。
4. **match spec body 单元素元组 → badarg**：`[{'$2'}]` 是 action 不是表达式。
5. **named_table 重名**：`ets:new` 同名未删再建直接 badarg——测试里记得删表。
6. **set 遍历顺序未定义**：与 map 同款纪律，输出前 sort。

---
