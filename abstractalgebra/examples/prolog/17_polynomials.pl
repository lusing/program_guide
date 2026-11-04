:- encoding(utf8).
% 第 17 章 · 多项式环 —— Prolog 通道
%
% 纯递归卷积乘法 + 长除法 + 余式定理 + 求值同态。

% ---------- 多项式件（低位在前，系数 mod p） ----------
peval(P, F, A, V) :-
    reverse(F, FR),
    foldl([C, Acc0, Acc1]>>(Acc1 is (Acc0 * A + C) mod P), FR, 0, V).

trim(F0, F) :- reverse(F0, R), drop_zeros(R, RR), reverse(RR, F).
drop_zeros([0 | T], R) :- !, drop_zeros(T, R).
drop_zeros(F, F).

padd(P, F, G, S) :-
    length(F, NF), length(G, NG), NL is max(NF, NG),
    findall(C, (NLm is NL - 1, between(0, NLm, I),
                (nth0(I, F, A) -> true ; A = 0),
                (nth0(I, G, B) -> true ; B = 0),
                C is (A + B) mod P), S0),
    trim(S0, S).

% 纯递归卷积：f = [a0|rest] 的积 = a0·g + x·(rest·g)
pmul(P, [], _, [0]) :- !.
pmul(P, _, [], [0]) :- !.
pmul(P, [A | Rest], G, M) :-
    pmul(P, Rest, G, M1),
    shift(M1, M1s),
    scale(P, G, A, GA),
    padd(P, GA, M1s, M).

shift(F, [0 | F]).
scale(_, _, 0, [0]) :- !.
scale(P, G, A, S) :- maplist([B, C]>>(C is A * B mod P), G, S).

% ---------- 长除法 ----------
modinv_p(A, P, B) :- Pm is P - 1, between(1, Pm, B), A * B mod P =:= 1, !.

pdiv(P, F, G, Q, R) :-
    trim(G, Gt), trim(F, Ft),
    length(Gt, NG),
    div_loop(P, Ft, Gt, NG, [], Terms, R0),
    materialize_q(Terms, Q),
    trim(R0, R).

% 商以 (Shift, C) 对累积，最后物化（避开逐步插值的对齐陷阱）
materialize_q(Terms, Q) :-
    max_shift(Terms, 0, MS),
    MSm is MS,
    findall(C, (between(0, MSm, I),
                (member(I-C, Terms) -> true ; C = 0)), Q).

max_shift([], MS, MS).
max_shift([S-_ | T], Acc, MS) :- (S > Acc -> A1 is S ; A1 is Acc), max_shift(T, A1, MS).

div_loop(P, R0, G, NG, Q0, Q, R) :-
    length(R0, NR),
    (NR < NG -> Q = Q0, R = R0
    ; last(R0, RC), last(G, GC),
      modinv_p(GC, P, Ginv),
      C is RC * Ginv mod P,
      Shift is NR - NG,
      scale(P, G, C, CG),
      pad_left(CG, Shift, CGS),
      length(R0, NR2), length(CGS, NL),
      (NL < NR2 -> length(Pad, NR2), append(CGS, Pad, CGP) ; CGP = CGS),
      maplist([X, Y, Z]>>(Z is (X - Y) mod P), R0, CGP, R1),
      trim(R1, R1t),
      div_loop(P, R1t, G, NG, [Shift - C | Q0], Q, R)).

pad_left(L, 0, L) :- !.
pad_left(L, N, [0 | R]) :- N1 is N - 1, pad_left(L, N1, R).

main :-
    format("==== 17 多项式环~n"),

    % 除法算式：x⁵−1 ÷ x²+x+1（ℤ₇）
    pdiv(7, [6, 0, 0, 0, 0, 1], [1, 1, 1], Q, R),
    length(R, LR), length([1, 1, 1], LG), LR < LG,
    pmul(7, Q, [1, 1, 1], QG),
    padd(7, QG, R, Sum),
    Sum == [6, 0, 0, 0, 0, 1],
    format("除法算式：x⁵−1 = q(x)(x²+x+1) + r，deg r < 2（ℤ₇）✓~n"),

    % 余式定理
    forall((between(0, 6, A), F2 = [3, 5, 1, 2]),
           (A1 is (7 - A) mod 7,
            pdiv(7, F2, [A1, 1], _, RR), nth0(0, RR, RV),
            peval(7, F2, A, EV), RV == EV)),
    format("余式定理：f mod (x−a) 余数 = f(a)（ℤ₇，7 点）✓~n"),

    % 次数塌缩
    pmul(4, [1, 2], [1, 2], SQ), SQ == [1],
    format("次数塌缩：ℤ₄[x] 中 (2x+1)² = 1 ✓~n"),

    % 求值同态
    forall(between(0, 6, A),
           (F3 = [1, 5, 3], G3 = [2, 4],
            pmul(7, F3, G3, FG),
            peval(7, F3, A, VF), peval(7, G3, A, VG),
            peval(7, FG, A, VFG),
            VFG is VF * VG mod 7)),
    format("求值同态：φₐ(fg) = φₐ(f)φₐ(g)（ℤ₇，7 点）✓~n"),

    format("END ====~n").
