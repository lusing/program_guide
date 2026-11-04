:- encoding(utf8).
% 第 26 章 · 线性变换 —— Prolog 通道
%
% GF(2) 的 2×2 可逆矩阵群 GL(2,2) ≅ S₃。

mat2([A, B, C, D]) :- member(A, [0,1]), member(B, [0,1]),
                      member(C, [0,1]), member(D, [0,1]).

det2(M, Det) :- M = [A, B, C, D], Det is (A * D - B * C) mod 2.

gl22(M) :- mat2(M), det2(M, 1).

% 矩阵乘法（GF(2)）
mmul2([A,B,C,D], [E,F,G,H], M) :-
    X1 is (A*E + B*G) mod 2, X2 is (A*F + B*H) mod 2,
    X3 is (C*E + D*G) mod 2, X4 is (C*F + D*H) mod 2,
    M = [X1, X2, X3, X4].

% 矩阵作用在非零向量 {e1, e2, e1+e2} 上诱导 {1,2,3} 的置换
phi([A,B,C,D], Perm) :-
    findall(L, (member(W, [[1,0],[0,1],[1,1]]),
                wlabel([A,B,C,D], W, L)), Perm).

wlabel([A,B,C,D], [X,Y], L) :-
    Z1 is (A*X + B*Y) mod 2, Z2 is (C*X + D*Y) mod 2,
    ( [Z1,Z2] = [1,0] -> L = 1
    ; [Z1,Z2] = [0,1] -> L = 2
    ; L = 3 ).

s3_id([1,2,3]).
s3_comp(P, Q, R) :- R = [P1, P2, P3],
    nth1(1, Q, Q1), nth1(2, Q, Q2), nth1(3, Q, Q3),
    nth1(Q1, P, P1), nth1(Q2, P, P2), nth1(Q3, P, P3).

main :-
    format("==== 26 线性变换~n"),

    findall(M, gl22(M), GL),
    length(GL, 6),

    % 乘法封闭
    forall((member(M, GL), member(N, GL), mmul2(M, N, P), member(P, GL)), true),

    % phi 是双射且保复合
    findall(Perm, (member(M, GL), phi(M, Perm)), Perms),
    sort(Perms, Sorted),
    length(Sorted, 6),

    forall((member(M, GL), member(N, GL), mmul2(M, N, P),
            phi(M, PM), phi(N, PN), phi(P, PP)),
           (s3_comp(PM, PN, R), R == PP)),

    format("GL(2,2) ≅ S₃：6 元、乘法封闭、矩阵幂 ↦ 置换复合 ✓~n"),

    format("END ====~n").
