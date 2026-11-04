:- encoding(utf8).
% 第 15 章 · 交换环的基本性质 —— Prolog 通道
%
% ℤ_m 加乘双表驱动：环公理 + 整环/域判定 + 零因子谱。

% ---------- 表驱动运算 ----------
elem(zm(M), X) :- between(0, M, X0), X is X0 mod M.
addp(zm(M), X, Y, Z) :- Z is (X + Y) mod M.
mulp(zm(M), X, Y, Z) :- Z is (X * Y) mod M.

% ---------- 环公理（加法交换群 + 乘法结合 + 分配） ----------
ring_axioms(R) :-
    % 分配律：x(y+z) = xy + xz
    forall((elem(R, X), elem(R, Y), elem(R, Z)),
           (addp(R, Y, Z, YZ), mulp(R, X, YZ, L),
            mulp(R, X, Y, XY), mulp(R, X, Z, XZ), addp(R, XY, XZ, Rs),
            L == Rs)),
    % 乘法结合律
    forall((elem(R, X), elem(R, Y), elem(R, Z)),
           (mulp(R, X, Y, XY), mulp(R, XY, Z, L),
            mulp(R, Y, Z, YZ), mulp(R, X, YZ, Rs),
            L == Rs)),
    % 乘法交换律
    forall((elem(R, X), elem(R, Y)),
           (mulp(R, X, Y, A), mulp(R, Y, X, B), A == B)).

% ---------- 整环 / 域 ----------
zero_divisor(R, A) :-
    elem(R, A), A \= 0,
    elem(R, B), B \= 0,
    mulp(R, A, B, 0).

domain(R) :- \+ zero_divisor(R, _).

invertible(R, A) :- elem(R, A), A \= 0,
    elem(R, B), mulp(R, A, B, 1).

field(R) :-
    domain(R),
    forall((elem(R, A), A \= 0), invertible(R, A)).

main :-
    format("==== 15 交换环的基本性质~n"),

    forall(member(M, [5, 7, 11]),
           (ring_axioms(zm(M)), domain(zm(M)), field(zm(M)))),
    format("ℤ₅、ℤ₇、ℤ₁₁：环公理 + 整环 + 域 ✓~n"),

    % 零因子谱
    findall(A, zero_divisor(zm(6), A), Z6), sort(Z6, [2, 3, 4]),
    findall(A, zero_divisor(zm(8), A), Z8), sort(Z8, [2, 4, 6]),
    format("零因子谱：ℤ₆ = {2,3,4}；ℤ₈ = {2,4,6} ✓~n"),

    % 命题 3.15：m = 2..16
    forall(between(2, 16, M),
           ((field(zm(M)) -> Fld = true ; Fld = false),
            (prime_m(M) -> Prm = true ; Prm = false),
            Fld == Prm)),
    format("命题 3.15：m = 2..16，ℤ_m 域 ⟺ 素数 ✓~n"),

    % ℤ₆ 零因子现场：3·4 = 0
    mulp(zm(6), 3, 4, 0),
    format("ℤ₆ 现场：3·4 = 0（mod 6）✓~n"),

    format("END ====~n").

prime_m(M) :- M >= 2, \+ (between(2, M, D), D * D =< M, M mod D =:= 0).
