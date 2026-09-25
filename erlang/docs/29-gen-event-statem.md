# 29 · gen_event 与 gen_statem：两种行为补全 OTP 版图

> 对应示例：`examples/29_gen_event_statem/`（辅助模块：evt_counter / evt_forward / evt_crash / lock_statem）

gen_server（15 章）、supervisor（16 章）、application（17 章）之外，
OTP 还有两块常用行为：**gen_event**（事件管理器）与 **gen_statem**
（状态机）。取材《Erlang 程序设计》第 22 章 + 《Erlang and Elixir
for Imperative Programmers》第 10 章的 OTP 服务器巡礼。

## 29.1 gen_event：manager 是进程，handler 是可插拔的小角色

```text
notify ──▶ gen_event manager 进程
               ├── evt_counter（处理器 1：数事件，状态=计数）
               ├── evt_forward（处理器 2：转发给我）
               └── evt_crash  （处理器 3：收到 {die,_} 就崩）
```

handler 不是模块——是挂在 manager 上的**实例**（同模块可挂多个），
每个 handler 有自己的状态：

```erlang
{ok, M} = gen_event:start({local, ex29_evt}),
ok = gen_event:add_handler(M, evt_counter, []),
ok = gen_event:add_handler(M, evt_forward, [self()]),
ok = gen_event:notify(M, {tick, 1}),              %% 广播给所有 handler
3 = gen_event:call(M, evt_counter, get_count, 2000).   %% call 定向某一个
```

## 29.2 崩溃隔离：handler 死了只死它自己

```text
崩溃之后剩下的 handler = [evt_counter]
counter 还在数 = 3
```

`evt_crash` 收到 `{die, _}` 抛异常 → manager **摘掉它**、其他 handler
继续收后续事件。这与 gen_server 形成对照：server 崩了要 supervisor
重启；handler 崩了 manager 顺势除名——**事件流的可用性优先于单个
处理器**。logger 的 handler 机制（22 章）就是 gen_event 组装的：你
`logger:add_handler/2` 挂的就是这种处理器。

## 29.3 swap_handler：热替换把状态带过去

```erlang
ok = gen_event:swap_handler(M, {evt_counter, []}, {evt_counter, []}),
```

OTP 29 实测三连：

1. 老书的 **swap_handler/4 已是 undef**——现在是 **/3**：新旧 handler
   连各自的 args **各自成对**；
2. 状态传递链：老 handler 的 `terminate(Args1, State)` 返回
   `{ok, Term}` → 新实例的 `init` 收到 **`{Args2, Term}`**（Term 是
   整个返回值，不拆）；
3. `delete_handler` 的返回值就是 terminate 的返回值——状态外带的
   另一条通道。

```erlang
%% evt_counter：
init({_Args2, {ok, Carried}}) when is_integer(Carried) -> {ok, Carried};
init(_) -> {ok, 0}.
terminate(_Args, Count) -> {ok, Count}.
```

```text
替换前 counter 数到 = 7
替换后新 counter 从旧状态接着数 = 7
```

## 29.4 gen_statem：状态机即回调

门禁锁是教科书经典例（Armstrong 书 22 章拿它讲 gen_statem 前身）。
**状态 = 函数名**，事件按四类分派：

```erlang
callback_mode() -> state_functions.

locked({call, From}, {button, D}, #{code := Code, entered := Entered} = Data) ->
    Now = Entered ++ [D],
    case Now =:= Code of
        true  -> {next_state, open, Data#{entered => []},
                  [{reply, From, unlock}, {state_timeout, 500, auto_lock}]};
        false -> ...
    end;
locked(state_timeout, clear, Data) ->
    {keep_state, Data#{entered => []}}.      %% 部分输入超时清零

open(state_timeout, auto_lock, Data) -> {next_state, locked, Data}.
```

```text
按完整正确序列 = [partial,partial,unlock]
开门后的状态 = {open,[]}
开门期间再按键（open 态只回 still_open） = still_open
超时自动落锁 = {locked,[]}
```

**OTP 29 实测坑**：state_timeout 触发的事件类型是
**`state_timeout`**——老教材写 `timeout` 的地方现在直接
`function_clause` 崩（状态机整个带走）。`timeout` 是 gen_fsm 时代的
遗留语义，别混。

两种 `callback_mode`：

| 模式 | 形态 | 适合 |
|---|---|---|
| `state_functions` | 每状态一个同名函数 | 状态少、转移清晰（门禁锁） |
| `handle_event_function` | 一个 `handle_event/4` 吃所有状态 | 状态多/动态生成、或要推迟事件 `{postpone, true}` |

命令式程序员视角：switch-case 的状态机把「状态」藏在变量里、把
「转移」散在各 case 分支；gen_statem 反过来——**状态当函数头、事件
当参数**，非法转移在编译期就是缺子句（Crash 报告直指状态+事件对）。

## 29.5 坑位清单

1. **gen_event 的 code_change 是 /3**（gen_server/gen_statem 是 /4）
   ——从别的行为抄回调签名必挂。
2. **swap_handler 是 /3**（OTP 29；老书 /4 已 undef），新旧 handler
   各自成对；携带值经 terminate → `init({Args2, Term})`。
3. **`global`/`gen_event` 的返回值风格不统一**：register_name 返回
   yes/no、add_handler 返回 ok——别拿 `true =` 到处匹配。
4. **state_timeout 的事件类型是 `state_timeout`**（不是 `timeout`）；
   写错子句头 = function_clause 崩掉整个状态机。
5. **gen_statem 链接调用方**：start_link 的状态机一崩，没开 trap_exit
   的测试/驱动进程跟着死——教学演示的「意外终止」多半是它。
6. **handler 崩溃摘除是异步的**：notify 之后立刻 which_handlers 可能
   还看得到尸体——测试里 sleep 一拍再断言。
7. **call 带超时**（第 4 参）：handler 不回话时默认 5 秒挂等。

## 29.6 要点小结

```text
  gen_event：manager 一个进程，handler 可插拔、各自有状态
  notify 广播、call 定向；handler 崩溃只被除名，事件流不断
  logger 的 handler 机制 = gen_event（22 章的伏笔在这里兑现）
  swap_handler/3 热替换：terminate 的返回值进新 init({Args2, Term})
  gen_statem：状态当函数（state_functions）或一个大回调（handle_event_function）
  state_timeout 事件类型就叫 state_timeout；{reply, From, Msg} 应答 call
  行为选择：事件解耦用 gen_event；状态爆炸用 gen_statem 换 gen_server
```
