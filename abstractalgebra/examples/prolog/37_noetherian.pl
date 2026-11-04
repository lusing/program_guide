:- encoding(utf8).
% 第 37 章 · 诺特环 —— Prolog 通道
%
% 单项式理想上闭包 + 升链稳定（Dickson）+ 极小生成集 + ℤ/n 理想格。

% 上闭包：窗口 [0,Bound]² 内由生成单项式生成的单项式理想
mon_closure(Gens, Bound, S) :-
    mc_grow(Gens, Bound, [], S).

mc_grow([], _, S0, S) :- !, sort(S0, S).
mc_grow([[A, B]|Rest], Bound, Seen, S) :-
    (   member([A, B], Seen)
    ->  mc_grow(Rest, Bound, Seen, S)
    ;   ( A > Bound ; B > Bound )
    ->  mc_grow(Rest, Bound, Seen, S)
    ;   A1 is A + 1, B1 is B + 1,
        (   A1 =< Bound -> RestA = [[A1, B]|Rest] ; RestA = Rest ),
        (   B1 =< Bound -> RestB = [[A, B1]|RestA] ; RestB = RestA ),
        mc_grow(RestB, Bound, [[A, B]|Seen], S)
    ).

% 极小生成集：不被其他成员（坐标 ≤）支配
minimal_gens(S, M) :-
    include([E]>>(\+ (member(F, S), F \= E,
                      coord_le(F, E))),
             S, M).

% 坐标 ≤（列表逐位）
coord_le(F, E) :-
    nth0(0, F, F0), nth0(1, F, F1),
    nth0(0, E, E0), nth0(1, E, E1),
    F0 =< E0, F1 =< E1.

main :-
    format("==== 37 诺特环~n"),

    % 升链稳定：累计链 {(2,1)} ⊂ {(2,1),(1,3)} ⊂ {(2,1),(1,3),(1,2)}
    % ⊂ {(2,1),(1,3),(1,2),(2,2)}——最后一步 (2,2) ≥ (2,1) 被支配，理想不动
    mon_closure([[2,1]], 8, C1),
    mon_closure([[2,1],[1,3]], 8, C2),
    mon_closure([[2,1],[1,3],[1,2]], 8, C3),
    mon_closure([[2,1],[1,3],[1,2],[2,2]], 8, C4),
    C3 = C4,
    \+ (C1 = C2), \+ (C2 = C3),
    subset2(C1, C2), subset2(C2, C3), subset2(C3, C4),
    format("Dickson：累计链严格递增三步后被支配生成元封顶（升链稳定）✓~n"),

    % 极小生成：上闭包的极小元重新生成同一理想
    mon_closure([[2,0],[0,3],[1,1]], 8, S1),
    minimal_gens(S1, M1),
    sort(M1, [[0,3],[1,1],[2,0]]),
    mon_closure(M1, 8, S1b),
    S1 = S1b,
    format("极小生成：{(0,3),(1,1),(2,0)} 重新生成同一理想 ✓~n"),

    % (x², xy, y²)：恰为总次数 ≥ 2 的单项式全体
    mon_closure([[2,0],[1,1],[0,2]], 5, S2),
    forall(member([A,B], S2), A + B >= 2),
    forall((between(0, 5, A), between(0, 5, B), A + B >= 2),
            member([A, B], S2)),
    format("(x²,xy,y²) = 全部次数 ≥ 2 单项式（有限生成的典例）✓~n"),

    % ℤ/n 理想格有限 ⟹ ACC（推论 7.28 的数值面）
    findall(D, (between(1, 12, D), 12 mod D =:= 0), [1,2,3,4,6,12]),
    format("ℤ/12 理想格 = {1,2,3,4,6,12}（有限 ⟹ 诺特）✓~n"),

    format("END ====~n").

% 子集（项级）
subset2([], _).
subset2([H|T], S) :- member(H, S), subset2(T, S).
