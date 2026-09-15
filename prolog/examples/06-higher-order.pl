% ============================================================
%  06-higher-order.pl —— 高阶谓词与元调用
%
%  运行（SWI）: swipl -q -f examples/06-higher-order.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/06-higher-order.pl --entry-goal main
%
%  Prolog 没有 lambda，但可以用「部分应用的项 + call/N」达到同样效果。
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  一、call/N：把谓词当值传
% ------------------------------------------------------------
double(X, Y) :- Y is X * 2.
pair_with(A, B, A-B).
add3(A, B, C) :- C is A + B.

demo_call :-
    format("---- call/N ----~n", []),
    call(double, 21, R1),
    format("  call(double, 21, X)      -> ~w~n", [R1]),
    call(pair_with(a), b, R2),
    format("  call(pair_with(a), b, X) -> ~w（少给一个参数 = 部分应用）~n", [R2]),
    % 用 Goal 变量保存「待补参数的目标」
    Goal = add3(10),
    call(Goal, 5, R3),
    format("  Goal = add3(10), call(Goal,5,X) -> ~w~n", [R3]).

% ------------------------------------------------------------
%  二、maplist：对列表逐元素应用
%     maplist(Goal, L1, L2)     一一映射
%     maplist(Goal, L1, L2, L3) 二元映射
%     两个引擎都有，是最可移植的高阶谓词
% ------------------------------------------------------------
demo_maplist :-
    format("---- maplist ----~n", []),
    maplist(double, [1,2,3], Ds),
    format("  maplist(double, [1,2,3], X) -> ~w~n", [Ds]),
    maplist(add3, [1,2,3], [10,20,30], Ss),
    format("  maplist(add3, 两列表逐项相加) -> ~w~n", [Ss]),
    % 用部分应用做闭包：把常量「烤」进目标里
    maplist(pair_with(tag), [a,b,c], Ps),
    format("  maplist(pair_with(tag), [a,b,c], X) -> ~w~n", [Ps]),
    format("  这就是 Prolog 版闭包：把常量写进项，剩下的参数交给 maplist~n", []),
    % 判定式：全部满足才算成功
    ( maplist(>(10), [1,2,3]) -> format("  maplist(>(10),[1,2,3]) -> 真（10>1,10>2,10>3）~n", []) ; true ),
    ( maplist(>(2), [1,2,3])  -> true
    ; format("  maplist(>(2),[1,2,3])  -> 假（注意 >(2) 表示 2>X）~n", []) ).

% ------------------------------------------------------------
%  三、自写 fold / scan（SWI 的 foldl/4 在 GNU 里没有）
% ------------------------------------------------------------
my_foldl([], _, Acc, Acc).
my_foldl([X | Xs], Goal, Acc, R) :-
    call(Goal, Acc, X, Acc1),
    my_foldl(Xs, Goal, Acc1, R).

demo_fold :-
    format("---- 折叠 ----~n", []),
    my_foldl([1,2,3,4], add3, 0, Sum),
    format("  求和：~w~n", [Sum]),
    my_foldl([1,2,3,4], mul3, 1, Prod),
    format("  求积：~w~n", [Prod]),
    my_foldl([], add3, 0, Empty),
    format("  空列表：~w（单位元的重要性）~n", [Empty]).

mul3(A, B, C) :- C is A * B.

% ------------------------------------------------------------
%  四、=..（univ）：项 <-> 列表 互转
% ------------------------------------------------------------
demo_univ :-
    format("---- =..（univ）----~n", []),
    T1 = point(3, 4),
    T1 =.. L1,
    format("  point(3,4) =.. X       -> ~w~n", [L1]),
    L2 = [circle, 5],
    T2 =.. L2,
    format("  [circle,5] =.. X       -> ~q~n", [T2]),
    % 典型用途：给任意复合项「改函子」（rename_functor/3 定义在下面）
    rename_functor(point(1,2), vec, T3),
    format("  换函子 point(1,2) -> vec -> ~q~n", [T3]),
    % functor/3 与 arg/3
    functor(point(1,2), Fn, Ar),
    format("  functor(point(1,2))    -> ~q / ~w~n", [Fn, Ar]),
    arg(2, point(1,2), A2),
    format("  arg(2, point(1,2))     -> ~w~n", [A2]).

rename_functor(Term, NewF, Out) :-
    Term =.. [_ | Args],
    Out =.. [NewF | Args].

% ------------------------------------------------------------
%  五、用元编程做「通用遍历器」
% ------------------------------------------------------------
% 对任意复合项的所有参数做变换
map_term(In, Goal, Out) :-
    (   compound(In)
    ->  In =.. [F | Args],
        maplist(map_term_arg(Goal), Args, NewArgs),
        Out =.. [F | NewArgs]
    ;   call(Goal, In, Out)
    ).

map_term_arg(Goal, A, B) :- map_term(A, Goal, B).

bump(X, Y) :- number(X), !, Y is X + 1.
bump(X, X).

demo_map_term :-
    format("---- 通用项变换 ----~n", []),
    In = f(1, g(2, h(3)), atom),
    map_term(In, bump, Out),
    format("  ~q 里所有数字 +1 -> ~q~n", [In, Out]).

% ------------------------------------------------------------
%  六、apply 风格：把谓词存进事实库（解释器常见套路）
% ------------------------------------------------------------
:- dynamic(op_table/2).
op_table(add, add3).
op_table(mul, mul3).
op_table(dbl, double).

% 表里混着二元和一元谓词，用 catch 兜住「参数个数不匹配」的错误
% （SWI 和 GNU 默认都会抛 existence_error，而不是安静地失败）
eval_op(Name, A, B, R) :-
    op_table(Name, P),
    (   catch(call(P, A, B, R), _, fail)
    ->  true
    ;   call(P, A, R)
    ).

demo_table :-
    format("---- 谓词表（解释器套路）----~n", []),
    forall(member(N, [add, mul, dbl]),
           ( eval_op(N, 6, 7, V), format("  ~w(6,7) = ~w~n", [N, V]) )).

run :-
    format("==== 06  高阶谓词与元调用 ====~n", []), nl,
    demo_call,      nl,
    demo_maplist,   nl,
    demo_fold,      nl,
    demo_univ,      nl,
    demo_map_term,  nl,
    demo_table.

main :-
    (   catch((run, nl, format("==== 06 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 06 运行失败~n", []), halt(1)
    ).
