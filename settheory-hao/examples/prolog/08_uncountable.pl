:- encoding(utf8).
% 第 08 章 Prolog：对角线法的有限终审。
% ① n×n 的 0-1 矩阵（n=3，共 512 个）：翻转对角线得到的行
%    与矩阵的每一行都不同——对角线论证的全量审计；
% ② 康托定理的有限版：{0,1,2} → P({0,1,2}) 的全部 512 个函数，
%    对角集 D = {x | x ∉ f(x)} 都不在值域内。

% ---------- ① 矩阵对角线 ----------
bits_row(0, []).
bits_row(N, [B|T]) :- N > 0, N1 is N - 1, between(0, 1, B), bits_row(N1, T).

matrix(0, _, []).
matrix(N, Width, [R|Rs]) :- N > 0, N1 is N - 1,
    bits_row(Width, R), matrix(N1, Width, Rs).

flip_diag(M, F) :-
    length(M, N),
    findall(B, (nth1(I, M, Row), nth1(I, Row, B0), B is 1 - B0), F).

differs_at(F, Row, I) :- nth1(I, F, FB), nth1(I, Row, RB), FB =\= RB.

check_diagonal :-
    forall((matrix(3, 3, M), flip_diag(M, F)),
           (forall(member(Row, M),
                   (nth1(I, Row, _), differs_at(F, Row, I))))),
    format("diagonal: flipped diagonal differs from all rows of every 3x3 matrix: OK~n").

% ---------- ② 康托有限版 ----------
subsets_of_3(S) :- between(0, 7, S).                  % 位掩码 0..7

f_triple(A, B, C, [A, B, C]).

diag_set([A, B, C], D) :-                             % D = {x | x ∉ f(x)}
    bit_if_out(A, 0, DA), bit_if_out(B, 1, DB), bit_if_out(C, 2, DC),
    D is DA + DB + DC.
bit_if_out(Mask, X, Bit) :- (Mask >> X) /\ 1 =:= 0, Bit is 1 << X, !.
bit_if_out(_, _, 0).

check_cantor :-
    forall((subsets_of_3(A), subsets_of_3(B), subsets_of_3(C),
            f_triple(A, B, C, F), diag_set(F, D)),
           (member(D, F) -> fail ; true)),
    format("cantor finite: diagonal set never in range, all 512 functions: OK~n").

main :-
    format("==== 08 uncountable~n"),
    check_diagonal,
    check_cantor,
    format("END ====~n"), !.

:- initialization(main).
