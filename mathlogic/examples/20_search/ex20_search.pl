:- encoding(utf8).
% ex20_search.pl -- Mints ch10: LJpm* tableau decision procedure mirror.
% Components sq(G,D); tableau = list of components. ASCII stdout, END ====.

mem(X, [Y|_]) :- X == Y, !.
mem(X, [_|T]) :- mem(X, T).

add(X, L, L) :- mem(X, L), !.
add(X, L, [X|L]).

rem(_, [], []).
rem(X, [Y|T], R) :- X == Y, !, rem(X, T, R).
rem(X, [Y|T], [Y|R]) :- rem(X, T, R).

incl([], _).
incl([X|T], L) :- mem(X, L), incl(T, L).

% subsumed(s,u): s both-sides subset of u (Def 10.1)
subsumed(sq(G1,D1), sq(G2,D2)) :- incl(G1,G2), incl(D1,D2).

eqsq(sq(G1,D1), sq(G2,D2)) :-
    incl(G1,G2), incl(G2,G1), incl(D1,D2), incl(D2,D1).

atomic_f(v(_)).

axiom(sq(G,_)) :- mem(ff, G), !.
axiom(sq(G,D)) :- member(X, G), atomic_f(X), mem(X, D), !.

closed(T) :- member(S, T), axiom(S), !.

composite(C) :- compound(C), \+ atomic_f(C).

has_progress(Old, New) :-
    member(S, New),
    \+ (member(U, Old), subsumed(S, U)), !.

subst(T, S, Repl, none, NewT) :- !,
    findall(C, (member(U,T), (eqsq(U,S) -> member(C,Repl) ; C=U)), NewT).
subst(T, S, Repl, some(E), NewT) :-
    subst(T, S, Repl, none, Base),
    (mem(E, Base) -> NewT = Base
    ; NewT = [E|Base]).

mk_inst(T, S, Repl, Extra, Insts) :-
    subst(T, S, Repl, Extra, New),
    (has_progress(T, New) -> Insts = [[New]] ; Insts = []).

mk_inst2(T, S, P1, P2, Insts) :-
    subst(T, S, [P1], none, T1),
    subst(T, S, [P2], none, T2),
    (has_progress(T,T1), has_progress(T,T2) -> Insts = [[T1,T2]] ; Insts = []).

% analyze(T, sq(G,D), C, Insts)
analyze(T, sq(G,D), C, Insts) :-
    (mem(C,G) -> InG = true ; InG = false),
    (mem(C,D) -> InD = true ; InD = false),
    analyze_(T, G, D, C, InG, InD, Insts).

analyze_(T, G, D, and(X,Y), true, _, Insts) :- !,
    rem(and(X,Y), G, G0), add(X, G0, G1), add(Y, G1, G2),
    mk_inst(T, sq(G,D), [sq(G2, D)], none, Insts).
analyze_(T, G, D, and(X,Y), false, true, Insts) :- !,
    rem(and(X,Y), D, D0), add(X, D0, D1), add(Y, D1, D2),
    mk_inst2(T, sq(G,D), sq(G, D1), sq(G, D2), Insts).
analyze_(T, G, D, or(X,Y), true, _, Insts) :- !,
    rem(or(X,Y), G, G0), add(X, G0, G1), add(Y, G0, G2),
    mk_inst2(T, sq(G,D), sq(G1, D), sq(G2, D), Insts).
analyze_(T, G, D, or(X,Y), false, true, Insts) :- !,
    rem(or(X,Y), D, D0), add(X, D0, D1), add(Y, D1, D2),
    mk_inst(T, sq(G,D), [sq(G, D2)], none, Insts).
analyze_(T, G, D, imp(X,Y), true, _, Insts) :- !,
    % ->L premise1 keeps the principal formula (Glivenko needs it)
    add(X, D, D1),
    rem(imp(X,Y), G, G0), add(Y, G0, G2),
    mk_inst2(T, sq(G,D), sq(G, D1), sq(G2, D), Insts).
analyze_(T, G, D, imp(X,Y), false, true, Insts) :- !,
    % =>R: keep original component + add (G+X => [Y])
    add(X, G, G1),
    mk_inst(T, sq(G,D), [sq(G,D)], some(sq(G1, [Y])), Insts).
analyze_(_, _, _, _, _, _, []).

all_instances(T, Insts) :-
    findall(I,
        (member(sq(G,D), T),
         ( (member(C, G) ; member(C, D)), composite(C),
           analyze(T, sq(G,D), C, Is), member(I, Is) )
        ),
        Insts0),
    Insts0 \== [],
    dedup_insts(Insts0, Insts).

dedup_insts([], []).
dedup_insts([I|T], R) :-
    (member(J, T), same_inst(I, J) -> R = R0 ; R = [I|R0]),
    dedup_insts(T, R0).

same_inst([], []).
same_inst([A|As], [B|Bs]) :- eqsq(A, B), same_inst(As, Bs).

all_closed(_, []).
all_closed(Fuel, [P|Rest]) :-
    Fuel > 0,
    dfs(Fuel, P, none),
    Fuel1 is Fuel - 1,
    all_closed(Fuel1, Rest).

% dfs(Fuel, T, R): R=none ⟺ closed; R=some(T) ⟺ open terminal
dfs(_, T, none) :- closed(T), !.
dfs(0, T, some(T)) :- !.
dfs(Fuel, T, R) :-
    F1 is Fuel - 1,
    ( all_instances(T, Insts) ->
      ( member(Inst, Insts), all_closed(F1, Inst) -> R = none
      ; R = some(T) )
    ; R = some(T)
    ), !.

decide(Fuel, G, D) :- dfs(Fuel, [sq(G, D)], none), !.

neg(A, imp(A, ff)).

run(Name, G, D, Expect) :-
    (decide(24, G, D) -> Got = yes ; Got = no),
    (Got == Expect -> Ok = ok ; Ok = mismatch),
    format("~a: derivable=~a expect=~a ~a~n", [Name, Got, Expect, Ok]).

main :-
    P = v(p), Q = v(q),
    neg(P, NP), neg(Q, _NQ), neg(and(P, NP), NC),
    neg(or(P, NP), OR), neg(OR, NN), neg(NP, NNP),
    neg(imp(P, Q), PQ), neg(imp(Q, P), _QP),
    run(id, [], [imp(P,P)], yes),
    run(nocontra, [], [NC], yes),
    run(glivenko, [], [NN], yes),
    run(andcomm, [and(P,Q)], [and(Q,P)], yes),
    run(disjsyl, [NP, or(P,Q)], [Q], yes),
    run(lem, [], [or(P, NP)], no),
    run(dne, [], [imp(NNP, P)], no),
    run(peirce, [], [imp(imp(PQ, P), P)], no),
    run(wlem, [], [or(NP, NNP)], no),
    run(dummett, [], [or(imp(P,Q), imp(Q,P))], no),
    write('END ===='), nl.
