%% ============================================================
%% 18_ets —— ETS：进程之间唯一的「可变共享数据结构」
%%
%%    前面所有章节都在说「进程之间不共享内存」。ETS 是这条规则的**唯一例外**：
%%    它是一张存在 VM 全局的表，任何进程都能读写。
%%    代价与收益都很直接：
%%      · 读很快（常数级），并发读几乎无锁
%%      · 没有事务语义，写是「单条操作原子」，多条操作不原子
%%      · 表**属于创建它的进程** —— 那个进程一死，表就没了（这是最大的坑）
%%
%%    本示例打印的表内容一律先排序，因为 set 类型的遍历顺序是未定义的。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/18_ets examples/18_ets/18_ets.erl
%% 运行：
%%   erl -noshell -pa build/18_ets -run '18_ets' main -s init stop
%% ============================================================
-module('18_ets').

-export([main/0, own_table/0, sorted/1, tag_of/1]).

main() ->
    Old = process_flag(trap_exit, true),
    basic_ops(),
    four_types(),
    match_vs_match_object(),
    select_and_matchspec(),
    atomically_increment(),
    ownership(),
    options_and_usage(),
    process_flag(trap_exit, Old),
    io:format("~n==== 18 结束 ====~n").

%% 1) 基本操作
%% ------------------------------------------------------------
basic_ops() ->
    io:format("== 1) 基本操作 ==~n"),
    T = ets:new(demo1, [set, public]),
    d("ets:new 返回一个表标识（内部是整数，不打印）", is_reference(T) orelse is_integer(T)),
    d("空表 tab2list", ets:tab2list(T)),
    d("insert 一条", ets:insert(T, {a, 1})),
    d("insert 一个列表（批量，比逐条快）", ets:insert(T, [{b, 2}, {c, 3}])),
    d("tab2list（排序后）", sorted(ets:tab2list(T))),
    d("表里有几条（ets:size/1 **不存在**，要写 ets:info(T, size)）",
      ets:info(T, size)),
    d("lookup(a)", ets:lookup(T, a)),
    d("lookup(不存在的键) → 空列表，不报错", ets:lookup(T, zzz)),
    d("member(b)", ets:member(T, b)),
    d("同键再 insert 会**覆盖**（set 的语义）",
      begin ets:insert(T, {a, 999}), ets:lookup(T, a) end),
    d("delete 整个键", begin ets:delete(T, a), sorted(ets:tab2list(T)) end),
    d("delete_object 只删匹配的那条", ets:delete_object(T, {b, 2})),
    d("删完后", sorted(ets:tab2list(T))),
    d("delete_all_objects 清空", begin ets:delete_all_objects(T), ets:tab2list(T) end),
    d("info 里几个稳定字段",
      {ets:info(T, type), ets:info(T, protection), ets:info(T, named_table),
       ets:info(T, size)}),
    true = ets:delete(T),
    d("delete 整张表", table_gone),
    ok.

sorted(L) when is_list(L) -> lists:sort(L);
sorted(X) -> X.

%% 2) 四种表类型
%% ------------------------------------------------------------
%%   set            每个键只有一条（同键覆盖）；遍历顺序**未定义**
%%   ordered_set    按键排序；遍历顺序确定（做「按范围扫描」时用它）
%%   bag            同一个键允许多条，但**对象不能完全相同**
%%   duplicate_bag  同一个键允许多条，重复对象也可以有多份
four_types() ->
    io:format("~n== 2) 四种表类型 ==~n"),
    Row = [{"set", set}, {"ordered_set", ordered_set},
           {"bag", bag}, {"duplicate_bag", duplicate_bag}],
    [io:format("  ~-16ts -> ~p~n", [Name, type_demo(Type)]) || {Name, Type} <- Row],
    ok.

type_demo(Type) ->
    T = ets:new(tmp, [Type, public]),
    _ = ets:insert(T, [{k, 1}, {k, 2}, {k, 1}]),
    Result = sorted(ets:lookup(T, k)),
    _ = ets:delete(T),
    Result.

%% 3) match 与 match_object 的返回完全不同
%% ------------------------------------------------------------
%% 这是最容易用错的一对函数：
%%   match(T, Pattern)        返回**变量绑定列表**，比如 [[1],[2]]
%%   match_object(T, Pattern) 返回**匹配到的对象本身**，比如 [{a,1},{b,2}]
%% 想要对象就一定要用 match_object。
match_vs_match_object() ->
    io:format("~n== 3) match vs match_object ==~n"),
    T = ets:new(demo3, [set, public]),
    _ = ets:insert(T, [{a, 1}, {b, 2}, {c, 3}]),
    %% '_' 表示「任意」，'$1' 是绑定变量
    d("match(T, {'_', 2})（找值为 2 的项）", ets:match(T, {'_', 2})),
    d("match_object(T, {'_', 2})（同条件，但要对象）", ets:match_object(T, {'_', 2})),
    d("match(T, {'_', '$1'}) 返回的是每个匹配项的 $1 绑定",
      sorted(ets:match(T, {'_', '$1'}))),
    d("match_object(T, {'_', '$1'}) 返回完整对象",
      sorted(ets:match_object(T, {'_', '$1'}))),
    d("match(T, '$1') 会把**每一条**的整个对象绑到 $1",
      sorted(ets:match(T, '$1'))),
    d("match_delete(T, {'_', 2}) 的返回（删掉几条）", ets:match_delete(T, {'_', 2})),
    d("删完剩下", sorted(ets:tab2list(T))),
    true = ets:delete(T),
    ok.

%% 4) select 与 match spec
%% ------------------------------------------------------------
%% match spec 的形状是 [{模式, 守卫列表, body}]：
%%   模式 '{$1,$2}' 之类跟 match 一样，'_' 是任意
%%   守卫里 {'>','$2',2} 表示「$2 大于 2」——注意 '>' 在这里是**字面量原子**，
%%     不能写成 X > 2 这种表达式
%%   body 决定返回什么：['$2'] 返回第二个字段；[{'$1','$2'}] 返回一个元组
%% **坑**：body 必须是「表达式列表」。写 [{'$2'}] 时那个单元素元组会被当成
%% action（比如 {const, ...}），于是运行期 badarg。想要 $2 的值就写 ['$2']。
select_and_matchspec() ->
    io:format("~n== 4) select 与 match spec ==~n"),
    T = ets:new(demo4, [ordered_set, public]),
    _ = ets:insert(T, [{a, 1}, {b, 5}, {c, 9}]),
    d("全部对象（ordered_set 且 tab2list 是有序的）", ets:tab2list(T)),
    d("select：只取值为 5 的那条的键",
      ets:select(T, [{{'$1', 5}, [], ['$1']}])),
    d("select：值为 5 的那条的键，且要求键不是 a",
      ets:select(T, [{{'$1', 5}, [{'=/=', '$1', a}], ['$1']}])),
    d("select：值大于 1 的 {键,值} 对（'>' 是字面量原子）",
      ets:select(T, [{{'$1', '$2'}, [{'>', '$2', 1}], [{{'$1', '$2'}}]}])),
    d("select：body 里做加法",
      ets:select(T, [{{'$1', '$2'}, [], [{{'$1', {'+', '$2', 100}}}]}])),
    d("select：只取 $2（值）",
      ets:select(T, [{{'$1', '$2'}, [], ['$2']}])),
    body_forms(T),
    true = ets:delete(T),
    ok.

%% body 各种写法实测。规则：body 是**表达式列表**，列表里每个元素是一条
%% 「表达式」，每个匹配到的对象会把它算一遍，结果按顺序收集成一个列表。
%% 常见踩坑：
%%   · 想写一个元组结果，必须多套一层： [{{'$1','$2'}}] 而不是 [{'$1','$2'}]
%%   · 想写单变量，必须是 ['$2'] 而不是 [{'$2'}]（后者被当成 action 元组 → badarg）
%%   · [] 空 body 也是 badarg（至少要有一个表达式）
%% 打印时统一用 ~w，因为 body 结果常是小整数列表，~p 会美化成字符串。
body_forms(T) ->
    io:format("~n  -- body 的写法实测（表里的对象是 {a,1},{b,5},{c,9}）--~n"),
    Cases = [{"['$2']          只想拿 $2", ['$2']},
             {"['$1']          只想拿 $1", ['$1']},
             {"['$_']          $_ 是**整个对象**", ['$_']},
             {"[{{'$1','$2'}}] 想造一个元组（多套一层）", [{{'$1', '$2'}}]},
             {"[['$1','$2']]   想造一个列表", [['$1', '$2']]},
             {"[{'element',2,'$_'}] 用 BIF 取整个对象的第 2 个元素",
              [{'element', 2, '$_'}]},
             {"[{'element',2,'$1'}] ←错：$1 是键（原子），不是对象",
              [{'element', 2, '$1'}]},
             {"[{'const',42}]  常量（每个对象都给一个 42）", [{'const', 42}]},
             {"[{'=:=','$2',5}] 只做判断，不做筛选", [{'=:=', '$2', 5}]},
             {"[{'$1','$2'}]   忘了多套一层 → badarg", [{'$1', '$2'}]},
             {"[{'$2'}]        想拿 $2 却写成元组 → badarg", [{'$2'}]},
             {"[]              空 body → badarg", []}],
    [begin
         R = try ets:select(T, [{{'$1', '$2'}, [], Body}]) of
                 V -> V
             catch
                 error:Reason -> {error, tag_of(Reason)}
             end,
         io:format("  ~ts~n      => ~ts~n", [Label, io_lib:format("~w", [R])])
     end || {Label, Body} <- Cases],
    ok.

%% 5) 原子自增：ets:update_counter
%% ------------------------------------------------------------
%% 这是 ETS 最有用的函数之一：计数器自增是**单条原子操作**，
%% 所以可以直接当分布式计数器用，不需要额外加锁，也不会有丢更新。
atomically_increment() ->
    io:format("~n== 5) 原子自增：update_counter ==~n"),
    T = ets:new(counter, [set, public]),
    _ = ets:insert(T, {hits, 0}),
    d("默认步长 1，返回自增后的值", ets:update_counter(T, hits, 1)),
    d("再来两次", {ets:update_counter(T, hits, 1), ets:update_counter(T, hits, 1)}),
    d("步长写负数就是自减", ets:update_counter(T, hits, -2)),
    d("带门槛的写法 {Pos, Incr, Threshold, SetValue}："
      "低于门槛就设为 SetValue",
      ets:update_counter(T, hits, {2, 10, 100, 100})),
    d("当前值", ets:lookup(T, hits)),
    true = ets:delete(T),
    ok.

%% 6) 所有权：表属于创建它的进程
%% ------------------------------------------------------------
%% 打开 `{heir, Heir, Data}` 之后，owner 死掉时表会被**交给** heir，
%% heir 会收到 {'ETS-TRANSFER', Tid, FromPid, Data}。
%% 这是让 ETS 表活过「worker 重启」的标准手段（第 23 章会用到）。
ownership() ->
    io:format("~n== 6) 所有权：表属于创建它的进程 ==~n"),
    Self = self(),
    %% 不带 heir：owner 一死，表立刻消失
    {Pid1, MRef1} = spawn_monitor(fun() ->
                                          _ = ets:new(no_heir, [named_table, public]),
                                          Self ! ready,
                                          receive stop -> ok end
                                  end),
    receive ready -> ok after 2000 -> ok end,
    d("子进程建成表后，表是存在的吗", ets:info(no_heir) =/= undefined),
    d("表的所有者是本进程吗（不是，是子进程）", ets:info(no_heir, owner) =:= Self),
    exit(Pid1, kill),
    receive {'DOWN', MRef1, process, _, _} -> ok after 2000 -> ok end,
    d("owner 被 kill 之后，表还在吗", ets:info(no_heir) =/= undefined),

    %% 带 heir：owner 死了表会被交给 heir
    {Pid2, MRef2} = spawn_monitor(fun() ->
                                          _ = ets:new(with_heir,
                                                      [named_table, public,
                                                       {heir, Self, my_data}]),
                                          Self ! ready2,
                                          receive stop -> ok end
                                  end),
    receive ready2 -> ok after 2000 -> ok end,
    exit(Pid2, kill),
    receive
        {'DOWN', MRef2, process, _, _} -> ok
    after 2000 -> ok
    end,
    d("owner 死了，但我们（heir）会收到 ETS-TRANSFER 消息",
      receive {'ETS-TRANSFER', _Tid, _From, Data} -> {got_transfer, Data}
      after 2000 -> timeout
      end),
    d("表还活着吗 / 现在 owner 是本进程吗",
      {ets:info(with_heir) =/= undefined, ets:info(with_heir, owner) =:= Self}),
    true = ets:delete(with_heir),
    ok.

%% 7) 常用选项与使用建议
%% ------------------------------------------------------------
options_and_usage() ->
    io:format("~n== 7) 常用选项与建议 ==~n"),
    flag_vs_tuple(),
    T = ets:new(opts, [set, public, named_table,
                       {keypos, 1}, {read_concurrency, true},
                       {write_concurrency, true}, {decentralized_counters, true},
                       compressed]),
    show_info_keys(T),
    d("read_concurrency **不受**调度器个数影响", ets:info(T, read_concurrency)),
    d("compressed 的读回值", ets:info(T, compressed)),
    d("keypos / protection / named_table / type",
      {ets:info(T, keypos), ets:info(T, protection),
       ets:info(T, named_table), ets:info(T, type)}),
    %% **实测**：write_concurrency 与 decentralized_counters 会被运行时
    %% 按**调度器个数**静默降级：
    %%   4 个调度器时请求 true，读回来是 true；
    %%   +S 1:1（单调度器）时请求 true，读回来变成 false。
    %% 原因：只有 1 个调度器时「并发写」根本不存在，开着只是白增锁开销，
    %% 所以运行时直接关掉。{write_concurrency, auto} 也一样
    %% （多调度器报 auto，单调度器报 false）。
    %% → 结论：**不要把这两个值直接打进输出**，换台机器/换个调度器配置就不一样。
    %%   想核对就写成下面的布尔断言。
    Sched = erlang:system_info(schedulers_online),
    d("write_concurrency 读回来 = (调度器个数 > 1)",
      ets:info(T, write_concurrency) =:= (Sched > 1)),
    d("decentralized_counters 走同一条规则（一起被降级）",
      ets:info(T, decentralized_counters) =:= (Sched > 1)),
    true = ets:delete(T),

    %% named_table 之后可以直接拿名字当「表标识」用
    T2 = ets:new(named_demo, [set, named_table, public]),
    _ = ets:insert(T2, {k, v}),
    d("named_table：可以用名字代替表标识（ets:lookup(named_demo, k)）",
      ets:lookup(named_demo, k)),
    d("ets:info(T2, name) 给的就是这个名字", ets:info(T2, name)),
    true = ets:delete(named_demo),
    d("删掉之后 ets:info 返回 undefined", ets:info(named_demo)),

    Tips = [{"一个进程的高频本地缓存", "还是用 map（ETS 有额外开销）"},
            {"多个进程都要读同一份数据", "ETS（protected/public，读几乎无锁）"},
            {"要做「按键范围扫描」", "ordered_set"},
            {"计数器、限流、去重集合", "ETS + update_counter / insert_new"},
            {"数据必须跨进程重启还在", "ETS + heir（第 23 章），或者干脆用数据库"},
            {"需要事务语义（多表/多条一起成功或失败）", "mnesia（本章不涉及）"}],
    io:format("~n"),
    [begin
         io:format("  ~ts~n", [A]),
         io:format("      → ~ts~n", [B])
     end || {A, B} <- Tips],
    ok.

%% 选项有两种形状，混了就是运行期 badarg（编译期查不出来）：
%%   · **裸原子开关**：set / ordered_set / bag / duplicate_bag /
%%     public / protected / private / named_table / compressed
%%   · **{键, 值} 对**：{keypos, N} / {read_concurrency, B} /
%%     {write_concurrency, B|auto} / {decentralized_counters, B} / {heir, Pid[, Data]}
%% 最常见写错法：把裸原子写成 {Atom, true}。
flag_vs_tuple() ->
    io:format("~n  -- 选项的两种形状（写错的后果实测）--~n"),
    Cases = [{"compressed               裸原子", [set, compressed]},
             {"named_table              裸原子", [set, named_table]},
             {"{keypos,2}               元组，对", [set, {keypos, 2}]},
             {"{read_concurrency,true}  元组，对", [set, {read_concurrency, true}]},
             {"{compressed,true}        ←错：裸原子写成元组", [set, {compressed, true}]},
             {"{named_table,true}       ←错：同上", [set, {named_table, true}]},
             {"{public,true}            ←错：同上", [set, {public, true}]},
             {"{set,true}               ←错：同上", [set, {set, true}]},
             {"{heir,self()}            {heir,Pid} 合法，Data 可省", [set, {heir, self()}]}],
    [begin
         R = try ets:new(tmp, Opts) of
                 T -> true = ets:delete(T), ok
             catch
                 error:Reason -> {error, Reason}
             end,
         io:format("  ~ts~n      => ~p~n", [Label, R])
     end || {Label, Opts} <- Cases],
    ok.

%% ets:info/1 的字段清单。用 ~p 打印会被自动折行得很难看，
%% 所以自己切成每行 4 个，用 ~ts 输出（~ts 不会被折行）。
show_info_keys(T) ->
    Keys = [atom_to_list(K) || {K, _} <- lists:sort(ets:info(T))],
    io:format("  ets:info(T) 的字段清单（共 ~p 个，先排序，每行 4 个）~n",
              [length(Keys)]),
    [io:format("      ~ts~n", [lists:join(", ", C)]) || C <- chunk(Keys, 4)],
    ok.

chunk([], _) -> [];
chunk(L, N) ->
    {H, T} = lists:split(min(N, length(L)), L),
    [H | chunk(T, N)].

own_table() -> ets:info(with_heir).

tag_of({Reason, Stack}) when is_list(Stack) -> {crashed, Reason};
tag_of(R) -> R.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

