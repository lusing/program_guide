:- encoding(utf8).
% ex3_fitch.pl —— 费奇式自然演绎 FJ/FK 检查器（马明辉 2.1）
% 公式：pv(N) | bot | and2(A,B) | or2(A,B) | imp(A,B)；neg(A) 即 imp(A,bot)
% 依据：pre | hyp | reit(M) | ai(M,N) | ael(M) | aer(M) | oi1(M) | oi2(M)
%       | oe(M,A,B,C,E) | ii(A,B) | ie(M,N) | bote(M) | ne(A,B)
% 作用域纪律：推理规则只准引同框行（acc_same）；Reit 恰上一级（acc_up）。

% ---------- 推导数据（书例） ----------

% 引例：alpha, alpha->beta, ~beta |- bot
line(exIntro, 1, 0, pv(0), pre).
line(exIntro, 2, 0, imp(pv(0), pv(1)), pre).
line(exIntro, 3, 0, imp(pv(1), bot), pre).
line(exIntro, 4, 0, pv(1), ie(2, 1)).
line(exIntro, 5, 0, bot, ie(3, 4)).

% 引例：|- alpha->alpha
line(exId, 1, 1, pv(0), hyp).
line(exId, 2, 1, pv(0), reit(1)).
line(exId, 3, 0, imp(pv(0), pv(0)), ii(1, 2)).

% 例 2.1(3)：|-FK ~~alpha->alpha（跨级 Reit + ne 归谬）
line(exDNE, 1, 1, imp(imp(pv(0), bot), bot), hyp).
line(exDNE, 2, 2, imp(pv(0), bot), hyp).
line(exDNE, 3, 2, imp(imp(pv(0), bot), bot), reit(1)).
line(exDNE, 4, 2, bot, ie(3, 2)).
line(exDNE, 5, 1, pv(0), ne(2, 4)).
line(exDNE, 6, 0, imp(imp(imp(pv(0), bot), bot), pv(0)), ii(1, 5)).

% 引例：alpha|beta |- beta|alpha（oe 双并列框）
line(exComm, 1, 0, or2(pv(0), pv(1)), pre).
line(exComm, 2, 1, pv(0), hyp).
line(exComm, 3, 1, or2(pv(1), pv(0)), oi2(2)).
line(exComm, 4, 1, pv(1), hyp).
line(exComm, 5, 1, or2(pv(1), pv(0)), oi1(4)).
line(exComm, 6, 0, or2(pv(1), pv(0)), oe(1, 2, 3, 4, 5)).

% 引例：|- (alpha->beta)->((beta->gamma)->(alpha->gamma))——级联 Reit
line(exSyll, 1, 1, imp(pv(0), pv(1)), hyp).
line(exSyll, 2, 2, imp(pv(1), pv(2)), hyp).
line(exSyll, 3, 2, imp(pv(0), pv(1)), reit(1)).
line(exSyll, 4, 3, pv(0), hyp).
line(exSyll, 5, 3, imp(pv(0), pv(1)), reit(3)).
line(exSyll, 6, 3, pv(1), ie(5, 4)).
line(exSyll, 7, 3, imp(pv(1), pv(2)), reit(2)).
line(exSyll, 8, 3, pv(2), ie(7, 6)).
line(exSyll, 9, 2, imp(pv(0), pv(2)), ii(4, 8)).
line(exSyll, 10, 1, imp(imp(pv(1), pv(2)), imp(pv(0), pv(2))), ii(2, 9)).
line(exSyll, 11, 0, imp(imp(pv(0), pv(1)),
                        imp(imp(pv(1), pv(2)), imp(pv(0), pv(2)))), ii(1, 10)).

% |-FK p|~p（ne 归谬）；FJ 拒收
line(exLem, 1, 1, imp(or2(pv(0), imp(pv(0), bot)), bot), hyp).
line(exLem, 2, 2, pv(0), hyp).
line(exLem, 3, 2, imp(or2(pv(0), imp(pv(0), bot)), bot), reit(1)).
line(exLem, 4, 2, or2(pv(0), imp(pv(0), bot)), oi1(2)).
line(exLem, 5, 2, bot, ie(3, 4)).
line(exLem, 6, 1, imp(pv(0), bot), ii(2, 5)).
line(exLem, 7, 1, or2(pv(0), imp(pv(0), bot)), oi2(6)).
line(exLem, 8, 1, bot, ie(1, 7)).
line(exLem, 9, 0, or2(pv(0), imp(pv(0), bot)), ne(1, 8)).

% 跨级引用（漏 Reit）抓错现场
line(badCross, 1, 1, imp(pv(0), pv(1)), hyp).
line(badCross, 2, 2, pv(0), hyp).
line(badCross, 3, 2, pv(1), ie(1, 2)).
line(badCross, 4, 1, imp(pv(0), pv(1)), ii(2, 3)).
line(badCross, 5, 0, imp(imp(pv(0), pv(1)), imp(pv(0), pv(1))), ii(1, 4)).

line(goodCross, 1, 1, imp(pv(0), pv(1)), hyp).
line(goodCross, 2, 2, pv(0), hyp).
line(goodCross, 3, 2, imp(pv(0), pv(1)), reit(1)).
line(goodCross, 4, 2, pv(1), ie(3, 2)).
line(goodCross, 5, 1, imp(pv(0), pv(1)), ii(2, 4)).
line(goodCross, 6, 0, imp(imp(pv(0), pv(1)), imp(pv(0), pv(1))), ii(1, 5)).

% ---------- 可达性 ----------

any_hyp_lv(D, J, Hi, Lv) :-
    between(J, Hi, X), line(D, X, V, _, hyp), V =:= Lv, !.
any_below(D, J, Hi, Lv) :-
    between(J, Hi, X), line(D, X, V, _, _), V < Lv, !.

acc_same(D, M, I) :-
    line(D, M, VM, _, _), line(D, I, VI, _, _),
    VM =:= VI, M < I, J0 is M + 1, \+ any_hyp_lv(D, J0, I, VM).
acc_up(D, M, I) :-
    line(D, M, VM, _, _), line(D, I, VI, _, _),
    VI =:= VM + 1, M < I, J0 is M + 1, \+ any_below(D, J0, I, VM).

% ---------- 级别纪律 ----------

first_ok(D) :-
    line(D, 1, L, _, J),
    ( J = pre -> L =:= 0
    ; J = hyp -> L =:= 1
    ; false ).

step_ok(D, I) :-
    I1 is I + 1,
    line(D, I, L1, _, _), line(D, I1, L2, _, J2),
    L2 =< L1 + 1,
    ( L2 =:= L1 + 1 -> J2 = hyp ; true ),
    ( J2 = hyp -> (L2 =:= L1 ; L2 =:= L1 + 1) ; true ),
    ( J2 = pre -> L2 =:= 0 ; true ).

steps_ok(D) :-
    forall(between(1, 20, I),
           ( line(D, I, _, _, _), I1 is I + 1, line(D, I1, _, _, _)
           -> step_ok(D, I) ; true )).

% ---------- 依据逐行核 ----------

check_j(D, I, L, F, J, Kc) :-
    check_just(D, I, L, F, J, Kc).

check_just(_, _, L, _, pre, _) :- !, L =:= 0.
check_just(_, _, _, _, hyp, _) :- !.
check_just(D, I, _, F, reit(M), _) :- !,
    line(D, M, _, F, _),
    ( acc_same(D, M, I) ; acc_up(D, M, I) ).
check_just(D, I, _, F, ai(M, N), _) :- !,
    line(D, M, _, A, _), line(D, N, _, B, _),
    F = and2(A, B), acc_same(D, M, I), acc_same(D, N, I).
check_just(D, I, _, F, ael(M), _) :- !,
    line(D, M, _, and2(A, _), _), F = A, acc_same(D, M, I).
check_just(D, I, _, F, aer(M), _) :- !,
    line(D, M, _, and2(_, B), _), F = B, acc_same(D, M, I).
check_just(D, I, _, F, oi1(M), _) :- !,
    line(D, M, _, A, _), F = or2(A, _), acc_same(D, M, I).
check_just(D, I, _, F, oi2(M), _) :- !,
    line(D, M, _, B, _), F = or2(_, B), acc_same(D, M, I).
check_just(D, I, _, F, bote(M), _) :- !,
    line(D, M, _, bot, _), F = _, acc_same(D, M, I).
check_just(D, I, _, F, ie(M, N), _) :- !,
    line(D, M, _, imp(A, B), _), line(D, N, _, A, _),
    F = B, acc_same(D, M, I), acc_same(D, N, I).
check_just(D, I, L, F, ii(A, B), _) :- !,
    I is B + 1,
    line(D, A, LA, FA, hyp), line(D, B, LB, FB, _),
    LA =:= L + 1, LB =:= LA, F = imp(FA, FB).
check_just(D, I, L, F, ne(A, B), Kc) :- !,
    Kc =:= 1, I is B + 1,
    line(D, A, LA, FA, hyp), line(D, B, LB, bot, _),
    LA =:= L + 1, LB =:= LA, FA = imp(F, bot).
check_just(D, I, L, F, oe(M, A, B, C, E), _) :- !,
    C is B + 1, I is E + 1,
    line(D, M, _, or2(X, Y), _),
    line(D, A, LA, X, hyp), line(D, C, LC, Y, hyp),
    line(D, B, LB, FB, _), line(D, E, LE, FE, _),
    LA =:= L + 1, LC =:= L + 1, LB =:= LA, LE =:= LC,
    FB = F, FE = F.

check1(D, I, Kc) :-
    line(D, I, L, F, J), check_j(D, I, L, F, J, Kc).

fitch_ok(D, Kc) :-
    first_ok(D), steps_ok(D),
    forall(between(1, 20, I),
           ( line(D, I, _, _, _) -> check1(D, I, Kc) ; true )).

% ---------- main ----------

report(Name, Kc, Expect) :-
    ( fitch_ok(Name, Kc) -> R = ok ; R = bad ),
    ( R = Expect -> format("~w kc=~w: ~w (expected ~w) PASS~n", [Name, Kc, R, Expect])
    ; format("~w kc=~w: ~w (expected ~w) MISMATCH~n", [Name, Kc, R, Expect]) ).

main :-
    report(exIntro, 1, ok),
    report(exId, 0, ok),
    report(exDNE, 1, ok),
    report(exDNE, 0, bad),
    report(exComm, 0, ok),
    report(exSyll, 0, ok),
    report(exLem, 1, ok),
    report(exLem, 0, bad),
    report(badCross, 1, bad),
    report(goodCross, 0, ok),
    format("END ====~n").
