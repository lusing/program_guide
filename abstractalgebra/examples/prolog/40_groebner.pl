:- encoding(utf8).
% 第 40 章 · 格罗布纳基 —— Prolog 通道
%
% S-多项式 + Buchberger 判据/算法（整数系数、首项首一）+ 成员判定 + 消元。
% 多项式机器与第 39 章同构。

% ---------- 多项式机器 ----------
p_add(P, Q, R) :- append(P, Q, PQ), merge_terms(PQ, R).
merge_terms(Ts, R) :- sort(1, @=<, Ts, Ss), combine_runs(Ss, R).
combine_runs([], []) :- !.
combine_runs([_-0|Rest], Out) :- !, combine_runs(Rest, Out).
combine_runs([E1-C1, E2-C2|Rest], Out) :-
    E1 == E2, !,
    C is C1 + C2,
    combine_runs([E1-C|Rest], Out).
combine_runs([T|Rest], [T|Out]) :- combine_runs(Rest, Out).

scale_term(_, _, _, 0, []) :- !.
scale_term(P, DI, DJ, C, R) :-
    maplist([I-J-Ci, I2-J2-C2]>>(
                I2 is I + DI, J2 is J + DJ, C2 is Ci * C),
            P, R).

p_mul(P, Q, R) :-
    findall(Term,
            (member(I-J-C1, P), member(DI-DJ-C2, Q),
             C is C1 * C2, C =\= 0,
             I2 is I + DI, J2 is J + DJ,
             Term = I2-J2-C),
            Ts),
    merge_terms(Ts, R).

lex_lt(E1, E2) :- E1 @< E2.
leading(P, E-C) :-
    member(E-C, P),
    \+ (member(E2-_, P), E2 \= E, lex_lt(E, E2)).

div_(F, Gs, R) :- div_loop(F, Gs, [], R).
div_loop([], _, R, R) :- !.
div_loop(F0, Gs, R0, R) :-
    (   try_reduce(F0, Gs, F1)
    ->  div_loop(F1, Gs, R0, R)
    ;   leading(F0, E-C),
        p_add(R0, [E-C], R1),
        p_add(F0, [E-(-C)], F1),
        div_loop(F1, Gs, R1, R)
    ).
try_reduce(F0, Gs, F1) :-
    member(G, Gs),
    leading(G, GE-GC),
    leading(F0, FE-FC),
    FE = FI-FJ, GE = GI-GJ,
    FI >= GI, FJ >= GJ,
    FC mod GC =:= 0,
    Q is -FC // GC,
    DI is FI - GI, DJ is FJ - GJ,
    scale_term(G, DI, DJ, Q, Scaled),
    p_add(F0, Scaled, F1).

% ---------- S-多项式与 Buchberger ----------
% S(f, g) = lc(g)·(L/lt f)·f − lc(f)·(L/lt g)·g（整系数交叉乘，
% 与标准定义差一个单位倍，余式是否为零等价）
spoly(F, G, S) :-
    leading(F, FE-FC), leading(G, GE-GC),
    FE = FI-FJ, GE = GI-GJ,
    LI is max(FI, GI), LJ is max(FJ, GJ),
    scale_term(F, LI-FI, LJ-FJ, GC, SF),
    scale_term(G, LI-GI, LJ-GJ, -FC, SG),
    p_add(SF, SG, S).

is_groebner(Gs) :-
    \+ (pairs_member(G1, G2, Gs),
        spoly(G1, G2, S0),
        p_add(S0, [], S),
        S \= [],
        div_(S, Gs, R),
        R \= []).

pairs_member(G1, G2, Gs) :-
    member(G1, Gs), member(G2, Gs), G1 \= G2,
    G1 @< G2.

buchberger(Gs0, Gs) :-
    append(Gs0, [], G1),
    buch_loop(G1, Gs).

buch_loop(Gs, GsOut) :-
    (   pairs_member(A, B, Gs),
        spoly(A, B, S0), p_add(S0, [], S), S \= [],
        div_(S, Gs, R), R \= [],
        normalize_sign(R, RN),
        \+ member_same(RN, Gs)
    ->  append(Gs, [RN], Gs2),
        buch_loop(Gs2, GsOut)
    ;   GsOut = Gs
    ).

% 首项系数为负则整体变号（交叉乘 S-多项式的单位倍归一）
normalize_sign([], []) :- !.
normalize_sign(P, PN) :-
    leading(P, _-C),
    (   C < 0
    ->  maplist([E-Ci, E-C2]>>(C2 is -Ci), P, PN)
    ;   PN = P
    ).

member_same(R, [G|_]) :- sort(R, Rs), sort(G, Gs), Rs == Gs, !.
member_same(R, [_|T]) :- member_same(R, T).

main :-
    format("==== 40 格罗布纳基~n"),

    % S(x²+1, xy−1) = x+y；mod 原基余式非零 ⟹ 非 Grobner 基
    H1 = [2-0-1, 0-0-1],
    H2 = [1-1-1, 0-0-(-1)],
    spoly(H1, H2, S),
    sort(S, [0-1-1, 1-0-1]),
    div_(S, [H1, H2], R0),
    sort(R0, [0-1-1, 1-0-1]),
    \+ is_groebner([H1, H2]),
    format("S-多项式：S(x²+1, xy−1) = x+y，余式非零 ⟹ 非基 ✓~n"),

    % Buchberger：补入 S-余式直到判据通过
    buchberger([H1, H2], GB),
    is_groebner(GB),
    % x+y（或其倍形）在基中
    member_contains(GB, [0-1-1, 1-0-1]),
    format("Buchberger：{x²+1, xy−1} 扩成 Grobner 基（判据全过）✓~n"),

    % 成员判定（推论 7.63）：xy²−x ∈ (xy+1, y²−1)；x ∉
    K1 = [1-1-1, 0-0-1],
    K2 = [0-2-1, 0-0-(-1)],
    buchberger([K1, K2], GBe),
    is_groebner(GBe),
    div_([1-2-1, 1-0-(-1)], GBe, []),
    div_([1-0-1], GBe, Rx),
    Rx \= [],
    format("成员判定：xy²−x ∈（余式 0）；x ∉（余式非零）✓~n"),

    % 消元：{x²+y²−1, x−y} 的基含纯 y 多项式 2y²−1
    P1 = [2-0-1, 0-2-1, 0-0-(-1)],
    P2 = [1-0-1, 0-1-(-1)],
    buchberger([P1, P2], GBs),
    member_contains(GBs, [0-2-2, 0-0-(-1)]),
    format("消元：基含 2y²−1 ⟹ y = ±1/√2、x = y ✓~n"),

    format("END ====~n").

member_contains(GB, Target) :-
    member(G, GB),
    sort(G, Gs), sort(Target, Ts),
    Gs == Ts.
