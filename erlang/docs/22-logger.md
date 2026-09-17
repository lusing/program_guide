# 22 · 日志与可观测性

> 对应示例：`examples/22_logger/`（日志写进文件再读回来打印——handler 异步写，与 io:format 无顺序保证）

## 22.1 一条日志过四道关

```text
1. primary level（全局总闸，**默认 notice**——info/debug 默认不出来！）
2. primary filters（对所有 handler 生效；stop 即止）
3. module level（按发起模块调级别，只对 ?LOG_* 宏生效）
4. handler level + filters（每个 handler 再筛一遍）
```

任何一道关说"不要"，这条日志就消失——**而且不报错**。

## 22.2 级别与比较

`debug < info < notice < warning < error < critical < alert < emergency`。`logger:compare_levels(A, B)` 返回 `gt | lt | eq`。两道关**串联**，取更严的：primary=notice + handler=debug 时 info 出不来；primary=debug + handler=error 时 info 也出不来。

## 22.3 模块级的坑

`set_module_level(Mod, Level)` 靠日志事件里的 **mfa 元数据**判断"是谁打的"，而 mfa 只有 `?LOG_INFO` 等**宏**才塞进去——直接调 `logger:info/1` 完全不受模块级管（示例实测：同一模块里宏被挡、直调照出）。

## 22.4 msg 的三种形状

```erlang
logger:info("plain").                        %% {string, S}
logger:info("formatted ~p", [X]).            %% {Fmt, Args}——格式化**推迟**到写的时候
logger:info(#{what => happened}).            %% {report, Map}——按键排序 "count: 3, what: ..."
```

自己写 filter 必须三种都处理（`msg_to_text` 惯用法见示例）。**在调用方拼大字符串是反模式**——格式化的代价应留在 handler 进程。

## 22.5 模板与元数据

```erlang
{logger_formatter, #{template => [level, <<" [">>, request_id, <<"] ">>, msg, "\n"]}}
```

可用字段：level/msg/mfa/domain/time/date/pid/gl/file/line/report_cb；**time/pid 每次都变**——要可复现的输出就别放进模板。模板字面量写成 binary（`<<"[x] ">>`）；用 `++` 拼平字面量与 msg 会报 `invalid_formatter_template`。metadata 里没有的字段输出**空串**不报错。

## 22.6 过滤器三态

返回 `LogEvent`（继续/可改字段，比如把 info 提级成 critical）、`ignore`（**不表态**，不是丢弃）、`stop`（丢弃）。过滤器崩了会被 logger **摘掉**并报一条——之后所有日志都出来了。

## 22.7 过载保护：日志真的会丢

handler 异步写，队列三道闸（默认值）：`sync_mode_qlen=10`（转同步，调用方被迫等）→ `drop_mode_qlen=200`（**直接丢日志保命**）→ `flush_qlen=1000`。所以：**别拿日志当审计/业务数据**；慢速落盘的 handler 把 drop_mode_qlen 调小。

## 22.8 坑位清单

1. **`logger:info` 默认什么都看不到**：primary level 默认 notice——`set_primary_config(level, info)` 或 sys.config 配。
2. **模块级不生效**：直调 `logger:info` 不带 mfa——改用 `?LOG_*` 宏（include `kernel/include/logger.hrl`）。
3. **ignore ≠ 丢弃**：要丢返回 stop。
4. **过滤器只处理了字符串形状**：带参数/report 的日志会让它崩，然后被摘掉。
5. **日志与 io:format 顺序对不上**：handler 是另一个进程——要复核就写文件再读回（本示例的做法）。
6. **没有 logger_disk_h**：写文件用 `logger_std_h + config#{type => {file, Name}}`。

---
