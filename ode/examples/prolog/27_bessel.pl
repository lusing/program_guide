:- encoding(utf8).
% 27_bessel.pl —— 第 27 章：Gamma 递推 + J0 级数系数（Prolog 通道）
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

% ---------- Gamma 递推（rational 阶乘账） ----------
gamma_fact(0, 1).
gamma_fact(N, F) :- N > 0, N1 is N - 1, gamma_fact(N1, F1), F is N * F1.
% Gamma(n+1) = n!
gamma_check(N) :- gamma_fact(N, F), F =:= gamma(N + 1).

% Gamma(1/2) = sqrt(pi)（数值）
gamma_half(V) :- V is sqrt(pi * 1.0).

% ---------- J0 级数系数（rational） ----------
% J0(x) = sum (-1)^k (x/2)^{2k} / (k!)^2
j0_coeff(K, C) :-
    gamma_fact(K, KF),
    Den is KF * KF,
    C is (-1) ** K / Den.   % 浮点（符号 + 分母）

j0_coeff_q(K, Num, Den) :-   % 有理账：Num = (-1)^k、Den = (k!)^2
    gamma_fact(K, KF), Den is KF * KF,
    (K mod 2 =:= 0 -> Num = 1 ; Num = -1).

% J0 数值（截断 20 项）
j0_val(X, V) :- j0_sum(X, 20, V).
j0_sum(X, N, V) :- j0_loop(X, N, 0, 0.0, V).
j0_loop(_, N, K, Acc, Acc) :- K > N, !.
j0_loop(X, N, K, Acc, V) :-
    j0_coeff(K, C),
    Term is C * (X / 2) ** (2 * K),
    Acc1 is Acc + Term,
    K1 is K + 1,
    j0_loop(X, N, K1, Acc1, V).

% ---------- J1/J2 级数 ----------
j1_val(X, V) :- j1_sum(X, 20, V).
j1_sum(X, N, V) :- j1_loop(X, N, 0, 0.0, V).
j1_loop(_, N, K, Acc, Acc) :- K > N, !.
j1_loop(X, N, K, Acc, V) :-
    gamma_fact(K, KF), gamma_fact(K + 1, KF1),
    C is (-1) ** K / (KF * KF1),
    Term is C * (X / 2) ** (2 * K + 1),
    Acc1 is Acc + Term,
    K1 is K + 1,
    j1_loop(X, N, K1, Acc1, V).
j2_series_val(X, V) :- j2_sum(X, 20, V).
j2_sum(X, N, V) :- j2_loop(X, N, 0, 0.0, V).
j2_loop(_, N, K, Acc, Acc) :- K > N, !.
j2_loop(X, N, K, Acc, V) :-
    gamma_fact(K, KF), gamma_fact(K + 2, KF2),
    C is (-1) ** K / (KF * KF2),
    Term is C * (X / 2) ** (2 * K + 2),
    Acc1 is Acc + Term,
    K1 is K + 1,
    j2_loop(X, N, K1, Acc1, V).

% ---------- main ----------
main :-
    format("==== 27 bessel~n"),

    % (1) Gamma 阶乘
    gamma_fact(5, 120), gamma_fact(7, 5040),
    gamma_half(GH), abs(GH - 1.7724538509055159) < 1.0e-12,
    format("Gamma: 5! = 120, 7! = 5040, Gamma(1/2) = sqrt(pi) = ~w~n", [GH]),

    % (2) J0 级数前几项系数（分母 (k!)²）
    j0_coeff_q(0, 1, 1), j0_coeff_q(1, -1, 1), j0_coeff_q(2, 1, 4), j0_coeff_q(3, -1, 36),
    format("J0 coefficients: 1, -1, 1/4, -1/36 (denominator (k!)^2)~n"),

    % (3) J0 数值：文献值 J0(1) = 0.76520、J0(5) = -0.17760
    j0_val(1.0, V1), abs(V1 - 0.7651976865579666) < 1.0e-12,
    j0_val(5.0, V5), abs(V5 - (-0.1775967713143383)) < 1.0e-10,
    format("J0(1) = ~w, J0(5) = ~w (series, literature values)~n", [V1, V5]),

    % (4) 递推：J2 = (2/x)J1 - J0（级数独立算 vs 递推生成）
    j1_val(2.3, J1v), j0_val(2.3, J0v), j2_series_val(2.3, J2v),
    Rec is 2 * J1v / 2.3 - J0v,
    abs(J2v - Rec) < 1.0e-10,
    format("recurrence: J2(series) = (2/x)J1 - J0 at x = 2.3~n"),

    format("END ====~n").
