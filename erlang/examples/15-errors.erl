%% ============================================================
%% 15 - 错误处理：三种异常类、常见错误原因、以及「让它崩」哲学
%%
%%    这一章的重点不是 try/catch 的语法（第 13 章讲过了），而是**策略**：
%%      · error / exit / throw 三类各管什么，什么时候用哪个
%%      · 库函数为什么统一返回 {ok,_} | {error,_}
%%      · 常见运行期错误的 Reason 到底长什么样（一张实测出来的表）
%%      · 什么样的异常该让它把进程崩掉，崩了以后谁能看见
%%
%%    本章有两条「-Wall 帮你在编译期就拦住」的实测结论，见第 6 节的注释。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/15-errors.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '15-errors' main -s init stop
%% ============================================================
-module('15-errors').

-export([main/0, to_error/1, norm/1, with_context/1, parse_good/1, parse_bad/1,
         crash/1, observe/1]).

main() ->
    three_classes(),
    return_vs_raise(),
    reason_table(),
    static_checks(),
    catch_expr_deprecated(),
    let_it_crash(),
    rethrow_with_context(),
    io:format("~n==== 15 结束 ====~n").

%% 1) 三种异常类各管什么
%% ------------------------------------------------------------
%%   类     产生方式                          语义
%%   error  erlang:error/1,2 + 运行期错误      「代码有 bug / 输入不合法」，调用方可捕获
%%   exit   exit/1,2, 被 link 的进程杀掉       「这个进程该结束了」，用于进程级信号
%%   throw  throw/1                            「非本地返回」，只在本进程内做控制流
%%
%%   选择原则：
%%     · 能被调用方合理处理的失败 → **不要抛**，返回 {ok,_} | {error,_}
%%     · 调用方用不了的失败（参数违反契约）→ error(Reason)，让它崩
%%     · 需要「跨几层函数直接返回」→ throw（但别跨进程语义用它，那是 exit）
%%     · 要结束一个进程/发信号 → exit(Reason)
three_classes() ->
    io:format("== 1) 三种异常类 ==~n"),
    Z = opaque_zero(),
    Cases = [{error, fun() -> erlang:error(bug) end},
             {error, fun() -> 1 / Z end},
             {exit, fun() -> exit(shutdown) end},
             {throw, fun() -> throw(early_return) end}],
    [io:format("  ~-6ts -> Class = ~p, Reason = ~p~n",
               [atom_to_list(Class), class_of(F), norm(reason_of(F))])
     || {Class, F} <- Cases],
    %% erlang:error/2 可以在 Reason 里塞任意「上下文」，这是最实用的做法
    d("error({bad_input, S}) 风格的原因",
      to_error(fun() -> erlang:error({bad_input, "abc"}) end)),
    ok.

class_of(F) -> try F() catch C:_ -> C end.
reason_of(F) -> try F() catch _:R -> R end.

%% 2) 返回值还是抛异常
%% ------------------------------------------------------------
%% Erlang 标准库的约定：**可预期的失败用返回值**，返回 {ok, Result} | {error, Reason}。
%% 这样调用方必须显式处理，编译器与 dialyzer 也能帮你查漏。
return_vs_raise() ->
    io:format("~n== 2) 返回值 vs 抛异常 ==~n"),
    d("可预期失败：返回 {ok,_} / {error,_}", parse_good("12")),
    d("同样可预期失败（输入不是数字）", parse_good("abc")),
    %% 用 try 也可以，但把「可预期的失败」当异常抛会让调用方难受：
    %% 他要写 try 才能拿到结果，而 try 里**所有**异常都会经过这里。
    d("不该这样做：可预期失败却抛异常",
      to_error(fun() -> raises_when_bad("abc") end)),
    d("替代方案：用 case 直接分派",
      case_style("abc")),
    ok.

parse_good(S) ->
    try {ok, list_to_integer(S)}
    catch
        error:badarg -> {error, {not_a_number, S}}
    end.

%% 反面教材：把「输入不合法」当异常抛出去
raises_when_bad(S) ->
    try {ok, list_to_integer(S)} catch error:badarg -> erlang:error({bad_input, S}) end.

case_style(S) ->
    %% 也可以用 try ... of 的完整形状，但多数时候 case 更直白。
    %% 注意别画蛇添足地写成 case {parse_soft(S)} of —— 那个 {·} 是**单元素元组**，
    %% {ok, N} 与 {error, R} 都匹配不上，编译器会直接报
    %%   this clause cannot match because of different types/sizes
    case parse_soft(S) of
        {ok, N} -> {parsed, N};
        {error, R} -> {failed, R}
    end.

parse_soft(S) ->
    try {ok, list_to_integer(S)} catch error:badarg -> {error, {not_a_number, S}} end.

%% 3) 常见运行期错误的 Reason（全部实测）
%% ------------------------------------------------------------
%% **坑（本条很关键）**：不能在字面量上直接把错误算出来 ——
%% erlc -Wall 会在编译期点出来，配上 -Werror 直接编不过，示例根本跑不起来。
%% 所以所有「必然失败」的输入都要从参数进来（见第 6 节实测的警告原文）。
call1(F, A) ->
    try {ok, F(A)} catch Class:Reason -> {Class, norm(Reason)} end.

opaque_zero() -> length(lists:seq(1, 0)).
opaque_neg() -> -length(lists:seq(1, 1)).
only_int(X) when is_integer(X) -> X.
big_atom() -> list_to_atom(lists:duplicate(300, $a)).
as_int(S) -> list_to_integer(S).
bind_ok(V) -> {ok, X} = V, X.
lookup(K, M) -> maps:get(K, M).
trying(X) -> try X of only -> ok after ok end.
casing(X) -> case X of only -> ok end.
iffing(X) -> if X > 10 -> big end.

reason_table() ->
    io:format("~n== 3) 常见运行期错误的 Reason 全表 ==~n"),
    Rows =
        [{"badarg（参数类型/取值不对）",           fun as_int/1,       "abc"},
         {"badarith（算术错误，除零等）",          fun(_) -> 1 / opaque_zero() end, x},
         {"badmatch（模式匹配失败）",              fun bind_ok/1,      {error, boom}},
         {"function_clause（函数没有匹配的子句）", fun only_int/1,     atom},
         {"undef（模块或函数不存在）",             fun(_) -> no_such_mod:f() end, x},
         {"badarity（调用 fun 时参数个数不对）",   fun(_) -> apply(fun(X) -> X end, [1, 2]) end, x},
         {"try_clause（try 的 of 子句都不匹配）",  fun trying/1,       1},
         {"case_clause（case 的子句都不匹配）",    fun casing/1,       1},
         {"if_clause（if 没有真分支）",            fun iffing/1,       1},
         {"badmap（拿非 map 当 map 用）",          fun(M) -> lookup(k, M) end, not_a_map},
         {"badkey（map 里没有这个键，maps:get/2）", fun(M) -> lookup(missing, M) end, #{}},
         {"system_limit（超长原子等资源上限）",    fun(_) -> big_atom() end, x},
         {"timeout_value（receive 的超时为负）",   fun(_) -> receive after opaque_neg() -> ok end end, x}],
    [io:format("  ~-38ts = ~p~n", [Label, call1(F, A)]) || {Label, F, A} <- Rows],
    io:format("  ~ts~n",
              ["注意 badmap 的 Reason 是 {badmap, X}，badkey 是 {badkey, K}，"]),
    io:format("  ~ts~n",
              ["而 badmatch / case_clause / try_clause 都把自己的「触发值」带在 Reason 里。"]),
    ok.

%% 4) 哪些错误其实在编译期就能发现
%% ------------------------------------------------------------
%% 这正是本示例到处传参数的原因。若在字面量上直接写：
%%   list_to_integer("abc")   → the call to list_to_integer/1 will fail with a 'badarg' exception
%%   {ok, X} = {error, boom}  → no clause will ever match
%%   maps:get(k, not_a_map)   → the call to map_get/2 will fail with a '{badmap,not_a_map}' exception
%%   maps:get(missing, #{})   → the call to map_get/2 will fail with a '{badkey,missing}' exception
%% 写成 try 1 of 2 -> ok ... end 会报 no clause will ever match。
%% 这些在 -Wall 下都是警告，配上 -Werror 就是编译失败。
static_checks() ->
    io:format("~n== 4) 编译期就能发现的「必然失败」 ==~n"),
    io:format("  ~ts~n", ["上面 4 条警告原文写在 static_checks/0 的注释里。"]),
    io:format("  ~ts~n", ["结论：示例要想「真的跑到错误」，输入必须来自变量或参数，"]),
    io:format("  ~ts~n", ["不能让编译器看出结果是常量（原因见第 02 章的常量传播）。"]),
    %% 演示「从参数进来就不报」：同一个函数，字面量调用会被警告、参数调用不会
    d("从参数进来的必然失败：编译期不报，运行期抛",
      call1(fun as_int/1, "abc")),
    ok.

%% 5) catch 表达式已废弃
%% ------------------------------------------------------------
%%   `catch Expr` 这种老写法在 OTP 29 下**编译期就报错**（配 -Werror 时）：
%%     'catch ...' is deprecated; please use 'try ... catch ... end' instead.
%%     Compile directive 'nowarn_deprecated_catch' can be used to suppress ...
%%   想临时压掉它可以在模块里加 -compile(nowarn_deprecated_catch).
%%   但别加：catch Expr 会**把三类异常混成一个值**（error 只留 Reason、
%%   exit 得到 {'EXIT', Reason}、throw 得到 Value），几乎没法正确分支。
catch_expr_deprecated() ->
    io:format("~n== 5) catch 表达式已废弃 ==~n"),
    io:format("  ~ts~n", ["`catch Expr` 在 OTP 29 下编译即警告（-Werror 直接失败）。"]),
    io:format("  ~ts~n", ["它会把三类异常压成三种不同形状的返回值，别再用了："]),
    io:format("  ~ts~n", ["  error  → Reason；throw → Value；exit → {'EXIT', Reason}。"]),
    d("用 try 能同时拿到 Class 与 Reason（推荐）",
      [{class_of(F), norm(reason_of(F))}
       || F <- [fun() -> erlang:error(x) end,
                fun() -> exit(y) end,
                fun() -> throw(z) end]]),
    ok.

%% 6) 让它崩：进程级容错的前提是「崩了能被看见」
%% ------------------------------------------------------------
%% 关键事实（本示例实测，一张表）：
%%   · 谁想「看见」这次崩溃，就得 monitor（或 link）它：
%%     monitor 收到 {'DOWN', Ref, process, Pid, Reason}。
%%   · DOWN 的 Reason 形状按类不同：
%%       error → {Reason0, Stacktrace}    ← 带栈
%%       exit  → Reason（原样）
%%       throw → {nocatch, Value}         ← 没人接住才崩，所以叫 nocatch
%%     「崩了还能拿到栈」只对 error 类成立。
%%   · **默认 logger 会自动上报 error 类的崩溃**（exit 类一律不上报）：
%%       实测 exit(reason_x) / exit({shutdown,_}) / exit(normal) / exit(kill)
%%       都不产生任何日志；erlang:error 和未捕获的 throw 会各产生一条。
%%
%%     上报长这样（时间戳与 pid 是变量，所以它没法做逐字节比对）：
%%       =ERROR REPORT==== 16-Sep-2026::20:27:48.198791 ===
%%       Error in process <0.82.0> with exit value:
%%       {boom,[{log1,crash,1,[{file,"log1.erl"},{line,3}]}]}
%%
%%     它由**默认 logger handler** 打到 stdout，而且是**异步**的 ——
%%     所以日志行会插在别的位置。本示例要的是可重复输出，先把默认 handler 摘掉。
%%     想看真实日志：把下面这行注释掉再跑，或看第 27 章（自定义 handler 收日志）。
let_it_crash() ->
    io:format("~n== 6) 让它崩，然后从外面看 ==~n"),
    io:format("  ~ts~n", ["（先摘掉默认 logger handler，否则 stdout 里会混进带时间戳的 ERROR REPORT）"]),
    _ = logger:remove_handler(default),
    [d("观察 " ++ atom_to_list(K) ++ " 类崩溃的 DOWN 原因", observe(K))
     || K <- [error_class, exit_class, throw_class]],
    d("观察者进程自己没事（同一个进程连续观察三次也没崩）", still_alive()),
    ok.

crash(error_class) -> erlang:error(boom);
crash(exit_class)  -> exit(reason_x);
crash(throw_class) -> throw(tossed).

%% spawn_monitor 而不是 spawn：要拿到 DOWN 消息才能知道「崩了、为什么崩」。
%% 只打印与调度/地址无关的信息：Reason 的标签、栈顶的 {模块,函数,参数个数}、
%% 栈是否非空。直接把整个 Reason 打出来会带上 file/line 与 fun 地址，不可重复。
observe(Kind) ->
    {_Pid, Ref} = spawn_monitor(fun() -> crash(Kind) end),
    receive
        {'DOWN', Ref, process, _Pid2, Reason} ->
            {down, describe_down(Reason)}
    after 2000 ->
            {down, timeout}
    end.

describe_down({Reason0, Stack}) when is_list(Stack) ->
    %% error 类：Reason 是 {Reason0, Stacktrace}
    {error, Reason0, top_frame, top_frame(Stack), stack_non_empty, Stack =/= []};
describe_down(Reason) ->
    {other_class, norm(Reason)}.

top_frame(Stack) ->
    {M, F, A} = {element(1, hd(Stack)), element(2, hd(Stack)), element(3, hd(Stack))},
    {M, F, A}.

still_alive() -> is_process_alive(self()).  %% 永远是 true，只用来证明观察者没被带崩

%% 7) 加上下文重新抛出（保留原始栈）
%% ------------------------------------------------------------
%% 库函数通常这样做：先把异常**原样**记下来（记日志），再包一层上下文抛给调用方。
%% 关键是栈要一起往下传：catch Class:Reason:Stack 里的 Stack 直接交给
%% erlang:raise/3，否则调用方拿到的栈是从这里开始的，丢失了真正的出错点。
with_context(F) ->
    try F()
    catch Class:Reason:Stack -> erlang:raise(Class, {context, Reason}, Stack)
    end.

rethrow_with_context() ->
    io:format("~n== 7) 加一层上下文再抛出 ==~n"),
    d("原始异常",
      to_error(fun() -> crash(error_class) end)),
    d("包了一层 context 之后（注意 Reason 变了）",
      to_error(fun() -> with_context(fun() -> crash(error_class) end) end)),
    d("栈顶仍是真正的出错函数（因为 Stack 一起传下去了）",
      try with_context(fun() -> crash(error_class) end)
      catch _:_:Stack -> top_frame(Stack)
      end),
    ok.

%% 8) 把任意异常规整成 {error, Reason}
%% ------------------------------------------------------------
%% 有用：作为「最后一道边界」（比如 HTTP handler 的出口），让调用方只面对一种形状。
%% 危险：如果它包在**很靠内**的地方，就会把 bug 变成静默的返回值 ——
%% 这正是 setpgr 里最常见的坏味道 `catch _:_ -> ok`。
to_error(F) ->
    try {ok, F()} catch Class:Reason -> {error, Class, norm(Reason)} end.

%% 把「每次运行都可能不同」的东西替换掉，剩下的才敢打进输出。
%% fun / pid / ref 都会打印成带地址的形式（#Fun<mod.N.123456>），
%% 进程和 ref 更离谱；栈帧里还带 file/line。所以打印异常原因前先归一化。
norm(F) when is_function(F)   -> '<fun>';
norm(P) when is_pid(P)        -> '<pid>';
norm(R) when is_reference(R)  -> '<ref>';
norm(T) when is_tuple(T)      -> list_to_tuple([norm(E) || E <- tuple_to_list(T)]);
norm(L) when is_list(L)       -> [norm(E) || E <- L];
norm(X)                       -> X.

%% 反面教材（不执行，只作对照）
%%   parse_bad(S) -> try {ok, list_to_integer(S)} catch _:_ -> ok end.
%% 它把「输入不是数字」和「代码里有 bug」一起吞成 ok，调用方什么都看不出来。
parse_bad(S) ->
    try {ok, list_to_integer(S)} catch _:_ -> ok end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
