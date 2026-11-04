:- encoding(utf8).
% 第 32 章 · 西罗定理 —— Prolog 通道
%
% 闭包枚举子群 → 西罗计数两条件 + 30/40/56 非单性算术 + UT(3,F_p)。

% ---------- 置换基础设施 ----------
compose(Sigma, Tau, Rho) :- compose_at(Tau, Sigma, Rho).
compose_at([], _, []).
compose_at([T|Ts], Sigma, [R|Rs]) :- nth1(T, Sigma, R), compose_at(Ts, Sigma, Rs).

perm_id(N, Id) :- numlist(1, N, Id).

% 闭包（排序去重，比较到不动点）
close_set(S0, S) :-
    findall(P, (member(A, S0), member(B, S0), compose(A, B, P)), Ps),
    append(S0, Ps, C0), sort(C0, S1),
    (S1 == S0 -> S = S0 ; close_set(S1, S)).

group_of(N, Gens, G) :-
    perm_id(N, Id),
    append(Gens, [Id], Seed),
    close_set(Seed, G).

% 全部子群：单点与点对的闭包（小群中每个子群 ≤ 2 生成）
subgroups(G, Subs) :-
    findall(H, (member(A, G), closure01(G, A, H)), Hs),
    sort(Hs, Subs).
closure01(_, A, H) :- close_set([A], H).
closure01(G, A, H) :-
    member(B, G), A @< B,
    close_set([A, B], H).

% ---------- 西罗计数 ----------
pm_split(N, P, E, M) :- pm_split_(N, P, 0, E, M).
pm_split_(N, P, A, E, M) :-
    (   N mod P =:= 0
    ->  N1 is N // P, A1 is A + 1, pm_split_(N1, P, A1, E, M)
    ;   E = A, M = N
    ).

sylow_count(G, Order, P, Count) :-
    pm_split(Order, P, E, M),
    Target is P ^ E,
    subgroups(G, Subs),
    include([H]>>(length(H, Target)), Subs, Syl),
    length(Syl, Count),
    Count mod P =:= 1,          % 定理 6.19：n_p ≡ 1 (mod p)
    M mod Count =:= 0.          % 定理 6.19：n_p | m

% ---------- UT(3, F_p)：元组群 ----------
ut_mul((A,B,C), (D,E,F), P, (X,Y,Z)) :-
    X is (A + D) mod P,
    Y is (B + E) mod P,
    Z is (C + F + A*E) mod P.

ut_group(P, Elems) :-
    P1 is P - 1,
    findall((A,B,C),
            (between(0, P1, A), between(0, P1, B), between(0, P1, C)),
            Elems),
    % 乘法封闭
    forall((member(X, Elems), member(Y, Elems)),
           (ut_mul(X, Y, P, Z), member(Z, Elems))).

ut_order(X, P, N) :- ut_step(X, X, 1, P, N).
ut_step(_, (0,0,0), K, _, K) :- !.
ut_step(X, Y, K0, P, N) :-
    ut_mul(Y, X, P, Y1),
    K1 is K0 + 1,
    ut_step(X, Y1, K1, P, N).

% ---------- 主流程 ----------
main :-
    format("==== 32 西罗定理~n"),

    % S₃（3 点置换）
    group_of(3, [[2,1,3], [2,3,1]], S3),
    length(S3, 6),
    sylow_count(S3, 6, 2, 3),
    sylow_count(S3, 6, 3, 1),
    format("S₃：n₂ = 3 ≡ 1 (mod 2) 且 | 3；n₃ = 1 ✓~n"),

    % A₄ = ⟨(12)(34), (123)⟩
    group_of(4, [[2,1,4,3], [2,3,1,4]], A4),
    length(A4, 12),
    sylow_count(A4, 12, 2, 1),
    sylow_count(A4, 12, 3, 4),
    format("A₄：n₂ = 1（V₄ 正规）；n₃ = 4 ≡ 1 (mod 3) 且 | 4 ✓~n"),

    % D₄ = ⟨(1234), (12)(34)⟩：2-群
    group_of(4, [[2,3,4,1], [2,1,4,3]], D4),
    length(D4, 8),
    sylow_count(D4, 8, 2, 1),
    format("D₄：8 = 2³，整群即唯一西罗 2-子群 ✓~n"),

    % S₄
    group_of(4, [[2,1,3,4], [2,3,4,1]], S4),
    length(S4, 24),
    sylow_count(S4, 24, 2, 3),
    sylow_count(S4, 24, 3, 4),
    format("S₄：n₂ = 3 ≡ 1 (mod 2) 且 | 3；n₃ = 4 ≡ 1 (mod 3) 且 | 4 ✓~n"),

    % 30/40/56 非单性：候选枚举与元素计数
    findall(D, (between(1, 6, D), 6 mod D =:= 0, D mod 5 =:= 1), [1, 6]),
    findall(D, (between(1, 8, D), 8 mod D =:= 0, D mod 5 =:= 1), [1]),
    findall(D, (between(1, 8, D), 8 mod D =:= 0, D mod 7 =:= 1), [1, 8]),
    6*4 + 10*2 =:= 44, 44 > 29,
    8*6 + 1 + 7 =:= 56, 8*6 + 1 + 8 > 56,
    format("非单性：30（44 > 29）、40（n₅ = 1）、56（56 封顶再超）✓~n"),

    % UT(3, F₂)：阶谱与 D₄ 相同
    ut_group(2, UT2),
    length(UT2, 8),
    ut_order((1,0,0), 2, 2),
    ut_order((1,1,0), 2, 4),
    findall(O, (member(X, UT2), ut_order(X, 2, O)), Os0),
    msort(Os0, [1,2,2,2,2,2,4,4]),
    format("UT(3,F₂)：阶谱 {1,2⁵,4²} 与 D₄ 相同（≅ D₄）✓~n"),

    % UT(3, F₃)：阶谱同 (ℤ/3)³ 但非阿贝尔
    ut_group(3, UT3),
    length(UT3, 27),
    forall(member(X, UT3), (ut_order(X, 3, O), (O = 1 ; O = 3))),
    ut_mul((1,0,0), (0,1,0), 3, Z1), ut_mul((0,1,0), (1,0,0), 3, Z2),
    Z1 \= Z2,
    format("UT(3,F₃)：全部元素 ≤ 3 阶 = (ℤ/3)³ 的阶谱，但群非阿贝尔 ✓~n"),

    % |GL|（定理 6.30）
    GL22 is (2^2-1)*(2^2-2), GL22 =:= 6,
    GL32 is (2^3-1)*(2^3-2)*(2^3-4), GL32 =:= 168,
    168 =:= 21 * 8,
    format("|GL(2,F₂)| = 6、|GL(3,F₂)| = 168 = 21·8（UT(3,F₂) 是西罗 2-子群）✓~n"),

    format("END ====~n").
