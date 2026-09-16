%% ============================================================
%% 18 - 进程：spawn、进程隔离、注册名、以及「别用进程字典」
%%
%%    Erlang 的并发单位是**进程**（不是线程、不是协程），由 VM 调度，
%%    彼此**完全隔离**：不共享内存，只能靠消息通信（第 19 章）。
%%    隔离带来的好处是可以放心地「崩掉就重来」（第 20、22 章）。
%%
%%    进程的代价很低（几百字节、创建微秒级），所以「一个连接一个进程」
%%    这种模型在 Erlang 里是常态。
%%
%%    本示例所有涉及并发的结论都是**与调度无关的汇总**（求和、排序后的列表、
%%    布尔断言），不打印 pid，也不依赖任何输出顺序 ——
%%    否则 run-all.sh 的「两种调度器配置输出必须逐字节一致」这条就过不了。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/18-processes.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '18-processes' main -s init stop
%% ============================================================
-module('18-processes').

-export([main/0, worker/1, pmap/2, sum_parallel/2, dict_probe/1]).

main() ->
    spawning(),
    isolation(),
    limits(),
    naming(),
    parallel_map(),
    parallel_sum(),
    process_dictionary(),
    io:format("~n==== 18 结束 ====~n").

%% 1) 三种启动形式
%% ------------------------------------------------------------
%%   spawn(fun() -> ... end)          最灵活：闭包能捕获变量
%%   spawn(Mod, Fun, Args)            最省内存：不用传 fun，适合热更新
%%   spawn_link / spawn_monitor       带链接/监控（第 20 章细讲）
%% 想拿返回值，就自己发消息回来（见 parallel_map/2）。
spawning() ->
    io:format("== 1) 三种 spawn 形式 ==~n"),
    Self = self(),
    Ref1 = make_ref(),
    %% 形式 A：fun，可以直接捕获 Self 与 Ref1
    spawn(fun() -> Self ! {Ref1, from_fun} end),
    d("spawn/1 的结果", receive {Ref1, V1} -> V1 after 1000 -> timeout end),
    Ref2 = make_ref(),
    %% 形式 B：MFA。注意函数必须导出，否则 undef
    spawn(?MODULE, worker, [{Self, Ref2, from_mfa}]),
    d("spawn/3（模块, 函数, 参数列表）的结果",
      receive {Ref2, V2} -> V2 after 1000 -> timeout end),
    Ref3 = make_ref(),
    %% 形式 C：spawn_monitor，顺便拿到进程结束的通知（第 15、20 章）
    {_Pid3, MRef} = spawn_monitor(fun() -> Self ! {Ref3, from_monitor} end),
    d("spawn_monitor/1 的结果",
      receive {Ref3, V3} -> V3 after 1000 -> timeout end),
    %% 进程结束时 DOWN 消息一定会到（顺序无所谓，只断言「收到了」）
    Down = receive {'DOWN', MRef, process, _, Reason} -> {got_down, Reason}
           after 1000 -> timeout end,
    d("spawn_monitor 的 DOWN 消息", Down),
    %% 打印 pid 出来每次运行都不一样，所以只看稳定的元信息
    d("主进程的注册名（没注册过）", process_info(self(), registered_name)),
    ok.

%% 给 spawn/3 用的目标函数：必须导出，参数用列表传
worker({To, Ref, Value}) ->
    To ! {Ref, Value}.

%% 2) 进程隔离：数据是**拷贝**，不是共享
%% ------------------------------------------------------------
%% 这是 Erlang 并发模型的核心事实：
%%   * 每个进程有独立的堆，别的进程看不到你的数据
%%   * 往别的进程发消息时，特别大的二进制（refc binary，超过 64 字节那种）
%%     是**共享**的；其它所有 term 一律**拷贝**过去
%%   * 所以「改一个变量」永远影响不到别人 —— 没有共享可变状态这回事
isolation() ->
    io:format("~n== 2) 进程隔离：数据是拷贝 ==~n"),
    Self = self(),
    Data = [1, 2, 3],
    Ref = make_ref(),
    Ref2 = make_ref(),
    spawn(fun() ->
                  %% 子进程里对捕获到的 Data 做「修改」：其实只是构造了个新列表
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
            d("父进程的数据有没有被改？", Data),
            d("父进程的数据与子进程看到的值相等吗（=:= 只比大小）",
              Data =:= ChildSaw)
    after 1000 -> d("隔离测试", timeout)
    end,
    receive
        {Ref2, ChildKey} ->
            d("子进程在自己字典里读到的", ChildKey)
    after 1000 -> d("进程字典测试", timeout)
    end,
    d("父进程读同一个键（进程字典也是每进程独立的）", get(isolation_key)),
    ok.

%% 3) 数量与上限
%% ------------------------------------------------------------
%% process_count() 每次运行都可能不同 → 只断言范围，不打印数字。
limits() ->
    io:format("~n== 3) 进程数与上限 ==~n"),
    d("进程数是一个正整数", erlang:system_info(process_count) > 0),
    d("进程数远小于上限", erlang:system_info(process_count) < erlang:system_info(process_limit)),
    d("最大值就是 process_limit 这个常量", erlang:system_info(process_limit)),
    %% 在当前 VM 上试出「能同时存在多少进程」不现实（会吃满内存），
    %% 但「启动 200 个进程然后全部回收」很便宜，可以实测一下
    Self = self(),
    Refs = [begin
                R = make_ref(),
                spawn(fun() -> Self ! {R, ok} end),
                R
            end || _ <- lists:seq(1, 200)],
    Got = [receive {R, ok} -> 1 after 5000 -> 0 end || R <- Refs],
    d("启动 200 个进程，收到回复的个数", lists:sum(Got)),
    ok.

%% 4) 注册名：给进程起一个全局可见的名字
%% ------------------------------------------------------------
%% 注册名是**全局唯一**的原子。register 重名会 badarg；
%% 名字随进程一起消失（进程一死，名字自动释放）。
%% 这对「单例服务」很方便，但**不要滥用**：注册名是全局可变状态，
%% 会让测试互相干扰；OTP 里的正规做法是用监督树 + 局部注册（第 22 章）。
naming() ->
    io:format("~n== 4) 注册名 ==~n"),
    Name = '18-processes-demo-server',
    Pid = spawn(fun() -> receive stop -> ok end end),
    true = register(Name, Pid),
    d("whereis(名字) 拿到 pid（只比较是否是活的，不打印 pid）",
      is_pid(whereis(Name))),
    d("名字在 registered() 里吗", lists:member(Name, registered())),
    d("whereis(没注册过的名字)", whereis('no-such-name-here')),
    %% 注册名是全局的，重名注册会失败
    Pid2 = spawn(fun() -> ok end),
    d("重名注册会 badarg",
      begin
          try register(Name, Pid2) of
              _ -> unexpected_ok
          catch
              error:badarg -> badarg
          end
      end),
    %% 我们注册的进程还在（另一个进程已经自然结束了，但名字是我们的）
    d("注册的进程还活着吗", is_process_alive(Pid)),
    unregister(Name),
    d("unregister 之后 whereis 返回", whereis(Name)),
    %% 注意：进程一死名字就自动释放，不需要（也无法）手动清
    Pid ! stop,
    ok.

%% 5) 并发模式一：并行 map
%% ------------------------------------------------------------
%% 「把一批活分给 N 个进程，结果按输入顺序收回来」的唯一正确做法是
%% **给每个请求配一个 ref**，因为回复的顺序无法预测。
%% 这里故意不保证顺序，最后 sort 一下 —— 顺便证明结果与调度无关。
pmap(F, L) ->
    Self = self(),
    Tagged = [{make_ref(), X} || X <- L],
    [spawn(fun() -> Self ! {R, F(X)} end) || {R, X} <- Tagged],
    [receive {R, V} -> V after 5000 -> {error, timeout} end || {R, _} <- Tagged].

parallel_map() ->
    io:format("~n== 5) 并发模式：并行 map ==~n"),
    L = lists:seq(1, 12),
    d("输入的平方（顺序版）", [X * X || X <- L]),
    d("输入的平方（并发的 pmap）", pmap(fun(X) -> X * X end, L)),
    d("两者完全一致吗", pmap(fun(X) -> X * X end, L) =:= [X * X || X <- L]),
    %% 用「每个元素由一个独立进程处理」来体现并发：
    %% 统计去重后的进程数（pid 本身不可打印，但个数是确定的）
    Self = self(),
    Pids = pmap(fun(_X) -> self() end, lists:seq(1, 4)),
    d("4 个元素分别由几个不同进程处理", length(lists:usort(Pids))),
    d("这些进程都不是调用者本进程", not lists:member(Self, Pids)),
    ok.

%% 6) 并发模式二：分治求和（结果与调度无关）
%% ------------------------------------------------------------
sum_parallel(L, Chunks) ->
    Parts = split_even(L, Chunks),
    pmap(fun(P) -> lists:sum(P) end, Parts).

split_even(L, N) when N > 1 ->
    Len = length(L),
    Size = (Len + N - 1) div N,
    split_chunks(L, Size).

split_chunks([], _) -> [];
split_chunks(L, Size) ->
    case length(L) =< Size of
        true -> [L];
        false ->
            {H, T} = lists:split(Size, L),
            [H | split_chunks(T, Size)]
    end.

parallel_sum() ->
    io:format("~n== 6) 并发模式：分治求和 ==~n"),
    L = lists:seq(1, 1000),
    Expected = lists:sum(L),
    d("顺序求和", Expected),
    d("4 个进程分段求和再相加", lists:sum(sum_parallel(L, 4))),
    d("两者相等吗", lists:sum(sum_parallel(L, 4)) =:= Expected),
    d("分段后每段的和（与切分方式有关，但与调度无关）", sum_parallel(L, 4)),
    ok.

%% 7) 进程字典：知道它存在，但别用
%% ------------------------------------------------------------
%% put/get/erase 是**进程局部**的键值存储。它的坏处：
%%   * 隐式状态：函数签名看不出它读写了什么，测试和重构都变难
%%   * 只在当前进程有效，跨进程完全不可见（下面演示）
%%   * 一旦换了进程模型（比如以后拆成多进程），逻辑就崩了
%% OTP 自己只在极少数底层场合用它（比如随进程附带的临时标记），
%% **业务代码里应该用参数传递、record、map 或 gen_server 的 state**。
dict_probe(Key) -> get(Key).

process_dictionary() ->
    io:format("~n== 7) 进程字典（知道就好，别用） ==~n"),
    put(probe_key, 42),
    d("put 之后本进程 get 得到", dict_probe(probe_key)),
    d("get/1 取不存在的键返回", get(never_put)),
    d("get/0 列出整个字典", lists:sort(get())),
    Self = self(),
    Ref = make_ref(),
    spawn(fun() -> Self ! {Ref, dict_probe(probe_key)} end),
    d("另一个进程里 get 同一个键（看不到！）",
      receive {Ref, V} -> V after 1000 -> timeout end),
    d("erase 返回被删掉的值", erase(probe_key)),
    d("erase 之后", dict_probe(probe_key)),
    ok.


d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
