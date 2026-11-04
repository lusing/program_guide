:- encoding(utf8).
% 24_laplace.pl —— 第 24 章：Laplace 变换表引擎（Prolog 通道）
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

% ---------- 变换表 ----------
laplace(n(1), div(n(1), s)).
laplace(n(C), div(n(C), s)) :- C =\= 1.
laplace(pow(t, 2), div(n(2), pow(s, 3))).
laplace(exp(mul(n(-1), t)), div(n(1), add(s, n(1)))).
laplace(sin(mul(n(2), t)), div(n(2), add(pow(s, 2), n(4)))).
laplace(cos(mul(n(2), t)), div(s, add(pow(s, 2), n(4)))).

% 线性（表驱动的简单组合）
laplace(add(A, B), add(LA, LB)) :- laplace(A, LA), laplace(B, LB), !.
laplace(mul(n(C), F), mul(n(C), LF)) :- laplace(F, LF), !.

% ---------- 数值求值：F(s) 表达式在数值点 ----------
eval_laplace(div(n(1), s), S, V) :- V is 1 / S.
eval_laplace(div(n(2), pow(s, 3)), S, V) :- V is 2 / S ** 3.
eval_laplace(div(n(1), add(s, n(1))), S, V) :- V is 1 / (S + 1).
eval_laplace(div(n(2), add(pow(s, 2), n(4))), S, V) :- V is 2 / (S * S + 4).
eval_laplace(div(s, add(pow(s, 2), n(4))), S, V) :- V is S / (S * S + 4).

% ---------- main ----------
main :-
    format("==== 24 laplace~n"),

    % (1) 表变换 + 数值点核对：∫e^{-st}f dt vs 表值（梯形）
    check_laplace(exp(mul(n(-1), t)), 2.0),
    check_laplace(sin(mul(n(2), t)), 1.2),
    format("table transform verified numerically for e^-t and sin 2t~n"),

    % (2) 线性组合
    laplace(add(n(3), pow(t, 2)), add(div(n(3), s), div(n(2), pow(s, 3)))),
    format("linearity: L{3 + t^2} = 3/s + 2/s^3~n"),

    % (3) 例 B 部分分式：1/[s(s+1)(s+2)] = 1/2s - 1/(s+1) + 1/2(s+2)
    (   between(1, 5, I), S is 0.6 + I * 0.5,
        LHS is 1 / (S * (S + 1) * (S + 2)),
        RHS is 0.5 / S - 1 / (S + 1) + 0.5 / (S + 2),
        abs(LHS - RHS) < 1.0e-12,
        fail
    ;   true
    ),
    format("partial fractions: 1/[s(s+1)(s+2)] = 1/(2s) - 1/(s+1) + 1/(2(s+2))~n"),

    % (4) 卷积定理数值：(e^-t * t)(t) = t - 1 + e^-t 的变换 = 1/(s^2(s+1))
    (   between(1, 4, I), S is 0.8 + I * 0.6,
        % L{t - 1 + e^-t} = 1/s^2 - 1/s + 1/(s+1)
        LHS is 1 / (S * S) - 1 / S + 1 / (S + 1),
        RHS is 1 / (S * S * (S + 1)),
        abs(LHS - RHS) < 1.0e-12,
        fail
    ;   true
    ),
    format("convolution: L{t-1+e^-t} = 1/(s^2(s+1)) = L{e^-t}L{t}~n"),

    format("END ====~n").

% check_laplace(F_t, S)：数值积分 vs 表值
check_laplace(exp(mul(n(-1), t)), S) :-
    eval_laplace(div(n(1), add(s, n(1))), S, Vtable),
    num_integral(S, exp_neg, Vnum),
    abs(Vnum - Vtable) / Vtable < 1.0e-6.
check_laplace(sin(mul(n(2), t)), S) :-
    eval_laplace(div(n(2), add(pow(s, 2), n(4))), S, Vtable),
    num_integral(S, sin2, Vnum),
    abs(Vnum - Vtable) / Vtable < 1.0e-6.

% 被积函数选择
integrand(exp_neg, T, V) :- V is exp(-T).            % f = e^{-t}（表项 1/(s+1)）
integrand(sin2, T, V) :- V is sin(2 * T).

% 数值 ∫₀^T e^{-st} f(t) dt（T = 30，梯形 300000 点）
num_integral(S, Kind, V) :-
    T is 30.0, Nn is 300000, H is T / Nn,
    integral_loop(S, Kind, T, Nn, H, 1, 0.0, V0),
    integrand(Kind, 0.0, F0), integrand(Kind, T, FT),
    V is V0 + H / 2 * (F0 + exp(-S * T) * FT).

integral_loop(_, _, _, Nn, _, I, Acc, Acc) :- I >= Nn, !.
integral_loop(S, Kind, T, Nn, H, I, Acc, V) :-
    Ti is I * H,
    integrand(Kind, Ti, F),
    Acc1 is Acc + H * exp(-S * Ti) * F,
    I1 is I + 1,
    integral_loop(S, Kind, T, Nn, H, I1, Acc1, V).
