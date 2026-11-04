:- encoding(utf8).
% 第 16 章 · 域与分式域 —— Prolog 通道
%
% 序对分式构造 + 等价关系传递性爆破实验（ℤ/6ℤ）。

gcd_abs(0, B, G) :- !, G is abs(B).
gcd_abs(A, 0, G) :- !, G is abs(A).
gcd_abs(A, B, G) :- A1 is abs(A), B1 is abs(B),
    (B1 =:= 0 -> G = A1 ; R is A1 mod B1, gcd_abs(B1, R, G)).

frac_norm(A, B, N, D) :-
    B =\= 0,
    gcd_abs(A, B, G),
    (B < 0 -> S1 = -1 ; S1 = 1),
    N is S1 * A // G,
    D is S1 * B // G.

frac_add(A-B, C-D, N, Dd) :- N is A * D + C * B, Dd is B * D.
frac_mul(A-B, C-D, N, Dd) :- N is A * C, Dd is B * D.

frac_equiv_p(P, A, B, C, D) :- AD is A * D, BC is B * C,
    (AD - BC) mod P =:= 0.

% 传递性爆破搜索（全部变量显式枚举）
transitivity_witness(P, W) :-
    Pm is P - 1,
    between(0, Pm, A), between(1, Pm, B),
    between(0, Pm, C), between(1, Pm, D),
    between(0, Pm, E), between(1, Pm, F),
    frac_equiv_p(P, A, B, C, D),
    frac_equiv_p(P, C, D, E, F),
    \+ frac_equiv_p(P, A, B, E, F),
    !,
    W = (A/B, C/D, E/F).

% 等价关系三公理（全部变量显式枚举）
equiv_relation(P) :-
    Pm is P - 1,
    forall(between(0, Pm, X), frac_equiv_p(P, X, 1, X, 1)),
    forall((between(0, Pm, A), between(1, Pm, B),
            between(0, Pm, C), between(1, Pm, D),
            frac_equiv_p(P, A, B, C, D)),
           frac_equiv_p(P, C, D, A, B)),
    forall((between(0, Pm, A), between(1, Pm, B),
            between(0, Pm, C), between(1, Pm, D),
            between(0, Pm, E), between(1, Pm, F),
            frac_equiv_p(P, A, B, C, D),
            frac_equiv_p(P, C, D, E, F)),
           frac_equiv_p(P, A, B, E, F)).

main :-
    format("==== 16 域与分式域~n"),

    frac_add(1-2, 1-3, N1, D1), gcd_abs(N1, D1, 1),
    N1 = 5, D1 = 6,
    frac_mul(1-2, 1-3, N2, D2), N2 = 1, D2 = 6,
    frac_norm(2, 6, N3, D3), N3 = 1, D3 = 3,
    format("ℤ 分式：1/2+1/3 = 5/6；1/2·1/3 = 1/6；(2,6)→(1,3) ✓~n"),

    forall(member(P, [5, 7, 11]), equiv_relation(P)),
    format("素数模（5,7,11）：分式等价关系三公理全过 ✓~n"),

    transitivity_witness(6, W),
    format("良定义性爆破：ℤ/6ℤ 上传递性反例 ~w ✓~n", [W]),

    format("END ====~n").
