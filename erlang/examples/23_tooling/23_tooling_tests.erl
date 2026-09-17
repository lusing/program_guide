%% ============================================================
%% 23_tooling 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/23_tooling examples/23_tooling/*_tests.erl
%%   erl -noshell -pa build/23_tooling -eval "eunit:test('23_tooling_tests'), halt()."
%% ============================================================
-module('23_tooling_tests').

-include_lib("eunit/include/eunit.hrl").

combine_test() ->
    ?assertEqual("a b", '23_tooling':combine("a", "b")),
    ?assertEqual("中文 ok", '23_tooling':combine("中文", "ok")).

tagged_test() ->
    ?assertEqual({3, 3}, '23_tooling':tagged(3)),
    ?assertEqual({3.7, 3}, '23_tooling':tagged(3.7)),
    ?assertException(error, function_clause, '23_tooling':tagged(atom)).

gen_server_api_test() ->
    _ = logger:remove_handler(default),
    _ = process_flag(trap_exit, true),
    ok = '23_tooling':store_start(),          %% 幂等：已在跑也返回 ok
    ?assert(is_pid(whereis('23_tooling'))),
    ok = '23_tooling':set(k1, 1),
    ok = '23_tooling':set(k2, 2),
    ?assertEqual(2, '23_tooling':count()),
    %% 未知请求被 handle_call 兜底子句接住
    ?assertEqual({error, unknown_request},
                 gen_server:call('23_tooling', weird_request)),
    %% sys 通道：get_state / replace_state 不停机生效
    %%（replace_state 直接返回改完的新状态，不是 {ok, State}）
    ?assertMatch(#{data := #{k1 := 1}, puts := 2},
                 sys:get_state('23_tooling')),
    _NewState = sys:replace_state('23_tooling', fun(S) -> S#{puts := 99} end),
    ?assertMatch(#{puts := 99}, sys:get_state('23_tooling')),
    ok = '23_tooling':store_stop().

proc_lib_start_sync_test() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    %% start_link 返回时 init_ack 已发生——进程一定活着且身份信息已写入
    {ok, P} = '23_tooling':start(),
    ?assert(is_process_alive(P)),
    Dict = element(2, process_info(P, dictionary)),
    %% $initial_call 是 {模块, 函数, 参数个数} 三元组
    ?assertMatch({_, _, _}, proplists:get_value('$initial_call', Dict)),
    ?assert(is_list(proplists:get_value('$ancestors', Dict))),
    exit(P, shutdown),
    %% init_fail：初始化失败让调用方拿到错误而不是卡住
    ?assertEqual({error, simulated_failure}, '23_tooling':start_failing()),
    _ = process_flag(trap_exit, Old).

hot_code_versions_test() ->
    %% 同一进程内装载两个版本、验证全限定调用拿新版（对照示例第 3 节）
    %% receive 用 guard 只认数字回复（邮箱里可能有别的测试残留的 EXIT）
    {module, hot_t} = load_hot(1),
    P = spawn(hot_t, loop, []),
    P ! {self(), q},          %% 模式是字面量 {P, q}——消息形状要完全一致
    ?assertEqual(1, receive V1 when is_integer(V1) -> V1
                           after 2000 -> timeout end),
    {module, hot_t} = load_hot(2),
    %% 已在跑的进程重新全限定调用 → 新版本；新 spawn 的进程也是新版本
    P ! {self(), q},
    ?assertEqual(2, receive V2 when is_integer(V2) -> V2
                           after 2000 -> timeout end),
    exit(P, kill),
    true = code:soft_purge(hot_t),
    false = erlang:check_old_code(hot_t).

load_hot(N) ->
    Src = ["-module(hot_t).\n"
           "-export([loop/0, ver/0]).\n"
           "loop() -> receive {P, q} -> P ! ?MODULE:ver(), loop() end.\n"
           "ver() -> ", integer_to_list(N), ".\n"],
    ok = file:write_file("build/hot_t.erl", Src),
    {ok, hot_t, Bin} = compile:file("build/hot_t.erl", [binary, return_errors]),
    code:load_binary(hot_t, "hot_t.erl", Bin).

spec_in_beam_test() ->
    %% -spec 存在 beam 的抽象代码里
    {ok, Beam} = file:read_file(code:which('23_tooling')),
    {ok, {_, [{abstract_code, {raw_abstract_v1, Forms}}]}} =
        beam_lib:chunks(Beam, [abstract_code]),
    Specs = [F || {attribute, _, spec, _} = F <- Forms],
    ?assert(length(Specs) >= 2),
    Names = [begin {attribute, _, spec, {{N, _A}, _}} = S, N end || S <- Specs],
    ?assert(lists:member(combine, Names)),
    ?assert(lists:member(tagged, Names)).
