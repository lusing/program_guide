%% ============================================================
%% 03_types 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/03_types examples/03_types/*_tests.erl
%%   erl -noshell -pa build/03_types -eval "eunit:test('03_types_tests'), halt()."
%% ============================================================
-module('03_types_tests').

-include_lib("eunit/include/eunit.hrl").

fact_test() ->
    ?assertEqual(1, '03_types':fact(0)),
    ?assertEqual(720, '03_types':fact(6)),
    ?assertEqual(2432902008176640000, '03_types':fact(20)),
    ?assertException(error, badarg, '03_types':fact(-1)),
    ?assertException(error, badarg, '03_types':fact(1.5)).

div_rem_test() ->
    %% 向零截断 + 余数符号跟随被除数（03 章 4 节的恒等式）
    ?assertEqual(-3, -7 div 2),
    ?assertEqual(-1, -7 rem 2),
    ?assert(-7 =:= (-7 div 2) * 2 + (-7 rem 2)).

float_overflow_test() ->
    %% 溢出是 badarith，不是 inf（对 C/Java 的最大差异）
    ?assertEqual({error, badarith},
                 '03_types':raises(fun(X) -> X * 10 end, 1.0e308)),
    ?assertEqual({error, badarith},
                 '03_types':raises(fun(X) -> X / X end, 0.0)).

raising_capture_test() ->
    %% raises/2 把 Class 与 Reason 都带回来
    ?assertEqual({error, badarith},
                 '03_types':raises(fun(D) -> 1 div D end, 0)).

rounding_test() ->
    ?assertEqual(3, round(2.5)),      %% .5 远离零
    ?assertEqual(-3, round(-2.5)),
    ?assertEqual(-3, floor(-2.5)),
    ?assertEqual(-2, trunc(-2.5)).

term_order_test() ->
    %% 全序：number < atom < tuple < list（完整次序见 docs 03.7）
    ?assert(1 < a),
    ?assert({1, 2} < [1]),
    ?assertEqual([1, 3.0, a, b, "x"], lists:sort([b, 1, a, "x", 3.0])).

safe_atom_test() ->
    %% hello 在本模块加载前就存在，所以能命中；造新原子被拦
    ?assertEqual({ok, hello}, '03_types':safe_atom("hello")),
    ?assertEqual({error, not_existing},
                 '03_types':safe_atom("definitely_not_an_atom_xyz")).
