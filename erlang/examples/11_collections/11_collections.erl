%% ============================================================
%% 11_collections —— proplists、sets、queue、array
%%
%%    都是「配置/容器」，但标准库给了好几套实现，接口相似、
%%    代价与顺序完全不同。这一章把选型讲清楚：
%%      proplists  配置与选项列表（允许重复键、先给的赢）
%%      sets/ordsets/gb_sets  三套集合（map/有序列表/平衡树）
%%      queue      FIFO（in/snoc 参数顺序相反！）
%%      array      稀疏数组（越界不报错）
%%
%%    本示例所有输出都先归一化（sort / to_list），因为
%%    sets 的遍历顺序每次启动都随机。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/11_collections examples/11_collections/11_collections.erl
%% 运行：
%%   erl -noshell -pa build/11_collections -run '11_collections' main -s init stop
%% ============================================================
-module('11_collections').

-export([main/0, open/1, describe_open/1, mk/2, as_list/2, raises/2]).

main() ->
    proplist_shapes(),
    proplist_duplicates(),
    proplist_flags(),
    set_impls(),
    set_algebra(),
    gb_sets_extras(),
    queues(),
    arrays(),
    options_api(),
    choosing(),
    io:format("~n==== 11 结束 ====~n").

%% 1) proplists：形状与读取
%% ------------------------------------------------------------
%% 属性列表（proplist）里的项有三种合法形状：
%%   {Key, Value}   最常见
%%   Key            裸原子，被当成 {Key, true}
%%   其它           会被取值函数**静默忽略**（不报错！）
proplist_shapes() ->
    io:format("== 1) proplists：形状与读取 ==~n"),
    Opts = [{verbose, true}, debug, {retries, 3}, 42],
    d("属性列表（42 不是合法项，会被静默忽略）", Opts),
    d("get_value(verbose, Opts)", proplists:get_value(verbose, Opts)),
    d("get_value(debug, Opts)（裸原子等价 {debug,true}）",
      proplists:get_value(debug, Opts)),
    d("get_value(missing, Opts) → undefined", proplists:get_value(missing, Opts)),
    d("get_value(missing, Opts, 60) → 三参版兜底",
      proplists:get_value(missing, Opts, 60)),
    d("lookup(debug, Opts)（拿整个项而不是值）", proplists:lookup(debug, Opts)),
    d("get_keys（裸原子算键；42 这种非法项不算；顺序随机 → 先 sort）",
      lists:sort(proplists:get_keys(Opts))),
    d("lists:keyfind 也能用（proplist 就是列表）", lists:keyfind(retries, 1, Opts)),
    %% 注意 lists:keysort(1, Opts) 会崩：裸原子 debug 不是元组，element(1,·) badarg
    d("keysort 对含裸原子的 proplist 会抛",
      raises(fun(L) -> lists:keysort(1, L) end, Opts)),
    ok.

%% 2) 重复键：先给的赢（与 map 相反）
%% ------------------------------------------------------------
%% 典型的「合并配置」写法：把「高优先级的那份」放在**前面**、不要合并。
proplist_duplicates() ->
    io:format("~n== 2) 重复键：先给的赢 ==~n"),
    P = [{level, warn}, {level, info}, {level, debug}],
    d("get_value 取**第一个**", proplists:get_value(level, P)),
    d("get_all_values 取全部", proplists:get_all_values(level, P)),
    M = maps:from_list(P),
    d("对照 map：from_list 只剩最后一个", maps:to_list(M)),
    Defaults = [{retries, 3}, {timeout, 60}],
    User = [{timeout, 5}],
    d("默认值 + 用户值（用户放前面 → 用户赢）",
      [{K, proplists:get_value(K, User, proplists:get_value(K, Defaults, undefined))}
       || {K, _} <- Defaults]),
    ok.

%% 3) 布尔开关：get_bool 无法区分「没写」和「写了 false」
%% ------------------------------------------------------------
proplist_flags() ->
    io:format("~n== 3) 布尔开关 ==~n"),
    d("get_bool(debug, [debug])", proplists:get_bool(debug, [debug])),
    d("get_bool(debug, [{debug,false}])", proplists:get_bool(debug, [{debug, false}])),
    d("get_bool(debug, [])（不存在也是 false）", proplists:get_bool(debug, [])),
    d("想区分就用 is_defined/2",
      {proplists:is_defined(debug, []), proplists:is_defined(debug, [{debug, false}])}),
    ok.

%% 4) 三套集合实现：接口名几乎一样，顺序完全不同
%% ------------------------------------------------------------
set_impls() ->
    io:format("~n== 4) 三套集合 ==~n"),
    L = [c, a, b, z, a],
    d("输入（注意 a 出现两次）", L),
    d("sets:to_list（顺序随机！必须 sort）", lists:sort(sets:to_list(mk(sets, L)))),
    d("ordsets:to_list（有序列表实现，天然有序）", as_list(ordsets, mk(ordsets, L))),
    d("gb_sets:to_list（树的中序遍历，也是有序的）",
      as_list(gb_sets, mk(gb_sets, L))),
    d("三套的 size 一致",
      [{I, elem_size(I, mk(I, L))} || I <- [sets, ordsets, gb_sets]]),
    d("sets 的内部表示（就是个 map）",
      lists:sort(maps:to_list(mk(sets, [a, b])))),
    d("ordsets 的内部表示（就是有序列表本身）", mk(ordsets, [b, a])),
    ok.

mk(sets, L) -> sets:from_list(L);
mk(ordsets, L) -> ordsets:from_list(L);
mk(gb_sets, L) -> gb_sets:from_list(L).

as_list(sets, S) -> lists:sort(sets:to_list(S));
as_list(ordsets, S) -> ordsets:to_list(S);
as_list(gb_sets, S) -> gb_sets:to_list(S).

elem_size(sets, S) -> sets:size(S);
elem_size(ordsets, S) -> ordsets:size(S);
elem_size(gb_sets, S) -> gb_sets:size(S).

%% 5) 集合代数：三套实现结果应当完全一致
%% ------------------------------------------------------------
set_algebra() ->
    io:format("~n== 5) 集合代数 ==~n"),
    A = [1, 2, 3, 4],
    B = [3, 4, 5],
    Impls = [sets, ordsets, gb_sets],
    [d("union/intersection/subtract 在三套实现下的结果",
       {Op, [{I, as_list(I, op(Op, I, mk(I, A), mk(I, B)))} || I <- Impls]})
     || Op <- [union, intersection, subtract]],
    d("is_subset({3,4}, {1..5})",
      [{I, elem_subset(I, mk(I, [3, 4]), mk(I, [1, 2, 3, 4, 5]))} || I <- Impls]),
    ok.

op(union, sets, A, B) -> sets:union(A, B);
op(union, ordsets, A, B) -> ordsets:union(A, B);
op(union, gb_sets, A, B) -> gb_sets:union(A, B);
op(intersection, sets, A, B) -> sets:intersection(A, B);
op(intersection, ordsets, A, B) -> ordsets:intersection(A, B);
op(intersection, gb_sets, A, B) -> gb_sets:intersection(A, B);
op(subtract, sets, A, B) -> sets:subtract(A, B);
op(subtract, ordsets, A, B) -> ordsets:subtract(A, B);
op(subtract, gb_sets, A, B) -> gb_sets:subtract(A, B).

elem_subset(sets, A, B) -> sets:is_subset(A, B);
elem_subset(ordsets, A, B) -> ordsets:is_subset(A, B);
elem_subset(gb_sets, A, B) -> gb_sets:is_subset(A, B).

%% 6) gb_sets 独有能力：最小/最大/区间查询
%% ------------------------------------------------------------
gb_sets_extras() ->
    io:format("~n== 6) gb_sets 独有能力 ==~n"),
    G = mk(gb_sets, [5, 1, 9, 3, 7]),
    d("集合", as_list(gb_sets, G)),
    d("smallest / largest", {gb_sets:smallest(G), gb_sets:largest(G)}),
    {S1, Rest1} = gb_sets:take_smallest(G),
    d("take_smallest → {元素, 剩下的集合}", {S1, as_list(gb_sets, Rest1)}),
    d("larger(4, G)（比 4 大的最小元素）", gb_sets:larger(4, G)),
    d("larger(100, G)（没有更大 → none）", gb_sets:larger(100, G)),
    ok.

%% 7) queue：两端都能进出，但函数名容易记反
%% ------------------------------------------------------------
%%   queue:in(Item, Q)    在**尾部**加（最常见的入队）
%%   queue:in_r(Item, Q)  在头部加；cons 等价于 in_r
%%   queue:snoc(Q, Item)  等价于 in  ← 参数顺序反过来了！
%%   queue:out(Q)         → {{value, X}, Q2} | {empty, Q}
queues() ->
    io:format("~n== 7) queue ==~n"),
    Q = queue:from_list([1, 2, 3]),
    d("from_list([1,2,3]) 后 to_list", queue:to_list(Q)),
    Out = queue:out(Q),
    d("out → {取出的项, 剩下的队列}",
      {element(1, Out), queue:to_list(element(2, Out))}),
    d("in(4, Q) 从尾部加", queue:to_list(queue:in(4, Q))),
    d("in_r(0, Q) 从头部加", queue:to_list(queue:in_r(0, Q))),
    d("snoc(Q, 4) 等价于 in（参数顺序反了）", queue:to_list(queue:snoc(Q, 4))),
    d("join 把两个队列接起来", queue:to_list(queue:join(Q, queue:from_list([4, 5])))),
    d("空队列：is_empty / peek / len",
      {queue:is_empty(queue:new()), queue:peek(queue:new()), queue:len(queue:new())}),
    ok.

%% 8) array：稀疏数组
%% ------------------------------------------------------------
%%   size/1             条目总数（**含**默认值条目）
%%   sparse_size/1      到「最后一个非默认值条目」为止的条目数
%%   sparse_to_orddict  只列**真正设过**的 {下标, 值}
arrays() ->
    io:format("~n== 8) array：稀疏数组 ==~n"),
    A = array:from_list([a, b, c]),
    d("from_list([a,b,c])", array:to_list(A)),
    d("get(0) / get(2)", {array:get(0, A), array:get(2, A)}),
    %% 越界不报错，而是给默认值 —— 这是最容易踩的一条
    d("get(9)（越界！返回默认值而不是报错）", array:get(9, A)),
    Sparse = array:set(1000, x, array:new()),
    d("set(1000, x, new()) 之后",
      {size, array:size(Sparse), sparse_size, array:sparse_size(Sparse)}),
    d("取中间没设过的下标", array:get(500, Sparse)),
    d("sparse_to_orddict（只列真正设过的）", array:sparse_to_orddict(Sparse)),
    ok.

%% 9) 实战：带选项的 API（见文件尾部 open/1）
%% ------------------------------------------------------------
options_api() ->
    io:format("~n== 9) 实战：带选项的 API ==~n"),
    d("全用默认值", describe_open([])),
    d("改两个", describe_open([{mode, write}, {retries, 0}])),
    d("布尔开关写成裸原子", describe_open([{mode, append}, verbose])),
    d("mode 非法", describe_open([{mode, destroy}])),
    d("多写了不认识的键（应该报错，而不是静默忽略）",
      describe_open([{mode, read}, {retry, 5}])),
    ok.

%% 10) 该用哪个
%% ------------------------------------------------------------
choosing() ->
    io:format("~n== 10) 选择建议 ==~n"),
    Tips = [{"频繁成员判断、不在乎顺序", "sets（O(1)，to_list 顺序随机）"},
            {"元素少且要按序遍历", "ordsets（实现就是有序列表）"},
            {"元素多、要按序或取最小/最大", "gb_sets（O(log n)，功能最全）"},
            {"FIFO 队列", "queue（均摊 O(1)，别用 list ++）"},
            {"下标是整数、大部分为空", "array（越界返回默认值）"},
            {"键是任意项、要 O(1) 查找", "map（10 章）"}],
    [io:format("  ~ts -> ~ts~n", [K, V]) || {K, V} <- Tips],
    ok.

%% 实战：一个带选项的 API（proplists 最正经的用途：函数的「命名参数」）
%% ------------------------------------------------------------
%% 要点：先合并默认值，再校验取值范围，最后**别保留用户给错的键**。
open(Opts) ->
    Mode = proplists:get_value(mode, Opts, read),
    Retries = proplists:get_value(retries, Opts, 3),
    Verbose = proplists:get_bool(verbose, Opts),
    Known = [mode, retries, verbose],
    Unknown = [K || {K, _} <- Opts, not lists:member(K, Known)]
        ++ [K || K <- Opts, is_atom(K), not lists:member(K, Known)],
    case lists:member(Mode, [read, write, append]) of
        false -> {error, {bad_mode, Mode}};
        true when not is_integer(Retries); Retries < 0 ->
            {error, {bad_retries, Retries}};
        true when Unknown =/= [] ->
            {error, {unknown_options, lists:sort(Unknown)}};
        true ->
            {ok, #{mode => Mode, retries => Retries, verbose => Verbose}}
    end.

describe_open(Opts) ->
    case open(Opts) of
        {ok, M} -> {ok, lists:sort(maps:to_list(M))};
        {error, R} -> {error, R}
    end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.
