%% ============================================================
%% 12 - 函数与闭包
%%
%%    Erlang 的函数是一等值：可以存进变量、放进列表、当参数传、
%%    当返回值返回。fun 捕获的是**变量的当前值**（值捕获），
%%    不是变量的位置 —— 这一点和很多语言不同。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/12-funs.erl
%% 运行：
%%   erl -noshell -pa build -run '12-funs' main -s init stop
%% ============================================================
-module('12-funs').

-export([main/0, adder/1, apply_n/3, compose/2]).

main() ->
    syntax_forms(),
    closures_and_capture(),
    higher_order(),
    returning_funs(),
    funs_in_data(),
    recursion_with_funs(),
    io:format("~n==== 12 结束 ====~n").

%% 1) fun 的四种写法
%% ------------------------------------------------------------
syntax_forms() ->
    io:format("== 1) fun 的四种写法 ==~n"),
    %% ① 匿名 fun
    F1 = fun(X) -> X * 2 end,
    d("匿名 fun fun(X) -> X * 2 end", F1(21)),
    %% ② 多子句 fun（可以带 guard）
    F2 = fun(X) when X > 0 -> positive;
            (0) -> zero;
            (_) -> negative
         end,
    d("多子句 fun", [F2(N) || N <- [1, 0, -1]]),
    %% ③ fun 引用：fun Name/Arity，直接指向已存在的函数
    F3 = fun erlang:max/2,
    d("fun erlang:max/2", F3(3, 7)),
    %% ④ 本地 fun 引用（不能捕获任何变量，但更快）
    d("fun local_helper/1", (fun local_helper/1)(5)),
    %% arity 是 fun 的一部分
    d("is_function(F1, 1)", is_function(F1, 1)),
    d("is_function(F1, 2)", is_function(F1, 2)),
    d("erlang:fun_info(F1, arity)", element(2, erlang:fun_info(F1, arity))),
    d("erlang:fun_info 的 type / name",
      {element(2, erlang:fun_info(F1, type)), element(2, erlang:fun_info(fun local_helper/1, name))}),
    ok.

local_helper(X) -> X * 100.

%% 2) 闭包与「值捕获」
%% ------------------------------------------------------------
%% 关键点：fun 捕获的是**创建时**变量绑定的值。
%% 变量在 Erlang 里不可能被重新赋值，所以不存在
%% 「循环里创建一堆 fun 结果全都引用同一个变量」那类问题。
closures_and_capture() ->
    io:format("~n== 2) 闭包与值捕获 ==~n"),
    N = 10,
    AddN = fun(X) -> X + N end,
    d("捕获 N=10 的 fun 调用 5 次", AddN(5)),
    %% N 不可能被改写，所以多次调用结果必然一致
    d("同一个 fun 调三次结果相同", {AddN(1), AddN(1), AddN(1)}),
    %% 也可以捕获函数（这就是一个简单的「函数工厂」）
    Double = adder(2),
    Triple = adder(3),
    d("adder(2)(10) / adder(3)(10)", {Double(10), Triple(10)}),
    %% 每次调用 make_counter 得到互相独立的闭包
    C1 = make_counter(0),
    C2 = make_counter(100),
    d("两个独立计数器", {[C1(), C1(), C1()], [C2(), C2()]}),
    ok.

adder(N) -> fun(X) -> X + N end.

%% 用闭包 + 进程状态模拟一个计数器（真正的可变状态在进程里，见第 23 章）
make_counter(_Start) ->
    Pid = spawn(fun() -> counter_loop(0) end),
    fun() ->
        Pid ! {next, self()},
        receive {value, V} -> V end
    end.

counter_loop(N) ->
    receive
        {next, From} ->
            From ! {value, N},
            counter_loop(N + 1)
    end.

%% 3) 高阶函数：把 fun 当参数
%% ------------------------------------------------------------
higher_order() ->
    io:format("~n== 3) fun 当参数 ==~n"),
    d("apply_n(fun(X)->X*X end, 3, 2)", apply_n(fun(X) -> X * X end, 3, 2)),
    d("两次 compose", (compose(fun(X) -> X + 1 end, fun(X) -> X * 2 end))(5)),
    d("用 fun 当比较器排序",
      lists:sort(fun(A, B) -> A > B end, [3, 1, 2])),
    d("用 fun 做按键提取再排序",
      lists:sort(fun(A, B) -> element(2, A) =< element(2, B) end,
                 [{a, 3}, {b, 1}, {c, 2}])),
    d("lists:foldl 里用闭包累积", lists:foldl(fun(X, Acc) -> Acc ++ [X] end, [], [1, 2, 3])),
    d("自己写一个 take_while",
      take_while(fun(X) -> X < 4 end, [1, 2, 5, 1])),
    ok.

%% 把 F 连用 N 次
apply_n(F, N, Start) ->
    lists:foldl(fun(_, Acc) -> F(Acc) end, Start, lists:seq(1, N)).

%% 组合两个一元函数：先 F 再 G
compose(F, G) -> fun(X) -> G(F(X)) end.

take_while(_Pred, []) -> [];
take_while(Pred, [H | T]) ->
    case Pred(H) of
        true -> [H | take_while(Pred, T)];
        false -> []
    end.

%% 4) 返回 fun：函数工厂
%% ------------------------------------------------------------
returning_funs() ->
    io:format("~n== 4) fun 当返回值 ==~n"),
    %% 用 fun 做「校验器工厂」
    Checkers = [{min_len, min_len(3)}, {is_int, fun(X) -> is_integer(X) end}],
    d("校验器工厂", [{Name, F("abcd")} || {Name, F} <- Checkers]),
    d("同一个校验器换个输入", [{Name, F("ab")} || {Name, F} <- Checkers]),
    %% 用 fun 做「记忆化」的简化版（缓存表放在闭包外的 ETS）
    Tab = ets:new(memo, [set, public]),
    Slow = fun(N) -> timer:sleep(0), N * N end,
    Memo = fun(N) ->
                   case ets:lookup(Tab, N) of
                       [{N, V}] -> {cached, V};
                       [] -> V = Slow(N), ets:insert(Tab, {N, V}), {computed, V}
                   end
           end,
    d("第一次算", Memo(6)),
    d("第二次命中缓存", Memo(6)),
    ets:delete(Tab),
    ok.

min_len(N) -> fun(S) -> length(S) >= N end.

%% 5) 把 fun 存进数据结构
%% ------------------------------------------------------------
funs_in_data() ->
    io:format("~n== 5) fun 存进数据结构 ==~n"),
    Ops = #{add => fun(A, B) -> A + B end,
            sub => fun(A, B) -> A - B end,
            mul => fun(A, B) -> A * B end},
    d("用 map 做命令表（键排序后输出）",
      lists:sort([{K, F(6, 3)} || {K, F} <- lists:sort(maps:to_list(Ops))])),
    %% proplist 形式的命令表也很常见
    Pipeline = [fun(X) -> X + 1 end, fun(X) -> X * 2 end, fun(X) -> X - 3 end],
    d("把一串 fun 依次施加", lists:foldl(fun(F, Acc) -> F(Acc) end, 10, Pipeline)),
    %% fun 可以作为消息发送（同一节点内）
    Me = self(),
    Pid = spawn(fun() -> receive {run, F} -> Me ! {result, F(7)} end end),
    Pid ! {run, fun(X) -> X * 3 end},
    d("把 fun 当消息发给另一个进程", receive {result, R} -> R after 1000 -> timeout end),
    ok.

%% 6) 用 fun 写递归：让匿名函数也能递归
%% ------------------------------------------------------------
%% 匿名 fun 没法直接引用自己（没有名字），标准做法是
%% 「把自身作为第一个参数传进来」。
recursion_with_funs() ->
    io:format("~n== 6) 匿名 fun 的递归 ==~n"),
    %% 经典写法：Y 组合子的 Erlng 版（自己传自己）
    Fact = fun(_F, 0) -> 1;
              (F, N) -> N * F(F, N - 1)
           end,
    d("匿名 fun 实现阶乘 fact(6)", Fact(Fact, 6)),
    %% 更实用的做法：写成具名函数再取 fun 引用
    d("具名函数 + fun 引用更清晰", (fun my_fact/1)(6)),
    ok.

my_fact(0) -> 1;
my_fact(N) -> N * my_fact(N - 1).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
