# 28 · DETS 与 Mnesia：把数据放到磁盘上

> 对应示例：`examples/28_dets_mnesia/`（沙箱在 build 目录下，每次运行前清空）

第 18 章的 ETS 住在内存、随进程生死。这一章是它的两步延伸——
DETS（磁盘版 ETS）与 Mnesia（带事务的分布式数据库）。取材《Erlang
程序设计》第 19 章尾部与第 20 章。

```text
ETS    内存 / 随进程死 / 无事务
DETS   文件即表 / 重启还在 / 单表 2GB 上限 / 没有 ordered_set
Mnesia 事务 / 索引 / 分布式副本 / OTP 自带
```

## 28.1 DETS：形状与 ETS 几乎一样

```erlang
{ok, Ref} = dets:open_file(kv28, [{file, "kv.dets"}, {type, set}]),
ok = dets:insert(Ref, [{k3, "c"}, {k1, "a"}, {k2, "b"}]),
[{k2, "b"}] = dets:lookup(Ref, k2),          %% 返回列表（同 ets）
3 = dets:info(Ref, size),                    %% 条数看 size
undefined = dets:info(Ref, no_items),        %% no_items 是 undefined！
L = dets:foldl(fun (Obj, Acc) -> [Obj | Acc] end, [], Ref),   %% 顺序不保证
lists:sort(L).                               %% 打印前必须 sort
```

三种表型同键行为与 ETS 一致（set 覆盖 / bag 去完全重复 /
duplicate_bag 全保留），但 **DETS 没有 ordered_set**——要有序遍历就
读出来自己 sort。

## 28.2 持久化与脏文件

close 之后换个名字重新 open 同一个文件，内容从磁盘回来——这就是
「文件即表」。反过来，**dets 文件是跨运行残留的状态**：

```erlang
%% 打开一个非 dets 文件：
{error, {not_a_dets_file, Path}} = dets:open_file(g, [{file, "garbage"}, ...]).
%% 上次崩溃留下的残缺真 dets 文件：{error, needs_repair, Path}
```

确定性脚本每次运行用干净沙箱（示例的 `fresh_sandbox/0`：先删目录再
建）——比「修复残骸」省心得多。

## 28.3 Mnesia：schema、事务、脏读、索引

```erlang
ok = application:set_env(mnesia, dir, Dir),   %% 必须在 create_schema 之前
ok = mnesia:create_schema([node()]),
ok = mnesia:start(),
{atomic, ok} = mnesia:create_table(kv, [{ram_copies, [node()]},
                                       {attributes, [key, val]}]),

Write = fun () -> [mnesia:write({kv, K, V}) || {K, V} <- [{x, 1}, {y, 2}]], written end,
{atomic, written} = mnesia:transaction(Write),
Read = fun () -> mnesia:read({kv, x}) end,
{atomic, [{kv, x, 1}]} = mnesia:transaction(Read),
[{kv, y, 2}] = mnesia:dirty_read({kv, y}).     %% 脏读：跳过锁与日志
```

事务里的 fun **不能有副作用**（可能重试）。abort 整体回滚：

```erlang
Abort = fun () -> mnesia:write({kv, z, 99}), mnesia:abort(simulated_failure) end,
{aborted, simulated_failure} = mnesia:transaction(Abort),
[] = mnesia:dirty_read({kv, z}).
```

索引给非主键属性建，查分两个版本——**`index_read` 只能在事务里用**
（事务外直接 `exit({aborted, no_transaction})`，连 error 都不是），
事务外用 `dirty_index_read`：

```erlang
{atomic, ok} = mnesia:add_table_index(kv, val),
[{kv, y, 2}] = mnesia:dirty_index_read(kv, 2, val),
{atomic, [{kv, x, 1}]} = mnesia:transaction(fun () -> mnesia:index_read(kv, 1, val) end).
```

收摊：`mnesia:stop()` → `mnesia:delete_schema([node()])`。

## 28.4 坑位清单

1. **dets:info 看条数用 `size`**——`no_items` 返回 undefined（老接口
   残留，编译器不拦）。
2. **dets:lookup 返回对象列表**，模式 `{Obj} = dets:lookup(...)` 会
   badmatch——同 ets 的形状，但老书里常写成单对象。
3. **dets 文件跨运行残留**：测试/演示必须每次清沙箱或删文件再开；
   同名 open 会看到上次的数据累积（bag/duplicate_bag 越攒越多）。
4. **mnesia 的 dir 要在 create_schema 之前 set_env**——schema 文件
   落在旧目录里，之后 set_env 也连不上。
5. **mnesia 启停打带时间戳的 INFO REPORT**（走 logger）——main/tests
   首行 `logger:remove_handler(default)` 即静音。
6. **`index_read` 事务外直接 exit**（`{aborted, no_transaction}`）——
   不是返回 `{error, _}`，try/catch error 都接不住（是 exit）；事务外
   用 `dirty_index_read/3`。
7. **dets 无 ordered_set**；遍历顺序不保证——输出前 sort。
8. **错误值里带绝对路径**（`{not_a_dets_file, Path}`）——打印时只留
   标签，路径进不得验证输出。
9. **二进制字面量 `<<"中文">>` 被 latin1 截断**（第 9 章头号坑在 dets
   这里最容易复犯）——持久化中文用 `unicode:characters_to_binary/1`。

## 28.5 要点小结

```text
  台阶：ETS（内存）→ DETS（文件即表）→ Mnesia（事务数据库），全 OTP 自带
  DETS 与 ETS 同形状：lookup 列表、info size、无 ordered_set
  dets 文件是跨运行状态：干净沙箱是最省心的确定性解法
  mnesia 事务 fun 无副作用；abort 整体回滚；dirty_* 快而脆
  index_read 事务内专用，事务外 dirty_index_read
  输出纪律：错误只打标签、中文用 characters_to_binary、遍历先 sort
```
