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

string_replace_test() ->
    %% 默认 leading：只换第一处，返回 iodata
    ?assertEqual(["a", "+", "b-c"], string:replace("a-b-c", "-", "+")),
    ?assertEqual(["a", "+", "b", "+", "c"], string:replace("a-b-c", "-", "+", all)),
    ?assertEqual(["a-b", "+", "c"], string:replace("a-b-c", "-", "+", trailing)),
    %% iodata 转平面二进制
    ?assertEqual(<<"a+b+c">>,
                 unicode:characters_to_binary(string:replace("a-b-c", "-", "+", all))).

uri_string_test() ->
    %% parse 的 map 只含出现过的部件，port 是整数
    ?assertEqual(#{scheme => "https", userinfo => "user", host => "example.com",
                   port => 8443, path => "/a/b", query => "x=1", fragment => "frag"},
                 uri_string:parse("https://user@example.com:8443/a/b?x=1#frag")),
    ?assertEqual(#{scheme => "https", host => "example.com", path => "/"},
                 uri_string:parse("https://example.com/")),
    %% 没有 port 键时用 maps:get/3 兜底
    ?assertEqual(443, maps:get(port, uri_string:parse("https://example.com/"), 443)),
    %% 非法输入返回三元组，不抛异常
    ?assertEqual({error, invalid_uri, ":"}, uri_string:parse("http://h/p?a=b c")),
    ?assertEqual("https://example.com/a",
                 uri_string:recompose(#{scheme => "https", host => "example.com",
                                        path => "/a"})),
    ?assertEqual("http://example.com/~user",
                 uri_string:normalize("HTTP://Example.COM:80/%7euser")),
    ?assertEqual("a%20b", uri_string:quote("a b")),
    ?assertEqual("a b", uri_string:unquote("a%20b")).
