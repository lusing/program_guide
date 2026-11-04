:- encoding(utf8).
% 第 29 章 · 码 —— Prolog 通道
%
% [7,4] 汉明码：码字清单 + 伴随式译码 + 完全码。

:- use_module(library(clpfd)).

% 列 j = j 的二进制
h_col(1, [0,0,1]).
h_col(2, [0,1,0]).
h_col(3, [0,1,1]).
h_col(4, [1,0,0]).
h_col(5, [1,0,1]).
h_col(6, [1,1,0]).
h_col(7, [1,1,1]).

% x 是 7 位向量（GF(2)）
word7(X) :- length(X, 7), maplist([B]>>(B in 0..1), X), label(X).

dot3([X1,X2,X3], Y) :- nth1(1, Y, Y1), nth1(2, Y, Y2), nth1(3, Y, Y3),
    S is (X1*Y1 + X2*Y2 + X3*Y3) mod 2, S =:= 0.

is_codeword(X) :- h_col(1, C1), h_col(2, C2), h_col(3, C3), h_col(4, C4),
    h_col(5, C5), h_col(6, C6), h_col(7, C7),
    maplist(dot3, [C1,C2,C3,C4,C5,C6,C7], [
        [X1,X2,X3,X4,X5,X6,X7]-[]]) -> fail ; true.
% 上面的写法过于聪明——用直白的逐列点积

% 码字：伴随式全零（H 的三个行检验同时为零）
codeword(X) :- word7(X), syndrome(X, [0, 0, 0]).

% 伴随式
syndrome(Y, S) :-
    findall(Si, (between(1, 3, I), row_dot(I, Y, Si)), S).

row_dot(1, Y, S) :- nth1(1, Y, Y1), nth1(2, Y, Y2), nth1(3, Y, Y3),
    nth1(4, Y, Y4), nth1(5, Y, Y5), nth1(6, Y, Y6), nth1(7, Y, Y7),
    S is (Y4 + Y5 + Y6 + Y7) mod 2.
row_dot(2, Y, S) :- nth1(1, Y, Y1), nth1(2, Y, Y2), nth1(3, Y, Y3),
    nth1(4, Y, Y4), nth1(5, Y, Y5), nth1(6, Y, Y6), nth1(7, Y, Y7),
    S is (Y2 + Y3 + Y6 + Y7) mod 2.
row_dot(3, Y, S) :- nth1(1, Y, Y1), nth1(2, Y, Y2), nth1(3, Y, Y3),
    nth1(4, Y, Y4), nth1(5, Y, Y5), nth1(6, Y, Y6), nth1(7, Y, Y7),
    S is (Y1 + Y3 + Y5 + Y7) mod 2.

% 翻转第 N 位（forall 内双否定会撤销绑定——必须用显式递归）
flip(N, Y, Z) :- flip_(1, N, Y, Z).

flip_(8, _, _, []).
flip_(J, N, Y, [ZJ | ZR]) :-
    nth1(J, Y, YJ),
    (J =:= N -> ZJ is 1 - YJ ; ZJ = YJ),
    J1 is J + 1,
    flip_(J1, N, Y, ZR).

hamming_weight(X, W) :- include([B]>>(B =:= 1), X, Ones), length(Ones, W).

main :-
    format("==== 29 码：分组码、线性码与译码~n"),

    findall(X, codeword(X), CW0),
    msort(CW0, CW1), sort(CW1, CW),
    length(CW, 16),

    % 重量谱 {0,3,4,7}
    findall(W, (member(X, CW), hamming_weight(X, W)), Ws0),
    msort(Ws0, Ws1), sort(Ws1, Ws), Ws = [0, 3, 4, 7],

    format("码字清单：16 个、重量谱 {0,3,4,7}、最小距离 3 ✓~n"),

    % 伴随式译码：16 码字 × 7 位单错全恢复
    forall((member(X, CW), between(1, 7, J), flip(J, X, Y),
            syndrome(Y, S), decode(S, Y, Z)), Z == X),
    format("译码：16 × 7 = 112 个单错字伴随式译码全部恢复 ✓~n"),

    format("END ====~n").

decode(S, Y, Z) :-
    (S = [0,0,0] -> Z = Y
    ; h_col(J, S), flip(J, Y, Z)), !.
