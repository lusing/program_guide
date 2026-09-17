%% ============================================================
%% 04_patterns 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/04_patterns examples/04_patterns/*_tests.erl
%%   erl -noshell -pa build/04_patterns -eval "eunit:test('04_patterns_tests'), halt()."
%% ============================================================
-module('04_patterns_tests').

-include_lib("eunit/include/eunit.hrl").

area_test() ->
    ?assertEqual(12, '04_patterns':area({rect, 3, 4})),
    ?assertEqual({error, {unknown_shape, {rect, 0, 4}}},
                 '04_patterns':area({rect, 0, 4})),   %% guard 不通过落兜底
    ?assert('04_patterns':area({circle, 2}) > 12.5).

head_tail_test() ->
    ?assertEqual(empty, '04_patterns':head_tail([])),
    ?assertEqual({single, 7}, '04_patterns':head_tail([7])),
    ?assertEqual({two_plus, 1, 2, [3, 4]}, '04_patterns':head_tail([1, 2, 3, 4])).

same_or_diff_test() ->
    %% {X, X} 模式要求两个位置相等
    ?assertEqual([same, different, same, different],
                 ['04_patterns':same_or_diff(T) || T <- [{1, 1}, {1, 2}, {a, a}, {a, b}]]).

parse_frame_test() ->
    ?assertEqual({ok, 1, 3, <<"abc">>, <<9, 9>>},
                 '04_patterns':parse_frame(<<1:8, 3:16, "abc", 9:8, 9:8>>)),
    ?assertEqual({incomplete, 1, 3, 2},
                 '04_patterns':parse_frame(<<1:8, 3:16, "ab">>)),
    ?assertEqual({error, {too_short, 1}},
                 '04_patterns':parse_frame(<<1>>)).

kind_test() ->
    ?assertEqual([non_negative_int, negative_int, zero_or_float, atom, other],
                 ['04_patterns':kind(V) || V <- [5, -5, 3.5, hello, {1}]]).

clamp_test() ->
    ?assertEqual(5, '04_patterns':clamp(5, 1, 10)),
    ?assertEqual(1, '04_patterns':clamp(0, 1, 10)),
    ?assertEqual(10, '04_patterns':clamp(99, 1, 10)),
    %% Lo>Hi（参数本身不合法）：第 2 子句 5 < 10 先命中，返回 Lo
    ?assertEqual(10, '04_patterns':clamp(5, 10, 1)).

guard_silent_failure_test() ->
    %% guard 里 hd([]) 静默不匹配；函数体里 hd([]) 抛 badarg
    ?assertEqual(not_int_list, '04_patterns':first_or_empty(not_a_list)),
    ?assertEqual({error, badarg},
                 '04_patterns':raises(fun(L) -> hd(L) end, [])).

case_clause_test() ->
    %% case_clause 的 reason 带着没匹配上的那个值
    ?assertEqual({error, {case_clause, something_else}},
                 '04_patterns':raises(fun(X) -> case X of only_this -> ok end end,
                                      something_else)),
    ?assertEqual({error, if_clause},
                 '04_patterns':raises(fun(X) -> if X > 10 -> big end end, 1)).

sign_test() ->
    ?assertEqual([positive, negative, zero],
                 ['04_patterns':sign(N) || N <- [5, -5, 0]]).
