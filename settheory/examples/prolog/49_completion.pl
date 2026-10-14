:- encoding(utf8).
% 第 49 章 布尔补全：V 形偏序的 RO(Q) 查询（Julia 版的 Prolog 镜像）

% ---------- V 形偏序：1=c 底，2=a，3=b ----------
le(X, Y) :- X == Y, !.
le(1, _).

% 下闭集判定与枚举
down(1, [1]).
down(2, [1,2]).
down(3, [1,3]).

downclosed(S) :-
    forall((member(P, S), down(P, D),
            member(Q, D)), member(Q, S)).

allsubsets([[],[1],[2],[3],[1,2],[1,3],[2,3],[1,2,3]]).

% 序拓扑开集 = 下闭集
open_set(S) :- allsubsets(All), member(S, All), downclosed(S).

% 闭集 = 开集的补；闭包 = 含 U 的最小闭集
compl(S, C) :- subtract([1,2,3], S, C).

closure(U, C) :-
    findall(K, (open_set(O), compl(O, K), subset(U, K)), Ks),
    shortest(Ks, C).

shortest([K], K) :- !.
shortest([K|Ks], C) :- shortest(Ks, C0),
    (length(K, L1), length(C0, L2), L1 =< L2 -> C = K ; C = C0).

% 内部 = 含于 U 的最大开集
interior(U, I) :-
    findall(O, (open_set(O), subset(O, U)), Os),
    longest(Os, I).

longest([O], O) :- !.
longest([O|Os], I) :- longest(Os, I0),
    (length(O, L1), length(I0, L2), L1 >= L2 -> I = O ; I = I0).

subset(A, B) :- forall(member(X, A), member(X, B)).

reg(U, R) :- closure(U, C), interior(C, R).

% j(p) = Reg(↓p)
jp(P, J) :- down(P, D), reg(D, J).

% ---------- 主检查 ----------
main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 49 V 形偏序的 RO 补全（Prolog 镜像）~n"),

    findall(O, open_set(O), Opens),
    sort(Opens, Os), length(Os, NO),
    format("序拓扑开集（下闭集）~w 个：~w~n", [NO, Os]),

    jp(1, J1), jp(2, J2), jp(3, J3),
    format("j(c) = ~w, j(a) = ~w, j(b) = ~w~n", [J1, J2, J3]),
    J1 == J2, J2 == J3,           % 三者坍缩为全集
    format("三者同一——V 形无可分离对，j 非单射（Cor 4.2.7 反例现场）✓~n"),

    findall(R, (open_set(O), reg(O, R)), Rs0),
    sort(Rs0, Rs), length(Rs, NR),
    NR == 2,
    format("RO(Q) = ~w（~w 元）——补全坍缩为 2 元布尔代数 ✓~n", [Rs, NR]),

    format("END ===="), nl.
