# 30 · 性能剖析与跟踪：先测量，再动手

> 对应示例：`examples/30_profiling/`

「过早优化是万恶之源」的前半句是「先测量」。取材《Erlang 程序设计》
第 21 章；本章把三件套按**确定性**重新划线：哪些数据能进验证输出、
哪些只能讲。

| 工具 | 数据 | 确定性 | 能否打印 |
|---|---|---|---|
| `timer:tc` | 耗时微秒 | ✗ 环境相关 | 只断言性质（`>= 0`） |
| `cprof` | 函数调用**次数** | ✓ 计数确定 | **可以打印** |
| `erlang:trace` + 自定义 tracer | 事件流 | ✓（聚合后） | 聚合计数可打印 |
| `fprof`/`dbg` | 调用链+绝对时间/交互流 | ✗ | 只讲不跑 |

## 30.1 timer:tc：一段代码跑多久

```erlang
{Micros, 2584} = timer:tc(?MODULE, fib, [18]),
true = Micros >= 0.     %% 只断言下限——Windows 上偶发量出 0 微秒！
```

实测两记：耗时数字每台机器每次跑都不同（打印即毁掉第 4 层）；快函数
在 Windows 上能量出 **0 微秒**——连「> 0」都不能断言，只能 `>= 0`。

## 30.2 cprof：计数剖析——唯一确定性的剖析数据

```erlang
cprof:start(),
ok = workload(),                 %% fib(18) + lists:sum(seq(1,500))
cprof:pause(),
{Total, PerMod} = cprof:analyse(),           %% {总数, [{模块, 数, [{FA,数}]}]}
{'30_profiling', Own, FAs} = cprof:analyse('30_profiling'),
```

```text
按模块计数（排序后） = [{'30_profiling',8362},
                {lists,631},
                {erlang,4},
                {erts_internal,2}]
本模块最热的函数（fib 递归） = {{'30_profiling',fib,1},8361}
fib/1 实测次数 == 闭式推算 = true
```

计数是确定的：同一负载永远同一组数——`fib(18)` 的 8361 次调用与闭式
`calls(n) = 1 + calls(n-1) + calls(n-2)` 分毫不差。**找热点函数用
cprof：谁被调得最多一目了然，且结果可进测试。**

`analyse` 返回的是嵌套结构（`{Total, [{M, C, [{FA, C}]}]}`），不是
扁平的 `{MFA, Count}` 列表——直接 keysort 会 case_clause。

## 30.3 erlang:trace + 自定义 tracer

cprof 数的是「多少次」，trace 抓的是「**什么时候**发生了什么」。自己
起一个 tracer 进程收事件、聚合成计数再打印（顺序依赖调度，**聚合后**
才确定）：

```erlang
trace_calls(Fun) ->
    Tracer = spawn(fun () -> collect(#{}) end),
    Matched = erlang:trace_pattern({?MODULE, '_', '_'}, true, [local]),
    true = Matched > 0,     %% 返回的是匹配到的函数个数，不是 1！
    1 = erlang:trace(self(), true, [call, arity, {tracer, Tracer}]),
    _ = Fun(),
    1 = erlang:trace(self(), false, [call]),
    _ = erlang:trace_pattern({?MODULE, '_', '_'}, false, [local]),
    Tracer ! {stop, self()},
    receive {counts, Counts} -> Counts end.
```

要点：`[local]` 抓模块内**本地调用**（fib 自己调自己）；`arity`
旗标让消息只带 `{M, F, 元数}` 不带参数（参数可能是大项，且进输出就
毁确定性）。dbg 是它的交互式封装、fprof 再加调用链与耗时——概念懂
了，输出格式注定进不了逐字节验证。

## 30.4 观察者效应：测完要收摊

```text
stop 之后重新 analyse（观察者效应要收摊） = {'30_profiling',0,[]}
```

cprof/trace 都给系统加税：**用完必须 stop**——否则「测一次永远付
代价」，而且 cprof 的计数表会污染下一次剖析（start 前先 stop 的习惯
值一文不值，stop 之后 analyse 归零才是干净）。

## 30.5 坑位清单

1. **时间只能断言性质，计数才能打印**——第 4 层逐字节验证的分界线。
2. **Windows 上 timer:tc 可能量出 0 微秒**——断言用 `>= 0`。
3. **`cprof:analyse/1` 返回 `{Mod, 总数, [{FA, 数}]}`**、`analyse/0`
   返回 `{总数, [...]}`——嵌套结构，别当扁平表 keysort。
4. **`erlang:trace_pattern/3` 返回匹配到的函数个数**（如 19）——
   `1 = ...` 直接 badmatch。
5. **`arity` 是 `erlang:trace/3` 的裸原子旗标**，不是
   `{arity, true}` 元组、更不是 trace_pattern 的选项——放错位置
   badarg。
6. **trace_pattern 带 `[local]` 才抓本地调用**——默认 global 只抓
   外部调用，递归函数一个事件都看不到。
7. **tracer 按到达顺序收消息**——顺序依赖调度，打印前必须聚合排序。

## 30.6 要点小结

```text
  方法论：cprof 找热点函数 → fprof 看调用链 → trace 抓特定事件
  计数确定性可打印；时间是环境数字只断言性质
  trace：pattern(挑函数+local) + trace(挑进程+旗标) + tracer(收事件)
  观察者效应要收摊：cprof:stop / trace(false) / trace_pattern(false)
  系统数字（调度器数/队列长度/内存）同理：概念懂，数值不进输出
```
