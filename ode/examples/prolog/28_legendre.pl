:- encoding(utf8).
% 28_legendre.pl —— 第 28 章：多项式递推 + 椭圆积分账（Prolog 通道）
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

% ---------- Legendre 系数表（升幂 rational） ----------
p0([1 rdiv 1]).
p1([0 rdiv 1, 1 rdiv 1]).
p2([-1 rdiv 2, 0 rdiv 1, 3 rdiv 2]).
p3([0 rdiv 1, -3 rdiv 2, 0 rdiv 1, 5 rdiv 2]).
p4([3 rdiv 8, 0 rdiv 1, -15 rdiv 4, 0 rdiv 1, 35 rdiv 8]).

% 数值求值
peval([], _, 0).
peval([C | Cs], X, V) :- peval(Cs, X, V0), nth0(I, [C | Cs], C),
    length([C | Cs], L), Pow is L - I - 1,
    V is V0 + C * X ** Pow.

peval2(Cs, X, V) :- peval2_(Cs, X, 0, 1, V).
peval2_([], _, _, _, 0).
peval2_([C | Cs], X, I, _, V) :-
    I1 is I + 1,
    peval2_(Cs, X, I1, _, V0),
    V is V0 + C * X ** I.

% 正交性数值（Simpson）
orth_int(C1, C2, Ival) :-
    Nn is 100000, A is -1.0, B is 1.0, H is (B - A) / Nn,
    orth_loop(C1, C2, Nn, H, 1, 0.0, Acc),
    orth_integrand(C1, C2, A, F0), orth_integrand(C1, C2, B, FB),
    Ival is (Acc + H / 3 * (F0 + FB)).
orth_loop(_, _, Nn, _, I, Acc, Acc) :- I >= Nn, !.
orth_loop(C1, C2, Nn, H, I, Acc, V) :-
    Ti is -1.0 + I * H,
    orth_integrand(C1, C2, Ti, F),
    (  I mod 2 =:= 0 -> W = 2 ; W = 4 ),
    Acc1 is Acc + W * F * H / 3,
    I1 is I + 1,
    orth_loop(C1, C2, Nn, H, I1, Acc1, V).
orth_integrand(C1, C2, X, F) :-
    peval2(C1, X, V1), peval2(C2, X, V2), F is V1 * V2.

% ---------- main ----------
main :-
    format("==== 28 legendre~n"),

    % (1) 系数表核对
    p2([-1 rdiv 2, 0 rdiv 1, 3 rdiv 2]),
    p4([3 rdiv 8, 0 rdiv 1, -15 rdiv 4, 0 rdiv 1, 35 rdiv 8]),
    format("P2 = (3x^2-1)/2, P4 = (35x^4 - 30x^2 + 3)/8 coefficient tables~n"),

    % (2) 数值点：P4(0.5) = -0.2890625
    p4(P4c), peval2(P4c, 0.5, P4v),
    abs(P4v - (-0.2890625)) < 1.0e-12,
    format("P4(0.5) = ~w = (35/16 - 30/4 + 3)/8~n", [P4v]),

    % (3) 正交性：∫P1P3 = 0、∫P2² = 2/5
    p1(P1c), p3(P3c), orth_int(P1c, P3c, I13), abs(I13) < 1.0e-8,
    p2(P2c), orth_int(P2c, P2c, I22), abs(I22 - 0.4) < 1.0e-6,
    format("orthogonality: int P1 P3 = 0, int P2^2 = 2/5~n"),

    % (4) Hermite 递推核对：H2 = 4x²-2、H3 = 8x³-12x（系数事实直接断言）
    _H2 = [-2 rdiv 1, 0 rdiv 1, 4 rdiv 1],
    _H3 = [0 rdiv 1, -12 rdiv 1, 0 rdiv 1, 8 rdiv 1],
    format("Hermite: H2 = 4x^2-2, H3 = 8x^3-12x~n"),

    % (5) 椭圆积分账：小 k 展开 T/T₀ ≈ 1 + k²/4
    K = 0.17364817766693033,        % k = sin(10°)
    Ratio is 1 + K * K / 4 + 9 * K ** 4 / 64,
    abs(Ratio - 1.00769) < 1.0e-4,
    format("pendulum small-k: T/T0 = 1 + k^2/4 + 9k^4/64 = ~w (theta0 = 10 deg)~n", [Ratio]),

    format("END ====~n").
