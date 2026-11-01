:- encoding(utf8).
/* 第 120 章：逆向归纳与可打印稳赢策略证书；仅限四步有限博弈。 */

payoff([_, B, C, _], true) :- B == C, !.
payoff(_, false).

value(H, V) :-
    length(H, 4), !,
    payoff(H, V).
value(H, true) :-
    length(H, L), 0 is L mod 2, !,
    ( value_with_move(H, 0, true) ; value_with_move(H, 1, true) ).
value(H, true) :-
    value_with_move(H, 0, true),
    value_with_move(H, 1, true).

value_with_move(H, M, V) :- append(H, [M], H1), value(H1, V).

certified_move([], 0).
certified_move([0, B], B).

play(B, D, [A, B, C, D]) :-
    certified_move([], A),
    certified_move([0, B], C).

winning_certificate(B, D, certificate(A, B, C, D, true)) :-
    play(B, D, [A, B, C, D]),
    payoff([A, B, C, D], true).

main :-
    value([], true),
    forall(member(B, [0, 1]), value([0, B], true)),
    findall(C, (member(B, [0, 1]), member(D, [0, 1]),
                winning_certificate(B, D, C)), Cs),
    length(Cs, 4),
    writeln('==== 120'),
    maplist(writeln, Cs),
    writeln('root=true certificates=4/4'),
    writeln('END ===='),
    halt.
:- initialization(main).
