%% ============================================================================
%%  08_lists.pl —— 列表
%%
%%  Prolog 没有数组、没有下标运算符、没有 for。列表就是链表，
%%  语法 [H|T] 只是复合项 '.'(H,T) 的糖：
%%    [a,b,c]  ==  '.'(a, '.'(b, '.'(c, [])))
%%    [a]      ==  '.'(a, [])
%%    []       ==  原子 []
%%
%%  本章先用内建列表谓词，再手写一遍 —— 手写版才看得出「关系式」的味道。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、结构：头与尾
%% ---------------------------------------------------------------------------
demo_shape :-
    say("---- 1. 列表的解剖 ----"),
    [H | T] = [a, b, c],
    format("  [a,b,c] 的头 = ~w，尾 = ~w~n", [H, T]),
    [X | T2] = [a],
    format("  单元素列表 [a] 的头 = ~w，尾 = ~w~n", [X, T2]),

    % 尾部可以是任何项，于是得到「不完整列表」
    Improper = [a | b],
    format("  [a|b] 的尾是原子 b，整体是不完整列表 ~w~n", [Improper]),
    say("  内建谓词遇到不完整列表行为各异，可移植代码一律用完整列表。"),

    % 空列表：ISO 把它规定为原子 []，但 SWI 的 atom/1 对它返回 false，
    % 所以「空表是不是原子」不要作为判断依据，用 length/2 判空最稳。
    length([], ZeroLen),
    format("  length([], N)    N = ~w（这才是判空的可靠写法）~n", [ZeroLen]),
    (   is_list([a, b])
    ->  say("  is_list([a,b])  成立（两套引擎都提供）")
    ;   say("  is_list([a,b])  不成立")
    ),
    (   is_list([a, b | c])
    ->  say("  is_list([a,b|c]) 成立（这里不该出现）")
    ;   say("  is_list([a,b|c]) 不成立 —— 尾部不是列表")
    ).

%% ---------------------------------------------------------------------------
%%  二、长度
%% ---------------------------------------------------------------------------
%% 手写版：显式递归到空表
my_length([], 0).
my_length([_ | T], N) :-
    my_length(T, N0),
    N is N0 + 1.

demo_length :-
    say("---- 2. length/2 是关系，不是函数 ----"),
    length([a, b, c], N1),
    format("  length([a,b,c], N)  N = ~w~n", [N1]),
    length(L1, 2),
    numbervars(L1, 0, _),
    format("  length(L, 2)        L = ~w~n", [L1]),
    my_length([a, b, c, d], N2),
    format("  my_length([a,b,c,d])  = ~w~n", [N2]),
    say("  一次调用同时约束长度与内容 —— 后面构造列表时非常有用。").

%% ---------------------------------------------------------------------------
%%  三、拼接：append/3 的四种用法
%% ---------------------------------------------------------------------------
demo_append :-
    say("---- 3. append/3 一个谓词四种用法 ----"),
    % 用法 1：两个已知列表拼起来
    append([1, 2], [3, 4], L1),
    format("  append([1,2],[3,4],L)      L = ~w~n", [L1]),
    % 用法 2：把已知列表拆成「前缀 + 后缀」，回溯给出所有拆法
    append(P, S, [1, 2, 3, 4]),
    format("  拆一次：P = ~w，S = ~w~n", [P, S]),
    findall(P2 - S2, append(P2, S2, [1, 2]), Pairs),
    format("  用 findall 看全部拆法：~w~n", [Pairs]),
    % 用法 3：后缀固定，反推出前缀
    append(P3, [3, 4], [1, 2, 3, 4]),
    format("  后缀固定时：P = ~w~n", [P3]),
    % 用法 4：配合 length/2 限制长度，才不会无限生成
    findall(P4 - S4, ( length(P4, 1), append(P4, S4, [a, b]) ), Pairs2),
    format("  前缀限定长度 1：~w~n", [Pairs2]).

%% ---------------------------------------------------------------------------
%%  四、反转：两版实现与效率差别
%% ---------------------------------------------------------------------------
%% 朴素版：递归回来再往结果末尾追加 —— O(n^2)
naive_reverse([], []).
naive_reverse([H | T], R) :-
    naive_reverse(T, R0),
    append(R0, [H], R).

%% 累加器版：往下走的时候就把元素攒进累加器 —— O(n)，推荐写法
acc_reverse(L, R) :- acc_reverse(L, [], R).
acc_reverse([], Acc, Acc).
acc_reverse([H | T], Acc, R) :-
    acc_reverse(T, [H | Acc], R).

demo_reverse :-
    say("---- 4. reverse：朴素版 vs 累加器版 ----"),
    naive_reverse([1, 2, 3], R1),
    format("  朴素版   ~w~n", [R1]),
    acc_reverse([1, 2, 3], R2),
    format("  累加器版 ~w~n", [R2]),
    reverse([1, 2, 3], R3),
    format("  内建版   ~w~n", [R3]),
    say("  累加器是 Prolog 最重要的性能手段：把「递归回来再拼」改成"),
    say("  「往下走的时候顺手攒」，就省掉了 append 的复制开销。"),
    say("  尾递归 + 累加器 ≈ 命令式循环的成本。"),
    reverse(R4, [1, 2, 3]),
    format("  reverse 也能反着用：reverse(R, [1,2,3]) -> R = ~w~n", [R4]).

%% ---------------------------------------------------------------------------
%%  五、定位与筛选
%% ---------------------------------------------------------------------------
demo_access :-
    say("---- 5. 按下标取元素 / 判断成员 ----"),
    nth0(0, [a, b, c], N0),
    format("  nth0(0,[a,b,c])   ~w（下标从 0 起）~n", [N0]),
    nth1(1, [a, b, c], N1),
    format("  nth1(1,[a,b,c])   ~w（下标从 1 起）~n", [N1]),
    findall(I - V, nth0(I, [a, b, c], V), All0),
    format("  nth0 反向枚举     ~w~n", [All0]),

    last([a, b, c], L1),
    format("  last([a,b,c])     ~w~n", [L1]),

    select(b, [a, b, c], Rest),
    format("  select(b,[a,b,c]) 剩下的 = ~w~n", [Rest]),
    findall(S2, select(_E, [a, b, a], S2), Sels),
    format("  反向枚举所有可能  ~w~n", [Sels]),

    (   member(b, [a, b, c])
    ->  say("  member(b,[a,b,c])      成立")
    ;   say("  member(b,[a,b,c])      不成立")
    ),
    (   memberchk(b, [a, b, c])
    ->  say("  memberchk(b,[a,b,c])   成立（确定性的，只认第一个解）")
    ;   say("  memberchk(b,[a,b,c])   不成立")
    ),
    findall(L3, ( length(L3, 2), member(1, L3) ), Gen),
    numbervars(Gen, 0, _),
    format("  反向用 member：length=2 且含 1 的列表 = ~w~n", [Gen]),
    say("  注意必须先限定长度，否则 member(1,L) 会无限生成下去。").

%% ---------------------------------------------------------------------------
%%  六、排列与排序
%% ---------------------------------------------------------------------------
demo_sort :-
    say("---- 6. 排列与排序 ----"),
    findall(P, permutation([1, 2], P), Ps),
    length(Ps, N1),
    format("  permutation([1,2]) 共 ~w 种：~w~n", [N1, Ps]),

    % sort/2：排序 + 去重（按标准项序）
    sort([c, a, b, a], S1),
    format("  sort([c,a,b,a])   ~w（去重）~n", [S1]),
    % msort/2：只排序，不去重
    msort([c, a, b, a], S2),
    format("  msort([c,a,b,a])  ~w（保留重复）~n", [S2]),
    % keysort/2：元素须是 K-V 形式，只按 K 排，且稳定
    keysort([b - 1, a - 2, b - 0, a - 3], S3),
    format("  keysort/2         ~w（只按键，稳定）~n", [S3]),

    sort_by_length([[1, 2, 3], [a], [1, 2]], Sorted),
    format("  按长度升序排      ~w~n", [Sorted]),
    say("  可移植的自定义排序只有一条路：把准则做成「键」，再 keysort。"),
    say("  （predsort/3 与 sort/4 是 SWI 专有，GNU Prolog 没有。）").

%% 先把每个元素变成 长度-元素，keysort 之后再脱掉键
sort_by_length(L, Sorted) :-
    keyed(L, Keyed),
    keysort(Keyed, SortedKeyed),
    unkey(SortedKeyed, Sorted).

keyed([], []).
keyed([H | T], [K - H | KT]) :-
    length(H, K),
    keyed(T, KT).

unkey([], []).
unkey([_ - H | T], [H | UT]) :-
    unkey(T, UT).

%% ---------------------------------------------------------------------------
%%  七、手写一遍 map / filter / fold
%%  第 11 章会用内建的 maplist/3 等，这里先看它们长什么样。
%% ---------------------------------------------------------------------------
my_map(_, [], []).
my_map(P, [H | T], [R | RT]) :-
    call(P, H, R),
    my_map(P, T, RT).

my_filter(_, [], []).
my_filter(P, [H | T], R) :-
    (   call(P, H)
    ->  R = [H | RT]
    ;   R = RT
    ),
    my_filter(P, T, RT).

my_fold(_, [], Acc, Acc).
my_fold(P, [H | T], Acc, R) :-
    call(P, H, Acc, Acc1),
    my_fold(P, T, Acc1, R).

double(X, Y) :- Y is X * 2.
add_to(X, A, B) :- B is X + A.
positive(X) :- X > 0.

demo_hof :-
    say("---- 7. 手写 map / filter / fold ----"),
    my_map(double, [1, 2, 3], M),
    format("  my_map(double, [1,2,3])       ~w~n", [M]),
    my_filter(positive, [-1, 2, -3, 4], F),
    format("  my_filter(>0, [-1,2,-3,4])    ~w~n", [F]),
    my_fold(add_to, [1, 2, 3, 4], 0, Sum),
    format("  my_fold(+, [1,2,3,4], 0)      ~w~n", [Sum]),
    say("  这三个谓词把「怎么遍历」和「对元素做什么」拆开了 ——"),
    say("  传进去的 P 是一个「闭包」（closure），第 11 章专门讲。").

%% ---------------------------------------------------------------------------
%%  入口
%% ---------------------------------------------------------------------------
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []),
        halt(1)
    ).

run :-
    format("==== 08 开始 ====~n", []),
    say("列表是 Prolog 唯一的序列结构，本质是 '.'/2 链起来的复合项。"),
    say(""),

    demo_shape,   say(""),
    demo_length,  say(""),
    demo_append,  say(""),
    demo_reverse, say(""),
    demo_access,  say(""),
    demo_sort,    say(""),
    demo_hof,     say(""),

    format("==== 08 结束 ====~n", []).
