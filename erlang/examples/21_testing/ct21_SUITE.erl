%% ============================================================
%% ct21_SUITE —— Common Test 最小 suite（21 章演示用）
%%
%%   结构约定：
%%     all/0                 必须导出：列出要跑的测试用例（原子）
%%     init_per_suite/1      可选：整组的前置（返回 Config 给用例）
%%     end_per_suite/1       可选：整组的后置
%%     xxx/1                 测试用例：参数是 Config（proplist）
%%
%%   命令行跑法：
%%     ct_run -pa build/21_testing -suite ct21_SUITE -logdir build/ct-21-logs
%%   或 erl 里编程调用（见 21_testing.erl 的 run_ct/0）。
%% ============================================================
-module(ct21_SUITE).

-export([all/0, init_per_suite/1, end_per_suite/1,
         smoke_case/1, fixture_case/1, failing_shape_case/1]).

all() -> [smoke_case, fixture_case, failing_shape_case].

init_per_suite(Config) ->
    %% 前置：建一个临时目录挂进 Config，用例按 key 取
    Dir = "build/ct-21-sandbox",
    ok = filelib:ensure_dir(filename:join(Dir, "x")),
    [{sandbox, Dir} | Config].

end_per_suite(_Config) ->
    _ = file:del_dir_r("build/ct-21-sandbox"),
    ok.

smoke_case(_Config) ->
    %% 用例里用 ct:pal/2 打日志（进 CT 的 HTML 报告，不污染 stdout）
    ct:pal("smoke case running"),
    ok.

fixture_case(Config) ->
    Dir = proplists:get_value(sandbox, Config),
    File = filename:join(Dir, "data.txt"),
    ok = file:write_file(File, <<"ct">>),
    %% CT 内置断言与 EUnit 同一套（ct.hrl 里也是 ?assert 宏家族）
    {ok, <<"ct">>} = file:read_file(File),
    ok.

failing_shape_case(_Config) ->
    %% 演示「预期失败」的形状：失败用例让整组返回非 ok。
    %% 这里故意展示对 badarg 的验证（值来自 opaque，绕开编译期常量折叠）。
    opaque_one() =/= 2 orelse ct:fail("unexpected: opaque_one/0 changed").
opaque_one() -> length([x]).

%% 注意：suite 里写 ok = 1 + 1 这种常量断言会被 -Werror 在**编译期**点死
%%（no clause will ever match）——和示例代码里演示运行期错误是同一条纪律。
