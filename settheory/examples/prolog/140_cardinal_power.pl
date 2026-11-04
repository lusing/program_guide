:- encoding(utf8).
% 第 140 章 Prolog：基数幂的有限终审与 König 影子。
% ① 有限幂 2^n 与 n^k 的全枚举（函数集合 A^B 的显式计数）；
% ② κ^n = κ 的有限反例审计（n^n ≠ n）；
% ③ König 影子：cf(2^n) 后继=1 的有限同构。

% ① A^B 的显式枚举：B 到 A 的全部函数（值元组）

pow_count(A, B, C) :- C is A ^ B.

check_finite_pow :-
    forall((between(1, 4, A), between(0, 3, B)),
           ( pow_count(A, B, P1),
             findall(F, funcs(B, A, F), Fs),
             length(Fs, P2),
             P1 == P2 )),                              % 枚举数 = 算术幂
    format("finite powers: |A^B| = |A|^|B| by explicit enumeration: OK~n").

funcs(0, _, []).
funcs(N, A, [H|T]) :- N > 0, N1 is N - 1,
    A1 is A - 1, between(0, A1, H), funcs(N1, A, T).   % A1 先算再 between

% ② 无穷审计的有限反照：n·n ≠ n，n^n ≠ n（吸收的专利）
check_no_absorb :-
    forall(between(2, 5, N), (N * N =\= N, P is N ^ N, P =\= N)),
    format("finite contrast: n*n =/= n and n^n =/= n: OK~n").

% ③ 2^n 恒为后继序数（cf=1 的窗口影子；König 约束的无穷侧无法有限审计）
check_koenig_shadow :-
    forall(between(1, 6, N),
           (P is 2 ^ N, P > 0, succ(PM1, P))),
    format("koenig shadow: 2^n is always a successor (finite side): OK~n").

main :-
    format("==== 140 cardpow~n"),
    check_finite_pow,
    check_no_absorb,
    check_koenig_shadow,
    format("END ====~n"), !.

:- initialization(main).
