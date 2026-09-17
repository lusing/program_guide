%% ============================================================
%% 02_hello 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/02_hello examples/02_hello/*_tests.erl
%%   erl -noshell -pa build/02_hello -eval "eunit:test('02_hello_tests'), halt()."
%%
%% 约定：include eunit.hrl 后，名字以 _test / _test_ 结尾的函数会被
%% **自动导出并收集**（OTP 24+；再手写 -export 反而报 already exported
%% 警告，被 -Werror 拦下）。断言两种写法：?assertEqual 宏（失败信息
%% 更友好）与模式匹配 `=`（badmatch 也算失败）。系统讲解见第 21 章。
%% ============================================================
-module('02_hello_tests').

-include_lib("eunit/include/eunit.hrl").

%% ~p / ~w / ~ts / ~b 的语义对照（对应示例 == 2) 一节）
render_directives_test() ->
    ?assertEqual("\"abc\"", '02_hello':render("~p", "abc")),
    ?assertEqual("[97,98,99]", '02_hello':render("~w", "abc")),
    ?assertEqual("中文",  '02_hello':render("~ts", <<"中文"/utf8>>)),
    ?assertEqual("255",   '02_hello':render("~b", 255)),
    ?assertEqual("ff",    '02_hello':render("~.16b", 255)),
    ?assertEqual("'has space'", '02_hello':render("~p", 'has space')).

%% 宽度、对齐与零填充（对应示例 == 3) 一节）
render_width_test() ->
    ?assertEqual("      ab", '02_hello':render("~8s", "ab")),
    ?assertEqual("ab      ", '02_hello':render("~-8s", "ab")),
    ?assertEqual("09-16-2026",
                 lists:flatten(io_lib:format("~2..0B-~2..0B-~4..0B", [9, 16, 2026]))).

%% greet/1 两个子句都正常跑完并返回 ok
greet_test() ->
    ok = '02_hello':greet("世界"),
    ok = '02_hello':greet(42),
    ok.

%% 模块信息（对应示例 == 4) 一节）
module_info_test() ->
    ?assertEqual('02_hello', '02_hello':module_info(module)),
    ?assert(erlang:function_exported('02_hello', greet, 1)),
    ?assertNot(erlang:function_exported('02_hello', nope, 0)),
    Exports = lists:sort('02_hello':module_info(exports)),
    ?assert(lists:member({main, 0}, Exports)).
