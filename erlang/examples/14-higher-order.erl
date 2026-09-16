%% ============================================================
%% 14 - 高阶函数：把 fold 当成通用递归模板
%%
%%    第 12 章讲了 fun 的四种写法和闭包。这一章讲**怎么用**：
%%    列表库里的 map / filter / reverse / append / sum / max 全是
%%    「fold + 一个参数」的特例 —— 认准这一点，你自己要写的递归
%%    会减少一大半。
%%
%%    本示例所有输出都是与调度无关的确定值；map 相关的部分一律
%%    先 lists:sort（map 迭代顺序每次启动都随机，见第 10 章）。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/14-higher-order.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '14-higher-order' main -s init stop
%% ============================================================
-module('14-higher-order').

-export([main/0, fold_map/2, fold_filter/2, fold_reverse/1, fold_append/2,
         fold_sum/1, fold_max/1, compose/2, pipeline/1, adder/1, count_from/1]).

main() ->
    fold_as_template(),
    fold_direction(),
    short_circuit(),
    fun_as_parameter(),
    composition(),
    lazy_sequence(),
    io:format("~n==== 14 结束 ====~n").

%% 1) fold 是通用递归模板
%% ------------------------------------------------------------
%% lists:foldl(F, Init, List) 做的事：
%%     从 Init 出发，对列表里每个元素 X 依次算 Acc1 = F(X, Acc0)。
%% 只要你需要「从前往后遍历一边、攒一个东西」，它就是那个模板。
fold_as_template() ->
    io:format("== 1) 用 foldl 实现列表库里的那些函数 ==~n"),
    L = [1, 2, 3, 4],
    d("原列表", L),
    d("自写 map（每个元素 +1）", fold_map(fun(X) -> X + 1 end, L)),
    d("自写 filter（只留偶数）", fold_filter(fun(X) -> X rem 2 =:= 0 end, L)),
    d("自写 reverse", fold_reverse(L)),
    d("自写 append", fold_append([1, 2], [3, 4])),
    d("自写 sum", fold_sum(L)),
    d("自写 max", fold_max(L)),
    io:format("  ~ts~n", ["（以上每个都与对应的 lists:* 结果相同，下面直接比对）"]),
    d("fold_map 与 lists:map 一致",
      fold_map(fun(X) -> X + 1 end, L) =:= lists:map(fun(X) -> X + 1 end, L)),
    d("fold_filter 与 lists:filter 一致",
      fold_filter(fun(X) -> X rem 2 =:= 0 end, L)
      =:= lists:filter(fun(X) -> X rem 2 =:= 0 end, L)),
    d("fold_reverse 与 lists:reverse 一致", fold_reverse(L) =:= lists:reverse(L)),
    ok.

%% 注意参数顺序：foldl 的 fun 是 F(元素, 累加器)，不是反过来。
%% 写反了编译器不会拦（类型都对），结果会莫名其妙 —— 全靠记住。
%% 另外 [X | Acc] 这种「往头部塞」的累积方式得到的是**逆序**，
%% 所以最后要一次 lists:reverse/1（O(n)，很便宜）。
fold_map(F, L) ->
    lists:reverse(lists:foldl(fun(X, Acc) -> [F(X) | Acc] end, [], L)).

fold_filter(Pred, L) ->
    lists:reverse(lists:foldl(fun(X, Acc) ->
                                      case Pred(X) of
                                          true -> [X | Acc];
                                          false -> Acc
                                      end
                              end, [], L)).

fold_reverse(L) ->
    lists:foldl(fun(X, Acc) -> [X | Acc] end, [], L).

fold_append(A, B) ->
    lists:foldl(fun(X, Acc) -> [X | Acc] end, B, lists:reverse(A)).

fold_sum(L) ->
    lists:foldl(fun(X, Acc) -> X + Acc end, 0, L).

fold_max([H | T]) ->
    lists:foldl(fun(X, Acc) -> max(X, Acc) end, H, T).

%% 2) foldl 与 foldr 的求值顺序
%% ------------------------------------------------------------
%% 用「把访问到的元素依次攒进列表」来暴露顺序，不需要副作用：
%%   foldl 从左到右，foldr 从右到左。
%% 大多数时候该用 foldl（尾递归、常量栈）；foldr 只在
%% 「必须从右边开始」时用（例如按原顺序构造列表）。
fold_direction() ->
    io:format("~n== 2) foldl 与 foldr 的求值顺序 ==~n"),
    L = [1, 2, 3, 4],
    d("foldl 从左到右（把每个元素追加到尾部，顺序即访问顺序）",
      lists:foldl(fun(X, Acc) -> Acc ++ [X] end, [], L)),
    d("foldr 从右到左",
      lists:foldr(fun(X, Acc) -> Acc ++ [X] end, [], L)),
    %% foldr 配 [X|Acc] 反而能「原序」构造出列表 —— 它等价于 map
    d("foldr 配 [X|Acc] 就是 map（原序）",
      lists:foldr(fun(X, Acc) -> [X * 10 | Acc] end, [], L)),
    d("foldl 配 [X|Acc] 得到逆序",
      lists:foldl(fun(X, Acc) -> [X * 10 | Acc] end, [], L)),
    ok.

%% 3) 短路：any / all 会在有结论时立刻停下，map 不会
%% ------------------------------------------------------------
%% 用一个「碰到 touched 就抛异常」的探针函数来证明到底访问了几个元素：
%% 只要没抛异常，就说明后面的元素根本没被求值。
any_probe(hit)     -> true;
any_probe(touched) -> erlang:error(probe_touched);
any_probe(_)       -> false.

short_circuit() ->
    io:format("~n== 3) any / all 的短路 ==~n"),
    %% 注意这里**不能**用 hd([]) 之类，探针函数是主动抛异常的
    d("lists:any 命中 hit 就返回，后面的 touched 不会被求值",
      lists:any(fun any_probe/1, [nope, nope, hit, touched])),
    d("lists:all 遇到第一个 false 就返回，后面的 touched 不会被求值",
      lists:all(fun any_probe/1, [hit, nope, touched])),
    d("对照：lists:map 会遍历到底，于是碰到 touched 抛异常",
      to_error(fun() -> lists:map(fun any_probe/1, [hit, nope, touched]) end)),
    d("对照：lists:foreach 同样遍历到底",
      to_error(fun() -> lists:foreach(fun any_probe/1, [hit, touched]) end)),
    ok.

%% 4) 把 fun 当参数：谓词 / 变换器 / 比较器
%% ------------------------------------------------------------
%% 同一个函数配不同的 fun，就能得到不同的行为 —— 这是「把变化点参数化」。
%% 比较器一定要给「全序」：返回 true 表示「第一个参数应排在前面」。
fun_as_parameter() ->
    io:format("~n== 4) 谓词 / 变换器 / 比较器 ==~n"),
    People = [{bob, 30}, {alice, 25}, {carol, 35}],
    ByName = fun({A, _}, {B, _}) -> A =< B end,
    ByAge  = fun({_, A}, {_, B}) -> A =< B end,
    d("原数据", People),
    d("按名字排", lists:sort(ByName, People)),
    d("按年龄排", lists:sort(ByAge, People)),
    d("按谓词挑（年龄 > 28）", [P || P = {_, A} <- People, A > 28]),
    d("用谓词取反", lists:filter(fun(P) -> not age_gt(P, 28) end, People)),
    d("变换器：把年龄换成出生年份（2026 - age）",
      lists:map(fun({N, A}) -> {N, 2026 - A} end, People)),
    %% 常见做法：把「排序键提取」参数化，而不是给整张表写多个排序函数
    d("按任意键排序（复用同一段代码）",
      sort_by(fun({_, A}) -> A end, People)),
    ok.

age_gt({_, A}, N) -> A > N.

sort_by(KeyFun, L) ->
    lists:sort(fun(A, B) -> KeyFun(A) =< KeyFun(B) end, L).

%% 5) 组合与柯里化
%% ------------------------------------------------------------
%% Erlang 没有内置的 compose/pipeline，但写起来各一行。
%% 柯里化在 Erlang 里就是「返回一个捕获了参数的 fun」。
compose(F, G) -> fun(X) -> G(F(X)) end.

pipeline(Funs) -> fun(X) -> lists:foldl(fun(F, Acc) -> F(Acc) end, X, Funs) end.

adder(N) -> fun(X) -> X + N end.

composition() ->
    io:format("~n== 5) 组合与柯里化 ==~n"),
    Double = fun(X) -> X * 2 end,
    Inc = fun(X) -> X + 1 end,
    %% compose(F, G) 表示「先 F 再 G」，所以 compose(Double, Inc)(3) = 3*2+1 = 7
    d("compose(Double, Inc)(3)", compose(Double, Inc)(3)),
    d("compose(Inc, Double)(3)（顺序反过来结果就不同）", compose(Inc, Double)(3)),
    d("pipeline([Double, Inc, 平方])(3)",
      pipeline([Double, Inc, fun(X) -> X * X end])(3)),
    %% 柯里化：adder(10) 返回一个「+10」的函数。注意这里必须用 ds/2：
    %% [11,12,13] 是「可打印的字符列表」，~p 会把整个列表打成字符串 "\v\f\r"，
    %% 看不到数字。~w 不做这个美化，按列表原样打印。
    ds("lists:map(adder(10), [1,2,3])", lists:map(adder(10), [1, 2, 3])),
    d("同一件事用 ~p 打印（被当成字符串了）", lists:map(adder(10), [1, 2, 3])),
    ds("lists:map(adder(100), [1,2,3])", lists:map(adder(100), [1, 2, 3])),
    ok.

%% 6) 用 fun 表示惰性序列
%% ------------------------------------------------------------
%% 一个「迭代器」就是一个 fun()：调用它得到 {当前值, 下一个迭代器}。
%% 因为是惰性的，可以表示无限序列；用多少取多少。
count_from(N) -> fun() -> {N, count_from(N + 1)} end.

take(0, _Iter) -> [];
take(N, Iter) ->
    {V, Next} = Iter(),
    [V | take(N - 1, Next)].

lazy_sequence() ->
    io:format("~n== 6) 用 fun 表示惰性（可能是无限的）序列 ==~n"),
    Nats = count_from(1),
    d("从 1 开始取 5 个", take(5, Nats)),
    d("从 1 开始取 3 个（每次都是全新的一条序列）", take(3, count_from(1))),
    d("偶数序列的前 5 个", take(5, evens_from(2))),
    d("惰性序列 + 变换 + 过滤（取前 4 个偶数的平方）",
      take(4, pipeline_iter([fun(X) -> X * X end],
                            fun(X) -> X rem 2 =:= 0 end, evens_from(1)))),
    ok.

evens_from(N) when N rem 2 =:= 0 -> fun() -> {N, evens_from(N + 2)} end;
evens_from(N) -> evens_from(N + 1).

%% 给惰性序列加「变换」和「过滤」两级，思路和列表推导式一样，只是不求值
pipeline_iter(Transforms, Pred, Iter) ->
    fun() ->
            {V, Next} = Iter(),
            W = lists:foldl(fun(F, Acc) -> F(Acc) end, V, Transforms),
            case Pred(W) of
                true  -> {W, pipeline_iter(Transforms, Pred, Next)};
                false -> (pipeline_iter(Transforms, Pred, Next))()
            end
    end.

%% 把任意异常规整成 {error, Reason}，方便把「本该抛异常」的对照写进输出
to_error(F) ->
    try {ok, F()} catch Class:Reason -> {error, Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% d/2 用 ~p：可打印的字符列表会被美化成字符串（[101,102,103] → "efg"）。
%% 想强制按列表看数字，用 ds/2（内部用 ~w）。第 01 章有 ~p / ~w 的完整对照。
ds(Label, Value) -> io:format("  ~ts = ~w~n", [Label, Value]).
