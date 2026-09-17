%% ============================================================
%% 12_errors 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/12_errors examples/12_errors/*_tests.erl
%%   erl -noshell -pa build/12_errors -eval "eunit:test('12_errors_tests'), halt()."
%% ============================================================
-module('12_errors_tests').

-include_lib("eunit/include/eunit.hrl").

%% 触发值要绕开编译期常量传播（-Wall 会在编译期点死常量错误）
zero() -> length(lists:seq(1, 0)).

three_classes_test() ->
    ?assertMatch({error, error, badarith},
                 '12_errors':to_error(fun() -> 1 / zero() end)).

parse_soft_test() ->
    ?assertEqual({ok, 12}, '12_errors':parse_soft("12")),
    ?assertEqual({error, {not_a_number, "abc"}}, '12_errors':parse_soft("abc")).

classify_test() ->
    C = fun '12_errors':classify/1,
    ?assertEqual({non_negative, 5}, C(5)),
    ?assertEqual({non_negative, 7}, C(<<"7">>)),
    ?assertEqual({error, negative}, C(-5)),
    ?assertEqual({error, not_a_number}, C("abc")).

plain_match_penetrates_test() ->
    %% body 里写普通 = 的 badmatch 穿透 else（12 章 4 节）
    ?assertMatch({error, error, {badmatch, false}},
                 '12_errors':to_error(
                   fun() -> '12_errors':classify_plain_match(-5) end)).

down_reason_test() ->
    %% 崩溃会被默认 logger handler 上报到 stderr——先摘掉（与示例 main 同一纪律）
    _ = logger:remove_handler(default),
    %% error 类的 DOWN 带栈；exit 类原样；throw 类 {nocatch, V}
    ?assertMatch({down, {error, boom, stack_non_empty, true}},
                 '12_errors':observe(error_class)),
    ?assertMatch({down, {other_class, reason_x}},
                 '12_errors':observe(exit_class)),
    %% 未捕获 throw 的 DOWN 是 {{nocatch,V}, Stack}——也带栈
    ?assertMatch({down, {error, {nocatch, tossed}, stack_non_empty, true}},
                 '12_errors':observe(throw_class)).

raises_test() ->
    ?assertEqual({error, badarg},
                 '12_errors':raises(fun(S) -> list_to_integer(S) end, "x")).

norm_test() ->
    %% 归一化替换掉不可重复打印的东西
    ?assertEqual(['<fun>'], '12_errors':norm([fun() -> ok end])).
