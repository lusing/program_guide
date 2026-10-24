:- encoding(utf8).
% 第 78 章：奇异基数假设——银杰与嘎尔文-海纳（冯琦 §2.4）——Prolog 通道
% 两个搜索：desc_chain(N,K) 从 N 出发的严格递减自然数链（最大 K=N，良基性
% 的可执行形态；链长无界 ⟺ 起点无界，对应 no_omega_descending 的逆否读法）；
% 底集 {1..4} 的 15 个非空子集上两两交 ≤1 的极大几乎不相交族搜索（最大 10
% =单点集全体+二元集全体），对应引理 2.19 计数前的组合前提。

% ---------- 搜索一：递减链 ----------
step_down(A, B) :- between(0, A, B), B < A.

chain_from(0, [0]).
chain_from(N, [N|Rest]) :-
    N > 0,
    step_down(N, M),
    chain_from(M, Rest).

% desc_chain(N,K)：从 N 出发、恰 K 条边触零的一条严格递减链
desc_chain(N, K) :-
    chain_from(N, Chain),
    length(Chain, L),
    K is L - 1.

max_desc_len(N, K) :-
    findall(KK, desc_chain(N, KK), Ks),
    max_list(Ks, K).

% ---------- 搜索二：几乎不相交族 ----------
subset_of([], []).
subset_of([H|T], [H|S]) :- subset_of(T, S).
subset_of([_|T], S) :- subset_of(T, S).

nonempty_subsets(Base, Subs) :-
    findall(S, (subset_of(Base, S), S \= []), Subs).

almost_disjoint(Fam) :-
    forall((member(A, Fam), member(B, Fam), A \== B),
           (intersection(A, B, I), length(I, K), K =< 1)).

tagged_max([H], H).
tagged_max([Len-X|T], Best) :-
    tagged_max(T, Best0),
    Best0 = (Len0-_),
    (Len > Len0 -> Best = (Len-X) ; Best = Best0).

max_ad_family(Base, NSub, MaxSize, MaxFam) :-
    nonempty_subsets(Base, Subs),
    length(Subs, NSub),
    findall(Size-Fam,
        (subset_of(Subs, Fam), almost_disjoint(Fam), length(Fam, Size)),
        Tagged),
    tagged_max(Tagged, MaxSize-MaxFam0),
    sort(MaxFam0, MaxFam).

% ---------- 主检定 ----------
main :-
    format("==== 78~n"),
    % 搜索一：从 N 出发的递减链最大边数 = N
    forall(between(1, 6, N), (max_desc_len(N, K), K =:= N)),
    desc_chain(4, K4), K4 = 4,
    format("递减链搜索：从 N 出发的严格递减自然数链最大 ~w 条边（N=1..6 全部 K=N）——触零即止，良基性 ✓~n", [K4]),
    forall(between(1, 6, L), (desc_chain(L, KL), KL >= L)),
    writeln("  逆否读法：链长可任意大 ⟺ 起点可任意大（no_omega_descending 的有限影）✓"),
    % 搜索二：极大几乎不相交族
    max_ad_family([1,2,3,4], NSub, MaxSize, MaxFam),
    NSub = 15, MaxSize = 10,
    format("几乎不相交族搜索：{1..4} 的 ~w 个非空子集中两两交 ≤1 的极大族最大 ~w 个 ✓~n", [NSub, MaxSize]),
    format("  见证族（单点集全体+二元集全体）：~w~n", [MaxFam]),
    writeln("END ====").
