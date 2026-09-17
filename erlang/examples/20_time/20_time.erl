%% ---------------------------------------------------------------------------
%%  20_time —— 定时器、时间与系统限制
%%
%%  编译：erlc -Werror -Wall -o build/20_time examples/20_time.erl
%%  运行：erl -noshell -pa build/20_time -run '20_time' main -s init stop
%%
%%  这一章讲三件事：
%%    1. 「等一会儿」有几种写法，它们**不是**一回事；
%%    2. 时间怎么量 —— 墙钟会跳，单调钟不会，但单调钟可能是负数；
%%    3. 这台虚拟机到底能撑多少进程/原子/表，以及哪些边界会真的炸。
%%
%%  所有和时间有关的断言都写成「范围 / 布尔」而不是具体数值 ——
%%  具体毫秒数在两台机器、两次运行之间一定不一样。
%% ---------------------------------------------------------------------------
-module('20_time').

-export([main/0, opaque/1]).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

main() ->
    _ = logger:remove_handler(default),
    io:format("=== 26) 定时器、时间与系统限制 ===~n"),
    three_ways(),
    cancel_and_read(),
    who_runs_the_timer(),
    timeout_values(),
    clock_kinds(),
    system_limits(),
    integer_and_float_edges(),
    memory_and_gc(),
    mistakes(),
    io:format("==== 20 结束 ====~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 1) 三种「等一会儿」
%% ---------------------------------------------------------------------------
three_ways() ->
    io:format("~n== 1) 三种定时机制 ==~n"),
    io:format("  它们都能\"过一会儿收到点什么\"，但代价和语义完全不同。~n~n"),

    io:format("  (a) receive ... after —— 最轻，但它是**接收的一部分**~n"),
    AfterResult = receive nothing_ever_arrives -> got_it after 20 -> timed_out end,
    d("receive 一个不会来的消息，after 20 毫秒", AfterResult),
    io:format("  注意：after 的计时是**这次 receive 专属**的，~n"),
    io:format("  一旦超时分支执行完就结束了；想循环等就得自己写递归。~n~n"),

    io:format("  (b) erlang:send_after/3 —— 由虚拟机管，不占进程~n"),
    Ref = erlang:send_after(20, self(), {from, send_after}),
    d("返回值是引用吗", is_reference(Ref)),
    d("等着收（最多 2 秒）", wait_for({from, send_after}, 2000)),

    io:format("~n  (c) erlang:start_timer/3 —— 消息形状固定是 {timeout, Ref, Msg}~n"),
    TRef = erlang:start_timer(20, self(), payload),
    d("收到的是", wait_start_timer(TRef, 2000)),
    io:format("  区别：send_after 把你的消息**原样**投递，start_timer 包一层 {timeout, Ref, Msg}。~n"),
    io:format("  带 Ref 的好处：能区分\"这次的超时\"和\"上次的迟到回复\"（19 章讲过）。~n~n"),

    io:format("  (d) timer 模块 —— stdlib 的，背后**有一个进程**~n"),
    {ok, TMod} = timer:send_after(20, self(), {from, timer_mod}),
    d("timer:send_after 返回值的形状", tref_shape(TMod)),
    d("等着收", wait_for({from, timer_mod}, 2000)),
    d("只发到本地 pid 的话，timer_server **根本没启动**",
      is_pid(whereis(timer_server))),
    io:format("  （下一节专门讲这个：老教程说\"timer 模块全靠一个 timer_server 进程\"，~n"),
    io:format("   OTP 27 之后只对一部分调用成立。）~n"),
    d("timer:sleep(10) 的返回值", timer:sleep(10)),
    d("timer:seconds(1) / minutes(1) / hms(1,2,3)",
      {timer:seconds(1), timer:minutes(1), timer:hms(1, 2, 3)}),
    ok.

wait_for(Msg, Timeout) ->
    receive Msg -> got_it after Timeout -> timed_out end.

wait_start_timer(Ref, Timeout) ->
    receive
        {timeout, Ref, Payload} -> {timeout, '<Ref>', Payload}
    after Timeout ->
        timed_out
    end.

%% ---------------------------------------------------------------------------
%% 2) 取消与查询剩余时间
%% ---------------------------------------------------------------------------
cancel_and_read() ->
    io:format("~n== 2) 取消与查询剩余时间 ==~n"),
    TRef = erlang:start_timer(30000, self(), far_away),
    Left = erlang:read_timer(TRef),
    d("read_timer 一个还早的定时器（返回剩余毫秒）", {is_integer(Left), Left > 0}),

    Left2 = erlang:read_timer(TRef),
    d("  再读一次（只会**变少**，不会变多）", Left2 =< Left),

    Cancelled = erlang:cancel_timer(TRef),
    d("cancel_timer 返回剩余毫秒", {is_integer(Cancelled), Cancelled >= 0}),
    d("  再 cancel 一次（已经没了 → false）", erlang:cancel_timer(TRef)),
    d("  再 read_timer（false）", erlang:read_timer(TRef)),

    io:format("~n  -- 已经触发过的定时器 --~n"),
    Fired = erlang:start_timer(10, self(), now_now),
    receive {timeout, Fired, now_now} -> ok after 2000 -> ok end,
    d("cancel 一个**已经触发**的（false，不是剩余 0）", erlang:cancel_timer(Fired)),
    d("  read_timer 也已经 false", erlang:read_timer(Fired)),

    io:format("~n  注意：cancel_timer **保证**消息不会再来，但**不保证**它还没在邮箱里。~n"),
    io:format("  如果定时器已经触发、消息已经投递，你得自己把它从邮箱清掉：~n"),
    Late = erlang:start_timer(10, self(), late_msg),
    receive {timeout, Late, late_msg} -> ok after 2000 -> ok end,
    _ = erlang:cancel_timer(Late),
    d("  清一下邮箱里可能残留的", flush_one({timeout, Late, late_msg})),
    ok.

flush_one(Msg) ->
    receive Msg -> drained
    after 0 -> nothing_there
    end.

%% ---------------------------------------------------------------------------
%% 3) 谁在管这个定时器：timer 模块 vs erlang:send_after
%% ---------------------------------------------------------------------------
who_runs_the_timer() ->
    io:format("~n== 3) timer 模块的真相：它**不一定**经过 timer_server ==~n"),
    io:format("  老说法是\"timer 模块所有定时器都挤在 timer_server 一个进程里\"。~n"),
    io:format("  这在 OTP 27 之后**不成立了** —— 实测（OTP 29）：~n~n"),

    d("一开始 timer_server 存在吗", is_pid(whereis(timer_server))),
    {ok, TLocal} = timer:send_after(2000, self(), to_local_pid),
    d("timer:send_after 到**本地 pid** 的返回值", tref_shape(TLocal)),
    d("  之后 timer_server 启动了吗（**没有**）", is_pid(whereis(timer_server))),
    _ = timer:cancel(TLocal),

    register(timer_demo_dest, spawn(fun() -> receive _ -> ok end end)),
    {ok, TName} = timer:send_after(2000, timer_demo_dest, to_reg_name),
    d("timer:send_after 到**注册名**的返回值", tref_shape(TName)),
    d("  之后 timer_server 启动了吗（**启动了**）", is_pid(whereis(timer_server))),
    _ = timer:cancel(TName),

    {ok, TInterval} = timer:send_interval(2000, self(), tick),
    d("timer:send_interval 的返回值", tref_shape(TInterval)),
    _ = timer:cancel(TInterval),
    {ok, TInstant} = timer:send_after(0, self(), right_now),
    d("timer:send_after 时间给 0 的返回值", tref_shape(TInstant)),
    d("  消息是**立刻**投递的（不用等）",
      receive right_now -> delivered after 1000 -> lost end),

    io:format("~n  规律（对着 stdlib 源码确认的）：~n"),
    io:format("    · 发给**本地 pid** → 直接委托给 erlang:send_after，返回 {send_local, Ref}~n"),
    io:format("    · 发给**注册名 / 远端** → 得由服务进程代发，返回 {once, Ref}~n"),
    io:format("    · apply_after / exit_after / kill_after → {once, Ref}，需要服务进程~n"),
    io:format("    · send_interval → {interval, Ref}~n"),
    io:format("    · 时间为 0 → {instant, Ref}，立即投递，不走定时器~n"),

    io:format("~n  -- timer:cancel 与 erlang:cancel_timer 的差别 --~n"),
    d("timer:cancel 一个正常的 tref", timer:cancel(TLocal)),
    d("  再 cancel 一次（**还是** {ok, cancel}，不会告诉你已经没了）",
      timer:cancel(TLocal)),
    d("  对比：erlang:cancel_timer 第二次返回 false",
      begin
          R = erlang:send_after(2000, self(), zzz),
          _ = erlang:cancel_timer(R),
          erlang:cancel_timer(R)
      end),
    d("  timer:cancel 传一个裸 ref（返回 error 元组，不是抛）",
      timer:cancel(make_ref())),
    io:format("  结论：timer:cancel 的返回值**不能**用来判断\"到底取消成功没有\"。~n"),
    io:format("  真要精确控制（比如限流器），直接用 erlang:send_after + erlang:cancel_timer。~n"),
    ok.

%% tref 里含 ref，打印出来每次都不一样，只取其形状标签
tref_shape(TRef) -> element(1, TRef).

%% ---------------------------------------------------------------------------
%% 4) 超时值的合法范围
%% ---------------------------------------------------------------------------
timeout_values() ->
    io:format("~n== 4) 超时值：0、infinity、以及哪些值会炸 ==~n"),
    ZeroResult = receive never_arrives -> got after 0 -> immediate end,
    d("receive after 0（不等，直接走超时分支）", ZeroResult),
    d("send_after 时间给 0（几乎立刻投递）",
      begin
          R = erlang:send_after(0, self(), zero_msg),
          receive zero_msg -> delivered after 2000 -> lost end,
          erlang:cancel_timer(R),
          delivered
      end),
    d("send_after 负数",
      try erlang:send_after(-1, self(), x) of _ -> unexpected_ok
      catch error:R1 -> {error, R1} end),
    d("send_after 超大值（超过 2^64 毫秒）",
      try erlang:send_after(16#FFFFFFFFFFFFFFF, self(), x) of _ -> unexpected_ok
      catch error:R2 -> {error, R2} end),
    d("send_after 带一个不认识的选项",
      try erlang:send_after(10, self(), x, [{nonsense, true}]) of _ -> unexpected_ok
      catch error:R3 -> {error, R3} end),
    d("receive after 非法值（负数）",
      try (fun() -> receive q -> ok after -1 -> ok end end)() of _ -> unexpected_ok
      catch error:R4 -> {error, R4} end),
    io:format("  timeout_value 是**专门**给\"超时值不对\"的错误类，"
              "和 badarg 不一样，看到它就查超时参数。~n"),
    io:format("  infinity 是一个合法超时值（一直等），"
              "gen_server:call 不传超时默认就是 5000。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 5) 时间：墙钟 vs 单调钟
%% ---------------------------------------------------------------------------
clock_kinds() ->
    io:format("~n== 5) 时间：墙钟会跳，单调钟不会 ==~n"),
    io:format("  墙钟（system_time）：就是日历时间，NTP 校时、手动改表都会让它前后跳。~n"),
    io:format("  单调钟（monotonic_time）：保证只增不减，但**起点是任意的**。~n~n"),

    M1 = erlang:monotonic_time(),
    M2 = erlang:monotonic_time(),
    d("连续两次 monotonic_time，第二次不小于第一次", M2 >= M1),
    d("monotonic_time 一定 >= 0 吗（**不是**）", M1 >= 0),
    io:format("  所以：拿 monotonic_time 算**间隔**是对的，"
              "拿它当\"时间戳\"存起来是错的。~n~n"),

    d("system_time 是个正数（纳秒）", erlang:system_time() > 0),
    d("os:system_time 与 erlang:system_time 差不到 1 秒",
      abs(os:system_time(millisecond) - erlang:system_time(millisecond)) < 1000),
    d("time_offset 是个整数（墙钟 = 单调钟 + 偏移）", is_integer(erlang:time_offset())),
    d("convert_time_unit(1000, 微秒 → 纳秒)",
      erlang:convert_time_unit(1000, microsecond, nanosecond)),
    d("erlang:timestamp() 是个三元组（元/秒/微秒）", tuple_size(erlang:timestamp())),

    io:format("~n  -- 计时：timer:tc 还是 monotonic_time？ --~n"),
    {Us, Res} = timer:tc(fun() -> lists:sum(lists:seq(1, 100000)) end),
    d("timer:tc 的耗时（微秒，>0）", Us > 0),
    d("  它的返回值就是函数的返回值", Res),
    io:format("  timer:tc 内部用的是 os:timestamp（墙钟），"
              "跨 NTP 校时可能量出负数；~n"),
    io:format("  要准确测间隔，用 erlang:monotonic_time(0) 前后各取一次相减。~n"),
    Self = self(),
    _ = spawn(fun() -> T0 = erlang:monotonic_time(microsecond),
                       _ = lists:sum(lists:seq(1, 200000)),
                       T1 = erlang:monotonic_time(microsecond),
                       Self ! {elapsed_positive, T1 - T0 >= 0}
              end),
    d("monotonic_time 算出来的间隔 >= 0", receive {elapsed_positive, V} -> V after 3000 -> timeout end),
    ok.

%% ---------------------------------------------------------------------------
%% 6) 系统限制
%% ---------------------------------------------------------------------------
system_limits() ->
    io:format("~n== 6) 系统限制：这台虚拟机能撑多少东西 ==~n"),
    d("process_limit（进程数上限）", erlang:system_info(process_limit)),
    d("  当前进程数 > 0", erlang:system_info(process_count) > 0),
    d("ets_limit（ETS 表数上限，比进程小得多）", erlang:system_info(ets_limit)),
    io:format("  port_limit 的**具体数字会随环境变**：它是按进程能打开的文件描述符~n"),
    io:format("  上限算出来的，同一个仓库在不同 shell 里跑~n"),
    io:format("  都可能不一样（实测过 1048576 与 65536 两种情况）。所以这里只断言性质。~n"),
    d("  port_limit > 0", erlang:system_info(port_limit) > 0),
    d("  port_limit >= 当前 port 数", erlang:system_info(port_limit)
                                       >= erlang:system_info(port_count)),
    d("  atom_limit > 0", erlang:system_info(atom_limit) > 0),
    d("  当前原子数 > 0", erlang:system_info(atom_count) > 0),
    d("wordsize（一个字的字节数）", erlang:system_info(wordsize)),
    d("endian", erlang:system_info(endian)),
    d("system_architecture 里含 x86_64 吗",
      string:find(erlang:system_info(system_architecture), "x86_64") =/= nomatch),
    d("调度器个数 >= 1（具体几个随机器变，别写死）",
      erlang:system_info(schedulers_online) >= 1),
    d("smp_support", erlang:system_info(smp_support)),

    io:format("~n  -- 原子表：它会**一直涨**，而且不回收 --~n"),
    C0 = erlang:system_info(atom_count),
    [_ = list_to_atom("limits_probe_" ++ integer_to_list(N)) || N <- lists:seq(1, 200)],
    C1 = erlang:system_info(atom_count),
    d("造 200 个新原子后，原子数增加了", C1 - C0),
    d("  造过之后就能用 list_to_existing_atom 找到",
      list_to_existing_atom("limits_probe_1")),
    d("  找一个从没造过的（badarg）",
      try list_to_existing_atom("never_created_atom_zzz") of A -> {unexpected, A}
      catch error:R -> {error, R} end),
    io:format("  所以：绝不能拿**外部输入**（用户名、请求路径、MQ 主题）去 list_to_atom。~n"),
    io:format("  要查\"有没有这个原子\"用 list_to_existing_atom（不存在就 badarg，不会创建）。~n"),
    ok.

%% ---------------------------------------------------------------------------
%% 7) 整数与浮点的边界
%% ---------------------------------------------------------------------------
integer_and_float_edges() ->
    io:format("~n== 7) 数值边界：整数不会溢出，浮点会 ==~n"),
    d("1 bsl 1000 还是个整数（任意精度）", is_integer(1 bsl 1000)),
    d("  它是大整数（超过一个字）", (1 bsl 1000) > (1 bsl 59)),
    d("  (-1 bsl 100) + 1 也正常", is_integer((-1 bsl 100) + 1)),
    d("10 的 100 次方算得出来", is_integer(round(math:pow(10, 100)))),
    d("trunc(math:pow(10,100)) 和真值一样吗（**不**）",
      trunc(math:pow(10, 100)) =:= round(math:pow(10, 100))),

    io:format("~n  -- 浮点：溢出是 badarith，不是 inf --~n"),
    N = float(opaque(400)),
    d("math:pow(10, 400)",
      try math:pow(10, N) of V -> {unexpected, V}
      catch error:R1 -> {error, R1} end),
    d("1e308 * 10（连乘溢出）",
      try begin X = math:pow(10, 308), X * float(opaque(10)) end of V2 -> {unexpected, V2}
      catch error:R2 -> {error, R2} end),
    Neg = 0.0 - float(opaque(1)),
    d("math:sqrt(负数)（不是 nan，是 badarith）",
      try math:sqrt(Neg) of V3 -> {unexpected, V3}
      catch error:R3 -> {error, R3} end),
    io:format("  顺带：直接写 math:sqrt(-1.0) 会被 -Wall 在**编译期**判死"
              "（\"will fail with a badarith\"）。~n"),
    d("0.1 + 0.2 == 0.3 吗", 0.1 + 0.2 =:= 0.3),
    d("  差值", 0.1 + 0.2 - 0.3),
    io:format("  又一个**编译期**能抓到的：写 1.0e400 字面量直接 illegal float，~n"),
    io:format("  写 math:pow(10,400) 常量会被 -Wall 报 \"will fail with a badarith\"。~n"),
    io:format("  → 想演示运行期错误，值必须来自参数（这里的 opaque/1）。~n"),
    ok.

%% 编译期算不出来的「不透明」值
opaque(N) -> length(lists:seq(1, N)).

%% ---------------------------------------------------------------------------
%% 8) 内存与 GC
%% ---------------------------------------------------------------------------
memory_and_gc() ->
    io:format("~n== 8) 观测内存与 GC ==~n"),
    d("erlang:memory() 的键（排序后）",
      lists:sort([K || {K, _} <- erlang:memory()])),
    d("  total > 0", erlang:memory(total) > 0),
    d("  processes > 0", erlang:memory(processes) > 0),
    d("  atom_used <= atom", erlang:memory(atom_used) =< erlang:memory(atom)),

    {_, Heap0} = process_info(self(), heap_size),
    _ = lists:seq(1, 200000),
    {_, Heap1} = process_info(self(), heap_size),
    d("造一个 20 万元素的列表后 heap_size 变了",
      {Heap1 =/= Heap0, Heap1 > 0}),
    d("process_info 里有 garbage_collection 这一项",
      lists:member(garbage_collection, [K || {K, _} <- process_info(self())])),
    d("主动 erlang:garbage_collect()", erlang:garbage_collect()),

    d("message_queue_len（当前邮箱里的消息数）",
      element(2, process_info(self(), message_queue_len))),
    d("reductions（已经执行了多少\"步\"）",
      element(2, process_info(self(), reductions)) > 0),
    P = spawn(fun() -> ok end),
    timer:sleep(20),
    d("process_info 一个已经死的进程 → undefined", process_info(P, heap_size)),
    ok.

%% ---------------------------------------------------------------------------
%% 9) 常见错误清单
%% ---------------------------------------------------------------------------
mistakes() ->
    io:format("~n== 9) 常见错误清单 ==~n"),
    Rows =
     [{"拿外部输入做 list_to_atom", "原子表一直涨，直到节点被杀",
       "用 list_to_existing_atom，或者先自己白名单校验"},
      {"把 monotonic_time 当时间戳存", "起点任意，甚至可能是负数",
       "只用它算间隔；存时间用 system_time / os:system_time"},
      {"用墙钟测间隔", "NTP 校时会让间隔变成负数",
       "erlang:monotonic_time(0) 前后相减，或 erlang:statistics(runtime)"},
      {"cancel_timer 之后以为邮箱干净了", "消息可能已经投递",
       "cancel 之后再用 receive ... after 0 清一次"},
      {"大量定时器全用 timer 模块", "都挤在一个 timer_server 进程里",
       "高频/大量用 erlang:send_after；timer 模块只做偶发的一次性任务"},
      {"receive after 一个变量", "变量是负数时抛 timeout_value",
       "超时值也要防御性检查"},
      {"以为 ETS 表数和进程数一样多", "ets_limit 默认只有几千（本机 8192）",
       "要建很多表就 +e 调，或者复用表"},
      {"用 float 存金额", "0.1 + 0.2 /= 0.3",
       "用整数（分）或专门的十进制库"},
      {"以为浮点溢出得到 infinity", "实际抛 badarith",
       "涉及大数就用整数，别用 float"},
      {"process_info 一个未知进程", "返回 undefined，不是崩溃",
       "判断返回值，别直接 element(2, ...)"}],
    [begin
         io:format("  ~ts~n", [What]),
         io:format("      现象：~ts~n", [Sym]),
         io:format("      处理：~ts~n", [Fix])
     end || {What, Sym, Fix} <- Rows],
    ok.

