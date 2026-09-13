# Erlang/OTP 编程指南（Windows）

本教程按 `guide` 统一标准组织：**Markdown 文档 + 独立示例文件 + build 脚本 + 编译验证**。  
示例目录：`examples/`，构建入口：`build.ps1`。

## 目录

1. [环境准备](#环境准备)
2. [第一个 Erlang 程序](#第一个-erlang-程序)
3. [基本类型与模式匹配](#基本类型与模式匹配)
4. [列表与元组处理](#列表与元组处理)
5. [递归与 Guard](#递归与-guard)
6. [高阶函数](#高阶函数)
7. [错误处理](#错误处理)
8. [Record 与 Map](#record-与-map)
9. [进程与消息传递](#进程与消息传递)
10. [OTP 行为：gen_server](#otp-行为gen_server)
11. [ETS 内存表](#ets-内存表)
12. [进阶专题示例（e11-e30）](#进阶专题示例e11-e30)
13. [统一编译验证](#统一编译验证)

---

## 环境准备

- Erlang 目录：`G:\scoop\apps\erlang\current`
- 编译器：`G:\scoop\apps\erlang\current\bin\erlc.exe`
- 教程目录：`G:\code\guide\erlang`

可用下面命令检查：

```powershell
G:\scoop\apps\erlang\current\bin\erlc.exe -version
```

---

## 第一个 Erlang 程序

源码：`examples/e01_hello.erl`

```erlang
-module(e01_hello).
-export([main/0]).

main() ->
    io:format("Hello, Erlang/OTP!~n").
```

---

## 基本类型与模式匹配

源码：`examples/e02_types_pattern.erl`

```erlang
-module(e02_types_pattern).
-export([describe/1, demo/0]).

describe({user, Name, Age}) when is_list(Name), is_integer(Age) ->
    {ok, io_lib:format("user=~s age=~p", [Name, Age])};
describe(#{name := Name, age := Age}) when is_binary(Name), is_integer(Age) ->
    {ok, io_lib:format("user=~ts age=~p", [Name, Age])};
describe(_) ->
    {error, invalid_data}.

demo() ->
    A = describe({user, "alice", 21}),
    B = describe(#{name => <<"bob">>, age => 32}),
    {A, B}.
```

---

## 列表与元组处理

源码：`examples/e03_lists_tuples.erl`

```erlang
-module(e03_lists_tuples).
-export([sum/1, first_two/1, demo/0]).

sum(List) when is_list(List) ->
    lists:sum(List).

first_two([A, B | _]) ->
    {A, B};
first_two(_) ->
    error.

demo() ->
    Total = sum([1, 2, 3, 4, 5]),
    Pair = first_two([x, y, z]),
    {Total, Pair}.
```

---

## 递归与 Guard

源码：`examples/e04_recursion_guards.erl`

```erlang
-module(e04_recursion_guards).
-export([factorial/1, fib/1]).

factorial(N) when is_integer(N), N >= 0 ->
    factorial_loop(N, 1).

factorial_loop(0, Acc) ->
    Acc;
factorial_loop(N, Acc) ->
    factorial_loop(N - 1, N * Acc).

fib(N) when is_integer(N), N >= 0 ->
    fib_loop(N, 0, 1).

fib_loop(0, A, _) ->
    A;
fib_loop(N, A, B) ->
    fib_loop(N - 1, B, A + B).
```

---

## 高阶函数

源码：`examples/e05_hof.erl`

```erlang
-module(e05_hof).
-export([square_all/1, even_only/1, sum_of_squares/1]).

square_all(List) ->
    lists:map(fun(X) -> X * X end, List).

even_only(List) ->
    lists:filter(fun(X) -> X rem 2 =:= 0 end, List).

sum_of_squares(List) ->
    lists:foldl(fun(X, Acc) -> X * X + Acc end, 0, List).
```

---

## 错误处理

源码：`examples/e06_error_handling.erl`

```erlang
-module(e06_error_handling).
-export([safe_div/2, safe_apply/2]).

safe_div(_, 0) ->
    {error, divide_by_zero};
safe_div(A, B) ->
    {ok, A / B}.

safe_apply(Fun, Arg) when is_function(Fun, 1) ->
    try Fun(Arg) of
        Value -> {ok, Value}
    catch
        Class:Reason ->
            {error, {Class, Reason}}
    end.
```

---

## Record 与 Map

源码：`examples/e07_records_maps.erl`

```erlang
-module(e07_records_maps).
-export([new_person/2, birthday/1, person_to_map/1]).

-record(person, {name, age = 0}).

new_person(Name, Age) when is_list(Name), is_integer(Age), Age >= 0 ->
    #person{name = Name, age = Age}.

birthday(P = #person{age = Age}) ->
    P#person{age = Age + 1}.

person_to_map(#person{name = Name, age = Age}) ->
    #{name => Name, age => Age}.
```

---

## 进程与消息传递

源码：`examples/e08_process_message.erl`

```erlang
-module(e08_process_message).
-export([start_worker/0, ask/2]).

start_worker() ->
    spawn(fun loop/0).

ask(Pid, Msg) ->
    Ref = make_ref(),
    Pid ! {self(), Ref, Msg},
    receive
        {Ref, Reply} -> {ok, Reply}
    after 1000 ->
        timeout
    end.

loop() ->
    receive
        {From, Ref, {echo, Value}} ->
            From ! {Ref, Value},
            loop();
        {From, Ref, stop} ->
            From ! {Ref, stopped};
        _Other ->
            loop()
    end.
```

---

## OTP 行为：gen_server

源码：`examples/e09_counter_server.erl`

```erlang
-module(e09_counter_server).
-behaviour(gen_server).

-export([start_link/0, stop/0, get/0, inc/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

stop() ->
    gen_server:call(?SERVER, stop).

get() ->
    gen_server:call(?SERVER, get).

inc() ->
    gen_server:cast(?SERVER, inc).

init([]) ->
    {ok, 0}.

handle_call(get, _From, Count) ->
    {reply, Count, Count};
handle_call(stop, _From, Count) ->
    {stop, normal, ok, Count};
handle_call(_Req, _From, Count) ->
    {reply, {error, unknown_call}, Count}.

handle_cast(inc, Count) ->
    {noreply, Count + 1};
handle_cast(_Msg, Count) ->
    {noreply, Count}.

handle_info(_Info, Count) ->
    {noreply, Count}.

terminate(_Reason, _Count) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
```

---

## ETS 内存表

源码：`examples/e10_ets_demo.erl`

```erlang
-module(e10_ets_demo).
-export([run/0]).

run() ->
    Tab = ets:new(score_tab, [set, public]),
    true = ets:insert(Tab, {alice, 100}),
    true = ets:insert(Tab, {bob, 95}),
    [{alice, AliceScore}] = ets:lookup(Tab, alice),
    All = ets:tab2list(Tab),
    ets:delete(Tab),
    #{alice => AliceScore, all => All}.
```

---

    ## 进阶专题示例（e11-e30）

    为满足“更完整教程 + 更多可编译样例”，新增 20 个进阶示例：

    - `e11_binary_bitstring.erl`：二进制与位语法拆包
    - `e12_string_unicode.erl`：字符串规范化与 Unicode 二进制
    - `e13_case_if.erl`：`case` / `if` 分支组织
    - `e14_list_comprehension.erl`：列表推导式（含勾股数组合）
    - `e15_proplists.erl`：属性列表与默认配置合并
    - `e16_sets_demo.erl`：`sets` 集合操作
    - `e17_gb_trees_demo.erl`：`gb_trees` 有序键值结构
    - `e18_queue_demo.erl`：函数式队列 `queue`
    - `e19_orddict_demo.erl`：有序字典 `orddict`
    - `e20_timer_timeout.erl`：`receive ... after` 与 `timer:send_after/3`
    - `e21_monitor_demo.erl`：进程监控 `erlang:monitor/2`
    - `e22_supervisor_spec.erl`：Supervisor 子规格构造
    - `e23_application_env.erl`：应用环境变量读写
    - `e24_file_io.erl`：文本文件读写
    - `e25_regex_demo.erl`：正则匹配与提取
    - `e26_term_binary.erl`：`term_to_binary` 与 `binary_to_term`
    - `e27_rand_demo.erl`：随机数与抽样
    - `e28_spawn_pool.erl`：并行映射 `pmap`
    - `e29_maps_advanced.erl`：嵌套 Map 读写与计数聚合
    - `e30_logger_demo.erl`：结构化日志数据拼装

    示例均位于 `examples/` 并纳入 `build.ps1 -All` 的统一编译验证。

    ---

    ## 统一编译验证

在本目录执行：

```powershell
cd G:\code\guide\erlang
.\build.ps1 -All
```

单文件：

```powershell
.\build.ps1 -File e09_counter_server.erl
```

清理：

```powershell
.\build.ps1 -Clean
```

建议每次新增示例后都执行一次 `-All`，确保教程示例持续可编译。
