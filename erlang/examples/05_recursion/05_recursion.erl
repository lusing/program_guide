%% ============================================================
%% 05_recursion —— 递归与尾调用
%%
%%    Erlang 没有循环语句（没有 for / while）。所有重复都靠递归。
%%    因此「尾递归」在这里不是优化技巧，而是**基本功**：
%%    尾调用会复用当前栈帧，非尾调用则要一直堆着等返回。
%%
%%    本示例用「递归到自己最深处时该进程占多少内存」来量化这个差别。
%%    实测（OTP 29 / 本机 64 位）：深度 200000 时
%%      非尾递归峰值 2546256 words，尾递归峰值 2624 words，相差约 970 倍。
%%    具体数值随实现/机器变化，所以示例只打印与实现无关的布尔结论。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/05_recursion examples/05_recursion/05_recursion.erl
%% 运行：
%%   erl -noshell -pa build/05_recursion -run '05_recursion' main -s init stop
%% ============================================================
-module('05_recursion').

-export([main/0, fact/1, fib/1, sum_to/1, depth_count/1, is_even/1, rev_map/2,
         count_down/1, count_down_tail/1, eval/1]).

%% 1) 递归的两种写法
%% ------------------------------------------------------------
%% 非尾递归：返回前还要做一次 +1，编译器无法复用栈帧
count_down(0) -> 0;
count_down(N) -> 1 + count_down(N - 1).

%% 尾递归：最后一步就是调用自己，累加结果放在**参数**里
count_down_tail(N) -> count_down_tail(N, 0).
count_down_tail(0, Acc) -> Acc;
count_down_tail(N, Acc) -> count_down_tail(N - 1, Acc + 1).

main() ->
    tail_call_cost(),
    classic_examples(),
    mutual_recursion(),
    list_recursion(),
    recurse_over_variants(),
    io:format("~n==== 05 结束 ====~n").

%% 2) 用内存量化尾调用
%% ------------------------------------------------------------
%% 把递归放在一个独立进程里跑，这样它的堆从很小的基线开始长，
%% 而且不会污染主进程。在最深处读自己的 memory 就是「峰值」。
peak_memory(Fun, N) ->
    Self = self(),
    spawn(fun() ->
        _ = Fun(N),
        Self ! {peak, element(2, erlang:process_info(self(), memory))}
    end),
    receive {peak, M} -> M after 10000 -> timeout end.

tail_call_cost() ->
    io:format("== 1) 尾调用到底省什么 ==~n"),
    Depth = 200000,
    NonTail = peak_memory(fun count_down/1, Depth),
    Tail = peak_memory(fun count_down_tail/1, Depth),
    d("递归深度", Depth),
    d("非尾递归峰值 > 尾递归峰值 * 10", NonTail > Tail * 10),
    d("两者结果相同", count_down(Depth) =:= count_down_tail(Depth)),
    ok.

%% 3) 经典递归：阶乘、斐波那契、求和
%% ------------------------------------------------------------
%% 阶乘：n! 增长极快，Erlang 的任意精度整数照单全收
fact(N) when is_integer(N), N >= 0 -> fact(N, 1).

fact(0, Acc) -> Acc;
fact(N, Acc) -> fact(N - 1, N * Acc).

%% 斐波那契：朴素递归是指数复杂度，这里用「双累加器」做到 O(N)
fib(N) when is_integer(N), N >= 0 -> fib(N, 0, 1).

fib(0, A, _B) -> A;
fib(N, A, B) -> fib(N - 1, B, A + B).

sum_to(N) when is_integer(N), N >= 0 -> sum_to(N, 0).

sum_to(0, Acc) -> Acc;
sum_to(N, Acc) -> sum_to(N - 1, Acc + N).

classic_examples() ->
    io:format("~n== 2) 经典递归 ==~n"),
    d("fact(10)", fact(10)),
    d("fact(50) 的位数", length(integer_to_list(fact(50)))),
    d("fib(10) / fib(30) / fib(80)", {fib(10), fib(30), fib(80)}),
    d("sum_to(100)", sum_to(100)),
    d("sum_to(100) 与 lists:sum 一致", sum_to(100) =:= lists:sum(lists:seq(1, 100))),
    ok.

%% 4) 相互递归
%% ------------------------------------------------------------
%% Erlang 没有「先声明后使用」的限制，函数之间可以直接互相调用。
is_even(0) -> true;
is_even(N) when N > 0 -> is_odd(N - 1);
is_even(N) -> is_even(-N).

is_odd(0) -> false;
is_odd(N) when N > 0 -> is_even(N - 1);
is_odd(N) -> is_odd(-N).

mutual_recursion() ->
    io:format("~n== 3) 相互递归 ==~n"),
    d("is_even/1 与 is_odd/1 互相调用", [{N, is_even(N)} || N <- lists:seq(0, 6)]),
    d("is_even(-7)", is_even(-7)),
    ok.

%% 5) 对列表递归：这是 Erlang 里最常见的递归形态
%% ------------------------------------------------------------
%% 非尾递归版（保持顺序、最直观）
depth_count([]) -> 0;
depth_count([_ | T]) -> 1 + depth_count(T).

%% 尾递归版（用累加器计数）
depth_count_tail(L) -> depth_count_tail(L, 0).
depth_count_tail([], Acc) -> Acc;
depth_count_tail([_ | T], Acc) -> depth_count_tail(T, Acc + 1).

%% 尾递归但会反转结果，所以末尾要 reverse 回来
rev_map(F, L) -> lists:reverse(rev_map(F, L, [])).

rev_map(_F, [], Acc) -> Acc;
rev_map(F, [H | T], Acc) -> rev_map(F, T, [F(H) | Acc]).

list_recursion() ->
    io:format("~n== 4) 列表上的递归 ==~n"),
    L = lists:seq(1, 100000),
    d("对 5 个元素做非尾递归计数", depth_count([a, b, c, d, e])),
    d("与非尾递归版结果一致（10 万元素）", depth_count(L) =:= depth_count_tail(L)),
    d("尾递归版也能改写 map，只是要 reverse 一次",
      rev_map(fun(X) -> X * 2 end, [1, 2, 3, 4])),
    d("与 lists:map 结果一致",
      rev_map(fun(X) -> X * 2 end, L) =:= lists:map(fun(X) -> X * 2 end, L)),
    ok.

%% 6) 递归处理递归数据结构：表达式求值器
%% ------------------------------------------------------------
eval({num, N}) -> N;
eval({add, A, B}) -> eval(A) + eval(B);
eval({sub, A, B}) -> eval(A) - eval(B);
eval({mul, A, B}) -> eval(A) * eval(B);
%% 注意：guard 看到的 B 是**语法树节点** {num, 0}，不是求值后的 0，
%% 所以「除零判断」必须在求值之后再做，不能靠 guard。
eval({divi, A, B}) -> safe_div(eval(A), eval(B)).

safe_div(_, 0) -> {error, divide_by_zero};
safe_div(A, B) -> A div B.

recurse_over_variants() ->
    io:format("~n== 5) 递归处理递归数据结构 ==~n"),
    Expr = {add, {mul, {num, 2}, {num, 3}}, {sub, {num, 10}, {num, 4}}},
    d("表达式 (2*3) + (10-4)", eval(Expr)),
    d("嵌套的除法表达式", eval({divi, {num, 100}, {sub, {num, 3}, {num, 1}}})),
    d("除零被兜底子句接住", eval({divi, {num, 1}, {num, 0}})),
    d("深度递归的加法链",
      eval(lists:foldl(fun(N, Acc) -> {add, Acc, {num, N}} end, {num, 0},
                       lists:seq(1, 1000)))),
    ok.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
