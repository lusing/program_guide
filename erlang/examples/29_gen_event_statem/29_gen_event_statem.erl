%% ============================================================
%% 29_gen_event_statem —— gen_event 与 gen_statem：两种未覆盖的 OTP 行为
%%
%%    gen_event：事件管理器 + 可插拔处理器
%%      · manager 是一个进程；每个 handler 也是独立的小进程（不是模块）
%%      · notify 广播给所有 handler；call 定向某一个
%%      · handler 崩溃只损失自己：manager 摘掉它，别的 handler 继续
%%        （logger 的 handler 机制就是 gen_event 组装的——第 22 章）
%%    gen_statem：状态机即回调
%%      · callback_mode() -> state_functions：每个状态一个同名函数
%%      · 事件四类：{call,From} / cast / info / timeout（含 state_timeout）
%%      · 门禁锁 lock_statem 是教科书例：按对密码开门、超时清零自动落锁
%%
%%    辅助模块：evt_counter / evt_forward / evt_crash（gen_event 处理器）
%%              lock_statem（gen_statem 门禁锁）
%%
%% 编译：
%%   erlc -Werror -Wall -o build/29_gen_event_statem examples/29_gen_event_statem/*.erl
%% 运行：
%%   erl -noshell -pa build/29_gen_event_statem -run '29_gen_event_statem' main
%% ============================================================
-module('29_gen_event_statem').

-export([main/0]).

-define(TIMEOUT_SLICE, 1200).   %% 比 lock 的 state_timeout(1000ms) 长一截

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

main() ->
    logger:remove_handler(default),
    event_model(),
    crash_isolation(),
    swap_carries_state(),
    statem_lock(),
    io:format("~n==== 29 结束 ====~n").

%% ------------------------------------------------------------ %%
%% 1) 事件模型：manager 是进程，handler 是可插拔的小角色
%% ------------------------------------------------------------
event_model() ->
    io:format("~n== 1) 事件模型：manager 与 handler ==~n"),
    {ok, M} = gen_event:start({local, ex29_evt}),
    ok = gen_event:add_handler(M, evt_counter, []),
    ok = gen_event:add_handler(M, evt_forward, [self()]),
    d("当前 handler", lists:sort(gen_event:which_handlers(M))),
    %% notify 广播：两个 handler 各自收到
    ok = gen_event:notify(M, {tick, 1}),
    ok = gen_event:notify(M, {tick, 2}),
    ok = gen_event:notify(M, {tick, 3}),
    receive {event, {tick, 3}} -> d("forward handler 把事件转给了我（第 3 条）", ok)
    after 2000 -> d("forward", timeout) end,
    %% call 定向问 counter
    d("定向 call 问 counter 数了几条", gen_event:call(M, evt_counter, get_count, 2000)),
    %% 删掉一个 handler，另一个照常
    ok = gen_event:delete_handler(M, evt_forward, []),
    d("删 forward 后剩", lists:sort(gen_event:which_handlers(M))),
    ok = gen_event:notify(M, {tick, 4}),
    d("counter 又数了一条", gen_event:call(M, evt_counter, get_count, 2000)),
    gen_event:stop(M).

%% ------------------------------------------------------------ %%
%% 2) 崩溃隔离：handler 死了只死它自己
%% ------------------------------------------------------------
crash_isolation() ->
    io:format("~n== 2) 崩溃隔离：handler 死了只死它自己 ==~n"),
    {ok, M} = gen_event:start({local, ex29_crash}),
    ok = gen_event:add_handler(M, evt_counter, []),
    ok = gen_event:add_handler(M, evt_crash, []),
    ok = gen_event:notify(M, {normal_event, fine}),
    d("正常事件后 handler 都在", lists:sort(gen_event:which_handlers(M))),
    d("counter 数到", gen_event:call(M, evt_counter, get_count, 2000)),
    %% evt_crash 收到 {die, _} 就抛异常——manager 摘掉它，counter 无恙
    ok = gen_event:notify(M, {die, this_one_kills_me}),
    timer:sleep(50),                       %% 摘除是 manager 异步干的
    d("崩溃之后剩下的 handler", lists:sort(gen_event:which_handlers(M))),
    ok = gen_event:notify(M, {after_crash, still_alive}),
    d("counter 还在数", gen_event:call(M, evt_counter, get_count, 2000)),
    gen_event:stop(M).

%% ------------------------------------------------------------ %%
%% 3) swap_handler：热替换时把状态带过去
%% ------------------------------------------------------------
swap_carries_state() ->
    io:format("~n== 3) swap_handler：热替换时把状态带过去 ==~n"),
    {ok, M} = gen_event:start({local, ex29_swap}),
    ok = gen_event:add_handler(M, evt_counter, []),
    [ok = gen_event:notify(M, {tick, N}) || N <- lists:seq(1, 7)],
    d("替换前 counter 数到", gen_event:call(M, evt_counter, get_count, 2000)),
    %% swap：老 handler 的 terminate 返回值会传给新实例的 init
    %% （OTP 29 是 swap_handler/3：新旧 handler 连 args 各自成对，
    %%   老书里的 /4 写法已是 undef）
    ok = gen_event:swap_handler(M, {evt_counter, []}, {evt_counter, []}),
    d("替换后新 counter 从旧状态接着数", gen_event:call(M, evt_counter, get_count, 2000)),
    gen_event:stop(M).

%% ------------------------------------------------------------ %%
%% 4) gen_statem：门禁锁（state_functions 模式）
%% ------------------------------------------------------------
statem_lock() ->
    io:format("~n== 4) gen_statem：门禁锁 ==~n"),
    {ok, Pid} = lock_statem:start_link("314"),
    d("初始状态", lock_statem:status()),
    d("按对第一个数字（部分正确）", lock_statem:button($3)),
    d("状态里已按的数字", lock_statem:status()),
    d("按错下一位（前缀不匹配，清零）", lock_statem:button($9)),
    d("清零后的已按数字", lock_statem:status()),
    d("按完整正确序列", [lock_statem:button(D) || D <- "314"]),
    d("开门后的状态", lock_statem:status()),
    d("开门期间再按键（open 态只回 still_open）", lock_statem:button($1)),
    %% state_timeout：open 500ms 后自动落锁
    timer:sleep(?TIMEOUT_SLICE),
    d("超时自动落锁", lock_statem:status()),
    %% 超时清零：locked 期间按了部分数字，等 1s 后清空
    lock_statem:button($3),
    timer:sleep(?TIMEOUT_SLICE),
    {locked, []} = lock_statem:status(),
    d("locked 超时清零已按数字", ok),
    lock_statem:stop(),
    d("门禁进程收摊", is_process_alive(Pid) =:= false).
