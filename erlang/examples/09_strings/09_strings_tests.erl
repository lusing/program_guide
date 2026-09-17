%% ============================================================
%% 09_strings 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/09_strings examples/09_strings/*_tests.erl
%%   erl -noshell -pa build/09_strings -eval "eunit:test('09_strings_tests'), halt()."
%% ============================================================
-module('09_strings_tests').

-include_lib("eunit/include/eunit.hrl").

string_is_list_test() ->
    ?assert("abc" =:= [97, 98, 99]),
    ?assert(is_list("abc")),
    ?assertEqual(3, length("abc")),
    ?assertEqual("abcd", "ab" ++ "cd"),
    %% 列表字符串与二进制字符串是两个东西
    ?assert("abc" =/= <<"abc">>).

latin1_trap_test() ->
    %% <<"中">> 被截成单字节 20013 rem 256 = 45；/utf8 才是三字节
    ?assertEqual(45, $中 rem 256),
    ?assertEqual(1, byte_size(<<"中">>)),
    ?assertEqual(3, byte_size(<<"中"/utf8>>)),
    ?assertEqual(<<"abc">>, <<"abc"/utf8>>).   %% 纯 ASCII 两者等价

list_to_binary_test() ->
    %% 码点 > 255 的列表直接 list_to_binary 抛 badarg
    ?assertEqual({error, badarg},
                 '09_strings':raises(fun(L) -> list_to_binary(L) end, [$中])),
    ?assertEqual(<<"中"/utf8>>, unicode:characters_to_binary([$中])).

three_lengths_test() ->
    ?assertEqual(2, length("中文")),                 %% 码点
    ?assertEqual(6, byte_size(<<"中文"/utf8>>)),     %% 字节
    ?assertEqual(2, string:length(<<"中文"/utf8>>)), %% 字素簇
    %% e + 组合重音符：两个码点、一个字素簇
    ?assertEqual(2, length([$e, 16#0301])),
    ?assertEqual(1, string:length([$e, 16#0301])).

string_module_test() ->
    ?assertEqual(["a", "b", "c"], string:split("a,b,c", ",", all)),
    ?assertEqual("x", string:trim("  x  ")),
    %% pad 返回嵌套列表（iodata），flatten 后才是 "007"
    ?assertEqual("007", lists:flatten(string:pad("7", 3, leading, $0))),
    ?assertEqual(["a", "b"], string:lexemes("a,,b", ",")),
    ?assertEqual({42, "x"}, string:to_integer("42x")),
    ?assertEqual({error, no_integer}, string:to_integer("x")).

iolist_test() ->
    Deep = ["a", [$b, $c], <<"def">>, [[<<"g">>]]],
    ?assertEqual(<<"abcdefg">>, iolist_to_binary(Deep)),
    ?assertEqual(7, iolist_size(Deep)).
