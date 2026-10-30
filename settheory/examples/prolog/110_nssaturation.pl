:- encoding(utf8).
% 第 110 章：投影、饱和界与反射可比对查询（光影原理的有限实例）。

% ── 一、位掩码宇宙与投影 π ──
proj(M, P) :- P is M /\ 6.                % 抹掉坐标 0

ideal_member(i0, M) :- member(M, [0, 1]).  % I₀ = {∅, {0}}
pos(i0, M) :- between(0, 7, M), \+ ideal_member(i0, M).

subL(M, N) :- D is M /\ (\N), D =:= 0.    % 位掩码包含 m ⊆ n
leq(I, C, D) :- Dg is C /\ (\D), ideal_member(I, Dg).   % C ≤ D ⟺ C−D ∈ I

% 类代表：mod-I 等价类中的最小正测元。
rep_min(I, M, R) :-
    findall(X, (between(0, 7, X), pos(I, X), leq(I, X, M), leq(I, M, X)), Xs),
    min_list(Xs, R).

% 商原子：是自己的类代表、且无更小的类代表在其下。
atom_of(I, R) :-
    pos(I, R),
    rep_min(I, R, R),
    \+ (pos(I, R2), rep_min(I, R2, R2), R2 \= R, leq(I, R2, R)).

% 商反链：两两不相容的正测族按类代表去重的规模（穷举核查）。
sub_powerset([], []).
sub_powerset([H|T], [H|S]) :- sub_powerset(T, S).
sub_powerset([_|T], S) :- sub_powerset(T, S).

family_incompat(I, A) :-
    \+ (member(C, A), member(D, A), C \= D,
        Int is C /\ D, \+ ideal_member(I, Int)).

max_antichain(I, Best) :-
    findall(M, pos(I, M), IP),
    findall(K, (sub_powerset(IP, A), A \= [], family_incompat(I, A),
                findall(R, (member(X, A), rep_min(I, X, R)), Rs0),
                sort(Rs0, Rs), length(Rs, K)), Ks),
    max_list(Ks, Best).

% ── 二、反射可比对（光影原理有限实例） ──
upward_closed(S) :-
    forall((member(N, S), pos(i0, N), pos(i0, N2), subL(N, N2)),
           member(N2, S)).

full_proj(S) :-
    forall(member(T, [2, 4, 6]), (member(N, S), proj(N, T))).

reflect_pair(S) :-
    member(N, S), member(N2, S), N \= N2, subL(N, N2),
    proj(N, P1), proj(N2, P2), P1 \= P2.

main :-
    format("==== 110~n"),
    % 投影样本。
    proj(7, 6), proj(3, 2), proj(1, 0),
    % 饱和界：I₀ 反链至多 2（= 商原子数）。
    max_antichain(i0, 2),
    atom_of(i0, 2), atom_of(i0, 4),
    \+ atom_of(i0, 6),
    % 核刻画：m ∈ I₀ ⟺ π(m) = 0。
    forall(between(0, 7, M),
           (ideal_member(i0, M) -> proj(M, 0) ; proj(M, P), P \= 0)),
    % 反链投影不交。
    forall((pos(i0, C), pos(i0, D), Int is C /\ D, ideal_member(i0, Int)),
           (proj(C, P1), proj(D, P2), PAnd is P1 /\ P2, PAnd =:= 0)),
    % 反射可比对：穷举全部上向闭 + 全投影的族。
    findall(M, pos(i0, M), IP),
    findall(S, (sub_powerset(IP, S), S \= [],
                upward_closed(S), full_proj(S)), PsFams),
    PsFams \= [],
    forall(member(S, PsFams), reflect_pair(S)),
    length(PsFams, Cnt),
    format("投影样本；饱和界 2=原子数；核=π⁻¹(∅)；反链投影不交；~n"),
    format("上向闭 PS 族 ~w 个全含反射可比对~n", [Cnt]),
    writeln("END ====").
