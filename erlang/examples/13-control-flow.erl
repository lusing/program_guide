%% ============================================================
%% 13 - 分支与异常：case / if / try / receive / maybe
%%
%%    Erlang 的控制流都是「表达式」，都有值。
%%    本示例把这五种分支形式一次讲清，并给出各自的适用场景。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/13-control-flow.erl
%% 运行：
%%   erl -noshell -pa build -run '13-control-flow' main -s init stop
%% ============================================================
-module('13-control-flow').

-export([main/0, describe/1, sign/1, safe_div/2, classify/1, find_first/2]).

main() ->
    case_demo(),
    if_demo(),
    try_demo(),
    receive_demo(),
    maybe_demo(),
    when_to_use_what(),
    io:format("~n==== 13 结束 ====~n").

%% 1) case：按值的形状分派
%% ------------------------------------------------------------
%% 与函数多子句几乎等价，选哪个看「选择依据是不是参数本身」。
%% 对函数参数分派 → 用多子句；对中间结果分派 → 用 case。
describe({ok, V}) -> {success, V};
describe({error, Reason}) -> {failure, Reason};
describe([]) -> empty_list;
describe(L) when is_list(L) -> {list_of, length(L)};
describe(Other) -> {unknown, Other}.

case_demo() ->
    io:format("== 1) case ==~n"),
    d("describe({ok, 1})", describe({ok, 1})),
    d("describe({error, not_found})", describe({error, not_found})),
    d("describe([])", describe([])),
    d("describe([1,2,3])", describe([1, 2, 3])),
    d("describe(42)", describe(42)),
    %% case 也用在「对中间结果分派」
    d("对中间结果用 case", lookup_report(#{a => 1}, a)),
    d("对中间结果用 case（缺失）", lookup_report(#{a => 1}, b)),
    %% 没有任何子句匹配会抛 case_clause
    d("没有兜底子句时抛 case_clause",
      raises(fun(X) -> case X of only_this -> ok end end, something_else)),
    ok.

lookup_report(Map, Key) ->
    case maps:find(Key, Map) of
        {ok, V} when is_integer(V) -> {found_int, V};
        {ok, V} -> {found, V};
        error -> missing
    end.

%% 2) if：只按 guard 条件分派，不绑定变量
%% ------------------------------------------------------------
%% 注意：if **没有匹配所有情况的分支**时，会抛 if_clause 异常。
%% 所以最后一个分支几乎总是写 true -> ...。
sign(X) when is_number(X) ->
    if
        X > 0 -> positive;
        X < 0 -> negative;
        true -> zero          %% 这一行不能省
    end.

if_demo() ->
    io:format("~n== 2) if ==~n"),
    d("sign(5) / sign(-5) / sign(0)", [sign(N) || N <- [5, -5, 0]]),
    %% if 的分支里只能写 guard，不能有普通表达式
    d("if 没有 true 兜底时会抛 if_clause",
      raises(fun(X) -> if X > 10 -> big end end, 1)),
    %% 所以更推荐 case 或函数多子句；if 只适合「纯粹的条件阶梯」
    d("用 case 达到同样效果且更安全",
      (fun(X) -> case X > 10 of true -> big; false -> small end end)(1)),
    ok.

%% 3) try / catch / after
%% ------------------------------------------------------------
%% 异常有三个「类（Class）」：
%%   error   —— 运行时错误（badarg / badarith / badmatch / undef ...）
%%   exit    —— exit(Reason) 或进程被 link 杀掉
%%   throw   —— throw(Value)，专门用于「非本地返回」
%%
%% 捕获可以只写 Reason，也可以写 Class:Reason，还可以带 Stacktrace。
safe_div(_, 0) -> {error, divide_by_zero};
safe_div(A, B) when is_number(A), is_number(B) -> {ok, A / B}.

try_demo() ->
    io:format("~n== 3) try / catch / after ==~n"),
    d("安全除法（用返回值而不是异常）", safe_div(10, 4)),
    d("除零被前一个子句接住", safe_div(10, 0)),
    %% 三类异常都能用 Class:Reason 捕获。
    %% 注意列表推导的**生成器**是 {标签, Fun} 元组，把 Fun 取出来才是要调用的东西；
    %% 写成 [class_of(F) || F <- error_like_cases()] 的话 F 是元组不是函数，
    %% 调用变成「求值一个元组」，得到的是 badfun 而不是原异常。
    d("三类异常的 Class",
      [{Tag, class_of(F)} || {Tag, F} <- error_like_cases()]),
    d("三类异常的 Reason",
      [{Tag, reason_of(F)} || {Tag, F} <- error_like_cases()]),
    %% 陷阱：catch 里**不写 Class** 时，Class 默认为 throw，
    %% 所以 error 类和 exit 类都接不住、会直接崩掉进程。
    %% 这个陷阱没法在本示例里演示（一演示进程就崩、还会打崩溃日志），
    %% 请记住结论：永远写 Class:Reason 或 _:Reason，不要只写 Reason。
    %% 下面显式写 throw 类，于是只有 throw 那一个被接住，其余照旧抛出去 ——
    %% 用 to_error/1 包一层才敢在同一个进程里逐个试。
    d("只接 throw 类：写 throw:R 时 error/exit 类接不住",
      [{Tag, only_throw_caught(F)} || {Tag, F} <- error_like_cases()]),
    %% 带 stacktrace
    d("捕获时带上 stacktrace（长度 > 0）",
      stack_size_of(fun() -> erlang:error(boom) end) > 0),
    d("stacktrace 的第一帧是出错函数",
      first_stack_frame(fun() -> erlang:error(boom) end)),
    %% after 一定会执行
    d("after 一定执行（无论正常还是异常）", after_always_runs()),
    %% 把任意异常规整成 {error, _}，调用方只需要处理一种形状
    d("把任意异常规整成 {error, _}", normalize_all()),
    ok.

%% 三类异常各来一个
error_like_cases() ->
    Z = opaque_zero(),
    [{error, fun() -> erlang:error(e) end},
     {exit, fun() -> exit(x) end},
     {throw, fun() -> throw(t) end},
     {badarith, fun() -> 1 / Z end}].

class_of(F) ->
    try F() catch Class:_ -> Class end.

reason_of(F) ->
    try F() catch _:Reason -> Reason end.

%% 只接 throw 类：throw 类被**内层** throw_only/1 接住，
%% error / exit 类穿透内层继续往上抛，由**外层**的 Class:Reason 接住并标成 escaped。
%% 两层套起来才敢在同一个进程里逐个试 —— 否则 error 类会直接崩掉本进程。
only_throw_caught(F) ->
    try throw_only(F) catch Class:Reason -> {escaped, Class, Reason} end.

throw_only(F) ->
    try F() catch throw:R -> {caught_as_throw, R} end.

%% 用一个独立进程观察 after 是否执行；结论是布尔值，与调度无关。
%% 进程正常结束则收到消息，否则超时 —— 不依赖任何时序假设。
after_always_runs() ->
    Self = self(),
    Ref = make_ref(),
    spawn(fun() ->
                  Flag = try
                             erlang:error(x)
                         catch
                             _:_ -> caught
                         after
                             Self ! {Ref, after_ran}
                         end,
                  Self ! {Ref, value, Flag}
          end),
    R1 = receive {Ref, after_ran} -> true after 1000 -> false end,
    R2 = receive {Ref, value, _} -> true after 1000 -> false end,
    {after_ran, R1, value_delivered, R2}.

stack_size_of(F) ->
    try F() catch _:_:Stack -> length(Stack) end.

%% 注意 catch 里是 Class:Reason:Stacktrace，冒号后直接跟变量，
%% 写成 Class:Reason:[...] 是语法错误
first_stack_frame(F) ->
    try F() catch _:_:Stack -> hd(Stack) end.

%% 要演示「运行期」异常，值必须来自编译器**无法常量折叠**的来源：
%% opaque_zero() 在编译期算不出来（lists:seq 是远程调用），运行期返回 0。
%% 直接写 1 / 0 的话，erlc -Wall 会在编译期就报
%%   evaluation of operator '/'/2 will fail with a 'badarith' exception
opaque_zero() -> length(lists:seq(1, 0)).

normalize_all() ->
    Z = opaque_zero(),
    E = opaque_empty(),
    [{div_zero, to_error(fun() -> 1 / Z end)},
     {hd_empty, to_error(fun() -> hd(E) end)},
     {no_error, to_error(fun() -> ok end)}].

opaque_empty() -> lists:filter(fun(_) -> false end, [placeholder]).

to_error(F) ->
    try {ok, F()} catch Class:Reason -> {error, {Class, Reason}} end.

%% 4) receive：唯一和并发绑定的分支形式
%% ------------------------------------------------------------
%% receive 从当前进程的**邮箱**里取消息。支持：
%%   · 带模式的消息选择（不匹配的消息留在邮箱里，后面再取）
%%   · after 超时
%%   · 用 ref 把「回复」和「请求」配对（见第 23 章的协议设计）
receive_demo() ->
    io:format("~n== 4) receive ==~n"),
    Self = self(),
    Pid = spawn(fun() -> receive {Self, X} -> Self ! {echo, X} end end),
    Pid ! {Self, 42},
    d("取到匹配的消息", receive {echo, V} -> V after 1000 -> timeout end),
    %% 不匹配的消息会留在邮箱里，后续还能取到
    Self ! not_matching,
    Self ! {wanted, 1},
    d("先放两条，只取匹配的那条", receive {wanted, V2} -> V2 after 1000 -> timeout end),
    d("剩下那条还在邮箱里", receive not_matching -> picked after 0 -> empty end),
    %% 邮箱现在空了
    d("邮箱空了（after 0 立即返回）", receive anything -> got after 0 -> empty end),
    %% 常用技巧：用 after N 当作「轮询间隔」（见第 22 章）
    d("after 0 可以当「非阻塞收信」", receive nope -> yes after 0 -> no end),
    ok.

%% 5) maybe 表达式（OTP 25 引入，OTP 27 起默认启用）
%% ------------------------------------------------------------
%% 本机实测 erl_features:enabled() = [maybe_expr]，即默认可用。
%% 它解决的问题：一串「可能失败」的步骤，用 case 会写成很深的嵌套。
%%
%% 三条**实测**出来的语义（官方 doc/system/expressions.md「Maybe」一节）：
%%   1. 只有 `?=` 失败才走 else，且 else 匹配的是**失败的那个值本身**
%%      （不是 {badmatch, Value}，也不是异常堆栈）；
%%   2. body 里写明文的 `true = N >= 0` 失败会抛 {badmatch,false} 运行期错误，
%%      **不会**被 else 接住 —— 想让它走 else 必须写成 `true ?= (N >= 0)`；
%%   3. else 里所有子句都不匹配 → 抛 else_clause 运行期错误。
%% 另外：maybe 块里绑定的变量不能在块外使用（编译器会报 unsafe variable）。
classify(X) ->
    maybe
        {ok, N} ?= to_int(X),
        true ?= (N >= 0),           %% 必须用 ?=，见上面第 2 条
        {non_negative, N}
    else
        {error, R} -> {error, R};
        false -> {error, negative};
        Other -> {error, {unexpected, Other}}
    end.

%% 反例：同样想拦「负数」，但 body 里写的是普通 `=`。
%% 结果是抛 {badmatch,false} 运行期错误，else 的 false 子句**根本不会执行**。
classify_with_plain_match(X) ->
    maybe
        {ok, N} ?= to_int(X),
        true = N >= 0,
        {non_negative, N}
    else
        false -> {error, negative};
        Other -> {error, {unexpected, Other}}
    end.

%% 反例：else 没写兜底子句 → else_clause
%% 注意要让它真的落到 else：?= 失败的值必须**匹配不上**任何子句。
%% 若传一个 to_int 认不出的值，失败值是 {error,not_a_number}，正好命中 {error,R}，
%% 于是原样返回、根本走不到 else_clause。传 -5 让第二个 ?= 失败、值是 false 才行。
classify_no_fallback(X) ->
    maybe
        {ok, N} ?= to_int(X),
        true ?= (N >= 0),
        {non_negative, N}
    else
        {error, R} -> {error, R}
    end.

to_int(X) when is_integer(X) -> {ok, X};
to_int(X) when is_binary(X) ->
    case string:to_integer(binary_to_list(X)) of
        {N, []} -> {ok, N};
        _ -> {error, not_a_number}
    end;
to_int(_) -> {error, not_a_number}.

maybe_demo() ->
    io:format("~n== 5) maybe 表达式 ==~n"),
    d("别用 maybe 时的嵌套写法", nested_lookup(#{a => #{b => 1}}, [a, b])),
    d("classify(5)", classify(5)),
    d("classify(-5)（?= 失败，值是 false → 命中 else 的 false 子句）",
      classify(-5)),
    d("classify(<<\"7\">>)", classify(<<"7">>)),
    d("classify(\"abc\")（?= 失败，值是 {error,not_a_number}）",
      classify("abc")),
    d("classify(3.5)（值是 {error,not_a_number}）", classify(3.5)),
    %% 反例 1：普通 = 失败会抛 badmatch，else 接不住
    d("body 里写 true = N >= 0 的后果（badmatch 穿透 else）",
      to_error(fun() -> classify_with_plain_match(-5) end)),
    %% 反例 2：else 没有兜底子句
    d("else 无兜底子句时抛 else_clause",
      to_error(fun() -> classify_no_fallback(-5) end)),
    ok.

%% 对照：不用 maybe 时的深层嵌套
nested_lookup(M, [K]) -> maps:find(K, M);
nested_lookup(M, [K | Rest]) ->
    case maps:find(K, M) of
        {ok, Inner} when is_map(Inner) -> nested_lookup(Inner, Rest);
        _ -> error
    end.

%% 6) 该怎么选
%% ------------------------------------------------------------
when_to_use_what() ->
    io:format("~n== 6) 选择建议 ==~n"),
    Tips = [{"函数参数的不同形状", "函数多子句 + guard"},
            {"中间结果的形状", "case"},
            {"纯条件阶梯（无变量绑定）", "if（记得 true 兜底）"},
            {"可能失败的调用链", "try/catch，或返回 {ok,_}|{error,_}"},
            {"等消息 / 超时", "receive ... after"},
            {"连续多个可能失败的步骤", "maybe 表达式"}],
    io:format("~n"),
    [io:format("  ~ts -> ~ts~n", [pad(A, 40), B]) || {A, B} <- Tips],
    %% 顺带说明：为什么上面不能直接写 ~-40ts
    d("~ts 的宽度按字符数算，中文占两列，直接用 ~-40ts 会错位（字符数 / 显示列数）",
      {length("函数参数的不同形状"), disp_width("函数参数的不同形状")}),
    %% 顺便演示 find_first/2 的两种返回风格
    d("find_first 找到", find_first(fun(X) -> X > 2 end, [1, 2, 3])),
    d("find_first 没找到（返回 error 而不是抛）", find_first(fun(X) -> X > 9 end, [1, 2, 3])),
    ok.

%% io_lib 的字段宽度按**字符数**填充，一个中日韩汉字占两个终端列，
%% 所以含中文的表格直接用 ~-28ts 会参差不齐。这里手写一个按显示宽度补空格的版本。
disp_width(S) ->
    lists:sum([char_cols(C) || C <- unicode:characters_to_list(S)]).

char_cols(C) when C >= 16#1100, C =< 16#115F -> 2;   %% 谚文字母
char_cols(C) when C >= 16#2E80, C =< 16#A4CF -> 2;   %% CJK 部首/汉字/假名
char_cols(C) when C >= 16#AC00, C =< 16#D7A3 -> 2;   %% 谚文音节
char_cols(C) when C >= 16#F900, C =< 16#FAFF -> 2;   %% CJK 兼容汉字
char_cols(C) when C >= 16#FE30, C =< 16#FE6F -> 2;   %% CJK 兼容形式
char_cols(C) when C >= 16#FF00, C =< 16#FF60 -> 2;   %% 全角形式
char_cols(C) when C >= 16#FFE0, C =< 16#FFE6 -> 2;   %% 全角符号
char_cols(_) -> 1.

pad(S, Width) ->
    case disp_width(S) of
        W when W >= Width -> S;
        W -> S ++ lists:duplicate(Width - W, $\s)
    end.

%% 库函数风格：找不到返回 error，而不是抛异常
find_first(_Pred, []) -> error;
find_first(Pred, [H | T]) ->
    case Pred(H) of
        true -> {ok, H};
        false -> find_first(Pred, T)
    end.

raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
