:- encoding(utf8).
/* 第 121 章：有限辅助博弈的策略提升/拉回证书；不模拟无限测度平均。 */

aux_payoff(A, B, H, true) :- (A == 1 ; B == 0), H == B, !.
aux_payoff(_, _, _, false).

projected_payoff(A, B, true) :-
    member(H, [0, 1]), aux_payoff(A, B, H, true), !.
projected_payoff(_, _, false).

base_strategy_wins(A) :-
    forall(member(B, [0, 1]), projected_payoff(A, B, true)).

aux_strategy_wins(A, H0, H1) :-
    aux_payoff(A, 0, H0, true),
    aux_payoff(A, 1, H1, true).

base_value(true) :- member(A, [0, 1]), base_strategy_wins(A), !.
base_value(false).

aux_value(true) :-
    member(A, [0, 1]), member(H0, [0, 1]), member(H1, [0, 1]),
    aux_strategy_wins(A, H0, H1), !.
aux_value(false).

lift_certificate(A, certificate(A, response(0, 0), response(1, 1))) :-
    base_strategy_wins(A),
    aux_strategy_wins(A, 0, 1).

pullback_certificate(A, H0, H1, certificate(A, response(0, H0), response(1, H1))) :-
    aux_strategy_wins(A, H0, H1),
    base_strategy_wins(A).

main :-
    base_value(true), aux_value(true),
    findall(C, (member(A, [0, 1]), lift_certificate(A, C)), Lifts),
    findall(C, (member(A, [0, 1]), member(H0, [0, 1]), member(H1, [0, 1]),
                pullback_certificate(A, H0, H1, C)), Pullbacks),
    length(Lifts, 1), length(Pullbacks, 1),
    forall(member(H, [0, 1]), aux_payoff(0, 1, H, false)),
    writeln('==== 121'),
    maplist(writeln, Lifts),
    maplist(writeln, Pullbacks),
    writeln('base=true auxiliary=true lift=1 pullback=1'),
    writeln('END ===='),
    halt.
:- initialization(main).
