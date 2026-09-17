%% ============================================================
%% 20_time 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/20_time examples/20_time/*_tests.erl
%%   erl -noshell -pa build/20_time -eval "eunit:test('20_time_tests'), halt()."
%% ============================================================
-module('20_time_tests').

-include_lib("eunit/include/eunit.hrl").

send_after_test() ->
    %% send_after 原样投递消息；start_timer 包一层 {timeout, Ref, Msg}
    Ref = erlang:send_after(20, self(), hello_timer),
    ?assert(is_reference(Ref)),
    ?assertEqual(hello_timer, receive M -> M after 2000 -> timeout end),
    TRef = erlang:start_timer(20, self(), payload),
    ?assertMatch({timeout, TRef, payload},
                 receive M2 = {timeout, TRef, _} -> M2 after 2000 -> timeout end).

cancel_timer_test() ->
    %% cancel 返回剩余毫秒；已触发/已取消返回 false
    TRef = erlang:start_timer(30000, self(), never),
    ?assertMatch(N when is_integer(N) andalso N > 0,
                 erlang:cancel_timer(TRef)),
    ?assertEqual(false, erlang:cancel_timer(TRef)),
    ?assertEqual(false, erlang:read_timer(TRef)),
    %% 已触发过的定时器：cancel 也是 false（不是剩余 0）
    Fired = erlang:start_timer(10, self(), fired),
    receive {timeout, Fired, fired} -> ok after 2000 -> ok end,
    ?assertEqual(false, erlang:cancel_timer(Fired)).

timer_module_cancel_test() ->
    %% timer:cancel 永远返回 {ok,cancel}——不能用来判断成功与否
    {ok, TRef} = timer:send_after(2000, self(), never),
    ?assertEqual({ok, cancel}, timer:cancel(TRef)),
    ?assertEqual({ok, cancel}, timer:cancel(TRef)),   %% 再 cancel 还是 ok！
    ?assertMatch({error, _}, timer:cancel(make_ref())).

timeout_value_test() ->
    %% 超时值非法是 timeout_value 不是 badarg
    ?assertException(error, timeout_value,
                     (fun() -> receive q -> ok after opaque_neg() -> ok end end)()),
    ?assertException(error, badarg,
                     erlang:send_after(opaque_neg(), self(), x)).

monotonic_test() ->
    %% 单调钟只增不减，但起点任意（可能是负数）——只用来算间隔
    M1 = erlang:monotonic_time(),
    timer:sleep(5),
    M2 = erlang:monotonic_time(),
    ?assert(M2 >= M1),
    Elapsed = erlang:convert_time_unit(M2 - M1, native, millisecond),
    ?assert(Elapsed >= 0),
    ?assert(erlang:system_time() > 0).

atom_table_grows_test() ->
    %% 原子表只涨不回收：造过才有，没造过的 list_to_existing_atom 拒绝
    %%（差值可能比造的个数少 1——个别原子可能已存在，只断言"确实涨了"）
    C0 = erlang:system_info(atom_count),
    [_ = list_to_atom("probe_" ++ integer_to_list(N)) || N <- lists:seq(1, 50)],
    ?assert(erlang:system_info(atom_count) - C0 >= 49),
    ?assertEqual(probe_1, list_to_existing_atom("probe_1")),
    ?assertException(error, badarg,
                     list_to_existing_atom("never_created_atom_zzz")).

float_overflow_test() ->
    %% 浮点溢出是 badarith 不是 inf；触发值来自 opaque 绕开编译期常量传播
    ?assertException(error, badarith,
                     math:pow(10, float('20_time':opaque(400)))),
    ?assertException(error, badarith,
                     math:sqrt(0.0 - float('20_time':opaque(1)))).

%% 编译期算不出来的「不透明」负数
opaque_neg() -> -length(lists:seq(1, 1)).
