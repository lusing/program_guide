:- encoding(utf8).
% 第 22 章 · 商环与有限域 —— Prolog 通道
%
% GF(4) 全表驱动 + GF(8) 生成元阶。

% ---------- GF(4)：元素 0,1,2,3 ↔ 0,1,α,α+1 ----------
gf4_add(0, X, X) :- !.
gf4_add(X, 0, X) :- !.
gf4_add(1, 1, 0) :- !.
gf4_add(2, 2, 0) :- !.
gf4_add(3, 3, 0) :- !.
gf4_add(1, 2, 3) :- !.
gf4_add(2, 1, 3) :- !.
gf4_add(1, 3, 2) :- !.
gf4_add(3, 1, 2) :- !.
gf4_add(2, 3, 1) :- !.
gf4_add(3, 2, 1).

gf4_mul(0, _, 0) :- !.
gf4_mul(_, 0, 0) :- !.
gf4_mul(1, X, X) :- !.
gf4_mul(X, 1, X) :- !.
gf4_mul(2, 2, 3) :- !.       % α·α = α+1
gf4_mul(2, 3, 1) :- !.        % α·α² = 1
gf4_mul(3, 2, 1) :- !.
gf4_mul(3, 3, 2).             % α²·α² = α

gf4_elem(X) :- member(X, [0, 1, 2, 3]).

% ---------- GF(2³) 多项式模型 ----------
% 元素 = 长度 3 的 ℤ₂ 向量（低位在前），模 x³+x+1
gf8_elem([A, B, C]) :- member(A, [0, 1]), member(B, [0, 1]), member(C, [0, 1]).

gf8_add(X, Y, Z) :- maplist([A, B, C]>>(C is (A + B) mod 2), X, Y, Z).

gf8_mul(X, Y, Z) :-
    pmul2(X, Y, P),
    reduce8(P, Z).

pmul2([], _, [0]) :- !.
pmul2(_, [], [0]) :- !.
pmul2([A | Rest], G, M) :-
    pmul2(Rest, G, M1),
    shift(M1, M1s),
    scale2(G, A, GA),
    padd2(GA, M1s, M).
shift(F, [0 | F]).
scale2(_, 0, [0]) :- !.
scale2(G, 1, G).
padd2(F, G, S) :-
    length(F, NF), length(G, NG), NL is max(NF, NG),
    findall(C, (NLm is NL - 1, between(0, NLm, I),
                (nth0(I, F, A) -> true ; A = 0),
                (nth0(I, G, B) -> true ; B = 0),
                C is (A + B) mod 2), S).

% 模 x³+x+1 归约（反复消 ≥ 3 次项）
reduce8(P, Z) :-
    length(P, NP),
    (NP =< 3 -> pad3(P, Z)
    ; last(P, C),
      append(Low, [C], P),          % P 已绑定：Low 唯一确定
      padd2(Low, [C, C], L1),       % x³ ≡ x+1：c·x³ ↦ c·(x+1)
      reduce8(L1, Z)).

pad3(P, Z) :- length(P, N),
    (N == 3 -> Z = P
    ; Need is 3 - N, length(Pad, Need), append(P, Pad, Z)).

% α = [0,1,0] 的幂
gf8_pow(0, [1, 0, 0]) :- !.
gf8_pow(K, P) :- K > 0, K1 is K - 1, gf8_pow(K1, P0),
    gf8_mul(P0, [0, 1, 0], P).

main :-
    format("==== 22 商环与有限域~n"),

    % GF(4) 加法表对称性 + 乘法交换
    forall((gf4_elem(A), gf4_elem(B)),
           (gf4_add(A, B, S1), gf4_add(B, A, S2), S1 == S2)),
    forall((gf4_elem(A), gf4_elem(B)),
           (gf4_mul(A, B, P1), gf4_mul(B, A, P2), P1 == P2)),
    % α³ = 1：非零乘法群循环
    gf4_mul(2, 2, 3), gf4_mul(2, 3, 1), gf4_mul(3, 3, 2),
    % 分配律（4³ 全查）
    forall((gf4_elem(A), gf4_elem(B), gf4_elem(C)),
           (gf4_add(B, C, BC), gf4_mul(A, BC, L),
            gf4_mul(A, B, AB), gf4_mul(A, C, AC), gf4_add(AB, AC, R),
            L == R)),
    format("GF(4)：加乘交换、α³ = 1、分配律 4³ 全查 ✓~n"),

    % GF(8)：α 的阶 = 7（原根）
    gf8_pow(7, [1, 0, 0]),
    \+ (between(1, 6, K), gf8_pow(K, [1, 0, 0])),
    % α 的全部幂遍历非零元
    findall(P, (between(1, 7, K), gf8_pow(K, P)), Powers),
    msort(Powers, [_ | _]),
    length(Powers, 7),
    format("GF(8) = ℤ₂[x]/(x³+x+1)：α 阶 7（原根），α 的幂遍历非零元 ✓~n"),

    format("END ====~n").
