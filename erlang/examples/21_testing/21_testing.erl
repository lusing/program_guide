%% ============================================================
%% 21_testing —— 测试：EUnit 与 Common Test
%%
%%    OTP 自带两套测试框架：
%%      EUnit        单元测试主力：include 头文件、函数名 _test 结尾即可，
%%                   eunit:test(Mod) 收集执行（build.ps1 第 2 层验证靠它）
%%      Common Test  集成/系统测试：SUITE 模块 + 配置组 + 独立日志/HTML 报告
%%
%%    本示例演示：断言家族、生成器、fixture、表驱动、超时与并行、
%%    eunit:test 的编程调用，以及**在代码里实跑一个 Common Test suite**。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/21_testing examples/21_testing/*.erl
%% 运行：
%%   erl -noshell -pa build/21_testing -run '21_testing' main -s init stop
%% 测试（build.ps1 第 2 层就是这么跑的）：
%%   erl -noshell -pa build/21_testing -eval "eunit:test('21_testing_tests'), halt()."
%% ============================================================
-module('21_testing').

-include_lib("eunit/include/eunit.hrl").

-export([main/0, wrap/2, classify/1, fib/1, eunit_forms/0, run_ct/0]).

main() ->
    %% CT 内部出错会经默认 logger 打带时间戳的报告——照例先摘掉
    _ = logger:remove_handler(default),
    io:format("== 1) 被测的纯函数 ==~n"),
    pure_functions(),
    io:format("~n== 2) 断言家族 ==~n"),
    assertion_family(),
    io:format("~n== 3) 表驱动：一个函数测一批用例 ==~n"),
    table_driven_note(),
    io:format("~n== 4) eunit:test 的编程调用 ==~n"),
    eunit_forms(),
    io:format("~n== 5) Common Test：实跑一个 suite ==~n"),
    run_ct(),
    io:format("~n==== 21 结束 ====~n").

%% 1) 被测对象：可测逻辑一律抽成纯函数
%% ------------------------------------------------------------
%% wrap/2 按宽度折行（与 go 教程 15 章同一个练习题）：
%%   wrap("aaa bbb ccc", 7) -> ["aaa bbb", "ccc"]
%% 逻辑与 I/O 分离——测试不需要起进程、不需要 mock、不需要文件。
wrap(Text, Width) ->
    wrap(string:split(Text, " ", all), Width, [], 0).

wrap([], _Width, Cur, _CurLen) ->
    [join_words(lists:reverse(Cur))];
wrap([W | Rest], Width, Cur, CurLen) ->
    case Cur of
        [] ->
            wrap(Rest, Width, [W | Cur], length(W));
        _ ->
            case CurLen + 1 + length(W) =< Width of
                true ->
                    wrap(Rest, Width, [W | Cur], CurLen + 1 + length(W));
                false ->
                    [join_words(lists:reverse(Cur))
                     | wrap([W | Rest], Width, [], 0)]
            end
    end.

%% lists:join 只插分隔符（["a","b"] → ["a"," ","b"]，嵌套的），
%% 拼平面字符串要再 flatten（11 章讲过的坑，这里撞个正着）
join_words(Words) -> lists:flatten(lists:join(" ", Words)).

classify(N) when is_integer(N), N >= 0, N < 60 -> fail;
classify(N) when is_integer(N), N < 80 -> pass;
classify(N) when is_integer(N) -> excellent;
classify(_) -> {error, not_an_integer}.

fib(0) -> 0;
fib(1) -> 1;
fib(N) when is_integer(N), N > 1 -> fib(N - 1) + fib(N - 2);
fib(_) -> erlang:error(badarg).

pure_functions() ->
    d("wrap(\"aaa bbb ccc\", 7)", wrap("aaa bbb ccc", 7)),
    d("wrap(\"the quick brown fox\", 10)", wrap("the quick brown fox", 10)),
    d("classify(59)/classify(60)/classify(90)/classify(x)",
      [classify(V) || V <- [59, 60, 90, x]]),
    d("fib(10)", fib(10)),
    ok.

%% 2) 断言家族（全部在测试模块里实际使用，这里列语义）
%% ------------------------------------------------------------
%%   ?assert(Bool)                    任意布尔
%%   ?assertEqual(Expected, Actual)   相等（失败信息最友好，首选）
%%   ?assertNotEqual / ?assertNot
%%   ?assertMatch(Pattern, Actual)    模式匹配（Pattern 可带 guard）
%%   ?assertException(Class, Reason, Expr)   预期抛出
%%   ?assertError(Reason, Expr) / ?assertExit / ?assertThrow   三类简写
assertion_family() ->
    io:format("  ?assert(Bool) / ?assertEqual(Want, Got) / ?assertMatch(Pat, Got)~n"),
    io:format("  ?assertException(Class, Reason, Expr)；?assertError/?assertExit/?assertThrow~n"),
    io:format("  失败时 EUnit 打印 expected/value/expression 三元组，第 21 章示例全绿~n"),
    ok.

%% 3) 表驱动：惯用法是把用例收进列表一次性遍历
%% ------------------------------------------------------------
%% 见 21_testing_tests.erl 的 wrap_table_test/0：用例 {输入宽度, 输入文本, 期望}
%% 收进一个列表，foreach 断言。加用例只加一行。
table_driven_note() ->
    io:format("  用例表：[{Width, Text, Expected} || ...] 一次遍历（见测试模块）~n"),
    io:format("  加用例只加一行，不改逻辑——表驱动是 EUnit 的主力写法~n"),
    ok.

%% 4) eunit:test 的编程调用形态
%% ------------------------------------------------------------
%% eunit 支持的输入形态（实测可用）：
%%   eunit:test(Atom)                   按模块名收集 *_test/_test_
%%   eunit:test({module, Atom})         同上
%%   eunit:test({generator, Fun})       Fun 返回测试项（惰性生成）
%%   eunit:test([T1, T2])               测试项列表
%% 常用选项：no_output（安静）、verbose（每个测试一行）。
eunit_forms() ->
    d("eunit:test('21_testing_tests')（build.ps1 用的形态）",
      eunit:test('21_testing_tests', [no_output])),
    d("eunit:test({generator, ...})（生成器形态）",
      eunit:test({generator, fun sample_generator/0}, [no_output])),
    d("eunit:test(一个不存在的模块)", eunit:test(no_such_tests_module_xyz, [no_output])),
    ok.

%% 生成器：返回测试项列表。测试项可以是函数、{T,fun}、
%% {setup, Setup, Inst}、{timeout, N, Inst}、{inorder,[...]}、{inparallel,[...]}...
sample_generator() ->
    [fun () -> ?assertEqual(2, fib(3)) end,
     {"描述性的测试名", fun () -> ?assertEqual(pass, classify(70)) end}].

%% 5) Common Test：在代码里实跑一个 suite
%% ------------------------------------------------------------
%% ct21_SUITE.erl 与本文件同目录（build.ps1 一起编译）。
%% 返回 {Ok, Failed, {UserSkipped, AutoSkipped}}。
%% 日志写进 build/ct-21-logs/（跑前重建、跑后清掉）。
run_ct() ->
    LogDir = "build/ct-21-logs",
    RunDir = "build/ct-21-run",
    _ = file:del_dir_r(LogDir),
    _ = file:del_dir_r(RunDir),
    ok = filelib:ensure_dir(filename:join(LogDir, "x")),
    ok = filelib:ensure_dir(filename:join(RunDir, "x")),
    %% CT 的默认流程是在「测试目录」里找 *_SUITE.erl 自己编译（make）。
    %% 把 suite 源码拷进沙箱目录再指给它——和 ct_run 的真实用法同构，
    %% 编译产物与日志都留在 build/ 下，不污染源码目录。
    {ok, Src} = file:read_file("examples/21_testing/ct21_SUITE.erl"),
    ok = file:write_file(filename:join(RunDir, "ct21_SUITE.erl"), Src),
    %% CT 会往 stdout 打带时间戳的运行目录名——换掉本进程的 group leader，
    %% 让这些输出进「黑洞」，只留返回值（group_leader 重定向是通用静音技巧）
    RealGL = group_leader(),
    BlackHole = spawn(fun blackhole_gl/0),
    group_leader(BlackHole, self()),
    R = ct:run_test([{dir, RunDir}, {logdir, LogDir}]),
    group_leader(RealGL, self()),
    d("ct:run_test 的返回 {Ok, Failed, {UserSkipped, AutoSkipped}}", R),
    _ = file:del_dir_r(LogDir),
    _ = file:del_dir_r(RunDir),
    %% 命令行形态（docs 里有完整命令）：
    io:format("  命令行等价：ct_run -dir build/ct-21-run -logdir build/ct-21-logs~n"),
    ok.

%% 最小 io 协议实现：写请求应答 ok（丢弃内容），读请求应答 eof
blackhole_gl() ->
    receive
        {io_request, From, ReplyAs, Req} ->
            From ! {io_reply, ReplyAs, io_reply_for(Req)},
            blackhole_gl();
        _Other ->
            blackhole_gl()
    end.

io_reply_for(Req) when element(1, Req) =:= get_chars;
                       element(1, Req) =:= get_line;
                       element(1, Req) =:= get_until ->
    eof;    %% 读请求：一律当「读到末尾」
io_reply_for(getopts) -> {error, enotsup};
io_reply_for(_Other) -> ok.   %% 其余（含不认识的写请求）一律应答 ok

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
