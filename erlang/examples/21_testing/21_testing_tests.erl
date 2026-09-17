%% ============================================================
%% 21_testing 的 EUnit 测试（build.ps1 第 2 层验证对象）
%%
%%   erlc -Werror -Wall -o build/21_testing examples/21_testing/*_tests.erl
%%   erl -noshell -pa build/21_testing -eval "eunit:test('21_testing_tests'), halt()."
%%
%% 本模块同时是「写法示范」：断言家族、表驱动、生成器、fixture、超时。
%% ============================================================
-module('21_testing_tests').

-include_lib("eunit/include/eunit.hrl").

%% ---------- 纯函数断言 ----------

wrap_test() ->
    ?assertEqual(["aaa"], '21_testing':wrap("aaa", 7)).

%% 表驱动：一个函数测一批用例，加用例只加一行
wrap_table_test_() ->
    Cases = [{7,  "aaa bbb ccc",       ["aaa bbb", "ccc"]},
             {10, "the quick brown fox", ["the quick", "brown fox"]},
             {3,  "aaaa b",            ["aaaa", "b"]},       %% 单词超宽也不硬拆
             {99, "one two",           ["one two"]}],
    [fun () ->
         ?assertEqual(Expected, '21_testing':wrap(Text, Width))
     end || {Width, Text, Expected} <- Cases].

classify_test() ->
    ?assertEqual(fail, '21_testing':classify(0)),
    ?assertEqual(fail, '21_testing':classify(59)),
    ?assertEqual(pass, '21_testing':classify(60)),
    ?assertEqual(excellent, '21_testing':classify(90)),
    ?assertEqual({error, not_an_integer}, '21_testing':classify(x)).

fib_test() ->
    [?assertEqual(Want, '21_testing':fib(N)) || {N, Want} <- [{0, 0}, {1, 1}, {10, 55}]],
    ?assertError(badarg, '21_testing':fib(minus_one())).

%% 编译期算不出来的负数（-Werror 会点死常量版）
minus_one() -> 0 - length([x]).

%% ---------- 断言家族示范 ----------

assert_family_test() ->
    ?assert(1 < 2),
    ?assertNot(1 > 2),
    ?assertEqual(2, 1 + one()),
    ?assertNotEqual(one(), zero()),                     %% 不等的值（opaque 绕开常量折叠）
    ?assertMatch({ok, V} when V > 0, {ok, one()}),      %% 模式可带 guard
    ?assertException(error, badarg, list_to_integer(bad_int())),
    ?assertError(badarith, one() / zero()),             %% error 类简写
    ok.

one() -> length([x]).
zero() -> length([]).
bad_int() -> "not-an-int" ++ [].

%% ---------- 生成器与 fixture ----------

%% _test_ 后缀 = 生成器：返回测试项列表（惰性）。EUnit 收集导出的 *_test_/0。
generator_shape_test_() ->
    [fun () -> ?assertEqual(1, one()) end,
     {"带名字的测试项", fun () -> ?assertEqual(0, zero()) end}].

%% setup fixture：{Setup, Cleanup, Instantiator}
%% Instantiator 接收 Setup 的返回值，必须**返回测试项**（不能直接执行断言）
setup_fixture_test_() ->
    {setup,
     fun () -> _ = file:del_dir_r("build/eunit-21-fixture"),   %% 幂等：先清旧的
               ok = file:make_dir("build/eunit-21-fixture"),
               "build/eunit-21-fixture" end,
     fun (Dir) -> ok = file:del_dir_r(Dir) end,   %% del_dir 只删空目录，用 _r
     fun (Dir) ->
         [fun () ->
              File = filename:join(Dir, "x.txt"),
              ok = file:write_file(File, <<"data">>),
              ?assertEqual({ok, <<"data">>}, file:read_file(File))
          end]
     end}.

%% foreach：每个用例一套 Setup/Cleanup（对照 setup 的「整组一套」）。
%% 用例元素是 fun(SetupResult) -> 测试项；?_assert* 宏直接产出惰性测试。
foreach_fixture_test_() ->
    {foreach,
     fun () -> ok = file:make_dir("build/eunit-21-fe"), fe_done end,
     fun (_) -> ok = file:del_dir("build/eunit-21-fe") end,
     [fun (fe_done) -> ?_assert(filelib:is_dir("build/eunit-21-fe")) end,
      fun (fe_done) -> ?_assertEqual(fe_done, fe_done) end]}.

%% 超时包裹：单测试默认 5 秒，慢测试显式给
timeout_shape_test_() ->
    {timeout, 10,
     fun () -> timer:sleep(one()), ?assert(true) end}.

%% 顺序与并行：默认按声明序；inparallel 并行跑（互不依赖才用）
order_shape_test_() ->
    {inorder,
     [fun () -> put(step, 1), ?assertEqual(1, get(step)) end,
      fun () -> ?assertEqual(1, get(step)), put(step, 2) end,
      fun () -> ?assertEqual(2, get(step)), erase(step) end]}.
