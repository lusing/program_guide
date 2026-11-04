:- encoding(utf8).
% 21_bifurcation.pl —— 第 21 章：范式识别器（Prolog 通道）
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

% ---------- 范式识别与奇点 ----------
% normal_form(Eq, Kind)：y' = f(y, mu) 的多项式形态
normal_form(sub(mu, pow(y, 2)), saddle_node).          % mu - y^2
normal_form(sub(mul(mu, y), pow(y, 2)), transcritical). % mu y - y^2
normal_form(sub(mul(mu, y), pow(y, 3)), pitchfork).     % mu y - y^3

% equilibria(Kind, Mu, Es)：奇点表（Mu 为数值）
equilibria(saddle_node, Mu, [S, NS]) :- Mu > 0, S is sqrt(Mu), NS is -S, !.
equilibria(saddle_node, _, []).
equilibria(transcritical, Mu, [0, Mu]).
equilibria(pitchfork, Mu, [0, S, NS]) :- Mu > 0, S is sqrt(Mu), NS is -S, !.
equilibria(pitchfork, _, [0]).

% stable_at(Kind, Mu, Point)：符号/线性化判稳
stable_at(saddle_node, Mu, P) :- Mu > 0, P is sqrt(Mu).         % f' = -2√μ < 0
stable_at(transcritical, Mu, 0) :- Mu < 0.                       % f' = μ < 0
stable_at(transcritical, Mu, P) :- Mu > 0, P is Mu.              % f' = -μ < 0
stable_at(pitchfork, Mu, 0) :- Mu < 0.                            % μ<0 唯一稳定是 0
stable_at(pitchfork, Mu, P) :- Mu > 0, S is sqrt(Mu), (P is S ; P is -S).

% hopf_radius(Mu, R)：超临界 Hopf 环半径 √μ
hopf_radius(Mu, R) :- R is sqrt(Mu).

% ---------- main ----------
main :-
    format("==== 21 bifurcation~n"),

    % (1) 三范式识别
    normal_form(sub(mu, pow(y, 2)), saddle_node),
    normal_form(sub(mul(mu, y), pow(y, 2)), transcritical),
    normal_form(sub(mul(mu, y), pow(y, 3)), pitchfork),
    format("normal forms recognized: saddle-node / transcritical / pitchfork~n"),

    % (2) 鞍结奇点：μ=1 给 ±1，上稳下不稳；μ=-1 无
    equilibria(saddle_node, 1.0, [1.0, -1.0]),
    equilibria(saddle_node, -1.0, []),
    stable_at(saddle_node, 1.0, 1.0),
    format("saddle-node mu=1: equilibria +-1 (upper stable); mu=-1: none~n"),

    % (3) 跨临界交换：μ=-0.5 稳在 0；μ=0.5 稳在 μ
    stable_at(transcritical, -0.5, 0),
    stable_at(transcritical, 0.5, 0.5),
    format("transcritical: stability exchanges at mu=0~n"),

    % (4) 叉式：μ=1 三奇点，±1 稳；μ=-0.5 只有 0 稳
    equilibria(pitchfork, 1.0, [0, 1.0, -1.0]),
    stable_at(pitchfork, 1.0, 1.0),
    stable_at(pitchfork, 1.0, -1.0),
    stable_at(pitchfork, -0.5, 0),
    format("pitchfork mu=1: {0, +-1} with +-1 stable; mu<0: y=0 stable~n"),

    % (5) Hopf 半径律：三点核对 √μ
    hopf_radius(0.25, 0.5), hopf_radius(1.0, 1.0), hopf_radius(4.0, 2.0),
    format("Hopf: cycle radius sqrt(mu) at mu = 0.25/1/4 -> 0.5/1/2~n"),

    format("END ====~n").
