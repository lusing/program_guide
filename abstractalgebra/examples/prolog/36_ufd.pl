:- encoding(utf8).
% 第 36 章 · 唯一分解整环 —— Prolog 通道
%
% 分解重组 + gcd min-指数 + 高斯引理（内容乘积）+ ℤ[√−5] 反例。

% 试除分解（与第 32 章同构）
factorize(1, []) :- !.
factorize(N, Pf) :- N > 1, factorize_(N, 2, Pf).
factorize_(1, _, []).
factorize_(N, P, [P-E|Rest]) :-
    N mod P =:= 0, !,
    count_div(N, P, 0, E),
    PE is P ^ E,
    N1 is N // PE,
    P1 is P + 1,
    factorize_(N1, P1, Rest).
factorize_(N, P, Pf) :-
    N mod P =\= 0, !,
    P1 is P + 1,
    factorize_(N, P1, Pf).

count_div(N, P, A0, A) :-
    (   N mod P =:= 0
    ->  N1 is N // P, A1 is A0 + 1, count_div(N1, P, A1, A)
    ;   A = A0
    ).

% 重组
rebuild([], 1).
rebuild([P-E|Rest], N) :-
    rebuild(Rest, N0),
    N is N0 * P ^ E.

% gcd 经分解：min 指数
gcd_factor(A, B, G) :-
    factorize(A, Fa), factorize(B, Fb),
    findall(P-MinE,
            (member(P-Ea, Fa), member(P-Eb, Fb),
             MinE is min(Ea, Eb)),
            Common),
    rebuild(Common, G).

% 多项式乘法（系数表升幂）：收集 (位置, 乘积) 对再按位求和
poly_mul(A, B, C) :-
    length(A, LA), length(B, LB), LC is LA + LB - 1, LC >= 1,
    findall(K-V,
            (nth1(I, A, Ai), nth1(J, B, Bj),
             V0 is Ai * Bj, V0 =\= 0,
             K is I + J - 1, V = V0),
            Pairs),
    fill_coeffs(1, LC, Pairs, C).

fill_coeffs(I, LC, _, []) :- I > LC, !.
fill_coeffs(I, LC, Pairs, [C|Cs]) :-
    findall(V, member(I-V, Pairs), Vs),
    sum_list(Vs, C),
    I1 is I + 1,
    fill_coeffs(I1, LC, Pairs, Cs).

% 内容（系数 gcd）
gcd_(0, B, G) :- !, G = B.
gcd_(A, 0, G) :- !, G = A.
gcd_(A, B, G) :- C is A mod B, gcd_(B, C, G).
gcd2(A, B, G) :- AA is abs(A), BB is abs(B), gcd_(AA, BB, G).

content([], 0).
content([C], G) :- gcd2(C, 0, G).
content([C|Cs], G) :- content(Cs, G0), gcd2(C, G0, G).

% ℤ[√−5]：(a, b) 表示 a + b√−5；范数 a² + 5b²
nmul((A, B), (C, D), (X, Y)) :- X is A * C - 5 * B * D, Y is A * D + B * C.
norm((A, B), N) :- N is A * A + 5 * B * B.

% 整除：β/α 系数均为整数
divides_zw(Alpha, Beta) :-
    Alpha = (A, B), Beta = (C, D),
    Det is A * A + 5 * B * B,
    X is (A * C + 5 * B * D) / Det,
    Y is (A * D - B * C) / Det,
    integer_ratio(X), integer_ratio(Y).

integer_ratio(Q) :- abs(Q - round(Q)) < 1e-9.

main :-
    format("==== 36 唯一分解整环~n"),

    % 分解重组 2..200
    forall(between(2, 200, N),
           (factorize(N, F), rebuild(F, N))),
    factorize(360, [2-3, 3-2, 5-1]),
    format("ℤ 分解：360 = 2³·3²·5；2..200 重组还原 ✓~n"),

    % gcd = min 指数（1..40 对拍欧几里得）
    forall((between(1, 40, A), between(1, 40, B)),
           (gcd_factor(A, B, G), gcd2(A, B, G))),
    format("gcd min-指数 ⟺ 欧几里得（1..40 全对拍）✓~n"),

    % 高斯引理：content(fg) = content(f)·content(g)
    forall(member((F, G), [([2,4,6],[3,9]), ([4,6],[6,10]),
                           ([1,2,3],[5,7]), ([6,10,15],[4,14])]),
           (poly_mul(F, G, FG),
            content(F, CF), content(G, CG), content(FG, CFG),
            CFG =:= CF * CG)),
    format("高斯引理：content(fg) = content(f)·content(g) 四组核对 ✓~n"),

    % ℤ[√−5]：范数乘性 + 6 的两分解
    forall((between(-3, 3, A), between(-3, 3, B),
            between(-3, 3, C), between(-3, 3, D)),
           (nmul((A, B), (C, D), P), norm(P, NP),
            norm((A, B), NA), norm((C, D), NC), NP =:= NA * NC)),
    nmul((2, 0), (3, 0), (6, 0)),
    nmul((1, 1), (1, -1), (6, 0)),
    norm((2, 0), 4), norm((3, 0), 9), norm((1, 1), 6), norm((1, -1), 6),
    % 范数 2、3 无解（a²+5b² 表）
    \+ (between(0, 3, A), between(0, 1, B), norm((A, B), N2), (N2 = 2 ; N2 = 3)),
    % 2 不整除 1±√−5（但整除乘积）
    \+ divides_zw((2, 0), (1, 1)),
    \+ divides_zw((2, 0), (1, -1)),
    divides_zw((2, 0), (6, 0)),
    format("ℤ[√−5]：6 = 2·3 = (1±√−5)；范数无 2/3 ⟹ 四因子不可约；2 非素 ✓~n"),

    format("END ====~n").
