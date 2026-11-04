:- encoding(utf8).
% 第 28 章 · 特征值 —— Prolog 通道
%
% GF(3) 上 2×2 矩阵的谱枚举（伴随式/特征值穷举）。

charpoly2(A, B, C, D, NegTr, Det) :-
    NegTr is -(A + D),
    Det is A * D - B * C.

% 特征值：二次 x² + NegTr·x + Det 的根（GF(p) 穷举）
eigen2_p(P, A, B, C, D, Lam) :-
    charpoly2(A, B, C, D, NegTr, Det),
    Pm is P - 1, between(0, Pm, L0), Lam is L0 mod P,
    V is (Lam * Lam + NegTr * Lam + Det) mod P, V =:= 0.

disc(A, B, C, D, Disc) :-
    charpoly2(A, B, C, D, NegTr, Det),
    Disc is NegTr * NegTr - 4 * Det.

is_square_mod3(0).
is_square_mod3(1).

main :-
    format("==== 28 特征值~n"),

    % [[2,1],[1,2]] 在 GF(3)：p(x) = x² − 4x + 3 ≡ x² + 2x（mod 3）
    charpoly2(2, 1, 1, 2, NegTr, Det),
    NegTr =:= -4, Det =:= 3,

    % GF(3) 全谱枚举
    findall([A,B,C,D]-Lams,
            (between(0, 2, A), between(0, 2, B), between(0, 2, C), between(0, 2, D),
             findall(L, eigen2_p(3, A, B, C, D, L), Ls0),
             sort(Ls0, Lams),
             Lams \= []),
            WithEig),
    length(WithEig, NE), NE == 63,      % 81 − 18（判别式非平方的 18 个）
    format("GF(3) 全谱：81 个 2×2 中 63 个在 GF(3) 有特征值 ✓~n"),

    % 无谱矩阵：判别式为 2（非平方）的全部 18 个
    findall([A,B,C,D],
            (between(0, 2, A), between(0, 2, B), between(0, 2, C), between(0, 2, D),
             \+ eigen2_p(3, A, B, C, D, _)), NoEig),
    length(NoEig, 18),
    format("谱迁移：18 个矩阵的特征多项式在 GF(3) 无根（谱住 GF(9)）✓~n"),

    % [[0,1],[1,1]] 在 GF(2)：x²+x+1 无根、B³ = I
    charpoly2(0, 1, 1, 1, NT, DT),
    NT =:= -1, DT =:= -1,                 % x² − x − 1
    \+ eigen2_p(2, 0, 1, 1, 1, _),        % mod 2：x² + x + 1 无根
    matmul2(2, [0,1,1,1], [0,1,1,1], B2),
    matmul2(2, B2, [0,1,1,1], B3),
    B3 == [1, 0, 0, 1],                    % B³ = I
    format("GF(2)：[[0,1],[1,1]] 谱住 GF(4)，但 B³ = I（阶 3）✓~n"),

    format("END ====~n").

matmul2(P, [A,B,C,D], [E,F,G,H], M) :-
    X1 is (A*E + B*G) mod P, X2 is (A*F + B*H) mod P,
    X3 is (C*E + D*G) mod P, X4 is (C*F + D*H) mod P,
    M = [X1, X2, X3, X4].
