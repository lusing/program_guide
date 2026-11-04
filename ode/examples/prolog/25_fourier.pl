:- encoding(utf8).
% 25_fourier.pl —— 第 25 章：系数引擎（Prolog 通道）
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

% ---------- 方波/锯齿波闭式系数（rational + pi） ----------
% 方波 sq(x) = sign(x)：b_n = 4/(pi n)（奇 n）
sq_bn(N, Bn) :- N mod 2 =:= 1, Bn is 4.0 / (pi * N), !.
sq_bn(_, 0.0).

% 锯齿波 saw(x) = x on (-pi, pi)：b_n = 2(-1)^{n+1}/n
saw_bn(N, Bn) :- N mod 2 =:= 1, !, Bn is 2.0 / N.
saw_bn(N, Bn) :- Bn is -2.0 / N.

% x^2 的余弦系数 a_n = 4(-1)^n/n^2
x2_an(N, An) :- Sign is (-1.0) ** N, An is 4.0 * Sign / (N * N).

% Parseval 截断（方波到 N 项）
parseval_partial(N, E) :-
    findall(Bn, (between(1, N, K), K mod 2 =:= 1, Bn is (4.0 / (pi * K)) ** 2), Bs),
    sum_list(Bs, E).

% ---------- main ----------
main :-
    format("==== 25 fourier~n"),

    % (1) 方波系数
    sq_bn(1, B1), abs(B1 - 4.0 / pi) < 1.0e-12,
    sq_bn(3, B3), abs(B3 - 4.0 / (3 * pi)) < 1.0e-12,
    sq_bn(2, 0.0),
    format("square wave: b_1 = 4/pi, b_3 = 4/(3pi), even n vanish~n"),

    % (2) 锯齿系数
    saw_bn(1, S1), abs(S1 - 2.0) < 1.0e-12,
    saw_bn(2, S2), abs(S2 + 1.0) < 1.0e-12,
    format("sawtooth: b_1 = 2, b_2 = 1 (formula -2(-1)^{n+1}/n)~n"),

    % (3) x^2 余弦系数
    x2_an(1, A1), abs(A1 + 4.0) < 1.0e-12,
    x2_an(2, A2), abs(A2 - 1.0) < 1.0e-12,
    format("x^2 cosine coefficients: a_1 = -4, a_2 = 1 (1/n^2 decay)~n"),

    % (4) Parseval 截断 → 2
    parseval_partial(2001, E),
    abs(E - 2.0) < 5.0e-3,
    format("Parseval: partial sum (N=2001) = ~w -> 2 = (1/pi) int f^2~n", [E]),

    format("END ====~n").
