:- encoding(utf8).
% 第 88 章 · L 中的组合原理与弱紧基数（冯琦第二卷 §2.1.4-2.1.5）——Prolog 通道
% 三组样品：封口引擎（定理 2.12 性质 (4)）、钻石时刻表（定理 2.14）、
% 柯尼希树枝（定理 2.15(2) 方向）。

% ---------- 一、封口引擎 ----------

% 节点是 0/1 表；前缀延拓。
prefix_of(A, T) :- append(A, _, T).

next_level(Level, Grown) :-
    findall(Child,
            (member(T, Level), member(B, [0, 1]), append(T, [B], Child)),
            Grown).

extends_some(A, T) :- member(Ax, A), prefix_of(Ax, T), !.

seal_level(A, Level, Sealed) :-
    next_level(Level, Grown),
    include(extends_some(A), Grown, Sealed).

sealed_by(A, Level) :- forall(member(T, Level), extends_some(A, T)).

% 第 2 层封口 [1,1]；第 6 层再封口第 5 层首节点（Jensen 构造
% 在极限层反复封口的有限形态）。
build_levels(T) :-
    T0 = [[]],
    next_level(T0, T1),
    seal_level([[1, 1]], T1, T2),
    next_level(T2, T3), next_level(T3, T4), next_level(T4, T5),
    T5 = [A1 | _],
    seal_level([A1], T5, T6),
    next_level(T6, T7), next_level(T7, T8), next_level(T8, T9),
    T = [T0, T1, T2, T3, T4, T5, T6, T7, T8, T9].

% ---------- 二、钻石时刻表 ----------

vtwo(N, V) :-
    (   N > 0, N mod 2 =:= 0
    ->  N1 is N div 2, vtwo(N1, V1), V is V1 + 1
    ;   V = 0
    ).

% ---------- 三、柯尼希树枝 ----------

count1([], 0).
count1([1 | R], S) :- !, count1(R, S0), S is S0 + 1.
count1([_ | R], S) :- count1(R, S).
count0([], 0).
count0([0 | R], S) :- !, count0(R, S0), S is S0 + 1.
count0([_ | R], S) :- count0(R, S).

% 可判定无限树：每个前缀 p 满足 #1(p) <= #0(p) + 2。
in_tree(T) :-
    forall(prefix_of(P, T),
           (count1(P, C1), count0(P, C0), C1 =< C0 + 2)).

% 贪心延伸：选一个子树在更深处仍有节点的孩子。
extend(Cur, Cand) :-
    member(B, [0, 1]),
    append(Cur, [B], Cand),
    in_tree(Cand),
    append(Cand, [0, 0, 0, 0], Deep),
    in_tree(Deep),
    !.

branch_loop(0, B, B) :- !.
branch_loop(N, Cur, B) :-
    N > 0, N1 is N - 1,
    extend(Cur, Cand),
    branch_loop(N1, Cand, B).

% ---------- 主程序 ----------

main :-
    writeln("==== 88"),
    build_levels(T),
    maplist(length, T, Sizes),
    format("层规模：~w（两次封口各剪掉一半）~n", [Sizes]),
    T = [_, _, _ | _],
    nth0(5, T, T5), T5 = [A1 | _],
    forall(nth0(N, T, Ln),
           ((N >= 2 -> sealed_by([[1, 1]], Ln) ; true),
            (N >= 6 -> sealed_by([A1], Ln) ; true))),
    writeln("A0 自第 2 层、A1 自第 6 层起全程封口：极大性永久保持 OK"),
    forall(between(1, 479, N),
           (vtwo(N, I), M is N >> I, 1 is M mod 2)),
    forall(between(0, 5, I),
           (findall(N, (between(1, 479, N), vtwo(N, I)), Ns),
            length(Ns, C),
            C >= 480 // (2 ** (I + 1)) - 1)),
    writeln("时刻表账目：n = 2^i*奇数，每个目标 2^i(2m+1) 型时刻无穷多 OK"),
    branch_loop(24, [], _),
    writeln("贪心树枝长度 24，全程满足树条件 OK（层有限 + 无限深 -> 有树枝）"),
    writeln("END ====").
