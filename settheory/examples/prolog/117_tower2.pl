:- encoding(utf8).

% 第 117 章：荟萃塔 II——见证提升、定向复合与临界点小模型表。
% 只检查三级有限模型；不声称证明 Q<δ 的泛型性或 Woodin 定理。

point(0). point(1). point(2).
mark(0, 0). mark(1, 1). mark(2, 2).

proj(0, _, 0).
proj(1, 0, 0). proj(1, 1, 1). proj(1, 2, 1).
proj(2, X, X).

funs([F0, F1, F2]) :-
    member(F0, [0,1,2]), member(F1, [0,1,2]), member(F2, [0,1,2]).

feval(F, X, V) :- nth0(X, F, V).
lift_eval(K, F, X, V) :- proj(K, X, Y), feval(F, Y, V).
rep(K, F, V) :- mark(K, X), feval(F, X, V).

% 一个见证从低层提升后，在高层标志坐标上保持代表值。
rep_lift_ok(K, L, F) :-
    rep(K, F, V), mark(L, X), lift_eval(K, F, X, V).

representation_table :-
    forall((member((K,L), [(0,1),(0,2),(1,2)]), funs(F)),
           rep_lift_ok(K, L, F)).

% 两次提升与直接提升逐点一致。
composition_table :-
    forall((member((K,L), [(0,1),(0,2),(1,2)]), funs(F), point(X)),
           (proj(L, X, Y), lift_eval(K, F, Y, A),
            lift_eval(K, F, X, B), A =:= B)).

restriction_table :-
    forall((funs(F), member(X, [0,1])),
           (lift_eval(1, F, X, A), feval(F, X, B), A =:= B)).

% crit=1、目标=2：0 固定而 1 被送到 2。
jfin(0, 0). jfin(1, 2). jfin(2, 3).
critical_point_table :-
    jfin(0, 0), jfin(1, 2), jfin(2, 3),
    \+ jfin(1, 1),
    forall((point(X), X < 1), jfin(X, X)).

% 同一集合的特征词：前缀树与分支表互相复原。
word(A, W) :-
    findall(B, (member(X, [0,1,2]), (member(X, A) -> B=1 ; B=0)), W).

prefix_tree(A, T) :-
    word(A, W),
    findall(P, (between(0, 3, N), length(P, N), append(P, _, W)), T).

branch_table(A, B) :-
    word(A, W),
    findall(X-Bit, (nth0(X, W, Bit)), B).

from_prefix(T, A) :-
    findall(X, (between(0, 2, X), N is X+1, nth0(N, T, P), nth0(X, P, 1)), A).

from_branch(B, A) :-
    findall(X, member(X-1, B), A).

tree_table :-
    forall(between(0, 7, M),
           (findall(X, (between(0, 2, X), 1 is (M >> X) /\ 1), A),
            prefix_tree(A, T), branch_table(A, B),
            from_prefix(T, A1), from_branch(B, A2),
            A1 == A, A2 == A)).

main :-
    representation_table, composition_table, restriction_table,
    critical_point_table, tree_table,
    writeln("==== 117"),
    writeln("27 函数×3 层对：见证提升与代表值保持；复合兼容"),
    writeln("8 个子集：前缀树/分支表一致；crit=1 小模型表通过"),
    writeln("END ====").
