%% ============================================================
%% 19 - 消息传递与协议设计
%%
%%    进程之间只能靠消息通信，而消息是**异步、无类型、无顺序保证**的。
%%    这一章讲怎么在这之上做出可靠的请求-响应协议：
%%      · 邮箱语义（消息一直留着，直到被取走）
%%      · 为什么每个请求必须带一个 ref
%%      · 超时之后「迟到的回复」怎么处理
%%      · 选择性接收的代价，以及邮箱会怎样悄悄涨大
%%
%%    本章结论全部与调度无关：不用「谁先谁后」当结论，而是用
%%    「读到的配对结果」「邮箱长度」这类确定值。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/19-messaging.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '19-messaging' main -s init stop
%% ============================================================
-module('19-messaging').

-export([main/0, out_of_order_service/1, flush/1, counter_loop/1]).

main() ->
    mailbox_semantics(),
    send_to_dead_process(),
    protocol_shape(),
    out_of_order(),
    timeout_and_late_reply(),
    selective_receive_cost(),
    counter_service(),
    io:format("~n==== 19 结束 ====~n").

%% 1) 邮箱语义
%% ------------------------------------------------------------
%% `Pid ! Msg` 的语义（违反直觉的地方最多，逐条记）：
%%   * 永不阻塞、永不失败 —— 目标进程死了也照样返回 Msg
%%   * 消息进的是**对方的邮箱**；对方什么时候取、取不取，你管不着
%%   * 对方只取「匹配自己 receive 模式」的消息，不匹配的**留在邮箱里**
%%   * 所以邮箱是个队列，可能无限增长
%%   * 但「同一个发送者 → 同一个接收者」的消息顺序是有保证的（FIFO）
mailbox_semantics() ->
    io:format("== 1) 邮箱语义 ==~n"),
    Self = self(),
    d("发送前 message_queue_len", queue_len()),
    %% 往自己邮箱塞三条，其中一条故意不匹配
    Self ! {tag, 1},
    Self ! other,
    Self ! {tag, 2},
    d("塞完三条后 message_queue_len", queue_len()),
    d("只取匹配 {tag,_} 的第一条", receive {tag, X} -> X after 0 -> none end),
    d("不匹配的 other 还留着 → message_queue_len", queue_len()),
    d("再取一条 {tag,_}", receive {tag, Y} -> Y after 0 -> none end),
    d("现在只剩 other → message_queue_len", queue_len()),
    d("把剩下的 other 取掉", receive other -> picked after 0 -> none end),
    d("邮箱清空后 message_queue_len", queue_len()),
    %% 顺序保证：同一个发送者到同一个接收者，消息按发送顺序到达。
    %% 这里用一个带超时的 pull/0 而不是裸 receive —— 万一邮箱是空的，
    %% 裸 receive 会**永久阻塞**（示例就挂住了），带 after 才敢写。
    Self ! a, Self ! b, Self ! c,
    d("同一发送者的消息按发送顺序到达", {pull(), pull(), pull()}),
    d("取完三条后 message_queue_len", queue_len()),
    ok.

pull() -> receive X -> X after 1000 -> timeout end.

queue_len() -> element(2, process_info(self(), message_queue_len)).

%% 2) 发给已死进程：静默丢弃
%% ------------------------------------------------------------
%% `!` 不会因为目标死了而失败（并发进程随时可能死，这是有意的设计）。
%% 但它意味着「我发出去了」绝不等于「对方收到了」——
%% 要确认就得让对方回一条消息，或者 monitor 它。
send_to_dead_process() ->
    io:format("~n== 2) 发给已死进程 ==~n"),
    {Pid, MRef} = spawn_monitor(fun() -> ok end),
    receive {'DOWN', MRef, process, _, R} -> d("目标进程已结束，原因", R) after 2000 -> ok end,
    d("它还活着吗", is_process_alive(Pid)),
    d("往它发消息的返回值（就是被发的那个值，没有报错）", Pid ! hello_dead),
    d("发送后依然没有异常，本进程邮箱长度", queue_len()),
    ok.

%% 3) 一条协议的三种消息
%% ------------------------------------------------------------
%% 约定俗成的三种形状（gen_server 就是按这三种设计的，见第 21 章）：
%%   call   {From, Ref, Request}    →  请求；对方必须回 {Ref, Reply}
%%   cast   Request（不带 From/Ref）  →  单向通知，对方不回
%%   reply  {Ref, Reply}            →  回复，靠 Ref 对上号
%% 唯一要点：**回复里必须带回 Ref**，否则调用方无法在乱序、超时、
%% 并发多个请求的情况下确定这条回复是谁的。
protocol_shape() ->
    io:format("~n== 3) 一条协议的三种消息 ==~n"),
    %% 前三列故意用 ASCII：~-18ts 的宽度是按**字符数**算的，中文一个字占两列，
    %% 混用会让表格错位（第 13 章有按显示宽度补空格的写法）。
    Rows = [{"call", "{From, Ref, Request}", "请求；对方必须回 {Ref, Reply}"},
            {"cast", "Request", "单向通知，对方不回，发送方也不等"},
            {"reply", "{Ref, Reply}", "由 call 的接收方发出，靠 Ref 对上号"}],
    io:format("~n"),
    [io:format("  ~-8ts ~-22ts ~ts~n", [A, B, C]) || {A, B, C} <- Rows],
    io:format("  ~ts~n", ["注意：Erlang 不检查消息内容，协议只是「约定」。"]),
    io:format("  ~ts~n", ["      用错了形状不会报错，只会让 receive 一直等（然后超时）。"]),
    ok.

%% 4) 实测：不带 ref 的协议会被乱序回复搞错
%% ------------------------------------------------------------
%% 这个服务故意「先回复第二条请求」——现实中的服务因为并发处理、
%% 或者只是调度，回复顺序本来就不保证。
out_of_order_service(Owner) ->
    receive
        {Owner, TagA, A} ->
            receive
                {Owner, TagB, B} ->
                    Owner ! {reply, TagB, B},
                    Owner ! {reply, TagA, A}
            after 2000 -> ok
            end
    after 2000 -> ok
    end.

out_of_order() ->
    io:format("~n== 4) 实测：不带 ref 的协议会被乱序回复搞错 ==~n"),
    Owner = self(),
    %% 注意：self() 必须在 spawn 之前取，否则拿到的是子进程自己的 pid
    Svc1 = spawn(fun() -> out_of_order_service(Owner) end),
    %% --- 朴素协议：请求不带 ref，只能按「谁先到」对应 ---
    ReqA = {a_request, 111},
    ReqB = {b_request, 222},
    Svc1 ! {Owner, ReqA, ReqA},
    Svc1 ! {Owner, ReqB, ReqB},
    R1 = receive {reply, _, V1} -> V1 after 2000 -> timeout end,
    R2 = receive {reply, _, V2} -> V2 after 2000 -> timeout end,
    d("朴素协议：调用方以为第一条回复属于 a_request", R1),
    d("朴素协议：以为第二条属于 b_request", R2),
    io:format("  ~ts~n", ["（上面读到的其实是 b 的回复和 a 的回复 —— 配对错了）"]),

    %% --- 正确协议：请求带 ref，回复带回 ref ---
    Svc2 = spawn(fun() -> out_of_order_service(Owner) end),
    RefA = make_ref(),
    RefB = make_ref(),
    Svc2 ! {Owner, RefA, {a_request, 111}},
    Svc2 ! {Owner, RefB, {b_request, 222}},
    GotA = receive {reply, RefA, VA} -> VA after 2000 -> timeout end,
    GotB = receive {reply, RefB, VB} -> VB after 2000 -> timeout end,
    d("带 ref：a_request 的回复（即使它后到）", GotA),
    d("带 ref：b_request 的回复（即使它先到）", GotB),
    ok.

%% 5) 超时与迟到的回复
%% ------------------------------------------------------------
%% 超时之后只有两条路，**没有第三条**：
%%   A. 用 ref 精确 flush 掉那条迟到回复（本节演示），然后可以安全重试；
%%   B. 认为这一层协议已经不可信，直接让它崩（多数情况更简单，第 22 章）。
%% 千万不要「超时就当没发生、接着读邮箱」—— 迟到的回复会被下一条 receive
%% 当成新回复读进来，这就是最典型的消息错配 bug。
timeout_and_late_reply() ->
    io:format("~n== 5) 超时与迟到的回复 ==~n"),
    Owner = self(),
    %% 一个「回复来得很晚」的服务：收到就睡 300ms 再回
    Slow = spawn(fun() ->
                         receive
                             {O, Tag, V} ->
                                 timer:sleep(300),
                                 O ! {reply, Tag, V}
                         after 2000 -> ok
                         end
                 end),
    Ref = make_ref(),
    Slow ! {Owner, Ref, slow_value},
    d("只等 50ms → 超时",
      receive {reply, Ref, V} -> V after 50 -> timeout end),
    %% 等到那条迟到的回复真的进了邮箱
    timer:sleep(500),
    d("迟到回复已在邮箱里（message_queue_len）", queue_len()),
    flush(Ref),
    d("flush(Ref) 之后还能读到它吗",
      receive {reply, Ref, _} -> still_there after 0 -> clean end),
    d("邮箱长度回到", queue_len()),
    %% 换新 ref 重试是安全的：不可能把上一次的回复当成这一次的
    Fast = spawn(fun() -> receive {O2, T2, V2} -> O2 ! {reply, T2, V2} end end),
    Ref2 = make_ref(),
    Fast ! {Owner, Ref2, ok_value},
    d("换新 ref 重试的结果",
      receive {reply, Ref2, V3} -> V3 after 2000 -> timeout end),
    ok.

%% 只清掉「这个 ref 对应的回复」，不碰邮箱里的其它消息。
%% after 0 保证「没有就立刻返回」，不会阻塞。
flush(Ref) ->
    receive
        {reply, Ref, _} -> flush(Ref)
    after 0 -> ok
    end.

%% 6) 选择性接收的代价：不匹配的消息会一直堆着
%% ------------------------------------------------------------
%% receive 的匹配方式是「从邮箱头部往后找第一条匹配的」。邮箱里堆着 N 条
%% 不匹配的消息时，每次 receive 都要扫过它们 —— 于是既变慢，内存也一直涨。
%% 用 message_queue_len 把这个现象量化（长度是确定的，与调度无关）。
selective_receive_cost() ->
    io:format("~n== 6) 选择性接收的代价 ==~n"),
    Self = self(),
    [Self ! {noise, N} || N <- lists:seq(1, 1000)],
    d("先塞 1000 条不匹配的消息，邮箱长度", queue_len()),
    Self ! {wanted, found},
    d("再塞一条匹配的", queue_len()),
    %% 匹配的那条在最后，receive 也能找到它 —— 代价是扫过前面全部 1000 条
    d("取出匹配的那条", receive {wanted, W} -> W after 0 -> none end),
    d("取完之后邮箱长度（1000 条噪音还在）", queue_len()),
    Noise = [receive {noise, N} -> N end || _ <- lists:seq(1, 1000)],
    d("把噪音全吃掉：条数 / 首尾", {length(Noise), {hd(Noise), lists:last(Noise)}}),
    d("邮箱终于空了", queue_len()),
    io:format("  ~ts~n", ["结论：协议要保证「每个进程只收到自己认识的消息」，"]),
    io:format("  ~ts~n", ["      否则邮箱就是内存泄漏点，receive 也会越来越慢。"]),
    ok.

%% 7) 一个正经的协议：计数器服务
%% ------------------------------------------------------------
%% 把「调用」定义成 {From, Ref, 请求}、「回复」定义成 {Ref, 结果}，
%% 再加一种不需要回复的 cast（increment_async）和一种终止消息。
counter_loop(N) ->
    receive
        {From, Ref, get} ->
            From ! {Ref, N},
            counter_loop(N);
        {From, Ref, {add, K}} when is_integer(K) ->
            From ! {Ref, ok},
            counter_loop(N + K);
        {_From, increment_async} ->
            %% cast：不需要回复，发送方也不等
            counter_loop(N + 1);
        stop ->
            stopped
    end.

%% 同步调用：带超时，超时返回 {error, timeout} 而不是抛异常
call(Pid, Request, Timeout) ->
    Ref = make_ref(),
    Pid ! {self(), Ref, Request},
    receive
        {Ref, Reply} -> Reply
    after Timeout -> {error, timeout}
    end.

counter_service() ->
    io:format("~n== 7) 一个正经的协议：计数器服务 ==~n"),
    Pid = spawn(fun() -> counter_loop(0) end),
    d("新建服务，初始值", call(Pid, get, 2000)),
    d("add 5 的返回", call(Pid, {add, 5}, 2000)),
    d("add 5 之后的值", call(Pid, get, 2000)),
    %% cast 不等回复；因为同一发送者的消息是 FIFO 的，
    %% 紧接着的这次 get 一定能看到这次自增 —— 结论与调度无关
    Pid ! {self(), increment_async},
    d("发一条 cast 之后立刻 get", call(Pid, get, 2000)),
    d("再加 10", begin call(Pid, {add, 10}, 2000), call(Pid, get, 2000) end),
    %% 协议里没定义的请求 → 服务进程收不到匹配的消息，调用方超时
    d("发一个协议里没定义的请求（调用方会超时）",
      call(Pid, {no_such_request, 1}, 100)),
    d("服务进程被这条没人认领的消息影响了吗（还能正常 get）",
      call(Pid, get, 2000)),
    %% 停掉服务，用 monitor 确认它真的结束了
    MRef = erlang:monitor(process, Pid),
    Pid ! stop,
    receive {'DOWN', MRef, process, _, Reason} -> d("停止服务后 DOWN 的原因", Reason)
    after 2000 -> d("停止服务", timeout)
    end,
    d("朝已经停掉的服务发请求 → 超时", call(Pid, get, 100)),
    ok.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
