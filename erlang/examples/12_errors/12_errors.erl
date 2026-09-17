%% ============================================================
%% 12_errors —— 异常与错误处理哲学
%%
%%    重点不是 try/catch 的语法，而是**策略**：
%%      · error / exit / throw 三类各管什么，什么时候用哪个
%%      · 库函数为什么统一返回 {ok,_} | {error,_}
%%      · 常见运行期错误的 Reason 到底长什么样（一张实测出来的表）
%%      · 什么样的异常该让它把进程崩掉（let it crash），崩了谁能看见
%%      · maybe 表达式：连续「可能失败」步骤的平铺写法
%%
%% 编译：
%%   erlc -Werror -Wall -o build/12_errors examples/12_errors/12_errors.erl
%% 运行：
%%   erl -noshell -pa build/12_errors -run '12_errors' main -s init stop
%% ============================================================
-module('12_errors').

-export([main/0, classify/1, to_error/1, parse_soft/1, crash/1, observe/1,
         raises/2, classify_plain_match/1, norm/1]).

main() ->
    _ = logger:remove_handler(default),   %% 防崩溃 ERROR REPORT 污染输出
    three_classes(),
    catch_without_class(),
    after_always_runs(),
    maybe_demo(),
    return_vs_raise(),
    reason_table(),
    let_it_crash(),
    rethrow_with_context(),
    io:format("~n==== 12 结束 ====~n").

%% 1) 三种异常类各管什么
%% ------------------------------------------------------------
%%   error  erlang:error/1,2 + 运行期错误   「代码有 bug / 输入不合法」
%%   exit   exit/1,2，被 link 的进程杀掉    「这个进程该结束了」
%%   throw  throw/1                          「非本地返回」，只在本进程内
%%
%%   选择原则：
%%     · 调用方能合理处理的失败 → **不要抛**，返回 {ok,_} | {error,_}
%%     · 调用方用不了的失败（参数违反契约）→ error(Reason)，让它崩
%%     · 跨几层函数直接返回 → throw（别跨进程用它，那是 exit 的活）
%%     · 要结束一个进程 → exit(Reason)
three_classes() ->
    io:format("== 1) 三种异常类 ==~n"),
    Z = opaque_zero(),
    Cases = [{error, fun() -> erlang:error(bug) end},
             {error, fun() -> 1 / Z end},
             {exit, fun() -> exit(shutdown) end},
             {throw, fun() -> throw(early_return) end}],
    [io:format("  ~-6ts -> Class = ~p, Reason = ~p~n",
               [atom_to_list(Tag), class_of(F), norm(reason_of(F))])
     || {Tag, F} <- Cases],
    d("error({bad_input, S}) 风格（把上下文塞进 Reason）",
      to_error(fun() -> erlang:error({bad_input, "abc"}) end)),
    ok.

class_of(F) -> try F() catch C:_ -> C end.
reason_of(F) -> try F() catch _:R -> R end.

%% 2) catch 省略 Class 默认 throw；catch Expr 已废弃
%% ------------------------------------------------------------
%% 两条实测结论：
%%   · catch 里**不写 Class** 时默认接 throw 类，error/exit 直接穿透崩进程；
%%     永远写 Class:Reason 或 _:Reason。
%%   · `catch Expr` 老写法在 OTP 29 下编译期就报废弃警告（-Werror 直接失败），
%%     它还会把三类异常压成三种不同形状的值，别再用了。
catch_without_class() ->
    io:format("~n== 2) catch 的两个陷阱 ==~n"),
    Z = opaque_zero(),
    Cases = [{error, fun() -> erlang:error(e) end},
             {exit, fun() -> exit(x) end},
             {throw, fun() -> throw(t) end},
             {badarith, fun() -> 1 / Z end}],
    d("只接 throw 类：error/exit 类穿透内层（标成 escaped）",
      [{Tag, only_throw_caught(F)} || {Tag, F} <- Cases]),
    d("捕获时带上 stacktrace（长度 > 0）",
      stack_size_of(fun() -> erlang:error(boom) end) > 0),
    d("stacktrace 的第一帧是出错函数",
      first_frame_module(fun() -> erlang:error(boom) end)),
    ok.

only_throw_caught(F) ->
    try throw_only(F) catch Class:Reason -> {escaped, Class, Reason} end.

throw_only(F) ->
    try F() catch throw:R -> {caught_as_throw, R} end.

stack_size_of(F) ->
    try F() catch _:_:Stack -> length(Stack) end.

%% catch 里是 Class:Reason:Stack，冒号后直接跟变量；写 [...] 是语法错误
first_frame_module(F) ->
    try F() catch _:_:Stack -> {mfa, element(1, hd(Stack))} end.

%% 3) after 一定执行
%% ------------------------------------------------------------
after_always_runs() ->
    io:format("~n== 3) after 一定执行 ==~n"),
    Self = self(),
    Ref = make_ref(),
    spawn(fun() ->
                  Flag = try erlang:error(x)
                         catch _:_ -> caught
                         after Self ! {Ref, after_ran}
                         end,
                  Self ! {Ref, value, Flag}
          end),
    R1 = receive {Ref, after_ran} -> true after 1000 -> false end,
    R2 = receive {Ref, value, _} -> true after 1000 -> false end,
    d("无论正常还是异常，after 都跑了", {after_ran, R1, value_delivered, R2}),
    ok.

%% 4) maybe 表达式（OTP 25 引入，OTP 27 起默认启用）
%% ------------------------------------------------------------
%% 三条**实测**出来的语义：
%%   1. 只有 `?=` 失败才走 else，且 else 匹配的是**失败的那个值本身**；
%%   2. body 里写明文的 `true = N >= 0` 失败会抛 badmatch **穿透** else——
%%      想让它走 else 必须写成 `true ?= (N >= 0)`；
%%   3. else 里所有子句都不匹配 → 抛 else_clause。
classify(X) ->
    maybe
        {ok, N} ?= to_int(X),
        true ?= (N >= 0),           %% 必须用 ?=，见第 2 条
        {non_negative, N}
    else
        {error, R} -> {error, R};
        false -> {error, negative};
        Other -> {error, {unexpected, Other}}
    end.

%% 反例：body 里写普通 = → badmatch 穿透 else
classify_plain_match(X) ->
    maybe
        {ok, N} ?= to_int(X),
        true = N >= 0,
        {non_negative, N}
    else
        false -> {error, negative}
    end.

to_int(X) when is_integer(X) -> {ok, X};
to_int(X) when is_binary(X) ->
    case string:to_integer(binary_to_list(X)) of
        {N, []} -> {ok, N};
        _ -> {error, not_a_number}
    end;
to_int(_) -> {error, not_a_number}.

maybe_demo() ->
    io:format("~n== 4) maybe 表达式 ==~n"),
    d("classify(5)", classify(5)),
    d("classify(-5)（?= 失败，值是 false → else 的 false 子句）", classify(-5)),
    d("classify(\"abc\")（值是 {error,not_a_number}）", classify("abc")),
    d("body 里写 true = N >= 0 的后果（badmatch 穿透 else）",
      to_error(fun() -> classify_plain_match(-5) end)),
    ok.

%% 5) 返回值还是抛异常
%% ------------------------------------------------------------
%% 标准库的约定：**可预期的失败用返回值** {ok, Result} | {error, Reason}。
%% 调用方必须显式处理，编译器与 dialyzer 也能帮你查漏（23 章）。
return_vs_raise() ->
    io:format("~n== 5) 返回值 vs 抛异常 ==~n"),
    d("可预期失败：返回 {ok,_} / {error,_}", parse_soft("12")),
    d("同样可预期失败（输入不是数字）", parse_soft("abc")),
    d("用 case 分派两种结果",
      case parse_soft("abc") of
          {ok, N} -> {parsed, N};
          {error, R} -> {failed, R}
      end),
    ok.

parse_soft(S) ->
    try {ok, list_to_integer(S)}
    catch error:badarg -> {error, {not_a_number, S}}
    end.

%% 6) 常见运行期错误的 Reason（全部实测）
%% ------------------------------------------------------------
%% 不能在字面量上直接把错误算出来——erlc -Wall 会在编译期点出来，
%% 配 -Werror 编不过。所以所有「必然失败」的输入都从参数进来。
call1(F, A) ->
    try {ok, F(A)} catch Class:Reason -> {Class, norm(Reason)} end.

opaque_zero() -> length(lists:seq(1, 0)).
opaque_neg() -> -length(lists:seq(1, 1)).
only_int(X) when is_integer(X) -> X.
big_atom() -> list_to_atom(lists:duplicate(300, $a)).
as_int(S) -> list_to_integer(S).
bind_ok(V) -> {ok, X} = V, X.
lookup(K, M) -> maps:get(K, M).
casing(X) -> case X of only -> ok end.
iffing(X) -> if X > 10 -> big end.

reason_table() ->
    io:format("~n== 6) 常见运行期错误的 Reason ==~n"),
    Rows =
        [{"badarg（参数类型/取值不对）",           fun as_int/1,       "abc"},
         {"badarith（算术错误，除零等）",          fun(_) -> 1 / opaque_zero() end, x},
         {"badmatch（模式匹配失败）",              fun bind_ok/1,      {error, boom}},
         {"function_clause（没有匹配的子句）",     fun only_int/1,     atom},
         {"undef（模块或函数不存在）",             fun(_) -> no_such_mod:f() end, x},
         {"case_clause（case 都不匹配）",          fun casing/1,       1},
         {"if_clause（if 没有真分支）",            fun iffing/1,       1},
         {"badmap（拿非 map 当 map 用）",          fun(M) -> lookup(k, M) end, not_a_map},
         {"badkey（map 里没有这个键）",            fun(M) -> lookup(missing, M) end, #{}},
         {"system_limit（超长原子等资源上限）",    fun(_) -> big_atom() end, x},
         {"timeout_value（receive 超时为负）",
          fun(_) -> receive after opaque_neg() -> ok end end, x}],
    [io:format("  ~-36ts = ~p~n", [Label, call1(F, A)]) || {Label, F, A} <- Rows],
    io:format("  ~ts~n",
              ["注意 badmap 是 {badmap,X}、badkey 是 {badkey,K}，"]),
    io:format("  ~ts~n",
              ["而 badmatch / case_clause / try_clause 把「触发值」带在 Reason 里。"]),
    ok.

%% 7) 让它崩：崩了能被看见
%% ------------------------------------------------------------
%% 关键事实（实测）：
%%   · 想看见崩溃就得 monitor（或 link）：DOWN 的 Reason 形状按类不同——
%%       error → {Reason0, Stacktrace}（带栈）；exit → Reason 原样；
%%       throw → {nocatch, Value}（没人接住才崩，所以叫 nocatch）
%%   · 默认 logger 自动上报 error 类崩溃（exit 类一律不上报）
let_it_crash() ->
    io:format("~n== 7) 让它崩，然后从外面看 ==~n"),
    [d("观察 " ++ atom_to_list(K) ++ " 类崩溃的 DOWN", observe(K))
     || K <- [error_class, exit_class, throw_class]],
    d("观察者进程自己没事", is_process_alive(self())),
    ok.

crash(error_class) -> erlang:error(boom);
crash(exit_class)  -> exit(reason_x);
crash(throw_class) -> throw(tossed).

observe(Kind) ->
    {_Pid, Ref} = spawn_monitor(fun() -> crash(Kind) end),
    receive
        {'DOWN', Ref, process, _Pid2, Reason} ->
            {down, describe_down(Reason)}
    after 2000 ->
            {down, timeout}
    end.

describe_down({Reason0, Stack}) when is_list(Stack) ->
    {error, Reason0, stack_non_empty, Stack =/= []};
describe_down(Reason) ->
    {other_class, norm(Reason)}.

%% 8) 加上下文重新抛出（保留原始栈）
%% ------------------------------------------------------------
%% catch Class:Reason:Stack 里的 Stack 要交给 erlang:raise/3，
%% 否则调用方拿到的栈从这里开始，丢失了真正的出错点。
with_context(F) ->
    try F()
    catch Class:Reason:Stack -> erlang:raise(Class, {context, Reason}, Stack)
    end.

rethrow_with_context() ->
    io:format("~n== 8) 加一层上下文再抛出 ==~n"),
    d("原始异常", to_error(fun() -> crash(error_class) end)),
    d("包了一层 context 之后（Reason 变了）",
      to_error(fun() -> with_context(fun() -> crash(error_class) end) end)),
    d("栈顶仍是真正的出错函数（Stack 一起传下去了）",
      try with_context(fun() -> crash(error_class) end)
      catch _:_:Stack -> element(1, hd(Stack))
      end),
    ok.

%% 把任意异常规整成 {error, _}：只该用在**最外层边界**（HTTP handler 出口等）。
%% 包在很靠内的地方 = 把 bug 变成静默返回值。
to_error(F) ->
    try {ok, F()} catch Class:Reason -> {error, Class, norm(Reason)} end.

raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

%% 打印前归一化：fun/pid/ref/栈帧带地址与 file/line，不可重复
norm(F) when is_function(F)   -> '<fun>';
norm(P) when is_pid(P)        -> '<pid>';
norm(R) when is_reference(R)  -> '<ref>';
norm(T) when is_tuple(T)      -> list_to_tuple([norm(E) || E <- tuple_to_list(T)]);
norm(L) when is_list(L)       -> [norm(E) || E <- L];
norm(X)                       -> X.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
