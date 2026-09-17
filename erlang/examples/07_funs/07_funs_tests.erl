%% ============================================================
%% 07_funs 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/07_funs examples/07_funs/*_tests.erl
%%   erl -noshell -pa build/07_funs -eval "eunit:test('07_funs_tests'), halt()."
%% ============================================================
-module('07_funs_tests').

-include_lib("eunit/include/eunit.hrl").

adder_compose_test() ->
    ?assertEqual(12, '07_funs':adder(2)(10)),
    ?assertEqual(13, '07_funs':adder(3)(10)),
    %% compose 先 F 再 G：Double→Inc 是 3*2+1=7，反过来是 (3+1)*2=8
    ?assertEqual(7, '07_funs':compose(fun(X) -> X * 2 end, fun(X) -> X + 1 end)(3)),
    ?assertEqual(8, '07_funs':compose(fun(X) -> X + 1 end, fun(X) -> X * 2 end)(3)),
    %% pipeline 依序施加：((5*2)+1)^2 = 121
    ?assertEqual(121, '07_funs':pipeline([fun(X) -> X * 2 end,
                                          fun(X) -> X + 1 end,
                                          fun(X) -> X * X end])(5)).

fold_implementations_test() ->
    ?assertEqual([2, 3, 4], '07_funs':fold_map(fun(X) -> X + 1 end, [1, 2, 3])),
    ?assertEqual([2, 4], '07_funs':fold_filter(fun(X) -> X rem 2 =:= 0 end, [1, 2, 3, 4])),
    ?assertEqual(10, '07_funs':fold_sum([1, 2, 3, 4])),
    ?assertEqual('07_funs':fold_map(fun(X) -> X * 3 end, lists:seq(1, 30)),
                 lists:map(fun(X) -> X * 3 end, lists:seq(1, 30))).

sort_by_test() ->
    People = [{bob, 30}, {alice, 25}, {carol, 35}],
    ?assertEqual([{alice, 25}, {bob, 30}, {carol, 35}],
                 '07_funs':sort_by(fun({_, A}) -> A end, People)),
    ?assertEqual([{alice, 25}, {bob, 30}, {carol, 35}],
                 '07_funs':sort_by(fun({N, _}) -> N end, People)).

short_circuit_test() ->
    %% touched 元素抛 probe_touched；any/all 短路所以碰不到它
    ?assert(lists:any(fun '07_funs':any_probe/1, [nope, hit, touched])),
    ?assertNot(lists:all(fun '07_funs':any_probe/1, [hit, nope, touched])),
    ?assertMatch({error, error, probe_touched},
                 '07_funs':to_error(
                   fun() -> lists:map(fun '07_funs':any_probe/1, [touched]) end)).

comprehension_silent_skip_test() ->
    %% 生成器模式不匹配被静默跳过（07 章 8 节的坑）
    ?assertEqual([1, 2, 3], [X || {X} <- [{1}, {2}, not_tuple, {3}]]).

binary_comprehension_test() ->
    ?assertEqual(<<1, 2, 3, 4, 5, 6>>,
                 <<<<X>> || <<X>> <= <<1, 2, 3, 4, 5, 6>>>>),
    ?assertEqual(<<4, 8, 12>>,
                 <<<<(X * 2)>> || <<X>> <= <<1, 2, 3, 4, 5, 6>>, X rem 2 =:= 0>>),
    ?assertEqual(<<0, 1, 0, 2, 0, 3>>,
                 <<<<Y:16/little>> || <<Y:16/big>> <= <<1, 0, 2, 0, 3, 0>>>>).

quicksort_wordfreq_test() ->
    ?assertEqual([1, 2, 3, 6, 8], '07_funs':quicksort([3, 6, 1, 8, 2])),
    ?assertEqual([1 | [2 | [3 | []]]], '07_funs':flatten_deep([1, [2, [3]], []])),
    ?assertEqual([{"a", 2}, {"b", 1}],
                 '07_funs':word_freq(["a", "b", "a"])).

lazy_test() ->
    ?assertEqual([1, 2, 3, 4, 5], '07_funs':take(5, '07_funs':count_from(1))),
    ?assertEqual([2, 4, 6, 8, 10], '07_funs':take(5, '07_funs':evens_from(2))).
