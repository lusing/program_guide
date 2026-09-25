%% ============================================================
%% 31_multicore —— 多核并行：pmap 三变体与 future
%%
%%    Erlang 的并行不需要锁：每个进程一个邮箱，调度器铺满所有核。
%%      · pmap 无序版 —— spawn 一批、谁先完成收谁（结果 sort 后才可打印）
%%      · pmap 有序版 —— 消息带序号，按原顺序重组（书上的经典实现）
%%      · pmmap 超时版 —— 卡死的元素放弃：收完 deadline 就杀 worker；
%%        「迟到送达的孤儿消息」要用 drain 清理，否则污染后面的测试
%%      · future      —— 先起步、后取值：spawn + ref 配对
%%
%%    确定性铁律：输出里绝不出现时间数字（加速比因机器而异）——
%%    只有计数、排序后的结果、布尔。串行 vs 并行的**结果等价**可以断言。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/31_multicore examples/31_multicore/31_multicore.erl
%% 运行：
%%   erl -noshell -pa build/31_multicore -run '31_multicore' main
%% ============================================================
-module('31_multicore').

-export([main/0, fib/1, pmap_unordered/2, pmap_ordered/2, pmmap/3,
         future/1, yield/1]).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

fib(0) -> 0;
fib(1) -> 1;
fib(N) -> fib(N - 1) + fib(N - 2).

%% 无序 pmap：收满为止，结果顺序 = 完成顺序（打印前必须 sort）
pmap_unordered(Fun, List) ->
    Parent = self(),
    _ = [spawn(fun () -> Parent ! {pmap_tag, Fun(X)} end) || X <- List],
    [receive {pmap_tag, V} -> V end || _ <- List].

%% 有序 pmap：消息带序号，按输入顺序重组
pmap_ordered(Fun, List) ->
    Parent = self(),
    Indexes = lists:seq(1, length(List)),
    _ = [spawn(fun () -> Parent ! {{tag, I}, Fun(X)} end)
         || {I, X} <- lists:zip(Indexes, List)],
    [receive {{tag, I}, V} -> V end || I <- Indexes].

%% 超时版 pmap：到点收工，没完成的杀掉。返回「已完成部分的序号」
%% （排序后给出——缺谁就是谁超时了）
pmmap(Fun, Timeout, List) ->
    Parent = self(),
    Refs = [{I, spawn(fun () -> Parent ! {{pm, I}, Fun(X)} end)}
            || {I, X} <- lists:zip(lists:seq(1, length(List)), List)],
    Done = collect_pm(Timeout, length(Refs), []),
    %% 杀掉没完成的 worker：先杀（被杀的不会再发），grace 一拍后
    %% 把「正在路上」的孤儿消息扫掉，否则污染调用方后面的 receive
    DoneIdx = [I || {I, _} <- Done],
    [exit(P, kill) || {I, P} <- Refs, not lists:member(I, DoneIdx)],
    timer:sleep(30),
    drain_pm(),
    DoneIdx.

collect_pm(_Timeout, 0, Done) -> lists:sort(Done);
collect_pm(Timeout, Left, Done) ->
    receive
        {{pm, I}, V} ->
            collect_pm(Timeout, Left - 1, [{I, V} | Done])
    after Timeout ->
            %% 整体只等一个 deadline：收到几条算几条，剩下的放弃
            lists:sort(Done)
    end.

drain_pm() ->
    receive {{pm, _}, _} -> drain_pm() after 0 -> ok end.

%% future：先起步后取值
future(Fun) ->
    Ref = make_ref(),
    Parent = self(),
    spawn(fun () -> Parent ! {Ref, Fun()} end),
    Ref.

yield(Ref) ->
    receive {Ref, V} -> V end.

main() ->
    logger:remove_handler(default),
    schedulers(),
    serial_baseline(),
    unordered_pmap(),
    ordered_pmap(),
    timeout_pmap(),
    futures(),
    io:format("~n==== 31 结束 ====~n").

%% ------------------------------------------------------------ %%
%% 1) 多核现实：调度器铺满核
%% ------------------------------------------------------------
schedulers() ->
    io:format("~n== 1) 多核现实：调度器铺满核 ==~n"),
    d("调度器数量 >= 1（具体数字因机器而异，不打印）",
      erlang:system_info(schedulers) >= 1),
    d("在线调度器 >= 1", erlang:system_info(schedulers_online) >= 1),
    io:format("  （+S 1:1 强制成单调度器——并行变交织，结果不该有任何变化）~n").

%% ------------------------------------------------------------ %%
%% 2) 串行基线
%% ------------------------------------------------------------
serial_baseline() ->
    io:format("~n== 2) 串行基线 ==~n"),
    Input = [14, 15, 16, 17, 18],
    Serial = [fib(X) || X <- Input],
    d("串行 map 的结果", Serial),
    d("和 lists:map 一致", lists:map(fun fib/1, Input) =:= Serial).

%% ------------------------------------------------------------ %%
%% 3) 无序 pmap：完成顺序不等于输入顺序
%% ------------------------------------------------------------
unordered_pmap() ->
    io:format("~n== 3) 无序 pmap ==~n"),
    Input = [17, 14, 16, 15, 18],
    Got = pmap_unordered(fun fib/1, Input),
    d("收齐后 sort（完成顺序随机，排序后才可打印）", lists:sort(Got)),
    d("与串行结果一致（结果等价是可断言的）",
      lists:sort(Got) =:= lists:sort([fib(X) || X <- Input])).

%% ------------------------------------------------------------ %%
%% 4) 有序 pmap：序号 tag 按输入顺序重组
%% ------------------------------------------------------------
ordered_pmap() ->
    io:format("~n== 4) 有序 pmap ==~n"),
    Input = [18, 14, 17, 15, 16],
    Got = pmap_ordered(fun fib/1, Input),
    d("输出顺序 = 输入顺序（谁先算完无所谓）", Got),
    d("逐项等于串行 map", Got =:= [fib(X) || X <- Input]).

%% ------------------------------------------------------------ %%
%% 5) 超时版 pmmap：卡死的元素被放弃
%% ------------------------------------------------------------
timeout_pmap() ->
    io:format("~n== 5) 超时版 pmmap ==~n"),
    %% 3 号元素卡死 60 秒，其他都是快活
    Job = fun (3) -> receive after 60_000 -> never end;
              (_X) -> quick
          end,
    Done = pmmap(Job, 300, [1, 2, 3, 4]),
    d("完成的序号（3 号卡死被放弃）", Done),
    d("放弃即放弃：没有兜底等待", Done =:= [1, 2, 4]).

%% ------------------------------------------------------------ %%
%% 6) future：先起步，后取值
%% ------------------------------------------------------------
futures() ->
    io:format("~n== 6) future：先起步，后取值 ==~n"),
    F1 = future(fun () -> fib(20) end),
    F2 = future(fun () -> lists:sum(lists:seq(1, 1000)) end),
    %% 两个都已起步；此刻主进程还能干别的活
    d("起步后再干活", 1 + 1),
    d("取第一个 future", yield(F1)),
    d("取第二个 future", yield(F2)),
    io:format("  （加速比多大不打——那要跑时间数字；结果正确才是可验证的）~n").
