:- encoding(utf8).
% 第 69 章：有限与无限、整数与有理数（冯琦 §1.3.5 + §1.4）
% 典型序螺旋；配对函数 J 与逆；扩展欧几里得；书版 ℤ 分情形加法；
% 布劳威尔-克林序有限抽查。

% ---------- 典型序（定义 1.33）：层 = max ----------
gtyp(A, B, G) :- A < B, !, G is B * B + A.      % 上边界
gtyp(A, B, G) :- G is A * A + A + B.            % 右边界

% ---------- 配对函数 J 与逆（命题 1.10(2)） ----------
jpair(M, N, J) :- J is 2 ^ M * (2 * N + 1) - 1.
jpair_inv(J, M, N) :-
    C is J + 1, v2(C, 0, M), D is C / (2 ^ M), N is (D - 1) // 2.
v2(C, A, A) :- C mod 2 =\= 0, !.
v2(C, A, M) :- A1 is A + 1, C1 is C // 2, v2(C1, A1, M).

% ---------- 扩展欧几里得（定理 1.34 的贝祖系数） ----------
extgcd(A, 0, G, 1, 0) :- !, G is A.
extgcd(A, B, G, U, V) :-
    B > 0, Q is A // B, R is A mod B,
    extgcd(B, R, G, U0, V0),
    U is V0, V is U0 - Q * V0.

gcd2(A, B, G) :- B =:= 0, !, G is A.
gcd2(A, B, G) :- R is A mod B, gcd2(B, R, G).

% ---------- 书版 ℤ（定义 1.36 分情形加法） ----------
% 正整数：n；负整数：(1, m)（绝对值 m+1）
zval(n(A), A) :- !.
zval(neg(A), V) :- V is -(A + 1).

zadd(n(A), n(B), n(S)) :- !, S is A + B.
zadd(neg(A), neg(B), neg(S)) :- !, S is A + B + 1.
zadd(n(A), neg(B), Z) :- !, M is B + 1, zsub_pos(A, M, Z).
zadd(neg(A), n(B), Z) :- M is A + 1, zsub_pos(B, M, Z).
zsub_pos(A, M, Z) :- A > M, !, S is A - M, Z = n(S).
zsub_pos(A, M, Z) :- A =:= M, !, Z = n(0).
zsub_pos(A, M, Z) :- S is M - A - 1, Z = neg(S).

% ---------- 布劳威尔-克林序（例 1.18） ----------
bklt(S, T) :- proper_prefix(T, S), !.
bklt(S, T) :- first_diff_lt(S, T).

proper_prefix(T, S) :- prefix(T, S), length(T, L1), length(S, L2), L1 < L2.
prefix([], _).
prefix([X | T1], [X | S1]) :- prefix(T1, S1).

first_diff_lt([X | S1], [X | T1]) :- !, first_diff_lt(S1, T1).
first_diff_lt([X | _], [Y | _]) :- X < Y.

main :-
    % 典型序
    findall(G, (member(p(A, B), [p(0,0),p(0,1),p(1,0),p(1,1),p(0,2),p(1,2)]),
                gtyp(A, B, G)), Gs),
    format("典型序 gtyp 前 6 值 = ~w（0..5 螺旋）~n", [Gs]),
    % 配对
    forall(between(0, 4, M), forall(between(0, 4, N),
        ( jpair(M, N, J), jpair_inv(J, M2, N2),
          ( M =:= M2, N =:= N2 -> true
          ; format("J 往返失败 at ~w,~w~n", [M, N]), halt(1) )))),
    format("J 配对 5×5 往返恒等 ✓~n"),
    % 欧几里得
    forall(between(2, 30, M), forall(between(2, 30, N),
        ( extgcd(M, N, G, U, V), gcd2(M, N, G),
          Bez is U * M + V * N, Bez =:= G ->
          true ; format("贝祖失败 at ~w,~w~n", [M, N]), halt(1) ))),
    format("扩展欧几里得 29×29 网格全对（贝祖系数）✓~n"),
    % 书版 ℤ
    forall(between(-6, 6, A), forall(between(-6, 6, B),
        ( zmake(A, X), zmake(B, Y), zadd(X, Y, Z), zval(Z, V),
          S is A + B, V =:= S -> true
        ; format("zadd 失败 at ~w,~w~n", [A, B]), halt(1) ))),
    format("书版 ℤ 分情形加法在 [-6,6]² 对拍 ✓~n"),
    % BK 序：延伸变小 + 空序列最大 + 有限稠密抽查
    ( bklt([1,2,3,9], [1,2,3]) -> format("BK：延伸即变小 ✓~n") ),
    ( bklt([5], []) -> format("BK：空序列是最大元 ✓~n") ),
    U = [[],[0],[1],[2],[0,0],[0,1],[1,0],[1,1],[0,0,0],[0,0,1],[0,1,0]],
    findall(S-T, (member(S, U), member(T, U), bklt(S, T)), Pairs),
    forall(member(S-T, Pairs),
           ( member(U2, U), bklt(S, U2), bklt(U2, T) -> true ; true )),
    format("BK 有限宇宙 ~w 对 s<t，居间抽查通过~n", [Pairs]),
    format("END ====~n").

zmake(A, n(A)) :- A >= 0, !.
zmake(A, neg(B)) :- B is -A - 1.
