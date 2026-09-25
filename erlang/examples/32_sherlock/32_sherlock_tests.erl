%% ============================================================
%% 32_sherlock 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/32_sherlock examples/32_sherlock/*_tests.erl
%%   erl -noshell -pa build/32_sherlock -eval "eunit:test('32_sherlock_tests'), halt()."
%% ============================================================
-module('32_sherlock_tests').

-include_lib("eunit/include/eunit.hrl").

tokens_test() ->
    ?assertEqual(["indeed", "the", "morning"],
                 '32_sherlock':tokens("Indeed, the Morning!")),
    ?assertEqual(["a", "b"],
                 '32_sherlock':tokens("a--b!!!")).

counts_and_top_test() ->
    Counts = '32_sherlock':counts(["w", "w", "x"]),
    ?assertEqual(#{"w" => 2, "x" => 1}, Counts),
    %% 同频按字典序：确定性
    ?assertEqual([{"w", 2}, {"x", 1}], '32_sherlock':top_n(Counts, 5)).

similarity_properties_test() ->
    A = '32_sherlock':tokens("a b c d"),
    B = '32_sherlock':tokens("c d e f"),
    %% 交集 {c,d}=2，并集 {a,b,c,d,e,f}=6
    ?assertEqual({2, 6}, '32_sherlock':similarity(A, B)),
    ?assertEqual(1.0, '32_sherlock':ratio('32_sherlock':similarity(A, A))),
    ?assertEqual('32_sherlock':ratio('32_sherlock':similarity(A, B)),
                 '32_sherlock':ratio('32_sherlock':similarity(B, A))).

the_case_test() ->
    Anon = '32_sherlock':tokens('32_sherlock':anonymous()),
    A = '32_sherlock':tokens('32_sherlock':author_a1())
        ++ '32_sherlock':tokens('32_sherlock':author_a2()),
    B = '32_sherlock':tokens('32_sherlock':author_b1())
        ++ '32_sherlock':tokens('32_sherlock':author_b2()),
    RA = '32_sherlock':ratio('32_sherlock':similarity(Anon, A)),
    RB = '32_sherlock':ratio('32_sherlock':similarity(Anon, B)),
    ?assert(RA > RB).       %% 匿名段文风属于作者甲

predict_next_test() ->
    Tokens = ["the", "cat", "sat", "the", "cat", "ran"],
    ?assertEqual("cat", '32_sherlock':predict_next(Tokens, "the")),
    ?assertEqual(none, '32_sherlock':predict_next(Tokens, "dog")),

    %% 并列取字典序最小（确定性）
    Tie = ["p", "a", "p", "b"],
    ?assertEqual("a", '32_sherlock':predict_next(Tie, "p")).
