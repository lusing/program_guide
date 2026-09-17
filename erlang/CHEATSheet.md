# Erlang/OTP 29 速查表

一页纸放下 24 章的常用语法与命令；`N.M` = 第 N 章 M 节，详细讲解见对应章（02–24 章都有可跑示例）。

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
