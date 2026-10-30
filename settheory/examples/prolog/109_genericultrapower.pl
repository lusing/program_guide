:- encoding(utf8).
% 第 109 章：理想力迫、泛型超滤子候选、稠密集相遇与下降链查询。

% ── 一、样本理想（位掩码）与正测集 ──
ideal(M) :- member(M, [0, 1]).            % I = {∅, {0}}
pos(M) :- between(0, 7, M), \+ ideal(M).
ipos(M) :- pos(M).

% C ≤ D ⟺ C − D ∈ I。
le(C, D) :- Dg is C /\ (\D), ideal(Dg).

% ── 二、泛型超滤子候选：主滤子 ──
gmem(a1, M) :- pos(M), M /\ 2 > 0.        % G(1)：含 1 的正测集
gmem(a2, M) :- pos(M), M /\ 4 > 0.        % G(2)：含 2 的正测集

% 超滤子四公理 (a)-(d)。
ultra(A) :-
    gmem(A, 7), \+ gmem(A, 0),
    forall((gmem(A, C), gmem(A, D)), (I is C /\ D, gmem(A, I))),
    forall((gmem(A, C), ipos(E), le(C, E)), gmem(A, E)),
    forall(ipos(C), (gmem(A, C) ; Uc is 7 /\ (\C), gmem(A, Uc))).

% ── 三、稠密集与相遇（去重子集枚举） ──
all_ipos(I) :- findall(M, ipos(M), I).

sub_ipos([], []).
sub_ipos([H|T], [H|S]) :- sub_ipos(T, S).
sub_ipos([_|T], S) :- sub_ipos(T, S).

dense(Ds) :- forall(ipos(X), (member(Y, Ds), le(Y, X))).

meets(A, Ds) :- member(Y, Ds), gmem(A, Y).

% ── 四、下降链（引理 2.30(3) 的有限影子） ──
desc_chain([C]) :- ipos(C).
desc_chain([C, D|Rest]) :-
    ipos(C), ipos(D), D \= C, le(D, C), \+ le(C, D),
    desc_chain([D|Rest]).

% ── 五、有限 Łoś 样本（真值集裁决） ──
fval(f, 0, 3). fval(f, 1, 1). fval(f, 2, 4).
fval(g, 0, 2). fval(g, 1, 2). fval(g, 2, 0).

truth_lt(N1, N2, M) :-
    ( fval(N1, 0, A), fval(N2, 0, B), A < B -> B1 = 1 ; B1 = 0 ),
    ( fval(N1, 1, A2), fval(N2, 1, B2), A2 < B2 -> B2v = 1 ; B2v = 0 ),
    ( fval(N1, 2, A3), fval(N2, 2, B3), A3 < B3 -> B3v = 1 ; B3v = 0 ),
    M is B1 + (B2v << 1) + (B3v << 2).

main :-
    format("==== 109~n"),
    % 序正反 + 自反 + 传递。
    le(2, 3),                                 % {1} ≤ {0,1}
    \+ le(7, 3),                              % U ≰ {0,1}
    forall(ipos(C), le(C, C)),
    forall((ipos(C), ipos(D), ipos(E), le(C, D), le(D, E)), le(C, E)),
    % 超滤子四公理。
    ultra(a1), ultra(a2),
    % 稠密集全相遇（泛型性）。
    all_ipos(IP),
    findall(D, (sub_ipos(IP, D), D \= [], dense(D)), Ds),
    Ds \= [],
    forall((member(A, [a1, a2]), member(D, Ds)), meets(A, D)),
    % 有限 Łoś 样本：{a | f < g} = {1}——G(1) 下为真、G(2) 下为假。
    truth_lt(f, g, M), M == 2,
    gmem(a1, M), \+ gmem(a2, M),
    % 引理 2.29 影子：{a | Id a = 1} = {1} ∈ G(1)。
    gmem(a1, 2),
    % 下降链：最长严格链 2 级。
    findall(L, (desc_chain(Ch), length(Ch, L)), Ls),
    max_list(Ls, Max), Max == 2,
    format("序正反+自反传递；超滤子四公理；稠密集全相遇；Łoś 样本双向；下降链至多 2 级~n"),
    writeln("END ====").
