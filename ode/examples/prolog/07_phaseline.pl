:- encoding(utf8).
% 07_phaseline.pl —— 第 07 章：符号相线引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
% 对多项式 f(y)（rational 系数）：平衡点求根、区间定号、sink/source/degenerate 分类。
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

% ---------- 相线引擎 ----------
% f 用 y 的多项式表示：poly(Coeffs)（Coeffs 从低到高，rational）
% eval_poly(Coeffs, Y, V)
eval_poly([], _, 0).
eval_poly([C | Cs], Y, V) :- eval_poly(Cs, Y, V0), V is C + Y * V0.

% 有理根搜索（[-20,20] 整数根，针对书例的整根）
rational_roots(Cs, Roots) :-
    findall(R, (between(-20, 20, R0), R is R0 rdiv 1, eval_poly(Cs, R, V), V =:= 0), Roots).

% 分类：平衡点两侧区间符号
%   左 ↓(-1) 右 ↑(+1) ⟹ source？不——箭头相向（左↑右↓）⟹ sink；相背 ⟹ source
classify(Cs, Ye, Type) :-
    eval_poly(Cs, Ye - 0.5, VL), eval_poly(Cs, Ye + 0.5, VR),
    SL is sign(VL), SR is sign(VR),
    ( SL =:= 1, SR =:= -1 -> Type = sink
    ; SL =:= -1, SR =:= 1 -> Type = source
    ; Type = degenerate ).

% 导数判据（多项式导数）
poly_deriv([], []).
poly_deriv([_], []).
poly_deriv([_, C1 | Rest], D) :- poly_deriv_([C1 | Rest], 1, D).
poly_deriv_([], _, []).
poly_deriv_([C | Cs], N, [D | Ds]) :- D is C * N, N1 is N + 1, poly_deriv_(Cs, N1, Ds).

% ---------- main ----------
main :-
    format("==== 07 phaseline~n"),

    % (1) 书例 2.29：f = y(y-1) = [-0, 1, 1]（y² - y）
    Cs29 = [0 rdiv 1, -1 rdiv 1, 1 rdiv 1],
    rational_roots(Cs29, R29), sort(R29, [0, 1]),
    classify(Cs29, 0, sink),
    classify(Cs29, 1, source),
    format("y(y-1): equilibria 0 (sink), 1 (source)~n"),
    poly_deriv(Cs29, D29), eval_poly(D29, 0, Dp0), Dp0 < 0,
    eval_poly(D29, 1, Dp1), Dp1 > 0,
    format("derivative test: f'(0) = ~w < 0, f'(1) = ~w > 0~n", [Dp0, Dp1]),

    % (2) 书例 2.30：f = ky²，k=2 ⟹ [0,0,2]：退化结点（f'(0)=0）
    Cs30 = [0, 0, 2],
    classify(Cs30, 0, degenerate),
    poly_deriv(Cs30, [0, 4]), eval_poly([0, 4], 0, 0),
    format("2y^2: degenerate node, f'(0) = 0 (test inconclusive)~n"),

    % (3) 书例 2.31：f = -y³ ⟹ [0,0,0,-1]：sink 但判据哑火
    Cs31 = [0, 0, 0, -1],
    classify(Cs31, 0, sink),
    poly_deriv(Cs31, D31), eval_poly(D31, 0, 0),
    format("-y^3: sink by sign analysis, f'(0) = 0 (test blind)~n"),

    % (4) 复合例：f = y(y-1)(y+2) 展开系数
    % y(y-1)(y+2) = y^3 + y^2 - 2y ⟹ [-2, 1, 1, 0]? 展开核对：
    % (y^2 - y)(y + 2) = y^3 + 2y^2 - y^2 - 2y = y^3 + y^2 - 2y
    CsX = [0, -2, 1, 1],
    rational_roots(CsX, RX), sort(RX, [-2, 0, 1]),
    classify(CsX, -2, source),
    classify(CsX, 0, sink),
    classify(CsX, 1, source),
    format("y(y-1)(y+2): -2 (source), 0 (sink), 1 (source)~n"),

    format("END ====~n").
