# 21 · 测试：EUnit 与 Common Test

> 对应示例：`examples/21_testing/`（含 `ct21_SUITE.erl`——示例里**实跑**的 Common Test suite）

## 21.1 测试是 OTP 自带的

```erlang
-module(my_tests).
-include_lib("eunit/include/eunit.hrl").   %% *_test 函数被自动导出并收集

reverse_test() -> ?assertEqual([3,2,1], lists:reverse([1,2,3])).
```

```powershell
erl -noshell -pa build/NN -eval "eunit:test('NN_tests'), halt()."
```

不用装框架、不用配置——本教程**每个示例都带测试**（build.ps1 第 2 层验证）。

## 21.2 断言家族

| 宏 | 用途 |
|---|---|
| `?assert(Bool)` / `?assertNot` | 任意布尔 |
| `?assertEqual(Want, Got)` | 相等——失败信息最友好，**首选** |
| `?assertMatch(Pat, Got)` | 模式匹配，Pattern 可带 guard |
| `?assertException(Class, Reason, Expr)` | 预期抛出；`?assertError/?assertExit/?assertThrow` 是三类简写 |
| `?_assertXxx`（宏名带下划线） | 生成**惰性测试项**——fixture 的 instantiator 里用 |

> `-Werror` 会在**编译期点死常量断言**：`?assertEqual(2, 1+1)`、`ok = 1 + 1` 直接 `no clause will ever match`——断言的值要来自 opaque 函数（`length([x])`），这也是 02 章纪律的延伸。

## 21.3 表驱动：EUnit 主力写法

```erlang
wrap_table_test_() ->
    Cases = [{7, "aaa bbb ccc", ["aaa bbb", "ccc"]}, ...],
    [fun () -> ?assertEqual(Exp, '21_testing':wrap(Text, W)) end
     || {W, Text, Exp} <- Cases].
```

加用例只加一行。被测逻辑抽成**纯函数**（`wrap/2`）——不可变 + 无副作用让 Erlang 测试天然不需要 mock。

## 21.4 生成器与 fixture

```erlang
gen_test_() -> [fun() -> ... end, {"名字", fun() -> ... end}].   %% _test_ 后缀 = 生成器

{setup, Setup, Cleanup, fun(Ctx) -> [测试项] end}.   %% 整组一套前后置
{foreach, Setup, Cleanup, [fun(Ctx) -> ?_assert(..) end]}.  %% 每用例一套
{timeout, 10, fun() -> ... end}.                      %% 默认 5s，慢测试显式给
{inorder, [...]}. / {inparallel, [...]}.              %% 顺序 / 并行
```

坑：setup/foreach 的 instantiator 必须**返回测试项**（直接在体里写断言会报 `is not a test`）；setup 要**幂等**（上次失败残留的目录会让 make_dir 报 eexist——先 `del_dir_r` 再建）；`file:del_dir` 只删空目录，清理用 `_r`。

## 21.5 eunit:test 的形态

`eunit:test(Mod)` / `{module, M}` / `{generator, Fun}` / 列表 / `deep` 测试树；选项 `[no_output]`（安静）`[verbose]`。命令行版：`erl -noshell -pa build/NN -eval "eunit:test('NN_tests'), halt()."`。

## 21.6 Common Test：suite 结构与实跑

```erlang
-module(ct21_SUITE).
-export([all/0, init_per_suite/1, end_per_suite/1, smoke_case/1, ...]).
all() -> [smoke_case, fixture_case, failing_shape_case].
init_per_suite(Config) -> [{sandbox, Dir} | Config].   %% 前置挂进 Config
fixture_case(Config) -> Dir = proplists:get_value(sandbox, Config), ...   %% 用例收 Config
%% ct:pal/2 打日志进 HTML 报告（不污染 stdout）；ct:fail/1 显式置败
```

```powershell
ct_run -dir build/ct-21-run -logdir build/ct-21-logs   # 命令行
erl -noshell -pa build/21_testing -eval "ct:run_test([{dir, D}, {logdir, L}]), halt()."  # 编程
```

返回 `{Ok, Failed, {UserSkipped, AutoSkipped}}`。CT 默认在**测试目录**里找 `*_SUITE.erl` 自己 make——把源码拷进沙箱目录再指给它（示例 `run_ct/0` 的做法）。日志/HTML 报告在 logdir，含时间戳目录名。

## 21.7 静音第三方输出：group leader 重定向

CT 往 stdout 打带时间戳的行——可复现输出的死敌。技巧：把本进程的 `group_leader` 换成一个"黑洞"进程（实现最小 io 协议：写请求应 ok、读请求应 eof），第三方输出全部静音，只留返回值：

```erlang
RealGL = group_leader(),  group_leader(BlackHole, self()),
R = ct:run_test(Opts),    group_leader(RealGL, self()).
```

## 21.8 坑位清单

1. **测试模块手写 `-export`**：eunit.hrl 已自动导出 `*_test`——再写报 already exported（`-Werror` 拦下）。
2. **常量断言编译期点死**：`?assertEqual(2, 1+1)` 编不过——值走 opaque 函数。
3. **fixture instantiator 直接写断言**：报 `result is not a test`——返回测试项或用 `?_assert` 宏。
4. **setup 不幂等**：上次残留让 make_dir 报 eexist——先清再建。
5. **`file:del_dir` 删非空目录**：报 eexist——清理用 `del_dir_r`。
6. **单测试默认 5 秒超时**：慢用例包 `{timeout, N, ...}`，否则被 EUnit 杀掉。
7. **EUnit 测试进程是全新的**：进程字典/全局状态每个用例独立——依赖跨用例状态要用 foreach 传递。
8. **并行用例共享注册名/文件**：`inparallel` 会互踩——有共享资源的用 `inorder`。

---
