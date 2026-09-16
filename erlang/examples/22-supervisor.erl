%% ============================================================
%% 22 - supervisor：把「崩了就重启」变成声明式的
%%
%%    第 20 章我们看到，手写 link + trap_exit 很快就不够用了：
%%    重启几次、重启太频繁怎么办、谁先起谁后起、怎么整体关停……
%%    supervisor 把这些变成一份**声明**：给我子进程清单 + 重启策略，
%%    剩下的它负责。
%%
%%    本章全部结论都是**实测**出来的，而且用「收到几条 child_up 消息」
%%    来判定重启范围，而不是靠等待时间猜。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/22-supervisor.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '22-supervisor' main -s init stop
%% ============================================================
-module('22-supervisor').

-behaviour(supervisor).

-export([main/0, init/1, worker_start/1, child_loop/0,
         start_sup/4, kill/2, drain/0]).

%% ------------------------------------------------------------
%% 子进程：演示用最朴素的 spawn_link。真实项目里这里应该是 gen_server。
%% ------------------------------------------------------------
%% supervisor 对子进程的两条硬性要求：
%%   1. start 函数必须返回 {ok, Pid}（失败返回 {error, Reason} 或 ignore）
%%   2. 那个进程必须**已经和 supervisor 建立链接** —— 否则它死了，
%%      supervisor 根本不知道，也就无所谓重启。
%%      用 spawn_link / proc_lib:spawn_link / gen_server:start_link 都行。
worker_start({Tag, Notify}) ->
    Pid = spawn_link(fun() ->
                             Notify ! {child_up, Tag},
                             child_loop()
                     end),
    {ok, Pid}.

child_loop() ->
    receive
        stop -> ok
    end.

%% ------------------------------------------------------------
%% 子进程规格（child spec）
%% ------------------------------------------------------------
%% 新版写法是 map（老的元组 {Id, Start, Restart, Shutdown, Type, Modules} 也行）：
%%   id       唯一标识（原子或 term）；重启策略靠它区分「同一个孩子」
%%   start    {模块, 函数, 参数}，必须返回 {ok, Pid}
%%   restart  permanent  —— 永远重启（默认）
%%            transient  —— 只有**异常**退出才重启（正常退出不重启）
%%            temporary  —— 从不重启
%%   shutdown 关闭时给多少毫秒；brutal_kill 表示直接 exit(Pid, kill)
%%            对 worker 常用 5000，对 supervisor 用 infinity
%%   type     worker | supervisor
%%   modules  给 release 升级用的提示，一般写 [?MODULE]
spec(Tag, Notify) ->
    #{id => Tag,
      start => {?MODULE, worker_start, [{Tag, Notify}]},
      restart => permanent,
      shutdown => 5000,
      type => worker,
      modules => [?MODULE]}.

%% init/1 返回 {ok, {SupFlags, ChildSpecs}}
%%   strategy  one_for_one   谁崩了重启谁（默认，最常用）
%%             one_for_all   任何一个崩了，全部重启
%%             rest_for_one  崩的那个 + 启动顺序在它**之后**的全部重启
%%   intensity / period      在 period 秒内最多重启 intensity 次；
%%                           超过就放弃并把整个监督树关掉（防止无限重启风暴）
init({Strategy, Intensity, Period, Tags, Notify}) ->
    SupFlags = #{strategy => Strategy, intensity => Intensity, period => Period},
    {ok, {SupFlags, [spec(T, Notify) || T <- Tags]}}.

%% 本模块同时充当示例的 main，所以不带 handle_info 之类的额外回调。

%% ------------------------------------------------------------
%% 演示
%% ------------------------------------------------------------
main() ->
    %% supervisor 的重启/放弃都会走 logger 默认 handler（带时间戳），先摘掉。
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),

    strategy_table(),
    one_for_one_demo(),
    one_for_all_demo(),
    rest_for_one_demo(),
    intensity_demo(),
    inspect_and_dynamic(),

    process_flag(trap_exit, Old),
    io:format("~n==== 22 结束 ====~n").

strategy_table() ->
    io:format("== 1) 三种重启策略 ==~n"),
    %% 中文标签不做定宽对齐：~-30ts 的宽度按**字符数**算，
    %% 而一个汉字占两列，表格必然错位（第 13 章有按显示宽度补空格的写法）。
    %% 这里干脆一行一条，省掉对齐问题。
    Rows = [{"one_for_one", "谁崩了重启谁", "进程之间互相独立"},
            {"one_for_all", "任何一个崩了，全部重启", "进程之间有强耦合，缺一不可"},
            {"rest_for_one", "崩的那个 + 它之后启动的全部重启", "有启动依赖（如先 DB 后缓存）"}],
    io:format("~n"),
    [begin
         io:format("  ~ts —— ~ts~n", [A, B]),
         io:format("      适用：~ts~n", [C])
     end || {A, B, C} <- Rows],
    ok.

%% ------------------------------------------------------------
%% 观察工具
%% ------------------------------------------------------------
start_sup(Strategy, Intensity, Tags, Notify) ->
    {ok, Sup} = supervisor:start_link(?MODULE, {Strategy, Intensity, 1, Tags, Notify}),
    %% 每个孩子起来都会发一条 {child_up, Tag}，全部收进来
    [_ = wait_child_up() || _ <- Tags],
    Sup.

wait_child_up() ->
    receive {child_up, T} -> T after 2000 -> timeout end.

%% 按 id 杀孩子。
%% **不能**用 which_children 的第一个元素当「第一个孩子」——
%% 官方文档明确说 which_children 的返回顺序是未定义的，
%% 依赖顺序的示例在别的 OTP 版本上就会翻车。
kill(Sup, Id) ->
    {Id, Pid, _Type, _Mods} = lists:keyfind(Id, 1, supervisor:which_children(Sup)),
    exit(Pid, kill),
    ok.

drain() ->
    receive {child_up, T} -> [T | drain()] after 150 -> [] end.

%% 杀掉 Id，收集这一轮的重启消息。
%% Expected 是**预期**的重启个数（由策略决定，见各 demo）；
%% 等够 Expected 条之后再 drain 一下确认没有多余消息 ——
%% 报告比预期多出来的部分，而不是把它们混进下一轮。
restart_round(Sup, Id, Expected) ->
    kill(Sup, Id),
    Got = [wait_child_up() || _ <- lists:seq(1, Expected)],
    Extra = drain(),
    lists:sort(Got) ++ [{unexpected_extra, X} || X <- Extra].

%% ------------------------------------------------------------
%% 三种策略的实测对比
%% ------------------------------------------------------------
%% 都是「三个孩子 a/b/c（启动顺序 a → b → c），杀掉其中一个，看谁被重启」。
%% 为什么杀 c 而不是杀 a：one_for_all 与 rest_for_one 在「杀第一个」时结果相同，
%% 必须杀**最后一个**才能把两者区分开。
one_for_one_demo() ->
    io:format("~n== 2) one_for_one：只重启崩掉的那个 ==~n"),
    Sup = start_sup(one_for_one, 5, [a, b, c], self()),
    d("三个孩子都起来了", ready),
    d("杀掉 c 之后被重启的是", restart_round(Sup, c, 1)),
    d("再杀掉 c 之后被重启的是", restart_round(Sup, c, 1)),
    stop_sup(Sup),
    ok.

one_for_all_demo() ->
    io:format("~n== 3) one_for_all：一个崩了全部重启 ==~n"),
    Sup = start_sup(one_for_all, 5, [a, b, c], self()),
    d("三个孩子都起来了", ready),
    d("杀掉 c 之后被重启的是（三个都重启）", restart_round(Sup, c, 3)),
    stop_sup(Sup),
    ok.

rest_for_one_demo() ->
    io:format("~n== 4) rest_for_one：崩的那个 + 它之后启动的 ==~n"),
    Sup = start_sup(rest_for_one, 5, [a, b, c], self()),
    d("三个孩子都起来了（启动顺序 a → b → c）", ready),
    d("杀掉 c（最后一个）之后被重启的是（只有它）", restart_round(Sup, c, 1)),
    Sup2 = start_sup(rest_for_one, 5, [a, b, c], self()),
    d("杀掉 a（第一个）之后被重启的是（它和后面的）", restart_round(Sup2, a, 3)),
    stop_sup(Sup2),
    stop_sup(Sup),
    ok.

%% ------------------------------------------------------------
%% 重启强度：撑不住就整体关掉
%% ------------------------------------------------------------
%% intensity = 2 / period = 1 表示「1 秒内最多重启 2 次」。
%% 连续杀 3 次 → 第 3 次时 supervisor 放弃，把整棵树关掉并终止。
%% 这是**有意的**保护：如果子进程在 init 里就崩，没有这个限制就会无限重启风暴。
intensity_demo() ->
    io:format("~n== 5) 重启强度（intensity / period） ==~n"),
    {ok, Sup} = supervisor:start_link(?MODULE, {one_for_one, 2, 1, [a], self()}),
    _ = wait_child_up(),
    MRef = erlang:monitor(process, Sup),
    %% 第 1、2 次会被正常重启
    R1 = kill_and_wait(Sup),
    R2 = kill_and_wait(Sup),
    d("前两次杀掉都被重启了", {R1, R2}),
    %% 第 3 次超过强度 → 整个 supervisor 结束
    kill(Sup, a),
    d("第 3 次之后 supervisor 自己的终止原因",
      receive {'DOWN', MRef, process, _, Reason} -> Reason after 3000 -> still_running end),
    d("supervisor 死了以后孩子还在吗（which_children 会退出）",
      try supervisor:count_children(Sup) of
          _ -> some_children_left
      catch
          exit:_ -> supervisor_gone
      end),
    ok.

kill_and_wait(Sup) ->
    restart_round(Sup, a, 1).

stop_sup(Sup) ->
    MRef = erlang:monitor(process, Sup),
    exit(Sup, shutdown),
    receive {'DOWN', MRef, process, _, _} -> ok after 2000 -> ok end.

%% ------------------------------------------------------------
%% 观察监督树 + 运行期增删孩子
%% ------------------------------------------------------------
inspect_and_dynamic() ->
    io:format("~n== 6) 观察与运行期增删 ==~n"),
    Sup = start_sup(one_for_one, 5, [a, b], self()),
    %% which_children 返回 [{Id, Pid, Type, Modules}] —— 含 pid，不能直接打印
    %% which_children 的顺序是**未定义**的，所以要 sort 才是确定输出
    d("which_children 的稳定形状",
      lists:sort([{Id, is_pid(Pid), Type}
                  || {Id, Pid, Type, _} <- supervisor:which_children(Sup)])),
    d("count_children", lists:sort(supervisor:count_children(Sup))),
    %% 动态加一个孩子
    {ok, _Pid} = supervisor:start_child(Sup, spec(c, self())),
    _ = wait_child_up(),
    d("start_child 之后 count_children", lists:sort(supervisor:count_children(Sup))),
    %% 关掉并删掉它（两步：terminate 是「停」，delete 才是「从清单里去掉」）
    d("terminate_child 的返回", supervisor:terminate_child(Sup, c)),
    d("delete_child 的返回", supervisor:delete_child(Sup, c)),
    d("删掉之后 count_children", lists:sort(supervisor:count_children(Sup))),
    %% 重复删除会被拒绝（这是好事：说明 supervisor 在管着你）
    d("重复 delete_child 的返回", supervisor:delete_child(Sup, c)),
    stop_sup(Sup),
    ok.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
