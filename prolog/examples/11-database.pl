% ============================================================
%  11-database.pl —— 动态数据库（在运行时改程序本身）
%
%  运行（SWI）: swipl -q -f examples/11-database.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/11-database.pl --entry-goal main
%
%  Prolog 的数据库可以在运行时增删子句 —— 这是它区别于
%  绝大多数语言的一点：程序和数据是同一种东西。
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% 必须先声明，否则 assertz 会报错
:- dynamic(counter/1).
:- dynamic(todo/2).
:- dynamic(memo/2).
:- dynamic(edge/2).

% ------------------------------------------------------------
%  一、assertz / asserta / retract / retractall
%     assertz：加到末尾（默认顺序）
%     asserta：加到开头（优先级高）
% ------------------------------------------------------------
demo_assert :-
    format("---- assertz / asserta / retract ----~n", []),
    assertz(todo(1, '买牛奶')),
    assertz(todo(2, '写教程')),
    asserta(todo(0, '起床')),      % 插到最前面
    findall(Id-Task, todo(Id, Task), All),
    format("  全部 todo：~w~n", [All]),
    format("  （asserta 的 0 号排在最前，证明插入位置有区别）~n", []),
    retract(todo(1, _)),
    findall(Id2-Task2, todo(Id2, Task2), After),
    format("  retract 掉 1 号后：~w~n", [After]),
    retractall(todo(_, _)),
    ( todo(_, _) -> format("  还有残留~n", []) ; format("  retractall 清空完毕~n", []) ).

% ------------------------------------------------------------
%  二、用动态库做计数器（替代全局变量）
% ------------------------------------------------------------
reset_counter :- retractall(counter(_)), assertz(counter(0)).
bump_counter(N) :-
    retract(counter(Old)),
    N is Old + 1,
    assertz(counter(N)).
peek_counter(N) :- counter(N).

demo_counter :-
    format("---- 计数器（Prolog 版全局变量）----~n", []),
    reset_counter,
    forall(between(1, 5, _), bump_counter(_)),
    peek_counter(C),
    format("  bump 五次后：~w~n", [C]),
    format("  注意 retract+assertz 不是原子操作；真要并发就得加锁。~n", []).

% ------------------------------------------------------------
%  三、用动态库做缓存（memoization）
% ------------------------------------------------------------
:- dynamic(fib_naive_memo/2).

fib_slow(0, 0).
fib_slow(1, 1).
fib_slow(N, F) :- N > 1, A is N-1, B is N-2, fib_slow(A, FA), fib_slow(B, FB), F is FA+FB.

fib_memo(N, F) :-
    (   memo(N, Cached)
    ->  F = Cached
    ;   fib_slow(N, F0),
        F = F0,
        assertz(memo(N, F0))
    ).

demo_memo :-
    format("---- 用动态库做缓存 ----~n", []),
    retractall(memo(_, _)),
    fib_memo(20, A),
    format("  fib_memo(20) = ~w（第一次，真的算）~n", [A]),
    findall(K-_, memo(K, _), Keys),
    length(Keys, NK),
    format("  缓存里已有 ~w 条记录~n", [NK]),
    fib_memo(20, B),
    format("  fib_memo(20) = ~w（第二次，直接命中缓存）~n", [B]),
    retractall(memo(_, _)).

% ------------------------------------------------------------
%  四、动态谓词 + 图 = 可变图算法
% ------------------------------------------------------------
build_graph :-
    retractall(edge(_, _)),
    assertz(edge(a, b)), assertz(edge(b, c)),
    assertz(edge(c, d)), assertz(edge(a, c)),
    assertz(edge(d, a)).

% 朴素写法在有环图上会无限枚举（a->b->c->d->a），必须带 visited
% reachable(X, Y) :- edge(X, Y).
% reachable(X, Y) :- edge(X, Z), reachable(Z, Y).
reachable(X, Y) :- reach(X, Y, [X]).
reach(X, Y, _) :- edge(X, Y).
reach(X, Y, Visited) :-
    edge(X, Z),
    \+ memberchk(Z, Visited),
    reach(Z, Y, [Z | Visited]).

path2(X, Y, [X, Y]) :- edge(X, Y).
path2(X, Y, [X | Rest]) :- edge(X, Z), path2(Z, Y, Rest).

% 带 visited 的搜索，避免环路导致无限递归
walk(From, To, Visited, [To]) :-
    edge(From, To),
    \+ memberchk(To, Visited).
walk(From, To, Visited, [Next | Rest]) :-
    edge(From, Next),
    \+ memberchk(Next, Visited),
    walk(Next, To, [Next | Visited], Rest).

demo_graph :-
    format("---- 动态图 ----~n", []),
    build_graph,
    findall(X-Y, edge(X, Y), Es),
    format("  边：~w~n", [Es]),
    findall(R, reachable(a, R), Rs),
    format("  从 a 可达：~w~n", [Rs]),
    ( walk(a, d, [a], P) -> format("  a->d 无环路径：~w~n", [P]) ; true ),
    format("  图存在环（d->a），不加 visited 集合会无限递归。~n", []).

% ------------------------------------------------------------
%  五、clause/2：把程序当数据读
% ------------------------------------------------------------
demo_clause :-
    format("---- clause/2 反射 ----~n", []),
    build_graph,
    findall(Head-Body, clause(edge(Head, _), Body), Cs),
    length(Cs, NC),
    format("  clause(edge(H,_), B) 取到 ~w 条~n", [NC]),
    ( clause(edge(X1, Y1), true) -> format("  其中一条：edge(~w, ~w)，体是 true~n", [X1, Y1]) ; true ),
    format("  注意：静态谓词在 GNU Prolog 里也能用 clause/2，~n", []),
    format("  但 gplc 编译时可能把不存在的调用直接报 link error（见 07 的坑）。~n", []).

% ------------------------------------------------------------
%  六、坑：动态库的生命周期
% ------------------------------------------------------------
demo_pitfalls :-
    format("---- 坑 ----~n", []),
    format("  1) 忘了 :- dynamic(p/n) 就 assertz，两个引擎都报错~n", []),
    format("  2) 语法：SWI 可写 :- dynamic foo/1，GNU 只认 :- dynamic(foo/1).~n", []),
    format("     所以本教程统一写成带括号的形式~n", []),
    format("  3) 动态库默认跨查询保留 —— 重跑程序前记得 retractall 清理~n", []),
    format("  4) assert 进去的事实在回溯时不会自动撤销，要自己写清理逻辑~n", []),
    format("  5) 大量 assert/retract 会留下垃圾，长跑程序注意性能~n", []).

run :-
    format("==== 11  动态数据库 ====~n", []), nl,
    demo_assert,   nl,
    demo_counter,  nl,
    demo_memo,     nl,
    demo_graph,    nl,
    demo_clause,   nl,
    demo_pitfalls.

main :-
    (   catch((run, nl, format("==== 11 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 11 运行失败~n", []), halt(1)
    ).
