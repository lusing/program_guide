# 13 · 进程与消息

> 对应示例：`examples/13_processes/`

## 13.1 进程：微秒级、全隔离

```erlang
spawn(fun() -> ... end).          %% ① 匿名 fun：可捕获变量
spawn(?MODULE, worker, [Args]).   %% ② MFA：必须导出；热更新友好（23 章）
spawn_monitor(fun() -> ... end).  %% ③ 顺便拿到 {Pid, Ref}，结束/崩溃有 DOWN
```

每进程独立堆、几百字节、创建微秒级——"一个连接一个进程"是常态。**数据是拷贝**：发消息时 term 复制到对方堆（>64 字节的 refc binary 共享），"改一个变量永远影响不到别人"。

## 13.2 注册名

```erlang
true = register(my_server, Pid).
whereis(my_server).    %% Pid | undefined（没注册不会崩）
```

注册名是**全局唯一原子**，重名 register 抛 badarg；名字随进程死亡自动释放。别滥用——全局可变状态会让测试互相干扰；OTP 的正规做法是监督树 + 局部注册（16 章）。

## 13.3 邮箱与选择性接收

```erlang
Self ! {tag, 1}, Self ! other, Self ! {tag, 2}.
receive {tag, X} -> X after 0 -> none end.   %% 只取匹配的；other 留在邮箱
```

`!` 的语义逐条记：**永不阻塞、永不失败**（目标死了也照样返回 Msg）；消息进对方邮箱；不匹配的消息**永远留在邮箱里**（队列可无限涨）；同一发送者→同一接收者 FIFO。选择性接收要扫过所有不匹配消息——噪音堆积 = 内存泄漏 + 越收越慢。

## 13.4 协议三消息与 ref 配对

```erlang
%% call:   {From, Ref, Request}  → 对方必须回 {Ref, Reply}
%% cast:   Request（不带 From/Ref）→ 单向通知
%% reply:  {Ref, Reply}          → 靠 Ref 对上号
call(Pid, Req, Timeout) ->
    Ref = make_ref(),
    Pid ! {self(), Ref, Req},
    receive {Ref, Reply} -> Reply
    after Timeout -> {error, timeout}
    end.
```

实测：不带 ref 的协议在**乱序回复**下配对直接搞错（示例第 6 节）；Erlang 不检查消息内容，形状写错只会让 receive 一直等。

## 13.5 超时与迟到的回复

超时后只有两条路：**用 ref 精确 flush 掉迟到回复**（`flush(Ref)` 只清这个 ref 的，不碰别的消息）然后换新 ref 重试；或认为协议不可信，**让它崩**交给监督树。"超时就当没发生"是错的——迟到回复会被下一条 receive 当成新回复读进来。

## 13.6 pmap：并行 map

```erlang
pmap(F, L) ->
    Self = self(),
    Tagged = [{make_ref(), X} || X <- L],
    [spawn(fun() -> Self ! {R, F(X)} end) || {R, X} <- Tagged],
    [receive {R, V} -> V after 5000 -> timeout end || {R, _} <- Tagged].
```

每个请求配一个 ref，结果**按输入顺序**收回——回复顺序不可预测也没关系。

## 13.7 坑位清单

1. **`!` 发成功 ≠ 对方收到**：死进程静默丢弃；要确认就 monitor 或要求回执。
2. **协议不带 ref**：乱序回复直接配错——所有请求-响应协议必须有 ref。
3. **超时后不清邮箱**：迟到回复污染下一次 receive——flush(Ref) 或让它崩。
4. **self() 要在 spawn 前取**：在 fun 里取到的是子进程自己的 pid。
5. **`after 0` 才敢探测邮箱**：裸 `receive X -> ...` 邮箱空时**永久阻塞**。
6. **spawn/3 的函数必须导出**：否则 undef；spawn/1 没这个限制。
7. **进程字典别用**：put/get 是隐式全局状态（虽然进程局部），测试与重构的地狱——用参数、record 或 gen_server state。

---
