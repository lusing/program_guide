%% ============================================================
%% 28_dets_mnesia —— DETS 与 Mnesia：把数据放到磁盘上
%%
%%    第 18 章的 ETS 住在内存、随进程生死。这一章是它的两步延伸：
%%      · DETS   —— 磁盘版 ETS：文件即表，重启数据还在；
%%                  没有 ordered_set、单文件上限 2GB、操作慢一个量级
%%      · Mnesia —— 分布式数据库：事务、索引、表副本位置（ram/disc）；
%%                  查询写在 fun 里（不能有副作用），失败整体回滚
%%
%%    实测坑（CHEATSheet 详见）：
%%      · dets 文件是**跨运行残留的状态**——确定性脚本每次用干净沙箱；
%%        打开非 dets 文件报 {error,{not_a_dets_file,路径}}；上次崩溃
%%        留下的残缺文件报 needs_repair
%%      · dets:lookup 返回**对象列表**（同 ets），不是单个对象
%%      · dets:info 看条数用 size（no_items 是 undefined！）
%%      · mnesia 启停会产生带时间戳的 INFO REPORT——首行摘掉 logger
%%        默认 handler 即静音
%%      · mnesia 的目录用 application:set_env(mnesia, dir, ...) 在
%%        create_schema **之前**设置
%%      · index_read 只能在事务里用（外面直接 exit no_transaction），
%%        事务外用 dirty_index_read
%%
%% 编译：
%%   erlc -Werror -Wall -o build/28_dets_mnesia examples/28_dets_mnesia/28_dets_mnesia.erl
%% 运行：
%%   erl -noshell -pa build/28_dets_mnesia -run '28_dets_mnesia' main
%% ============================================================
-module('28_dets_mnesia').

-export([main/0, sandbox/0, fresh_sandbox/0]).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% 沙箱放在 build/28_dets_mnesia/sandbox28（随 build 目录整体不入库）
sandbox() ->
    filename:join(filename:dirname(code:which(?MODULE)), "sandbox28").

%% 每次运行前清一遍——dets 文件是跨运行残留的状态
fresh_sandbox() ->
    _ = file:del_dir_r(sandbox()),
    ok = file:make_dir(sandbox()),
    ok.

main() ->
    logger:remove_handler(default),
    ok = fresh_sandbox(),
    ladder(),
    dets_basics(),
    dets_types(),
    dets_persistence(),
    dets_dirty_file(),
    mnesia_cycle(),
    io:format("~n==== 28 结束 ====~n").

%% ------------------------------------------------------------ %%
%% 1) 台阶：内存表 → 磁盘表 → 数据库
%% ------------------------------------------------------------
ladder() ->
    io:format("~n== 1) 台阶：内存表 → 磁盘表 → 数据库 ==~n"),
    d("ETS", '内存 / 随进程死 / 无事务'),
    d("DETS", '文件即表 / 重启还在 / 单表 2GB 上限'),
    d("Mnesia", '事务 / 索引 / 分布式副本'),
    io:format("  （三者都是 OTP 自带——零外部依赖就能持久化）~n").

%% ------------------------------------------------------------ %%
%% 2) DETS 基本操作：形状与 ETS 几乎一样
%% ------------------------------------------------------------
dets_basics() ->
    io:format("~n== 2) DETS 基本操作 ==~n"),
    F = filename:join(sandbox(), "kv.dets"),
    {ok, Ref} = dets:open_file(kv28, [{file, F}, {type, set}]),
    ok = dets:insert(Ref, [{k3, "c"}, {k1, "a"}, {k2, "b"}]),
    d("遍历用 foldl，打印前必须 sort（顺序不保证）",
      lists:sort(dets:foldl(fun (Obj, Acc) -> [Obj | Acc] end, [], Ref))),
    d("lookup 返回**列表**（不是单个对象）", dets:lookup(Ref, k2)),
    d("查不存在的键", dets:lookup(Ref, nope)),
    d("条数看 info 的 size", dets:info(Ref, size)),
    d("no_items 是 undefined（易错）", dets:info(Ref, no_items)),
    d("表型", dets:info(Ref, type)),
    ok = dets:close(Ref).

%% ------------------------------------------------------------ %%
%% 3) 三种表型：同键行为（没有 ordered_set！）
%% ------------------------------------------------------------
dets_types() ->
    io:format("~n== 3) 三种表型：同键行为（没有 ordered_set！）~n"),
    [d(atom_to_list(Type),
       lists:sort(open_type_and_lookup(Type)))
     || Type <- [set, bag, duplicate_bag]],
    io:format("  （DETS 不支持 ordered_set——要有序遍历：读出后自己 sort）~n").

open_type_and_lookup(Type) ->
    F = filename:join(sandbox(), atom_to_list(Type) ++ ".dets"),
    _ = file:delete(F),
    {ok, Ref} = dets:open_file(list_to_atom("t_" ++ atom_to_list(Type)),
                               [{file, F}, {type, Type}]),
    ok = dets:insert(Ref, [{k, 1}, {k, 1}, {k, 2}]),
    L = dets:lookup(Ref, k),
    ok = dets:close(Ref),
    L.

%% ------------------------------------------------------------ %%
%% 4) 持久化：close 之后重新打开
%% ------------------------------------------------------------
dets_persistence() ->
    io:format("~n== 4) 持久化：close 之后重新打开 ==~n"),
    F = filename:join(sandbox(), "persist.dets"),
    _ = file:delete(F),
    {ok, Ref} = dets:open_file(p28, [{file, F}, {type, set}]),
    %% 注意：二进制字面量 <<"中文">> 会被 latin1 截断（第 9 章头号坑），
    %% 存中文用 unicode:characters_to_binary/1
    ok = dets:insert(Ref, {only, unicode:characters_to_binary("重启还在")}),
    d("写入条数", dets:info(Ref, size)),
    ok = dets:close(Ref),
    %% 同一个文件换个名字打开——内容从磁盘回来
    {ok, Re} = dets:open_file(p28_reopened, [{file, F}, {type, set}]),
    d("重开后 lookup", dets:lookup(Re, only)),
    d("重开后条数", dets:info(Re, size)),
    ok = dets:close(Re).

%% ------------------------------------------------------------ %%
%% 5) 脏文件：不是 dets 格式的文件
%% ------------------------------------------------------------
dets_dirty_file() ->
    io:format("~n== 5) 脏文件：不是 dets 格式的文件 ==~n"),
    F = filename:join(sandbox(), "garbage.dets"),
    ok = file:write_file(F, unicode:characters_to_binary("这不是 dets 文件")),
    {error, {not_a_dets_file, _Path}} =
        dets:open_file(g28, [{file, F}, {type, set}]),
    %% 错误里带绝对路径——打印只留标签（输出纪律：不打印路径）
    d("打开垃圾文件的错误标签", not_a_dets_file),
    io:format("  （上次崩溃留下的残缺真 dets 文件则报 needs_repair；~n"),
    io:format("   确定性脚本每次用干净沙箱是最省心的解法）~n").

%% ------------------------------------------------------------ %%
%% 6) Mnesia：schema、事务、脏读、索引
%% ------------------------------------------------------------
mnesia_cycle() ->
    io:format("~n== 6) Mnesia：schema、事务、脏读、索引 ==~n"),
    Dir = filename:join(sandbox(), "mnesia"),
    ok = file:make_dir(Dir),
    %% 目录必须在 create_schema 之前设置
    ok = application:set_env(mnesia, dir, Dir),
    ok = mnesia:create_schema([node()]),
    ok = mnesia:start(),
    {atomic, ok} = mnesia:create_table(kv,
                                       [{ram_copies, [node()]},
                                        {attributes, [key, val]}]),
    %% 事务里的 fun：不能有副作用（可能重试）
    Write = fun () ->
                    [mnesia:write({kv, K, V}) || {K, V} <- [{x, 1}, {y, 2}]],
                    written
            end,
    {atomic, written} = mnesia:transaction(Write),
    Read = fun () -> mnesia:read({kv, x}) end,
    {atomic, [{kv, x, 1}]} = mnesia:transaction(Read),
    d("事务读", ok),
    d("脏读（跳过事务锁与日志，快一截）", mnesia:dirty_read({kv, y})),
    %% abort：整个事务回滚
    Abort = fun () ->
                    mnesia:write({kv, z, 99}),
                    mnesia:abort(simulated_failure)
            end,
    {aborted, simulated_failure} = mnesia:transaction(Abort),
    d("abort 的事务整体回滚", mnesia:dirty_read({kv, z})),
    %% 索引：给非主键属性 val 建索引。查分两个版本——
    %% index_read 只能在事务里用（外面 exit no_transaction），
    %% 事务外用 dirty_index_read
    {atomic, ok} = mnesia:add_table_index(kv, val),
    d("脏按索引查 val=2", mnesia:dirty_index_read(kv, 2, val)),
    Idx = fun () -> mnesia:index_read(kv, 1, val) end,
    {atomic, [{kv, x, 1}]} = mnesia:transaction(Idx),
    d("事务里 index_read（同款 API 的事务版）", ok),
    d("表大小", mnesia:table_info(kv, size)),
    d("存储类型", mnesia:table_info(kv, storage_type)),
    stopped = mnesia:stop(),
    ok = mnesia:delete_schema([node()]),
    d("停库删 schema 收摊", ok).
