:- encoding(utf8).
% 第 38 章 · 广义的除法算式 —— Prolog 通道
%
% 单项式序（lex/grlex）+ 多元除法（整数系数、首项皆首一）+ 顺序依赖例。

% 多项式 = (I-J)-C 对表
p_add(P, Q, R) :-
    append(P, Q, PQ),
    merge_terms(PQ, R).

merge_terms(Ts, R) :-
    sort(1, @=<, Ts, Ss),
    combine_runs(Ss, R).

combine_runs([], []) :- !.
combine_runs([_-0|Rest], Out) :- !, combine_runs(Rest, Out).
combine_runs([E1-C1, E2-C2|Rest], Out) :-
    E1 == E2, !,
    C is C1 + C2,
    combine_runs([E1-C|Rest], Out).
combine_runs([T|Rest], [T|Out]) :-
    combine_runs(Rest, Out).

% 项乘单项式 x^DI y^DJ * C
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

% ---------- 单项式序 ----------
lex_lt(E1, E2) :- E1 @< E2.                    % 字典序（先比首坐标）

grlex_lt(E1, E2) :-
    E1 = I1-J1, E2 = I2-J2,
    S1 is I1 + J1, S2 is I2 + J2,
    (   S1 < S2 -> true
    ;   S1 > S2 -> fail
    ;   E1 @< E2
    ).

% 首项（序下最大；P 的元素是 (I-J)-C 对）
leading(P, E-C, Ord) :-
    member(E-C, P),
    \+ (member(E2-_, P), E2 \= E, ord_gt(E2, E, Ord)).

ord_gt(E1, E2, lex) :- lex_lt(E2, E1).
ord_gt(E1, E2, grlex) :- grlex_lt(E2, E1).

% ---------- 多元除法（定理 7.60，整数版） ----------
divide(F, Gs, Ord, R) :-
    div_loop(F, Gs, Ord, [], R).

div_loop([], _, _, R, R) :- !.
div_loop(F0, Gs, Ord, R0, R) :-
    (   try_reduce(F0, Gs, Ord, F1)
    ->  div_loop(F1, Gs, Ord, R0, R)
    ;   leading(F0, E-C, Ord),
        p_add(R0, [E-C], R1),
        p_add(F0, [E-(-C)], F1),
        div_loop(F1, Gs, Ord, R1, R)
    ).

try_reduce(F0, Gs, Ord, F1) :-
    member(G, Gs),
    leading(G, GE-GC, Ord),
    leading(F0, FE-FC, Ord),
    FE = FI-FJ, GE = GI-GJ,
    FI >= GI, FJ >= GJ,
    FC mod GC =:= 0,
    Q is -FC // GC,
    DI is FI - GI, DJ is FJ - GJ,
    scale_term(G, DI, DJ, Q, Scaled),
    p_add(F0, Scaled, F1).

main :-
    format("==== 38 广义的除法算式~n"),

    % 序个例：lex 中 x > y²（首坐标优先）；grlex 中 y² > x（总次优先）
    \+ lex_lt(1-0, 0-2),
    grlex_lt(1-0, 0-2),
    \+ grlex_lt(0-2, 1-0),
    format("序个例：lex 中 x > y²；grlex 中 y²（总次 2）> x（总次 1）✓~n"),

    % 除法例：f = x²y+xy²+y² 除 [xy−1, y²−1]（lex）余 x+y+1
    F = [2-1-1, 1-2-1, 0-2-1],
    G1 = [1-1-1, 0-0-(-1)],
    G2 = [0-2-1, 0-0-(-1)],
    divide(F, [G1, G2], lex, R),
    sort(R, [0-0-1, 0-1-1, 1-0-1]),
    format("多元除法：f mod [xy−1, y²−1] 余式 x+y+1（lex，整数系数）✓~n"),

    % 顺序依赖：xy² − x 除 [xy+1, y²−1] 得 −x−y；换序得 0
    H = [1-2-1, 1-0-(-1)],
    K1 = [1-1-1, 0-0-1],
    K2 = [0-2-1, 0-0-(-1)],
    divide(H, [K1, K2], lex, R1),
    sort(R1, [0-1-(-1), 1-0-(-1)]),
    divide(H, [K2, K1], lex, R2),
    R2 = [],
    format("顺序依赖：−x−y vs 0——余式不是理想成员判据（Grobner 动机）✓~n"),

    format("END ====~n").
