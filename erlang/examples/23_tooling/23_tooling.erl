%% ---------------------------------------------------------------------------
%%  23_tooling —— sys 调试、proc_lib、热加载、typespec 与内省
%%
%%  编译：erlc -Werror -Wall -o build/23_tooling examples/23_tooling/*.erl
%%  运行：erl -noshell -pa build/23_tooling -run '23_tooling' main -s init stop
%%
%%  前面 22 章都在讲"怎么写"，这一章讲"上线之后怎么查"：
%%    1. sys 模块 —— 不停机就能看/改一个 OTP 进程的状态（本模块自带一个
%%       gen_server 当被观测对象，所以示例完全自包含）；
%%    2. proc_lib —— 让"自己手写的进程"也像个 OTP 进程；
%%    3. 热代码加载 —— 为什么你的循环函数改了却没生效；
%%    4. typespec 与 beam 内省 —— -spec 写在哪、dialyzer 怎么跑；
%%    5. 节点内省 —— 出问题第一眼看什么。
%%
%%  dialyzer 的完整工作流（建 PLT、跑分析、typer）见 docs/23-tooling.md，
%%  那里给了本机实测过的命令与输出。
%% ---------------------------------------------------------------------------
-module('23_tooling').

-behaviour(gen_server).

%% 演示与纯函数
-export([main/0, proc_init/1, proc_init/2, combine/2, tagged/1, start/0, start_failing/0]).
%% 自带的 gen_server API 与回调（sys 一节的观测对象）。
%% 注意 API 别叫 put/2——撞进程字典 BIF（15 章的坑），这里叫 set/2
-export([store_start/0, store_stop/0, set/2, count/0,
         init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

%% ---- typespec 示范：这些 -spec 会进 beam，dialyzer 拿它做成功类型推断 ----
-spec combine(string(), string()) -> string().
%% 把两段文本用空格连起来（spec 声明输入输出都是字符串）
combine(A, B) when is_list(A), is_list(B) -> A ++ " " ++ B.

-spec tagged(integer() | float()) -> {number(), integer()}.
tagged(N) when is_number(N) -> {N, trunc(N)}.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

-define(DIR, "build/erl-demo-23").
-define(SERVER, ?MODULE).

main() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    reset(),
    sys_module(),
    proc_lib_basics(),
    hot_code(),
    typespec_section(),
    introspection(),
    cleanup(),
    process_flag(trap_exit, Old),
    io:format("==== 23 结束 ====~n"),
    ok.

reset() ->
    _ = file:del_dir_r(?DIR),
    ok = file:make_dir(?DIR),
    ok = store_start().

cleanup() ->
    ok = store_stop(),
    _ = file:del_dir_r(?DIR),
    ok.

%% ---------------------------------------------------------------------------
%% 0) 自带的 gen_server（sys 一节的观测对象）
%% ---------------------------------------------------------------------------
store_start() ->
    case gen_server:start_link({local, ?SERVER}, ?MODULE, [], []) of
        {ok, _Pid} -> ok;
        {error, {already_started, _Pid}} -> ok
    end.

store_stop() ->
    try gen_server:stop(?SERVER) of ok -> ok catch exit:_ -> ok end.

set(K, V) -> gen_server:call(?SERVER, {put, K, V}).
count()   -> gen_server:call(?SERVER, count).

init(_Args) -> {ok, #{data => #{}, puts => 0}}.

handle_call({put, K, V}, _From, #{data := D, puts := P} = S) ->
    {reply, ok, S#{data := D#{K => V}, puts := P + 1}};
handle_call(count, _From, #{data := D} = S) ->
    {reply, maps:size(D), S};
handle_call(_Req, _From, S) ->
    {reply, {error, unknown_request}, S}.

handle_cast(_Req, S) -> {noreply, S}.
handle_info(_Info, S) -> {noreply, S}.
terminate(_Reason, _State) -> ok.

%% ---------------------------------------------------------------------------
%% 1) sys 模块：线上看状态、改状态
%% ---------------------------------------------------------------------------
sys_module() ->
    io:format("~n== 1) sys：不停机查看/修改一个 OTP 进程 ==~n"),
    io:format("  sys 是 OTP 自带的\"调试通道\"：它用**系统消息**跟进程说话，~n"),
    io:format("  所以不需要你在 gen_server 里写任何额外代码。~n~n"),

    d("sys:get_state（服务自己才知道的状态）", sys:get_state(?SERVER)),
    ok = set(alpha, 1),
    ok = set(beta, 2),
    d("  放了两条之后的 state", sys:get_state(?SERVER)),

    io:format("~n  -- 改状态：线上救急用，但要小心 --~n"),
    d("sys:replace_state 把 puts 计数改成 999",
      sys:replace_state(?SERVER, fun(S) -> S#{puts := 999} end)),
    d("  count()（数据没动）", count()),

    io:format("~n  -- get_status：人读的版本 --~n"),
    {status, _Pid, {module, Mod}, Items} = sys:get_status(?SERVER),
    d("是 {status, Pid, {module, _}, 清单} 这个形状吗", true),
    d("  module（是行为模块 gen_server，不是业务模块）", Mod),
    d("  清单长度（固定的 5 项）", length(Items)),
    Misc = lists:last(Items),
    d("  最后一项的 header", proplists:get_value(header, Misc)),
    d("  最后一项里的 State", element(2, lists:last(Misc))),
    io:format("  observer / 各种运维工具显示的就是这个结构。~n"),

    io:format("~n  -- 开关统计与日志 --~n"),
    d("sys:statistics 开", sys:statistics(?SERVER, true)),
    _ = count(),
    d("  开完之后 get_status 里多出来的项",
      [element(1, I) || I <- lists:last(element(4, sys:get_status(?SERVER)))]),
    d("sys:statistics 关", sys:statistics(?SERVER, false)),
    d("sys:log 开始记录事件", sys:log(?SERVER, true)),
    _ = count(),
    d("  记录下来的事件条数", length(logged_events(?SERVER))),
    d("sys:log 关", sys:log(?SERVER, false)),
    io:format("  sys:trace/2 会把每一条系统消息打到 stdout（刷屏，只在排障时开）；~n"),
    io:format("  sys:no_debug/1 一键关掉所有调试开关。~n"),
    _ = sys:no_debug(?SERVER),

    io:format("~n  -- 挂起与恢复 --~n"),
    d("sys:suspend", sys:suspend(?SERVER)),
    d("  挂起期间 call 会超时（业务侧表现为\"卡住\"）",
      try gen_server:call(?SERVER, count, 200) of V -> {unexpected, V}
      catch exit:R -> {exit, element(1, R)} end),
    d("sys:resume", sys:resume(?SERVER)),
    d("  恢复之后", count()),
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
    d("  start/0 返回时 init 已经跑完了（init_ack 保证的）", is_process_alive(P)),

    Dict = proc_dict_keys(P),
    d("  进程字典里的键", Dict),
    d("  $initial_call（崩溃报告靠它显示\"本来要跑哪个函数\"）",
      proplists:get_value('$initial_call', Dict)),
    d("  $ancestors 是个非空列表（谁启动了我；监督者靠它认孩子）",
      is_list(proplists:get_value('$ancestors', Dict))),

    Q = spawn(fun() -> receive stop -> ok end end),
    d("  对比：普通 spawn 的进程字典（没有这些身份信息）", proc_dict_keys(Q)),
    Q ! stop,

    io:format("~n  -- 初始化失败要显式通知 --~n"),
    d("init_fail 让调用方拿到错误", start_failing()),
    io:format("~n  ⚠ 常见误解：proc_lib **不**自动支持 sys。~n"),
    io:format("    想让手写进程也能被 sys 查看，循环里必须自己处理系统消息：~n"),
    io:format("        receive {system, From, Req} -> sys:handle_system_msg(Req, From, ...)~n"),
    io:format("    或者干脆用 gen_server —— 这些它都替你做了。~n"),
    exit(P, shutdown),
    ok.

proc_dict_keys(P) ->
    case process_info(P, dictionary) of
        {dictionary, D} when is_list(D) -> lists:sort([K || {K, _} <- D]);
        _ -> []
    end.

%% 用 proc_lib 启动：proc_init 里 init_ack 之后 start_link 才返回
%%（注意别叫 init/1——那是 gen_server 回调的名字，撞了行为就乱了）
start() -> proc_lib:start_link(?MODULE, proc_init, [self()]).
start_failing() -> proc_lib:start_link(?MODULE, proc_init, [self(), fail]).

proc_init(Parent) ->
    proc_lib:init_ack(Parent, {ok, self()}),
    plain_loop().

proc_init(Parent, fail) ->
    %% ⚠ 老 OTP 的 init_fail/2 是 (Parent, Ret)；现代版本 /2 变成了 (Ret, Exception)，
    %% 传 (Parent, Ret) 会把 Parent 当返回值发回——要用 /3：
    proc_lib:init_fail(Parent, {error, simulated_failure}, {exit, normal}).

plain_loop() ->
    receive
        stop -> ok;
        _ -> plain_loop()
    end.

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
%% 4) typespec 与 beam 内省：-spec 就在 beam 里
%% ---------------------------------------------------------------------------
typespec_section() ->
    io:format("~n== 4) typespec：-spec 写在哪，dialyzer 怎么用 ==~n"),
    d("combine(\"a\", \"b\")（带 -spec 的函数照常调用）", combine("a", "b")),
    d("tagged(3.7)（union 类型：integer() | float() 都收）", tagged(3.7)),
    io:format("  常用类型：integer()/float()/number()、string()/binary()、~n"),
    io:format("  [T]（T 的列表）、{A,B}（元组）、map()、atom()、any()、~n"),
    io:format("  自定义 -type my_type() :: {ok, integer()} | {error, term()}。~n"),

    io:format("~n  -- spec 存在 beam 的抽象代码里（前提：编译带 +debug_info，~n"),
    io:format("     erlc 默认**不带**——不带的话 beam 里就是 no_abstract_code） --~n"),
    {ok, Beam} = file:read_file(code:which(?MODULE)),
    {ok, {_, [{abstract_code, {raw_abstract_v1, Forms}}]}} =
        beam_lib:chunks(Beam, [abstract_code]),
    Specs = [F || {attribute, _, spec, _} = F <- Forms],
    d("本模块里 -spec 属性的个数", length(Specs)),
    d("第一个 -spec 的形状（函数名 + 输入输出类型）",
      begin
          {attribute, _, spec, {{Name, Arity}, [{type, _, 'fun', _} | _]}} = hd(Specs),
          {Name, Arity}
      end),
    io:format("  dialyzer 的工作流（本机实测命令在 docs/23-tooling.md）：~n"),
    io:format("    dialyzer --build_plt --apps erts kernel stdlib   # 一次性建 PLT~n"),
    io:format("    dialyzer --plt PLT build/23_tooling/*.beam        # 静态分析~n"),
    io:format("    typer --plt PLT build/23_tooling/*.beam           # 反推缺失的 -spec~n"),
    io:format("  typer 不需要手动建 PLT（自己会用默认的）。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 5) 内省：出问题第一眼看什么
%% ---------------------------------------------------------------------------
introspection() ->
    io:format("~n== 5) 内省：出问题第一眼看什么 ==~n"),
    d("进程数 > 0", length(erlang:processes()) > 0),
    d("  已经注册了名字的进程数 > 0", length(registered()) > 0),

    io:format("~n  -- 按注册名找进程 --~n"),
    d("whereis(?SERVER) 是 pid 吗", is_pid(whereis(?SERVER))),
    d("whereis(一个没注册的名字)", whereis(no_such_name_zzz)),
    d("  registered() 里能找到自己吗", lists:member(?SERVER, registered())),

    io:format("~n  -- 找出\"最可疑\"的进程：邮箱最长的 --~n"),
    QueueLens = [QL || P <- erlang:processes(),
                       {message_queue_len, QL} <- [process_info(P, message_queue_len)],
                       QL =/= undefined],
    d("全部进程的邮箱长度都是 0（演示环境安静）",
      lists:all(fun(QL) -> QL =:= 0 end, QueueLens)),
    io:format("  线上排查：按 message_queue_len 倒序取前几名（代码见示例）——~n"),
    io:format("  邮箱一直涨 = 有人发得比处理得快，这是线上最常见的\"变慢\"。~n"),

    io:format("~n  -- 内存占用最大的进程（只断言性质） --~n"),
    MemList = [M || P <- erlang:processes(),
                    {memory, M} <- [process_info(P, memory)],
                    M =/= undefined],
    Biggest = lists:sublist(lists:reverse(lists:sort(MemList)), 3),
    d("每个进程的内存都 > 0", lists:all(fun(M) -> M > 0 end, MemList)),
    d("取前三大的，结果是递减的",
      case Biggest of [A1, B1, C1 | _] -> A1 >= B1 andalso B1 >= C1; _ -> too_few end),
    d("三个之和 <= 总内存", lists:sum(Biggest) =< erlang:memory(processes)),

    io:format("~n  -- 一个进程到底在干什么 --~n"),
    d("process_info 的 current_function 是 {模块, 函数, 参数个数}",
      tuple_size(element(2, process_info(whereis(?SERVER), current_function)))),
    d("  reductions（跑了多少\"步\"，越大越忙）",
      element(2, process_info(whereis(?SERVER), reductions)) > 0),
    ok.




