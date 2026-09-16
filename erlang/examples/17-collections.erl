%% ============================================================
%% 17 - 集合、队列、稀疏数组：标准库里的其它容器
%%
%%    都是「集合」，但 Erlang 给了三套实现，接口几乎一样、代价完全不同：
%%      sets     基于 map，成员判断 O(1)，**遍历顺序随机**
%%      ordsets  有序列表，元素少时最快，遍历天然有序
%%      gb_sets  平衡树，O(log n)，独有 smallest/largest/take_smallest
%%    另外两个常用容器：queue（FIFO，两个列表实现）和 array（稀疏数组）。
%%
%%    本示例所有输出都先归一化（sort 或转成列表），因为
%%    sets 和 queue 的内部表示、以及 sets 的遍历顺序都不适合直接打印。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/17-collections.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '17-collections' main -s init stop
%% ============================================================
-module('17-collections').

-export([main/0, mk/2, as_list/2, op/4]).

main() ->
    set_impls(),
    set_algebra(),
    gb_sets_extras(),
    queues(),
    arrays(),
    choosing(),
    io:format("~n==== 17 结束 ====~n").

%% 1) 三套实现：接口名几乎一样，顺序完全不同
%% ------------------------------------------------------------
set_impls() ->
    io:format("== 1) 三套集合实现的顺序差异 ==~n"),
    L = [c, a, b, z, a],
    d("输入（注意 a 出现两次）", L),
    %% 三套都会去重，但只有后两套保证顺序
    d("sets:to_list（顺序随机！必须 sort 才能比较）",
      lists:sort(sets:to_list(mk(sets, L)))),
    d("ordsets:to_list（有序列表实现，天然有序）",
      as_list(ordsets, mk(ordsets, L))),
    d("gb_sets:to_list（树的中序遍历，也是有序的）",
      as_list(gb_sets, mk(gb_sets, L))),
    d("三套的 size 一致",
      [{I, elem_size(I, mk(I, L))} || I <- [sets, ordsets, gb_sets]]),
    %% 内部表示差异巨大：sets 是 map、ordsets 就是列表、gb_sets 是树。
    %% map 直接打印顺序随机，所以也要先 sort。
    d("sets 的内部表示（就是个 map：键=元素，值=占位）",
      lists:sort(maps:to_list(mk(sets, [a, b])))),
    d("ordsets 的内部表示（就是有序列表本身）", mk(ordsets, [b, a])),
    io:format("  ~ts~n", ["（gb_sets 的内部是二叉树，形状与元素个数、插入顺序有关，"]),
    io:format("  ~ts~n", ["  直接打印没有意义，一律先 to_list）"]),
    ok.

%% 同一件事在三套实现里的函数名不同，用一个小调度器把差异集中起来：
%%   sets / ordsets:  add_element / del_element / is_element
%%   gb_sets:         add / delete_any   / is_element（is_member 也对）
mk(sets, L) -> sets:from_list(L);
mk(ordsets, L) -> ordsets:from_list(L);
mk(gb_sets, L) -> gb_sets:from_list(L).

as_list(sets, S) -> lists:sort(sets:to_list(S));
as_list(ordsets, S) -> ordsets:to_list(S);
as_list(gb_sets, S) -> gb_sets:to_list(S).

elem_size(sets, S) -> sets:size(S);
elem_size(ordsets, S) -> ordsets:size(S);
elem_size(gb_sets, S) -> gb_sets:size(S).

%% 2) 集合代数：三套实现结果应当完全一致
%% ------------------------------------------------------------
op(union, sets, A, B) -> sets:union(A, B);
op(union, ordsets, A, B) -> ordsets:union(A, B);
op(union, gb_sets, A, B) -> gb_sets:union(A, B);
op(intersection, sets, A, B) -> sets:intersection(A, B);
op(intersection, ordsets, A, B) -> ordsets:intersection(A, B);
op(intersection, gb_sets, A, B) -> gb_sets:intersection(A, B);
op(subtract, sets, A, B) -> sets:subtract(A, B);
op(subtract, ordsets, A, B) -> ordsets:subtract(A, B);
op(subtract, gb_sets, A, B) -> gb_sets:subtract(A, B).

set_algebra() ->
    io:format("~n== 2) 集合代数（三套实现互相对照） ==~n"),
    A = [1, 2, 3, 4],
    B = [3, 4, 5],
    Impls = [sets, ordsets, gb_sets],
    [d(atom_to_list(Op) ++ "(" ++ integer_list(A) ++ ", " ++ integer_list(B) ++ ")",
       [{I, as_list(I, op(Op, I, mk(I, A), mk(I, B)))} || I <- Impls])
     || Op <- [union, intersection, subtract]],
    %% 谓词类
    d("is_subset({3,4}, {1..5})",
      [{I, elem_subset(I, mk(I, [3, 4]), mk(I, [1, 2, 3, 4, 5]))} || I <- Impls]),
    d("is_disjoint({1,2}, {3,4})",
      [{I, elem_disjoint(I, mk(I, [1, 2]), mk(I, [3, 4]))} || I <- Impls]),
    ok.

elem_subset(sets, A, B) -> sets:is_subset(A, B);
elem_subset(ordsets, A, B) -> ordsets:is_subset(A, B);
elem_subset(gb_sets, A, B) -> gb_sets:is_subset(A, B).

elem_disjoint(sets, A, B) -> sets:is_disjoint(A, B);
elem_disjoint(ordsets, A, B) -> ordsets:is_disjoint(A, B);
elem_disjoint(gb_sets, A, B) -> gb_sets:is_disjoint(A, B).

integer_list(L) -> "[" ++ string:join([integer_to_list(X) || X <- L], ",") ++ "]".

%% 3) gb_sets 独有能力：拿到「最小/最大」以及沿着树走
%% ------------------------------------------------------------
%% 这些在 sets / ordsets 里没有对应函数（ordsets 至少要自己 hd/头尾）。
%% 注意 take_smallest/1 返回的是 {元素, 剩下的集合} —— 剩下那个别直接打印，
%% 它是树的内部表示。
gb_sets_extras() ->
    io:format("~n== 3) gb_sets 独有能力 ==~n"),
    G = mk(gb_sets, [5, 1, 9, 3, 7]),
    d("集合（to_list 后）", as_list(gb_sets, G)),
    d("smallest", gb_sets:smallest(G)),
    d("largest", gb_sets:largest(G)),
    {S1, Rest1} = gb_sets:take_smallest(G),
    d("take_smallest → {取出的元素, 剩下的集合转成列表}", {S1, as_list(gb_sets, Rest1)}),
    {S2, Rest2} = gb_sets:take_largest(G),
    d("take_largest", {S2, as_list(gb_sets, Rest2)}),
    %% 42 是可打印字符 $*，~p 会把单元素列表 [42] 打成字符串 "*"，
    %% 所以这里必须用 ds/2（内部是 ~w）。
    ds("singleton（注意 [42] 会被 ~p 打成 \"*\"，所以用 ~w）",
       as_list(gb_sets, gb_sets:singleton(42))),
    d("iterator + next 按序取出全部", iterate(G, [])),
    %% larger/smaller：找「比它大的最小元素 / 比它小的最大元素」，适合区间查询。
    %% 返回 {found, X} 或 none，不是裸元素。
    d("larger(4, G) → {found, 比 4 大的最小元素}", gb_sets:larger(4, G)),
    d("smaller(4, G) → {found, 比 4 小的最大元素}", gb_sets:smaller(4, G)),
    d("larger(100, G) → 没有更大的，返回 none", gb_sets:larger(100, G)),
    ok.

%% 用迭代器而不是 to_list 遍历：iterator 是取的游标，next 沿树前进。
iterate(S, Acc) -> iterate_next(gb_sets:iterator(S), Acc).

iterate_next(I, Acc) ->
    case gb_sets:next(I) of
        none -> lists:reverse(Acc);
        {V, I2} -> iterate_next(I2, [V | Acc])
    end.

%% 4) queue：两端都能进出，但「加哪一头」的函数名很容易记反
%% ------------------------------------------------------------
%%   queue:in(Item, Q)    在**尾部**加（最常见的入队）
%%   queue:in_r(Item, Q)  在头部加
%%   queue:cons(Item, Q)  等价于 in_r
%%   queue:snoc(Q, Item)  等价于 in          ← 参数顺序反过来了！
%%   queue:out(Q)         → {{value, X}, Q2} | {empty, Q}
%%   queue:peek(Q)        → {value, X} | empty
%% 内部是两个列表（前面一个、后面一个倒过来），均摊 O(1)；
%% 但这个「两个列表」的形状会漏到打印结果里，所以一律 to_list 后再看。
queues() ->
    io:format("~n== 4) queue：FIFO ==~n"),
    Q = queue:from_list([1, 2, 3]),
    d("from_list([1,2,3]) 后 to_list", queue:to_list(Q)),
    d("len", queue:len(Q)),
    d("peek", queue:peek(Q)),
    d("head / last", {queue:head(Q), queue:last(Q)}),
    Out = queue:out(Q),
    d("out → {取出的项, 剩下的队列转成列表}",
      {element(1, Out), queue:to_list(element(2, Out))}),
    d("in(4, Q) 从尾部加", queue:to_list(queue:in(4, Q))),
    d("in_r(0, Q) 从头部加", queue:to_list(queue:in_r(0, Q))),
    d("cons(0, Q) 等价于 in_r", queue:to_list(queue:cons(0, Q))),
    d("snoc(Q, 4) 等价于 in（注意参数顺序反了）", queue:to_list(queue:snoc(Q, 4))),
    d("join 把两个队列接起来", queue:to_list(queue:join(Q, queue:from_list([4, 5])))),
    d("filter", queue:to_list(queue:filter(fun(X) -> X rem 2 =:= 1 end, Q))),
    d("fold", queue:fold(fun(X, A) -> X + A end, 0, Q)),
    %% 空队列：别打印 out(queue:new())，它的表示是 {empty,{[],[]}}
    d("空队列：is_empty / peek / len",
      {queue:is_empty(queue:new()), queue:peek(queue:new()), queue:len(queue:new())}),
    ok.

%% 5) array：稀疏数组（大部分下标没有值时最省内存）
%% ------------------------------------------------------------
%% 语义按官方文档核过（size / sparse_size / sparse_to_orddict 三者容易搞混）：
%%   size/1              条目总数（**含**默认值条目）
%%   sparse_size/1       到「最后一个非默认值条目」为止的条目数（不是「存了几个」！）
%%   sparse_to_orddict/1  只列**真正设过**的 {下标, 值}，跳过默认值条目
%% 另外两条实测结论：
%%   * 取越界的下标**不报错**，返回默认值
%%   * size 会随你设过的最大下标增长（set(1000, ...) 之后 size 就是 1001）
arrays() ->
    io:format("~n== 5) array：稀疏数组 ==~n"),
    A = array:from_list([a, b, c]),
    d("from_list([a,b,c])", array:to_list(A)),
    d("size / default", {array:size(A), array:default(A)}),
    d("get(0) / get(2)", {array:get(0, A), array:get(2, A)}),
    %% 越界不报错，而是给默认值 —— 这是最容易踩的一条
    d("get(9)（越界！返回默认值而不是报错）", array:get(9, A)),
    d("带默认值的 new：array:new(5, {default, 0}) 全取出来",
      array:to_list(array:new(5, {default, 0}))),
    Sparse = array:set(1000, x, array:new()),
    d("array:set(1000, x, array:new()) 之后",
      {size, array:size(Sparse), sparse_size, array:sparse_size(Sparse)}),
    d("取中间没设过的下标", array:get(500, Sparse)),
    d("to_orddict 的前 3 项（**含**默认值条目）",
      lists:sublist(array:to_orddict(Sparse), 3)),
    d("sparse_to_orddict（只列真正设过的）", array:sparse_to_orddict(Sparse)),
    d("resize 到指定大小后再 to_list（多出来的被截掉）",
      array:to_list(array:resize(3, array:from_list([a, b, c, d])))),
    d("array 也能当普通的密集数组用",
      array:to_list(array:from_list([N * N || N <- lists:seq(0, 9)]))),
    ok.

%% 6) 该用哪个
%% ------------------------------------------------------------
choosing() ->
    io:format("~n== 6) 选择建议 ==~n"),
    Tips = [{"需要频繁成员判断、不在乎顺序", "sets（O(1)，但 to_list 顺序随机）"},
            {"元素少（几十个以内）且要按序遍历", "ordsets（实现就是有序列表，最省）"},
            {"元素多、要按序遍历或取最小/最大", "gb_sets（O(log n)，功能最全）"},
            {"需要按序但元素频繁增删", "gb_sets（ordsets 每次插入是 O(n)）"},
            {"FIFO 队列", "queue（均摊 O(1)，别用 list ++）"},
            {"下标是整数、大部分为空", "array（用 map 也行，但 array 更省）"},
            {"键是任意项、要 O(1) 查找", "map（第 10 章）"}],
    io:format("~n"),
    [io:format("  ~ts -> ~ts~n", [pad(A, 68), B]) || {A, B} <- Tips],
    d("表格里那个长度是按「显示列数」补的；若直接用 ~-34ts 只会按字符数补",
      {length("需要频繁成员判断、不在乎顺序"), disp_width("需要频繁成员判断、不在乎顺序")}),
    ok.

%% io_lib 的字段宽度按字符数填，中文占两个终端列 → 手写按显示宽度补空格
disp_width(S) -> lists:sum([char_cols(C) || C <- unicode:characters_to_list(S)]).

char_cols(C) when C >= 16#1100, C =< 16#115F -> 2;
char_cols(C) when C >= 16#2E80, C =< 16#A4CF -> 2;
char_cols(C) when C >= 16#AC00, C =< 16#D7A3 -> 2;
char_cols(C) when C >= 16#F900, C =< 16#FAFF -> 2;
char_cols(C) when C >= 16#FE30, C =< 16#FE6F -> 2;
char_cols(C) when C >= 16#FF00, C =< 16#FF60 -> 2;
char_cols(C) when C >= 16#FFE0, C =< 16#FFE6 -> 2;
char_cols(_) -> 1.

pad(S, W) ->
    case disp_width(S) of
        N when N >= W -> S;
        N -> S ++ lists:duplicate(W - N, $\s)
    end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% ~p 会把「可打印的字符列表」打成字符串（[42] → "*"），想按列表看数就用 ~w
ds(Label, Value) -> io:format("  ~ts = ~w~n", [Label, Value]).
