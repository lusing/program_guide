# 31 · 多核并行：pmap 三变体与 future

> 对应示例：`examples/31_multicore/`

Erlang 的并行不需要锁：每个进程一个邮箱，调度器把进程铺满所有核。
取材《Erlang 程序设计》第 26 章——「多核 CPU 编程」的核心洞察是：
**并发模型对了，多核的红利是免费的**（+S 1:1 单调度器只是把并行
变交织，结果不该有任何变化）。

## 31.1 无序 pmap：完成顺序 ≠ 输入顺序

```erlang
pmap_unordered(Fun, List) ->
    Parent = self(),
    _ = [spawn(fun () -> Parent ! {pmap_tag, Fun(X)} end) || X <- List],
    [receive {pmap_tag, V} -> V end || _ <- List].   %% 收满 N 条为止
```

```text
收齐后 sort（完成顺序随机，排序后才可打印） = [377,610,987,1597,2584]
```

谁先算完谁先到——**打印前必须 sort**，这是第 4 层的铁律。能用无序
结果就用无序版：省掉排序通信、整体延迟取最慢者而非总和。

## 31.2 有序 pmap：序号 tag 按输入顺序重组

```erlang
pmap_ordered(Fun, List) ->
    Parent = self(),
    Indexes = lists:seq(1, length(List)),
    _ = [spawn(fun () -> Parent ! {{tag, I}, Fun(X)} end)
         || {I, X} <- lists:zip(Indexes, List)],
    [receive {{tag, I}, V} -> V end || I <- Indexes].   %% 按序号逐个收
```

```text
输出顺序 = 输入顺序（谁先算完无所谓） = [2584,377,1597,610,987]
```

每条消息自带序号，receive 按序号点名——**等待是选择性的**：收第 2
条时第 3 条先到也不影响（躺在邮箱里等被点名）。

## 31.3 超时版 pmmap：卡死的元素被放弃

```erlang
%% 3 号元素卡死 60 秒，其他都是快活
Done = pmmap(Job, 300, [1, 2, 3, 4]),
```

```text
完成的序号（3 号卡死被放弃） = [1,2,4]
```

到点收工三步曲：deadline 一到**放弃未完成者** → **杀掉**还卡着的
worker（被杀的不会再发消息）→ **drain 清邮箱**（正在路上的孤儿消息
不扫掉，会污染调用方后面的 receive——测试里最阴的坑）：

```erlang
drain_pm() ->
    receive {{pm, _}, _} -> drain_pm() after 0 -> ok end.
```

## 31.4 future：先起步，后取值

```erlang
F1 = future(fun () -> fib(20) end),        %% spawn + make_ref 配对
F2 = future(fun () -> lists:sum(lists:seq(1, 1000)) end),
_ = 1 + 1,                                 %% 起步后主进程还能干活
6765 = yield(F1),                          %% receive 按 ref 点名取值
500500 = yield(F2).
```

书上叫 promise：`future/1` 返回 ref，`yield/1` 阻塞取值——两个
future 同时起步，取值顺序随意。

## 31.5 加速比与粒度：能断言什么

**结果等价**可以断言（串行 vs 并行逐项相等）；**加速比**不能——那
要打印时间数字（每台机器不同，第 4 层直接挂）。书里用
`timer:tc` 对比串行/并行耗时讲阿姆达尔定律，本教程把那段留给正文
叙述，输出里只有：

```text
串行 map 的结果 = [377,610,987,1597,2584]
和 lists:map 一致 = true
```

粒度同样重要：pmap 每个元素 spawn 一个进程——元素太小（如 `X * 2`）
时 spawn 的开销吃掉所有收益。**粗粒度任务**（fib(18) 这种）才值得。

## 31.6 坑位清单

1. **无序收集打印前必须 sort**——完成顺序就是调度顺序的影子。
2. **超时放弃后要杀 worker + drain 孤儿消息**——不杀则泄漏进程，
   不 drain 则迟到的 `{pm, I}` 消息砸进调用方后续的 receive（测试
   里表现为「偶发」的神秘失败）。
3. **pmmap 的 deadline 是整体的**：收到几条算几条——别按「每条
   等一拍」写，那是 N × 超时。
4. **输出纪律：绝不出现时间数字**——加速比、耗时全是环境数字；
   可断言的只有结果等价与完成集合。
5. **`+S 1:1` 通道是并行正确性的试金石**：单调度器下结果不同 =
   你的并行逻辑依赖了调度顺序（本教程第 4 层验证顺手把它跑了）。
6. **future 的 ref 配对**是选择性 receive 的前提——用「第几条消息」
   计数取值在并行世界必错。

## 31.7 要点小结

```text
  并行免费的前提：并发模型干净（每进程一邮箱，无共享无锁）
  无序 pmap 最快（免重组），能容忍乱序就用它
  有序 pmap：消息带序号，receive 点名收取
  pmmap：deadline 收工 + 杀 worker + drain 孤儿——三步都不能省
  future/promise：spawn + ref，先起步后取值
  阿姆达尔上限与粒度：粗任务才值得并行；加速比是叙述不是输出
```
