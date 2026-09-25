%% ============================================================
%% 29_gen_event_statem 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/29_gen_event_statem examples/29_gen_event_statem/*_tests.erl
%%   erl -noshell -pa build/29_gen_event_statem -eval "eunit:test('29_gen_event_statem_tests'), halt()."
%% ============================================================
-module('29_gen_event_statem_tests').

-include_lib("eunit/include/eunit.hrl").

counter_counts_test() ->
    {ok, M} = gen_event:start(),
    try
        ok = gen_event:add_handler(M, evt_counter, []),
        [ok = gen_event:notify(M, {tick, N}) || N <- lists:seq(1, 5)],
        ?assertEqual(5, gen_event:call(M, evt_counter, get_count, 2000)),
        %% delete 的返回值就是 terminate 的返回值——状态外带的通道
        ?assertEqual({ok, 5}, gen_event:delete_handler(M, evt_counter, [])),
        [ok = gen_event:notify(M, later) || _ <- [1, 2]],
        ?assertEqual([], gen_event:which_handlers(M))
    after
        gen_event:stop(M)
    end.

forward_test() ->
    {ok, M} = gen_event:start(),
    try
        ok = gen_event:add_handler(M, evt_forward, [self()]),
        ok = gen_event:notify(M, hello_from_forward),
        receive {event, hello_from_forward} -> ok
        after 2000 -> error(forward_missing)
        end
    after
        gen_event:stop(M)
    end.

crash_isolation_test() ->
    {ok, M} = gen_event:start(),
    try
        ok = gen_event:add_handler(M, evt_counter, []),
        ok = gen_event:add_handler(M, evt_crash, []),
        ok = gen_event:notify(M, fine),
        timer:sleep(20),
        ?assertEqual(1, gen_event:call(M, evt_counter, get_count, 2000)),
        ok = gen_event:notify(M, {die, on_purpose}),
        timer:sleep(50),      %% 摘除是 manager 异步做的
        ?assertEqual([evt_counter], lists:sort(gen_event:which_handlers(M))),
        ok = gen_event:notify(M, still_fine),
        %% {die,...} 这条也广播到了 counter——它自己不崩就照数
        ?assertEqual(3, gen_event:call(M, evt_counter, get_count, 2000))
    after
        gen_event:stop(M)
    end.

swap_carries_state_test() ->
    {ok, M} = gen_event:start(),
    try
        ok = gen_event:add_handler(M, evt_counter, []),
        [ok = gen_event:notify(M, tick) || _ <- lists:seq(1, 7)],
        ok = gen_event:swap_handler(M, {evt_counter, []}, {evt_counter, []}),
        ?assertEqual(7, gen_event:call(M, evt_counter, get_count, 2000)),
        ok = gen_event:notify(M, tick),
        ?assertEqual(8, gen_event:call(M, evt_counter, get_count, 2000))
    after
        gen_event:stop(M)
    end.

lock_happy_path_test() ->
    {ok, Pid} = lock_statem:start_link("314"),
    try
        ?assertEqual({locked, []}, lock_statem:status()),
        ?assertEqual(partial, lock_statem:button($3)),
        ?assertEqual({locked, "3"}, lock_statem:status()),
        ?assertEqual(wrong, lock_statem:button($9)),
        ?assertEqual({locked, []}, lock_statem:status()),
        ?assertEqual([partial, partial, unlock],
                     [lock_statem:button(D) || D <- "314"]),
        ?assertEqual({open, []}, lock_statem:status())
    after
        lock_statem:stop(),
        ?assert(not is_process_alive(Pid))
    end.

lock_auto_relock_and_clear_test() ->
    {ok, _Pid} = lock_statem:start_link("11"),
    try
        ?assertEqual([partial, unlock], [lock_statem:button(D) || D <- "11"]),
        timer:sleep(700),                       %% open 500ms 超时落锁
        ?assertEqual({locked, []}, lock_statem:status()),
        %% locked 部分输入 1000ms 超时清零
        partial = lock_statem:button($1),
        timer:sleep(1200),
        ?assertEqual({locked, []}, lock_statem:status()),
        %% 落锁后 still_open 的窗口也没了：正常按部分
        ?assertEqual(partial, lock_statem:button($1))
    after
        lock_statem:stop()
    end.
