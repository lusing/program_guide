%% ============================================================================
%%  04_terms.pl —— 项：Prolog 唯一的数据结构（第 04 章配套）
%%
%%  别的语言有 int / string / array / struct / object 一堆类型；
%%  Prolog 只有一种东西：**项（term）**，它由三种零件拼成：
%%      原子（atom）· 数字（number）· 变量（variable）· 复合项（compound）
%%  「列表」「字符串」「结构体」全是复合项的不同写法而已。
%%
%%  本示例演示：四种零件、复合项的解剖（functor/arg/=..）、
%%  把变量固定成名字（numbervars）以便打印、标准项序。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、四种零件
%% ---------------------------------------------------------------------------
demo_parts :-
    say("---- 1. 四种零件 ----"),

    % 原子：小写开头，或引号包起来。本身带值。
    format("  原子   : ~w ~w ~w~n", [apple, 'Hello World', '+']),

    % 数字：整数和浮点。浮点打印位数两套引擎不同，所以只用 ~2f 这种定点格式。
    format("  整数   : ~w~n", [42]),
    format("  负数   : ~w~n", [-7]),
    format("  浮点   : ~2f~n", [3.14159]),

    % 变量：大写或下划线开头，本身没有名字，只有「绑定」。
    %   打印未绑定变量会打出引擎内部的编号（_1234），两边还不一样 —— 所以
    %   示范打印前先用 numbervars/3 把变量固定成 A、B、C…
    T = pair(_First, _Second),
    numbervars(T, 0, _),
    format("  变量   : ~w~n", [T]),

    % 复合项：functor(arg1, arg2, ...)
    format("  复合项 : ~w~n", [point(3, 4)]),
    % 参数本身可以是任意项，于是「列表」和「树」都只是复合项
    format("  嵌套   : ~w~n", [tree(1, tree(2, leaf, leaf), leaf)]).

%% ---------------------------------------------------------------------------
%%  二、解剖复合项：functor/3 与 arg/3
%% ---------------------------------------------------------------------------
demo_anatomy :-
    say("---- 2. 解剖：functor/3 与 arg/3 ----"),
    T = point(3, 4),
    functor(T, Name, Arity),
    format("  functor(point(3,4)) = ~w/~w~n", [Name, Arity]),
    arg(1, T, A1),
    arg(2, T, A2),
    format("  arg(1) = ~w , arg(2) = ~w~n", [A1, A2]),

    % 反向用：给定名字和元数，造一个「全是新鲜变量」的骨架
    functor(Skeleton, point, 2),
    numbervars(Skeleton, 0, _),
    format("  functor(_, point, 2) 造骨架 = ~w~n", [Skeleton]),

    % 元数不同就是不同的项（同一个名字也不行）
    (   compare(Cmp, f(1), f(1, 2))
    ->  format("  compare(f(1), f(1,2)) = ~w（先比元数）~n", [Cmp])
    ;   true
    ).

%% ---------------------------------------------------------------------------
%%  三、=..（univ）：项 ↔ 列表 的双向桥
%% ---------------------------------------------------------------------------
demo_univ :-
    say("---- 3. =.. 把项拆成列表、把列表装成项 ----"),
    T = f(a, b, c),
    T =.. Parts,
    format("  f(a,b,c) =.. ~w~n", [Parts]),
    Built =.. [g, 1, 2],
    format("  [g,1,2] =.. ~w~n", [Built]),
    % 双向：左边是列表也行
    f(a, b) =.. L2,
    format("  f(a,b) 拆出来是 ~w~n", [L2]).

%% ---------------------------------------------------------------------------
%%  四、标准项序：所有排序、比较、集合操作的底座
%%     变量 < 数字 < 原子 < 复合项；同类型内部按自己的规则
%% ---------------------------------------------------------------------------
demo_order :-
    say("---- 4. 标准项序（@< @> @=< @>= 与 compare/3 都基于它）----"),
    say("  变量 < 数字 < 原子 < 复合项"),
    compare(Cmp1, 1, 2),
    compare(Cmp2, 2, 1),
    compare(Cmp3, 1, 1),
    compare(Cmp4, abc, abd),
    compare(Cmp5, _, 1),
    compare(Cmp6, 1, a),
    format("  compare(1, 2)       = ~w~n", [Cmp1]),
    format("  compare(2, 1)       = ~w~n", [Cmp2]),
    format("  compare(1, 1)       = ~w~n", [Cmp3]),
    format("  compare(abc, abd)   = ~w~n", [Cmp4]),
    format("  compare(_, 1)       = ~w~n", [Cmp5]),
    format("  compare(1, a)       = ~w~n", [Cmp6]),
    % 列表是复合项的一种，所以列表之间也按标准序比
    msort([3, 1, 2], Ms1),
    msort([b, a, c], Ms2),
    msort([[b], [a, c], [a]], Ms3),
    msort([f(b), f(a, x), f(a)], Ms4),
    format("  msort 数字        = ~w~n", [Ms1]),
    format("  msort 原子        = ~w~n", [Ms2]),
    format("  msort 列表        = ~w~n", [Ms3]),
    format("  msort 复合项      = ~w~n", [Ms4]),
    say("  注意：整数与浮点混排时两套引擎的次序不同，别混着排（第 23 章）。").

%% ---------------------------------------------------------------------------
%%  五、copy_term：拿一份互不干扰的副本
%% ---------------------------------------------------------------------------
demo_copy :-
    say("---- 5. copy_term/2：复制项，变量换成崭新的 ----"),
    Original = pair(_X, _Y),
    copy_term(Original, Copy),
    numbervars(Original, 0, _),
    numbervars(Copy, 0, _),
    format("  原件 = ~w~n", [Original]),
    format("  副本 = ~w~n", [Copy]),
    (   Original = Copy
    ->  say("  原件与副本可以合一（结构相同）")
    ;   say("  原件与副本不能合一")
    ),
    term_variables(Original, VarsO),
    term_variables(Copy, VarsC),
    length(VarsO, NO),
    length(VarsC, NC),
    format("  term_variables(原件) 个数 = ~w~n", [NO]),
    format("  term_variables(副本) 个数 = ~w~n", [NC]).

%% ---------------------------------------------------------------------------
%%  入口
%% ---------------------------------------------------------------------------
main :-
    (   catch(run, E, (format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   format(user_error, "*** run/0 失败~n", []), halt(1)
    ).

run :-
    format("==== 04 开始 ====~n", []),
    say("Prolog 只有一种数据结构：项。原子、数字、变量、复合项是它的四种零件。"),
    say(""),
    demo_parts,        say(""),
    demo_anatomy,      say(""),
    demo_univ,         say(""),
    demo_order,        say(""),
    demo_copy,         say(""),
    format("==== 04 结束 ====~n", []).
