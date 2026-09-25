%% ============================================================
%% 30_profiling —— 性能剖析与跟踪：先测量，再动手
%%
%%    三件套各管一段：
%%      · timer:tc    —— 一段代码跑了多久（微秒）；时间只能断言性质，
%%                       绝不能打印数值（环境数字毁确定性）
%%      · cprof       —— 计数剖析：谁被调用了多少次；**计数是确定性的**，
%%                       可以打印——这是唯一能进验证输出的剖析数据
%%      · erlang:trace—— 事件跟踪：call 起来了/返回了/进程死了……
%%                       自己起一个 tracer 进程收集、聚合计数后打印
%%    （fprof/dbg 输出带绝对时间与调用链，不适合逐字节验证——概念段讲）
%%
%%    观察者效应：剖析完必须停——cprof:stop 归零、trace_pattern 关掉，
%%    否则「测一次永远付代价」。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/30_profiling examples/30_profiling/30_profiling.erl
%% 运行：
%%   erl -noshell -pa build/30_profiling -run '30_profiling' main
%% ============================================================
-module('30_profiling').

-export([main/0, fib/1, fib_calls/1, workload/0, trace_calls/1]).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% 固定工作负载：朴素递归 fib（调用次数爆炸，适合当剖析标本）
fib(0) -> 0;
fib(1) -> 1;
fib(N) -> fib(N - 1) + fib(N - 2).

%% 调用次数的闭式：calls(n) = 1 + calls(n-1) + calls(n-2)
fib_calls(0) -> 1;
fib_calls(1) -> 1;
fib_calls(N) -> 1 + fib_calls(N - 1) + fib_calls(N - 2).

workload() ->
    _ = fib(18),
    _ = lists:sum(lists:seq(1, 500)),
    ok.

main() ->
    logger:remove_handler(default),
    timer_tc(),
    counting_with_cprof(),
    tracing_with_tracer(),
    system_glance(),
    io:format("~n==== 30 结束 ====~n").

%% ------------------------------------------------------------ %%
%% 1) timer:tc：一段代码跑多久
%% ------------------------------------------------------------
timer_tc() ->
    io:format("~n== 1) timer:tc：一段代码跑多久 ==~n"),
    {Micros, 2584} = timer:tc(?MODULE, fib, [18]),
    d("结果对（fib(18)=2584）", ok),
    d("耗时只断言性质（微秒数 >= 0），数值不打印", Micros >= 0),
    io:format("  （打印微秒数 = 每台机器每次跑都不一样——验证第 4 层直接挂）~n").

%% ------------------------------------------------------------ %%
%% 2) cprof：计数剖析——唯一确定性的剖析数据
%% ------------------------------------------------------------
counting_with_cprof() ->
    io:format("~n== 2) cprof：计数剖析 ==~n"),
    cprof:start(),
    ok = workload(),
    cprof:pause(),
    {Total, PerMod} = cprof:analyse(),
    d("总调用次数（只数函数调用，不含时间）", Total > 1000),
    Counts = [{M, C} || {M, C, _FAs} <- PerMod, M =/= cprof],
    d("按模块计数（排序后）", lists:reverse(lists:keysort(2, Counts))),
    {?MODULE, Own, FAs} = cprof:analyse(?MODULE),
    d("本模块被调用的次数", Own),
    TopFA = lists:last(lists:keysort(2, FAs)),
    d("本模块最热的函数（fib 递归）", TopFA),
    %% 自证：fib(18) 的调用次数应等于闭式
    [{{?MODULE, fib, 1}, Measured}] = [Pair || {{M, F, 1}, _} = Pair <- FAs,
                                               M =:= ?MODULE, F =:= fib],
    d("fib/1 实测次数 == 闭式推算", Measured =:= fib_calls(18)),
    cprof:stop(),
    d("stop 之后重新 analyse（观察者效应要收摊）", cprof:analyse(?MODULE)).

%% ------------------------------------------------------------ %%
%% 3) erlang:trace + 自定义 tracer：事件流变成计数
%% ------------------------------------------------------------
%% 起 tracer 进程：收 {trace, Pid, call, {M, F, Arity}} 计数，
%% 收 stop 回 aggregated 排序结果
trace_calls(Fun) ->
    Tracer = spawn(fun () -> collect(#{}) end),
    %% 只跟踪本模块的函数（含 local 调用——fib 自己调自己），
    %% arity 模式只记 {M, F, 元数}，不记参数（参数会进输出、还可能是大项）
    %% trace_pattern 返回**匹配到的函数个数**（不是 1！）
    Matched = erlang:trace_pattern({?MODULE, '_', '_'}, true, [local]),
    true = Matched > 0,
    %% arity 是 trace/3 的消息旗标（不记参数只记元数）——裸原子，
    %% 不是元组；也不是 trace_pattern 的选项（放错位置直接 badarg）
    1 = erlang:trace(self(), true, [call, arity, {tracer, Tracer}]),
    _ = Fun(),
    1 = erlang:trace(self(), false, [call]),
    _ = erlang:trace_pattern({?MODULE, '_', '_'}, false, [local]),
    Tracer ! {stop, self()},
    receive {counts, Counts} -> Counts after 3000 -> timeout end.

collect(Acc) ->
    receive
        {trace, _Pid, call, MFA} ->
            collect(Acc#{MFA => maps:get(MFA, Acc, 0) + 1});
        {stop, ReplyTo} ->
            ReplyTo ! {counts, lists:keysort(1, maps:to_list(Acc))}
    after 2000 -> ok
    end.

tracing_with_tracer() ->
    io:format("~n== 3) erlang:trace + 自定义 tracer ==~n"),
    Counts = trace_calls(fun () -> fib(10) end),
    [{{?MODULE, fib, 1}, N}] = [P || {{M, F, 1}, _} = P <- Counts,
                                      M =:= ?MODULE, F =:= fib],
    d("trace 到的 fib/1 调用次数 == 闭式", N =:= fib_calls(10)),
    d("收集到的函数种类（排序）", [FA || {FA, _} <- Counts]),
    io:format("  （dbg 模块是交互式 tracer 的开箱版；fprof 还能出调用链与耗时，~n"),
    io:format("   但输出带绝对时间——只讲不跑，进不了逐字节验证）~n").

%% ------------------------------------------------------------ %%
%% 4) 系统一瞥：环境数字只断言性质
%% ------------------------------------------------------------
system_glance() ->
    io:format("~n== 4) 系统一瞥 ==~n"),
    d("调度器数量 >= 1", erlang:system_info(schedulers) >= 1),
    d("运行队列长度 >= 0（繁忙程度的瞬时值）",
      erlang:statistics(run_queue) >= 0),
    d("进程数 >= 1", erlang:system_info(process_count) >= 1),
    io:format("  （erlang:memory/0 各项字节数同理：概念要懂，数字不打印）~n").
