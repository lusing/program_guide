%% ---------------------------------------------------------------------------
%%  28) 调试、热加载与运维
%%
%%  编译：erlc -Werror -Wall -o build/ebin examples/28-debugging-ops.erl
%%  运行：erl -noshell -pa build/ebin -run '28-debugging-ops' main -s init stop
%%
%%  前面 27 章都在讲"怎么写"，这一章讲"上线之后怎么查"。
%%  四件事：
%%    1. sys 模块 —— 不停机就能看/改一个 OTP 进程的状态；
%%    2. proc_lib —— 让"自己手写的进程"也像个 OTP 进程（崩溃报告、启动同步）；
%%    3. 热代码加载 —— 为什么你的循环函数改了却没生效；
%%    4. 节点内省 —— 出问题第一眼看什么。
%%
%%  第 1 节复用第 23 章那个最小应用 kvapp 里的 kvapp_store（gen_server）。
%% ---------------------------------------------------------------------------
-module('28-debugging-ops').

-export([main/0, init/1, init/2]).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

-define(DIR, "/tmp/erl-demo-28").

main() ->
    _ = logger:remove_handler(default),
    io:format("=== 28) 调试、热加载与运维 ===~n"),
    reset(),
    sys_module(),
    proc_lib_basics(),
    hot_code(),
    introspection(),
    mistakes(),
    cleanup(),
    io:format("==== 28 结束 ====~n"),
    ok.

reset() ->
    _ = file:del_dir_r(?DIR),
    ok = file:make_dir(?DIR),
    ok = application:load(kvapp),
    {ok, _} = application:ensure_all_started(kvapp),
    ok.

cleanup() ->
    _ = application:stop(kvapp),
    _ = application:unload(kvapp),
    ok = file:del_dir_r(?DIR),
    ok.

%% ---------------------------------------------------------------------------
%% 1) sys 模块：线上看状态、改状态
%% ---------------------------------------------------------------------------
sys_module() ->
    io:format("~n== 1) sys：不停机查看/修改一个 OTP 进程 ==~n"),
    io:format("  sys 是 OTP 自带的\"调试通道\"：它用**系统消息**跟进程说话，~n"),
    io:format("  所以不需要你在 gen_server 里写任何额外代码。~n"),
    io:format("  （下面拿第 23 章的 kvapp_store 当例子，它是个 gen_server。）~n~n"),

    d("sys:get_state（服务自己才知道的状态）", sys:get_state(kvapp_store)),
    ok = kvapp_store:put(alpha, 1),
    ok = kvapp_store:put(beta, 2),
    d("  放了两条之后的 state", sys:get_state(kvapp_store)),

    io:format("~n  -- 改状态：线上救急用，但要小心 --~n"),
    d("sys:replace_state 把 puts 计数改成 999",
      sys:replace_state(kvapp_store, fun(S) -> S#{puts := 999} end)),
    d("  all()（数据没动）", kvapp_store:all()),
    d("  count()", kvapp_store:count()),

    io:format("~n  -- get_status：人读的版本 --~n"),
    {status, _Pid, {module, Mod}, Items} = sys:get_status(kvapp_store),
    d("是 {status, Pid, {module, _}, 清单} 这个形状吗", true),
    d("  module（注意是行为模块名，不是你的模块）", Mod),
    d("  清单长度（固定的 5 项）", length(Items)),
    Misc = lists:last(Items),
    d("  最后一项的 header", proplists:get_value(header, Misc)),
    d("  最后一项里的 State", element(2, lists:last(Misc))),
    io:format("  observer / 各种运维工具显示的就是这个结构。~n"),

    io:format("~n  -- 开关统计与日志 --~n"),
    d("sys:statistics 开", sys:statistics(kvapp_store, true)),
    _ = kvapp_store:count(),
    d("  开完之后 get_status 里多出来的项",
      [element(1, I) || I <- lists:last(element(4, sys:get_status(kvapp_store)))]),
    d("sys:statistics 关", sys:statistics(kvapp_store, false)),
    d("sys:log 开始记录事件", sys:log(kvapp_store, true)),
    _ = kvapp_store:count(),
    _ = kvapp_store:put(gamma, 3),
    d("  记录下来的事件条数", length(logged_events(kvapp_store))),
    d("  每条事件的第一项（事件类型）",
      [element(1, E) || E <- logged_events(kvapp_store)]),
    d("sys:log 关", sys:log(kvapp_store, false)),
    io:format("  sys:trace/2 会把每一条系统消息打到 stdout（刷屏，只在排障时开）。~n"),
    _ = sys:no_debug(kvapp_store),

    io:format("~n  -- 挂起与恢复 --~n"),
    d("sys:suspend", sys:suspend(kvapp_store)),
    d("  挂起期间 call 会超时（业务侧表现为\"卡住\"）",
      try gen_server:call(kvapp_store, count, 200) of V -> {unexpected, V}
      catch exit:R -> {exit, element(1, R)} end),
    d("sys:resume", sys:resume(kvapp_store)),
    d("  恢复之后", kvapp_store:count()),
    ok.

%% 从 get_status 里把 \"Logged events\" 那一项取出来
logged_events(Name) ->
    {status, _Pid, {module, _Mod}, Items} = sys:get_status(Name),
    Misc = lists:last(Items),
    DataGroups = [L || {data, L} <- Misc],
    case [E || L <- DataGroups, {"Logged events", E} <- L] of
        [Events | _] -> Events;
        [] -> []
    end.

%% ---------------------------------------------------------------------------
%% 2) proc_lib：让手写的进程也"像" OTP 进程
%% ---------------------------------------------------------------------------
proc_lib_basics() ->
    io:format("~n== 2) proc_lib：手写进程的启动同步与身份信息 ==~n"),
    io:format("  直接 spawn 有两个问题：~n"),
    io:format("    (a) start 函数返回时，子进程**可能还没初始化完** —— 经典竞态；~n"),
    io:format("    (b) 它崩了之后，崩溃报告里只有 <0.87.0>，看不出是谁。~n"),
    io:format("  proc_lib 解决这两件事。~n~n"),

    {ok, P} = start(),
    d("proc_lib 启动的进程是活的", is_process_alive(P)),
    d("  start/0 返回时 init 已经跑完了（init_ack 保证的）",
      sys_ok(P)),

    Dict = case process_info(P, dictionary) of
               {dictionary, D} when is_list(D) -> lists:sort([K || {K, _} <- D]);
               _ -> []
           end,
    d("  进程字典里的键", Dict),
    d("  $initial_call（崩溃报告靠它显示\"本来要跑哪个函数\"）",
      proplists:get_value('$initial_call', Dict)),
    d("  $ancestors（谁启动了我；监督者靠它认孩子）",
      proplists:get_value('$ancestors', Dict)),

    Q = spawn(fun() -> receive stop -> ok end end),
    QDict = case process_info(Q, dictionary) of
                {dictionary, D2} when is_list(D2) -> lists:sort([K || {K, _} <- D2]);
                _ -> []
            end,
    d("  对比：普通 spawn 的进程字典", QDict),
    Q ! stop,

    io:format("~n  -- 初始化失败要显式通知 --~n"),
    d("init_fail 让调用方拿到错误", start_failing()),
    d("  proc_lib:stop 也要 sys 支持，我们这个进程不认 → 会一直等到超时",
      try proc_lib:stop(P, normal, 300) of
          ok -> ok
      catch exit:StopReason -> {exit, StopReason}
      end),
    exit(P, shutdown),

    io:format("~n  ⚠ 常见误解：proc_lib **不**自动支持 sys。~n"),
    io:format("    想让手写进程也能被 sys 查看，循环里必须自己处理系统消息：~n"),
    io:format("        receive {system, From, Req} -> sys:handle_system_msg(Req, From, ...);~n"),
    io:format("    或者干脆用 gen_server —— 这些它都替你做了。~n"),
    ok.

%% 用 proc_lib 启动：init/1 里 init_ack 之后才返回
start() -> proc_lib:start_link(?MODULE, init, [self()]).

%% 演示 init_fail：init/1 收到 fail 就通知调用方
start_failing() -> proc_lib:start_link(?MODULE, init, [self(), fail]).

init(Parent) ->
    proc_lib:init_ack(Parent, {ok, self()}),
    plain_loop().
init(Parent, fail) ->
    proc_lib:init_fail(Parent, {error, simulated_failure}).

plain_loop() ->
    receive
        stop -> ok;
        _ -> plain_loop()
    end.

%% 我们这个 plain_loop 不处理系统消息，所以不能用 sys 去查它；
%% 这里只验证"进程活着、而且 start/0 返回前 init 已经执行过"。
sys_ok(P) -> is_process_alive(P).

%% ---------------------------------------------------------------------------
%% 3) 热代码加载：为什么改了不生效
%% ---------------------------------------------------------------------------
hot_code() ->
    io:format("~n== 3) 热代码加载：局部调用 vs 全限定调用 ==~n"),
    io:format("  一个模块在虚拟机里可以**同时存在两个版本**。规则是：~n"),
    io:format("    · 局部调用（直接写函数名）→ 永远用**当前进程正在跑的那一版**；~n"),
    io:format("    · 全限定调用（?MODULE:f()）→ 永远用**最新的一版**。~n"),
    io:format("  所以循环函数要想升级后立刻生效，必须写成  ?MODULE:loop(...)。~n~n"),

    {module, hot_demo} = load_version(1),
    {P1, P2} = hot_demo:start(),
    d("第 1 版：局部调用 loop()", ask(P1)),
    d("第 1 版：全限定调用 ?MODULE:ver()", ask(P2)),

    {module, hot_demo} = load_version(2),
    io:format("  装完第 2 版（ver/0 从 1 改成 2）之后：~n"),
    d("  还在跑的 loop（局部调用）→ 还是旧值", ask(P1)),
    d("  还在跑的 loop_fq（全限定调用）→ 拿到新值", ask(P2)),
    d("erlang:check_old_code（有旧版本在跑吗）", erlang:check_old_code(hot_demo)),

    P3 = spawn(hot_demo, loop, []),
    d("  新起的进程用 loop（局部调用）也是新的", ask(P3)),

    io:format("~n  -- 旧版本什么时候被清掉 --~n"),
    d("code:soft_purge（只清没人跑的旧版）", code:soft_purge(hot_demo)),
    d("  因为 P1 还在跑旧版，所以清不掉；check_old_code 仍是",
      erlang:check_old_code(hot_demo)),
    exit(P1, kill),
    timer:sleep(30),
    d("  把 P1 杀掉之后再 soft_purge", code:soft_purge(hot_demo)),
    d("  check_old_code", erlang:check_old_code(hot_demo)),
    io:format("  code:purge/1 是**硬清**：会把还在用旧版的进程直接杀掉，慎用。~n"),
    exit(P2, kill), exit(P3, kill),
    ok.

ask(P) ->
    P ! {self(), q},
    receive V -> V after 3000 -> timeout end.

%% 在运行时编译出 hot_demo 的第 N 版并装进虚拟机
load_version(N) when is_integer(N) ->
    Src = "-module(hot_demo).\n"
          "-export([start/0, loop/0, loop_fq/0, ver/0]).\n"
          "start() -> {spawn(?MODULE, loop, []), spawn(?MODULE, loop_fq, [])}.\n"
          "loop() -> receive {P, q} -> P ! ver(), loop() end.\n"
          "loop_fq() -> receive {P, q} -> P ! ?MODULE:ver(), loop_fq() end.\n"
          "ver() -> " ++ integer_to_list(N) ++ ".\n",
    File = filename:join(?DIR, "hot_demo.erl"),
    ok = file:write_file(File, Src),
    {ok, hot_demo, Bin} = compile:file(File, [binary, return_errors]),
    code:load_binary(hot_demo, "hot_demo.erl", Bin).

%% ---------------------------------------------------------------------------
%% 4) 内省：出问题第一眼看什么
%% ---------------------------------------------------------------------------
introspection() ->
    io:format("~n== 4) 内省：出问题第一眼看什么 ==~n"),
    d("进程数 > 0", length(erlang:processes()) > 0),
    d("  已经注册了名字的进程数 > 0", length(registered()) > 0),
    d("  端口数 > 0", length(erlang:ports()) > 0),
    d("  ETS 表数 >= 0", length(ets:all()) >= 0),
    d("erlang:system_info(process_count) 与 length(processes()) 一致吗",
      erlang:system_info(process_count) =:= length(erlang:processes())),

    io:format("~n  -- 按注册名找进程 --~n"),
    d("whereis(kvapp_store) 是 pid 吗", is_pid(whereis(kvapp_store))),
    d("whereis(一个没注册的名字)", whereis(no_such_name_zzz)),
    d("registered() 里能找到 kvapp_store 吗",
      lists:member(kvapp_store, registered())),

    io:format("~n  -- 找出\"最可疑\"的进程：邮箱最长的 --~n"),
    Busiest = lists:sublist(
        lists:reverse(lists:keysort(2,
            [{P, QL} || P <- erlang:processes(),
                        {message_queue_len, QL} <- [process_info(P, message_queue_len)],
                        QL =/= undefined])), 3),
    d("邮箱最长的三个进程的队列长度（只打数字，不打 pid）",
      [QL || {_P, QL} <- Busiest]),
    io:format("  邮箱一直涨 = 有人发得比处理得快。这是线上最常见的\"变慢\"原因。~n"),

    io:format("~n  -- 内存占用最大的进程 --~n"),
    MemList = [M || P <- erlang:processes(),
                    {memory, M} <- [process_info(P, memory)],
                    M =/= undefined],
    Biggest = lists:sublist(lists:reverse(lists:sort(MemList)), 3),
    io:format("  具体字节数每次运行都不一样（而且和调度器个数有关），~n"),
    io:format("  所以这里只断言它的**性质**：~n"),
    d("每个进程的内存都 > 0", lists:all(fun(M) -> M > 0 end, MemList)),
    d("取前三大的，结果是递减的",
      case Biggest of [A1, B1, C1 | _] -> A1 >= B1 andalso B1 >= C1; _ -> too_few end),
    d("三个之和 <= 总内存", lists:sum(Biggest) =< erlang:memory(processes)),

    io:format("~n  -- 一个进程到底在干什么 --~n"),
    d("process_info(whereis(kvapp_store), current_function) 有值吗",
      element(1, process_info(whereis(kvapp_store), current_function)) =/= undefined),
    d("  current_function 是个 {模块, 函数, 参数个数}",
      tuple_size(element(2, process_info(whereis(kvapp_store), current_function)))),
    d("  reductions（跑了多少\"步\"，越大越忙）",
      element(2, process_info(whereis(kvapp_store), reductions)) > 0),
    ok.

%% ---------------------------------------------------------------------------
%% 5) 常见错误清单
%% ---------------------------------------------------------------------------
mistakes() ->
    io:format("~n== 5) 常见错误清单 ==~n"),
    Rows =
     [{"改了代码但进程行为没变", "循环里用了局部调用，进程还在跑旧版本",
       "循环写成 ?MODULE:loop(State)"},
      {"release 升级后老进程跑老代码", "同上：最多同时存在两个版本",
       "要么全限定调用，要么让监督者重启进程"},
      {"code:purge 之后有进程莫名死了", "purge 会杀掉还在跑旧版的进程",
       "先用 code:soft_purge；确认没人用了再 purge"},
      {"sys:get_state 卡住不返回", "目标不是 OTP 进程（不处理系统消息）",
       "手写进程要在循环里调 sys:handle_system_msg/6，或者改用 gen_server"},
      {"sys:replace_state 改完服务行为怪了", "绕过了所有业务逻辑直接改内部状态",
       "只作为应急手段；改完要考虑重启"},
      {"用 sys:trace 之后日志刷屏", "trace 会把每条系统消息打到 stdout",
       "sys:no_debug(Pid) 一键关掉所有调试开关"},
      {"spawn 之后立刻用，偶尔拿不到", "start 返回时子进程还没初始化完",
       "用 proc_lib:init_ack 做启动同步，或者干脆用 gen_server"},
      {"崩溃报告里只有 pid，看不出是谁", "进程字典里没有 $initial_call",
       "用 proc_lib 起进程，或放进监督树"},
      {"线上\"变慢\"但 CPU 不高", "某个进程邮箱堆积",
       "按 message_queue_len 排序找最长的那个"},
      {"registered() 拿不到想要的名字", "进程已死或名字被别人先注册了",
       "whereis/1 返回 undefined 就当没这个人，别直接当 pid 用"}],
    [begin
         io:format("  ~ts~n", [What]),
         io:format("      现象：~ts~n", [Sym]),
         io:format("      处理：~ts~n", [Fix])
     end || {What, Sym, Fix} <- Rows],
    ok.
