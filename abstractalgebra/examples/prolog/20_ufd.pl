:- encoding(utf8).
% 第 20 章 · 多项式的唯一分解 —— Prolog 通道
%
% ℤ₂[x] 次数 ≤ 4 的不可约谱 + 分解还原。

peval(P, F, A, V) :-
    reverse(F, FR),
    foldl([C, Acc0, Acc1]>>(Acc1 is (Acc0 * A + C) mod P), FR, 0, V).

has_root(P, F) :- Pm is P - 1, between(0, Pm, A), peval(P, F, A, V), V =:= 0.

deg(F, D) :- length(F, D1), D is D1 - 1.

% ℤ₂[x] 全部 32 个多项式（5 位编码，高位在前 → 低位在前）
poly2(F) :-
    between(0, 31, Code),
    bits5(Code, BitsHigh),
    reverse(BitsHigh, F0),
    trim2(F0, F).

bits5(Code, [B4, B3, B2, B1, B0]) :-
    B4 is Code // 16 mod 2,
    B3 is Code // 8 mod 2,
    B2 is Code // 4 mod 2,
    B1 is Code // 2 mod 2,
    B0 is Code mod 2.

trim2(F0, F) :- reverse(F0, R), drop_z(R, RR), reverse(RR, F).
drop_z([0 | T], R) :- !, drop_z(T, R).
drop_z(F, F).

% deg 1 恒不可约（线性多项式）；deg 2-3：无根 ⟺ 不可约
irreducible2_3(F) :- deg(F, 1), !.
irreducible2_3(F) :- deg(F, D), D >= 2, D =< 3, \+ has_root(2, F).

% deg 4：无根 + 无二次因子
monic_quad2([0, 0, 1]).
monic_quad2([1, 0, 1]).
monic_quad2([0, 1, 1]).
monic_quad2([1, 1, 1]).

divides2(G, F) :- pdiv2(2, F, G, _, R), R == [0], !.

% 多项式乘法（ℤ₂，卷积）
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

% ℤ₂ 长除法
pdiv2(2, F, G, Q, R) :-
    length(G, NG),
    divl2(F, G, NG, [], Q0, R0),
    reverse(Q0, Q), trim2(R0, R).
divl2(R0, G, NG, Q0, Q, R) :-
    length(R0, NR),
    (NR < NG -> Q = Q0, trim2(R0, R)
    ; last(R0, RC), last(G, GC),
      RC == GC,                          % 系数域 ℤ₂：c = rc/gc
      Shift is NR - NG,
      scale2(G, 1, CG),
      pad_l(CG, Shift, CGS),
      length(R0, NR2), length(CGS, CLen),
      (CLen < NR2 -> length(Pad, NR2), append(CGS, Pad, CGP) ; CGP = CGS),
      mapl2sub(R0, CGP, R1),
      trim2(R1, R1t),
      Needed is Shift + 1,
      length(Q0, QL),
      (Needed > QL -> length(Pad2, Needed), append(Q0, Pad2, Q1) ; Q1 = Q0),
      nth0(Shift, Q1, _, QTail),
      nth0(Shift, Q2, 1, QTail),
      divl2(R1t, G, NG, Q2, Q, R)).
pad_l(L, 0, L) :- !.
pad_l(L, N, [0 | R]) :- N1 is N - 1, pad_l(L, N1, R).
mapl2sub([], [], []) :- !.
mapl2sub([A | T], [B | U], [C | V]) :- C is (A - B) mod 2, mapl2sub(T, U, V).

main :-
    format("==== 20 多项式的唯一分解~n"),

    % ℤ₂[x] 次数 1..3 的不可约谱
    findall(F, (poly2(F), irreducible2_3(F)), Irr),
    mapl_deg(Irr, Degrees),
    msort(Degrees, DSorted),
    % deg1: 2 个（x, x+1）、deg2: 1 个（x²+x+1）、deg3: 2 个
    DSorted == [1, 1, 2, 3, 3],
    format("ℤ₂[x] 不可约谱（deg ≤ 3）：deg1 ×2、deg2 ×1、deg3 ×2 ✓~n"),

    % x⁴+x+1 不可约（无根 + 无二次因子）
    \+ has_root(2, [1, 1, 0, 0, 1]),
    \+ (monic_quad2(G), divides2(G, [1, 1, 0, 0, 1])),
    format("x⁴+x+1 (ℤ₂)：无根且无二次因子 ⟹ 不可约 ✓~n"),

    % x⁴+x²+1 = (x²+x+1)²
    pmul2([1, 1, 1], [1, 1, 1], SQ),
    SQ == [1, 0, 1, 0, 1],
    format("x⁴+x²+1 = (x²+x+1)²（ℤ₂）✓~n"),

    format("END ====~n").

mapl_deg([], []).
mapl_deg([F | T], [D | DT]) :- deg(F, D), mapl_deg(T, DT).
