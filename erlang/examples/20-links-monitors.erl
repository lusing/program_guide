%% ============================================================
%% 20 - 链接、监控与 exit 信号
%%
%%    进程隔离带来一个问题：别人死了我怎么知道？反过来，我死了别人怎么办？
%%    Erlang 给了两套机制：
%%      link     双向。A link B 之后，谁死都会给对方发一个 exit 信号；
%%               对方没开 trap_exit 就会被**一起杀掉**。
%%      monitor  单向。A monitor B 之后，B 死了只给 A 一条 DOWN 消息，
%%               A 完全不受影响。
%%    容错的基石就在这：**让失控的进程死掉，由外部（监督者）收拾现场**。
%%
%%    本示例全程在 trap_exit = true 下运行（否则被 link 的那些「故意崩掉的
%%    进程」会把主进程一起带走）；结束时再还原 —— 这个「改了就还原」的
%%    习惯很重要，忘了还原会让后面的崩溃静默地变成一个消息。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/20-links-monitors.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '20-links-monitors' main -s init stop
%% ============================================================
-module('20-links-monitors').

-export([main/0, crash_with/1, quietly_exit/1, normal_end/0, tag_of/1]).

main() ->
    %% 默认 logger handler 会把 error 类的进程崩溃**异步**打到 stdout，
    %% 带时间戳和 pid（见第 15 章实测）。本示例要可重复输出，先摘掉它；
    %% 想看那些报告就注释掉这行，或看第 27 章怎么用自定义 handler 收日志。
    _ = logger:remove_handler(default),

    %% 实测一个反直觉的事实：**由 `erl -run` 启动的这个进程，
    %% trap_exit 本来就是 true**（不是 false）。所以下面那些故意崩掉的
    %% 被 link 的进程不会把主进程带走；而自己 spawn 出来的进程默认是 false。
    d("本进程（erl -run 启动）的 trap_exit",
      element(2, process_info(self(), trap_exit))),
    Self = self(),
    R0 = make_ref(),
    spawn(fun() -> Self ! {R0, element(2, process_info(self(), trap_exit))} end),
    d("新 spawn 的进程默认 trap_exit",
      receive {R0, V0} -> V0 after 1000 -> timeout end),

    %% trap_exit 开关是**进程属性**，process_flag/2 返回改动前的值，
    %% 所以标准写法是「先存旧值，用完还原」。
    Old = process_flag(trap_exit, true),
    io:format("原 trap_exit = ~p，已强制改为 true~n", [Old]),

    link_vs_monitor(),
    exit_message_shape(),
    kill_is_untrappable(),
    waiting_for_many(),
    no_trap_means_die(),
    why_supervision(),

    process_flag(trap_exit, Old),
    d("还原后的 trap_exit（用 process_info 读回来确认）",
      element(2, process_info(self(), trap_exit))),
    io:format("~n==== 20 结束 ====~n").

%% 给各个实验用的「会崩的进程」
crash_with(error_class) -> erlang:error(boom);
crash_with(exit_plain)  -> exit(reason_x);
crash_with(nocatch)     -> throw(tossed).

quietly_exit(Reason) -> exit(Reason).

normal_end() -> normal.

%% 1) link 与 monitor：一个是双向，一个是单向
%% ------------------------------------------------------------
link_vs_monitor() ->
    io:format("~n== 1) link（双向）与 monitor（单向） ==~n"),
    %% monitor：目标崩了，我收到 DOWN 消息，我照常活着
    {Pid1, MRef} = spawn_monitor(fun() -> crash_with(error_class) end),
    d("monitor 一个会崩的进程，收到 DOWN 的原因标签",
      receive {'DOWN', MRef, process, _, R1} -> tag_of(R1) after 2000 -> timeout end),
    d("我还活着吗（monitor 不影响调用者）", is_process_alive(self())),
    _ = Pid1,
    %% link：目标崩了，exit 信号传给链接方。
    %% 因为开了 trap_exit，它变成一条 {'EXIT', Pid, Reason} 消息，而不是杀掉我。
    Pid2 = spawn_link(fun() -> crash_with(error_class) end),
    d("link 一个会崩的进程，收到 EXIT 消息",
      receive {'EXIT', P2, R2} when P2 =:= Pid2 -> tag_of(R2) after 2000 -> timeout end),
    d("它已经死了吗 / 我还活着吗", {is_process_alive(Pid2), is_process_alive(self())}),
    %% 注意：带中文/箭头等非 latin1 字符的字符串用 ~p 打印会变成一串整数
    %% （~p 只对「可打印的 latin1 字符列表」做字符串美化），所以要逐条用 ~ts 打。
    io:format("  ~ts~n", ["monitor 的消息：{'DOWN', Ref, process, Pid, Reason}"]),
    io:format("  ~ts~n", ["link 的消息：   {'EXIT', Pid, Reason}（仅 trap_exit 时才变成消息）"]),
    ok.

%% 2) exit 信号的 reason 形状
%% ------------------------------------------------------------
%% 关键实测结论：
%%   error 类崩溃 → 消息里的 Reason 是 {Reason0, Stacktrace}（**带栈**）
%%   exit(R)      → 原样就是 R
%%   throw 未捕获 → {nocatch, Value}
%% 只有 error 类能拿到栈，所以「崩溃日志里能看到出错位置」只对 error 类成立。
exit_message_shape() ->
    io:format("~n== 2) exit 消息里的 reason 形状 ==~n"),
    d("error 类：reason 是 {原因, 栈}（下面只汇总标签与「栈非空」）",
      exit_of(fun() -> crash_with(error_class) end)),
    d("exit(R)：reason 就是 R", exit_of(fun() -> crash_with(exit_plain) end)),
    d("throw 未捕获：{nocatch, Value}",
      exit_of(fun() -> crash_with(nocatch) end)),
    d("正常结束：normal", exit_of(fun() -> normal_end() end)),
    ok.

%% 起一个链接着的进程，看它的终止原因长什么样（只汇总，不打印 pid）
exit_of(F) ->
    Pid = spawn_link(F),
    receive
        {'EXIT', P, Reason} when P =:= Pid -> tag_of(Reason)
    after 2000 -> timeout
    end.

%% 3) exit(Pid, kill)：唯一不可捕获的终止方式
%% ------------------------------------------------------------
%%   exit(Pid, R)  R 不是 kill 时：对方如果开了 trap_exit，会收到
%%                {'EXIT', ...} 消息而**继续活着**（它可以不理会）；
%%                没开 trap_exit 就被杀，终止原因就是 R。
%%   exit(Pid, kill) 则无论对方怎么设置都必死，终止原因是 killed，
%%                而且**对方不会有任何机会处理**（不能用来做优雅停止）。
%% 所以：kill 是「兜底弄死」，shutdown 才是「请你体面地停」。
kill_is_untrappable() ->
    io:format("~n== 3) exit(Pid, kill) 不可捕获 ==~n"),
    Owner = self(),
    %% 目标进程开了 trap_exit：普通 exit 信号打不死它。
    %% 它先回一条 ready，确保「trap_exit 已经生效」再受信号 ——
    %% 用 sleep 等就变成了靠时序假设，靠消息握手才是确定的。
    T1 = spawn(fun() -> trap_target(Owner) end),
    receive {ready, P1} when P1 =:= T1 -> d("目标已就绪（trap_exit 已开）", ok)
    after 2000 -> d("目标就绪握手", timeout)
    end,
    MRef1 = erlang:monitor(process, T1),
    exit(T1, please_stop),
    d("开了 trap_exit 的目标：普通 exit 信号被它处理掉了，终止原因是",
      receive {'DOWN', MRef1, process, _, R1} -> R1 after 2000 -> timeout end),

    %% 同一个目标，这次用 kill
    T2 = spawn(fun() -> trap_target(Owner) end),
    receive {ready, P2} when P2 =:= T2 -> ok after 2000 -> ok end,
    MRef2 = erlang:monitor(process, T2),
    exit(T2, kill),
    d("同一个目标改用 kill：照样死，且原因是",
      receive {'DOWN', MRef2, process, _, R2} -> R2 after 2000 -> timeout end),
    ok.

%% 开了 trap_exit 的「硬骨头」目标：把收到的 exit 信号当消息处理
trap_target(Owner) ->
    process_flag(trap_exit, true),
    Owner ! {ready, self()},
    receive
        {'EXIT', _, _} -> exit(handled_exit_message)
    end.

%% 4) 用 monitor 等一批进程结束
%% ------------------------------------------------------------
%% 这是手写并发最常见的需求：起了 N 个工人，等它们全干完再汇总。
%% 正确做法是 monitor + 按 Ref 收 DOWN（不能靠进程数，也不能靠顺序）。
waiting_for_many() ->
    io:format("~n== 4) 等一批进程结束 ==~n"),
    Jobs = [{normal, 1}, {normal, 2}, {crash, 3}],
    Refs = [begin
                {_P, R} = spawn_monitor(fun() ->
                                               case Kind of
                                                   normal -> quietly_exit(normal);
                                                   crash -> crash_with(error_class)
                                               end
                                       end),
                R
            end || {Kind, _} <- Jobs],
    Reasons = [receive {'DOWN', R, process, _, Reason} -> tag_of(Reason)
               after 2000 -> timeout
               end || R <- Refs],
    d("三个工人的结束原因（按提交顺序）", Reasons),
    d("正常结束的个数", length([x || R <- Reasons, R =:= normal])),
    d("崩掉的个数", length([x || R <- Reasons, R =/= normal])),
    ok.

%% 5) 不开 trap_exit 会怎样：被链接的进程崩了，自己也死
%% ------------------------------------------------------------
%% 想在同一个进程里「演示自己被杀」是做不到的 —— 死了就没法再打印。
%% 所以换个可观察的写法：让一个**中间进程**去 link 一个会崩的进程，
%% 再从外面 monitor 这个中间进程，看它是被带崩的。
no_trap_means_die() ->
    io:format("~n== 5) 没有 trap_exit 时，链接的崩溃会传染 ==~n"),
    Victim = spawn(fun() ->
                           %% 这个进程**没有**开 trap_exit
                           process_flag(trap_exit, false),
                           _Child = spawn_link(fun() -> crash_with(error_class) end),
                           %% 等被杀；如果侥幸没被杀，就报告还活着
                           timer:sleep(500),
                           exit(survived)
                   end),
    MRef = erlang:monitor(process, Victim),
    d("被链接的进程崩了，链接方自己的终止原因",
      receive {'DOWN', MRef, process, _, R} -> tag_of(R) after 2000 -> timeout end),
    io:format("  ~ts~n", ["（如果链接方开了 trap_exit，它就会活下来并收到 EXIT 消息 ——"]),
    io:format("  ~ts~n", ["  这是监督树能存在的前提。）"]),
    ok.

%% 6) 为什么需要监督树
%% ------------------------------------------------------------
why_supervision() ->
    io:format("~n== 6) 手写这套东西为什么不够 ==~n"),
    Tips = [{"我崩了要重启", "谁负责重启？重启几次？太频繁要不要放弃？"},
            {"我崩了要通知别人", "通知谁？通知完对方该做什么？"},
            {"启动顺序有依赖", "数据库没起来时，缓存进程该不该启动？"},
            {"关闭顺序有依赖", "关的时候谁先谁后？关不掉怎么办？"}],
    [io:format("  ~ts~n", ["· " ++ A ++ " → " ++ B]) || {A, B} <- Tips],
    io:format("  ~ts~n", [""]),
    io:format("  ~ts~n", ["这些问题的答案就是 OTP 的 supervisor 与 application 替你想好的："]),
    io:format("  ~ts~n", ["  第 21 章 gen_server、第 22 章 supervisor、第 23 章 application。"]),
    ok.

%% 只保留 reason 的「标签」，丢掉 pid 与栈里的地址/行号。
%% 栈里的 {file, ...} 和 {line, ...} 会随源码改动变化，不能直接打进输出。
tag_of({Reason, Stack}) when is_list(Stack) -> {crashed, Reason, stack_non_empty, Stack =/= []};
tag_of(R) -> R.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
