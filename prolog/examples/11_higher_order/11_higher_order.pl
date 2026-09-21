%% ============================================================================
%%  11_higher_order.pl —— 高阶谓词与闭包
%%
%%  Prolog 的「函数」是谓词，而谓词本身就是一个项 —— 所以可以把谓词当参数传。
%%  两种传法：
%%    1. 传原子/复合项（closure）：把「谓词名 + 已绑定的额外参数」打包成一个项
%%         传 plus/3 之外的 plus(3) 表示「加 3」
%%    2. 直接传一个目标项（goal）：call((member(X,L), X > 1))
%%
%%  调用它们的唯一入口是 call/1..call/8：
%%    call(G)        执行目标项 G
%%    call(C, A)     把 C 当成 A 元谓词来调（C 可以是原子或闭包）
%%    call(C, A, B)  同上
%%
%%  本教程约定：只用 call/N、maplist/2,3、forall/2 这几个两套引擎都有的，
%%  其余（foldl/4+、include/3、exclude/3、partition/4 …）都手写。
%% ============================================================================

:- set_prolog_flag(double_quotes, codes).

say(S) :- format("~s~n", [S]).

%% ---------------------------------------------------------------------------
%%  一、call/1：把「目标」当数据
%% ---------------------------------------------------------------------------
demo_call :-
    say("---- 1. call/1：目标是项，可以当参数传 ----"),
    G = member(a, [a, b]),
    (   call(G)
    ->  say("  G = member(a,[a,b])  call(G)  成立")
    ;   say("  G = member(a,[a,b])  call(G)  不成立")
    ),
    % 复合目标也能装进一个项里
    G2 = (member(X, [1, 2, 3]), X > 1),
    findall(X, call(G2), L2),
    format("  call((member(X,[1,2,3]), X>1))  X 的取值 = ~w~n", [L2]),
    say("  换句话：目标不只是「代码」，它同时是「可以运算的数据」。"),
    say("  这一条让「写一个引擎」变得可行（第 12、24 章）。").

%% ---------------------------------------------------------------------------
%%  二、call/N：闭包
%% ---------------------------------------------------------------------------
demo_closure :-
    say("---- 2. 闭包：把参数「预先装进」谓词 ----"),

    % plus(A,B) 是普通二元谓词；plus(3) 是一个只差一个参数的闭包
    C = plus(3),
    call(C, 4, R),
    format("  C = plus(3), call(C, 4) -> ~w~n", [R]),

    % 闭包可以放进列表里，做成「策略表」
    findall(R2, ( member(C2, [plus(10), plus(20), plus(30)]), call(C2, 5, R2) ), Rs),
    format("  对 5 分别施加 +10/+20/+30：~w~n", [Rs]),

    % 闭包也能预置多个参数，剩下的留给调用者
    findall(R3, ( member(C3, [scale(2), scale(3)]), call(C3, 10, R3) ), Rs3),
    format("  对 10 分别做 scale(2)/scale(3)：~w~n", [Rs3]),

    say("  闭包 = 「谓词名 + 部分实参」打包成的项。"),
    say("  这等价于函数式语言里的 partial application，但 Prolog 不需要 lambda。"),
    say("  注意只能补「前若干个」参数，不能只补后面的 —— 所以写库时习惯把"),
    say("  「配置参数」放前面、「数据参数」放最后。").

plus(A, B, C) :- C is A + B.
scale(K, X, Y) :- Y is K * X.

%% ---------------------------------------------------------------------------
%%  三、maplist：批量施加
%% ---------------------------------------------------------------------------
sq(X, Y) :- Y is X * X.
in_range(X) :- X >= 2, X =< 4.

demo_maplist :-
    say("---- 3. maplist/2 与 maplist/3 ----"),
    maplist(sq, [1, 2, 3, 4], Squares),
    format("  maplist(sq, [1,2,3,4])    = ~w~n", [Squares]),
    (   maplist(in_range, [2, 3, 4])
    ->  say("  maplist(in_range, [2,3,4]) 全部满足 -> 成立")
    ;   say("  maplist(in_range, [2,3,4]) 成立")
    ),
    (   maplist(in_range, [1, 9])
    ->  say("  maplist(in_range, [1,9])   有元素不满足 -> 成立？")
    ;   say("  maplist(in_range, [1,9])   有元素不满足 -> 失败")
    ),
    say("  maplist/2 是「全部满足」语义：任何一个元素失败，整体就失败。"),
    say("  它不产生部分结果，所以别指望它做 filter —— filter 用下面的 partition。"),

    % maplist/3 两个列表长度必须一致
    (   maplist(sq, [1, 2], [1, 4, 9])
    ->  say("  长度不一致时 maplist/3 居然成立？")
    ;   say("  maplist/3 要求两个列表等长，长度不一致直接失败")
    ).

%% ---------------------------------------------------------------------------
%%  四、手写 foldl / partition / zip
%%  内建的 foldl/4+ 与 include/exclude 只有 SWI 有，所以自己写一份。
%% ---------------------------------------------------------------------------
my_foldl(_, [], Acc, Acc).
my_foldl(P, [H | T], Acc, R) :-
    call(P, H, Acc, Acc1),
    my_foldl(P, T, Acc1, R).

my_partition(_, [], [], []).
my_partition(P, [H | T], Yes, No) :-
    (   call(P, H)
    ->  Yes = [H | YT],
        No = NT
    ;   Yes = YT,
        No = [H | NT]
    ),
    my_partition(P, T, YT, NT).

my_zip([], [], []).
my_zip([A | As], [B | Bs], [A - B | Ps]) :-
    my_zip(As, Bs, Ps).

sum3(X, Acc, Acc1) :- Acc1 is Acc + X.

demo_own :-
    say("---- 4. 手写 foldl / partition / zip ----"),
    my_foldl(sum3, [1, 2, 3, 4], 0, Sum),
    format("  my_foldl(+, [1,2,3,4], 0)  = ~w~n", [Sum]),

    my_partition(in_range, [1, 2, 3, 4, 5], Yes, No),
    format("  my_partition(2=<X=<4, [1..5])  满足 = ~w，不满足 = ~w~n", [Yes, No]),

    my_zip([a, b, c], [1, 2, 3], Pairs),
    format("  my_zip([a,b,c],[1,2,3])    = ~w~n", [Pairs]),

    % 闭包 + foldl 组合出「任意聚合」
    my_foldl(sum3, [1, 2, 3], 100, R2),
    format("  my_foldl(+, [1,2,3], 100)  = ~w（初值可任意）~n", [R2]),
    say("  注意三个手写版的共同点：递归骨架完全一样，只有 call(P, ...) 那行不同。"),
    say("  把「遍历」和「动作」分开，就是高阶谓词的全部价值。").

%% ---------------------------------------------------------------------------
%%  五、forall/2：把「对所有元素都成立」写成一句话
%% ---------------------------------------------------------------------------
demo_forall :-
    say("---- 5. forall/2 做「全部满足」判定 ----"),
    (   forall(member(X, [2, 3, 4]), X > 1)
    ->  say("  forall(member(X,[2,3,4]), X>1)  成立")
    ;   say("  forall(member(X,[2,3,4]), X>1)  不成立")
    ),
    (   forall(member(X2, [2, 3, 4]), X2 > 3)
    ->  say("  forall(member(X,[2,3,4]), X>3)  成立？")
    ;   say("  forall(member(X,[2,3,4]), X>3)  不成立")
    ),
    say("  forall(Cond, Action) 在 ISO 里等价于 \\+ (Cond, \\+ Action)："),
    say("  只要有一个 Cond 解让 Action 不成立，整个 forall 就失败。"),
    say("  它是「全部」语义的判定器，不产生新解 —— 判定用的首选。"),

    % forall 做副作用（打印）也很地道
    findall(N, between(1, 3, N), L),
    say("  用 forall 打印一行一个元素："),
    forall(member(E, L), format("    ~w~n", [E])).

%% ---------------------------------------------------------------------------
%%  六、用 =.. 动态构造目标再调用
%% ---------------------------------------------------------------------------
demo_dynamic :-
    say("---- 6. =.. 造目标 + call ----"),
    Functor = plus,
    Args = [3, 9],
    Goal =.. [Functor | Args],
    call(Goal, R),
    format("  Goal =.. [plus,3,9]  ->  call(Goal, R)  R = ~w~n", [R]),
    say("  这是 Prolog 版的「反射」：谓词名来自变量、参数来自列表，"),
    say("  组合成目标再执行。配置驱动的解释器就靠这一手（第 24 章）。").

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
    format("==== 11 开始 ====~n", []),
    say("谓词就是项，所以可以当参数传 —— 这就是 Prolog 的高阶谓词。"),
    say(""),

    demo_call,    say(""),
    demo_closure, say(""),
    demo_maplist, say(""),
    demo_own,     say(""),
    demo_forall,  say(""),
    demo_dynamic, say(""),

    format("==== 11 结束 ====~n", []).
