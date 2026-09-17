%% ============================================================
%% 07_funs —— fun、高阶函数与推导式
%%
%%    Erlang 的函数是一等值：可以存进变量、放进列表、当参数传、
%%    当返回值返回。fun 捕获的是**变量的当前值**（值捕获）——
%%    不可变语言里根本不存在「闭包陷阱」。
%%    推导式 [ X || 生成器, 过滤器 ] 则是 map+filter 的语法糖。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/07_funs examples/07_funs/07_funs.erl
%% 运行：
%%   erl -noshell -pa build/07_funs -run '07_funs' main -s init stop
%% ============================================================
-module('07_funs').

-export([main/0, adder/1, compose/2, pipeline/1, sort_by/2,
         fold_map/2, fold_filter/2, fold_sum/1, quicksort/1,
         flatten_deep/1, word_freq/1, take/2, count_from/1,
         any_probe/1, to_error/1, evens_from/1]).

main() ->
    syntax_forms(),
    closures(),
    fold_as_template(),
    short_circuit(),
    predicates_transformers_comparators(),
    composition(),
    recursion_with_funs(),
    comprehension_basics(),
    multiple_generators(),
    binary_comprehensions(),
    comprehension_in_practice(),
    lazy_sequence(),
    io:format("~n==== 07 结束 ====~n").

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
    %% ③ 外部 fun 引用：fun M:F/A
    d("fun erlang:max/2", (fun erlang:max/2)(3, 7)),
    %% ④ 本地 fun 引用（更快；热加载语义见 23 章）
    d("fun local_helper/1", (fun local_helper/1)(5)),
    d("is_function(F1, 1) / is_function(F1, 2)", {is_function(F1, 1), is_function(F1, 2)}),
    d("erlang:fun_info(F1, arity)", element(2, erlang:fun_info(F1, arity))),
    ok.

local_helper(X) -> X * 100.

%% 2) 闭包与值捕获
%% ------------------------------------------------------------
%% fun 捕获的是创建时变量绑定的值。变量不可能被重新赋值，
%% 所以「循环里创建一堆 fun 全引用同一个变量」那类问题不存在。
closures() ->
    io:format("~n== 2) 闭包与值捕获 ==~n"),
    N = 10,
    AddN = fun(X) -> X + N end,
    d("捕获 N=10 的 fun 调用 5 次", AddN(5)),
    d("同一个 fun 调三次结果相同", {AddN(1), AddN(1), AddN(1)}),
    %% 函数工厂：返回捕获了参数的 fun（Erlang 版柯里化）
    d("adder(2)(10) / adder(3)(10)", {adder(2)(10), adder(3)(10)}),
    ok.

adder(N) -> fun(X) -> X + N end.

%% 3) fold 是通用递归模板
%% ------------------------------------------------------------
%% map / filter / reverse / sum 全是「fold + 一个 fun」的特例——
%% 认准这一点，你要手写的递归会少一大半。
%% 注意参数顺序：foldl 的 fun 是 F(元素, 累加器)。
fold_as_template() ->
    io:format("~n== 3) fold 是通用模板 ==~n"),
    L = [1, 2, 3, 4],
    d("原列表", L),
    d("自写 map（+1）", fold_map(fun(X) -> X + 1 end, L)),
    d("自写 filter（偶数）", fold_filter(fun(X) -> X rem 2 =:= 0 end, L)),
    d("自写 sum", fold_sum(L)),
    d("foldl 配 [X|Acc] 是逆序；foldr 是正序",
      {lists:foldl(fun(X, Acc) -> [X * 10 | Acc] end, [], L),
       lists:foldr(fun(X, Acc) -> [X * 10 | Acc] end, [], L)}),
    ok.

fold_map(F, L) ->
    lists:reverse(lists:foldl(fun(X, Acc) -> [F(X) | Acc] end, [], L)).

fold_filter(Pred, L) ->
    lists:reverse(lists:foldl(fun(X, Acc) ->
                                      case Pred(X) of
                                          true -> [X | Acc];
                                          false -> Acc
                                      end
                              end, [], L)).

fold_sum(L) ->
    lists:foldl(fun(X, Acc) -> X + Acc end, 0, L).

%% 4) any / all 短路（用异常探针证明）
%% ------------------------------------------------------------
any_probe(hit)     -> true;
any_probe(touched) -> erlang:error(probe_touched);
any_probe(_)       -> false.

short_circuit() ->
    io:format("~n== 4) any / all 短路 ==~n"),
    d("any 命中 hit 就返回，touched 不会被求值",
      lists:any(fun any_probe/1, [nope, nope, hit, touched])),
    d("all 遇到第一个 false 就返回，touched 不会被求值",
      lists:all(fun any_probe/1, [hit, nope, touched])),
    d("对照：map 会遍历到底，碰到 touched 抛异常",
      to_error(fun() -> lists:map(fun any_probe/1, [hit, nope, touched]) end)),
    ok.

to_error(F) ->
    try {ok, F()} catch Class:Reason -> {error, Class, Reason} end.

%% 5) 谓词 / 变换器 / 比较器：把变化点参数化
%% ------------------------------------------------------------
predicates_transformers_comparators() ->
    io:format("~n== 5) 谓词 / 变换器 / 比较器 ==~n"),
    People = [{bob, 30}, {alice, 25}, {carol, 35}],
    d("按名字排", lists:sort(fun({A, _}, {B, _}) -> A =< B end, People)),
    d("按年龄排（sort_by 复用同一段代码）",
      sort_by(fun({_, A}) -> A end, People)),
    d("变换器：年龄→出生年份",
      lists:map(fun({N, A}) -> {N, 2026 - A} end, People)),
    ok.

sort_by(KeyFun, L) ->
    lists:sort(fun(A, B) -> KeyFun(A) =< KeyFun(B) end, L).

%% 6) 组合与柯里化
%% ------------------------------------------------------------
compose(F, G) -> fun(X) -> G(F(X)) end.       %% 先 F 再 G

pipeline(Funs) -> fun(X) -> lists:foldl(fun(F, Acc) -> F(Acc) end, X, Funs) end.

composition() ->
    io:format("~n== 6) 组合与柯里化 ==~n"),
    Double = fun(X) -> X * 2 end,
    Inc = fun(X) -> X + 1 end,
    d("compose(Double, Inc)(3)", compose(Double, Inc)(3)),
    d("compose(Inc, Double)(3)（顺序反了结果不同）", compose(Inc, Double)(3)),
    d("pipeline([Double, Inc, 平方])(3)",
      pipeline([Double, Inc, fun(X) -> X * X end])(3)),
    %% 柯里化注意：[11,12,13] 是可打印字符列表，~p 会打成 "\v\f\r"，
    %% 想按列表看数字用 ~w（02 章的 ~p/~w 对照）
    ds("lists:map(adder(10), [1,2,3])", lists:map(adder(10), [1, 2, 3])),
    ok.

%% 7) 匿名 fun 的递归
%% ------------------------------------------------------------
recursion_with_funs() ->
    io:format("~n== 7) 匿名 fun 的递归 ==~n"),
    %% 标准写法：把自己当第一个参数传进去
    Fact = fun F(0) -> 1;
               F(N) -> N * F(N - 1)
            end,
    d("fun F(...) end 自递归 fact(6)", Fact(6)),
    d("具名函数 + fun 引用更清晰", (fun my_fact/1)(6)),
    ok.

my_fact(0) -> 1;
my_fact(N) -> N * my_fact(N - 1).

%% 8) 推导式：基本形式
%% ------------------------------------------------------------
%% [ 输出 || 生成器, 过滤器... ]；过滤器就是一个 guard。
comprehension_basics() ->
    io:format("~n== 8) 推导式 ==~n"),
    d("[X*2 || X <- [1,2,3]]", [X * 2 || X <- [1, 2, 3]]),
    d("[X || X <- 1..10, 偶数]", [X || X <- lists:seq(1, 10), X rem 2 =:= 0]),
    d("模式解构 [{N,_} <- ...]", [N * 10 || {_K, N} <- [{a, 1}, {b, 2}]]),
    %% 生成器里的模式不匹配会被**静默跳过**——很多 bug 的来源
    d("模式不匹配静默跳过", [X || {X} <- [{1}, {2}, not_tuple, {3}]]),
    d("用生成器当局部变量（完全平方数）",
      [N || N <- lists:seq(1, 50), S <- [trunc(math:sqrt(N))], S * S =:= N]),
    ok.

%% 9) 多个生成器 = 嵌套循环
%% ------------------------------------------------------------
%% 右边的生成器在**内层**；后面生成器的范围可以用前面的变量。
multiple_generators() ->
    io:format("~n== 9) 多个生成器 ==~n"),
    d("笛卡尔积", [[A, B] || A <- [1, 2], B <- [x, y]]),
    d("20 以内的勾股数",
      [{A, B, C} || C <- lists:seq(1, 20),
                    B <- lists:seq(1, C),
                    A <- lists:seq(1, B),
                    A * A + B * B =:= C * C]),
    d("第二个生成器的范围由第一个决定",
      [{N, M} || N <- lists:seq(1, 3), M <- lists:seq(1, N)]),
    ok.

%% 10) 二进制推导式
%% ------------------------------------------------------------
%% 两条硬规则：生成器写 <=；输出表达式必须是二进制 <<...>>。
binary_comprehensions() ->
    io:format("~n== 10) 二进制推导式 ==~n"),
    Bin = <<1, 2, 3, 4, 5, 6>>,
    d("原样复制", <<<<X>> || <<X>> <= Bin>>),
    d("取偶数再翻倍", <<<<(X * 2)>> || <<X>> <= Bin, X rem 2 =:= 0>>),
    d("大端读 2 字节重写成小端",
      <<<<Y:16/little>> || <<Y:16/big>> <= <<1, 0, 2, 0, 3, 0>>>>),
    Utf8 = <<"中文abc"/utf8>>,
    d("按 utf8 解出码点", [C || <<C/utf8>> <= Utf8]),
    d("只保留 ASCII（重编码为二进制）",
      <<<<C/utf8>> || <<C/utf8>> <= Utf8, C < 128>>),
    ok.

%% 11) 实战：推导式的常用姿势
%% ------------------------------------------------------------
comprehension_in_practice() ->
    io:format("~n== 11) 实战用法 ==~n"),
    d("flatten_deep([1,[2,[3,[4]]],5])", flatten_deep([1, [2, [3, [4]]], 5])),
    d("带下标", lists:zip(lists:seq(1, 2), [a, b])),
    d("词频统计（排序后输出）", word_freq(["a", "b", "a", "c", "a", "b"])),
    d("quicksort([3,6,1,8,2])", quicksort([3, 6, 1, 8, 2])),
    ok.

flatten_deep(L) ->
    [X || E <- L, X <- do_flatten(E)].

do_flatten(L) when is_list(L) -> flatten_deep(L);
do_flatten(X) -> [X].

%% 词频：foldl + maps:update_with；输出前 sort（map 迭代顺序随机，10 章）
word_freq(Words) ->
    Counts = lists:foldl(fun(W, Acc) ->
                                 maps:update_with(W, fun(N) -> N + 1 end, 1, Acc)
                         end, #{}, Words),
    lists:sort(maps:to_list(Counts)).

quicksort([]) -> [];
quicksort([Pivot | Rest]) ->
    quicksort([X || X <- Rest, X < Pivot])
        ++ [Pivot] ++
        quicksort([X || X <- Rest, X >= Pivot]).

%% 12) 用 fun 表示惰性序列
%% ------------------------------------------------------------
%% 迭代器 = fun()：调用得 {当前值, 下一个迭代器}。可以表示无限序列。
count_from(N) -> fun() -> {N, count_from(N + 1)} end.

take(0, _Iter) -> [];
take(N, Iter) ->
    {V, Next} = Iter(),
    [V | take(N - 1, Next)].

lazy_sequence() ->
    io:format("~n== 12) 惰性序列 ==~n"),
    d("自然数前 5 个", take(5, count_from(1))),
    d("偶数序列前 5 个", take(5, evens_from(2))),
    d("前 4 个偶数的平方", take(4, squares_of_evens(evens_from(2)))),
    ok.

evens_from(N) when N rem 2 =:= 0 -> fun() -> {N, evens_from(N + 2)} end;
evens_from(N) -> evens_from(N + 1).

squares_of_evens(Iter) ->
    fun() ->
        {V, Next} = Iter(),
        {V * V, squares_of_evens(Next)}
    end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% ~w 不做「可打印列表美化」，强制按列表看数字
ds(Label, Value) -> io:format("  ~ts = ~w~n", [Label, Value]).
