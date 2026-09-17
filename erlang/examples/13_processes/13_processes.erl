%% ============================================================
%% 13_processes —— 进程与消息
%%
%%    Erlang 的并发单位是**进程**（不是线程），由 VM 调度、彼此完全隔离：
%%    不共享内存，只能靠消息通信。进程的代价很低（几百字节、创建微秒级），
%%    所以「一个连接一个进程」是常态。
%%
%%    本示例所有涉及并发的结论都是**与调度无关的汇总**（求和、排序、
%%    布尔断言），不打印 pid、不依赖输出顺序。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/13_processes examples/13_processes/13_processes.erl
%% 运行：
%%   erl -noshell -pa build/13_processes -run '13_processes' main -s init stop
%% ============================================================
-module('13_processes').

-export([main/0, worker/1, pmap/2, counter_loop/1, call/3, flush/1]).

main() ->
    _ = logger:remove_handler(default),
    spawning(),
    isolation(),
    naming(),
    mailbox_semantics(),
    send_to_dead_process(),
    out_of_order(),
    timeout_and_late_reply(),
    parallel_map(),
    counter_service(),
    io:format("~n==== 13 结束 ====~n").

%% 1) 三种启动形式
%% ------------------------------------------------------------
%%   spawn(fun() -> ... end)   最灵活：闭包能捕获变量
%%   spawn(Mod, Fun, Args)     最省内存；热更新友好（23 章）
%%   spawn_monitor             带监控，进程结束/崩溃会收到 DOWN
spawning() ->
    io:format("== 1) 三种 spawn 形式 ==~n"),
    Self = self(),
    Ref1 = make_ref(),
    spawn(fun() -> Self ! {Ref1, from_fun} end),
    d("spawn/1 的结果", receive {Ref1, V1} -> V1 after 1000 -> timeout end),
    Ref2 = make_ref(),
    %% MFA 形式：函数必须导出，否则 undef
    spawn(?MODULE, worker, [{Self, Ref2, from_mfa}]),
    d("spawn/3（模块, 函数, 参数列表）",
      receive {Ref2, V2} -> V2 after 1000 -> timeout end),
    Ref3 = make_ref(),
    {_Pid3, MRef} = spawn_monitor(fun() -> Self ! {Ref3, from_monitor} end),
    d("spawn_monitor/1 的结果",
      receive {Ref3, V3} -> V3 after 1000 -> timeout end),
    d("spawn_monitor 的 DOWN 消息",
      receive {'DOWN', MRef, process, _, Reason} -> {got_down, Reason}
      after 1000 -> timeout end),
    ok.

%% 给 spawn/3 用的目标函数：必须导出，参数用列表传
worker({To, Ref, Value}) ->
    To ! {Ref, Value}.

%% 2) 进程隔离：数据是**拷贝**，不是共享
%% ------------------------------------------------------------
%%   * 每个进程有独立的堆，别的进程看不到你的数据
%%   * 发消息时 term 一律拷贝过去（>64 字节的 refc binary 是共享的）
%%   * 所以「改一个变量」永远影响不到别人——没有共享可变状态
isolation() ->
    io:format("~n== 2) 进程隔离：数据是拷贝 ==~n"),
    Self = self(),
    Data = [1, 2, 3],
    Ref = make_ref(),
    Ref2 = make_ref(),
    spawn(fun() ->
                  %% 子进程里对捕获到的 Data 做「修改」：只是构造了个新列表
                  New = [0 | Data],
                  Self ! {Ref, New, Data}
          end),
    %% 子进程往**自己的**进程字典里写点东西
    spawn(fun() ->
                  put(isolation_key, written_by_child),
                  Self ! {Ref2, get(isolation_key)}
          end),
    receive
        {Ref, ChildNew, ChildSaw} ->
            d("子进程看到的原始值", ChildSaw),
            d("子进程「改」完的值", ChildNew),
            d("父进程的数据有没有被改？", Data)
    after 1000 -> d("隔离测试", timeout)
    end,
    receive
        {Ref2, ChildKey} ->
            d("子进程在自己字典里读到的", ChildKey)
    after 1000 -> d("进程字典测试", timeout)
    end,
    d("父进程读同一个键（进程字典也是每进程独立的）", get(isolation_key)),
    ok.

%% 3) 注册名：全局唯一的原子
%% ------------------------------------------------------------
%% register 重名会 badarg；名字随进程死亡自动释放。
%% 别滥用：注册名是全局可变状态，会让测试互相干扰。
naming() ->
    io:format("~n== 3) 注册名 ==~n"),
    Name = '13-processes-demo-server',
    Pid = spawn(fun() -> receive stop -> ok end end),
    true = register(Name, Pid),
    d("whereis(名字) 拿到 pid（只断言是 pid）", is_pid(whereis(Name))),
    d("whereis(没注册过的名字)", whereis('no-such-name-here')),
    Pid2 = spawn(fun() -> ok end),
    d("重名注册会 badarg",
      try register(Name, Pid2) of
          _ -> unexpected_ok
      catch error:badarg -> badarg
      end),
    unregister(Name),
    d("unregister 之后 whereis 返回", whereis(Name)),
    Pid ! stop,
    ok.

%% 4) 邮箱语义与选择性接收
%% ------------------------------------------------------------
%% `Pid ! Msg` 的语义（违反直觉的地方最多，逐条记）：
%%   * 永不阻塞、永不失败——目标进程死了也照样返回 Msg
%%   * 消息进的是**对方的邮箱**；对方只取「匹配自己 receive 模式」的，
%%     不匹配的**留在邮箱里**——邮箱是个可能无限增长的队列
%%   * 「同一个发送者 → 同一个接收者」消息顺序有保证（FIFO）
mailbox_semantics() ->
    io:format("~n== 4) 邮箱语义 ==~n"),
    Self = self(),
    d("发送前 message_queue_len", queue_len()),
    Self ! {tag, 1},
    Self ! other,
    Self ! {tag, 2},
    d("塞完三条后 message_queue_len", queue_len()),
    d("只取匹配 {tag,_} 的第一条", receive {tag, X} -> X after 0 -> none end),
    d("不匹配的 other 还留着 → message_queue_len", queue_len()),
    d("再取一条 {tag,_}", receive {tag, Y} -> Y after 0 -> none end),
    d("把剩下的 other 取掉", receive other -> picked after 0 -> none end),
    d("邮箱清空后 message_queue_len", queue_len()),
    %% 选择性接收的代价：不匹配的消息一直堆着，每次 receive 都要扫过它们
    [Self ! {noise, N} || N <- lists:seq(1, 1000)],
    Self ! {wanted, found},
    d("塞 1000 条噪音 + 1 条匹配后，取出匹配的那条",
      receive {wanted, W} -> W after 0 -> none end),
    d("取完之后邮箱长度（1000 条噪音还在）", queue_len()),
    [receive {noise, _} -> ok end || _ <- lists:seq(1, 1000)],
    d("噪音全吃掉之后", queue_len()),
    ok.

queue_len() -> element(2, process_info(self(), message_queue_len)).

%% 5) 发给已死进程：静默丢弃
%% ------------------------------------------------------------
%% 「我发出去了」绝不等于「对方收到了」——要确认就得让对方回消息，
%% 或者 monitor 它（14 章）。
send_to_dead_process() ->
    io:format("~n== 5) 发给已死进程 ==~n"),
    {Pid, MRef} = spawn_monitor(fun() -> ok end),
    receive {'DOWN', MRef, process, _, R} -> d("目标进程已结束，原因", R)
    after 2000 -> ok end,
    d("它还活着吗", is_process_alive(Pid)),
    d("往它发消息的返回值（就是被发的那个值）", Pid ! hello_dead),
    ok.

%% 6) 实测：不带 ref 的协议会被乱序回复搞错
%% ------------------------------------------------------------
%% 协议三种消息（gen_server 就是按这三种设计的，15 章）：
%%   call   {From, Ref, Request} → 请求；对方必须回 {Ref, Reply}
%%   cast   Request（不带 From/Ref）→ 单向通知
%%   reply  {Ref, Reply} → 回复，靠 Ref 对上号
%% 这个服务故意「先回复第二条请求」——并发场景回复顺序本来就不保证。
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
    io:format("~n== 6) 不带 ref 的协议会被乱序回复搞错 ==~n"),
    Owner = self(),
    %% --- 朴素协议：请求不带 ref，只能按「谁先到」对应 ---
    Svc1 = spawn(fun() -> out_of_order_service(Owner) end),
    ReqA = {a_request, 111},
    ReqB = {b_request, 222},
    Svc1 ! {Owner, ReqA, ReqA},
    Svc1 ! {Owner, ReqB, ReqB},
    R1 = receive {reply, _, V1} -> V1 after 2000 -> timeout end,
    R2 = receive {reply, _, V2} -> V2 after 2000 -> timeout end,
    d("朴素协议：以为第一条回复属于 a_request", R1),
    d("朴素协议：以为第二条属于 b_request", R2),
    io:format("  ~ts~n", ["（上面读到的其实是 b 的回复和 a 的回复——配对错了）"]),
    %% --- 正确协议：请求带 ref，回复带回 ref ---
    Svc2 = spawn(fun() -> out_of_order_service(Owner) end),
    RefA = make_ref(),
    RefB = make_ref(),
    Svc2 ! {Owner, RefA, {a_request, 111}},
    Svc2 ! {Owner, RefB, {b_request, 222}},
    d("带 ref：a_request 的回复（即使它后到）",
      receive {reply, RefA, VA} -> VA after 2000 -> timeout end),
    d("带 ref：b_request 的回复（即使它先到）",
      receive {reply, RefB, VB} -> VB after 2000 -> timeout end),
    ok.

%% 7) 超时与迟到的回复
%% ------------------------------------------------------------
%% 超时之后只有两条路：A. 用 ref 精确 flush 掉迟到回复再重试；
%% B. 认为协议不可信，让它崩（16 章的监督树）。
%% 千万不要「超时就当没发生」——迟到回复会被下一条 receive 当成新回复。
timeout_and_late_reply() ->
    io:format("~n== 7) 超时与迟到的回复 ==~n"),
    Owner = self(),
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
    timer:sleep(500),
    d("迟到回复已在邮箱里（message_queue_len）", queue_len()),
    flush(Ref),
    d("flush(Ref) 之后还能读到它吗",
      receive {reply, Ref, _} -> still_there after 0 -> clean end),
    %% 换新 ref 重试是安全的：不可能把上一次的回复当成这一次的
    Fast = spawn(fun() -> receive {O2, T2, V2} -> O2 ! {reply, T2, V2} end end),
    Ref2 = make_ref(),
    Fast ! {Owner, Ref2, ok_value},
    d("换新 ref 重试的结果",
      receive {reply, Ref2, V3} -> V3 after 2000 -> timeout end),
    ok.

%% 只清掉「这个 ref 对应的回复」，不碰邮箱里的其它消息
flush(Ref) ->
    receive
        {reply, Ref, _} -> flush(Ref)
    after 0 -> ok
    end.

%% 8) 并发模式：并行 map
%% ------------------------------------------------------------
%% 「把一批活分给 N 个进程，结果按输入顺序收回来」的唯一正确做法是
%% **给每个请求配一个 ref**——回复的顺序无法预测。
pmap(F, L) ->
    Self = self(),
    Tagged = [{make_ref(), X} || X <- L],
    [spawn(fun() -> Self ! {R, F(X)} end) || {R, X} <- Tagged],
    [receive {R, V} -> V after 5000 -> {error, timeout} end || {R, _} <- Tagged].

parallel_map() ->
    io:format("~n== 8) 并行 map ==~n"),
    L = lists:seq(1, 12),
    d("输入的平方（顺序版）", [X * X || X <- L]),
    d("输入的平方（并发的 pmap）", pmap(fun(X) -> X * X end, L)),
    d("两者完全一致吗", pmap(fun(X) -> X * X end, L) =:= [X * X || X <- L]),
    %% 统计去重后的进程数：证明每个元素由独立进程处理
    Pids = pmap(fun(_X) -> self() end, lists:seq(1, 4)),
    d("4 个元素分别由几个不同进程处理", length(lists:usort(Pids))),
    ok.

%% 9) 一个正经的协议：计数器服务
%% ------------------------------------------------------------
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
    io:format("~n== 9) 计数器服务 ==~n"),
    Pid = spawn(fun() -> counter_loop(0) end),
    d("新建服务，初始值", call(Pid, get, 2000)),
    d("add 5 的返回", call(Pid, {add, 5}, 2000)),
    d("add 5 之后的值", call(Pid, get, 2000)),
    %% cast 不等回复；同一发送者消息 FIFO，紧接着的 get 一定看到这次自增
    Pid ! {self(), increment_async},
    d("发一条 cast 之后立刻 get", call(Pid, get, 2000)),
    %% 协议里没定义的请求 → 服务进程收不到匹配消息，调用方超时
    d("发一个协议里没定义的请求（调用方超时）",
      call(Pid, {no_such_request, 1}, 100)),
    d("服务进程被这条没人认领的消息影响了吗", call(Pid, get, 2000)),
    MRef = erlang:monitor(process, Pid),
    Pid ! stop,
    d("停止服务后 DOWN 的原因",
      receive {'DOWN', MRef, process, _, Reason} -> Reason
      after 2000 -> timeout end),
    d("朝已经停掉的服务发请求 → 超时", call(Pid, get, 100)),
    ok.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
