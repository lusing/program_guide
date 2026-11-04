:- encoding(utf8).
% 17_putzer.pl —— 第 17 章：Putzer 2x2 公式引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% ---------- 微分/化简/求值内核（与 02 章同款） ----------
d(n(_), _, n(0)).
d(x, x, n(1)) :- !.
d(Y, Y, n(1)) :- atom(Y), !.
d(E, _, n(0)) :- atom(E), !.
d(add(A, B), V, add(DA, DB)) :- d(A, V, DA), d(B, V, DB).
d(sub(A, B), V, sub(DA, DB)) :- d(A, V, DA), d(B, V, DB).
d(mul(A, B), V, add(mul(DA, B), mul(A, DB))) :- d(A, V, DA), d(B, V, DB).
d(div(A, B), V, div(sub(mul(DA, B), mul(A, DB)), mul(B, B))) :-
    d(A, V, DA), d(B, V, DB).
d(pow(A, N), V, mul(n(N), mul(pow(A, N1), DA))) :-
    integer(N), N1 is N - 1, d(A, V, DA).
d(exp(A), V, mul(exp(A), DA)) :- d(A, V, DA).
d(sin(A), V, mul(cos(A), DA)) :- d(A, V, DA).
d(cos(A), V, neg(mul(sin(A), DA))) :- d(A, V, DA).

tl(sum(Ts), Ts) :- !.
tl(n(C), Ts) :- !, (C =:= 0 -> Ts = [] ; Ts = [t(C, [])]).
tl(add(A, B), Ts) :- !, tl(A, TA), tl(B, TB), append(TA, TB, Ts).
tl(sub(A, B), Ts) :- !, tl(A, TA), tl(B, TB),
    maplist(neg_t, TB, TBN), append(TA, TBN, Ts).
tl(mul(A, B), Ts) :- !, tl(A, TA), tl(B, TB), prod_terms(TA, TB, Ts).
tl(div(A, B), Ts) :- !, tl(mul(A, pow(B, -1)), Ts).
tl(pow(mul(A, B), N), Ts) :- !, tl(mul(pow(A, N), pow(B, N)), Ts).
tl(pow(pow(E, M), N), Ts) :- !, MN is M * N, tl(pow(E, MN), Ts).
tl(pow(A, N), Ts) :- !,
    ( A = n(V) -> W is V ^ N, tl(n(W), Ts)
    ; Ts = [t(1, [p(A, N)])] ).
tl(E, [t(1, [p(E, 1)])]).

neg_t(t(C, M), t(CN, M)) :- CN is -C.

prod_terms([], _, []).
prod_terms([t(Ca, Ma) | Rest], TB, Ts) :-
    prod_terms(Rest, TB, TsRest),
    ( Ca =:= 0 -> Ts = TsRest
    ; maplist(mul_term(Ca, Ma), TB, TsHead), append(TsHead, TsRest, Ts) ).

mul_term(Ca, Ma, t(Cb, Mb), t(C, M)) :- C is Ca * Cb, merge_pows(Ma, Mb, M).

merge_pows([], M, M).
merge_pows([p(F, N) | Ps], Qs, M) :- insert_pow(F, N, Qs, Qs2), merge_pows(Ps, Qs2, M).

insert_pow(F, N, [], [p(F, N)]).
insert_pow(F, N, [p(G, M) | Qs], R) :-
    ( F == G -> N2 is N + M,
        ( N2 =:= 0 -> R = Qs ; R = [p(F, N2) | Qs] )
    ; F @< G -> R = [p(F, N), p(G, M) | Qs]
    ; R = [p(G, M) | R2], insert_pow(F, N, Qs, R2) ).

combine_terms([], []).
combine_terms([t(C, M) | Ts], Out) :-
    partition(same_mono(M), Ts, Same, Rest),
    maplist(arg(1), Same, Cs),
    sum_list([C | Cs], C2),
    combine_terms(Rest, Rest2),
    ( C2 =:= 0 -> Out = Rest2 ; Out = [t(C2, M) | Rest2] ).
same_mono(M, t(_, M2)) :- M == M2.

rebuild([], n(0)).
rebuild([t(C, [])], n(C)) :- !.
rebuild([t(1, [p(F, 1)])], F) :- !.
rebuild([t(1, Ms)], S) :- !, rebuild_prod(Ms, S).
rebuild([t(C, Ms)], S) :- !, rebuild_prod(Ms, P),
    (P = n(1) -> S = n(C) ; S = mul(n(C), P)).
rebuild(Ts, sum(Ts)).

rebuild_prod([], n(1)).
rebuild_prod([p(F, 1)], F) :- !.
rebuild_prod([p(F, N)], pow(F, N)) :- !.
rebuild_prod([p(F, 1) | Ps], mul(F, R)) :- !, rebuild_prod(Ps, R).
rebuild_prod([p(F, N) | Ps], mul(pow(F, N), R)) :- rebuild_prod(Ps, R).

simp(n(C), n(C)) :- !.
simp(x, x) :- !.
simp(sum(Ts), S) :- !, combine_terms(Ts, TsC), rebuild(TsC, S).
simp(neg(A), S) :- !, simp(mul(n(-1), A), S).
simp(add(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(add(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(sub(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(sub(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(mul(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(mul(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(div(A, B), S) :- !, simp(A, SA), simp(B, SB),
    ( SB = n(V), V =\= 0 -> Q is 1 rdiv V, tl(mul(SA, n(Q)), Ts)
    ; tl(mul(SA, pow(SB, -1)), Ts) ),
    combine_terms(Ts, TsC), rebuild(TsC, S).
simp(E, E).

ev_at(n(C), _, C).
ev_at(x, X, X).
ev_at(add(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA + VB.
ev_at(sub(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA - VB.
ev_at(mul(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA * VB.
ev_at(div(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA / VB.
ev_at(neg(A), X, V) :- ev_at(A, X, VA), V is -VA.
ev_at(exp(A), X, V) :- ev_at(A, X, VA), V is exp(VA).
ev_at(sin(A), X, V) :- ev_at(A, X, VA), V is sin(VA).
ev_at(cos(A), X, V) :- ev_at(A, X, VA), V is cos(VA).
ev_at(pow(A, N), X, V) :- ev_at(A, X, VA), V is VA ^ N.
ev_at(sum(Ts), X, V) :- ev_terms(Ts, X, V).
ev_terms([], _, 0).
ev_terms([t(C, Ms) | Ts], X, V) :- ev_mono(Ms, X, VM), ev_terms(Ts, X, VR),
    V is C * VM + VR.
ev_mono([], _, 1).
ev_mono([p(F, N) | Ps], X, V) :- ev_at(F, X, VF), VN is VF ^ N,
    ev_mono(Ps, X, VR), V is VN * VR.

subst(n(C), _, _, n(C)).
subst(x, _, _, x).
subst(y, Phi, _, Phi) :- !.
subst(yp, _, DPhi, DPhi) :- !.
subst(add(A, B), Phi, DPhi, add(SA, SB)) :- subst(A, Phi, DPhi, SA), subst(B, Phi, DPhi, SB).
subst(sub(A, B), Phi, DPhi, sub(SA, SB)) :- subst(A, Phi, DPhi, SA), subst(B, Phi, DPhi, SB).
subst(mul(A, B), Phi, DPhi, mul(SA, SB)) :- subst(A, Phi, DPhi, SA), subst(B, Phi, DPhi, SB).
subst(div(A, B), Phi, DPhi, div(SA, SB)) :- subst(A, Phi, DPhi, SA), subst(B, Phi, DPhi, SB).
subst(neg(A), Phi, DPhi, neg(SA)) :- subst(A, Phi, DPhi, SA).
subst(E, Phi, DPhi, SE) :-
    E =.. [F, A], opaque(F), !,
    subst(A, Phi, DPhi, SA), SE =.. [F, SA].
subst(E, _, _, E).

opaque(exp). opaque(ln). opaque(sin). opaque(cos).

solve_check(Body, Phi) :-
    d(Phi, x, DPhi),
    subst(Body, Phi, DPhi, R),
    simp(R, n(0)).

% ---------- Putzer 2x2 ----------
% e^{At} = e^{τt/2}[cosh(κt) I + sinh(κt)/κ (A - τI/2)]，κ² = τ²/4 - det
% κ² < 0 时 cosh/sinh → cos/sin；κ = 0 时取极限 I + tB
putzer_kind(A, B, C, D, Kind) :-
    Tau is float(A + D), Det is A * D - B * C,
    K2 is Tau * Tau / 4 - Det,
    (   K2 > 1.0e-12 -> Kind = hyperbolic(Tau, K2)
    ;   K2 < -1.0e-12 -> K2n is -K2, Kind = trigonometric(Tau, K2n)
    ;   Kind = parabolic(Tau)
    ).

% putzer_at(A,B,C,D,T,E11,E12,E21,E22)：公式数值求值
putzer_at(A, B, C, D, T, E11, E12, E21, E22) :-
    Tau is A + D, Det is A * D - B * C,
    K2 is Tau * Tau / 4 - Det,
    H is exp(Tau * T / 2),
    B11 is A - Tau / 2, B12 is B, B21 is C, B22 is D - Tau / 2,
    (   K2 > 1.0e-12 ->
        K is sqrt(K2), CH is cosh(K * T), SH is sinh(K * T) / K
    ;   K2 < -1.0e-12 ->
        K is sqrt(-K2), CH is cos(K * T), SH is sin(K * T) / K
    ;   CH = 1.0, SH = T
    ),
    E11 is H * (CH + SH * B11), E12 is H * (SH * B12),
    E21 is H * (SH * B21), E22 is H * (CH + SH * B22).

% ---------- main ----------
main :-
    format("==== 17 putzer~n"),

    % (1) 三情形分类
    putzer_kind(2, 1, 1, 2, hyperbolic(4.0, 1.0)),
    format("[[2,1],[1,2]]: hyperbolic (kappa = 1, cosh/sinh)~n"),
    putzer_kind(1, -2, 2, 1, trigonometric(2.0, 4.0)),
    format("[[1,-2],[2,1]]: trigonometric (kappa = 2, cos/sin)~n"),
    putzer_kind(1, 1, 0, 1, parabolic(2.0)),
    format("[[1,1],[0,1]]: parabolic (kappa = 0, I + tB)~n"),

    % (2) 公式数值：Jordan 块 [[1,1],[0,1]] 的 e^{At} = e^t[[1,t],[0,1]]
    putzer_at(1.0, 1.0, 0.0, 1.0, 0.7, E11, E12, E21, E22),
    abs(E11 - exp(0.7)) < 1.0e-12,
    abs(E12 - 0.7 * exp(0.7)) < 1.0e-12,
    abs(E21) < 1.0e-15,
    abs(E22 - exp(0.7)) < 1.0e-12,
    format("Jordan [[1,1],[0,1]]: e^{At} = e^t [[1,t],[0,1]] verified at t=0.7~n"),

    % (3) 实异根矩阵：e^{At} 与特征分解 e^{tV diag V^-1} 数值对照
    % A = [[2,1],[1,2]]，λ=3/1，v=(1,1)/(1,-1)
    putzer_at(2.0, 1.0, 1.0, 2.0, 0.5, F11, F12, _, _),
    % e^{At} 作用在 (1,2) 上 = -0.5 e^t (1,-1) + 1.5 e^{3t} (1,1)
    X1 is F11 * 1.0 + F12 * 2.0,
    X1_expect is -0.5 * exp(0.5) * 1.0 + 1.5 * exp(1.5) * 1.0,
    abs(X1 - X1_expect) < 1.0e-12,
    format("e^{At} x0 (x-component) matches spectral decomposition at t=0.5~n"),

    % (4) det e^{At} = e^{tr t}
    putzer_at(1.0, -2.0, 2.0, 1.0, 0.8, A11, A12, A21, A22),
    DetFull is A11 * A22 - A12 * A21,
    abs(DetFull - exp(2.0 * 0.8)) < 1.0e-12,
    format("det e^{At} = e^{tr(A) t} for rotation+growth matrix~n"),

    format("END ====~n").
