# 14 · 链接与监控

> 对应示例：`examples/14_links/`

## 14.1 link 双向，monitor 单向

| | link | monitor |
|---|---|---|
| 方向 | 双向（谁死都通知对方） | 单向（只通知监控者） |
| 对方崩溃时 | 发 **exit 信号**：没开 trap_exit 就被**一起杀掉** | 收 `{'DOWN', Ref, process, Pid, Reason}` 消息，自己无恙 |
| 可重复 | `link/1` 幂等 | `erlang:monitor/2` 每次新 Ref，`demonitor` 取消 |
| 消息形状 | `{'EXIT', Pid, Reason}`（仅 trap_exit 时才成消息） | `{'DOWN', Ref, process, Pid, Reason}` |

容错的基石：**让失控的进程死掉，由外部（监督者）收拾现场**。

## 14.2 trap_exit：把信号变成消息

```erlang
Old = process_flag(trap_exit, true),    %% 返回旧值——用完还原
receive {'EXIT', Pid, Reason} -> ... end.
```

- 开了 trap_exit 的进程收到 exit 信号只是收到一条 `{'EXIT',...}` 消息，不会被杀；
- 实测反直觉点：**`erl -run` 启动的进程 trap_exit 本来就是 true**，自己 spawn 的默认 false（OTP 27+ 实测）；
- supervisor 就是"trap_exit + 重启策略"的封装（16 章）。

## 14.3 DOWN / EXIT 里的 Reason 形状

| 终止方式 | Reason |
|---|---|
| `erlang:error(R)` 崩溃 | `{R, Stacktrace}`——**带栈** |
| `exit(R)` | R 原样 |
| 未捕获 throw | `{nocatch, V, ...}` |
| 正常结束 | `normal` |

"崩溃日志能看到出错位置"只对 error 类成立——12 章同款结论。

## 14.4 exit(Pid, kill)：唯一不可捕获

```erlang
exit(T, please_stop).   %% trap_exit 的目标会把它变成消息、继续活着
exit(T, kill).          %% 无视一切设置必死，终止原因 killed
```

kill 是"兜底弄死"（对方没有任何机会处理）；**shutdown 才是"请你体面地停"**——supervisor 关闭子进程用的就是它（16 章）。

## 14.5 等一批进程结束

```erlang
Refs = [element(2, spawn_monitor(Job)) || Job <- Jobs],
[receive {'DOWN', R, process, _, Reason} -> ... end || R <- Refs].
```

起 N 个工人等全部干完：monitor + **按 Ref 收 DOWN**——不能靠进程数也不能靠顺序。

## 14.6 为什么需要监督树

"我崩了要重启"——谁负责重启？重启几次？太频繁要不要放弃？启动/关闭顺序有依赖怎么办？这些问题的答案就是 OTP 的 supervisor 与 application（15–17 章）。

## 14.7 坑位清单

1. **`erl -run` 起的进程 trap_exit 默认 true**：实测反直觉——迁移到 `erl -eval`/escript 时行为可能变。
2. **trap_exit 改了不还原**：后面所有崩溃静默变成消息，错误处理逻辑全乱——"先存旧值，用完还原"。
3. **exit(Pid, kill) 不给清理机会**：优雅停止用 shutdown/stop 协议，kill 只做兜底。
4. **等一批进程靠计数**：崩溃的不发 DOWN？不，都会发——但顺序不定，必须按 Ref 配对。
5. **link 了不开 trap_exit**：被链接方崩溃**传染**——测试进程全灭；示例演示了"没有 trap_exit 时链接方被带崩"。

---
