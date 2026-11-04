:- encoding(utf8).
% 第 09 章 · 群的定义与例子 —— Prolog 通道
%
% 凯莱表（op/4 事实）+ 公理直译 + 元素阶 + 定理 2.63 关系。

% ---------- 表驱动公理 ----------
% op(G, X, Y, Z)：群 G 中 X*Y = Z（元素以 1..n 编号）
closed(G)    :- forall((elem(G, X), elem(G, Y), op(G, X, Y, Z)), elem(G, Z)).
identity(G, E) :-
    elem(G, E),
    forall(elem(G, X), (op(G, E, X, X), op(G, X, E, X))).
inverses(G, E) :-
    forall(elem(G, X), (elem(G, Y), op(G, X, Y, E))).
associative(G) :-
    forall((elem(G, X), elem(G, Y), elem(G, Z),
            op(G, X, Y, XY), op(G, Y, Z, YZ),
            op(G, XY, Z, L), op(G, X, YZ, R)),
           (L == R ; L =:= R)).

abelian(G) :-
    forall((elem(G, X), elem(G, Y), op(G, X, Y, A), op(G, Y, X, B)), A == B).

is_group(G) :-
    closed(G),
    identity(G, E),
    inverses(G, E),
    associative(G).

% ---------- ℤ₄（加法，0..3 编号 1..4） ----------
elem(z4, X) :- member(X, [1, 2, 3, 4]).         % 编号 i ↔ 剩余类 i−1
op(z4, X, Y, Z) :- elem(z4, X), elem(z4, Y),
                   A is X - 1, B is Y - 1,
                   C is (A + B) mod 4, Z is C + 1.

% ---------- U(8)（乘法：{1,3,5,7} 编号 1..4） ----------
u8_vals([1, 3, 5, 7]).
elem(u8, X) :- u8_vals(Vs), member(X, Vs).
op(u8, X, Y, Z) :- elem(u8, X), elem(u8, Y), Z is (X * Y) mod 8.

% ---------- D₃（α^i b^j；1=1, 2=α, 3=α², 4=b, 5=αb, 6=α²b） ----------
elem(d3, X) :- between(1, 6, X).
op(d3, X, Y, Z) :-
    split(X, I, J), split(Y, K, L),
    (   J =:= 0 -> (R is (I + K) mod 3, S is L)
    ;   (R is (I - K) mod 3, S is 1 - L)
    ),
    join(R, S, Z).

split(X, I, J) :- X =< 3, !, I is X - 1, J = 0.
split(X, I, J) :- X > 3, !, I is X - 4, J = 1.
join(R, S, Z) :- S =:= 0, !, Z is R + 1.
join(R, S, Z) :- S =:= 1, Z is 3 + R + 1.

% ---------- 元素阶 ----------
order(G, X, N) :-
    identity(G, E),
    order_(G, X, E, 1, N).
order_(_, E, E, K, K) :- !.
order_(G, X, E, K0, N) :-
    op(G, X, E, Next),
    K1 is K0 + 1,
    order_(G, X, Next, K1, N).

% ---------- 幂 ----------
pow(G, X, 0, E) :- !, identity(G, E).
pow(G, X, K, P) :-
    K > 0,
    K1 is K - 1,
    pow(G, X, K1, P0),
    op(G, X, P0, P).

main :-
    format("==== 09 群的定义与例子~n"),

    forall(member(G, [z4, u8, d3]), is_group(G)),
    format("公理检查：ℤ₄、U(8)、D₃ 全过（封闭/单位/逆元/结合律 O(n³)）✓~n"),

    abelian(z4), abelian(u8), \+ abelian(d3),
    format("交换性：ℤ₄、U(8) 阿贝尔；D₃ 非阿贝尔 ✓~n"),

    % 元素阶
    findall(N, (elem(u8, X), order(u8, X, N)), Ns8),
    msort(Ns8, [1, 2, 2, 2]),
    format("元素阶：U(8) = ~w（Klein 四元群）✓~n", [Ns8]),

    % 定理 2.63 关系（n = 3）：α = 元素 2，b = 元素 4
    identity(d3, E),
    pow(d3, 2, 3, P1), P1 == E,          % α³ = 1
    op(d3, 4, 4, P2), P2 == E,           % b² = 1
    op(d3, 4, 2, Ba), op(d3, Ba, 4, Bab),
    pow(d3, 2, 2, Ainv),                 % α⁻¹ = α²
    Bab == Ainv,                          % bab = α⁻¹
    format("定理 2.63：α³ = b² = 1，bab = α⁻¹（D₃ 表上逐项）✓~n"),

    % 非阿贝尔现场：(αb)² ≠ α²b²
    op(d3, 2, 4, AB),
    pow(d3, AB, 2, AB2),
    pow(d3, 2, 2, A2), pow(d3, 4, 2, B2),
    op(d3, A2, B2, A2B2),
    AB2 \== A2B2,
    format("非阿贝尔现场：D₃ 中 (αb)² ≠ α²b² ✓~n"),

    format("END ====~n").
