# 20 · 时间与定时器

> 对应示例：`examples/20_time/`

## 20.1 四种"等一会儿"

| 机制 | 语义 | 代价 |
|---|---|---|
| `receive ... after N` | 这次 receive 的专属超时，**不是**定时器 | 最轻 |
| `erlang:send_after(N, Pid, Msg)` | VM 管，到点**原样**投递 | 不占进程 |
| `erlang:start_timer(N, Pid, Msg)` | 到点投 `{timeout, Ref, Msg}` | 不占进程 |
| `timer:send_after` 等 timer 模块 | stdlib 封装，**部分调用走 timer_server 进程** | 见 20.3 |

`after 0` 是"非阻塞探测"（不等直接走超时分支）；`after infinity` 一直等。

## 20.2 取消与剩余时间

```erlang
{ok, Left} = erlang:read_timer(TRef).      %% 剩余毫秒；已结束是 false
N = erlang:cancel_timer(TRef).             %% 返回剩余毫秒；已取消/已触发是 false
```

cancel **保证消息不会再来**，但**不保证它还没在邮箱里**——定时器已触发、消息已投递时，要自己 `receive ... after 0` 清一次邮箱（13 章同款纪律）。

## 20.3 timer 模块的真相（OTP 27+）

老说法"timer 模块全靠 timer_server 一个进程"**不再全对**。实测（OTP 29）：发给**本地 pid** 直接委托 `erlang:send_after`（timer_server 根本不启动）；发给**注册名/远端**、`apply_after/exit_after/send_interval` 才由服务进程代发。`timer:cancel` **永远返回 `{ok,cancel}`**——不能用来判断成功与否；精确控制（限流器）直接用 `erlang:send_after + erlang:cancel_timer`。

## 20.4 超时值的合法范围

`0` 立即、`infinity` 永久；**负数抛 `timeout_value`**（不是 badarg——看到它就查超时参数）；`send_after` 超 2^64 毫秒抛 badarg。`gen_server:call` 默认 5000ms。

## 20.5 墙钟 vs 单调钟

```erlang
erlang:system_time(millisecond).      %% 墙钟：NTP 校时会跳（存"时间戳"用它）
erlang:monotonic_time(millisecond).   %% 单调：只增不减，但起点任意、可能是负数
erlang:convert_time_unit(X, native, millisecond).  %% 单位换算必须显式
```

**单调钟算间隔、墙钟存时间**——拿 monotonic_time 当时间戳存是错的；反过来用墙钟测间隔，NTP 校时可能量出负数（`timer:tc` 内部就是墙钟）。

## 20.6 系统限制

| 项 | 默认 | 备注 |
|---|---|---|
| `process_limit` | 1048576 | 进程数上限 |
| `ets_limit` | 8192 | **比进程小得多**——要建很多表得调 |
| `atom_limit` | 1048576 | 只涨**不回收** |
| `port_limit` | 随环境变 | 按文件描述符上限算——别把数字打进输出 |

## 20.7 数值边界与内存观测

整数任意精度不溢出；**浮点溢出/负数开方抛 badarith**（没有 inf/nan）。`erlang:memory(total)`、`process_info(self(), heap_size/message_queue_len/reductions)` 观测现状；死进程的 `process_info` 返回 `undefined`（不崩）。

## 20.8 坑位清单

1. **monotonic_time 当时间戳存**：起点任意可为负——算间隔专用。
2. **墙钟测间隔**：NTP 一跳就是负数——`monotonic_time` 前后相减。
3. **cancel 后不清邮箱**：迟到的超时消息被下个 receive 读走——flush。
4. **大量定时器挤 timer 模块**：注册名/interval 场景都走 timer_server——高频用 `erlang:send_after`。
5. **`timer:cancel` 判断成功**：它永远 `{ok,cancel}`——判断用 `erlang:cancel_timer`。
6. **`receive after 变量` 不检查**：变量为负抛 `timeout_value`——超时值也防御。
7. **ets_limit 当 process_limit**：默认 8192，批量建表先想清楚。

---
