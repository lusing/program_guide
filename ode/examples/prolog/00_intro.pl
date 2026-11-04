:- encoding(utf8).
% 00_intro.pl —— 第 00 章：解的符号核对（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%
% 验证 y = 2e^x - x - 1 是 y' = x + y、y(0)=1 的解；反例 2e^x - x 残差 -1。
% 表达式树：n(C) | x | y | yp | add/sub/mul/div(E1,E2) | neg(E) | pow(E,N)
%           | exp/ln/sin/cos(E)
%
% 化简内核（全书 Prolog 通道共用，逐章自包含复制）：
%   表达式 -> 项表 t(C, Ms)（C 数值系数，Ms 排序幂因子表 p(F,N)）
%   -> 同单项合并 -> 重建规范形。乘法对加法自动分配，x*x -> pow(x,2)。

% ---------- 符号微分（纯 x 表达式；y/yp 只出现在代入前） ----------
d(n(_), _, n(0)).
d(x, x, n(1)) :- !.
d(add(A, B), V, add(DA, DB)) :- d(A, V, DA), d(B, V, DB).
d(sub(A, B), V, sub(DA, DB)) :- d(A, V, DA), d(B, V, DB).
d(mul(A, B), V, add(mul(DA, B), mul(A, DB))) :- d(A, V, DA), d(B, V, DB).
d(neg(A), V, neg(DA)) :- d(A, V, DA).
d(div(A, B), V, div(sub(mul(DA, B), mul(A, DB)), mul(B, B))) :-
    d(A, V, DA), d(B, V, DB).
d(pow(A, N), V, mul(n(N), mul(pow(A, N1), DA))) :-
    integer(N), N1 is N - 1, d(A, V, DA).
d(exp(A), V, mul(exp(A), DA)) :- d(A, V, DA).
d(ln(A), V, div(DA, A)) :- d(A, V, DA).
d(sin(A), V, mul(cos(A), DA)) :- d(A, V, DA).
d(cos(A), V, neg(mul(sin(A), DA))) :- d(A, V, DA).

% ---------- 项表：tl(E, Ts) ----------
tl(sum(Ts), Ts) :- !.
tl(n(C), Ts) :- !, (C =:= 0 -> Ts = [] ; Ts = [t(C, [])]).
tl(add(A, B), Ts) :- !, tl(A, TA), tl(B, TB), append(TA, TB, Ts).
tl(sub(A, B), Ts) :- !, tl(A, TA), tl(B, TB),
    maplist(neg_t, TB, TBN), append(TA, TBN, Ts).
tl(neg(A), Ts) :- !, tl(A, TA), maplist(neg_t, TA, Ts).
tl(mul(A, B), Ts) :- !, tl(A, TA), tl(B, TB), prod_terms(TA, TB, Ts).
tl(div(A, B), Ts) :- !, tl(mul(A, pow(B, -1)), Ts).
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

% ---------- 同单项合并 + 重建 ----------
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
rebuild([t(C, Ms)], S) :- !, rebuild_prod(Ms, P), (P = n(1) -> S = n(C) ; S = mul(n(C), P)).
rebuild(Ts, sum(Ts)).

rebuild_prod([], n(1)).
rebuild_prod([p(F, 1)], F) :- !.
rebuild_prod([p(F, N)], pow(F, N)) :- !.
rebuild_prod([p(F, 1) | Ps], mul(F, R)) :- !, rebuild_prod(Ps, R).
rebuild_prod([p(F, N) | Ps], mul(pow(F, N), R)) :- rebuild_prod(Ps, R).

% ---------- 化简主入口 ----------
simp(n(C), n(C)) :- !.
simp(x, x) :- !.
simp(sum(Ts), S) :- !, combine_terms(Ts, TsC), rebuild(TsC, S).
simp(add(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(add(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(sub(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(sub(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(neg(A), S) :- !, simp(mul(n(-1), A), S).
simp(mul(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(mul(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(div(A, B), S) :- !, simp(A, SA), simp(B, SB),
    ( SB = n(V), V =\= 0 -> Q is 1 rdiv V, tl(mul(SA, n(Q)), Ts)
    ; tl(mul(SA, pow(SB, -1)), Ts) ),
    combine_terms(Ts, TsC), rebuild(TsC, S).
simp(pow(A, N), S) :- !, simp(A, SA),
    ( N =:= 0 -> S = n(1)
    ; N =:= 1 -> S = SA
    ; SA = n(V) -> W is V ^ N, S = n(W)
    ; tl([t(1, [p(SA, N)])], Ts), combine_terms(Ts, TsC), rebuild(TsC, S) ).
simp(E, S) :- E =.. [F, A], opaque(F), !,
    simp(A, SA), S =.. [F, SA].
simp(E, E).

opaque(exp). opaque(ln). opaque(sin). opaque(cos).

% ---------- 代入：y -> Phi, yp -> DPhi ----------
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

% ---------- 解核对主谓词 ----------
solve_check(Body, Phi) :-
    d(Phi, x, DPhi),
    subst(Body, Phi, DPhi, R),
    simp(R, n(0)).

% 表达式在数值点求值（初值核对用）
ev_at(n(C), _, C).
ev_at(x, X, X).
ev_at(add(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA + VB.
ev_at(sub(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA - VB.
ev_at(mul(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA * VB.
ev_at(div(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA / VB.
ev_at(neg(A), X, V) :- ev_at(A, X, VA), V is -VA.
ev_at(exp(A), X, V) :- ev_at(A, X, VA), V is exp(VA).
ev_at(ln(A), X, V) :- ev_at(A, X, VA), V is log(VA).
ev_at(sin(A), X, V) :- ev_at(A, X, VA), V is sin(VA).
ev_at(cos(A), X, V) :- ev_at(A, X, VA), V is cos(VA).
ev_at(pow(A, N), X, V) :- ev_at(A, X, VA), V is VA ^ N.

% ---------- main ----------
main :-
    format("==== 00 intro~n"),

    % 常驻例：y' = x + y，y = 2e^x - x - 1
    Phi = sub(sub(mul(n(2), exp(x)), x), n(1)),
    solve_check(sub(yp, add(x, y)), Phi),
    format("y = 2e^x - x - 1 satisfies y' = x + y (simplifies to 0)~n"),

    % 初值：phi(0) = 2 - 0 - 1 = 1
    ev_at(Phi, 0, V0), V0 =:= 1,
    format("y(0) = 1~n"),

    % 反例：2e^x - x（少了 -1）残差恒为 -1
    Wrong = sub(mul(n(2), exp(x)), x),
    d(Wrong, x, DWrong),
    subst(sub(yp, add(x, y)), Wrong, DWrong, R),
    simp(R, n(C)), C =:= -1,
    format("wrong solution 2e^x - x has residual -1 (never 0)~n"),

    % Malthus 解核对：y' = 3y，y = 5e^{3x}
    solve_check(sub(yp, mul(n(3), y)), mul(n(5), exp(mul(n(3), x)))),
    format("y = 5e^{3x} satisfies y' = 3y~n"),

    % 指数定律核对：y = e^{2x} 满足 y' = 2y（链式法则走符号微分）
    solve_check(sub(yp, mul(n(2), y)), exp(mul(n(2), x))),
    format("y = e^{2x} satisfies y' = 2y~n"),

    format("END ====~n").
