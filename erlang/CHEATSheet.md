# Erlang/OTP 29 速查表

一页纸放下 32 章的常用语法与命令；`N.M` = 第 N 章 M 节，详细讲解见对应章（02–32 章都有可跑示例）。

## 1. 环境与命令（01/02）

```powershell
erlc +debug_info -Werror -Wall -o build/NN examples/NN/NN_topic.erl  # 编译（警告即错误）
erl -noshell -pa build/NN -run 'NN_topic' main -s init stop          # 非交互运行
erl -noshell -pa build/NN -eval "eunit:test('NN_topic_tests'), halt()."  # 跑测试
erl -noshell +S 1:1 ...            # 单调度器（本仓库验证通道 B）
erl                                # REPL：q(). 退出
dialyzer --build_plt --output_plt build/guide_plt --apps erts kernel stdlib compiler eunit common_test
ct_run -dir <测试目录> -logdir <日志目录>   # Common Test
```

| 坑 | 解法 |
|---|---|
| 数字开头模块名 | `-module('02_hello').` 引号原子；命令行不用引号（02.2） |
| 跑完不退出 | 必须带 `-s init stop`（02.1） |
| dialyzer 没料 | 编译加 `+debug_info`（erlc 默认不带，23.1） |

## 2. 类型与运算（03）

```erlang
16#FF. 2#1010. $A. 1_000_000.      %% 进制/字符/分隔字面量
-7 div 2.  -7 rem 2.               %% -3 / -1：向零截断，rem 符号随被除数
1 =:= 1.0.                         %% false：默认用 =:= 精确比较
'03_types':safe_atom("x").         %% {ok,x}|{error,not_existing}：外部输入只造已存在原子
```

| 坑 | 解法 |
|---|---|
| 浮点溢出 | 抛 badarith，没有 inf/nan（03.4） |
| `list_to_atom` 外部输入 | 原子表只涨不回收 → `list_to_existing_atom`（03.7） |
| `/` 出浮点 | 整数商用 `div`（03.3） |

## 3. 模式匹配与卫语句（04）

```erlang
area({rect, W, H}) when W > 0, H > 0 -> W * H;   %% 逗号 = and
week_day(N) when N =:= 6; N =:= 7 -> weekend;    %% 分号 = or
same_or_diff({X, X}) -> same.                    %% 同名变量 = 相等断言
#{name := N} = #{name => a}.                     %% map 模式 := 要求键存在
```

| 坑 | 解法 |
|---|---|
| guard 出错 | 静默变 false 继续下个子句——is_list 等类型判定放最前（04.6） |
| guard 调自定义函数 | 编译错误，只能用 BIF 白名单（04.6） |
| if 没兜底 | 抛 if_clause；`true ->` 不能省（04.7） |

## 4. 递归与列表（05/06/07）

```erlang
sum(0, Acc) -> Acc; sum(N, Acc) -> sum(N-1, Acc+N).   %% 尾递归（服务器循环必须）
rev_map(F, L) -> lists:reverse(rev_map(F, L, [])).    %% 攒后反转惯用法
lists:foldl(F(X,Acc), Init, L).  lists:keyfind(K, 1, L).  %% key 族
lists:usort/1. lists:uniq/1.                          %% 前者全去重，后者只去相邻
```

| 坑 | 解法 |
|---|---|
| 循环里 `Acc ++ [X]` | O(N²)：头插 + 最后 reverse（06.1） |
| `lists:nth` 是 1 基 | nth(0,_) 抛 function_clause（06.2） |
| lookup 家族返回值 | false/error/[]/none 四种——逐个确认（06.4） |

## 5. fun 与推导式（07）

```erlang
F = fun(X) -> X * 2 end.  G = fun erlang:max/2.  H = fun F(0) -> 1; F(N) -> N*F(N-1) end.
[X*2 || X <- L].  [X || {X} <- L].            %% 后者：模式不匹配**静默跳过**
<<<<Y:16/little>> || <<Y:16/big>> <= Bin>>.   %% 二进制推导式：<= 生成器 + 输出必须是二进制
```

| 坑 | 解法 |
|---|---|
| foldl 参数顺序 | F(元素, 累加器)，写反编译器不拦（07.3） |
| `~p` 打数字列表 | [11,12,13] 显示成 "\v\f\r"——用 `~w`（07.6） |

## 6. 二进制与字符串（08/09）

```erlang
<<Type:8, Len:16, P:Len/binary, Rest/binary>> = Bin.   %% 尺寸引用前面变量
<<"中文"/utf8>>.                        %% 二进制里的中文必须 /utf8
unicode:characters_to_list(Bin).        %% 解码；characters_to_binary 反向
iolist_to_binary(Deep).  iolist_size(Deep).
```

| 坑 | 解法 |
|---|---|
| `<<"中文">>` 截断 | latin1 截成 rem 256 字节——`/utf8`（09.2，24 章亲历） |
| `~s` 打中文 | badarg——`~ts`；原子用 `~tp`（02.3） |
| 三个"长度" | length 码点 / byte_size 字节 / string:length 字素簇（09.3） |

## 7. map、record 与容器（10/11）

```erlang
M#{k => v}.  M#{k := v2}.  maps:update_with(K, fun(V)->V+1 end, Init, M).  %% 计数惯用法
lists:sort(maps:to_list(M)).                        %% 迭代顺序随机，先 sort
P#person{age = A + 1}.  is_record(X, person).
Q = queue:from_list(L).  queue:in(X, Q).  queue:out(Q).
```

| 坑 | 解法 |
|---|---|
| `:=` 更新不存在的键 | 抛 badkey；upsert 用 `=>`（10.2） |
| map 顺序随机进输出 | sort 后才可比（10.4） |
| `queue:snoc` 参数序反 | `in(Item,Q)` vs `snoc(Q,Item)`（11.5） |
| array 越界 | 返回默认值不报错（11.6） |

## 8. 异常（12）

```erlang
try F() catch Class:Reason:Stack -> ... after Cleanup end.
maybe {ok, N} ?= to_int(X), true ?= (N >= 0) -> ok
else {error,R} -> R; false -> negative end.
%% Reason 表：badarg/badarith/badmatch/function_clause/case_clause/badmap/badkey...
```

| 坑 | 解法 |
|---|---|
| `catch R -> ...` 省略 Class | 默认只接 throw，error 穿透——写 `_:R`（12.2） |
| `catch Expr` | OTP 29 编译即废弃——用 try（12.2） |
| maybe 里普通 `=` | badmatch 穿透 else——断言用 `?=`（12.4） |
| `catch _:_ -> ok` | 只配最外层边界，别包在内部（12.7） |

## 9. 进程与容错（13/14）

```erlang
Pid ! {self(), Ref = make_ref(), Req}.       %% 协议必须带 ref
receive {Ref, Reply} -> Reply after 5000 -> {error, timeout} end.
spawn_monitor(fun() -> ... end).             %% DOWN 观察崩溃
Old = process_flag(trap_exit, true).         %% 用完还原
exit(Pid, shutdown).                         %% 优雅停；kill 不可捕获
```

| 坑 | 解法 |
|---|---|
| `!` 发成功 ≠ 收到 | 死进程静默丢；monitor 或要回执（13.3） |
| 超时后不清邮箱 | 迟到回复污染下一次 receive——flush(Ref)（13.5） |
| `erl -run` 进程 trap_exit 默认 true | OTP 27+ 实测，别想当然（14.2） |
| 忘 `-s init stop`/after 0 | 裸 receive 空邮箱永久阻塞（13.3） |

## 10. OTP 三件套（15/16/17）

```erlang
-behaviour(gen_server).
init/1 -> {ok, State}.  handle_call/3 -> {reply, R, S} | {noreply, S}.
gen_server:call(Name, Req, Timeout).          %% 默认 5000ms
init(SupArgs) -> {ok, {#{strategy => one_for_one, intensity => 3, period => 5}, Specs}}.
application:ensure_all_started(App).          %% 幂等；start/1 不管依赖
```

| 坑 | 解法 |
|---|---|
| terminate/2 不执行 | gen_server 要 `process_flag(trap_exit, true)`（17.5 头号坑） |
| API 叫 get/size | 撞自动导入 BIF——改名（15.7） |
| handle_info 没兜底 | 未知消息堆积邮箱（15.3） |
| stop ≠ unload | stop 只停树，env 还在（17.3） |
| env 改了不生效 | init 快照，重启进程（17.4） |

## 11. ETS、文件与时间（18/19/20）

```erlang
ets:new(T, [set, named_table, public, {heir, self(), Data}]).
ets:info(T, size).  ets:update_counter(T, K, 1).   %% 原子自增
file:write_file(F, <<"中文"/utf8>>, [append]).      %% 字节 iodata；append 不截断
erlang:monotonic_time(millisecond).                 %% 算间隔；墙钟存时间
Ref = erlang:send_after(N, self(), Msg).  erlang:cancel_timer(Ref).
```

| 坑 | 解法 |
|---|---|
| ets:size/1 不存在 | `ets:info(T, size)`（18.1） |
| owner 死表没 | heir 或放监督树进程（18.5） |
| write_file 中文 | {error,badarg}——`/utf8` 二进制；encoding 选项无效（19.3） |
| pread 移动偏移 | Windows/OTP29 实测会动，别依赖（19.4） |
| binary_to_term 不可信输入 | 会创建原子（DoS）——加 `[safe]`（19.7） |
| timer:cancel 判断成功 | 永远 {ok,cancel}——用 erlang:cancel_timer（20.3） |

## 12. 测试、日志与运维（21/22/23）

```erlang
-include_lib("eunit/include/eunit.hrl").
foo_test() -> ?assertEqual(Want, got()).          %% 常量断言会被 -Werror 点死
foo_table_test_() -> [fun() -> ... end || C <- Cases].   %% 表驱动生成器
{setup, Setup, Cleanup, fun(Ctx) -> [Test] end}.  %% instantiator 必须返回测试项
logger:set_primary_config(level, info).           %% 默认 notice！
?LOG_INFO("msg").                                 %% 宏才带 mfa（模块级只管宏）
sys:get_state(Name).  sys:replace_state(Name, F). sys:no_debug(Name).
?MODULE:loop(S).                                  %% 循环全限定调用，热升级才生效
```

| 坑 | 解法 |
|---|---|
| logger:info 看不见 | primary level 默认 notice（22.1） |
| 日志当审计数据 | 过载真的会丢（22.7） |
| fixture setup 不幂等 | 先 del_dir_r 再建；del_dir 只删空目录（21.4） |
| 改代码不生效 | 循环用了局部调用——`?MODULE:loop`（23.5） |
| code:purge 杀进程 | 先 soft_purge（23.5） |
| init_fail/2 老 API | 已变 (Ret,Exception)——用 /3（23.4 实测） |

## 13. 分布式、套接字与端口（25/26/27）

```erlang
{ok, P, N} = peer:start(#{name => ex_peer}).                 %% 自动连接父节点
{ok, P, N} = peer:start(#{name => X, connection => 0}).      %% TCP 控制：不自动连
rpc:call(N, M, F, A, 5000).                                 %% 第 5 参超时
spawn(N, Mod, Fun, Args).                                   %% 分布式 spawn
yes = rpc:call(N, global, register_name, [name, Pid]).
ok = global:sync().                                         %% 名字同步是异步的
true = erlang:set_cookie(Node, Cookie).

{ok, L} = gen_tcp:listen(0, [binary, {packet, 2}, {active, false}, {reuseaddr, true}]).
inet:setopts(S, [{active, once}]).                          %% 每包后双侧再武装
{ok, {Addr, Port, Data}} = gen_udp:recv(S, 0, 2400).        %% OTP29 扁平三元组
gen_udp:send(S, {127,0,0,1}, Port, Data).                   %% 未连接 socket 用 /4

Port_ = open_port({spawn_executable, Exe}, [binary, {packet, 2},
              {args, [Script]}, exit_status]).
%% escript 端口程序第一行：
ok = io:setopts(standard_io, [{binary, true}, {encoding, latin1}]).
```

| 坑 | 解法 |
|---|---|
| peer 生命周期绑父连接 | disconnect 杀死 peer——反复断连用 `connection => 0`（25.7） |
| peer_start 选项不存在 | 传 erl 参数用 `args => ["-eval", ...]`（25.9） |
| peer 的 logger 声明失效 | `level => none` 是**全放行**不是全静音——`remove_handler(default)`（25.9） |
| 失配握手 ERROR REPORT | ERTS 层带时间戳，摘 handler 拦不住——别触发真实失配握手（25.6） |
| global:register_name 返回 | yes 不是 true；查名前先 global:sync()（25.5） |
| gen_udp:recv 形状 | OTP29 扁平 `{Addr,Port,Packet}`——老书 `{Addr,Port},Packet` badmatch（26.5） |
| gen_udp:send/3 badarg | 未连接 socket 用 send/4；地址写 {127,0,0,1} 防 v6 解析（26.5） |
| active once 单侧武装 | 服务器与客户端每条消息后都要再 setopts（26.3） |
| escript 端口透传 | 不 setopts 则 unicode→latin1 转译崩：binary+latin1 双保险（27.3） |
| {packet,N} 双重成帧 | command 发裸载荷——帧由驱动管（27.2） |
| escript 异常栈进 stderr | 崩溃演示自捕异常后 halt(1)（27.4） |

## 14. 持久化与行为补全（28/29）

```erlang
{ok, R} = dets:open_file(n, [{file, F}, {type, set}]).
dets:info(R, size).                                   %% no_items 是 undefined！
lists:sort(dets:foldl(fun (O, Acc) -> [O|Acc] end, [], R)).

ok = application:set_env(mnesia, dir, Dir).           %% 先于 create_schema
ok = mnesia:create_schema([node()]), ok = mnesia:start().
{atomic, R} = mnesia:transaction(fun () -> ... end).  %% fun 无副作用
mnesia:dirty_index_read(T, V, Attr).                  %% 事务外用 dirty 版

{ok, M} = gen_event:start().
ok = gen_event:swap_handler(M, {H1, []}, {H2, []}).   %% OTP29 是 /3
%% gen_statem: state_timeout 事件类型就叫 state_timeout
```

| 坑 | 解法 |
|---|---|
| dets 文件跨运行累积 | 测试/演示每次清沙箱或删文件（28.2） |
| mnesia dir 时序 | set_env 必须在 create_schema 之前（28.3） |
| mnesia 启停 INFO REPORT | 首行 logger:remove_handler(default)（28.3） |
| index_read 事务外 | 直接 exit({aborted,no_transaction})——外面用 dirty_index_read（28.3） |
| dets 错误带绝对路径 | 打印只留标签 not_a_dets_file（28.2） |
| gen_event code_change 是 /3 | gen_server/gen_statem 才是 /4（29.5） |
| swap_handler 老书 /4 | OTP29 是 /3；携带值走 terminate→init({Args2,Term})（29.3） |
| state_timeout 写成 timeout | function_clause 崩掉状态机（29.4） |
| handler 崩溃摘除异步 | notify 后 sleep 一拍再断言 which_handlers（29.2） |

## 15. 剖析、多核与收官（30/31/32）

```erlang
{Micros, V} = timer:tc(M, F, A).        %% 时间只断言 >= 0（Windows 可量出 0）
cprof:start(), ... , cprof:analyse(M).  %% 计数确定可打印；用完 cprof:stop()
erlang:trace_pattern({M, '_', '_'}, true, [local]).   %% 返回匹配数
erlang:trace(self(), true, [call, arity, {tracer, Tracer}]).
%% pmap 无序收齐 sort；有序带序号；pmmap：deadline+杀+drain 三步曲
%% ~p 打整数列表会变字符串：[44,41] -> ",)"——装元组
```

| 坑 | 解法 |
|---|---|
| cprof:analyse 嵌套形状 | {Mod,数,[{FA,数}]}——别当扁平表 keysort（30.2） |
| trace_pattern 返回值 | 匹配到的函数个数，不是 1（30.3） |
| arity 旗标位置 | trace/3 的裸原子，不是元组/不是 pattern 选项（30.3） |
| trace 本地调用 | pattern 要 [local]，默认只抓外部调用（30.3） |
| pmmap 孤儿消息 | 杀 worker 后 drain，否则污染后续 receive（31.3） |
| 时间数字进输出 | 第 4 层挂——计数/结果/布尔才可打印（30/31 通例） |
| 串接字符串缺句号 | 多行 "..." 拼接最后要有 .——报错在下一函数头上（32.7） |
| 模式里取负 | {-C, W} 非法——排序用元组、还原再取负（32.6） |
