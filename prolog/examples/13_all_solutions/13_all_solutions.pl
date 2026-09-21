%% ============================================================================
%%  13_all_solutions.pl —— 收集全部解
%%
%%  Prolog 一个查询可能有零个、一个、或无穷多个解。要把「可能多个解」
%%  变成「一个列表」，有三个内建谓词，差别很关键：
%%
%%    findall(Template, Goal, List)
%%        把所有解收进 List。无解时成功并给出 []。最常用、最安全。
%%
%%    bagof(Template, Goal, List)
%%        无解时【失败】（而不是给 []）。
%%        更要紧的是：Goal 里的「自由变量」会让它按变量分组，依次给出多组解。
%%
%%    setof(Template, Goal, List)
%%        在 bagof 基础上再排序 + 去重。
%%
%%  用 ^/2 可以把变量「藏起来」，让它不参与分组 —— 这是 bagof/setof 的核心技巧。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% 示例数据：谁喜欢什么
likes(mary, food).
likes(mary, wine).
likes(john, wine).
likes(john, mary).
likes(john, food).

%% ---------------------------------------------------------------------------
%%  一、findall：最常用，永不失败
%% ---------------------------------------------------------------------------
demo_findall :-
    say("---- 1. findall/3 ----"),
    findall(X, likes(X, wine), L1),
    format("  findall(X, likes(X,wine), L)     L = ~w~n", [L1]),

    % 模板可以是任意项，不只是变量
    findall(X2 - Y2, likes(X2, Y2), L2),
    format("  findall(X-Y, likes(X,Y), L)      L = ~w~n", [L2]),

    % 无解时成功并给空表 —— 这一点让它最适合做「统计」
    findall(_X3, likes(nobody, _), L3),
    format("  findall(_, likes(nobody,_), L)   L = ~w，且整体成功~n", [L3]),

    % 计数不用 count，length 一下就行（可移植）
    findall(_X4, likes(john, _), L4),
    length(L4, NJ),
    format("  john 喜欢 ~w 样东西~n", [NJ]),

    say("  findall 的另一个性质：Goal 里的绑定不会漏到外面来。"),
    findall(Z, member(Z, [1, 2, 3]), _),
    (   var(Z)
    ->  say("    findall 之后 Z 仍是空的 —— 它自己内部把变量复制了一套")
    ;   format("    findall 之后 Z = ~w（不该出现）~n", [Z])
    ).

%% ---------------------------------------------------------------------------
%%  二、bagof：无解就失败，有自由变量就分组
%% ---------------------------------------------------------------------------
demo_bagof :-
    say("---- 2. bagof/3：失败语义 + 自动分组 ----"),

    % 无解 → 失败（对比 findall 的 []）
    (   bagof(X, likes(nobody, X), _L1)
    ->  say("  bagof(X, likes(nobody,X), L)  成功（这里不该出现）")
    ;   say("  bagof(X, likes(nobody,X), L)  失败 —— 无解时 bagof 失败")
    ),

    % 自由变量 Y（在 Goal 里出现但不是模板变量）→ 触发分组
    say("  likes(X,Y) 里的 X 是自由变量，bagof 会按 X 分组："),
    findall(X2 - Group, bagof(Y, likes(X2, Y), Group), Groups),
    format("    ~w~n", [Groups]),

    % 用 ^ 把 X 藏起来，就只剩一组
    bagof(Y2, X3 ^ likes(X3, Y2), All),
    format("  加上 X^ 之后只有一组：~w~n", [All]),

    say("  分组规则：Goal 里所有「既不在模板里、也没被 ^ 声明」的变量都要分组。"),
    say("  这条规则是初学者最容易踩的坑：明明只是想收集，结果出来一堆组。"),
    say("  所以经验是：如果不需要分组，直接用 findall，或者给变量加 ^。").

%% ---------------------------------------------------------------------------
%%  三、setof：排序 + 去重
%% ---------------------------------------------------------------------------
demo_setof :-
    say("---- 3. setof/3 = bagof + 排序去重 ----"),
    setof(Y, X ^ likes(X, Y), L1),
    format("  setof(Y, X^likes(X,Y), L)   L = ~w~n", [L1]),
    say("  排的是标准项序（第 04 章），去重也是按标准项序相等。"),

    % 注意：findall 不认 ^/2（只有 bagof/setof 会剥掉它），
    % 所以这里直接写 likes(_, Y)，用通配变量代替 ^。
    findall(Y2, likes(_X2, Y2), WithDup),
    format("  同样条件用 findall                  L = ~w（有重复）~n", [WithDup]),

    sort(WithDup, Dedup),
    format("  再 sort 一下                        L = ~w（与 setof 相同）~n", [Dedup]),
    say("  换句话说：setof ≈ sort(findall(...))，但对「无解」的语义不同。"),
    say("  另外 findall 不认 ^/2 —— X^Goal 会被当成一个叫 ^ 的谓词去调用，直接报错。"),
    (   setof(Y3, likes(nobody, Y3), _)
    ->  say("  setof 无解时：成功（这里不该出现）")
    ;   say("  setof 无解时：失败（与 bagof 一致，与 findall 不同）")
    ).

%% ---------------------------------------------------------------------------
%%  四、可移植的聚合：数、和、极值
%% ---------------------------------------------------------------------------
%% 内建的 aggregate_all/3 只有 SWI 有；下面这套 findall 组合在哪都能用。
%% 通用套路：先 findall 把「每个解对应的值」收成列表，再对列表做普通递归。
count_all(Goal, N) :-
    findall(dummy, call(Goal), L),
    length(L, N).

sum_of(Template, Goal, S) :-
    findall(V, ( call(Goal), V = Template ), Vs),
    sum_rec(Vs, S).

sum_rec([], 0).
sum_rec([H | T], S) :-
    sum_rec(T, S0),
    S is S0 + H.

max_of(Template, Goal, M) :-
    findall(V, ( call(Goal), V = Template ), [First | Rest]),
    max_rec(Rest, First, M).

max_rec([], M, M).
max_rec([H | T], Acc, M) :-
    Acc1 is max(H, Acc),
    max_rec(T, Acc1, M).

price(apple, 3).
price(pear, 5).
price(plum, 2).

demo_aggregate :-
    say("---- 4. 可移植的聚合写法 ----"),
    count_all(likes(_W, _), N),
    format("  一共有 ~w 条 likes 事实~n", [N]),

    sum_of(P, price(_F, P), Total),
    format("  所有商品价格之和         = ~w~n", [Total]),
    count_all(price(_F2, _P2), NPrice),
    format("  商品条数                 = ~w~n", [NPrice]),
    max_of(P3, price(_F3, P3), MaxP),
    format("  最贵的价格               = ~w~n", [MaxP]),

    % 也可以让模板直接算出一个数：统计每个人喜欢几样
    findall(W2 - N2, ( member(W2, [mary, john]),
                       findall(_Y, likes(W2, _), Ls),
                       length(Ls, N2) ), Counts),
    format("  每人喜欢几样             = ~w~n", [Counts]),
    say("  这几个 helpers 都是同一模式：findall 收值 → 对列表递归。"),
    say("  SWI 的 aggregate_all/3 能少写几行，但 GNU 没有，所以本教程不用。").

%% ---------------------------------------------------------------------------
%%  五、小心：findall 不能跨副作用收集顺序保证
%% ---------------------------------------------------------------------------
demo_caveat :-
    say("---- 5. 三个必须知道的坑 ----"),

    % 坑 1：Goal 里带副作用时，findall 会把全部解跑完才返回
    findall(X, ( member(X, [1, 2, 3]), format("    正在处理 ~w~n", [X]) ), _),
    say("  上面三行「正在处理」是 findall 一口气跑完全部解的结果。"),

    % 坑 2：模板里变量写重了，语义和你以为的不一样
    findall(X - X, member(X, [1, 2]), Pairs),
    format("  findall(X-X, member(X,[1,2]))  = ~w~n", [Pairs]),
    say("  X-X 只是「同一个值配自己」，不是「元素配下标」。"),
    findall(I - V, nth0(I, [a, b, c], V), Indexed),
    format("  元素配下标要显式给两个变量：~w~n", [Indexed]),

    % 坑 3：findall 的 Goal 抛异常时，异常会穿出来
    (   catch(findall(_Z, ( member(1, [1]), _Q4 is 0 / 0 ), _), _, fail)
    ->  say("  坑 3：Goal 里抛异常时 catch 生效（这里不该出现）")
    ;   say("  坑 3：Goal 里抛异常，异常会穿过 findall，需要自己在外面 catch")
    ).

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
    format("==== 13 开始 ====~n", []),
    say("findall 收集、bagof 分组、setof 排序去重 —— 三者的差别只在语义细节。"),
    say(""),

    demo_findall,   say(""),
    demo_bagof,     say(""),
    demo_setof,     say(""),
    demo_aggregate, say(""),
    demo_caveat,    say(""),

    format("==== 13 结束 ====~n", []).
